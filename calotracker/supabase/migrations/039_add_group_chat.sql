-- =============================================================================
-- CaloTracker - Group Chat (Groups) Migration
-- =============================================================================
-- Version: 3.9.0
-- Date: 2026-03-14
-- =============================================================================

-- ============================================
-- TABLE: group_messages
-- ============================================

CREATE TABLE IF NOT EXISTS public.group_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK (char_length(content) > 0)
);

CREATE INDEX IF NOT EXISTS idx_group_messages_group ON public.group_messages(group_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_sender ON public.group_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_created ON public.group_messages(created_at DESC);

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE public.group_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Group members can view group messages" ON public.group_messages;
CREATE POLICY "Group members can view group messages" ON public.group_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.group_members gm
      WHERE gm.group_id = group_messages.group_id
        AND gm.user_id = auth.uid()
        AND gm.status = 'active'
    )
  );

DROP POLICY IF EXISTS "Group members can send group messages" ON public.group_messages;
CREATE POLICY "Group members can send group messages" ON public.group_messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1
      FROM public.group_members gm
      WHERE gm.group_id = group_messages.group_id
        AND gm.user_id = auth.uid()
        AND gm.status = 'active'
    )
  );

DROP POLICY IF EXISTS "Group senders can delete their messages" ON public.group_messages;
CREATE POLICY "Group senders can delete their messages" ON public.group_messages
  FOR DELETE USING (auth.uid() = sender_id);

-- ============================================
-- REALTIME
-- ============================================

ALTER TABLE public.group_messages REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.group_messages;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.group_messages IS 'Group chat messages for community groups';
