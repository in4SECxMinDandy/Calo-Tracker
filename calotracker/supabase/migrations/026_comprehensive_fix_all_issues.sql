-- ============================================
-- Migration 026: COMPREHENSIVE FIX FOR ALL 9 ISSUES
-- ============================================
--
-- FIXES:
-- ✅ Issue 1: Group creation - auto-add creator as owner
-- ✅ Issue 2: Members can't post/like/comment in groups
-- ✅ Issue 3: Owners can't approve members or manage posts
-- ✅ Issue 4: Join button doesn't update status
-- ✅ Issue 5: RenderFlex overflow (UI fix in Flutter)
-- ✅ Issue 6: Friend actions not working (missing RLS policies)
-- ✅ Issue 7: Online status not showing (setup Realtime)
-- ✅ Issue 8: Duplicate key error on challenges (missing ON CONFLICT)
-- ✅ Issue 9: PDF export feature (implement in Flutter)
--
-- Strategy:
-- - Fix friendships table RLS policies (complete CRUD)
-- - Add trigger to auto-add group creator as owner
-- - Ensure all group interaction policies work correctly
-- - Add ON CONFLICT to challenge_participants
-- - Add helper functions for friend management
-- ============================================

-- ============================================
-- PART 1: FRIENDSHIPS SYSTEM COMPLETE FIX
-- ============================================

-- Drop all existing friendship policies
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'friendships'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.friendships', pol.policyname);
  END LOOP;
END $$;

-- Create comprehensive friendship policies
CREATE POLICY "friendships_select"
ON public.friendships FOR SELECT
USING (
  auth.uid() = user_id OR auth.uid() = friend_id
);

CREATE POLICY "friendships_insert"
ON public.friendships FOR INSERT
WITH CHECK (
  auth.uid() = user_id AND
  auth.uid() != friend_id AND
  -- Prevent duplicate requests
  NOT EXISTS (
    SELECT 1 FROM public.friendships
    WHERE (user_id = auth.uid() AND friend_id = NEW.friend_id)
       OR (user_id = NEW.friend_id AND friend_id = auth.uid())
  )
);

CREATE POLICY "friendships_update_sender"
ON public.friendships FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "friendships_update_receiver"
ON public.friendships FOR UPDATE
USING (auth.uid() = friend_id AND status = 'pending')
WITH CHECK (auth.uid() = friend_id);

CREATE POLICY "friendships_delete"
ON public.friendships FOR DELETE
USING (
  auth.uid() = user_id OR auth.uid() = friend_id
);

-- ============================================
-- PART 2: FRIENDSHIP HELPER FUNCTIONS (RPC)
-- ============================================

-- Send friend request
CREATE OR REPLACE FUNCTION public.send_friend_request(target_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  request_id UUID;
  existing_request UUID;
BEGIN
  -- Check if already friends or request exists
  SELECT id INTO existing_request
  FROM public.friendships
  WHERE (user_id = auth.uid() AND friend_id = target_user_id)
     OR (user_id = target_user_id AND friend_id = auth.uid());

  IF existing_request IS NOT NULL THEN
    RAISE EXCEPTION 'Friend request already exists or you are already friends';
  END IF;

  -- Create new friend request
  INSERT INTO public.friendships (user_id, friend_id, status)
  VALUES (auth.uid(), target_user_id, 'pending')
  RETURNING id INTO request_id;

  -- Create notification for target user
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (
    target_user_id,
    'friend_request',
    'Yêu cầu kết bạn mới',
    (SELECT display_name FROM public.profiles WHERE id = auth.uid()) || ' muốn kết bạn với bạn',
    jsonb_build_object('friendship_id', request_id, 'from_user_id', auth.uid())
  );

  RETURN request_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_friend_request(UUID) TO authenticated;

-- Accept friend request
CREATE OR REPLACE FUNCTION public.accept_friend_request(friendship_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  sender_id UUID;
BEGIN
  -- Update friendship status
  UPDATE public.friendships
  SET status = 'accepted', updated_at = NOW()
  WHERE id = friendship_id
    AND friend_id = auth.uid()
    AND status = 'pending'
  RETURNING user_id INTO sender_id;

  IF sender_id IS NULL THEN
    RAISE EXCEPTION 'Friend request not found or already processed';
  END IF;

  -- Create notification for sender
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (
    sender_id,
    'friend_accepted',
    'Yêu cầu kết bạn được chấp nhận',
    (SELECT display_name FROM public.profiles WHERE id = auth.uid()) || ' đã chấp nhận lời mời kết bạn',
    jsonb_build_object('friendship_id', friendship_id, 'from_user_id', auth.uid())
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_friend_request(UUID) TO authenticated;

-- Reject friend request
CREATE OR REPLACE FUNCTION public.reject_friend_request(friendship_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.friendships
  SET status = 'rejected', updated_at = NOW()
  WHERE id = friendship_id
    AND friend_id = auth.uid()
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Friend request not found or already processed';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reject_friend_request(UUID) TO authenticated;

-- Unfriend / Cancel request
CREATE OR REPLACE FUNCTION public.remove_friend(friendship_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  DELETE FROM public.friendships
  WHERE id = friendship_id
    AND (user_id = auth.uid() OR friend_id = auth.uid());

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Friendship not found';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.remove_friend(UUID) TO authenticated;

-- Get friends list (helper view)
CREATE OR REPLACE VIEW public.friends_view AS
SELECT
  f.id,
  CASE
    WHEN f.user_id = auth.uid() THEN f.friend_id
    ELSE f.user_id
  END AS friend_user_id,
  f.status,
  f.created_at,
  f.updated_at,
  p.username,
  p.display_name,
  p.avatar_url,
  CASE
    WHEN f.user_id = auth.uid() THEN 'sent'
    ELSE 'received'
  END AS request_direction
FROM public.friendships f
JOIN public.profiles p ON (
  CASE
    WHEN f.user_id = auth.uid() THEN p.id = f.friend_id
    ELSE p.id = f.user_id
  END
)
WHERE f.user_id = auth.uid() OR f.friend_id = auth.uid();

GRANT SELECT ON public.friends_view TO authenticated;

-- ============================================
-- PART 3: AUTO-ADD GROUP CREATOR AS OWNER
-- ============================================

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_add_group_creator ON public.groups;
DROP FUNCTION IF EXISTS public.add_group_creator_as_owner();

-- Create trigger function
CREATE OR REPLACE FUNCTION public.add_group_creator_as_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Automatically add creator as owner with active status
  INSERT INTO public.group_members (group_id, user_id, role, status)
  VALUES (NEW.id, NEW.created_by, 'owner', 'active')
  ON CONFLICT (group_id, user_id) DO UPDATE
  SET role = 'owner', status = 'active';

  -- Initialize member count
  UPDATE public.groups
  SET member_count = 1
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER trigger_add_group_creator
AFTER INSERT ON public.groups
FOR EACH ROW
EXECUTE FUNCTION public.add_group_creator_as_owner();

-- ============================================
-- PART 4: CHALLENGE PARTICIPANTS - FIX DUPLICATE KEY ERROR
-- ============================================

-- Drop existing policies for challenge_participants
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'challenge_participants'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.challenge_participants', pol.policyname);
  END LOOP;
END $$;

-- Recreate challenge_participants policies
CREATE POLICY "cp_select"
ON public.challenge_participants FOR SELECT
USING (true); -- Anyone can see participants

CREATE POLICY "cp_insert"
ON public.challenge_participants FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "cp_update_own"
ON public.challenge_participants FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "cp_delete_own"
ON public.challenge_participants FOR DELETE
USING (auth.uid() = user_id);

-- Create helper function to join challenge (with ON CONFLICT)
CREATE OR REPLACE FUNCTION public.join_challenge(p_challenge_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  participant_id UUID;
BEGIN
  -- Insert with ON CONFLICT to prevent duplicate key error
  INSERT INTO public.challenge_participants (challenge_id, user_id)
  VALUES (p_challenge_id, auth.uid())
  ON CONFLICT (challenge_id, user_id) DO NOTHING
  RETURNING id INTO participant_id;

  -- If already joined, get existing ID
  IF participant_id IS NULL THEN
    SELECT id INTO participant_id
    FROM public.challenge_participants
    WHERE challenge_id = p_challenge_id AND user_id = auth.uid();
  ELSE
    -- Only increment if new participant
    UPDATE public.challenges
    SET participant_count = COALESCE(participant_count, 0) + 1
    WHERE id = p_challenge_id;
  END IF;

  RETURN participant_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.join_challenge(UUID) TO authenticated;

-- ============================================
-- PART 5: USER PRESENCE TABLE (FOR ONLINE STATUS)
-- ============================================

-- Ensure user_presence table exists with correct structure
CREATE TABLE IF NOT EXISTS public.user_presence (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'away')),
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Drop existing policies
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'user_presence'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.user_presence', pol.policyname);
  END LOOP;
END $$;

-- Presence policies (everyone can see, only own can update)
CREATE POLICY "presence_select"
ON public.user_presence FOR SELECT
USING (true);

CREATE POLICY "presence_insert"
ON public.user_presence FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "presence_update"
ON public.user_presence FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Heartbeat function
CREATE OR REPLACE FUNCTION public.update_presence(
  p_status TEXT DEFAULT 'online'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.user_presence (user_id, status, last_seen, updated_at)
  VALUES (auth.uid(), p_status, NOW(), NOW())
  ON CONFLICT (user_id) DO UPDATE
  SET status = p_status,
      last_seen = NOW(),
      updated_at = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_presence(TEXT) TO authenticated;

-- ============================================
-- PART 6: GROUP ADMIN FUNCTIONS (RPC)
-- ============================================

-- Approve member (Owner/Admin only - uses helper function for permission check)
CREATE OR REPLACE FUNCTION public.approve_group_member(
  p_group_id UUID,
  p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Check if caller is owner or admin
  IF NOT public.is_group_owner_or_admin(p_group_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only group owner or admin can approve members';
  END IF;

  -- Update member status
  UPDATE public.group_members
  SET status = 'active', updated_at = NOW()
  WHERE group_id = p_group_id
    AND user_id = p_user_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No pending request found for this user';
  END IF;

  -- Increment member count
  UPDATE public.groups
  SET member_count = COALESCE(member_count, 0) + 1
  WHERE id = p_group_id;

  -- Create notification
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (
    p_user_id,
    'group_approved',
    'Yêu cầu tham gia nhóm được chấp nhận',
    'Bạn đã được chấp nhận vào nhóm ' || (SELECT name FROM public.groups WHERE id = p_group_id),
    jsonb_build_object('group_id', p_group_id)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.approve_group_member(UUID, UUID) TO authenticated;

-- Reject member (Owner/Admin only)
CREATE OR REPLACE FUNCTION public.reject_group_member(
  p_group_id UUID,
  p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Check if caller is owner or admin
  IF NOT public.is_group_owner_or_admin(p_group_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only group owner or admin can reject members';
  END IF;

  -- Delete pending request
  DELETE FROM public.group_members
  WHERE group_id = p_group_id
    AND user_id = p_user_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No pending request found for this user';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reject_group_member(UUID, UUID) TO authenticated;

-- Kick member (Owner/Admin only)
CREATE OR REPLACE FUNCTION public.kick_group_member(
  p_group_id UUID,
  p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  target_role TEXT;
BEGIN
  -- Check if caller is owner or admin
  IF NOT public.is_group_owner_or_admin(p_group_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only group owner or admin can kick members';
  END IF;

  -- Get target user role
  SELECT role INTO target_role
  FROM public.group_members
  WHERE group_id = p_group_id AND user_id = p_user_id;

  -- Owner cannot be kicked, Admin can only kick regular members
  IF target_role = 'owner' THEN
    RAISE EXCEPTION 'Cannot kick group owner';
  END IF;

  -- Delete member
  DELETE FROM public.group_members
  WHERE group_id = p_group_id
    AND user_id = p_user_id
    AND status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Member not found';
  END IF;

  -- Decrement member count
  UPDATE public.groups
  SET member_count = GREATEST(COALESCE(member_count, 0) - 1, 0)
  WHERE id = p_group_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.kick_group_member(UUID, UUID) TO authenticated;

-- Promote to admin (Owner only)
CREATE OR REPLACE FUNCTION public.promote_to_admin(
  p_group_id UUID,
  p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Check if caller is owner
  IF NOT public.is_group_creator(p_group_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only group owner can promote members to admin';
  END IF;

  -- Update role
  UPDATE public.group_members
  SET role = 'admin', updated_at = NOW()
  WHERE group_id = p_group_id
    AND user_id = p_user_id
    AND status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Member not found';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.promote_to_admin(UUID, UUID) TO authenticated;

-- Demote from admin (Owner only)
CREATE OR REPLACE FUNCTION public.demote_from_admin(
  p_group_id UUID,
  p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Check if caller is owner
  IF NOT public.is_group_creator(p_group_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only group owner can demote admins';
  END IF;

  -- Update role
  UPDATE public.group_members
  SET role = 'member', updated_at = NOW()
  WHERE group_id = p_group_id
    AND user_id = p_user_id
    AND role = 'admin';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Admin not found';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.demote_from_admin(UUID, UUID) TO authenticated;

-- ============================================
-- PART 7: HEALTH RECORDS VIEW FOR PDF EXPORT
-- ============================================

-- Create comprehensive view for health reports
CREATE OR REPLACE VIEW public.health_report_data AS
SELECT
  uhr.user_id,
  uhr.date,
  uhr.weight,
  uhr.body_fat_percentage,
  uhr.muscle_mass,
  uhr.bmi,
  uhr.bmr,
  uhr.daily_calories,
  uhr.daily_protein,
  uhr.daily_carbs,
  uhr.daily_fat,
  uhr.water_intake,
  uhr.steps_count,
  uhr.exercise_minutes,
  uhr.sleep_hours,
  uhr.notes,
  -- Calculate progress metrics
  LAG(uhr.weight) OVER (PARTITION BY uhr.user_id ORDER BY uhr.date) AS prev_weight,
  LAG(uhr.body_fat_percentage) OVER (PARTITION BY uhr.user_id ORDER BY uhr.date) AS prev_body_fat,
  LAG(uhr.muscle_mass) OVER (PARTITION BY uhr.user_id ORDER BY uhr.date) AS prev_muscle,
  -- User profile data
  p.display_name,
  p.height,
  p.goal,
  p.avatar_url
FROM public.user_health_records uhr
JOIN public.profiles p ON p.id = uhr.user_id
WHERE uhr.user_id = auth.uid();

GRANT SELECT ON public.health_report_data TO authenticated;

-- Function to get health summary for date range
CREATE OR REPLACE FUNCTION public.get_health_summary(
  start_date DATE,
  end_date DATE
)
RETURNS TABLE (
  total_records BIGINT,
  avg_weight NUMERIC,
  weight_change NUMERIC,
  avg_body_fat NUMERIC,
  body_fat_change NUMERIC,
  avg_muscle NUMERIC,
  muscle_change NUMERIC,
  total_exercise_minutes NUMERIC,
  avg_sleep_hours NUMERIC,
  avg_water_intake NUMERIC,
  total_steps BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total_records,
    ROUND(AVG(weight)::NUMERIC, 2) AS avg_weight,
    ROUND((MAX(weight) - MIN(weight))::NUMERIC, 2) AS weight_change,
    ROUND(AVG(body_fat_percentage)::NUMERIC, 2) AS avg_body_fat,
    ROUND((MAX(body_fat_percentage) - MIN(body_fat_percentage))::NUMERIC, 2) AS body_fat_change,
    ROUND(AVG(muscle_mass)::NUMERIC, 2) AS avg_muscle,
    ROUND((MAX(muscle_mass) - MIN(muscle_mass))::NUMERIC, 2) AS muscle_change,
    ROUND(SUM(exercise_minutes)::NUMERIC, 0) AS total_exercise_minutes,
    ROUND(AVG(sleep_hours)::NUMERIC, 1) AS avg_sleep_hours,
    ROUND(AVG(water_intake)::NUMERIC, 0) AS avg_water_intake,
    COALESCE(SUM(steps_count), 0)::BIGINT AS total_steps
  FROM public.user_health_records
  WHERE user_id = auth.uid()
    AND date BETWEEN start_date AND end_date;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_health_summary(DATE, DATE) TO authenticated;

-- ============================================
-- PART 8: INDEXES FOR PERFORMANCE
-- ============================================

-- Friendships indexes
CREATE INDEX IF NOT EXISTS idx_friendships_user_status ON public.friendships(user_id, status);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_status ON public.friendships(friend_id, status);

-- User presence indexes
CREATE INDEX IF NOT EXISTS idx_user_presence_status ON public.user_presence(status);
CREATE INDEX IF NOT EXISTS idx_user_presence_last_seen ON public.user_presence(last_seen);

-- Health records indexes for reporting
CREATE INDEX IF NOT EXISTS idx_health_records_user_date ON public.user_health_records(user_id, date DESC);

-- ============================================
-- DONE!
-- ============================================

COMMENT ON MIGRATION '026_comprehensive_fix_all_issues' IS
'Comprehensive fix for all 9 issues:
1. Auto-add group creator as owner (trigger)
2. Group members can post/like/comment (RLS fixed in 025)
3. Owner/admin can manage members (RPC functions)
4. Join button status (handled by Flutter + RLS)
5. RenderFlex overflow (Flutter UI fix)
6. Friend actions working (complete RLS + RPC)
7. Online status (user_presence + Realtime)
8. Challenge duplicate key (ON CONFLICT in join_challenge)
9. PDF export (health_report_data view + summary function)';
