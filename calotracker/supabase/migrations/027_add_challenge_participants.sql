-- =============================================================================
-- Migration 027: Challenge Participants Tracking System
-- =============================================================================
-- Purpose: Track user participation in challenges with progress
-- Date: 2026-02-12
-- Note: challenge_participants already exists from migration 001, we're upgrading it
-- =============================================================================

-- Challenge Participants Table (already exists from 001, using IF NOT EXISTS)
CREATE TABLE IF NOT EXISTS public.challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned')),

  -- Progress tracking with JSONB for flexibility
  progress JSONB DEFAULT '{}'::jsonb,
  -- Example structure:
  -- {
  --   "current_value": 5,
  --   "goal_value": 10,
  --   "last_updated": "2026-02-12T10:30:00Z",
  --   "daily_logs": [
  --     {"date": "2026-02-10", "value": 2},
  --     {"date": "2026-02-11", "value": 3}
  --   ]
  -- }

  -- Timestamps
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  UNIQUE(challenge_id, user_id)
);

-- Add status column if it doesn't exist (migration 001 only has is_completed)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'challenge_participants'
    AND column_name = 'status'
  ) THEN
    -- Add status column
    ALTER TABLE public.challenge_participants
      ADD COLUMN status TEXT DEFAULT 'active';

    -- Migrate data from is_completed to status
    UPDATE public.challenge_participants
    SET status = CASE
      WHEN is_completed = true THEN 'completed'
      ELSE 'active'
    END;

    -- Now make it NOT NULL and add check constraint
    ALTER TABLE public.challenge_participants
      ALTER COLUMN status SET NOT NULL;

    ALTER TABLE public.challenge_participants
      ADD CONSTRAINT challenge_participants_status_check
        CHECK (status IN ('active', 'completed', 'abandoned'));
  END IF;
END $$;

-- Add progress column if it doesn't exist (migration 001 has current_value and daily_progress)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'challenge_participants'
    AND column_name = 'progress'
  ) THEN
    -- Add progress JSONB column
    ALTER TABLE public.challenge_participants
      ADD COLUMN progress JSONB DEFAULT '{}'::jsonb;

    -- Migrate existing data
    UPDATE public.challenge_participants
    SET progress = jsonb_build_object(
      'current_value', COALESCE(current_value, 0),
      'daily_logs', COALESCE(daily_progress, '[]'::jsonb)
    );
  END IF;
END $$;

-- Indexes for performance (conditional on status column existence)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'challenge_participants'
    AND column_name = 'status'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_challenge_participants_user
      ON public.challenge_participants(user_id, status);

    CREATE INDEX IF NOT EXISTS idx_challenge_participants_challenge
      ON public.challenge_participants(challenge_id, status);

    CREATE INDEX IF NOT EXISTS idx_challenge_participants_active
      ON public.challenge_participants(status)
      WHERE status = 'active';
  END IF;
END $$;

-- =============================================================================
-- RLS Policies
-- =============================================================================
ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;

-- Users can join challenges
CREATE POLICY "Users can join challenges"
ON public.challenge_participants FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can view their own participations
CREATE POLICY "Users can view own participations"
ON public.challenge_participants FOR SELECT
USING (auth.uid() = user_id);

-- Users can view challenge leaderboards (all participants)
CREATE POLICY "Users can view challenge leaderboards"
ON public.challenge_participants FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.challenges
    WHERE id = challenge_participants.challenge_id
    AND (visibility = 'public' OR created_by = auth.uid())
  )
);

-- Users can update their own progress
CREATE POLICY "Users can update own progress"
ON public.challenge_participants FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Users can abandon their participation
CREATE POLICY "Users can abandon challenges"
ON public.challenge_participants FOR DELETE
USING (auth.uid() = user_id);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_challenge_participants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER challenge_participants_updated_at
BEFORE UPDATE ON public.challenge_participants
FOR EACH ROW
EXECUTE FUNCTION update_challenge_participants_updated_at();

-- Auto-set completed_at when status changes to completed
CREATE OR REPLACE FUNCTION set_challenge_completed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    NEW.completed_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER challenge_completed_timestamp
BEFORE UPDATE ON public.challenge_participants
FOR EACH ROW
EXECUTE FUNCTION set_challenge_completed_at();

-- Increment profiles.challenges_completed counter
CREATE OR REPLACE FUNCTION increment_challenges_completed()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    UPDATE public.profiles
    SET challenges_completed = challenges_completed + 1
    WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER challenge_completed_counter
AFTER UPDATE ON public.challenge_participants
FOR EACH ROW
EXECUTE FUNCTION increment_challenges_completed();

-- Update challenge participant count
CREATE OR REPLACE FUNCTION update_challenge_participant_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.challenges
    SET member_count = (
      SELECT COUNT(*) FROM public.challenge_participants
      WHERE challenge_id = NEW.challenge_id
      AND status IN ('active', 'completed')
    )
    WHERE id = NEW.challenge_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.challenges
    SET member_count = (
      SELECT COUNT(*) FROM public.challenge_participants
      WHERE challenge_id = OLD.challenge_id
      AND status IN ('active', 'completed')
    )
    WHERE id = OLD.challenge_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    UPDATE public.challenges
    SET member_count = (
      SELECT COUNT(*) FROM public.challenge_participants
      WHERE challenge_id = NEW.challenge_id
      AND status IN ('active', 'completed')
    )
    WHERE id = NEW.challenge_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER challenge_participant_count_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.challenge_participants
FOR EACH ROW
EXECUTE FUNCTION update_challenge_participant_count();

-- =============================================================================
-- Comments
-- =============================================================================
COMMENT ON TABLE public.challenge_participants IS 'Tracks user participation and progress in challenges';
COMMENT ON COLUMN public.challenge_participants.progress IS 'JSONB field storing progress data, structure varies by challenge type';
COMMENT ON COLUMN public.challenge_participants.status IS 'Participation status: active, completed, or abandoned';
