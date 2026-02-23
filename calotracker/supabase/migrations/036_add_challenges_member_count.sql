-- =============================================================================
-- Migration 036: Add member_count column to challenges table
-- =============================================================================
-- Purpose: Fix "column member_count of relation challenges does not exist"
--          error caused by trigger in migration 027
-- Date: 2026-02-23
-- =============================================================================
-- Add member_count column if it doesn't exist
DO $$ BEGIN IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
        AND table_name = 'challenges'
        AND column_name = 'member_count'
) THEN
ALTER TABLE public.challenges
ADD COLUMN member_count INTEGER DEFAULT 0;
END IF;
END $$;
-- Sync existing data: set member_count from actual participant counts
UPDATE public.challenges c
SET member_count = (
        SELECT COUNT(*)
        FROM public.challenge_participants cp
        WHERE cp.challenge_id = c.id
            AND cp.status IN ('active', 'completed')
    );
-- Add index for sorting by popularity
CREATE INDEX IF NOT EXISTS idx_challenges_member_count ON public.challenges(member_count DESC);
-- Comment
COMMENT ON COLUMN public.challenges.member_count IS 'Cached count of active/completed participants, updated by trigger in migration 027';