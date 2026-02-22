-- =============================================================================
-- CaloTracker - COMPREHENSIVE FIX FOR ALL DATABASE ISSUES
-- =============================================================================
-- Run this script in Supabase Dashboard > SQL Editor
-- Date: 2026-02-12
--
-- This migration fixes:
-- 1. ✅ Group join error (RLS violation on group_members)
-- 2. ✅ Missing update_presence() function (PGRST202)
-- 3. ✅ Friendships foreign key relationships (PGRST200) - already fixed in 033
-- 4. ✅ Enable Realtime for friendships, messages, notifications
-- 5. ✅ Add status column to profiles if missing
-- =============================================================================

-- =============================================================================
-- PART 1: Fix Profiles Table - Add Status Column
-- =============================================================================

-- Add status column to profiles if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'profiles'
    AND column_name = 'status'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN status TEXT DEFAULT 'offline';
    ALTER TABLE public.profiles ADD CONSTRAINT profiles_status_check
      CHECK (status IN ('online', 'offline', 'away'));
  END IF;
END $$;

-- Ensure is_online and last_seen exist (should already exist from migration 002)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ;

-- Add index for quick status lookups
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_is_online ON public.profiles(is_online);

COMMENT ON COLUMN public.profiles.status IS 'User online status: online, offline, away';

-- =============================================================================
-- PART 2: Create update_presence() Function (Fixes PGRST202)
-- =============================================================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.update_presence(text);

-- Create the update_presence function that your Flutter app calls
CREATE OR REPLACE FUNCTION public.update_presence(p_status TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Allows function to bypass RLS
AS $$
BEGIN
  -- Validate status input
  IF p_status NOT IN ('online', 'offline', 'away') THEN
    RAISE EXCEPTION 'Invalid status: must be online, offline, or away';
  END IF;

  -- Update profiles table
  UPDATE public.profiles
  SET
    status = p_status,
    is_online = (p_status = 'online'),
    last_seen = NOW()
  WHERE id = auth.uid();

  -- Also update user_presence table if it exists
  -- Note: user_presence has both status (added in 026) and is_online (from 014)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_presence') THEN
    INSERT INTO public.user_presence (user_id, is_online, last_seen, updated_at, status)
    VALUES (auth.uid(), (p_status = 'online'), NOW(), NOW(), p_status)
    ON CONFLICT (user_id) DO UPDATE
    SET
      status = p_status,
      is_online = (p_status = 'online'),
      last_seen = NOW(),
      updated_at = NOW();
  END IF;

  -- Log the update for debugging
  RAISE NOTICE 'User % set status to %', auth.uid(), p_status;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.update_presence(text) TO authenticated;

COMMENT ON FUNCTION public.update_presence(text) IS
  'Updates user presence status (online/offline/away) in profiles and user_presence tables';

-- =============================================================================
-- PART 3: Fix group_members RLS Policy (Fixes Code 42501)
-- =============================================================================

-- Ensure RLS is enabled
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- Drop all existing INSERT policies to avoid conflicts
DROP POLICY IF EXISTS "Users can join public groups" ON public.group_members;
DROP POLICY IF EXISTS "Users can join public groups v2" ON public.group_members;
DROP POLICY IF EXISTS "Users can join public groups v3" ON public.group_members;
DROP POLICY IF EXISTS "group_members_insert_public" ON public.group_members;

-- Create a comprehensive INSERT policy for group_members
-- This allows users to join public groups
CREATE POLICY "group_members_insert_public"
  ON public.group_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- User can only insert their own membership
    auth.uid() = user_id
    AND
    -- Only allow joining public groups OR groups where user is invited
    (
      -- Public groups: anyone can join
      EXISTS (
        SELECT 1 FROM public.groups g
        WHERE g.id = group_id
        AND g.visibility = 'public'
      )
      OR
      -- Private groups: only if user is the creator (when group is first created)
      EXISTS (
        SELECT 1 FROM public.groups g
        WHERE g.id = group_id
        AND g.created_by = auth.uid()
      )
    )
  );

-- Ensure SELECT policy exists for users to see their memberships
DROP POLICY IF EXISTS "Users can view own memberships" ON public.group_members;

CREATE POLICY "Users can view own memberships"
  ON public.group_members
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Ensure DELETE policy exists for users to leave groups
DROP POLICY IF EXISTS "Users can leave groups" ON public.group_members;
DROP POLICY IF EXISTS "Users can leave groups v2" ON public.group_members;

CREATE POLICY "Users can leave groups v2"
  ON public.group_members
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- =============================================================================
-- PART 4: Ensure Foreign Keys on Friendships (Should already exist from 033)
-- =============================================================================

-- This is a safety check - these should already exist from migration 033
DO $$
BEGIN
  -- Check if FK constraints exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'friendships_user_id_fkey'
    AND table_name = 'friendships'
  ) THEN
    -- Add user_id FK
    ALTER TABLE public.friendships
      ADD CONSTRAINT friendships_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES public.profiles(id)
        ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'friendships_friend_id_fkey'
    AND table_name = 'friendships'
  ) THEN
    -- Add friend_id FK
    ALTER TABLE public.friendships
      ADD CONSTRAINT friendships_friend_id_fkey
        FOREIGN KEY (friend_id)
        REFERENCES public.profiles(id)
        ON DELETE CASCADE;
  END IF;
END $$;

-- =============================================================================
-- PART 5: Enable Realtime for Key Tables
-- =============================================================================

-- Enable realtime for friendships (friend requests, acceptances)
DO $$
BEGIN
  -- Check if table is already in publication
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'friendships'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships;
    RAISE NOTICE '✅ Realtime enabled for friendships';
  ELSE
    RAISE NOTICE '⏭️ Realtime already enabled for friendships';
  END IF;
END $$;

-- Enable realtime for messages (chat)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    RAISE NOTICE '✅ Realtime enabled for messages';
  ELSE
    RAISE NOTICE '⏭️ Realtime already enabled for messages';
  END IF;
END $$;

-- Enable realtime for notifications (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
      AND tablename = 'notifications'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
      RAISE NOTICE '✅ Realtime enabled for notifications';
    ELSE
      RAISE NOTICE '⏭️ Realtime already enabled for notifications';
    END IF;
  ELSE
    RAISE NOTICE '⚠️ Notifications table does not exist, skipping realtime setup';
  END IF;
END $$;

-- Enable realtime for user_presence (online status)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_presence') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
      AND tablename = 'user_presence'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.user_presence;
      RAISE NOTICE '✅ Realtime enabled for user_presence';
    ELSE
      RAISE NOTICE '⏭️ Realtime already enabled for user_presence';
    END IF;
  END IF;
END $$;

-- Enable realtime for group_members (group joins)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'group_members'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.group_members;
    RAISE NOTICE '✅ Realtime enabled for group_members';
  ELSE
    RAISE NOTICE '⏭️ Realtime already enabled for group_members';
  END IF;
END $$;

-- =============================================================================
-- PART 6: Verification Queries
-- =============================================================================

-- Verify update_presence function exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname = 'update_presence'
  ) THEN
    RAISE NOTICE '✅ update_presence() function exists';
  ELSE
    RAISE WARNING '❌ update_presence() function NOT found!';
  END IF;
END $$;

-- Verify foreign keys on friendships
SELECT
  '✅ Friendships Foreign Keys' as check_type,
  constraint_name,
  column_name
FROM information_schema.key_column_usage
WHERE table_name = 'friendships'
  AND table_schema = 'public'
  AND constraint_name LIKE '%fkey%'
ORDER BY constraint_name;

-- Verify realtime publications
SELECT
  '✅ Realtime Publications' as check_type,
  schemaname,
  tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND tablename IN ('friendships', 'messages', 'notifications', 'user_presence', 'group_members')
ORDER BY tablename;

-- Verify group_members RLS policies
SELECT
  '✅ Group Members RLS Policies' as check_type,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'group_members'
  AND cmd = 'INSERT'
ORDER BY policyname;

-- Verify profiles has status column
SELECT
  '✅ Profiles Columns' as check_type,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name IN ('status', 'is_online', 'last_seen')
ORDER BY column_name;

-- =============================================================================
-- DONE!
-- =============================================================================

-- Summary of changes
DO $$
BEGIN
  RAISE NOTICE '
  ═══════════════════════════════════════════════════════════════
  ✅ COMPREHENSIVE FIX COMPLETED
  ═══════════════════════════════════════════════════════════════

  Fixed Issues:
  1. ✅ Added status column to profiles table
  2. ✅ Created update_presence(p_status) function
  3. ✅ Fixed group_members INSERT policy (allows joining public groups)
  4. ✅ Verified friendships foreign keys
  5. ✅ Enabled Realtime for: friendships, messages, notifications, user_presence, group_members

  Next Steps:
  1. Rebuild Flutter app: flutter clean && flutter pub get && flutter run
  2. Test group joining
  3. Test going online/offline
  4. Test friends list and messaging

  ═══════════════════════════════════════════════════════════════
  ';
END $$;
