-- =============================================================================
-- CaloTracker - FIX RLS INFINITE RECURSION
-- =============================================================================
-- Run this script in Supabase Dashboard > SQL Editor
-- This fixes the infinite recursion error in group_members policies
-- =============================================================================

-- Step 1: Drop the problematic policies
DROP POLICY IF EXISTS "Members can view group members" ON public.group_members;
DROP POLICY IF EXISTS "Anyone can view public group members" ON public.group_members;
DROP POLICY IF EXISTS "Users can join public groups" ON public.group_members;
DROP POLICY IF EXISTS "Users can leave groups" ON public.group_members;
DROP POLICY IF EXISTS "Users can view own memberships" ON public.group_members;
DROP POLICY IF EXISTS "Anyone can view public group members v2" ON public.group_members;
DROP POLICY IF EXISTS "Members can view group members v2" ON public.group_members;
DROP POLICY IF EXISTS "Users can join public groups v2" ON public.group_members;
DROP POLICY IF EXISTS "Users can leave groups v2" ON public.group_members;
DROP POLICY IF EXISTS "Admins can manage members" ON public.group_members;

-- Step 2: Create a security definer function to check group membership
-- This avoids infinite recursion by using SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.is_group_member(check_group_id UUID, check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = check_group_id AND user_id = check_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Step 3: Create fixed policies using the helper function

-- Policy: Anyone can view their own memberships
CREATE POLICY "Users can view own memberships"
  ON public.group_members FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Anyone can view members of public groups
CREATE POLICY "Anyone can view public group members v2"
  ON public.group_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_id AND g.visibility = 'public'
    )
  );

-- Policy: Group members can view other members in the same group
-- Uses the SECURITY DEFINER function to avoid recursion
CREATE POLICY "Members can view group members v2"
  ON public.group_members FOR SELECT
  USING (
    public.is_group_member(group_id, auth.uid())
  );

-- Policy: Users can join public groups
CREATE POLICY "Users can join public groups v2"
  ON public.group_members FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_id AND g.visibility = 'public'
    )
  );

-- Policy: Users can leave groups (delete their own membership)
CREATE POLICY "Users can leave groups v2"
  ON public.group_members FOR DELETE
  USING (auth.uid() = user_id);

-- Policy: Group admins can remove members
CREATE POLICY "Admins can manage members"
  ON public.group_members FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_id AND g.created_by = auth.uid()
    )
  );

-- =============================================================================
-- DONE! The infinite recursion should now be fixed.
-- =============================================================================

-- Verify policies
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'group_members';
