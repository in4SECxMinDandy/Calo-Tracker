-- ============================================
-- NOTE: This migration is SUPERSEDED by 019_fix_security_warnings.sql
-- which includes all these fixes plus additional security hardening.
-- If you already ran 018, running 019 will safely re-apply (DROP IF EXISTS + CREATE).
-- If you haven't run 018 yet, you can SKIP this and run 019 directly.
-- ============================================
-- Fix RLS policies for comments and likes tables
-- Error: "new row violates row-level security policy for table comments"
-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Anyone can view non-hidden comments" ON public.comments;
DROP POLICY IF EXISTS "Users can create comments" ON public.comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON public.comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON public.comments;
DROP POLICY IF EXISTS "Admins have full access to comments" ON public.comments;
DROP POLICY IF EXISTS "Anyone can view likes" ON public.likes;
DROP POLICY IF EXISTS "Users can create likes" ON public.likes;
DROP POLICY IF EXISTS "Users can delete their own likes" ON public.likes;
-- Ensure RLS is enabled
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
-- COMMENTS POLICIES
CREATE POLICY "Anyone can view non-hidden comments" ON public.comments FOR
SELECT USING (is_hidden = false);
CREATE POLICY "Users can create comments" ON public.comments FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own comments" ON public.comments FOR
UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own comments" ON public.comments FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can view their own comments" ON public.comments;
CREATE POLICY "Users can view their own comments" ON public.comments FOR
SELECT USING (auth.uid() = user_id);
-- LIKES POLICIES
CREATE POLICY "Anyone can view likes" ON public.likes FOR
SELECT USING (true);
CREATE POLICY "Users can create likes" ON public.likes FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own likes" ON public.likes FOR DELETE USING (auth.uid() = user_id);
-- ADMIN OVERRIDE for comments
CREATE POLICY "Admins have full access to comments" ON public.comments FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles
        WHERE user_id = auth.uid()
            AND role = 'admin'
    )
);