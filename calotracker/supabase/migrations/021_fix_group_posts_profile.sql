-- ============================================
-- Migration 021: Fix Group Posts & Profile Issues
-- ============================================
-- Fixes:
-- 1. Cannot create posts in groups (needs policy for group members)
-- 2. Display name showing as "Người dùng" (profile not created properly)
-- 3. Auth state issues
-- ============================================
-- ============================================
-- PART 1: Fix Posts RLS for Groups
-- ============================================
-- Problem: Current policy only allows INSERT if auth.uid() = user_id
-- But doesn't check if user can post to a group/challenge
-- Solution: Add policies for group members and challenge participants
-- Drop existing post policies
DROP POLICY IF EXISTS "posts_select_public" ON public.posts;
DROP POLICY IF EXISTS "posts_select_own" ON public.posts;
DROP POLICY IF EXISTS "posts_select_group_member" ON public.posts;
DROP POLICY IF EXISTS "posts_insert_own" ON public.posts;
DROP POLICY IF EXISTS "posts_insert_group_member" ON public.posts;
DROP POLICY IF EXISTS "posts_update_own" ON public.posts;
DROP POLICY IF EXISTS "posts_delete_own" ON public.posts;
-- Anyone can see public posts
CREATE POLICY "posts_select_public" ON public.posts FOR
SELECT TO authenticated USING (
        visibility = 'public'
        AND is_hidden = false
    );
-- Users can see their own posts
CREATE POLICY "posts_select_own" ON public.posts FOR
SELECT TO authenticated USING (auth.uid() = user_id);
-- Group members can see group posts
CREATE POLICY "posts_select_group_member" ON public.posts FOR
SELECT TO authenticated USING (
        group_id IS NOT NULL
        AND public.is_group_member(group_id, auth.uid())
    );
-- Users can create posts (personal)
CREATE POLICY "posts_insert_own" ON public.posts FOR
INSERT TO authenticated WITH CHECK (
        auth.uid() = user_id
        AND group_id IS NULL
        AND challenge_id IS NULL
    );
-- Group members can create posts in their groups
CREATE POLICY "posts_insert_group_member" ON public.posts FOR
INSERT TO authenticated WITH CHECK (
        auth.uid() = user_id
        AND (
            -- Personal post (no group/challenge)
            (
                group_id IS NULL
                AND challenge_id IS NULL
            )
            OR -- Group post (user is member)
            (
                group_id IS NOT NULL
                AND public.is_group_member(group_id, auth.uid())
            )
            OR -- Challenge post (user is participant)
            (
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
-- Users can update their own posts
CREATE POLICY "posts_update_own" ON public.posts FOR
UPDATE TO authenticated USING (auth.uid() = user_id);
-- Users can delete their own posts
CREATE POLICY "posts_delete_own" ON public.posts FOR DELETE TO authenticated USING (auth.uid() = user_id);
-- ============================================
-- PART 2: Ensure All Existing Users Have Profiles
-- ============================================
-- Problem: Some users may not have profiles created
-- This causes display_name to be null
-- Update handle_new_user to be more robust
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER AS $$ BEGIN -- Insert profile with better defaults
INSERT INTO public.profiles (
        id,
        username,
        display_name,
        avatar_url
    )
VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'username',
            'user_' || substr(NEW.id::text, 1, 8)
        ),
        COALESCE(
            NEW.raw_user_meta_data->>'display_name',
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            NEW.email,
            'Người dùng mới'
        ),
        NEW.raw_user_meta_data->>'avatar_url'
    ) ON CONFLICT (id) DO
UPDATE
SET display_name = COALESCE(
        EXCLUDED.display_name,
        public.profiles.display_name,
        'Người dùng mới'
    );
-- Add user role
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
-- Fix existing profiles with null or empty display_name
UPDATE public.profiles
SET display_name = COALESCE(
        display_name,
        (
            SELECT email
            FROM auth.users
            WHERE id = profiles.id
        ),
        'Người dùng ' || substr(id::text, 1, 8)
    )
WHERE display_name IS NULL
    OR display_name = ''
    OR display_name = 'Người dùng mới';
-- Ensure all profiles have proper visibility (fix navigation issue)
UPDATE public.profiles
SET profile_visibility = 'public'
WHERE profile_visibility IS NULL
    OR profile_visibility != 'public';
-- ============================================
-- PART 3: Fix Profile RLS Policies
-- ============================================
-- Problem: Old policies only allow viewing public profiles or own profile
-- This causes "Chưa đăng nhập" error when clicking on user avatars
-- Solution: Allow authenticated users to view all profiles
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
-- Authenticated users can view all profiles
DROP POLICY IF EXISTS "profiles_select_all" ON public.profiles;
CREATE POLICY "profiles_select_all" ON public.profiles FOR
SELECT TO authenticated USING (true);
-- Users can update their own profile
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles FOR
UPDATE TO authenticated USING (auth.uid() = id);