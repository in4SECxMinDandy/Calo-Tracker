-- ============================================
-- Migration 020: Fix infinite recursion in groups/group_members policies
-- ============================================
-- Problem: groups_select_member queries group_members, 
--          gm_select_public queries groups → infinite loop
-- Solution: Use SECURITY DEFINER helper functions to bypass RLS
-- ============================================
-- Drop existing functions first with CASCADE to remove dependent policies
-- All policies are recreated below in this migration
DROP FUNCTION IF EXISTS public.is_group_member(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_public(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_creator(UUID, UUID) CASCADE;
-- Helper function: check if user is member of a group (bypasses RLS)
CREATE FUNCTION public.is_group_member(p_group_id UUID, p_user_id UUID) RETURNS BOOLEAN AS $$
SELECT EXISTS (
        SELECT 1
        FROM public.group_members
        WHERE group_id = p_group_id
            AND user_id = p_user_id
    );
$$ LANGUAGE sql SECURITY DEFINER
SET search_path = '';
-- Helper function: check if group is public (bypasses RLS)
CREATE FUNCTION public.is_group_public(p_group_id UUID) RETURNS BOOLEAN AS $$
SELECT EXISTS (
        SELECT 1
        FROM public.groups
        WHERE id = p_group_id
            AND visibility = 'public'
    );
$$ LANGUAGE sql SECURITY DEFINER
SET search_path = '';
-- Helper function: check if user is group creator (bypasses RLS)
CREATE FUNCTION public.is_group_creator(p_group_id UUID, p_user_id UUID) RETURNS BOOLEAN AS $$
SELECT EXISTS (
        SELECT 1
        FROM public.groups
        WHERE id = p_group_id
            AND created_by = p_user_id
    );
$$ LANGUAGE sql SECURITY DEFINER
SET search_path = '';
-- ============================================
-- Recreate GROUPS policies using helper functions
-- ============================================
DROP POLICY IF EXISTS "groups_select_public" ON public.groups;
DROP POLICY IF EXISTS "groups_select_member" ON public.groups;
DROP POLICY IF EXISTS "groups_insert" ON public.groups;
DROP POLICY IF EXISTS "groups_update" ON public.groups;
DROP POLICY IF EXISTS "groups_delete" ON public.groups;
-- Anyone authenticated can see public groups (no cross-table reference)
CREATE POLICY "groups_select_public" ON public.groups FOR
SELECT TO authenticated USING (visibility = 'public');
-- Members can see their private groups (uses SECURITY DEFINER function)
CREATE POLICY "groups_select_member" ON public.groups FOR
SELECT TO authenticated USING (public.is_group_member(id, auth.uid()));
-- Creator can insert
CREATE POLICY "groups_insert" ON public.groups FOR
INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
-- Creator can update
CREATE POLICY "groups_update" ON public.groups FOR
UPDATE TO authenticated USING (auth.uid() = created_by);
-- Creator can delete
CREATE POLICY "groups_delete" ON public.groups FOR DELETE TO authenticated USING (auth.uid() = created_by);
-- ============================================
-- Recreate GROUP_MEMBERS policies using helper functions
-- ============================================
DROP POLICY IF EXISTS "gm_select_public" ON public.group_members;
DROP POLICY IF EXISTS "gm_select_own" ON public.group_members;
DROP POLICY IF EXISTS "gm_select_creator" ON public.group_members;
DROP POLICY IF EXISTS "gm_select_member" ON public.group_members;
DROP POLICY IF EXISTS "gm_insert_public" ON public.group_members;
DROP POLICY IF EXISTS "gm_insert_creator" ON public.group_members;
DROP POLICY IF EXISTS "gm_delete_self" ON public.group_members;
DROP POLICY IF EXISTS "gm_delete_creator" ON public.group_members;
-- Can see members of public groups (uses SECURITY DEFINER function)
CREATE POLICY "gm_select_public" ON public.group_members FOR
SELECT TO authenticated USING (public.is_group_public(group_id));
-- Can see own memberships
CREATE POLICY "gm_select_own" ON public.group_members FOR
SELECT TO authenticated USING (auth.uid() = user_id);
-- Group creator can see all members 
CREATE POLICY "gm_select_creator" ON public.group_members FOR
SELECT TO authenticated USING (public.is_group_creator(group_id, auth.uid()));
-- Members can see other members
CREATE POLICY "gm_select_member" ON public.group_members FOR
SELECT TO authenticated USING (public.is_group_member(group_id, auth.uid()));
-- Can join public groups
CREATE POLICY "gm_insert_public" ON public.group_members FOR
INSERT TO authenticated WITH CHECK (
        auth.uid() = user_id
        AND public.is_group_public(group_id)
    );
-- Group creator can add members
CREATE POLICY "gm_insert_creator" ON public.group_members FOR
INSERT TO authenticated WITH CHECK (public.is_group_creator(group_id, auth.uid()));
-- Can leave group (delete own membership)
CREATE POLICY "gm_delete_self" ON public.group_members FOR DELETE TO authenticated USING (auth.uid() = user_id);
-- Group creator can remove members
CREATE POLICY "gm_delete_creator" ON public.group_members FOR DELETE TO authenticated USING (public.is_group_creator(group_id, auth.uid()));