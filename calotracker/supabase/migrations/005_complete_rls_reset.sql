-- ===================================================================
-- FIX INFINITE RECURSION - COMPLETE RESET
-- Drop ALL existing policies and recreate from scratch
-- ===================================================================

-- Drop ALL existing policies on group_members
DO $$ 
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'group_members'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.group_members', policy_record.policyname);
    END LOOP;
END $$;

-- Disable RLS temporarily
ALTER TABLE public.group_members DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- ===================================================================
-- CREATE NEW POLICIES (SIMPLIFIED - NO RECURSION)
-- ===================================================================

-- 1. Anyone can view public group members
CREATE POLICY "Anyone can view public group members v2"
  ON public.group_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.groups
      WHERE groups.id = group_members.group_id 
      AND groups.visibility = 'public'
    )
  );

-- 2. Members can view their own group memberships
CREATE POLICY "Members can view own memberships v2"
  ON public.group_members FOR SELECT
  USING (auth.uid() = user_id);

-- 3. Users can join public groups
CREATE POLICY "Users can join public groups v2"
  ON public.group_members FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.groups
      WHERE groups.id = group_id 
      AND groups.visibility = 'public'
      AND (groups.require_approval = false OR groups.max_members IS NULL OR 
           (SELECT COUNT(*) FROM public.group_members WHERE group_id = groups.id) < groups.max_members)
    )
  );

-- 4. Users can leave groups
CREATE POLICY "Users can leave groups v2"
  ON public.group_members FOR DELETE
  USING (auth.uid() = user_id);

-- 5. Group creators can manage members (FIXED - no recursion)
CREATE POLICY "Group creators can manage members v2"
  ON public.group_members FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.groups
      WHERE groups.id = group_id 
      AND groups.created_by = auth.uid()
    )
  );

-- 6. Group creators can view all members
CREATE POLICY "Group creators can view all members v2"
  ON public.group_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.groups
      WHERE groups.id = group_id 
      AND groups.created_by = auth.uid()
    )
  );

-- ===================================================================
-- VERIFY
-- ===================================================================
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE tablename = 'group_members';
