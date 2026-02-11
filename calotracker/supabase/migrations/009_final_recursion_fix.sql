-- ===================================================================
-- FINAL FIX FOR INFINITE RECURSION
-- Problem: groups -> group_members -> groups -> infinite loop
-- Solution: Use SECURITY DEFINER functions to bypass RLS when checking
-- ===================================================================

-- ===================================================================
-- STEP 0: Drop existing functions first (CASCADE to remove dependent policies)
-- All policies are recreated in STEP 5 and STEP 6 below
-- ===================================================================
DROP FUNCTION IF EXISTS public.is_group_public(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_creator(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_member(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_admin(UUID, UUID) CASCADE;

-- ===================================================================
-- STEP 1: Create helper functions with SECURITY DEFINER
-- These functions bypass RLS, breaking the recursion cycle
-- ===================================================================

-- Check if group is public (bypasses RLS on groups)
CREATE FUNCTION public.is_group_public(_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.groups
    WHERE id = _group_id AND visibility = 'public'
  );
$$;

-- Check if user is group creator (bypasses RLS on groups)
CREATE FUNCTION public.is_group_creator(_group_id UUID, _user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.groups
    WHERE id = _group_id AND created_by = _user_id
  );
$$;

-- Check if user is group member (bypasses RLS on group_members)
CREATE FUNCTION public.is_group_member(_group_id UUID, _user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = _group_id AND user_id = _user_id
  );
$$;

-- Check if user is group admin/owner (bypasses RLS on group_members)
CREATE FUNCTION public.is_group_admin(_group_id UUID, _user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = _group_id
    AND user_id = _user_id
    AND role IN ('owner', 'admin')
  );
$$;

-- ===================================================================
-- STEP 2: Drop ALL existing policies on group_members
-- ===================================================================
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'group_members'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.group_members', pol.policyname);
    END LOOP;
END $$;

-- ===================================================================
-- STEP 3: Drop ALL existing policies on groups
-- ===================================================================
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'groups'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.groups', pol.policyname);
    END LOOP;
END $$;

-- ===================================================================
-- STEP 4: Re-enable RLS
-- ===================================================================
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- ===================================================================
-- STEP 5: Create new policies for GROUPS (using SECURITY DEFINER functions)
-- ===================================================================

-- Anyone can view public groups
CREATE POLICY "groups_select_public"
ON public.groups FOR SELECT
USING (visibility = 'public');

-- Members can view private groups (uses function to avoid recursion)
CREATE POLICY "groups_select_member"
ON public.groups FOR SELECT
USING (public.is_group_member(id, auth.uid()));

-- Anyone can create groups
CREATE POLICY "groups_insert"
ON public.groups FOR INSERT
WITH CHECK (auth.uid() = created_by);

-- Owners/Admins can update groups (uses function to avoid recursion)
CREATE POLICY "groups_update"
ON public.groups FOR UPDATE
USING (public.is_group_admin(id, auth.uid()) OR created_by = auth.uid());

-- Owners can delete groups
CREATE POLICY "groups_delete"
ON public.groups FOR DELETE
USING (created_by = auth.uid());

-- ===================================================================
-- STEP 6: Create new policies for GROUP_MEMBERS (using SECURITY DEFINER functions)
-- ===================================================================

-- View members of public groups (uses function to avoid recursion)
CREATE POLICY "gm_select_public"
ON public.group_members FOR SELECT
USING (public.is_group_public(group_id));

-- Users can always see their own memberships
CREATE POLICY "gm_select_own"
ON public.group_members FOR SELECT
USING (user_id = auth.uid());

-- Group creators can see all members (uses function to avoid recursion)
CREATE POLICY "gm_select_creator"
ON public.group_members FOR SELECT
USING (public.is_group_creator(group_id, auth.uid()));

-- Members can see other members in same group (uses function to avoid recursion)
CREATE POLICY "gm_select_member"
ON public.group_members FOR SELECT
USING (public.is_group_member(group_id, auth.uid()));

-- Users can join public groups OR creators can add themselves
CREATE POLICY "gm_insert_public"
ON public.group_members FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND (
    public.is_group_public(group_id)
    OR public.is_group_creator(group_id, auth.uid())
  )
);

-- Group creators/admins can add other members
CREATE POLICY "gm_insert_creator"
ON public.group_members FOR INSERT
WITH CHECK (
  public.is_group_creator(group_id, auth.uid())
  OR public.is_group_admin(group_id, auth.uid())
);

-- Users can leave groups
CREATE POLICY "gm_delete_self"
ON public.group_members FOR DELETE
USING (user_id = auth.uid());

-- Group creators can remove members
CREATE POLICY "gm_delete_creator"
ON public.group_members FOR DELETE
USING (public.is_group_creator(group_id, auth.uid()));

-- ===================================================================
-- STEP 7: Grant execute permissions on functions
-- ===================================================================
GRANT EXECUTE ON FUNCTION public.is_group_public(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_group_creator(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_group_member(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_group_admin(UUID, UUID) TO authenticated;

-- ===================================================================
-- DONE! No more infinite recursion
-- ===================================================================
