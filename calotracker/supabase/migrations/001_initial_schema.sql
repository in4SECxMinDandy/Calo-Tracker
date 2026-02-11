-- =============================================================================
-- CaloTracker Community Platform - Supabase Migration Script
-- =============================================================================
-- Run this script in Supabase Dashboard > SQL Editor
-- Version: 1.0.0
-- Date: 2026-02-01
-- =============================================================================
-- ============================================
-- PART 1: CORE USER TABLES
-- ============================================
-- Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  -- Health data (migrated from local)
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
  followers_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  -- Privacy settings
  profile_visibility TEXT DEFAULT 'public' CHECK (
    profile_visibility IN ('public', 'friends', 'private')
  ),
  show_stats_publicly BOOLEAN DEFAULT true,
  allow_challenge_invites BOOLEAN DEFAULT true,
  allow_group_invites BOOLEAN DEFAULT true,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Create index for username lookup
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
-- User roles for moderation
CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'moderator', 'user')),
  granted_by UUID REFERENCES public.profiles(id),
  granted_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, role)
);
CREATE INDEX IF NOT EXISTS idx_user_roles_user ON public.user_roles(user_id);
-- Follow relationships
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows(following_id);
-- ============================================
-- PART 2: GROUPS TABLES
-- ============================================
-- Groups (communities for specific goals)
CREATE TABLE IF NOT EXISTS public.groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  cover_image_url TEXT,
  category TEXT CHECK (
    category IN (
      'weight_loss',
      'muscle_gain',
      'healthy_eating',
      'running',
      'fitness',
      'general'
    )
  ),
  -- Group settings
  visibility TEXT DEFAULT 'public' CHECK (
    visibility IN ('public', 'private', 'invite_only')
  ),
  max_members INTEGER,
  require_approval BOOLEAN DEFAULT false,
  -- Metadata
  created_by UUID REFERENCES public.profiles(id),
  member_count INTEGER DEFAULT 0,
  post_count INTEGER DEFAULT 0,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_groups_slug ON public.groups(slug);
CREATE INDEX IF NOT EXISTS idx_groups_category ON public.groups(category);
CREATE INDEX IF NOT EXISTS idx_groups_visibility ON public.groups(visibility);
-- Group memberships
CREATE TABLE IF NOT EXISTS public.group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (
    role IN ('owner', 'admin', 'moderator', 'member')
  ),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'pending', 'banned')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_group_members_group ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON public.group_members(user_id);
-- Group invites
CREATE TABLE IF NOT EXISTS public.group_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  invited_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  invited_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (
    status IN ('pending', 'accepted', 'declined', 'expired')
  ),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  UNIQUE(group_id, invited_user_id)
);
-- ============================================
-- PART 3: CHALLENGES TABLES
-- ============================================
-- Challenges
CREATE TABLE IF NOT EXISTS public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  -- Challenge info
  title TEXT NOT NULL,
  description TEXT,
  cover_image_url TEXT,
  -- Challenge type and target
  challenge_type TEXT NOT NULL CHECK (
    challenge_type IN (
      'calories_burned',
      -- Đốt cháy calo
      'calories_intake',
      -- Nạp calo (cho người tăng cân)
      'steps',
      -- Số bước chân
      'water_intake',
      -- Uống nước (ml)
      'sleep_hours',
      -- Giờ ngủ
      'workouts_completed',
      -- Số buổi tập
      'weight_loss',
      -- Giảm cân (kg)
      'weight_gain',
      -- Tăng cân (kg)
      'streak',
      -- Chuỗi ngày liên tiếp
      'meals_logged' -- Số bữa ăn ghi nhận
    )
  ),
  target_value REAL NOT NULL,
  target_unit TEXT NOT NULL,
  -- Duration
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  -- Rewards
  points_reward INTEGER DEFAULT 100,
  badge_name TEXT,
  badge_icon TEXT,
  -- Visibility
  visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'group', 'invite_only')),
  -- Status
  status TEXT DEFAULT 'upcoming' CHECK (
    status IN (
      'draft',
      'upcoming',
      'active',
      'completed',
      'cancelled'
    )
  ),
  -- Metadata
  created_by UUID REFERENCES public.profiles(id),
  participant_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_challenges_group ON public.challenges(group_id);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON public.challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenges_type ON public.challenges(challenge_type);
CREATE INDEX IF NOT EXISTS idx_challenges_dates ON public.challenges(start_date, end_date);
-- Challenge participants
CREATE TABLE IF NOT EXISTS public.challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  -- Progress tracking
  current_value REAL DEFAULT 0,
  daily_progress JSONB DEFAULT '[]'::jsonb,
  -- Array of {date, value}
  -- Completion status
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  -- Ranking (updated by trigger/function)
  rank INTEGER,
  -- Timestamps
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_challenge_participants_challenge ON public.challenge_participants(challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participants_user ON public.challenge_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participants_rank ON public.challenge_participants(challenge_id, rank);
-- ============================================
-- PART 4: POSTS & SOCIAL TABLES
-- ============================================
-- Posts
CREATE TABLE IF NOT EXISTS public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  group_id UUID REFERENCES public.groups(id) ON DELETE
  SET NULL,
    challenge_id UUID REFERENCES public.challenges(id) ON DELETE
  SET NULL,
    -- Content
    content TEXT NOT NULL,
    image_urls TEXT [] DEFAULT '{}',
    -- Post type
    post_type TEXT DEFAULT 'general' CHECK (
      post_type IN (
        'general',
        -- Bài đăng thông thường
        'meal',
        -- Chia sẻ bữa ăn
        'workout',
        -- Chia sẻ buổi tập
        'achievement',
        -- Thành tựu
        'challenge_progress',
        -- Tiến độ thử thách
        'milestone',
        -- Cột mốc (VD: giảm 5kg)
        'question' -- Câu hỏi
      )
    ),
    -- Linked data (JSON for flexibility)
    linked_data JSONB,
    -- Engagement counters (denormalized for performance)
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    -- Visibility
    visibility TEXT DEFAULT 'public' CHECK (
      visibility IN ('public', 'group', 'followers', 'private')
    ),
    -- Moderation
    is_pinned BOOLEAN DEFAULT false,
    is_hidden BOOLEAN DEFAULT false,
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_posts_user ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_group ON public.posts(group_id);
CREATE INDEX IF NOT EXISTS idx_posts_challenge ON public.posts(challenge_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON public.posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_visibility ON public.posts(visibility);
-- Comments
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  like_count INTEGER DEFAULT 0,
  -- Moderation
  is_hidden BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_comments_post ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user ON public.comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON public.comments(parent_id);
-- Likes (unified for posts and comments)
CREATE TABLE IF NOT EXISTS public.likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  -- Constraint: must like either post OR comment, not both
  CHECK (
    (
      post_id IS NOT NULL
      AND comment_id IS NULL
    )
    OR (
      post_id IS NULL
      AND comment_id IS NOT NULL
    )
  ),
  UNIQUE(user_id, post_id),
  UNIQUE(user_id, comment_id)
);
CREATE INDEX IF NOT EXISTS idx_likes_user ON public.likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_post ON public.likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_comment ON public.likes(comment_id);
-- ============================================
-- PART 5: NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  -- Notification info
  type TEXT NOT NULL CHECK (
    type IN (
      'like',
      -- Ai đó thích bài viết/bình luận
      'comment',
      -- Ai đó bình luận
      'follow',
      -- Ai đó theo dõi
      'mention',
      -- Được nhắc đến
      'challenge_invite',
      -- Được mời tham gia thử thách
      'challenge_start',
      -- Thử thách bắt đầu
      'challenge_end',
      -- Thử thách kết thúc
      'challenge_rank',
      -- Thay đổi thứ hạng
      'group_invite',
      -- Được mời vào nhóm
      'group_join',
      -- Ai đó tham gia nhóm
      'achievement',
      -- Đạt thành tựu
      'milestone',
      -- Đạt cột mốc
      'system' -- Thông báo hệ thống
    )
  ),
  title TEXT NOT NULL,
  body TEXT,
  -- Deep link data
  action_url TEXT,
  -- Related entities (nullable)
  actor_id UUID REFERENCES public.profiles(id) ON DELETE
  SET NULL,
    related_post_id UUID REFERENCES public.posts(id) ON DELETE
  SET NULL,
    related_comment_id UUID REFERENCES public.comments(id) ON DELETE
  SET NULL,
    related_challenge_id UUID REFERENCES public.challenges(id) ON DELETE
  SET NULL,
    related_group_id UUID REFERENCES public.groups(id) ON DELETE
  SET NULL,
    -- Status
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, is_read)
WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);
-- ============================================
-- PART 6: MODERATION TABLES
-- ============================================
-- Reports
CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES public.profiles(id) ON DELETE
  SET NULL,
    -- What is being reported (only one should be set)
    reported_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    reported_comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    reported_group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    -- Report details
    reason TEXT NOT NULL CHECK (
      reason IN (
        'spam',
        -- Spam
        'harassment',
        -- Quấy rối
        'hate_speech',
        -- Ngôn từ thù địch
        'inappropriate_content',
        -- Nội dung không phù hợp
        'misinformation',
        -- Thông tin sai lệch
        'impersonation',
        -- Mạo danh
        'self_harm',
        -- Tự gây hại
        'other' -- Khác
      )
    ),
    description TEXT,
    -- Status
    status TEXT DEFAULT 'pending' CHECK (
      status IN ('pending', 'reviewing', 'resolved', 'dismissed')
    ),
    -- Resolution
    resolved_by UUID REFERENCES public.profiles(id),
    resolution_notes TEXT,
    action_taken TEXT CHECK (
      action_taken IN (
        'none',
        'warning',
        'content_removed',
        'user_banned',
        'escalated'
      )
    ),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON public.reports(reporter_id);
-- User bans
CREATE TABLE IF NOT EXISTS public.bans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  -- Ban details
  reason TEXT NOT NULL,
  banned_by UUID REFERENCES public.profiles(id),
  related_report_id UUID REFERENCES public.reports(id),
  -- Duration
  ban_type TEXT DEFAULT 'temporary' CHECK (ban_type IN ('temporary', 'permanent')),
  expires_at TIMESTAMPTZ,
  -- Status
  is_active BOOLEAN DEFAULT true,
  lifted_by UUID REFERENCES public.profiles(id),
  lifted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_bans_user ON public.bans(user_id);
CREATE INDEX IF NOT EXISTS idx_bans_active ON public.bans(user_id, is_active)
WHERE is_active = true;
-- ============================================
-- PART 7: HEALTH DATA SYNC TABLE
-- ============================================
-- User's personal health data (synced from local app)
CREATE TABLE IF NOT EXISTS public.user_health_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  -- Date (one record per day per user)
  date DATE NOT NULL,
  -- Calories
  calo_intake REAL DEFAULT 0,
  calo_burned REAL DEFAULT 0,
  net_calo REAL DEFAULT 0,
  -- Water (ml)
  water_intake INTEGER DEFAULT 0,
  -- Weight (optional)
  weight REAL,
  -- Sleep
  sleep_hours REAL,
  sleep_quality INTEGER CHECK (
    sleep_quality BETWEEN 1 AND 5
  ),
  -- Activity
  workouts_completed INTEGER DEFAULT 0,
  steps INTEGER DEFAULT 0,
  -- Meals logged count
  meals_logged INTEGER DEFAULT 0,
  -- Sync metadata
  synced_at TIMESTAMPTZ DEFAULT NOW(),
  local_updated_at TIMESTAMPTZ,
  UNIQUE(user_id, date)
);
CREATE INDEX IF NOT EXISTS idx_health_records_user_date ON public.user_health_records(user_id, date DESC);
-- ============================================
-- PART 8: ACHIEVEMENTS & BADGES
-- ============================================
CREATE TABLE IF NOT EXISTS public.achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT NOT NULL,
  category TEXT CHECK (
    category IN (
      'challenge',
      'streak',
      'milestone',
      'social',
      'special'
    )
  ),
  -- Requirements
  requirement_type TEXT NOT NULL,
  requirement_value INTEGER NOT NULL,
  points INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES public.achievements(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON public.user_achievements(user_id);
-- ============================================
-- PART 9: HELPER FUNCTIONS
-- ============================================
-- Function to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER AS $$ BEGIN
INSERT INTO public.profiles (id, username, display_name, avatar_url)
VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'username',
      'user_' || substr(NEW.id::text, 1, 8)
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      'Người dùng mới'
    ),
    NEW.raw_user_meta_data->>'avatar_url'
  );
-- Give default 'user' role
INSERT INTO public.user_roles (user_id, role)
VALUES (NEW.id, 'user');
RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER
INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at() RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Apply updated_at triggers
-- Apply updated_at triggers
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE
UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
DROP TRIGGER IF EXISTS update_groups_updated_at ON public.groups;
CREATE TRIGGER update_groups_updated_at BEFORE
UPDATE ON public.groups FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
DROP TRIGGER IF EXISTS update_challenges_updated_at ON public.challenges;
CREATE TRIGGER update_challenges_updated_at BEFORE
UPDATE ON public.challenges FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
DROP TRIGGER IF EXISTS update_posts_updated_at ON public.posts;
CREATE TRIGGER update_posts_updated_at BEFORE
UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
-- Function to increment/decrement counters
CREATE OR REPLACE FUNCTION public.increment_counter(
    table_name TEXT,
    column_name TEXT,
    row_id UUID,
    amount INTEGER DEFAULT 1
  ) RETURNS VOID AS $$ BEGIN EXECUTE format(
    'UPDATE public.%I SET %I = %I + $1 WHERE id = $2',
    table_name,
    column_name,
    column_name
  ) USING amount,
  row_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Function to update challenge participant ranks
CREATE OR REPLACE FUNCTION public.update_challenge_ranks(p_challenge_id UUID) RETURNS VOID AS $$ BEGIN WITH ranked AS (
    SELECT id,
      ROW_NUMBER() OVER (
        ORDER BY current_value DESC,
          updated_at ASC
      ) as new_rank
    FROM public.challenge_participants
    WHERE challenge_id = p_challenge_id
  )
UPDATE public.challenge_participants cp
SET rank = ranked.new_rank
FROM ranked
WHERE cp.id = ranked.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- ============================================
-- PART 10: ROW LEVEL SECURITY (RLS)
-- ============================================
-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
-- ============================================
-- PROFILES POLICIES
-- ============================================
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR
SELECT USING (profile_visibility = 'public');
CREATE POLICY "Users can view their own profile" ON public.profiles FOR
SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR
UPDATE USING (auth.uid() = id);
-- ============================================
-- FOLLOWS POLICIES
-- ============================================
CREATE POLICY "Anyone can view follows" ON public.follows FOR
SELECT USING (true);
CREATE POLICY "Users can create their own follows" ON public.follows FOR
INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can delete their own follows" ON public.follows FOR DELETE USING (auth.uid() = follower_id);
-- ============================================
-- GROUPS POLICIES
-- ============================================
CREATE POLICY "Public groups are viewable by everyone" ON public.groups FOR
SELECT USING (visibility = 'public');
CREATE POLICY "Members can view private groups" ON public.groups FOR
SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.group_members
      WHERE group_id = groups.id
        AND user_id = auth.uid()
    )
  );
CREATE POLICY "Users can create groups" ON public.groups FOR
INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Group owners/admins can update" ON public.groups FOR
UPDATE USING (
    EXISTS (
      SELECT 1
      FROM public.group_members
      WHERE group_id = groups.id
        AND user_id = auth.uid()
        AND role IN ('owner', 'admin')
    )
  );
-- ============================================
-- GROUP MEMBERS POLICIES
-- ============================================
CREATE POLICY "Anyone can view public group members" ON public.group_members FOR
SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.groups
      WHERE id = group_members.group_id
        AND visibility = 'public'
    )
  );
CREATE POLICY "Members can view group members" ON public.group_members FOR
SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.group_members gm
      WHERE gm.group_id = group_members.group_id
        AND gm.user_id = auth.uid()
    )
  );
CREATE POLICY "Users can join public groups" ON public.group_members FOR
INSERT WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1
      FROM public.groups
      WHERE id = group_id
        AND visibility = 'public'
    )
  );
CREATE POLICY "Users can leave groups" ON public.group_members FOR DELETE USING (auth.uid() = user_id);
-- ============================================
-- CHALLENGES POLICIES
-- ============================================
CREATE POLICY "Public challenges are viewable" ON public.challenges FOR
SELECT USING (
    visibility = 'public'
    OR visibility = 'group'
  );
CREATE POLICY "Users can create challenges" ON public.challenges FOR
INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Creators can update challenges" ON public.challenges FOR
UPDATE USING (auth.uid() = created_by);
-- ============================================
-- CHALLENGE PARTICIPANTS POLICIES
-- ============================================
CREATE POLICY "Anyone can view challenge participants" ON public.challenge_participants FOR
SELECT USING (true);
CREATE POLICY "Users can join challenges" ON public.challenge_participants FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own progress" ON public.challenge_participants FOR
UPDATE USING (auth.uid() = user_id);
-- ============================================
-- POSTS POLICIES
-- ============================================
CREATE POLICY "Public posts are viewable" ON public.posts FOR
SELECT USING (
    visibility = 'public'
    AND is_hidden = false
  );
CREATE POLICY "Users can view their own posts" ON public.posts FOR
SELECT USING (auth.uid() = user_id);
CREATE POLICY "Group members can view group posts" ON public.posts FOR
SELECT USING (
    visibility = 'group'
    AND is_hidden = false
    AND EXISTS (
      SELECT 1
      FROM public.group_members
      WHERE group_id = posts.group_id
        AND user_id = auth.uid()
    )
  );
CREATE POLICY "Users can create posts" ON public.posts FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own posts" ON public.posts FOR
UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own posts" ON public.posts FOR DELETE USING (auth.uid() = user_id);
-- ============================================
-- COMMENTS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Anyone can view non-hidden comments" ON public.comments;
CREATE POLICY "Anyone can view non-hidden comments" ON public.comments FOR
SELECT USING (is_hidden = false);
DROP POLICY IF EXISTS "Users can create comments" ON public.comments;
CREATE POLICY "Users can create comments" ON public.comments FOR
INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own comments" ON public.comments;
CREATE POLICY "Users can update their own comments" ON public.comments FOR
UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete their own comments" ON public.comments;
CREATE POLICY "Users can delete their own comments" ON public.comments FOR DELETE USING (auth.uid() = user_id);
-- ============================================
-- LIKES POLICIES
-- ============================================
DROP POLICY IF EXISTS "Anyone can view likes" ON public.likes;
CREATE POLICY "Anyone can view likes" ON public.likes FOR
SELECT USING (true);
DROP POLICY IF EXISTS "Users can create likes" ON public.likes;
CREATE POLICY "Users can create likes" ON public.likes FOR
INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete their own likes" ON public.likes;
CREATE POLICY "Users can delete their own likes" ON public.likes FOR DELETE USING (auth.uid() = user_id);
-- ============================================
-- NOTIFICATIONS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR
SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR
UPDATE USING (auth.uid() = user_id);
-- ============================================
-- REPORTS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can create reports" ON public.reports;
CREATE POLICY "Users can create reports" ON public.reports FOR
INSERT WITH CHECK (auth.uid() = reporter_id);
DROP POLICY IF EXISTS "Users can view their own reports" ON public.reports;
CREATE POLICY "Users can view their own reports" ON public.reports FOR
SELECT USING (auth.uid() = reporter_id);
DROP POLICY IF EXISTS "Moderators can view all reports" ON public.reports;
CREATE POLICY "Moderators can view all reports" ON public.reports FOR
SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.user_roles
      WHERE user_id = auth.uid()
        AND role IN ('admin', 'moderator')
    )
  );
DROP POLICY IF EXISTS "Moderators can update reports" ON public.reports;
CREATE POLICY "Moderators can update reports" ON public.reports FOR
UPDATE USING (
    EXISTS (
      SELECT 1
      FROM public.user_roles
      WHERE user_id = auth.uid()
        AND role IN ('admin', 'moderator')
    )
  );
-- ============================================
-- USER HEALTH RECORDS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view their own health records" ON public.user_health_records;
CREATE POLICY "Users can view their own health records" ON public.user_health_records FOR
SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert their own health records" ON public.user_health_records;
CREATE POLICY "Users can insert their own health records" ON public.user_health_records FOR
INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own health records" ON public.user_health_records;
CREATE POLICY "Users can update their own health records" ON public.user_health_records FOR
UPDATE USING (auth.uid() = user_id);
-- ============================================
-- ACHIEVEMENTS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Anyone can view achievements" ON public.achievements;
CREATE POLICY "Anyone can view achievements" ON public.achievements FOR
SELECT USING (true);
DROP POLICY IF EXISTS "Users can view their earned achievements" ON public.user_achievements;
CREATE POLICY "Users can view their earned achievements" ON public.user_achievements FOR
SELECT USING (auth.uid() = user_id);
-- ============================================
-- ADMIN OVERRIDE POLICIES
-- ============================================
DROP POLICY IF EXISTS "Admins have full access to profiles" ON public.profiles;
CREATE POLICY "Admins have full access to profiles" ON public.profiles FOR ALL USING (
  EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = 'admin'
  )
);
DROP POLICY IF EXISTS "Admins have full access to posts" ON public.posts;
CREATE POLICY "Admins have full access to posts" ON public.posts FOR ALL USING (
  EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = 'admin'
  )
);
DROP POLICY IF EXISTS "Admins have full access to comments" ON public.comments;
CREATE POLICY "Admins have full access to comments" ON public.comments FOR ALL USING (
  EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = 'admin'
  )
);
DROP POLICY IF EXISTS "Admins have full access to bans" ON public.bans;
CREATE POLICY "Admins have full access to bans" ON public.bans FOR ALL USING (
  EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = 'admin'
  )
);
-- ============================================
-- PART 11: SEED DATA - DEFAULT ACHIEVEMENTS
-- ============================================
INSERT INTO public.achievements (
    name,
    description,
    icon,
    category,
    requirement_type,
    requirement_value,
    points
  )
VALUES (
    'Người mới',
    'Tạo tài khoản thành công',
    '🎉',
    'milestone',
    'signup',
    1,
    10
  ),
  (
    'Bước đầu',
    'Hoàn thành thử thách đầu tiên',
    '🏆',
    'challenge',
    'challenges_completed',
    1,
    50
  ),
  (
    'Chiến binh',
    'Hoàn thành 10 thử thách',
    '⚔️',
    'challenge',
    'challenges_completed',
    10,
    200
  ),
  (
    'Streak 7 ngày',
    'Ghi nhận liên tục 7 ngày',
    '🔥',
    'streak',
    'streak_days',
    7,
    100
  ),
  (
    'Streak 30 ngày',
    'Ghi nhận liên tục 30 ngày',
    '💪',
    'streak',
    'streak_days',
    30,
    500
  ),
  (
    'Kết nối',
    'Có 10 người theo dõi',
    '👥',
    'social',
    'followers',
    10,
    50
  ),
  (
    'Ảnh hưởng',
    'Có 100 người theo dõi',
    '🌟',
    'social',
    'followers',
    100,
    200
  ),
  (
    'Chia sẻ',
    'Đăng 10 bài viết',
    '📝',
    'social',
    'posts',
    10,
    50
  ),
  (
    'Giảm 5kg',
    'Giảm được 5kg cân nặng',
    '⚖️',
    'milestone',
    'weight_lost',
    5,
    300
  ),
  (
    'Giảm 10kg',
    'Giảm được 10kg cân nặng',
    '🎯',
    'milestone',
    'weight_lost',
    10,
    500
  ) ON CONFLICT DO NOTHING;
-- ============================================
-- DONE!
-- ============================================
COMMENT ON SCHEMA public IS 'CaloTracker Community Platform - Schema created on 2026-02-01';