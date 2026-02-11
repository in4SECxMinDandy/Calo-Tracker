-- ============================================
-- Migration 019: Fix ALL Supabase Security Warnings
-- ============================================
-- Fixes:
-- 1. function_search_path_mutable (9 functions)
-- 2. auth_allow_anonymous_sign_ins (RLS policies on 8+ tables)
-- 3. auth_leaked_password_protection → manual in Dashboard
-- ============================================
-- ============================================
-- PART 1: FIX FUNCTION SEARCH PATH (SET search_path = '')
-- ============================================
-- Without search_path set, an attacker could create objects in a 
-- different schema to shadow existing ones and hijack function execution.
-- 1.1 handle_new_user
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER AS $$ BEGIN
INSERT INTO public.profiles (id, username, display_name, avatar_url)
VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'username',
            'user_' || substr(NEW.id::text, 1, 8)
        ),
        COALESCE(
            NEW.raw_user_meta_data->>'display_name',
            NEW.raw_user_meta_data->>'full_name',
            'Người dùng mới'
        ),
        NEW.raw_user_meta_data->>'avatar_url'
    ) ON CONFLICT (id) DO NOTHING;
BEGIN
INSERT INTO public.user_roles (user_id, role)
VALUES (NEW.id, 'user') ON CONFLICT DO NOTHING;
EXCEPTION
WHEN OTHERS THEN NULL;
END;
RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '';
-- 1.2 update_updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at() RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = '';
-- 1.3 increment_counter
CREATE OR REPLACE FUNCTION public.increment_counter(
        table_name TEXT,
        column_name TEXT,
        row_id UUID,
        amount INTEGER DEFAULT 1
    ) RETURNS VOID AS $$ BEGIN EXECUTE format(
        'UPDATE public.%I SET %I = %I + $1 WHERE id = $2',
        table_name,
        column_name,
        column_name
    ) USING amount,
    row_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '';
-- 1.4 update_challenge_ranks
CREATE OR REPLACE FUNCTION public.update_challenge_ranks(p_challenge_id UUID) RETURNS VOID AS $$ BEGIN WITH ranked AS (
        SELECT id,
            ROW_NUMBER() OVER (
                ORDER BY current_value DESC,
                    updated_at ASC
            ) as new_rank
        FROM public.challenge_participants
        WHERE challenge_id = p_challenge_id
    )
UPDATE public.challenge_participants cp
SET rank = ranked.new_rank
FROM ranked
WHERE cp.id = ranked.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '';
-- 1.5 set_user_online
CREATE OR REPLACE FUNCTION public.set_user_online(p_user_id UUID) RETURNS void AS $$ BEGIN
INSERT INTO public.user_presence (user_id, is_online, last_seen)
VALUES (p_user_id, true, NOW()) ON CONFLICT (user_id) DO
UPDATE
SET is_online = true,
    last_seen = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '';
-- 1.6 set_user_offline
CREATE OR REPLACE FUNCTION public.set_user_offline(p_user_id UUID) RETURNS void AS $$ BEGIN
UPDATE public.user_presence
SET is_online = false,
    last_seen = NOW()
WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '';
-- 1.7 update_user_online_status
CREATE OR REPLACE FUNCTION public.update_user_online_status(is_online_status BOOLEAN) RETURNS VOID AS $$ BEGIN
UPDATE public.profiles
SET is_online = is_online_status,
    last_seen = CASE
        WHEN is_online_status = false THEN NOW()
        ELSE last_seen
    END
WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '';
-- 1.8 get_friends_with_status
CREATE OR REPLACE FUNCTION public.get_friends_with_status() RETURNS TABLE (
        friendship_id UUID,
        friend_id UUID,
        username TEXT,
        display_name TEXT,
        avatar_url TEXT,
        is_online BOOLEAN,
        last_seen TIMESTAMPTZ,
        friendship_status TEXT
    ) AS $$ BEGIN RETURN QUERY
SELECT f.id as friendship_id,
    CASE
        WHEN f.user_id = auth.uid() THEN f.friend_id
        ELSE f.user_id
    END as friend_id,
    p.username,
    p.display_name,
    p.avatar_url,
    p.is_online,
    p.last_seen,
    f.status as friendship_status
FROM public.friendships f
    JOIN public.profiles p ON p.id = CASE
        WHEN f.user_id = auth.uid() THEN f.friend_id
        ELSE f.user_id
    END
WHERE (
        f.user_id = auth.uid()
        OR f.friend_id = auth.uid()
    )
    AND f.status = 'accepted';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '';
-- 1.9 get_conversation
CREATE OR REPLACE FUNCTION public.get_conversation(other_user_id UUID, msg_limit INT DEFAULT 50) RETURNS TABLE (
        id UUID,
        sender_id UUID,
        receiver_id UUID,
        content TEXT,
        is_read BOOLEAN,
        created_at TIMESTAMPTZ,
        is_mine BOOLEAN
    ) AS $$ BEGIN RETURN QUERY
SELECT m.id,
    m.sender_id,
    m.receiver_id,
    m.content,
    m.is_read,
    m.created_at,
    m.sender_id = auth.uid() as is_mine
FROM public.messages m
WHERE (
        m.sender_id = auth.uid()
        AND m.receiver_id = other_user_id
    )
    OR (
        m.sender_id = other_user_id
        AND m.receiver_id = auth.uid()
    )
ORDER BY m.created_at DESC
LIMIT msg_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '';
-- ============================================
-- PART 2: FIX ANONYMOUS ACCESS POLICIES 
-- Change policies to only apply TO authenticated role
-- ============================================
-- The issue: Policies without "TO authenticated" apply to ALL roles,
-- including the anonymous role. This means unauthenticated users can 
-- potentially access data through the anon key.
-- 2.1 Fix COMMENTS policies (from migration 018)
DROP POLICY IF EXISTS "Anyone can view non-hidden comments" ON public.comments;
DROP POLICY IF EXISTS "Users can create comments" ON public.comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON public.comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON public.comments;
DROP POLICY IF EXISTS "Users can view their own comments" ON public.comments;
DROP POLICY IF EXISTS "Admins have full access to comments" ON public.comments;
CREATE POLICY "Anyone can view non-hidden comments" ON public.comments FOR
SELECT TO authenticated USING (is_hidden = false);
CREATE POLICY "Users can create comments" ON public.comments FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own comments" ON public.comments FOR
UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own comments" ON public.comments FOR DELETE TO authenticated USING (auth.uid() = user_id);
-- 2.2 Fix LIKES policies (from migration 018)
DROP POLICY IF EXISTS "Anyone can view likes" ON public.likes;
DROP POLICY IF EXISTS "Users can create likes" ON public.likes;
DROP POLICY IF EXISTS "Users can delete their own likes" ON public.likes;
CREATE POLICY "Anyone can view likes" ON public.likes FOR
SELECT TO authenticated USING (true);
CREATE POLICY "Users can create likes" ON public.likes FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own likes" ON public.likes FOR DELETE TO authenticated USING (auth.uid() = user_id);
-- 2.3 Fix POSTS policies
DROP POLICY IF EXISTS "posts_select_public" ON public.posts;
DROP POLICY IF EXISTS "posts_update_own" ON public.posts;
DROP POLICY IF EXISTS "posts_delete_own" ON public.posts;
DROP POLICY IF EXISTS "posts_insert_own" ON public.posts;
CREATE POLICY "posts_select_public" ON public.posts FOR
SELECT TO authenticated USING (
        visibility = 'public'
        AND is_hidden = false
    );
CREATE POLICY "posts_insert_own" ON public.posts FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "posts_update_own" ON public.posts FOR
UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "posts_delete_own" ON public.posts FOR DELETE TO authenticated USING (auth.uid() = user_id);
-- 2.4 Fix FRIENDSHIPS policies
DROP POLICY IF EXISTS "friendships_select_own" ON public.friendships;
DROP POLICY IF EXISTS "friendships_insert_sender" ON public.friendships;
DROP POLICY IF EXISTS "friendships_update_involved" ON public.friendships;
DROP POLICY IF EXISTS "friendships_delete_involved" ON public.friendships;
-- Also drop old ones from migration 002
DROP POLICY IF EXISTS "Users can view their own friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can send friend requests" ON public.friendships;
DROP POLICY IF EXISTS "Users can update their own friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can delete their own friendships" ON public.friendships;
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
-- 2.5 Fix GROUPS policies
DROP POLICY IF EXISTS "groups_select_public" ON public.groups;
DROP POLICY IF EXISTS "groups_select_member" ON public.groups;
DROP POLICY IF EXISTS "groups_insert" ON public.groups;
DROP POLICY IF EXISTS "groups_update" ON public.groups;
DROP POLICY IF EXISTS "groups_delete" ON public.groups;
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
-- 2.6 Fix GROUP_MEMBERS policies
DROP POLICY IF EXISTS "gm_select_public" ON public.group_members;
DROP POLICY IF EXISTS "gm_select_own" ON public.group_members;
DROP POLICY IF EXISTS "gm_select_creator" ON public.group_members;
DROP POLICY IF EXISTS "gm_select_member" ON public.group_members;
DROP POLICY IF EXISTS "gm_insert_public" ON public.group_members;
DROP POLICY IF EXISTS "gm_insert_join" ON public.group_members;
DROP POLICY IF EXISTS "gm_insert_creator" ON public.group_members;
DROP POLICY IF EXISTS "gm_delete_self" ON public.group_members;
DROP POLICY IF EXISTS "gm_delete_leave" ON public.group_members;
DROP POLICY IF EXISTS "gm_delete_creator" ON public.group_members;
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
-- 2.7 Fix SAVED_POSTS policies
DROP POLICY IF EXISTS "saved_posts_select_own" ON public.saved_posts;
DROP POLICY IF EXISTS "saved_posts_insert_own" ON public.saved_posts;
DROP POLICY IF EXISTS "saved_posts_delete_own" ON public.saved_posts;
CREATE POLICY "saved_posts_select_own" ON public.saved_posts FOR
SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "saved_posts_insert_own" ON public.saved_posts FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "saved_posts_delete_own" ON public.saved_posts FOR DELETE TO authenticated USING (auth.uid() = user_id);
-- 2.8 Fix USER_PRESENCE policies
DROP POLICY IF EXISTS "Anyone can view presence" ON public.user_presence;
DROP POLICY IF EXISTS "Users can update own presence" ON public.user_presence;
CREATE POLICY "Anyone can view presence" ON public.user_presence FOR
SELECT TO authenticated USING (true);
CREATE POLICY "Users can update own presence" ON public.user_presence FOR ALL TO authenticated USING (auth.uid() = user_id);
-- 2.9 Fix STORAGE policies
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Post images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Public read avatars" ON storage.objects;
DROP POLICY IF EXISTS "Public read post-images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "User update avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload post images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own post images" ON storage.objects;
-- Storage: public READ is needed for avatars/images to display - keep for anon+authenticated
-- But write operations should be authenticated only
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects FOR
SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Post images are publicly accessible" ON storage.objects FOR
SELECT USING (bucket_id = 'post-images');
CREATE POLICY "Users can upload their own avatar" ON storage.objects FOR
INSERT TO authenticated WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name)) [1]
    );
CREATE POLICY "Users can update their own avatar" ON storage.objects FOR
UPDATE TO authenticated USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name)) [1]
    );
CREATE POLICY "Users can delete their own avatar" ON storage.objects FOR DELETE TO authenticated USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name)) [1]
);
CREATE POLICY "Users can upload post images" ON storage.objects FOR
INSERT TO authenticated WITH CHECK (
        bucket_id = 'post-images'
        AND auth.uid()::text = (storage.foldername(name)) [1]
    );
CREATE POLICY "Users can delete their own post images" ON storage.objects FOR DELETE TO authenticated USING (
    bucket_id = 'post-images'
    AND auth.uid()::text = (storage.foldername(name)) [1]
);
-- ============================================
-- PART 3: NOTE ABOUT LEAKED PASSWORD PROTECTION
-- ============================================
-- The "auth_leaked_password_protection" warning must be fixed manually:
-- 1. Go to Supabase Dashboard → Authentication → Settings 
-- 2. Scroll to "Password Protection"
-- 3. Enable "Leaked Password Protection"
-- This checks passwords against HaveIBeenPwned.org database
-- ============================================