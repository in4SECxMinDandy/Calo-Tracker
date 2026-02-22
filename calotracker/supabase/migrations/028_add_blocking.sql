-- =============================================================================
-- Migration 028: User Blocking System
-- =============================================================================
-- Purpose: Allow users to block others, hiding content and preventing interaction
-- Date: 2026-02-12
-- Security: Prevents harassment, improves user safety
-- =============================================================================

-- Blocked Users Table
CREATE TABLE IF NOT EXISTS public.blocked_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE, -- Person who blocks
  blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE, -- Person being blocked
  reason TEXT, -- Optional: spam, harassment, inappropriate, other
  notes TEXT, -- Optional private notes
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  UNIQUE(user_id, blocked_id),
  CHECK (user_id != blocked_id) -- Cannot block yourself
);

-- Indexes
CREATE INDEX idx_blocked_users_user ON public.blocked_users(user_id);
CREATE INDEX idx_blocked_users_blocked ON public.blocked_users(blocked_id);
CREATE INDEX idx_blocked_users_created ON public.blocked_users(created_at DESC);

-- =============================================================================
-- RLS Policies
-- =============================================================================
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

-- Users can block others
CREATE POLICY "Users can block others"
ON public.blocked_users FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can view their own blocks
CREATE POLICY "Users can view own blocks"
ON public.blocked_users FOR SELECT
USING (auth.uid() = user_id);

-- Users can unblock
CREATE POLICY "Users can unblock"
ON public.blocked_users FOR DELETE
USING (auth.uid() = user_id);

-- Users can update block notes/reason
CREATE POLICY "Users can update own blocks"
ON public.blocked_users FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- Triggers: Auto-unfriend when blocked
-- =============================================================================
CREATE OR REPLACE FUNCTION auto_unfriend_on_block()
RETURNS TRIGGER AS $$
BEGIN
  -- Remove friendship in both directions
  DELETE FROM public.friendships
  WHERE (user_id = NEW.user_id AND friend_id = NEW.blocked_id)
     OR (user_id = NEW.blocked_id AND friend_id = NEW.user_id);

  -- Cancel pending friend requests
  DELETE FROM public.friendships
  WHERE (user_id = NEW.user_id AND friend_id = NEW.blocked_id AND status = 'pending')
     OR (user_id = NEW.blocked_id AND friend_id = NEW.user_id AND status = 'pending');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER unfriend_on_block_trigger
AFTER INSERT ON public.blocked_users
FOR EACH ROW
EXECUTE FUNCTION auto_unfriend_on_block();

-- =============================================================================
-- Update existing RLS policies to respect blocks
-- =============================================================================

-- Helper function to check if user is blocked
CREATE OR REPLACE FUNCTION is_blocked(target_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.blocked_users
    WHERE (user_id = auth.uid() AND blocked_id = target_user_id)
       OR (user_id = target_user_id AND blocked_id = auth.uid())
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update Posts RLS to exclude blocked users
DROP POLICY IF EXISTS "Users can view public posts" ON public.posts;
DROP POLICY IF EXISTS "Users can view public posts (not from blocked users)" ON public.posts;
DROP POLICY IF EXISTS "Users can view public posts (not from blocked)" ON public.posts;

CREATE POLICY "Users can view public posts excluding blocked"
ON public.posts FOR SELECT
USING (
  visibility = 'public'
  AND NOT is_blocked(user_id)
);

-- Update Comments RLS
DROP POLICY IF EXISTS "Users can view comments on visible posts" ON public.comments;

CREATE POLICY "Users can view comments excluding blocked"
ON public.comments FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.posts
    WHERE posts.id = comments.post_id
    AND NOT is_blocked(posts.user_id)
  )
  AND NOT is_blocked(comments.user_id)
);

-- Update Friendships RLS (prevent friend requests from blocked users)
DROP POLICY IF EXISTS "Users can view friendships" ON public.friendships;

CREATE POLICY "Users can view friendships excluding blocked"
ON public.friendships FOR SELECT
USING (
  (auth.uid() = user_id OR auth.uid() = friend_id)
  AND NOT is_blocked(CASE WHEN auth.uid() = user_id THEN friend_id ELSE user_id END)
);

-- Prevent blocked users from sending friend requests
CREATE OR REPLACE FUNCTION prevent_blocked_friend_request()
RETURNS TRIGGER AS $$
BEGIN
  IF is_blocked(NEW.friend_id) THEN
    RAISE EXCEPTION 'Cannot send friend request to blocked user';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_blocked_before_friend_request
BEFORE INSERT ON public.friendships
FOR EACH ROW
EXECUTE FUNCTION prevent_blocked_friend_request();

-- Update Messages RLS (prevent messages from blocked users)
DROP POLICY IF EXISTS "Users can view their messages" ON public.messages;

CREATE POLICY "Users can view messages excluding blocked"
ON public.messages FOR SELECT
USING (
  (auth.uid() = sender_id OR auth.uid() = receiver_id)
  AND NOT is_blocked(CASE WHEN auth.uid() = sender_id THEN receiver_id ELSE sender_id END)
);

-- Prevent blocked users from sending messages
CREATE OR REPLACE FUNCTION prevent_blocked_message()
RETURNS TRIGGER AS $$
BEGIN
  IF is_blocked(NEW.receiver_id) THEN
    RAISE EXCEPTION 'Cannot send message to blocked user';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_blocked_before_message
BEFORE INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION prevent_blocked_message();

-- Update Group Members RLS (prevent blocked users from joining same group)
CREATE OR REPLACE FUNCTION prevent_blocked_group_join()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.group_members gm
    INNER JOIN public.blocked_users bu ON
      (bu.user_id = NEW.user_id AND bu.blocked_id = gm.user_id)
      OR (bu.user_id = gm.user_id AND bu.blocked_id = NEW.user_id)
    WHERE gm.group_id = NEW.group_id
  ) THEN
    RAISE EXCEPTION 'Cannot join group with blocked user';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_blocked_before_group_join
BEFORE INSERT ON public.group_members
FOR EACH ROW
EXECUTE FUNCTION prevent_blocked_group_join();

-- =============================================================================
-- Comments
-- =============================================================================
COMMENT ON TABLE public.blocked_users IS 'User blocking system for safety and harassment prevention';
COMMENT ON FUNCTION is_blocked(UUID) IS 'Helper function to check if current user has blocked or been blocked by target user';
COMMENT ON TRIGGER unfriend_on_block_trigger ON public.blocked_users IS 'Automatically removes friendship when user blocks another';
