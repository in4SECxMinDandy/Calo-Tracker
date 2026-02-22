-- ============================================
-- Migration 024: NUCLEAR Security Fix
-- ============================================
-- Previous migrations left orphan policies (old names) alongside new ones.
-- This migration drops ALL policies on every affected table, then recreates
-- only the correct ones with TO authenticated / TO service_role.
-- Also adds policies for group_invites and user_roles (RLS enabled, no policy).
-- ============================================s
-- ============================================
-- HELPER: Drop ALL policies on a table dynamically
-- ============================================
CREATE OR REPLACE FUNCTION pg_temp.drop_all_policies(p_schema TEXT, p_table TEXT) RETURNS void AS $$
DECLARE pol RECORD;
BEGIN FOR pol IN
SELECT policyname
FROM pg_policies
WHERE schemaname = p_schema
    AND tablename = p_table LOOP EXECUTE format(
        'DROP POLICY IF EXISTS %I ON %I.%I',
        pol.policyname,
        p_schema,
        p_table
    );
END LOOP;
END;
$$ LANGUAGE plpgsql;
-- ============================================
-- PART 1: PROFILES
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'profiles');
CREATE POLICY "profiles_select_all" ON public.profiles FOR
SELECT TO authenticated USING (true);
CREATE POLICY "profiles_update_own" ON public.profiles FOR
UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "profiles_admin_all" ON public.profiles FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles
        WHERE user_id = auth.uid()
            AND role = 'admin'
    )
);
-- ============================================
-- PART 2: POSTS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'posts');
CREATE POLICY "posts_select_public" ON public.posts FOR
SELECT TO authenticated USING (
        visibility = 'public'
        AND is_hidden = false
    );
CREATE POLICY "posts_select_own" ON public.posts FOR
SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "posts_select_group_member" ON public.posts FOR
SELECT TO authenticated USING (
        group_id IS NOT NULL
        AND public.is_group_member(group_id, auth.uid())
    );
CREATE POLICY "posts_insert_own" ON public.posts FOR
INSERT TO authenticated WITH CHECK (
        auth.uid() = user_id
        AND group_id IS NULL
        AND challenge_id IS NULL
    );
CREATE POLICY "posts_insert_group_member" ON public.posts FOR
INSERT TO authenticated WITH CHECK (
        auth.uid() = user_id
        AND (
            (
                group_id IS NULL
                AND challenge_id IS NULL
            )
            OR (
                group_id IS NOT NULL
                AND public.is_group_member(group_id, auth.uid())
            )
            OR (
                challenge_id IS NOT NULL
                AND EXISTS (
                    SELECT 1
                    FROM public.challenge_participants cp
                    WHERE cp.challenge_id = posts.challenge_id
                        AND cp.user_id = auth.uid()
                )
            )
        )
    );
CREATE POLICY "posts_update_own" ON public.posts FOR
UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "posts_delete_own" ON public.posts FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "posts_admin_all" ON public.posts FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles
        WHERE user_id = auth.uid()
            AND role = 'admin'
    )
);
-- ============================================
-- PART 3: COMMENTS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'comments');
CREATE POLICY "comments_select" ON public.comments FOR
SELECT TO authenticated USING (is_hidden = false);
CREATE POLICY "comments_insert" ON public.comments FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "comments_update_own" ON public.comments FOR
UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "comments_delete_own" ON public.comments FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "comments_admin_all" ON public.comments FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles
        WHERE user_id = auth.uid()
            AND role = 'admin'
    )
);
-- ============================================
-- PART 4: LIKES
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'likes');
CREATE POLICY "likes_select" ON public.likes FOR
SELECT TO authenticated USING (true);
CREATE POLICY "likes_insert" ON public.likes FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "likes_delete_own" ON public.likes FOR DELETE TO authenticated USING (auth.uid() = user_id);
-- ============================================
-- PART 5: FOLLOWS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'follows');
CREATE POLICY "follows_select" ON public.follows FOR
SELECT TO authenticated USING (true);
CREATE POLICY "follows_insert" ON public.follows FOR
INSERT TO authenticated WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "follows_delete_own" ON public.follows FOR DELETE TO authenticated USING (auth.uid() = follower_id);
-- ============================================
-- PART 6: FRIENDSHIPS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'friendships');
CREATE POLICY "friendships_select_own" ON public.friendships FOR
SELECT TO authenticated USING (
        auth.uid() = user_id
        OR auth.uid() = friend_id
    );
CREATE POLICY "friendships_insert_sender" ON public.friendships FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "friendships_update_involved" ON public.friendships FOR
UPDATE TO authenticated USING (
        auth.uid() = user_id
        OR auth.uid() = friend_id
    );
CREATE POLICY "friendships_delete_involved" ON public.friendships FOR DELETE TO authenticated USING (
    auth.uid() = user_id
    OR auth.uid() = friend_id
);
-- ============================================
-- PART 7: GROUPS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'groups');
CREATE POLICY "groups_select_public" ON public.groups FOR
SELECT TO authenticated USING (visibility = 'public');
CREATE POLICY "groups_select_member" ON public.groups FOR
SELECT TO authenticated USING (
        EXISTS (
            SELECT 1
            FROM public.group_members gm
            WHERE gm.group_id = id
                AND gm.user_id = auth.uid()
        )
    );
CREATE POLICY "groups_insert" ON public.groups FOR
INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "groups_update" ON public.groups FOR
UPDATE TO authenticated USING (auth.uid() = created_by);
CREATE POLICY "groups_delete" ON public.groups FOR DELETE TO authenticated USING (auth.uid() = created_by);
-- ============================================
-- PART 8: GROUP_MEMBERS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'group_members');
CREATE POLICY "gm_select_public" ON public.group_members FOR
SELECT TO authenticated USING (
        EXISTS (
            SELECT 1
            FROM public.groups g
            WHERE g.id = group_id
                AND g.visibility = 'public'
        )
    );
CREATE POLICY "gm_select_own" ON public.group_members FOR
SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "gm_select_creator" ON public.group_members FOR
SELECT TO authenticated USING (
        EXISTS (
            SELECT 1
            FROM public.groups g
            WHERE g.id = group_id
                AND g.created_by = auth.uid()
        )
    );
CREATE POLICY "gm_select_member" ON public.group_members FOR
SELECT TO authenticated USING (
        EXISTS (
            SELECT 1
            FROM public.group_members other_gm
            WHERE other_gm.group_id = group_id
                AND other_gm.user_id = auth.uid()
        )
    );
CREATE POLICY "gm_insert_public" ON public.group_members FOR
INSERT TO authenticated WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (
            SELECT 1
            FROM public.groups g
            WHERE g.id = group_id
                AND g.visibility = 'public'
        )
    );
CREATE POLICY "gm_insert_creator" ON public.group_members FOR
INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1
            FROM public.groups g
            WHERE g.id = group_id
                AND g.created_by = auth.uid()
        )
    );
CREATE POLICY "gm_delete_self" ON public.group_members FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "gm_delete_creator" ON public.group_members FOR DELETE TO authenticated USING (
    EXISTS (
        SELECT 1
        FROM public.groups g
        WHERE g.id = group_id
            AND g.created_by = auth.uid()
    )
);
-- ============================================
-- PART 9: CHALLENGES
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'challenges');
CREATE POLICY "challenges_select" ON public.challenges FOR
SELECT TO authenticated USING (
        visibility = 'public'
        OR visibility = 'group'
    );
CREATE POLICY "challenges_insert" ON public.challenges FOR
INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "challenges_update" ON public.challenges FOR
UPDATE TO authenticated USING (auth.uid() = created_by);
-- ============================================
-- PART 10: CHALLENGE_PARTICIPANTS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'challenge_participants');
CREATE POLICY "cp_select" ON public.challenge_participants FOR
SELECT TO authenticated USING (true);
CREATE POLICY "cp_insert" ON public.challenge_participants FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "cp_update_own" ON public.challenge_participants FOR
UPDATE TO authenticated USING (auth.uid() = user_id);
-- ============================================
-- PART 11: MESSAGES
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'messages');
CREATE POLICY "messages_select_own" ON public.messages FOR
SELECT TO authenticated USING (
        auth.uid() = sender_id
        OR auth.uid() = receiver_id
    );
CREATE POLICY "messages_insert" ON public.messages FOR
INSERT TO authenticated WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "messages_update_read" ON public.messages FOR
UPDATE TO authenticated USING (auth.uid() = receiver_id);
CREATE POLICY "messages_delete_own" ON public.messages FOR DELETE TO authenticated USING (auth.uid() = sender_id);
-- ============================================
-- PART 12: NOTIFICATIONS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'notifications');
CREATE POLICY "notifications_select_own" ON public.notifications FOR
SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "notifications_update_own" ON public.notifications FOR
UPDATE TO authenticated USING (auth.uid() = user_id);
-- ============================================
-- PART 13: REPORTS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'reports');
CREATE POLICY "reports_insert" ON public.reports FOR
INSERT TO authenticated WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "reports_select_own" ON public.reports FOR
SELECT TO authenticated USING (auth.uid() = reporter_id);
CREATE POLICY "reports_select_mod" ON public.reports FOR
SELECT TO authenticated USING (
        EXISTS (
            SELECT 1
            FROM public.user_roles
            WHERE user_id = auth.uid()
                AND role IN ('admin', 'moderator')
        )
    );
CREATE POLICY "reports_update_mod" ON public.reports FOR
UPDATE TO authenticated USING (
        EXISTS (
            SELECT 1
            FROM public.user_roles
            WHERE user_id = auth.uid()
                AND role IN ('admin', 'moderator')
        )
    );
-- ============================================
-- PART 14: USER_HEALTH_RECORDS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'user_health_records');
CREATE POLICY "uhr_select_own" ON public.user_health_records FOR
SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "uhr_insert_own" ON public.user_health_records FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "uhr_update_own" ON public.user_health_records FOR
UPDATE TO authenticated USING (auth.uid() = user_id);
-- ============================================
-- PART 15: ACHIEVEMENTS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'achievements');
CREATE POLICY "achievements_select" ON public.achievements FOR
SELECT TO authenticated USING (true);
-- ============================================
-- PART 16: USER_ACHIEVEMENTS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'user_achievements');
CREATE POLICY "user_achievements_select_own" ON public.user_achievements FOR
SELECT TO authenticated USING (auth.uid() = user_id);
-- ============================================
-- PART 17: BANS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'bans');
CREATE POLICY "bans_admin_all" ON public.bans FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles
        WHERE user_id = auth.uid()
            AND role = 'admin'
    )
);
-- ============================================
-- PART 18: SAVED_POSTS
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'saved_posts');
CREATE POLICY "saved_posts_select_own" ON public.saved_posts FOR
SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "saved_posts_insert_own" ON public.saved_posts FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "saved_posts_delete_own" ON public.saved_posts FOR DELETE TO authenticated USING (auth.uid() = user_id);
-- ============================================
-- PART 19: USER_PRESENCE
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'user_presence');
CREATE POLICY "presence_select" ON public.user_presence FOR
SELECT TO authenticated USING (true);
CREATE POLICY "presence_all_own" ON public.user_presence FOR ALL TO authenticated USING (auth.uid() = user_id);
-- ============================================
-- PART 20: OTP_TOKENS (service_role only)
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'otp_tokens');
CREATE POLICY "otp_tokens_service" ON public.otp_tokens FOR ALL TO service_role USING (true);
-- ============================================
-- PART 21: RESET_TOKENS (service_role only)
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'reset_tokens');
CREATE POLICY "reset_tokens_service" ON public.reset_tokens FOR ALL TO service_role USING (true);
-- ============================================
-- PART 22: RATE_LIMITS (service_role only)
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'rate_limits');
CREATE POLICY "rate_limits_service" ON public.rate_limits FOR ALL TO service_role USING (true);
-- ============================================
-- PART 23: GROUP_INVITES (RLS enabled, NO policy existed)
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'group_invites');
CREATE POLICY "gi_select_involved" ON public.group_invites FOR
SELECT TO authenticated USING (
        auth.uid() = invited_user_id
        OR auth.uid() = invited_by
        OR EXISTS (
            SELECT 1
            FROM public.groups g
            WHERE g.id = group_id
                AND g.created_by = auth.uid()
        )
    );
CREATE POLICY "gi_insert_creator" ON public.group_invites FOR
INSERT TO authenticated WITH CHECK (
        auth.uid() = invited_by
        AND EXISTS (
            SELECT 1
            FROM public.groups g
            WHERE g.id = group_id
                AND g.created_by = auth.uid()
        )
    );
CREATE POLICY "gi_update_invited" ON public.group_invites FOR
UPDATE TO authenticated USING (auth.uid() = invited_user_id);
CREATE POLICY "gi_delete" ON public.group_invites FOR DELETE TO authenticated USING (
    auth.uid() = invited_by
    OR auth.uid() = invited_user_id
);
-- ============================================
-- PART 24: USER_ROLES (RLS enabled, NO policy existed)
-- ============================================
SELECT pg_temp.drop_all_policies('public', 'user_roles');
-- Users can see their own roles
CREATE POLICY "ur_select_own" ON public.user_roles FOR
SELECT TO authenticated USING (auth.uid() = user_id);
-- Admins have full access to user_roles
CREATE POLICY "ur_admin_all" ON public.user_roles FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles ur
        WHERE ur.user_id = auth.uid()
            AND ur.role = 'admin'
    )
);
-- Service role full access (for trigger-based inserts)
CREATE POLICY "ur_service" ON public.user_roles FOR ALL TO service_role USING (true);
-- ============================================
-- PART 25: STORAGE.OBJECTS — Fix remaining write policies
-- ============================================
SELECT pg_temp.drop_all_policies('storage', 'objects');
-- Public READ for avatars (intentionally accessible to anon for image display)
CREATE POLICY "storage_avatars_read" ON storage.objects FOR
SELECT USING (bucket_id = 'avatars');
-- Public READ for post-images
CREATE POLICY "storage_posts_read" ON storage.objects FOR
SELECT USING (bucket_id = 'post-images');
-- Write operations: authenticated only
CREATE POLICY "storage_avatars_insert" ON storage.objects FOR
INSERT TO authenticated WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name)) [1]
    );
CREATE POLICY "storage_avatars_update" ON storage.objects FOR
UPDATE TO authenticated USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name)) [1]
    );
CREATE POLICY "storage_avatars_delete" ON storage.objects FOR DELETE TO authenticated USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name)) [1]
);
CREATE POLICY "storage_posts_insert" ON storage.objects FOR
INSERT TO authenticated WITH CHECK (
        bucket_id = 'post-images'
        AND auth.uid()::text = (storage.foldername(name)) [1]
    );
CREATE POLICY "storage_posts_delete" ON storage.objects FOR DELETE TO authenticated USING (
    bucket_id = 'post-images'
    AND auth.uid()::text = (storage.foldername(name)) [1]
);
-- ============================================
-- PART 26: REALTIME.MESSAGES — Drop any orphan policies
-- ============================================
DO $$ BEGIN IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'realtime'
        AND table_name = 'messages'
) THEN PERFORM pg_temp.drop_all_policies('realtime', 'messages');
END IF;
END $$;
-- ============================================
-- CLEANUP: Drop temp helper function
-- ============================================
-- pg_temp functions are auto-dropped at end of session
-- ============================================
-- NOTE: auth_leaked_password_protection requires Pro plan.
-- Skip if on Free plan.
-- ============================================