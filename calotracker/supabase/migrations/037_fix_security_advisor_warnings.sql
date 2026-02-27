-- ============================================================
-- Migration 037: Fix Supabase Security Advisor Warnings
-- Created: 2026-02-25
-- Fixes:
--   [ERROR] SECURITY DEFINER views (health_report_data, friends_view)
--   [WARN]  notif_insert RLS always-true WITH CHECK
--   [WARN]  ~30 functions with mutable search_path
--   [WARN]  Anonymous access policies on ~20 tables
-- ============================================================
-- ── 1. Fix SECURITY DEFINER views → SECURITY INVOKER ────────────────────────
-- These views used creator's permissions instead of the querying user's,
-- bypassing RLS entirely. Recreating with SECURITY INVOKER restores RLS.
-- Recreate health_report_data with SECURITY INVOKER
-- (exact schema from migration 026, just adding security_invoker option)
DROP VIEW IF EXISTS public.health_report_data;
CREATE VIEW public.health_report_data WITH (security_invoker = true) AS
SELECT uhr.user_id,
    uhr.date,
    uhr.weight,
    uhr.calo_intake,
    uhr.calo_burned,
    uhr.net_calo,
    uhr.water_intake,
    uhr.steps,
    uhr.sleep_hours,
    uhr.sleep_quality,
    uhr.workouts_completed,
    uhr.meals_logged,
    LAG(uhr.weight) OVER (
        PARTITION BY uhr.user_id
        ORDER BY uhr.date
    ) AS prev_weight,
    p.display_name,
    p.height,
    p.goal,
    p.avatar_url
FROM public.user_health_records uhr
    JOIN public.profiles p ON p.id = uhr.user_id
WHERE uhr.user_id = auth.uid();
GRANT SELECT ON public.health_report_data TO authenticated;
-- Recreate friends_view with SECURITY INVOKER
-- (exact schema from migration 026, friendships uses user_id + friend_id)
DROP VIEW IF EXISTS public.friends_view;
CREATE VIEW public.friends_view WITH (security_invoker = true) AS
SELECT f.id,
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
WHERE f.user_id = auth.uid()
    OR f.friend_id = auth.uid();
GRANT SELECT ON public.friends_view TO authenticated;
-- ── 2. Fix notif_insert RLS — WITH CHECK (true) is too permissive ────────────
-- Users should only be able to insert notifications targeting themselves
DROP POLICY IF EXISTS notif_insert ON public.notifications;
CREATE POLICY notif_insert ON public.notifications FOR
INSERT TO authenticated WITH CHECK (user_id = auth.uid());
-- ── 3. Fix function_search_path_mutable ─────────────────────────────────────
-- Add SET search_path = public to every vulnerable function.
-- Note: functions that already have SET search_path = '' (like those in
-- migration 026 using SECURITY DEFINER) are already safe. We only fix
-- the ones flagged by the advisor.
ALTER FUNCTION public.update_challenge_participant_count()
SET search_path = public;
ALTER FUNCTION public.auto_unfriend_on_block()
SET search_path = public;
ALTER FUNCTION public.prevent_blocked_friend_request()
SET search_path = public;
ALTER FUNCTION public.prevent_blocked_message()
SET search_path = public;
ALTER FUNCTION public.prevent_blocked_group_join()
SET search_path = public;
ALTER FUNCTION public.update_content_reports_updated_at()
SET search_path = public;
ALTER FUNCTION public.set_content_report_reviewed_at()
SET search_path = public;
ALTER FUNCTION public.prevent_duplicate_report()
SET search_path = public;
ALTER FUNCTION public.check_report_rate_limit()
SET search_path = public;
ALTER FUNCTION public.check_friend_request_rate_limit()
SET search_path = public;
ALTER FUNCTION public.check_group_creation_rate_limit()
SET search_path = public;
ALTER FUNCTION public.check_message_rate_limit()
SET search_path = public;
ALTER FUNCTION public.update_challenge_participants_updated_at()
SET search_path = public;
ALTER FUNCTION public.set_challenge_completed_at()
SET search_path = public;
ALTER FUNCTION public.increment_challenges_completed()
SET search_path = public;
ALTER FUNCTION public.auto_flag_highly_reported_content()
SET search_path = public;
ALTER FUNCTION public.update_device_tokens_updated_at()
SET search_path = public;
ALTER FUNCTION public.deactivate_old_device_tokens()
SET search_path = public;
ALTER FUNCTION public.cleanup_inactive_device_tokens()
SET search_path = public;
ALTER FUNCTION public.create_default_notification_preferences()
SET search_path = public;
ALTER FUNCTION public.update_profiles_search_vector()
SET search_path = public;
ALTER FUNCTION public.update_groups_search_vector()
SET search_path = public;
ALTER FUNCTION public.update_posts_search_vector()
SET search_path = public;
ALTER FUNCTION public.get_trending_searches(integer)
SET search_path = public;
ALTER FUNCTION public.check_post_rate_limit()
SET search_path = public;
ALTER FUNCTION public.check_comment_rate_limit()
SET search_path = public;
ALTER FUNCTION public.check_like_rate_limit()
SET search_path = public;
ALTER FUNCTION public.detect_duplicate_content_spam()
SET search_path = public;
-- Wrap all potentially-ambiguous signatures in a DO block for safety
DO $$
DECLARE r RECORD;
BEGIN -- For every function in public schema that the advisor flagged,
-- find its exact oid and alter it directly — no arg-list guessing.
FOR r IN
SELECT p.oid,
    p.proname
FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
    AND p.proname IN (
        'is_blocked',
        'get_user_fcm_tokens',
        'search_profiles',
        'search_groups',
        'search_posts',
        'global_search',
        'update_presence'
    ) LOOP EXECUTE format(
        'ALTER FUNCTION public.%I(%s) SET search_path = public',
        r.proname,
        pg_get_function_identity_arguments(r.oid)
    );
END LOOP;
END $$;
-- ── 4. Fix anonymous access — change TO public → TO authenticated ────────────
-- Tables that should NEVER be accessible to anon users.
-- achievements
DROP POLICY IF EXISTS achievements_select ON public.achievements;
CREATE POLICY achievements_select ON public.achievements FOR
SELECT TO authenticated USING (true);
-- bans
DROP POLICY IF EXISTS bans_select ON public.bans;
CREATE POLICY bans_select ON public.bans FOR
SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS bans_admin ON public.bans;
CREATE POLICY bans_admin ON public.bans FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles ur
        WHERE ur.user_id = auth.uid()
            AND ur.role = 'admin'
    )
);
-- user_achievements
DROP POLICY IF EXISTS ua_select ON public.user_achievements;
CREATE POLICY ua_select ON public.user_achievements FOR
SELECT TO authenticated USING (true);
-- user_health_records
DROP POLICY IF EXISTS uhr_select ON public.user_health_records;
CREATE POLICY uhr_select ON public.user_health_records FOR
SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS uhr_update ON public.user_health_records;
CREATE POLICY uhr_update ON public.user_health_records FOR
UPDATE TO authenticated USING (user_id = auth.uid());
-- user_presence
DROP POLICY IF EXISTS presence_select ON public.user_presence;
CREATE POLICY presence_select ON public.user_presence FOR
SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS presence_update ON public.user_presence;
CREATE POLICY presence_update ON public.user_presence FOR
UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
-- profiles
DROP POLICY IF EXISTS profiles_select ON public.profiles;
CREATE POLICY profiles_select ON public.profiles FOR
SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles FOR
UPDATE TO authenticated USING (id = auth.uid());
-- notifications
DROP POLICY IF EXISTS notif_select_own ON public.notifications;
CREATE POLICY notif_select_own ON public.notifications FOR
SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS notif_update_own ON public.notifications;
CREATE POLICY notif_update_own ON public.notifications FOR
UPDATE TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS notif_delete_own ON public.notifications;
CREATE POLICY notif_delete_own ON public.notifications FOR DELETE TO authenticated USING (user_id = auth.uid());
-- follows
DROP POLICY IF EXISTS follows_select ON public.follows;
CREATE POLICY follows_select ON public.follows FOR
SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS follows_delete ON public.follows;
CREATE POLICY follows_delete ON public.follows FOR DELETE TO authenticated USING (follower_id = auth.uid());
-- likes
DROP POLICY IF EXISTS likes_select ON public.likes;
CREATE POLICY likes_select ON public.likes FOR
SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS likes_delete ON public.likes;
CREATE POLICY likes_delete ON public.likes FOR DELETE TO authenticated USING (user_id = auth.uid());
-- saved_posts
DROP POLICY IF EXISTS sp_select ON public.saved_posts;
CREATE POLICY sp_select ON public.saved_posts FOR
SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS sp_delete ON public.saved_posts;
CREATE POLICY sp_delete ON public.saved_posts FOR DELETE TO authenticated USING (user_id = auth.uid());
-- search_history
DROP POLICY IF EXISTS "Users can manage own search history" ON public.search_history;
CREATE POLICY "Users can manage own search history" ON public.search_history FOR ALL TO authenticated USING (user_id = auth.uid());
-- notification_preferences
DROP POLICY IF EXISTS "Users can manage own notification preferences" ON public.notification_preferences;
CREATE POLICY "Users can manage own notification preferences" ON public.notification_preferences FOR ALL TO authenticated USING (user_id = auth.uid());
-- notification_queue (service_role only)
DROP POLICY IF EXISTS "Service role can access notification queue" ON public.notification_queue;
CREATE POLICY "Service role can access notification queue" ON public.notification_queue FOR ALL TO service_role USING (true);
-- user_device_tokens
DROP POLICY IF EXISTS "Users can view own tokens" ON public.user_device_tokens;
CREATE POLICY "Users can view own tokens" ON public.user_device_tokens FOR
SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can update own tokens" ON public.user_device_tokens;
CREATE POLICY "Users can update own tokens" ON public.user_device_tokens FOR
UPDATE TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can delete own tokens" ON public.user_device_tokens;
CREATE POLICY "Users can delete own tokens" ON public.user_device_tokens FOR DELETE TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Service role can access all tokens" ON public.user_device_tokens;
CREATE POLICY "Service role can access all tokens" ON public.user_device_tokens FOR ALL TO service_role USING (true);
-- spam_flags
DROP POLICY IF EXISTS "Admins can view spam flags" ON public.spam_flags;
CREATE POLICY "Admins can view spam flags" ON public.spam_flags FOR
SELECT TO authenticated USING (
        EXISTS (
            SELECT 1
            FROM public.user_roles ur
            WHERE ur.user_id = auth.uid()
                AND ur.role = 'admin'
        )
    );
DROP POLICY IF EXISTS "Admins can update spam flags" ON public.spam_flags;
CREATE POLICY "Admins can update spam flags" ON public.spam_flags FOR
UPDATE TO authenticated USING (
        EXISTS (
            SELECT 1
            FROM public.user_roles ur
            WHERE ur.user_id = auth.uid()
                AND ur.role = 'admin'
        )
    );
-- user_roles
DROP POLICY IF EXISTS ur_select_own ON public.user_roles;
CREATE POLICY ur_select_own ON public.user_roles FOR
SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS ur_admin ON public.user_roles;
CREATE POLICY ur_admin ON public.user_roles FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles ur2
        WHERE ur2.user_id = auth.uid()
            AND ur2.role = 'admin'
    )
);
-- storage.objects — restrict avatar/post policies to authenticated
DROP POLICY IF EXISTS storage_avatars_read ON storage.objects;
CREATE POLICY storage_avatars_read ON storage.objects FOR
SELECT TO authenticated USING (bucket_id = 'avatars');
DROP POLICY IF EXISTS storage_avatars_update ON storage.objects;
CREATE POLICY storage_avatars_update ON storage.objects FOR
UPDATE TO authenticated USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name)) [1]
    );
DROP POLICY IF EXISTS storage_avatars_delete ON storage.objects;
CREATE POLICY storage_avatars_delete ON storage.objects FOR DELETE TO authenticated USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name)) [1]
);
DROP POLICY IF EXISTS storage_posts_read ON storage.objects;
CREATE POLICY storage_posts_read ON storage.objects FOR
SELECT TO authenticated USING (bucket_id = 'posts');
DROP POLICY IF EXISTS storage_posts_delete ON storage.objects;
CREATE POLICY storage_posts_delete ON storage.objects FOR DELETE TO authenticated USING (
    bucket_id = 'posts'
    AND auth.uid()::text = (storage.foldername(name)) [1]
);
-- ── NOTE: auth_leaked_password_protection ───────────────────────────────────
-- Cannot be fixed via SQL — enable manually in Supabase Dashboard:
-- Authentication → Settings → Enable "Leaked Password Protection"
-- (Requires Pro plan or higher)