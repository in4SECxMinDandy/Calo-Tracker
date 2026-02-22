-- =============================================================================
-- Migration 030: FCM Device Tokens for Push Notifications
-- =============================================================================
-- Purpose: Store Firebase Cloud Messaging tokens for push notifications
-- Date: 2026-02-12
-- Security: Enable realtime notifications when users are offline
-- =============================================================================

-- User Device Tokens Table
CREATE TABLE IF NOT EXISTS public.user_device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL UNIQUE, -- Firebase Cloud Messaging token
  device_type TEXT CHECK (device_type IN ('android', 'ios', 'web')),
  device_name TEXT, -- e.g., "iPhone 13 Pro", "Samsung Galaxy S21"
  device_id TEXT, -- Unique device identifier
  app_version TEXT, -- e.g., "1.0.5"
  os_version TEXT, -- e.g., "iOS 16.2", "Android 13"
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_device_tokens_user ON public.user_device_tokens(user_id, is_active);
CREATE INDEX idx_device_tokens_fcm ON public.user_device_tokens(fcm_token);
CREATE INDEX idx_device_tokens_active ON public.user_device_tokens(is_active)
WHERE is_active = true;

-- =============================================================================
-- RLS Policies
-- =============================================================================
ALTER TABLE public.user_device_tokens ENABLE ROW LEVEL SECURITY;

-- Users can register their own device tokens
CREATE POLICY "Users can register device tokens"
ON public.user_device_tokens FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can view their own device tokens
CREATE POLICY "Users can view own tokens"
ON public.user_device_tokens FOR SELECT
USING (auth.uid() = user_id);

-- Users can update their own device tokens
CREATE POLICY "Users can update own tokens"
ON public.user_device_tokens FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Users can delete their own device tokens
CREATE POLICY "Users can delete own tokens"
ON public.user_device_tokens FOR DELETE
USING (auth.uid() = user_id);

-- Service role can access all tokens (for sending notifications)
CREATE POLICY "Service role can access all tokens"
ON public.user_device_tokens FOR ALL
USING (auth.jwt()->>'role' = 'service_role');

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_device_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER device_tokens_updated_at
BEFORE UPDATE ON public.user_device_tokens
FOR EACH ROW
EXECUTE FUNCTION update_device_tokens_updated_at();

-- Auto-deactivate old tokens when new token registered (same device_id)
CREATE OR REPLACE FUNCTION deactivate_old_device_tokens()
RETURNS TRIGGER AS $$
BEGIN
  -- If device_id is provided, deactivate old tokens for same device
  IF NEW.device_id IS NOT NULL THEN
    UPDATE public.user_device_tokens
    SET is_active = false
    WHERE user_id = NEW.user_id
    AND device_id = NEW.device_id
    AND id != NEW.id
    AND is_active = true;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER deactivate_old_tokens_trigger
AFTER INSERT ON public.user_device_tokens
FOR EACH ROW
EXECUTE FUNCTION deactivate_old_device_tokens();

-- Cleanup: Auto-deactivate tokens not used for 90 days
CREATE OR REPLACE FUNCTION cleanup_inactive_device_tokens()
RETURNS void AS $$
BEGIN
  UPDATE public.user_device_tokens
  SET is_active = false
  WHERE is_active = true
  AND last_used_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (run daily via cron or manually)
-- Note: Supabase cron extension required
-- SELECT cron.schedule('cleanup-device-tokens', '0 2 * * *', 'SELECT cleanup_inactive_device_tokens()');

-- =============================================================================
-- Notification Preferences Table
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,

  -- Push notification toggles
  push_enabled BOOLEAN NOT NULL DEFAULT true,
  push_friend_requests BOOLEAN NOT NULL DEFAULT true,
  push_messages BOOLEAN NOT NULL DEFAULT true,
  push_post_likes BOOLEAN NOT NULL DEFAULT true,
  push_post_comments BOOLEAN NOT NULL DEFAULT true,
  push_group_invites BOOLEAN NOT NULL DEFAULT true,
  push_challenge_invites BOOLEAN NOT NULL DEFAULT true,
  push_mentions BOOLEAN NOT NULL DEFAULT true,

  -- In-app notification toggles
  inapp_enabled BOOLEAN NOT NULL DEFAULT true,
  inapp_friend_requests BOOLEAN NOT NULL DEFAULT true,
  inapp_messages BOOLEAN NOT NULL DEFAULT true,
  inapp_post_likes BOOLEAN NOT NULL DEFAULT true,
  inapp_post_comments BOOLEAN NOT NULL DEFAULT true,
  inapp_group_invites BOOLEAN NOT NULL DEFAULT true,
  inapp_challenge_invites BOOLEAN NOT NULL DEFAULT true,
  inapp_mentions BOOLEAN NOT NULL DEFAULT true,

  -- Email notification toggles
  email_enabled BOOLEAN NOT NULL DEFAULT false,
  email_weekly_summary BOOLEAN NOT NULL DEFAULT false,
  email_marketing BOOLEAN NOT NULL DEFAULT false,

  -- Quiet hours (don't send push notifications during this time)
  quiet_hours_enabled BOOLEAN NOT NULL DEFAULT false,
  quiet_hours_start TIME, -- e.g., '22:00:00'
  quiet_hours_end TIME,   -- e.g., '08:00:00'

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS for notification preferences
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notification preferences"
ON public.notification_preferences FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Trigger for updated_at
CREATE TRIGGER notification_preferences_updated_at
BEFORE UPDATE ON public.notification_preferences
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- Auto-create default preferences for new users
CREATE OR REPLACE FUNCTION create_default_notification_preferences()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notification_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_notification_preferences_trigger
AFTER INSERT ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION create_default_notification_preferences();

-- =============================================================================
-- Helper function: Get active tokens for user (respecting preferences)
-- =============================================================================
CREATE OR REPLACE FUNCTION get_user_fcm_tokens(target_user_id UUID, notification_type TEXT)
RETURNS TABLE(fcm_token TEXT, device_type TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT dt.fcm_token, dt.device_type
  FROM public.user_device_tokens dt
  INNER JOIN public.notification_preferences np ON dt.user_id = np.user_id
  WHERE dt.user_id = target_user_id
  AND dt.is_active = true
  AND np.push_enabled = true
  -- Check specific notification type preference
  AND (
    (notification_type = 'friend_request' AND np.push_friend_requests = true)
    OR (notification_type = 'message' AND np.push_messages = true)
    OR (notification_type = 'post_like' AND np.push_post_likes = true)
    OR (notification_type = 'post_comment' AND np.push_post_comments = true)
    OR (notification_type = 'group_invite' AND np.push_group_invites = true)
    OR (notification_type = 'challenge_invite' AND np.push_challenge_invites = true)
    OR (notification_type = 'mention' AND np.push_mentions = true)
  )
  -- Respect quiet hours
  AND (
    np.quiet_hours_enabled = false
    OR (
      EXTRACT(HOUR FROM NOW() AT TIME ZONE 'UTC') NOT BETWEEN
      EXTRACT(HOUR FROM np.quiet_hours_start) AND
      EXTRACT(HOUR FROM np.quiet_hours_end)
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- Notification Queue Table (optional, for reliable delivery)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.notification_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB, -- Additional payload
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  attempts INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 3,
  error_message TEXT,
  scheduled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_queue_status ON public.notification_queue(status, scheduled_at);
CREATE INDEX idx_notification_queue_user ON public.notification_queue(user_id);

-- RLS (service role only)
ALTER TABLE public.notification_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can access notification queue"
ON public.notification_queue FOR ALL
USING (auth.jwt()->>'role' = 'service_role');

-- =============================================================================
-- Comments
-- =============================================================================
COMMENT ON TABLE public.user_device_tokens IS 'FCM tokens for push notifications';
COMMENT ON TABLE public.notification_preferences IS 'User preferences for push, in-app, and email notifications';
COMMENT ON TABLE public.notification_queue IS 'Queue for reliable push notification delivery';
COMMENT ON FUNCTION get_user_fcm_tokens(UUID, TEXT) IS 'Gets active FCM tokens for user respecting notification preferences and quiet hours';
COMMENT ON FUNCTION cleanup_inactive_device_tokens() IS 'Deactivates tokens not used in 90 days, should be run daily via cron';
