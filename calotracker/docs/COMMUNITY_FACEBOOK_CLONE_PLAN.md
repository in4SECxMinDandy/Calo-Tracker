# Community Feature Improvements - Facebook Clone Plan

## Summary of Issues

User yêu cầu các sửa đổi lớn để clone Facebook features:

### 1. ✅ Group Owner CRUD Permissions - FIXED
**Problem:** Owner không có quyền edit/delete group

**Root Cause:** Group creators có `role='member'` thay vì `role='owner'`

**Solutions Applied:**
1. Migration `011_fix_group_owner_roles.sql` - Update existing owners
2. Updated `createGroup()` to check and update role if needed
3. Added debug logging

**Files:**
- `011_fix_group_owner_roles.sql` - NEW
- `community_service.dart` - Updated createGroup() logic

---

### 2. ⏳ Post Location Display - PENDING
**Problem:** Location được lấy (GPS: 22.0382859, 105.7738671) nhưng không hiển thị trong post

**Current State:** PostCard không render location field

**Solution Needed:**
1. Check if `Post` model has `location` field
2. Update PostCard to display location với icon
3. Format: "📍 Hà Nội, Việt Nam" hoặc coordinates nếu không có reverse geocoding

**Estimated Complexity:** LOW - Chỉ cần thêm UI widget

---

### 3. ⏳ Friends Feature - PENDING
**Problem:**
- Accept/Decline buttons không hoạt động
- Có thể do lỗi `updated_at` column trong friendships table

**Solution Needed:**
1. Check friendships table schema
2. Fix accept/decline logic
3. Test thoroughly

**Estimated Complexity:** MEDIUM

---

### 4. ⏳ Online Status Indicator - PENDING
**Problem:** Cần hiển thị online status như Facebook:
- Green dot khi online
- Gray dot + last seen khi offline

**Solution Needed:**
1. Track online/offline status trong database
2. Real-time presence với Supabase realtime
3. UI components:
   - Green dot badge trên avatar
   - "Active now" text
   - "Active 5m ago" text khi offline

**Estimated Complexity:** HIGH - Requires realtime setup

---

### 5. ⏳ Message Button Visibility - PENDING
**Problem:** Message button cần chỉ hiển thị khi đã là bạn bè

**Current State:** Có thể hiển thị cho tất cả users

**Solution Needed:**
1. Check friendship status before showing message button
2. Hide button nếu không phải friend

**Estimated Complexity:** LOW

---

## Facebook-like Features Requested

User muốn "clone tính năng bạn bè giống với Facebook":

### Friends System (như Facebook)
1. **Friend Request Flow:**
   - Send request → Pending
   - Accept → Friends
   - Decline → Rejected
   - Cancel request (nếu pending)
   - Unfriend

2. **Online Status:**
   - Green dot when online
   - Last seen time when offline
   - "Active now" badge

3. **Messaging:**
   - Message button chỉ hiển thị cho friends
   - Online indicator trong chat
   - Last seen trong chat list

4. **Friend List:**
   - All friends
   - Online friends
   - Friend requests (received)
   - Sent requests

### Community Features (như Facebook Groups)
1. **Group Permissions:**
   - Owner: Full CRUD
   - Admin: Approve members, delete posts
   - Member: Create posts, comment

2. **Group Posts:**
   - Location tagging
   - Photos
   - Reactions (like Facebook reactions?)
   - Comments with threading?

3. **Group Discovery:**
   - Suggested groups
   - Search groups
   - Categories

---

## Implementation Priority

### Phase 1: Critical Fixes (Ngay bây giờ)
1. ✅ Group owner role fix
2. ⏳ Post location display
3. ⏳ Friends accept/decline fix
4. ⏳ Message button visibility

### Phase 2: Online Status (Sau Phase 1)
1. Database schema for presence
2. Supabase realtime setup
3. UI components
4. Last seen tracking

### Phase 3: Enhanced Features (Optional)
1. Friend suggestions
2. Mutual friends
3. Friend lists (close friends, acquaintances)
4. Group roles and permissions refinement
5. Post reactions (beyond just like)

---

## Database Changes Needed

### 1. Presence/Online Status
```sql
CREATE TABLE public.user_presence (
  user_id UUID PRIMARY KEY REFERENCES profiles(id),
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Trigger to update updated_at
CREATE TRIGGER update_user_presence_updated_at
BEFORE UPDATE ON public.user_presence
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
```

### 2. Fix Friendships (if needed)
- Check if `updated_at` column exists
- Add if missing

### 3. Post Location
- Check if `posts` table has `location_lat`, `location_lng`, `location_name`
- Add if missing

---

## Files to Modify

### Services
1. `friends_service.dart` - Fix accept/decline, add presence tracking
2. `community_service.dart` - Already updated for group owner
3. `presence_service.dart` - NEW - Handle online/offline status

### Models
1. `post.dart` - Check location fields
2. `friendship.dart` - Check updated_at
3. `user_presence.dart` - NEW

### Screens
1. `post_card.dart` - Display location
2. `friends_screen.dart` - Fix accept/decline buttons
3. `chat_screen.dart` - Show online status
4. `user_profile_screen.dart` - Show message button conditionally

### Database
1. `012_add_user_presence.sql` - NEW
2. `013_fix_friendships.sql` - If needed
3. `014_add_post_location.sql` - If needed

---

## Testing Checklist

### Group Owner
- [ ] Create group → Check role = 'owner'
- [ ] Edit group as owner → Success
- [ ] Delete group as owner → Success
- [ ] Non-owner cannot edit/delete → Blocked

### Post Location
- [ ] Create post with location → Location displays
- [ ] Format looks good (icon + text)
- [ ] Click location opens map (optional)

### Friends
- [ ] Send friend request → Success
- [ ] Accept friend request → Becomes friend
- [ ] Decline friend request → Removed
- [ ] Message button shows only for friends

### Online Status
- [ ] User goes online → Green dot appears
- [ ] User goes offline → Gray dot + last seen
- [ ] Last seen updates correctly
- [ ] Realtime updates work

---

## Next Steps

**Tôi đề xuất làm theo thứ tự:**

1. ✅ **DONE:** Fix group owner role
2. **Next:** Show post location (EASY)
3. **Next:** Fix friends accept/decline (MEDIUM)
4. **Next:** Message button visibility (EASY)
5. **Later:** Online status system (HARD - requires architecture)

**Bạn muốn tôi:**
- A. Implement tất cả ngay (sẽ mất nhiều thời gian)
- B. Làm từng phase, test kỹ từng phase
- C. Chỉ làm critical fixes (Phase 1) trước

**Please confirm!** 🙏
