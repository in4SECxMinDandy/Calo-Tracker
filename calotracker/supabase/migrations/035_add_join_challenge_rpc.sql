-- =============================================================================
-- Migration 035: Add join_challenge RPC Function
-- =============================================================================
-- Purpose: Create RPC function to safely join challenges with conflict handling
-- Date: 2026-02-15
-- =============================================================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.join_challenge(UUID);

-- Create join_challenge RPC function
-- This function handles duplicate joins gracefully using ON CONFLICT
CREATE OR REPLACE FUNCTION public.join_challenge(
  p_challenge_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_result JSONB;
  v_already_joined BOOLEAN;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();

  -- Check if user is authenticated
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Check if already joined
  SELECT EXISTS (
    SELECT 1 FROM public.challenge_participants
    WHERE challenge_id = p_challenge_id
    AND user_id = v_user_id
  ) INTO v_already_joined;

  -- If already joined, return success with message
  IF v_already_joined THEN
    v_result := jsonb_build_object(
      'success', true,
      'already_joined', true,
      'message', 'Bạn đã tham gia thử thách này rồi'
    );
    RETURN v_result;
  END IF;

  -- Insert new participant (with ON CONFLICT for extra safety)
  INSERT INTO public.challenge_participants (
    challenge_id,
    user_id,
    status,
    progress,
    joined_at,
    updated_at
  )
  VALUES (
    p_challenge_id,
    v_user_id,
    'active',
    jsonb_build_object(
      'current_value', 0,
      'goal_value', 0,
      'last_updated', NOW(),
      'daily_logs', '[]'::jsonb
    ),
    NOW(),
    NOW()
  )
  ON CONFLICT (challenge_id, user_id) DO NOTHING;

  -- Return success result
  v_result := jsonb_build_object(
    'success', true,
    'already_joined', false,
    'message', 'Tham gia thử thách thành công!'
  );

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    -- Log error and re-raise
    RAISE EXCEPTION 'Error joining challenge: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.join_challenge(UUID) TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION public.join_challenge(UUID) IS
'Allows authenticated users to join a challenge. Handles duplicate joins gracefully.';
