-- =====================================================
-- OTP-Based Password Reset System
-- Implements secure 6-digit OTP for password recovery
-- =====================================================
-- 1. Create otp_tokens table with security constraints
CREATE TABLE IF NOT EXISTS public.otp_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    otp_hash TEXT NOT NULL,
    -- Store bcrypt hash, NEVER plaintext
    purpose TEXT NOT NULL DEFAULT 'password_reset',
    attempts INTEGER NOT NULL DEFAULT 0,
    max_attempts INTEGER NOT NULL DEFAULT 5,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    used BOOLEAN NOT NULL DEFAULT false,
    -- Constraints
    CONSTRAINT valid_purpose CHECK (
        purpose IN ('password_reset', 'email_verify', 'phone_verify')
    ),
    CONSTRAINT valid_attempts CHECK (
        attempts >= 0
        AND attempts <= max_attempts
    ),
    CONSTRAINT valid_expiry CHECK (expires_at > created_at)
);
-- 2. Create reset_tokens table for post-OTP verification
CREATE TABLE IF NOT EXISTS public.reset_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    token TEXT NOT NULL UNIQUE,
    -- JWT or UUID token
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    used BOOLEAN NOT NULL DEFAULT false,
    -- Constraints
    CONSTRAINT valid_token_expiry CHECK (expires_at > created_at)
);
-- 3. Create rate_limit table to prevent abuse
CREATE TABLE IF NOT EXISTS public.rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    identifier TEXT NOT NULL,
    -- email or IP address
    action TEXT NOT NULL,
    -- 'request_otp', 'verify_otp', etc.
    attempt_count INTEGER NOT NULL DEFAULT 1,
    window_start TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_rate_limit UNIQUE(identifier, action)
);
-- 4. Create indexes for fast lookups
-- Note: Removed "expires_at > now()" from WHERE clauses because now() is STABLE, not IMMUTABLE
-- The queries will still filter expired tokens at runtime
CREATE INDEX IF NOT EXISTS idx_otp_tokens_email_purpose ON public.otp_tokens(email, purpose)
WHERE used = false;
CREATE INDEX IF NOT EXISTS idx_otp_tokens_expires ON public.otp_tokens(expires_at)
WHERE used = false;
CREATE INDEX IF NOT EXISTS idx_reset_tokens_token ON public.reset_tokens(token)
WHERE used = false;
CREATE INDEX IF NOT EXISTS idx_rate_limits_identifier_action ON public.rate_limits(identifier, action, window_start);
-- 5. Enable Row Level Security
ALTER TABLE public.otp_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reset_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;
-- 6. RLS Policies - Only Edge Functions/Service Role can access
-- No direct user access to these sensitive tables
DROP POLICY IF EXISTS "Service role only access to otp_tokens" ON public.otp_tokens;
CREATE POLICY "Service role only access to otp_tokens" ON public.otp_tokens USING (auth.role() = 'service_role');
DROP POLICY IF EXISTS "Service role only access to reset_tokens" ON public.reset_tokens;
CREATE POLICY "Service role only access to reset_tokens" ON public.reset_tokens USING (auth.role() = 'service_role');
DROP POLICY IF EXISTS "Service role only access to rate_limits" ON public.rate_limits;
CREATE POLICY "Service role only access to rate_limits" ON public.rate_limits USING (auth.role() = 'service_role');
-- 7. Automatic cleanup function for expired tokens
CREATE OR REPLACE FUNCTION public.cleanup_expired_tokens() RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$ BEGIN -- Delete expired OTP tokens older than 1 hour
DELETE FROM public.otp_tokens
WHERE expires_at < now() - INTERVAL '1 hour';
-- Delete expired reset tokens older than 1 hour
DELETE FROM public.reset_tokens
WHERE expires_at < now() - INTERVAL '1 hour';
-- Delete old rate limit records older than 1 day
DELETE FROM public.rate_limits
WHERE window_start < now() - INTERVAL '1 day';
END;
$$;
-- 8. Function to check rate limit (with proper locking to prevent race conditions)
CREATE OR REPLACE FUNCTION public.check_rate_limit(
        p_identifier TEXT,
        p_action TEXT,
        p_max_attempts INTEGER DEFAULT 3,
        p_window_minutes INTEGER DEFAULT 15
    ) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE v_current_count INTEGER;
v_window_start TIMESTAMPTZ;
BEGIN -- Get current rate limit record with lock to prevent race condition
SELECT attempt_count,
    window_start INTO v_current_count,
    v_window_start
FROM public.rate_limits
WHERE identifier = p_identifier
    AND action = p_action FOR
UPDATE;
-- Lock the row to prevent concurrent updates
-- If no record exists, create one
IF NOT FOUND THEN
INSERT INTO public.rate_limits (identifier, action, attempt_count, window_start)
VALUES (p_identifier, p_action, 1, now());
RETURN true;
END IF;
-- If window expired, reset counter
IF v_window_start < now() - (p_window_minutes || ' minutes')::INTERVAL THEN
UPDATE public.rate_limits
SET attempt_count = 1,
    window_start = now()
WHERE identifier = p_identifier
    AND action = p_action;
RETURN true;
END IF;
-- If within limits, increment counter
IF v_current_count < p_max_attempts THEN
UPDATE public.rate_limits
SET attempt_count = attempt_count + 1
WHERE identifier = p_identifier
    AND action = p_action;
RETURN true;
END IF;
-- Rate limit exceeded
RETURN false;
END;
$$;
-- 9. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO service_role;
GRANT ALL ON public.otp_tokens TO service_role;
GRANT ALL ON public.reset_tokens TO service_role;
GRANT ALL ON public.rate_limits TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_tokens TO service_role;
GRANT EXECUTE ON FUNCTION public.check_rate_limit TO service_role;
-- 10. Comment documentation
COMMENT ON TABLE public.otp_tokens IS 'Stores OTP codes for password reset and email verification';
COMMENT ON TABLE public.reset_tokens IS 'Stores temporary tokens after OTP verification for password reset';
COMMENT ON TABLE public.rate_limits IS 'Prevents abuse by tracking request frequency per identifier';
COMMENT ON FUNCTION public.check_rate_limit IS 'Returns false if rate limit exceeded, true otherwise';