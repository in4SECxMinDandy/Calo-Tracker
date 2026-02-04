# CaloTracker Community Platform - Architecture Design

## Overview

This document outlines the architectural transformation of CaloTracker from a single-user local app to a multi-user community platform using **Supabase** as the backend, with a focus on **Groups & Challenges** as the primary community interaction.

---

## 1. Technology Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Frontend** | Flutter (existing) | Cross-platform, already in use |
| **Backend** | Supabase | PostgreSQL, Auth, Storage, Realtime, Edge Functions |
| **Database** | PostgreSQL (Supabase) | Relational, scalable, RLS for security |
| **Authentication** | Supabase Auth | Email/password, OAuth (Google, Apple) |
| **Storage** | Supabase Storage | User avatars, meal photos, challenge images |
| **Realtime** | Supabase Realtime | Live updates for challenges, notifications |
| **Edge Functions** | Supabase Edge Functions | Complex business logic, notifications |
| **Local Cache** | SQLite (existing) | Offline support, reduce API calls |

---

## 2. Database Schema Design

### 2.1 Core User Tables

```sql
-- Users (extends Supabase auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  
  -- From existing local user
  height REAL,
  weight REAL,
  goal TEXT CHECK (goal IN ('lose', 'maintain', 'gain')),
  bmr REAL,
  daily_target REAL,
  country TEXT DEFAULT 'VN',
  language TEXT DEFAULT 'vi',
  
  -- Community stats
  total_points INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  challenges_completed INTEGER DEFAULT 0,
  
  -- Privacy settings
  profile_visibility TEXT DEFAULT 'public' CHECK (profile_visibility IN ('public', 'friends', 'private')),
  show_stats_publicly BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User roles for moderation
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'moderator', 'user')),
  granted_by UUID REFERENCES public.profiles(id),
  granted_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, role)
);

-- Follow relationships
CREATE TABLE public.follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);
```

### 2.2 Groups & Challenges Tables

```sql
-- Groups (communities for specific goals)
CREATE TABLE public.groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  cover_image_url TEXT,
  
  -- Group settings
  visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'invite_only')),
  max_members INTEGER,
  
  -- Metadata
  created_by UUID REFERENCES public.profiles(id),
  member_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Group memberships
CREATE TABLE public.group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'moderator', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- Challenges
CREATE TABLE public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  
  -- Challenge info
  title TEXT NOT NULL,
  description TEXT,
  cover_image_url TEXT,
  
  -- Challenge type
  challenge_type TEXT NOT NULL CHECK (challenge_type IN (
    'calories_burned', 'steps', 'water_intake', 'sleep_hours',
    'workouts_completed', 'weight_loss', 'weight_gain', 'streak'
  )),
  target_value REAL NOT NULL,
  target_unit TEXT NOT NULL,
  
  -- Duration
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  
  -- Rewards
  points_reward INTEGER DEFAULT 0,
  badge_name TEXT,
  
  -- Status
  status TEXT DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'active', 'completed', 'cancelled')),
  
  -- Metadata
  created_by UUID REFERENCES public.profiles(id),
  participant_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Challenge participants
CREATE TABLE public.challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Progress tracking
  current_value REAL DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  
  -- Ranking
  rank INTEGER,
  
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);
```

### 2.3 Content & Social Tables

```sql
-- Posts (for sharing progress, meals, achievements)
CREATE TABLE public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  challenge_id UUID REFERENCES public.challenges(id) ON DELETE SET NULL,
  
  -- Content
  content TEXT NOT NULL,
  image_urls TEXT[], -- Array of image URLs
  
  -- Post type
  post_type TEXT DEFAULT 'general' CHECK (post_type IN (
    'general', 'meal', 'workout', 'achievement', 'challenge_progress', 'milestone'
  )),
  
  -- Linked data (for meal/workout posts)
  linked_data JSONB,
  
  -- Engagement
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  
  -- Visibility
  visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'group', 'followers', 'private')),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Comments
CREATE TABLE public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE, -- For replies
  
  content TEXT NOT NULL,
  like_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Likes
CREATE TABLE public.likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Either post_id or comment_id must be set
  CHECK ((post_id IS NOT NULL AND comment_id IS NULL) OR (post_id IS NULL AND comment_id IS NOT NULL)),
  UNIQUE(user_id, post_id),
  UNIQUE(user_id, comment_id)
);

-- Notifications
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Notification info
  type TEXT NOT NULL CHECK (type IN (
    'like', 'comment', 'follow', 'challenge_invite', 'challenge_start',
    'challenge_end', 'group_invite', 'achievement', 'mention', 'system'
  )),
  title TEXT NOT NULL,
  body TEXT,
  
  -- Related entities
  related_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  related_post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL,
  related_challenge_id UUID REFERENCES public.challenges(id) ON DELETE SET NULL,
  related_group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  
  -- Status
  is_read BOOLEAN DEFAULT false,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.4 Moderation Tables

```sql
-- Reports
CREATE TABLE public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  -- What is being reported
  reported_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  reported_post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  reported_comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  reported_group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  
  -- Report details
  reason TEXT NOT NULL CHECK (reason IN (
    'spam', 'harassment', 'hate_speech', 'inappropriate_content',
    'misinformation', 'impersonation', 'other'
  )),
  description TEXT,
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
  resolved_by UUID REFERENCES public.profiles(id),
  resolution_notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- User bans
CREATE TABLE public.bans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Ban details
  reason TEXT NOT NULL,
  banned_by UUID REFERENCES public.profiles(id),
  
  -- Duration
  is_permanent BOOLEAN DEFAULT false,
  expires_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.5 Local Data Tables (keep for offline sync)

```sql
-- User's personal health data (synced from local)
CREATE TABLE public.user_health_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Date-based data
  date DATE NOT NULL,
  
  -- Calories
  calo_intake REAL DEFAULT 0,
  calo_burned REAL DEFAULT 0,
  net_calo REAL DEFAULT 0,
  
  -- Water
  water_intake INTEGER DEFAULT 0,
  
  -- Weight (optional, user may not log daily)
  weight REAL,
  
  -- Sleep
  sleep_hours REAL,
  sleep_quality INTEGER,
  
  -- Workouts completed count
  workouts_completed INTEGER DEFAULT 0,
  
  -- Sync metadata
  synced_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, date)
);
```

---

## 3. Row Level Security (RLS) Policies

```sql
-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
-- ... (all tables)

-- Example: Posts visibility
CREATE POLICY "Users can view public posts"
  ON public.posts FOR SELECT
  USING (visibility = 'public');

CREATE POLICY "Users can view their own posts"
  ON public.posts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Group members can view group posts"
  ON public.posts FOR SELECT
  USING (
    visibility = 'group' AND
    EXISTS (
      SELECT 1 FROM public.group_members
      WHERE group_id = posts.group_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create their own posts"
  ON public.posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own posts"
  ON public.posts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts"
  ON public.posts FOR DELETE
  USING (auth.uid() = user_id);

-- Admin policies
CREATE POLICY "Admins can do anything"
  ON public.posts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_id = auth.uid() AND role IN ('admin', 'moderator')
    )
  );
```

---

## 4. Folder Structure

```
lib/
├── core/
│   ├── config/
│   │   ├── supabase_config.dart
│   │   └── app_config.dart
│   ├── constants/
│   │   ├── api_endpoints.dart
│   │   └── storage_keys.dart
│   └── utils/
│       ├── validators.dart
│       └── formatters.dart
│
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── database_service.dart (existing, for offline)
│   │   │   └── cache_service.dart
│   │   └── remote/
│   │       ├── supabase_auth_datasource.dart
│   │       ├── supabase_user_datasource.dart
│   │       ├── supabase_group_datasource.dart
│   │       ├── supabase_challenge_datasource.dart
│   │       ├── supabase_post_datasource.dart
│   │       └── supabase_notification_datasource.dart
│   │
│   ├── models/
│   │   ├── user_profile.dart (existing, extended)
│   │   ├── group.dart
│   │   ├── challenge.dart
│   │   ├── challenge_participant.dart
│   │   ├── post.dart
│   │   ├── comment.dart
│   │   ├── notification.dart
│   │   └── report.dart
│   │
│   └── repositories/
│       ├── auth_repository.dart
│       ├── user_repository.dart
│       ├── group_repository.dart
│       ├── challenge_repository.dart
│       ├── post_repository.dart
│       └── notification_repository.dart
│
├── domain/
│   ├── entities/
│   └── usecases/
│       ├── auth/
│       ├── community/
│       └── challenges/
│
├── presentation/
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   │
│   │   ├── community/
│   │   │   ├── feed_screen.dart
│   │   │   ├── post_detail_screen.dart
│   │   │   └── create_post_screen.dart
│   │   │
│   │   ├── groups/
│   │   │   ├── groups_screen.dart
│   │   │   ├── group_detail_screen.dart
│   │   │   └── create_group_screen.dart
│   │   │
│   │   ├── challenges/
│   │   │   ├── challenges_screen.dart
│   │   │   ├── challenge_detail_screen.dart
│   │   │   ├── challenge_leaderboard_screen.dart
│   │   │   └── create_challenge_screen.dart
│   │   │
│   │   ├── profile/
│   │   │   ├── user_profile_screen.dart
│   │   │   ├── edit_profile_screen.dart
│   │   │   └── settings_screen.dart
│   │   │
│   │   └── notifications/
│   │       └── notifications_screen.dart
│   │
│   ├── widgets/
│   │   ├── community/
│   │   │   ├── post_card.dart
│   │   │   ├── comment_tile.dart
│   │   │   └── user_avatar.dart
│   │   │
│   │   └── challenges/
│   │       ├── challenge_card.dart
│   │       └── leaderboard_tile.dart
│   │
│   └── providers/ (or blocs/)
│       ├── auth_provider.dart
│       ├── community_provider.dart
│       └── challenge_provider.dart
│
└── services/
    ├── sync_service.dart (local <-> cloud sync)
    ├── push_notification_service.dart
    └── analytics_service.dart
```

---

## 5. Migration Strategy

### Phase 1: Setup & Authentication (Week 1-2)
1. Create Supabase project
2. Implement authentication (email, Google, Apple)
3. Create `profiles` table with migration from local `users`
4. Add Supabase SDK to Flutter app
5. Implement login/register screens

### Phase 2: Data Sync Layer (Week 3-4)
1. Create hybrid data layer (local + remote)
2. Implement offline-first architecture
3. Background sync for health records
4. Conflict resolution strategy (last-write-wins with timestamp)

### Phase 3: Groups & Challenges (Week 5-7)
1. Create groups infrastructure
2. Implement challenge creation and joining
3. Real-time challenge progress updates
4. Leaderboard functionality

### Phase 4: Social Features (Week 8-9)
1. Post creation and feed
2. Comments and likes
3. Follow system
4. Notifications (in-app + push)

### Phase 5: Moderation & Polish (Week 10-11)
1. Report system
2. Admin dashboard (web)
3. Content moderation tools
4. Performance optimization

### Phase 6: Launch (Week 12)
1. Beta testing
2. Bug fixes
3. Production deployment

---

## 6. API Endpoints (Supabase Edge Functions)

```typescript
// supabase/functions/join-challenge/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { challenge_id } = await req.json();
  
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
  );

  const { data: { user } } = await supabase.auth.getUser();
  
  // Check if challenge is active
  const { data: challenge } = await supabase
    .from("challenges")
    .select("*")
    .eq("id", challenge_id)
    .single();
  
  if (challenge.status !== "active" && challenge.status !== "upcoming") {
    return new Response(JSON.stringify({ error: "Challenge not available" }), { status: 400 });
  }

  // Add participant
  const { error } = await supabase.from("challenge_participants").insert({
    challenge_id,
    user_id: user.id,
  });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 });
  }

  // Update participant count
  await supabase.rpc("increment_challenge_participants", { challenge_id });

  return new Response(JSON.stringify({ success: true }));
});
```

---

## 7. Realtime Subscriptions (Flutter)

```dart
// lib/services/realtime_service.dart
class RealtimeService {
  final SupabaseClient _supabase;
  
  RealtimeService(this._supabase);
  
  // Subscribe to challenge progress updates
  Stream<List<ChallengeParticipant>> watchChallengeLeaderboard(String challengeId) {
    return _supabase
      .from('challenge_participants')
      .stream(primaryKey: ['id'])
      .eq('challenge_id', challengeId)
      .order('current_value', ascending: false)
      .map((data) => data.map((e) => ChallengeParticipant.fromJson(e)).toList());
  }
  
  // Subscribe to new notifications
  Stream<Notification> watchNotifications(String userId) {
    return _supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((data) => data.map((e) => Notification.fromJson(e)).toList())
      .expand((list) => list);
  }
}
```

---

## 8. Local-Cloud Sync Strategy

```dart
// lib/services/sync_service.dart
class SyncService {
  final DatabaseService _local;
  final SupabaseClient _supabase;
  
  Future<void> syncHealthRecords() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    // Get local records not yet synced
    final localRecords = await _local.getUnsyncedRecords();
    
    for (final record in localRecords) {
      await _supabase.from('user_health_records').upsert({
        'user_id': userId,
        'date': record.date,
        'calo_intake': record.caloIntake,
        'calo_burned': record.caloBurned,
        'water_intake': record.waterIntake,
        'sleep_hours': record.sleepHours,
        'synced_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');
      
      await _local.markAsSynced(record.id);
    }
  }
}
```

---

## 9. Next Steps

1. **Set up Supabase project** - Create project, get API keys
2. **Run database migrations** - Execute SQL schema
3. **Add `supabase_flutter` package** - Integrate SDK
4. **Implement authentication screens** - Login, Register, Forgot Password
5. **Create sync layer** - Hybrid local/remote data access

Would you like me to start implementing any specific part of this architecture?
