-- Fix Posts RLS Policy
-- Issue: Users cannot create posts due to restrictive RLS policy

-- Drop existing posts policies
DROP POLICY IF EXISTS "Public posts are viewable" ON public.posts;
DROP POLICY IF EXISTS "Users can view their own posts" ON public.posts;
DROP POLICY IF EXISTS "Group members can view group posts" ON public.posts;
DROP POLICY IF EXISTS "Users can create posts" ON public.posts;
DROP POLICY IF EXISTS "Users can update their own posts" ON public.posts;
DROP POLICY IF EXISTS "Users can delete their own posts" ON public.posts;
DROP POLICY IF EXISTS "Admins have full access to posts" ON public.posts;
DROP POLICY IF EXISTS "posts_select_public" ON public.posts;
DROP POLICY IF EXISTS "posts_insert_own" ON public.posts;
DROP POLICY IF EXISTS "posts_update_own" ON public.posts;
DROP POLICY IF EXISTS "posts_delete_own" ON public.posts;

-- Recreate with simplified policies

-- SELECT policies
CREATE POLICY "posts_select_public"
  ON public.posts
  FOR SELECT
  TO authenticated
  USING (
    visibility = 'public'
    OR user_id = auth.uid()
    OR (
      visibility = 'group' AND group_id IN (
        SELECT group_id FROM public.group_members WHERE user_id = auth.uid()
      )
    )
  );

-- INSERT policy - Allow authenticated users to create posts
CREATE POLICY "posts_insert_own"
  ON public.posts
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
  );

-- UPDATE policy - Users can update their own posts
CREATE POLICY "posts_update_own"
  ON public.posts
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DELETE policy - Users can delete their own posts
CREATE POLICY "posts_delete_own"
  ON public.posts
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Verify policies
SELECT 'Posts RLS Policies:' as step;
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'posts'
ORDER BY policyname;
