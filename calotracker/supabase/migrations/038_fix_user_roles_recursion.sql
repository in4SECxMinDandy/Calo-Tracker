-- ============================================================
-- Migration 038: Fix infinite recursion in user_roles RLS policy
-- Created: 2026-02-28
-- Problem: policy 'ur_admin' on user_roles queries user_roles itself
--          → PostgrestException: infinite recursion detected (42P17)
-- Solution: Use a SECURITY DEFINER helper function to bypass RLS
--           when checking admin status, breaking the recursion.
-- ============================================================
-- ── 1. Create a SECURITY DEFINER helper to check admin role ──────────────────
-- This function bypasses RLS entirely, so no recursion when called from a policy.
DROP FUNCTION IF EXISTS public.is_admin(uuid);
CREATE OR REPLACE FUNCTION public.is_admin(p_user_id uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = '' AS $$
SELECT EXISTS (
        SELECT 1
        FROM public.user_roles
        WHERE user_id = p_user_id
            AND role = 'admin'
    );
$$;
-- ── 2. Recreate user_roles policies WITHOUT self-referencing queries ──────────
-- Own row: every authenticated user can read their own roles
DROP POLICY IF EXISTS ur_select_own ON public.user_roles;
CREATE POLICY ur_select_own ON public.user_roles FOR
SELECT TO authenticated USING (user_id = auth.uid());
-- Admin: use the SECURITY DEFINER helper to avoid recursion
DROP POLICY IF EXISTS ur_admin ON public.user_roles;
CREATE POLICY ur_admin ON public.user_roles FOR ALL TO authenticated USING (public.is_admin(auth.uid()));
-- ── 3. Recreate dependent policies on other tables that had the same issue ────
-- bans_admin
DROP POLICY IF EXISTS bans_admin ON public.bans;
CREATE POLICY bans_admin ON public.bans FOR ALL TO authenticated USING (public.is_admin(auth.uid()));
-- spam_flags — admins can view
DROP POLICY IF EXISTS "Admins can view spam flags" ON public.spam_flags;
CREATE POLICY "Admins can view spam flags" ON public.spam_flags FOR
SELECT TO authenticated USING (public.is_admin(auth.uid()));
-- spam_flags — admins can update
DROP POLICY IF EXISTS "Admins can update spam flags" ON public.spam_flags;
CREATE POLICY "Admins can update spam flags" ON public.spam_flags FOR
UPDATE TO authenticated USING (public.is_admin(auth.uid()));