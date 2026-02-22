-- =============================================================================
-- Migration 029: Content Reporting & Moderation System
-- =============================================================================
-- Purpose: Allow users to report inappropriate content for moderator review
-- Date: 2026-02-12
-- Security: Community safety, content moderation
-- =============================================================================

-- Content Reports Table
CREATE TABLE IF NOT EXISTS public.content_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL, -- Person who reported
  content_type TEXT NOT NULL CHECK (content_type IN ('post', 'comment', 'user', 'group', 'message')),
  content_id UUID NOT NULL, -- ID of the reported content
  reason TEXT NOT NULL CHECK (reason IN (
    'spam',
    'harassment',
    'hate_speech',
    'violence',
    'inappropriate',
    'misinformation',
    'sexual_content',
    'self_harm',
    'other'
  )),
  description TEXT, -- Optional detailed description from reporter
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),

  -- Moderation fields
  reviewed_by UUID REFERENCES public.profiles(id),
  reviewed_at TIMESTAMPTZ,
  admin_note TEXT, -- Private note from moderator
  action_taken TEXT, -- What action was taken: deleted, warned, banned, none

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_content_reports_status ON public.content_reports(status);
CREATE INDEX idx_content_reports_content ON public.content_reports(content_type, content_id);
CREATE INDEX idx_content_reports_reporter ON public.content_reports(reporter_id);
CREATE INDEX idx_content_reports_created ON public.content_reports(created_at DESC);
CREATE INDEX idx_content_reports_pending ON public.content_reports(status, created_at DESC)
WHERE status = 'pending';

-- =============================================================================
-- RLS Policies
-- =============================================================================
ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

-- Users can submit reports
CREATE POLICY "Users can submit reports"
ON public.content_reports FOR INSERT
WITH CHECK (auth.uid() = reporter_id);

-- Reporters can view their own reports
CREATE POLICY "Reporters can view own reports"
ON public.content_reports FOR SELECT
USING (auth.uid() = reporter_id);

-- Admins/Moderators can view all reports
CREATE POLICY "Admins can view all reports"
ON public.content_reports FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
    AND role IN ('admin', 'moderator')
  )
);

-- Admins/Moderators can update reports
CREATE POLICY "Admins can update reports"
ON public.content_reports FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
    AND role IN ('admin', 'moderator')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
    AND role IN ('admin', 'moderator')
  )
);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_content_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER content_reports_updated_at
BEFORE UPDATE ON public.content_reports
FOR EACH ROW
EXECUTE FUNCTION update_content_reports_updated_at();

-- Auto-set reviewed_at when status changes from pending
CREATE OR REPLACE FUNCTION set_content_report_reviewed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status != 'pending' AND (OLD.status IS NULL OR OLD.status = 'pending') THEN
    NEW.reviewed_at = NOW();
    IF NEW.reviewed_by IS NULL THEN
      NEW.reviewed_by = auth.uid();
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER content_report_reviewed_timestamp
BEFORE UPDATE ON public.content_reports
FOR EACH ROW
EXECUTE FUNCTION set_content_report_reviewed_at();

-- Prevent duplicate reports (same user, same content within 24h)
CREATE OR REPLACE FUNCTION prevent_duplicate_report()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.content_reports
    WHERE reporter_id = NEW.reporter_id
    AND content_type = NEW.content_type
    AND content_id = NEW.content_id
    AND created_at > NOW() - INTERVAL '24 hours'
  ) THEN
    RAISE EXCEPTION 'You have already reported this content recently';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_duplicate_report
BEFORE INSERT ON public.content_reports
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_report();

-- Rate limit: Max 10 reports per hour per user
CREATE OR REPLACE FUNCTION check_report_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  report_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO report_count
  FROM public.content_reports
  WHERE reporter_id = NEW.reporter_id
  AND created_at > NOW() - INTERVAL '1 hour';

  IF report_count >= 10 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 10 reports per hour';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER report_rate_limit_check
BEFORE INSERT ON public.content_reports
FOR EACH ROW
EXECUTE FUNCTION check_report_rate_limit();

-- =============================================================================
-- View for moderators: Report summary with content preview
-- =============================================================================
CREATE OR REPLACE VIEW public.moderator_report_queue AS
SELECT
  cr.id,
  cr.content_type,
  cr.content_id,
  cr.reason,
  cr.description,
  cr.status,
  cr.created_at,
  cr.reviewed_at,
  cr.action_taken,

  -- Reporter info
  reporter.username AS reporter_username,
  reporter.display_name AS reporter_display_name,

  -- Reviewer info
  reviewer.username AS reviewer_username,
  reviewer.display_name AS reviewer_display_name,

  -- Content preview (different for each type)
  CASE
    WHEN cr.content_type = 'post' THEN (
      SELECT LEFT(content, 100) FROM public.posts WHERE id = cr.content_id
    )
    WHEN cr.content_type = 'comment' THEN (
      SELECT LEFT(content, 100) FROM public.comments WHERE id = cr.content_id
    )
    WHEN cr.content_type = 'user' THEN (
      SELECT username FROM public.profiles WHERE id = cr.content_id
    )
    WHEN cr.content_type = 'group' THEN (
      SELECT name FROM public.groups WHERE id = cr.content_id
    )
    ELSE NULL
  END AS content_preview,

  -- Report count for this content
  (
    SELECT COUNT(*)
    FROM public.content_reports cr2
    WHERE cr2.content_type = cr.content_type
    AND cr2.content_id = cr.content_id
  ) AS total_reports_for_content

FROM public.content_reports cr
LEFT JOIN public.profiles reporter ON cr.reporter_id = reporter.id
LEFT JOIN public.profiles reviewer ON cr.reviewed_by = reviewer.id
ORDER BY
  CASE cr.status
    WHEN 'pending' THEN 1
    WHEN 'reviewing' THEN 2
    ELSE 3
  END,
  cr.created_at DESC;

-- Grant access to admins/moderators
GRANT SELECT ON public.moderator_report_queue TO authenticated;

-- RLS for view
ALTER VIEW public.moderator_report_queue SET (security_invoker = on);

-- =============================================================================
-- Helper function: Auto-flag content with multiple reports
-- =============================================================================
CREATE OR REPLACE FUNCTION auto_flag_highly_reported_content()
RETURNS TRIGGER AS $$
DECLARE
  report_count INTEGER;
BEGIN
  -- Count total reports for this content
  SELECT COUNT(*) INTO report_count
  FROM public.content_reports
  WHERE content_type = NEW.content_type
  AND content_id = NEW.content_id;

  -- If 3+ reports, auto-flag content (implementation depends on content_type)
  IF report_count >= 3 THEN
    CASE NEW.content_type
      WHEN 'post' THEN
        UPDATE public.posts
        SET is_hidden = true
        WHERE id = NEW.content_id;
      WHEN 'comment' THEN
        UPDATE public.comments
        SET is_hidden = true
        WHERE id = NEW.content_id;
      -- Add other content types as needed
    END CASE;

    -- Notify admins (create notification)
    INSERT INTO public.app_notifications (
      user_id,
      type,
      title,
      message,
      data
    )
    SELECT
      ur.user_id,
      'admin_alert',
      'Nội dung nhận nhiều báo cáo',
      'Một ' || NEW.content_type || ' đã nhận ' || report_count || ' báo cáo',
      jsonb_build_object(
        'content_type', NEW.content_type,
        'content_id', NEW.content_id,
        'report_count', report_count
      )
    FROM public.user_roles ur
    WHERE ur.role IN ('admin', 'moderator');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_flag_content_trigger
AFTER INSERT ON public.content_reports
FOR EACH ROW
EXECUTE FUNCTION auto_flag_highly_reported_content();

-- =============================================================================
-- Comments
-- =============================================================================
COMMENT ON TABLE public.content_reports IS 'User-submitted reports for inappropriate content';
COMMENT ON VIEW public.moderator_report_queue IS 'Moderator dashboard view with report details and content preview';
COMMENT ON TRIGGER auto_flag_content_trigger ON public.content_reports IS 'Automatically hides content after receiving 3+ reports';
