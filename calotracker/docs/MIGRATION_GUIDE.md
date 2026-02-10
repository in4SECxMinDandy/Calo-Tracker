# Migration Guide - Run Supabase Migrations

## Overview
You need to run migrations 011-014 to enable the new Facebook-like features.

---

## Option 1: Supabase Dashboard (Recommended)

### Step 1: Open Supabase Dashboard
1. Go to https://app.supabase.com
2. Select your project
3. Click on **SQL Editor** in the left sidebar

### Step 2: Run Migration 011 - Fix Group Owner Roles
1. Click **New query**
2. Copy the contents of `supabase/migrations/011_fix_group_owner_roles.sql`
3. Paste into the SQL editor
4. Click **Run** (or press `Ctrl+Enter`)
5. Verify success message appears

### Step 3: Run Migration 012 - Add Post Location
1. Click **New query**
2. Copy the contents of `supabase/migrations/012_add_post_location.sql`
3. Paste into the SQL editor
4. Click **Run**
5. Verify columns added successfully

### Step 4: Run Migration 013 - Add Friendships Trigger
1. Click **New query**
2. Copy the contents of `supabase/migrations/013_add_friendships_trigger.sql`
3. Paste into the SQL editor
4. Click **Run**
5. Verify trigger created successfully

### Step 5: Run Migration 014 - Add User Presence
1. Click **New query**
2. Copy the contents of `supabase/migrations/014_add_user_presence.sql`
3. Paste into the SQL editor
4. Click **Run**
5. Verify table, policies, and functions created

### Step 6: Enable Realtime for user_presence
1. In Supabase Dashboard, go to **Database** → **Replication**
2. Find the `user_presence` table
3. Toggle **Realtime** to **ON**
4. Click **Save**

---

## Option 2: Supabase CLI

### Prerequisites
```bash
# Install Supabase CLI if not installed
npm install -g supabase

# Or with Homebrew (macOS)
brew install supabase
```

### Step 1: Check Supabase Status
```bash
cd calotracker
supabase status
```

### Step 2: Apply All Pending Migrations
```bash
supabase db push
```

This will automatically run all migration files in order (011-014).

### Step 3: Verify Migrations
```bash
# Check migration history
supabase migration list
```

You should see:
```
011_fix_group_owner_roles.sql ✓ Applied
012_add_post_location.sql ✓ Applied
013_add_friendships_trigger.sql ✓ Applied
014_add_user_presence.sql ✓ Applied
```

### Step 4: Enable Realtime (Manual)
- Still need to enable Realtime via Dashboard (see Option 1, Step 6)

---

## Option 3: Manual SQL (Advanced)

If you don't have Supabase CLI and prefer terminal:

### Using psql (PostgreSQL command line)
```bash
# Get connection string from Supabase Dashboard → Settings → Database
psql "postgresql://postgres:[YOUR-PASSWORD]@[YOUR-PROJECT-REF].supabase.co:5432/postgres"

# Run each migration
\i supabase/migrations/011_fix_group_owner_roles.sql
\i supabase/migrations/012_add_post_location.sql
\i supabase/migrations/013_add_friendships_trigger.sql
\i supabase/migrations/014_add_user_presence.sql

# Exit
\q
```

---

## Verification Steps

### 1. Check Tables Exist
Run in SQL Editor:
```sql
-- Should return all tables including user_presence
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

### 2. Check Post Location Columns
```sql
-- Should show location_lat, location_lng, location_name
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'posts'
  AND column_name LIKE 'location%';
```

### 3. Check user_presence Table
```sql
-- Should return 0 rows initially
SELECT * FROM user_presence;
```

### 4. Test Helper Functions
```sql
-- Replace with your user ID
SELECT set_user_online('YOUR-USER-ID-HERE');

-- Verify you're online
SELECT * FROM user_presence WHERE user_id = 'YOUR-USER-ID-HERE';
-- Should show: is_online = true

-- Go offline
SELECT set_user_offline('YOUR-USER-ID-HERE');

-- Verify
SELECT * FROM user_presence WHERE user_id = 'YOUR-USER-ID-HERE';
-- Should show: is_online = false, last_seen = recent timestamp
```

### 5. Check Friendships Trigger
```sql
-- Should return trigger info
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE trigger_name = 'update_friendships_updated_at';
```

### 6. Verify Group Owner Roles
```sql
-- All group creators should have role='owner'
SELECT g.id, g.name, gm.user_id, gm.role
FROM groups g
JOIN group_members gm ON g.id = gm.group_id
WHERE g.created_by = gm.user_id;
-- All rows should show role = 'owner'
```

---

## Troubleshooting

### Error: "relation already exists"
- **Cause:** Migration already ran partially
- **Fix:** Check which parts succeeded and manually run remaining statements

### Error: "permission denied"
- **Cause:** Insufficient permissions
- **Fix:** Ensure you're using postgres role (from Dashboard SQL Editor)

### Error: "function does not exist"
- **Cause:** Migration 014 didn't run completely
- **Fix:** Re-run migration 014 in SQL Editor

### Realtime not working
- **Check 1:** Verify Realtime is enabled in Dashboard → Database → Replication
- **Check 2:** Check Supabase status page for outages
- **Check 3:** Verify RLS policies allow SELECT on user_presence

### Green dot not appearing
- **Check 1:** Verify migration 014 ran successfully
- **Check 2:** Check Flutter logs for presenceService errors
- **Check 3:** Verify app calls `presenceService.goOnline()` on start

---

## Migration File Contents

### 011_fix_group_owner_roles.sql
- Updates existing group creators to have role='owner'
- Fixes CRUD permission issues

### 012_add_post_location.sql
- Adds location columns to posts table
- Enables post location display

### 013_add_friendships_trigger.sql
- Adds auto-update trigger for friendships.updated_at
- Fixes friend accept/decline functionality

### 014_add_user_presence.sql
- Creates user_presence table
- Adds RLS policies
- Creates helper functions: set_user_online, set_user_offline
- Adds auto-update trigger

---

## Post-Migration Testing

### Test 1: Create Group (Owner Permissions)
1. Open app → Community → Groups
2. Create a new group
3. Verify you can edit/delete posts in your group
4. **Expected:** Full CRUD permissions as owner

### Test 2: Post with Location
1. Create a new post with location enabled
2. Check if location appears below post metadata
3. **Expected:** See "📍 [Location Name]" badge

### Test 3: Friend Request Accept/Decline
1. Send friend request to another user
2. That user accepts/declines
3. Check friend request disappears
4. **Expected:** Request handled successfully

### Test 4: Online Status
1. Open app on Device A
2. Go to Friends screen
3. Open app on Device B (as a friend)
4. **Expected:** Device A shows green dot on Device B's avatar within 1-2 seconds

### Test 5: Last Seen
1. Close app on Device B
2. Wait 30+ seconds
3. Check Device A
4. **Expected:** Shows "Hoạt động X phút trước"

---

## Rollback Instructions (If Needed)

### To rollback all changes:
```sql
-- Drop user_presence (014)
DROP TABLE IF EXISTS user_presence CASCADE;
DROP FUNCTION IF EXISTS set_user_online(UUID);
DROP FUNCTION IF EXISTS set_user_offline(UUID);

-- Drop friendships trigger (013)
DROP TRIGGER IF EXISTS update_friendships_updated_at ON friendships;

-- Remove post location columns (012)
ALTER TABLE posts
  DROP COLUMN IF EXISTS location_lat,
  DROP COLUMN IF EXISTS location_lng,
  DROP COLUMN IF EXISTS location_name;

-- Rollback group owner roles (011) - CANNOT EASILY ROLLBACK
-- (Would need to restore original roles from backup)
```

⚠️ **Warning:** Only rollback if absolutely necessary. Better to fix forward.

---

## Success Criteria

✅ All 4 migrations run without errors
✅ Tables and triggers verified
✅ Realtime enabled for user_presence
✅ Test cases pass
✅ No console errors in Flutter app

---

**Next Step After Migrations:** Test all features end-to-end with multiple devices!

**Documentation:** See `FACEBOOK_FEATURES_SUMMARY.md` for implementation details.
