-- ==========================================
-- SUPER NUCLEAR CLEANUP for Group Members RLS
-- ==========================================

-- 1. Drop EVERYTHING on group_members dynamically
-- This block will find ALL policies on 'group_members' and drop them one by one.
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

-- 2. Verify cleanup (Optional debug check inside this script won't show in UI, but ensures clean slate)

-- 3. Re-create the 6 Clean, Non-Recursive Policies
-- (These are the same simplified ones from 006)

-- 3.1 VIEW: Public groups (viewable by anyone)
CREATE POLICY "gm_select_public"
ON public.group_members FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.groups
    WHERE groups.id = group_members.group_id
    AND groups.visibility = 'public'
  )
);

-- 3.2 VIEW: Own membership (always see yourself)
CREATE POLICY "gm_select_own"
ON public.group_members FOR SELECT
USING (
  auth.uid() = user_id
);

-- 3.3 VIEW: Group Creators (see all members in their groups)
CREATE POLICY "gm_select_creator"
ON public.group_members FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.groups
    WHERE groups.id = group_members.group_id
    AND groups.created_by = auth.uid()
  )
);

-- 3.4 JOIN: Anyone can join public groups
CREATE POLICY "gm_insert_join"
ON public.group_members FOR INSERT
WITH CHECK (
  auth.uid() = user_id -- Can only add self
  AND 
  EXISTS (
    SELECT 1 FROM public.groups
    WHERE groups.id = group_members.group_id
    AND groups.visibility = 'public' -- Only public groups (Private requires invite logic separately)
  )
);

-- 3.5 LEAVE: Can remove self
CREATE POLICY "gm_delete_leave"
ON public.group_members FOR DELETE
USING (
  auth.uid() = user_id
);

-- 3.6 KICK: Creator can remove anyone
CREATE POLICY "gm_delete_creator"
ON public.group_members FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.groups
    WHERE groups.id = group_members.group_id
    AND groups.created_by = auth.uid()
  )
);

-- Ensure RLS is enabled
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
