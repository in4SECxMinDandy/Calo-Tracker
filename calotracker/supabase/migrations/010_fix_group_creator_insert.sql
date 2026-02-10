-- ===================================================================
-- FIX: Allow group creators to add themselves as owner
-- Problem: gm_insert_public only allowed public groups, preventing
--          creators from adding themselves to private/invite-only groups
-- ===================================================================

-- Drop existing INSERT policies on group_members
DROP POLICY IF EXISTS "gm_insert_public" ON public.group_members;
DROP POLICY IF EXISTS "gm_insert_creator" ON public.group_members;

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

-- ===================================================================
-- DONE! Creators can now add themselves to any group they create
-- ===================================================================
