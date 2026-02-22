-- =============================================================================
-- Migration 032: Post & Comment Rate Limiting (Anti-Spam)
-- =============================================================================
-- Purpose: Prevent spam by limiting posts/comments per hour
-- Date: 2026-02-12
-- Security: Anti-abuse, prevent spam attacks
-- =============================================================================

-- =============================================================================
-- Post Rate Limiting: Max 10 posts per hour
-- =============================================================================

CREATE OR REPLACE FUNCTION check_post_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  post_count INTEGER;
  is_admin BOOLEAN;
BEGIN
  -- Check if user is admin/moderator (exempt from rate limits)
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = NEW.user_id
    AND role IN ('admin', 'moderator')
  ) INTO is_admin;

  IF is_admin THEN
    RETURN NEW;
  END IF;

  -- Count posts in last hour
  SELECT COUNT(*) INTO post_count
  FROM public.posts
  WHERE user_id = NEW.user_id
  AND created_at > NOW() - INTERVAL '1 hour';

  -- Rate limit: 10 posts per hour
  IF post_count >= 10 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 10 posts per hour. Please wait before posting again.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS post_rate_limit_check ON public.posts;
CREATE TRIGGER post_rate_limit_check
BEFORE INSERT ON public.posts
FOR EACH ROW
EXECUTE FUNCTION check_post_rate_limit();

-- =============================================================================
-- Comment Rate Limiting: Max 30 comments per hour
-- =============================================================================

CREATE OR REPLACE FUNCTION check_comment_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  comment_count INTEGER;
  is_admin BOOLEAN;
BEGIN
  -- Check if user is admin/moderator
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = NEW.user_id
    AND role IN ('admin', 'moderator')
  ) INTO is_admin;

  IF is_admin THEN
    RETURN NEW;
  END IF;

  -- Count comments in last hour
  SELECT COUNT(*) INTO comment_count
  FROM public.comments
  WHERE user_id = NEW.user_id
  AND created_at > NOW() - INTERVAL '1 hour';

  -- Rate limit: 30 comments per hour
  IF comment_count >= 30 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 30 comments per hour. Please wait before commenting again.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS comment_rate_limit_check ON public.comments;
CREATE TRIGGER comment_rate_limit_check
BEFORE INSERT ON public.comments
FOR EACH ROW
EXECUTE FUNCTION check_comment_rate_limit();

-- =============================================================================
-- Like/Reaction Rate Limiting: Max 100 likes per hour
-- =============================================================================

CREATE OR REPLACE FUNCTION check_like_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  like_count INTEGER;
BEGIN
  -- Count likes in last hour
  SELECT COUNT(*) INTO like_count
  FROM public.likes
  WHERE user_id = NEW.user_id
  AND created_at > NOW() - INTERVAL '1 hour';

  -- Rate limit: 100 likes per hour
  IF like_count >= 100 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 100 likes per hour. Please wait before liking again.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS like_rate_limit_check ON public.likes;
CREATE TRIGGER like_rate_limit_check
BEFORE INSERT ON public.likes
FOR EACH ROW
EXECUTE FUNCTION check_like_rate_limit();

-- =============================================================================
-- Friend Request Rate Limiting: Max 20 requests per day
-- =============================================================================

CREATE OR REPLACE FUNCTION check_friend_request_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  request_count INTEGER;
BEGIN
  -- Only check for new friend requests (status = 'pending')
  IF NEW.status != 'pending' THEN
    RETURN NEW;
  END IF;

  -- Count friend requests sent in last 24 hours
  SELECT COUNT(*) INTO request_count
  FROM public.friendships
  WHERE user_id = NEW.user_id
  AND status = 'pending'
  AND created_at > NOW() - INTERVAL '24 hours';

  -- Rate limit: 20 friend requests per day
  IF request_count >= 20 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 20 friend requests per day. Please wait before sending more requests.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS friend_request_rate_limit_check ON public.friendships;
CREATE TRIGGER friend_request_rate_limit_check
BEFORE INSERT ON public.friendships
FOR EACH ROW
EXECUTE FUNCTION check_friend_request_rate_limit();

-- =============================================================================
-- Group Creation Rate Limiting: Max 5 groups per day
-- =============================================================================

CREATE OR REPLACE FUNCTION check_group_creation_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  group_count INTEGER;
  is_admin BOOLEAN;
BEGIN
  -- Check if user is admin
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = NEW.created_by
    AND role IN ('admin', 'moderator')
  ) INTO is_admin;

  IF is_admin THEN
    RETURN NEW;
  END IF;

  -- Count groups created in last 24 hours
  SELECT COUNT(*) INTO group_count
  FROM public.groups
  WHERE created_by = NEW.created_by
  AND created_at > NOW() - INTERVAL '24 hours';

  -- Rate limit: 5 groups per day
  IF group_count >= 5 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 5 groups can be created per day. Please wait before creating more groups.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS group_creation_rate_limit_check ON public.groups;
CREATE TRIGGER group_creation_rate_limit_check
BEFORE INSERT ON public.groups
FOR EACH ROW
EXECUTE FUNCTION check_group_creation_rate_limit();

-- =============================================================================
-- Message Rate Limiting: Max 100 messages per hour
-- =============================================================================

CREATE OR REPLACE FUNCTION check_message_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  message_count INTEGER;
BEGIN
  -- Count messages sent in last hour
  SELECT COUNT(*) INTO message_count
  FROM public.messages
  WHERE sender_id = NEW.sender_id
  AND created_at > NOW() - INTERVAL '1 hour';

  -- Rate limit: 100 messages per hour
  IF message_count >= 100 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 100 messages per hour. Please wait before sending more messages.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS message_rate_limit_check ON public.messages;
CREATE TRIGGER message_rate_limit_check
BEFORE INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION check_message_rate_limit();

-- =============================================================================
-- Spam Detection: Auto-flag suspicious activity
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.spam_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  flag_type TEXT NOT NULL CHECK (flag_type IN (
    'excessive_posting',
    'excessive_commenting',
    'excessive_liking',
    'duplicate_content',
    'suspicious_pattern'
  )),
  severity TEXT NOT NULL DEFAULT 'low' CHECK (severity IN ('low', 'medium', 'high')),
  description TEXT,
  metadata JSONB, -- Store details like post IDs, patterns detected, etc.
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'reviewed', 'false_positive')),
  reviewed_by UUID REFERENCES public.profiles(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_spam_flags_user ON public.spam_flags(user_id, status);
CREATE INDEX idx_spam_flags_status ON public.spam_flags(status, severity, created_at DESC);

-- RLS for spam flags (admins only)
ALTER TABLE public.spam_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view spam flags"
ON public.spam_flags FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
    AND role IN ('admin', 'moderator')
  )
);

CREATE POLICY "Admins can update spam flags"
ON public.spam_flags FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
    AND role IN ('admin', 'moderator')
  )
);

-- Function to detect duplicate content spam
CREATE OR REPLACE FUNCTION detect_duplicate_content_spam()
RETURNS TRIGGER AS $$
DECLARE
  duplicate_count INTEGER;
BEGIN
  -- Check for exact duplicate posts in last hour
  SELECT COUNT(*) INTO duplicate_count
  FROM public.posts
  WHERE user_id = NEW.user_id
  AND content = NEW.content
  AND created_at > NOW() - INTERVAL '1 hour'
  AND id != NEW.id;

  -- If 3+ duplicate posts, flag as spam
  IF duplicate_count >= 3 THEN
    INSERT INTO public.spam_flags (user_id, flag_type, severity, description, metadata)
    VALUES (
      NEW.user_id,
      'duplicate_content',
      'medium',
      'User posted same content ' || duplicate_count || ' times in 1 hour',
      jsonb_build_object('post_id', NEW.id, 'duplicate_count', duplicate_count)
    );

    -- Notify admins
    INSERT INTO public.app_notifications (
      user_id,
      type,
      title,
      message,
      data
    )
    SELECT
      ur.user_id,
      'spam_alert',
      'Phát hiện spam',
      'User đăng nội dung trùng lặp ' || duplicate_count || ' lần',
      jsonb_build_object('spammer_id', NEW.user_id, 'post_id', NEW.id)
    FROM public.user_roles ur
    WHERE ur.role IN ('admin', 'moderator');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER detect_duplicate_spam_trigger
AFTER INSERT ON public.posts
FOR EACH ROW
EXECUTE FUNCTION detect_duplicate_content_spam();

-- =============================================================================
-- Rate Limit Stats View (for admins to monitor)
-- =============================================================================

CREATE OR REPLACE VIEW public.rate_limit_stats AS
SELECT
  'posts' AS action_type,
  user_id,
  COUNT(*) AS action_count,
  MAX(created_at) AS last_action
FROM public.posts
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 5

UNION ALL

SELECT
  'comments' AS action_type,
  user_id,
  COUNT(*) AS action_count,
  MAX(created_at) AS last_action
FROM public.comments
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 10

UNION ALL

SELECT
  'likes' AS action_type,
  user_id,
  COUNT(*) AS action_count,
  MAX(created_at) AS last_action
FROM public.likes
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 50

ORDER BY action_count DESC;

-- Grant access to admins
GRANT SELECT ON public.rate_limit_stats TO authenticated;
ALTER VIEW public.rate_limit_stats SET (security_invoker = on);

-- =============================================================================
-- Comments
-- =============================================================================
COMMENT ON FUNCTION check_post_rate_limit() IS 'Limits users to 10 posts per hour (admins exempt)';
COMMENT ON FUNCTION check_comment_rate_limit() IS 'Limits users to 30 comments per hour (admins exempt)';
COMMENT ON FUNCTION check_like_rate_limit() IS 'Limits users to 100 likes per hour';
COMMENT ON FUNCTION check_friend_request_rate_limit() IS 'Limits users to 20 friend requests per day';
COMMENT ON FUNCTION check_group_creation_rate_limit() IS 'Limits users to 5 group creations per day';
COMMENT ON FUNCTION check_message_rate_limit() IS 'Limits users to 100 messages per hour';
COMMENT ON TABLE public.spam_flags IS 'Auto-detected spam activity for admin review';
COMMENT ON VIEW public.rate_limit_stats IS 'Real-time view of users approaching rate limits';
