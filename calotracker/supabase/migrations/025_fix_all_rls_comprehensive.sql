-- ============================================
-- Migration 025: COMPREHENSIVE RLS FIX
-- ============================================
-- Fixes ALL 3 critical issues:
--   1. Posts/Likes/Comments blocked for authenticated users
--   2. Group Owner/Admin missing CRUD permissions
--   3. Member approval (pending → active) not working
--
-- Strategy:
--   - Drop ALL policies on affected tables
--   - Recreate SECURITY DEFINER helper functions (CASCADE safe)
--   - Rebuild policies from scratch with correct logic
--   - Ensure no infinite recursion
-- ============================================

-- ============================================
-- HELPER: Drop ALL policies on a table dynamically
-- ============================================
CREATE OR REPLACE FUNCTION pg_temp.drop_all_policies(p_schema TEXT, p_table TEXT)
RETURNS void AS $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = p_schema AND tablename = p_table
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, p_schema, p_table);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STEP 1: Recreate SECURITY DEFINER helper functions
-- These bypass RLS to prevent infinite recursion
-- ============================================

-- Drop all helper functions with CASCADE (removes dependent policies)
DROP FUNCTION IF EXISTS public.is_group_member(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_active_member(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_public(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_creator(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_admin(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_owner_or_admin(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_member_any_status(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_app_admin(UUID) CASCADE;

-- 1a. Check if user is an ACTIVE member of a group
CREATE FUNCTION public.is_group_member(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id
      AND user_id = p_user_id
      AND status = 'active'
  );
$$;

-- 1b. Check if group is public
CREATE FUNCTION public.is_group_public(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.groups
    WHERE id = p_group_id AND visibility = 'public'
  );
$$;

-- 1c. Check if user is the group creator
CREATE FUNCTION public.is_group_creator(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.groups
    WHERE id = p_group_id AND created_by = p_user_id
  );
$$;

-- 1d. Check if user is owner or admin of a group
CREATE FUNCTION public.is_group_owner_or_admin(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id
      AND user_id = p_user_id
      AND status = 'active'
      AND role IN ('owner', 'admin')
  );
$$;

-- 1e. Check if user has ANY row in group_members (including pending)
CREATE FUNCTION public.is_group_member_any_status(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id AND user_id = p_user_id
  );
$$;

-- 1f. Check if user is admin (app-wide)
CREATE FUNCTION public.is_app_admin(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = p_user_id AND role = 'admin'
  );
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.is_group_member(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_group_public(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_group_creator(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_group_owner_or_admin(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_group_member_any_status(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_app_admin(UUID) TO authenticated;

-- ============================================
-- STEP 2: GROUPS policies
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'groups');

-- Anyone authenticated can see public groups
CREATE POLICY "groups_select_public"
  ON public.groups FOR SELECT TO authenticated
  USING (visibility = 'public');

-- Members can see their private/invite groups
CREATE POLICY "groups_select_member"
  ON public.groups FOR SELECT TO authenticated
  USING (public.is_group_member(id, auth.uid()));

-- Creator can see their own groups always
CREATE POLICY "groups_select_creator"
  ON public.groups FOR SELECT TO authenticated
  USING (created_by = auth.uid());

-- Authenticated users can create groups
CREATE POLICY "groups_insert"
  ON public.groups FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = created_by);

-- Owner or admin can update group
CREATE POLICY "groups_update"
  ON public.groups FOR UPDATE TO authenticated
  USING (
    created_by = auth.uid()
    OR public.is_group_owner_or_admin(id, auth.uid())
  );

-- Only creator can delete group
CREATE POLICY "groups_delete"
  ON public.groups FOR DELETE TO authenticated
  USING (created_by = auth.uid());

-- ============================================
-- STEP 3: GROUP_MEMBERS policies
-- Fixes: Member approval, pending status, owner/admin CRUD
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'group_members');

-- Users can see their own memberships (any status - to check pending)
CREATE POLICY "gm_select_own"
  ON public.group_members FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Active members can see other members in their group
CREATE POLICY "gm_select_member"
  ON public.group_members FOR SELECT TO authenticated
  USING (public.is_group_member(group_id, auth.uid()));

-- Anyone can see members of public groups
CREATE POLICY "gm_select_public"
  ON public.group_members FOR SELECT TO authenticated
  USING (public.is_group_public(group_id));

-- Owner/Admin can see ALL members (including pending) for approval
CREATE POLICY "gm_select_admin"
  ON public.group_members FOR SELECT TO authenticated
  USING (public.is_group_owner_or_admin(group_id, auth.uid()));

-- Users can JOIN public groups (status = 'active' directly)
CREATE POLICY "gm_insert_public"
  ON public.group_members FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND public.is_group_public(group_id)
    AND status = 'active'
    AND role = 'member'
    AND NOT public.is_group_member_any_status(group_id, auth.uid())
  );

-- Users can REQUEST to join private/invite groups (status = 'pending')
CREATE POLICY "gm_insert_request"
  ON public.group_members FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND NOT public.is_group_public(group_id)
    AND status = 'pending'
    AND role = 'member'
    AND NOT public.is_group_member_any_status(group_id, auth.uid())
  );

-- Creator can add themselves as owner (for group creation flow)
CREATE POLICY "gm_insert_creator"
  ON public.group_members FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND public.is_group_creator(group_id, auth.uid())
  );

-- Owner/Admin can add members directly (invite flow)
CREATE POLICY "gm_insert_by_admin"
  ON public.group_members FOR INSERT TO authenticated
  WITH CHECK (
    public.is_group_owner_or_admin(group_id, auth.uid())
  );

-- Owner/Admin can UPDATE members (approve pending, change role, ban)
CREATE POLICY "gm_update_admin"
  ON public.group_members FOR UPDATE TO authenticated
  USING (public.is_group_owner_or_admin(group_id, auth.uid()));

-- Users can leave groups (delete their own membership)
CREATE POLICY "gm_delete_self"
  ON public.group_members FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- Owner/Admin can remove members
CREATE POLICY "gm_delete_admin"
  ON public.group_members FOR DELETE TO authenticated
  USING (public.is_group_owner_or_admin(group_id, auth.uid()));

-- ============================================
-- STEP 4: POSTS policies
-- Fixes: Insert blocked, group posts, owner/admin moderation
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'posts');

-- Anyone authenticated can see public, non-hidden posts
CREATE POLICY "posts_select_public"
  ON public.posts FOR SELECT TO authenticated
  USING (visibility = 'public' AND is_hidden = false);

-- Users can always see their own posts
CREATE POLICY "posts_select_own"
  ON public.posts FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- Group members can see group posts
CREATE POLICY "posts_select_group"
  ON public.posts FOR SELECT TO authenticated
  USING (
    group_id IS NOT NULL
    AND public.is_group_member(group_id, auth.uid())
  );

-- Authenticated users can create personal posts (no group/challenge)
-- AND group members can create posts in their groups
-- AND challenge participants can create posts in challenges
CREATE POLICY "posts_insert"
  ON public.posts FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND (
      -- Personal post
      (group_id IS NULL AND challenge_id IS NULL)
      OR
      -- Group post (must be active member)
      (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid()))
      OR
      -- Challenge post (must be participant)
      (challenge_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.challenge_participants cp
        WHERE cp.challenge_id = posts.challenge_id
          AND cp.user_id = auth.uid()
      ))
    )
  );

-- Users can update their own posts
CREATE POLICY "posts_update_own"
  ON public.posts FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

-- Group owner/admin can moderate (update) posts in their group
CREATE POLICY "posts_update_group_admin"
  ON public.posts FOR UPDATE TO authenticated
  USING (
    group_id IS NOT NULL
    AND public.is_group_owner_or_admin(group_id, auth.uid())
  );

-- Users can delete their own posts
CREATE POLICY "posts_delete_own"
  ON public.posts FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- Group owner/admin can delete posts in their group
CREATE POLICY "posts_delete_group_admin"
  ON public.posts FOR DELETE TO authenticated
  USING (
    group_id IS NOT NULL
    AND public.is_group_owner_or_admin(group_id, auth.uid())
  );

-- ============================================
-- STEP 5: COMMENTS policies
-- Fixes: Insert blocked, group admin moderation
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'comments');

-- Anyone authenticated can see non-hidden comments
CREATE POLICY "comments_select"
  ON public.comments FOR SELECT TO authenticated
  USING (is_hidden = false);

-- Users can see their own comments even if hidden
CREATE POLICY "comments_select_own"
  ON public.comments FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- Authenticated users can create comments
CREATE POLICY "comments_insert"
  ON public.comments FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own comments
CREATE POLICY "comments_update_own"
  ON public.comments FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

-- Users can delete their own comments
CREATE POLICY "comments_delete_own"
  ON public.comments FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- App admin can moderate comments
CREATE POLICY "comments_admin"
  ON public.comments FOR ALL TO authenticated
  USING (public.is_app_admin(auth.uid()));

-- ============================================
-- STEP 6: LIKES policies
-- Fixes: Insert/Delete blocked, select for checking liked status
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'likes');

-- Anyone authenticated can see likes (needed to check if already liked)
CREATE POLICY "likes_select"
  ON public.likes FOR SELECT TO authenticated
  USING (true);

-- Authenticated users can like (insert)
CREATE POLICY "likes_insert"
  ON public.likes FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can unlike (delete their own likes)
CREATE POLICY "likes_delete"
  ON public.likes FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================
-- STEP 7: GROUP_INVITES policies
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'group_invites');

-- Users can see invites they received or sent
CREATE POLICY "gi_select"
  ON public.group_invites FOR SELECT TO authenticated
  USING (invited_user_id = auth.uid() OR invited_by = auth.uid());

-- Owner/Admin can see all invites for their group
CREATE POLICY "gi_select_admin"
  ON public.group_invites FOR SELECT TO authenticated
  USING (public.is_group_owner_or_admin(group_id, auth.uid()));

-- Owner/Admin can create invites
CREATE POLICY "gi_insert"
  ON public.group_invites FOR INSERT TO authenticated
  WITH CHECK (
    invited_by = auth.uid()
    AND public.is_group_owner_or_admin(group_id, auth.uid())
  );

-- Invited user can update invite (accept/decline)
CREATE POLICY "gi_update_recipient"
  ON public.group_invites FOR UPDATE TO authenticated
  USING (invited_user_id = auth.uid());

-- Owner/Admin can delete invites
CREATE POLICY "gi_delete_admin"
  ON public.group_invites FOR DELETE TO authenticated
  USING (public.is_group_owner_or_admin(group_id, auth.uid()));

-- ============================================
-- STEP 8: FOLLOWS policies
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'follows');

CREATE POLICY "follows_select"
  ON public.follows FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "follows_insert"
  ON public.follows FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "follows_delete"
  ON public.follows FOR DELETE TO authenticated
  USING (auth.uid() = follower_id);

-- ============================================
-- STEP 9: NOTIFICATIONS policies
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'notifications');

CREATE POLICY "notif_select_own"
  ON public.notifications FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "notif_insert"
  ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "notif_update_own"
  ON public.notifications FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "notif_delete_own"
  ON public.notifications FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================
-- STEP 10: CHALLENGES & CHALLENGE_PARTICIPANTS policies
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'challenges');

CREATE POLICY "challenges_select"
  ON public.challenges FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "challenges_insert"
  ON public.challenges FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "challenges_update"
  ON public.challenges FOR UPDATE TO authenticated
  USING (auth.uid() = created_by);

CREATE POLICY "challenges_delete"
  ON public.challenges FOR DELETE TO authenticated
  USING (auth.uid() = created_by);

SELECT pg_temp.drop_all_policies('public', 'challenge_participants');

CREATE POLICY "cp_select"
  ON public.challenge_participants FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "cp_insert"
  ON public.challenge_participants FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "cp_update_own"
  ON public.challenge_participants FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "cp_delete_own"
  ON public.challenge_participants FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================
-- STEP 11: FRIENDSHIPS policies
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'friendships');

CREATE POLICY "friendships_select"
  ON public.friendships FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "friendships_insert"
  ON public.friendships FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id AND status = 'pending');

CREATE POLICY "friendships_update"
  ON public.friendships FOR UPDATE TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "friendships_delete"
  ON public.friendships FOR DELETE TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- ============================================
-- STEP 12: MESSAGES policies
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'messages');

CREATE POLICY "messages_select"
  ON public.messages FOR SELECT TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "messages_insert"
  ON public.messages FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "messages_update"
  ON public.messages FOR UPDATE TO authenticated
  USING (auth.uid() = receiver_id);

CREATE POLICY "messages_delete"
  ON public.messages FOR DELETE TO authenticated
  USING (auth.uid() = sender_id);

-- ============================================
-- STEP 13: PROFILES policies
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'profiles');

CREATE POLICY "profiles_select"
  ON public.profiles FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "profiles_insert"
  ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE TO authenticated
  USING (auth.uid() = id);

-- ============================================
-- STEP 14: OTHER TABLES (keep existing logic)
-- ============================================

-- user_roles
SELECT pg_temp.drop_all_policies('public', 'user_roles');
CREATE POLICY "ur_select_own" ON public.user_roles FOR SELECT TO authenticated
  USING (auth.uid() = user_id);
CREATE POLICY "ur_admin" ON public.user_roles FOR ALL TO authenticated
  USING (public.is_app_admin(auth.uid()));
CREATE POLICY "ur_service" ON public.user_roles FOR ALL TO service_role
  USING (true);

-- user_health_records
SELECT pg_temp.drop_all_policies('public', 'user_health_records');
CREATE POLICY "uhr_select" ON public.user_health_records FOR SELECT TO authenticated
  USING (auth.uid() = user_id);
CREATE POLICY "uhr_insert" ON public.user_health_records FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "uhr_update" ON public.user_health_records FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

-- achievements
SELECT pg_temp.drop_all_policies('public', 'achievements');
CREATE POLICY "achievements_select" ON public.achievements FOR SELECT TO authenticated
  USING (true);

-- user_achievements
SELECT pg_temp.drop_all_policies('public', 'user_achievements');
CREATE POLICY "ua_select" ON public.user_achievements FOR SELECT TO authenticated
  USING (true);
CREATE POLICY "ua_insert" ON public.user_achievements FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- bans
SELECT pg_temp.drop_all_policies('public', 'bans');
CREATE POLICY "bans_select" ON public.bans FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR public.is_app_admin(auth.uid()));
CREATE POLICY "bans_admin" ON public.bans FOR ALL TO authenticated
  USING (public.is_app_admin(auth.uid()));

-- reports
SELECT pg_temp.drop_all_policies('public', 'reports');
CREATE POLICY "reports_insert" ON public.reports FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "reports_select_own" ON public.reports FOR SELECT TO authenticated
  USING (auth.uid() = reporter_id);
CREATE POLICY "reports_admin" ON public.reports FOR ALL TO authenticated
  USING (public.is_app_admin(auth.uid()));

-- saved_posts
SELECT pg_temp.drop_all_policies('public', 'saved_posts');
CREATE POLICY "sp_select" ON public.saved_posts FOR SELECT TO authenticated
  USING (auth.uid() = user_id);
CREATE POLICY "sp_insert" ON public.saved_posts FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "sp_delete" ON public.saved_posts FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- user_presence
SELECT pg_temp.drop_all_policies('public', 'user_presence');
CREATE POLICY "up_select" ON public.user_presence FOR SELECT TO authenticated
  USING (true);
CREATE POLICY "up_upsert" ON public.user_presence FOR ALL TO authenticated
  USING (auth.uid() = user_id);

-- OTP tables (service_role only)
SELECT pg_temp.drop_all_policies('public', 'otp_tokens');
SELECT pg_temp.drop_all_policies('public', 'reset_tokens');
SELECT pg_temp.drop_all_policies('public', 'rate_limits');
CREATE POLICY "otp_service" ON public.otp_tokens FOR ALL TO service_role USING (true);
CREATE POLICY "reset_service" ON public.reset_tokens FOR ALL TO service_role USING (true);
CREATE POLICY "rate_service" ON public.rate_limits FOR ALL TO service_role USING (true);

-- ============================================
-- STEP 15: Ensure RLS is enabled on ALL tables
-- ============================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reset_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 16: Utility RPC function for atomic counter updates
-- Param names MUST match Flutter calls: table_name, column_name, row_id, amount
-- ============================================
CREATE OR REPLACE FUNCTION public.increment_counter(
  table_name TEXT,
  column_name TEXT,
  row_id UUID,
  amount INTEGER DEFAULT 1
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  EXECUTE format(
    'UPDATE public.%I SET %I = COALESCE(%I, 0) + $1 WHERE id = $2',
    table_name, column_name, column_name
  ) USING amount, row_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.increment_counter(TEXT, TEXT, UUID, INTEGER) TO authenticated;

-- ============================================
-- DONE!
-- ============================================
-- Summary of what this migration fixes:
--
-- 1. POSTS: Single insert policy covers personal + group + challenge posts
-- 2. LIKES: Added likes_select (was missing → couldn't check if liked)
-- 3. COMMENTS: Simplified insert policy for all authenticated users
-- 4. GROUP_MEMBERS:
--    - gm_insert_request: Users can request to join private groups (pending)
--    - gm_update_admin: Owner/Admin can approve (pending → active)
--    - gm_insert_by_admin: Owner/Admin can add members directly
--    - is_group_member() now checks status = 'active'
-- 5. GROUPS: Owner OR Admin can update groups
-- 6. All helper functions use SET search_path = '' for security
-- ============================================
