# Online Status System Implementation (Facebook-like)

## Overview
Implemented a real-time online/offline status system with Facebook-like green dot indicators and "last seen" timestamps.

## Database Schema

### Migration 014: user_presence table
```sql
CREATE TABLE IF NOT EXISTS public.user_presence (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Features:**
- Tracks online/offline status per user
- Records last seen timestamp
- Auto-updates timestamp via trigger
- RLS policies for security
- Helper functions: `set_user_online`, `set_user_offline`

## Architecture

### 1. UserPresence Model (`lib/models/user_presence.dart`)
```dart
class UserPresence {
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime updatedAt;

  String get lastSeenText {
    // Returns "Đang hoạt động" if online
    // Returns "Hoạt động X phút/giờ/ngày trước" if offline
  }
}
```

### 2. PresenceService (`lib/services/presence_service.dart`)
**Methods:**
- `goOnline()` - Set user online with heartbeat (30s interval)
- `goOffline()` - Set user offline, stop heartbeat
- `getUserPresence(userId)` - Get single user presence
- `getBatchPresence(userIds)` - Get multiple users' presence
- `subscribeToPresence(userIds)` - Subscribe to real-time updates
- `presenceStream` - Broadcast stream of presence changes

**Heartbeat Mechanism:**
- Timer runs every 30 seconds
- Calls `set_user_online` to keep status fresh
- Auto-stops when user goes offline

**Real-time Updates:**
- Uses Supabase `.stream()` with `.inFilter()`
- Broadcasts changes to all subscribers
- Updates UI automatically via StreamSubscription

### 3. OnlineIndicator Widget (`lib/widgets/online_indicator.dart`)
**Components:**
- `OnlineIndicator` - Simple green/gray dot
- `AvatarWithPresence` - CircleAvatar with overlaid presence dot

**Visual Design:**
- Green dot = online
- Gray dot = offline
- White border + shadow for contrast
- Positioned at bottom-right of avatar

## Integration Points

### 1. Community Hub Screen
```dart
_presenceService.goOnline();  // On app start
_presenceService.goOffline(); // On app close
```

### 2. User Profile Screen
- Shows avatar with online indicator
- Displays "Đang hoạt động" or "Hoạt động X phút trước"
- Subscribes to real-time presence updates for viewed user
- Updates automatically when status changes

### 3. Friends Screen
- Loads batch presence for all friends
- Subscribes to real-time updates
- Shows green/gray dot on each friend's avatar
- Updates instantly when friends go online/offline

## Flow Diagram

```
App Start
  └─> CommunityHubScreen.initState()
       └─> presenceService.goOnline()
            ├─> Insert/Update user_presence (is_online=true)
            └─> Start 30s heartbeat timer

User views Friend's Profile
  └─> UserProfileScreen._loadProfile()
       ├─> presenceService.getUserPresence(friendId)
       ├─> presenceService.subscribeToPresence([friendId])
       └─> Listen to presenceStream → Update UI

Friend goes online elsewhere
  └─> Supabase Realtime detects change
       └─> Stream emits new UserPresence
            └─> UserProfileScreen receives update → setState()
                 └─> UI shows green dot + "Đang hoạt động"

App Close
  └─> CommunityHubScreen.dispose()
       └─> presenceService.goOffline()
            ├─> Stop heartbeat timer
            └─> Update user_presence (is_online=false, last_seen=NOW())
```

## Testing Checklist

### Basic Functionality
- [ ] Run migration 014 in Supabase
- [ ] User shows as online when app is open
- [ ] Green dot appears on user's avatar
- [ ] User shows as offline after 30+ seconds of closing app
- [ ] Gray dot appears when offline

### Real-time Updates
- [ ] Open app on Device A, view friend's profile
- [ ] Open app on Device B (as the friend)
- [ ] Device A should show green dot instantly
- [ ] Close app on Device B
- [ ] Device A should show "Hoạt động X phút trước" after 30s

### Last Seen Text
- [ ] Shows "Đang hoạt động" when online
- [ ] Shows "Hoạt động X phút trước" for < 60 min
- [ ] Shows "Hoạt động X giờ trước" for < 24 hours
- [ ] Shows "Hoạt động X ngày trước" for >= 24 hours

### Friends List
- [ ] All friends show online/offline status
- [ ] Status updates in real-time without refresh
- [ ] Batch loading works for 10+ friends

### Edge Cases
- [ ] Handles null presence gracefully (no indicator shown)
- [ ] Handles network errors in heartbeat
- [ ] Doesn't crash on dispose with active subscriptions
- [ ] Works for users viewing their own profile (no presence shown)

## Database Functions

### set_user_online(p_user_id UUID)
```sql
INSERT INTO public.user_presence (user_id, is_online, last_seen)
VALUES (p_user_id, true, NOW())
ON CONFLICT (user_id) DO UPDATE
SET is_online = true, last_seen = NOW(), updated_at = NOW();
```

### set_user_offline(p_user_id UUID)
```sql
UPDATE public.user_presence
SET is_online = false, last_seen = NOW(), updated_at = NOW()
WHERE user_id = p_user_id;
```

## Performance Considerations

1. **Batch Loading:** Use `getBatchPresence()` for friends list instead of individual calls
2. **Heartbeat Interval:** 30 seconds balances freshness vs server load
3. **Stream Filtering:** Only subscribe to relevant user IDs
4. **Cleanup:** Always unsubscribe in dispose() to prevent memory leaks

## Future Enhancements

1. **Typing Indicators:** Show "đang nhập..." in chat
2. **Custom Status:** Let users set "Busy", "Away", etc.
3. **Last Active Location:** Show "Active on Mobile/Web"
4. **Offline Queue:** Queue heartbeats when network is down
5. **Presence in Groups:** Show online members count in group cards

## Related Files

### Models
- `lib/models/user_presence.dart`

### Services
- `lib/services/presence_service.dart`

### Widgets
- `lib/widgets/online_indicator.dart`

### Screens
- `lib/screens/community/community_hub_screen.dart`
- `lib/screens/community/user_profile_screen.dart`
- `lib/screens/community/friends_screen.dart`

### Migrations
- `supabase/migrations/014_add_user_presence.sql`

## Troubleshooting

### Green dot not showing
- Check if user called `goOnline()` on app start
- Verify migration 014 ran successfully
- Check Supabase RLS policies allow read access

### Status not updating in real-time
- Verify Supabase Realtime is enabled for `user_presence` table
- Check if subscription used correct `.inFilter()` syntax
- Ensure presenceStream is being listened to

### "Last seen" time is incorrect
- Check server timezone vs client timezone
- Verify heartbeat is running (check debug logs)
- Ensure `updated_at` trigger exists on table

## Migration Instructions

1. **Run migration in Supabase:**
   ```bash
   # Via Supabase CLI
   supabase db push

   # Or manually in SQL Editor
   # Copy contents of 014_add_user_presence.sql
   ```

2. **Enable Realtime:**
   - Go to Supabase Dashboard → Database → Replication
   - Enable replication for `user_presence` table

3. **Test RLS policies:**
   - Try reading user_presence as authenticated user
   - Should return presence data
   - Try as anonymous user - should fail

## Success Metrics

✅ **Completed:**
- Database schema with RLS policies
- UserPresence model with lastSeenText helper
- PresenceService with heartbeat and realtime
- OnlineIndicator widget components
- Integration in 3 screens (hub, profile, friends)
- Automatic online/offline on app lifecycle

🔄 **Pending:**
- Run migrations in production Supabase
- End-to-end testing with multiple devices
- Performance testing with 100+ friends

---

**Implementation Date:** February 9, 2026
**Status:** ✅ Code Complete - Pending Migration & Testing
