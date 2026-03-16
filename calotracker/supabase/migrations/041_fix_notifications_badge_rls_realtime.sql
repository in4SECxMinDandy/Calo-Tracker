-- ============================================================
-- Migration: 041_fix_notifications_badge_rls_realtime
-- Purpose: Fix notifications RLS, add indexes, enable realtime
-- Created: 2026-03-16
-- ============================================================

BEGIN;

-- ──────────────────────────────────────────────────────────
-- 1. ADD 'message' TYPE TO NOTIFICATIONS CHECK CONSTRAINT
-- ──────────────────────────────────────────────────────────

-- Drop existing check constraint if exists
ALTER TABLE public.notifications 
DROP CONSTRAINT IF EXISTS notifications_type_check;

-- Add new check constraint with 'message' type
ALTER TABLE public.notifications 
ADD CONSTRAINT notifications_type_check CHECK (
    type IN (
        'like',
        'comment', 
        'follow',
        'mention',
        'message',
        'challenge_invite',
        'challenge_start',
        'challenge_end',
        'challenge_rank',
        'group_invite',
        'group_join',
        'achievement',
        'milestone',
        'system'
    )
);

-- ──────────────────────────────────────────────────────────
-- 2. ADD INDEXES FOR NOTIFICATIONS
-- ──────────────────────────────────────────────────────────

-- Index for fetching unread notifications (most common query)
DROP INDEX IF EXISTS idx_notifications_user_unread;
CREATE INDEX idx_notifications_user_unread 
ON public.notifications (user_id, is_read, created_at DESC);

-- Index for fetching all notifications for a user
DROP INDEX IF EXISTS idx_notifications_user;
CREATE INDEX idx_notifications_user 
ON public.notifications (user_id, created_at DESC);

-- Index for notification cleanup (old read notifications)
DROP INDEX IF EXISTS idx_notifications_old_read;
CREATE INDEX idx_notifications_old_read 
ON public.notifications (user_id, is_read, created_at) 
WHERE is_read = true;

-- ──────────────────────────────────────────────────────────
-- 3. RLS POLICIES FOR NOTIFICATIONS
-- ──────────────────────────────────────────────────────────

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can only view their own notifications
DROP POLICY IF EXISTS notif_select_own ON public.notifications;
CREATE POLICY notif_select_own ON public.notifications 
FOR SELECT TO authenticated 
USING (user_id = auth.uid());

-- INSERT: Users can only create notifications for themselves
-- (Note: Notifications are typically created by triggers or service role)
DROP POLICY IF EXISTS notif_insert_own ON public.notifications;
CREATE POLICY notif_insert_own ON public.notifications 
FOR INSERT TO authenticated 
WITH CHECK (user_id = auth.uid());

-- UPDATE: Users can only update (mark as read) their own notifications
DROP POLICY IF EXISTS notif_update_own ON public.notifications;
CREATE POLICY notif_update_own ON public.notifications 
FOR UPDATE TO authenticated 
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- DELETE: Users can only delete their own notifications
DROP POLICY IF EXISTS notif_delete_own ON public.notifications;
CREATE POLICY notif_delete_own ON public.notifications 
FOR DELETE TO authenticated 
USING (user_id = auth.uid());

-- ──────────────────────────────────────────────────────────
-- 4. ENABLE REALTIME FOR NOTIFICATIONS
-- ──────────────────────────────────────────────────────────

-- Enable realtime for the notifications table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
    END IF;
END $$;

-- ──────────────────────────────────────────────────────────
-- 5. VERIFICATION QUERIES
-- ──────────────────────────────────────────────────────────

-- Check RLS is enabled
SELECT 
    'RLS Enabled: ' || relrowsecurity AS result
FROM pg_class 
WHERE relname = 'notifications';

-- Check policies exist
SELECT 
    policyname, 
    cmd, 
    qual, 
    with_check 
FROM pg_policies 
WHERE tablename = 'notifications';

-- Check indexes exist
SELECT 
    indexname, 
    indexdef 
FROM pg_indexes 
WHERE tablename = 'notifications'
AND indexname LIKE 'idx_notifications%';

-- Check realtime is enabled
SELECT 
    schemaname, 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename = 'notifications';

COMMIT;

-- End of migration
