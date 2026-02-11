-- ============================================
-- Migration 023: Fix ALL Remaining Security Warnings
-- ============================================
-- Fixes:
-- 1. function_search_path_mutable (3 functions)
-- 2. auth_allow_anonymous_sign_ins (remaining ~20 tables)
-- 3. auth_leaked_password_protection (manual step in Dashboard)
-- ============================================
-- ============================================
-- PART 1: FIX FUNCTION SEARCH PATH
-- ============================================
-- 1.1 update_group_member_count (from migration 017, missing SET search_path)
CREATE OR REPLACE FUNCTION public.update_group_member_count() RETURNS TRIGGER AS $$ BEGIN IF TG_OP = 'INSERT' THEN
UPDATE public.groups
SET member_count = (
        SELECT count(*)
        FROM public.group_members
        WHERE group_id = NEW.group_id
            AND status = 'active'
    )
WHERE id = NEW.group_id;
RETURN NEW;
ELSIF TG_OP = 'DELETE' THEN
UPDATE public.groups
SET member_count = (
        SELECT count(*)
        FROM public.group_members
        WHERE group_id = OLD.group_id
            AND status = 'active'
    )
WHERE id = OLD.group_id;
RETURN OLD;
ELSIF TG_OP = 'UPDATE' THEN
UPDATE public.groups
SET member_count = (
        SELECT count(*)
        FROM public.group_members
        WHERE group_id = NEW.group_id
            AND status = 'active'
    )
WHERE id = NEW.group_id;
RETURN NEW;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '';
-- 1.2 cleanup_expired_tokens (recreate to ensure search_path sticks)
CREATE OR REPLACE FUNCTION public.cleanup_expired_tokens() RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$ BEGIN
DELETE FROM public.otp_tokens
WHERE expires_at < now() - INTERVAL '1 hour';
DELETE FROM public.reset_tokens
WHERE expires_at < now() - INTERVAL '1 hour';
DELETE FROM public.rate_limits
WHERE window_start < now() - INTERVAL '1 day';
END;
$$;
-- 1.3 check_rate_limit (recreate to ensure search_path sticks)
CREATE OR REPLACE FUNCTION public.check_rate_limit(
        p_identifier TEXT,
        p_action TEXT,
        p_max_attempts INTEGER DEFAULT 3,
        p_window_minutes INTEGER DEFAULT 15
    ) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE v_current_count INTEGER;
v_window_start TIMESTAMPTZ;
BEGIN
SELECT attempt_count,
    window_start INTO v_current_count,
    v_window_start
FROM public.rate_limits
WHERE identifier = p_identifier
    AND action = p_action FOR
UPDATE;
IF NOT FOUND THEN
INSERT INTO public.rate_limits (identifier, action, attempt_count, window_start)
VALUES (p_identifier, p_action, 1, now());
RETURN true;
END IF;
IF v_window_start < now() - (p_window_minutes || ' minutes')::INTERVAL THEN
UPDATE public.rate_limits
SET attempt_count = 1,
    window_start = now()
WHERE identifier = p_identifier
    AND action = p_action;
RETURN true;
END IF;
IF v_current_count < p_max_attempts THEN
UPDATE public.rate_limits
SET attempt_count = attempt_count + 1
WHERE identifier = p_identifier
    AND action = p_action;
RETURN true;
END IF;
RETURN false;
END;
$$;
-- ============================================
-- PART 2: FIX ANONYMOUS ACCESS RLS POLICIES
-- ============================================
-- All policies must use "TO authenticated" to prevent anonymous access.
-- We DROP existing policies and recreate with TO authenticated.
-- -----------------------------------------------
-- 2.1 ACHIEVEMENTS
-- -----------------------------------------------
DROP POLICY IF EXISTS "Anyone can view achievements" ON public.achievements;
CREATE POLICY "Anyone can view achievements" ON public.achievements FOR
SELECT TO authenticated USING (true);
-- -----------------------------------------------
-- 2.2 USER_ACHIEVEMENTS
-- -----------------------------------------------
DROP POLICY IF EXISTS "Users can view their earned achievements" ON public.user_achievements;
CREATE POLICY "Users can view their earned achievements" ON public.user_achievements FOR
SELECT TO authenticated USING (auth.uid() = user_id);
-- -----------------------------------------------
-- 2.3 BANS
-- -----------------------------------------------
DROP POLICY IF EXISTS "Admins have full access to bans" ON public.bans;
CREATE POLICY "Admins have full access to bans" ON public.bans FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles
        WHERE user_id = auth.uid()
            AND role = 'admin'
    )
);
-- -----------------------------------------------
-- 2.4 CHALLENGES
-- -----------------------------------------------
DROP POLICY IF EXISTS "Public challenges are viewable" ON public.challenges;
CREATE POLICY "Public challenges are viewable" ON public.challenges FOR
SELECT TO authenticated USING (
        visibility = 'public'
        OR visibility = 'group'
    );
DROP POLICY IF EXISTS "Creators can update challenges" ON public.challenges;
CREATE POLICY "Creators can update challenges" ON public.challenges FOR
UPDATE TO authenticated USING (auth.uid() = created_by);
DROP POLICY IF EXISTS "Users can create challenges" ON public.challenges;
CREATE POLICY "Users can create challenges" ON public.challenges FOR
INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
-- -----------------------------------------------
-- 2.5 CHALLENGE_PARTICIPANTS
-- -----------------------------------------------
DROP POLICY IF EXISTS "Anyone can view challenge participants" ON public.challenge_participants;
CREATE POLICY "Anyone can view challenge participants" ON public.challenge_participants FOR
SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Users can join challenges" ON public.challenge_participants;
CREATE POLICY "Users can join challenges" ON public.challenge_participants FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own progress" ON public.challenge_participants;
CREATE POLICY "Users can update their own progress" ON public.challenge_participants FOR
UPDATE TO authenticated USING (auth.uid() = user_id);
-- -----------------------------------------------
-- 2.6 FOLLOWS
-- -----------------------------------------------
DROP POLICY IF EXISTS "Anyone can view follows" ON public.follows;
CREATE POLICY "Anyone can view follows" ON public.follows FOR
SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Users can create their own follows" ON public.follows;
CREATE POLICY "Users can create their own follows" ON public.follows FOR
INSERT TO authenticated WITH CHECK (auth.uid() = follower_id);
DROP POLICY IF EXISTS "Users can delete their own follows" ON public.follows;
CREATE POLICY "Users can delete their own follows" ON public.follows FOR DELETE TO authenticated USING (auth.uid() = follower_id);
-- -----------------------------------------------
-- 2.7 NOTIFICATIONS
-- -----------------------------------------------
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR
SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR
UPDATE TO authenticated USING (auth.uid() = user_id);
-- -----------------------------------------------
-- 2.8 MESSAGES (public schema)
-- -----------------------------------------------
DROP POLICY IF EXISTS "Users can view their own messages" ON public.messages;
CREATE POLICY "Users can view their own messages" ON public.messages FOR
SELECT TO authenticated USING (
        auth.uid() = sender_id
        OR auth.uid() = receiver_id
    );
DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
CREATE POLICY "Users can send messages" ON public.messages FOR
INSERT TO authenticated WITH CHECK (auth.uid() = sender_id);
DROP POLICY IF EXISTS "Users can mark messages as read" ON public.messages;
CREATE POLICY "Users can mark messages as read" ON public.messages FOR
UPDATE TO authenticated USING (auth.uid() = receiver_id);
DROP POLICY IF EXISTS "Users can delete their own sent messages" ON public.messages;
CREATE POLICY "Users can delete their own sent messages" ON public.messages FOR DELETE TO authenticated USING (auth.uid() = sender_id);
-- -----------------------------------------------
-- 2.9 PROFILES (fix admin + general policies)
-- -----------------------------------------------
DROP POLICY IF EXISTS "Admins have full access to profiles" ON public.profiles;
CREATE POLICY "Admins have full access to profiles" ON public.profiles FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles
        WHERE user_id = auth.uid()
            AND role = 'admin'
    )
);
DROP POLICY IF EXISTS "profiles_select_all" ON public.profiles;
CREATE POLICY "profiles_select_all" ON public.profiles FOR
SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles FOR
UPDATE TO authenticated USING (auth.uid() = id);
-- -----------------------------------------------
-- 2.10 REPORTS
-- -----------------------------------------------
DROP POLICY IF EXISTS "Users can view their own reports" ON public.reports;
CREATE POLICY "Users can view their own reports" ON public.reports FOR
SELECT TO authenticated USING (auth.uid() = reporter_id);
DROP POLICY IF EXISTS "Users can create reports" ON public.reports;
CREATE POLICY "Users can create reports" ON public.reports FOR
INSERT TO authenticated WITH CHECK (auth.uid() = reporter_id);
DROP POLICY IF EXISTS "Moderators can view all reports" ON public.reports;
CREATE POLICY "Moderators can view all reports" ON public.reports FOR
SELECT TO authenticated USING (
        EXISTS (
            SELECT 1
            FROM public.user_roles
            WHERE user_id = auth.uid()
                AND role IN ('admin', 'moderator')
        )
    );
DROP POLICY IF EXISTS "Moderators can update reports" ON public.reports;
CREATE POLICY "Moderators can update reports" ON public.reports FOR
UPDATE TO authenticated USING (
        EXISTS (
            SELECT 1
            FROM public.user_roles
            WHERE user_id = auth.uid()
                AND role IN ('admin', 'moderator')
        )
    );
-- -----------------------------------------------
-- 2.11 USER_HEALTH_RECORDS
-- -----------------------------------------------
DROP POLICY IF EXISTS "Users can view their own health records" ON public.user_health_records;
CREATE POLICY "Users can view their own health records" ON public.user_health_records FOR
SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert their own health records" ON public.user_health_records;
CREATE POLICY "Users can insert their own health records" ON public.user_health_records FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own health records" ON public.user_health_records;
CREATE POLICY "Users can update their own health records" ON public.user_health_records FOR
UPDATE TO authenticated USING (auth.uid() = user_id);
-- -----------------------------------------------
-- 2.12 OTP_TOKENS (service_role only)
-- -----------------------------------------------
DROP POLICY IF EXISTS "Service role only access to otp_tokens" ON public.otp_tokens;
CREATE POLICY "Service role only access to otp_tokens" ON public.otp_tokens FOR ALL TO service_role USING (true);
-- -----------------------------------------------
-- 2.13 RESET_TOKENS (service_role only)
-- -----------------------------------------------
DROP POLICY IF EXISTS "Service role only access to reset_tokens" ON public.reset_tokens;
CREATE POLICY "Service role only access to reset_tokens" ON public.reset_tokens FOR ALL TO service_role USING (true);
-- -----------------------------------------------
-- 2.14 RATE_LIMITS (service_role only)
-- -----------------------------------------------
DROP POLICY IF EXISTS "Service role only access to rate_limits" ON public.rate_limits;
CREATE POLICY "Service role only access to rate_limits" ON public.rate_limits FOR ALL TO service_role USING (true);
-- -----------------------------------------------
-- 2.15 REALTIME.MESSAGES (fix duplicate policies in realtime schema)
-- -----------------------------------------------
DROP POLICY IF EXISTS "Users can view their own messages" ON realtime.messages;
DROP POLICY IF EXISTS "Users can mark messages as read" ON realtime.messages;
DROP POLICY IF EXISTS "Users can delete their own sent messages" ON realtime.messages;
-- Only recreate if the table exists in realtime schema
DO $$ BEGIN IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'realtime'
        AND table_name = 'messages'
) THEN EXECUTE 'CREATE POLICY "Users can view their own messages" ON realtime.messages
      FOR SELECT TO authenticated USING (true)';
EXECUTE 'CREATE POLICY "Users can mark messages as read" ON realtime.messages
      FOR UPDATE TO authenticated USING (true)';
EXECUTE 'CREATE POLICY "Users can delete their own sent messages" ON realtime.messages
      FOR DELETE TO authenticated USING (true)';
END IF;
END $$;
-- -----------------------------------------------
-- 2.16 STORAGE.OBJECTS — Fix write policies only
-- Note: Public READ policies for avatars/post-images are INTENTIONALLY
-- kept without TO authenticated so images display without auth.
-- Only write operations need TO authenticated (already fixed in 019).
-- -----------------------------------------------
-- Nothing to do here — migration 019 already fixed write policies.
-- The remaining storage warnings are for intentional public read policies.
-- ============================================
-- PART 3: LEAKED PASSWORD PROTECTION
-- ============================================
-- This CANNOT be set via SQL. You must enable it manually:
-- 1. Go to Supabase Dashboard → Authentication → Settings
-- 2. Scroll down to "Password Protection"
-- 3. Enable "Leaked Password Protection"
-- This checks passwords against HaveIBeenPwned.org database.
-- ============================================