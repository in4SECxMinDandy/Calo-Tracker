-- =============================================================================
-- CaloTracker - Add demographics to user_profiles
-- =============================================================================
-- Version: 4.0.0
-- Date: 2026-03-14
-- =============================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS age INT DEFAULT 30 CHECK (age >= 10 AND age <= 120),
  ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT 'female' CHECK (gender IN ('male', 'female'));

COMMENT ON COLUMN public.profiles.age IS 'Age in years for BMR calculation';
COMMENT ON COLUMN public.profiles.gender IS 'Gender for BMR calculation (male/female)';
