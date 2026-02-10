-- Fix Friendships RLS and Add Saved Posts
-- Issue: Friend accept/decline not working
-- New Feature: Saved posts functionality

-- ===================================================================
-- PART 1: FIX FRIENDSHIPS RLS POLICIES
-- ===================================================================

DROP POLICY IF EXISTS "Users can view their friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can send friend requests" ON public.friendships;
DROP POLICY IF EXISTS "Users can update friendship status" ON public.friendships;
DROP POLICY IF EXISTS "Users can delete friendships" ON public.friendships;
DROP POLICY IF EXISTS "friendships_select_own" ON public.friendships;
DROP POLICY IF EXISTS "friendships_insert_sender" ON public.friendships;
DROP POLICY IF EXISTS "friendships_update_involved" ON public.friendships;
DROP POLICY IF EXISTS "friendships_delete_involved" ON public.friendships;

-- SELECT: Users can view friendships where they are involved
CREATE POLICY "friendships_select_own"
  ON public.friendships
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR friend_id = auth.uid()
  );

-- INSERT: Users can create friend requests (sender must be current user)
CREATE POLICY "friendships_insert_sender"
  ON public.friendships
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND status = 'pending'
  );

-- UPDATE: Users can update if they are the receiver (friend_id) or sender (user_id)
CREATE POLICY "friendships_update_involved"
  ON public.friendships
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid() OR friend_id = auth.uid()
  )
  WITH CHECK (
    user_id = auth.uid() OR friend_id = auth.uid()
  );

-- DELETE: Users can delete friendships where they are involved
CREATE POLICY "friendships_delete_involved"
  ON public.friendships
  FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid() OR friend_id = auth.uid()
  );

-- ===================================================================
-- PART 2: CREATE SAVED POSTS TABLE
-- ===================================================================

CREATE TABLE IF NOT EXISTS public.saved_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_saved_posts_user ON public.saved_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_posts_post ON public.saved_posts(post_id);
CREATE INDEX IF NOT EXISTS idx_saved_posts_created ON public.saved_posts(created_at DESC);

-- Enable RLS
ALTER TABLE public.saved_posts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "saved_posts_select_own" ON public.saved_posts;
DROP POLICY IF EXISTS "saved_posts_insert_own" ON public.saved_posts;
DROP POLICY IF EXISTS "saved_posts_delete_own" ON public.saved_posts;

-- RLS Policies for saved_posts
CREATE POLICY "saved_posts_select_own"
  ON public.saved_posts
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "saved_posts_insert_own"
  ON public.saved_posts
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "saved_posts_delete_own"
  ON public.saved_posts
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ===================================================================
-- VERIFICATION
-- ===================================================================

SELECT 'Friendships RLS Policies:' as step;
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'friendships'
ORDER BY policyname;

SELECT 'Saved Posts RLS Policies:' as step;
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'saved_posts'
ORDER BY policyname;
