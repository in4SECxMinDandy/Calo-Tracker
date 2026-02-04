-- ===================================================================
-- FIX INFINITE RECURSION - NUCLEAR OPTION
-- This script drops ALL policies explicitly by name
-- ===================================================================
-- Step 1: Drop ALL existing policies (both old and new v2 versions)
DROP POLICY IF EXISTS "gm_select_public" ON public.group_members;
DROP POLICY IF EXISTS "gm_select_own" ON public.group_members;
DROP POLICY IF EXISTS "gm_select_creator" ON public.group_members;
DROP POLICY IF EXISTS "gm_insert_join" ON public.group_members;
DROP POLICY IF EXISTS "gm_delete_leave" ON public.group_members;
DROP POLICY IF EXISTS "gm_delete_creator" ON public.group_members;
DROP POLICY IF EXISTS "Anyone can view public group members" ON public.group_members;
DROP POLICY IF EXISTS "Anyone can view public group members v2" ON public.group_members;
DROP POLICY IF EXISTS "Members can view own memberships" ON public.group_members;
DROP POLICY IF EXISTS "Members can view own memberships v2" ON public.group_members;
DROP POLICY IF EXISTS "Users can join public groups" ON public.group_members;
DROP POLICY IF EXISTS "Users can join public groups v2" ON public.group_members;
DROP POLICY IF EXISTS "Users can leave groups" ON public.group_members;
DROP POLICY IF EXISTS "Users can leave groups v2" ON public.group_members;
DROP POLICY IF EXISTS "Group creators can manage members" ON public.group_members;
DROP POLICY IF EXISTS "Group creators can manage members v2" ON public.group_members;
DROP POLICY IF EXISTS "Group creators can view all members" ON public.group_members;
DROP POLICY IF EXISTS "Group creators can view all members v2" ON public.group_members;
-- Drop any other possible policies
DROP POLICY IF EXISTS "group_members_select_policy" ON public.group_members;
DROP POLICY IF EXISTS "group_members_insert_policy" ON public.group_members;
DROP POLICY IF EXISTS "group_members_delete_policy" ON public.group_members;
DROP POLICY IF EXISTS "group_members_update_policy" ON public.group_members;
-- Step 2: Verify all policies are dropped
SELECT 'BEFORE RECREATE - Policies on group_members:' as step;
SELECT policyname
FROM pg_policies
WHERE tablename = 'group_members';
-- Step 3: Temporarily disable RLS to allow operations
ALTER TABLE public.group_members DISABLE ROW LEVEL SECURITY;
-- Step 4: Re-enable RLS
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
-- ===================================================================
-- Step 5: CREATE SIMPLIFIED POLICIES (NO RECURSION)
-- KEY: Only reference 'groups' table, NEVER self-reference 'group_members'
-- ===================================================================
-- Policy 1: SELECT - Allow authenticated users to select from group_members
-- if the group is public (check groups table only)
CREATE POLICY "gm_select_public" ON public.group_members FOR
SELECT TO authenticated USING (
    EXISTS (
      SELECT 1
      FROM public.groups g
      WHERE g.id = group_members.group_id
        AND g.visibility = 'public'
    )
  );
-- Policy 2: SELECT - Users can always see their own memberships
CREATE POLICY "gm_select_own" ON public.group_members FOR
SELECT TO authenticated USING (user_id = auth.uid());
-- Policy 3: SELECT - Group creators can see all members of their groups
CREATE POLICY "gm_select_creator" ON public.group_members FOR
SELECT TO authenticated USING (
    EXISTS (
      SELECT 1
      FROM public.groups g
      WHERE g.id = group_members.group_id
        AND g.created_by = auth.uid()
    )
  );
-- Policy 4: INSERT - Users can join public groups (add themselves only)
CREATE POLICY "gm_insert_join" ON public.group_members FOR
INSERT TO authenticated WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.groups g
      WHERE g.id = group_id
        AND g.visibility = 'public'
    )
  );
-- Policy 5: DELETE - Users can leave groups (remove themselves only)
CREATE POLICY "gm_delete_leave" ON public.group_members FOR DELETE TO authenticated USING (user_id = auth.uid());
-- Policy 6: DELETE - Group creators can remove any member
CREATE POLICY "gm_delete_creator" ON public.group_members FOR DELETE TO authenticated USING (
  EXISTS (
    SELECT 1
    FROM public.groups g
    WHERE g.id = group_members.group_id
      AND g.created_by = auth.uid()
  )
);
-- ===================================================================
-- Step 6: VERIFY FINAL STATE
-- ===================================================================
SELECT 'AFTER RECREATE - Final policies on group_members:' as step;
SELECT schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'group_members'
ORDER BY policyname;