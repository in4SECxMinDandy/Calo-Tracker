// Edge Function: Verify Password Reset OTP
// POST /verify-password-otp
// Body: { email: string, otp: string }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as bcrypt from "https://deno.land/x/bcrypt@v0.4.1/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestBody {
  email: string
  otp: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Parse and validate request
    const { email, otp }: RequestBody = await req.json()

    if (!email || !otp) {
      return new Response(
        JSON.stringify({ error: 'Email and OTP are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const normalizedEmail = email.toLowerCase().trim()
    const normalizedOtp = otp.trim()

    // Validate OTP format (6 digits)
    if (!/^\d{6}$/.test(normalizedOtp)) {
      return new Response(
        JSON.stringify({ error: 'Invalid OTP format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // 3. Check rate limit for OTP verification (10 attempts per 15 minutes)
    const { data: rateLimitOk } = await supabaseClient.rpc('check_rate_limit', {
      p_identifier: normalizedEmail,
      p_action: 'verify_otp',
      p_max_attempts: 10,
      p_window_minutes: 15
    })

    if (!rateLimitOk) {
      return new Response(
        JSON.stringify({
          error: 'Too many attempts. Please try again later.',
          code: 'RATE_LIMIT_EXCEEDED'
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 4. Retrieve OTP record from database
    const { data: otpRecords, error: fetchError } = await supabaseClient
      .from('otp_tokens')
      .select('*')
      .eq('email', normalizedEmail)
      .eq('purpose', 'password_reset')
      .eq('used', false)
      .order('created_at', { ascending: false })
      .limit(1)

    if (fetchError) {
      console.error('Error fetching OTP:', fetchError)
      throw fetchError
    }

    if (!otpRecords || otpRecords.length === 0) {
      return new Response(
        JSON.stringify({
          error: 'Invalid or expired OTP',
          code: 'OTP_NOT_FOUND'
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const otpRecord = otpRecords[0]

    // 5. Check if OTP has expired (5 minutes)
    const now = new Date()
    const expiresAt = new Date(otpRecord.expires_at)

    if (now > expiresAt) {
      // Delete expired OTP
      await supabaseClient
        .from('otp_tokens')
        .delete()
        .eq('id', otpRecord.id)

      return new Response(
        JSON.stringify({
          error: 'OTP has expired. Please request a new one.',
          code: 'OTP_EXPIRED'
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 6. Check if max attempts exceeded
    if (otpRecord.attempts >= otpRecord.max_attempts) {
      // Delete OTP after max attempts
      await supabaseClient
        .from('otp_tokens')
        .delete()
        .eq('id', otpRecord.id)

      return new Response(
        JSON.stringify({
          error: 'Maximum verification attempts exceeded. Please request a new OTP.',
          code: 'MAX_ATTEMPTS_EXCEEDED'
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 7. Verify OTP using timing-safe comparison
    const otpMatches = await bcrypt.compare(normalizedOtp, otpRecord.otp_hash)

    if (!otpMatches) {
      // Increment attempt counter
      await supabaseClient
        .from('otp_tokens')
        .update({ attempts: otpRecord.attempts + 1 })
        .eq('id', otpRecord.id)

      const remainingAttempts = otpRecord.max_attempts - otpRecord.attempts - 1

      return new Response(
        JSON.stringify({
          error: 'Incorrect OTP',
          code: 'OTP_INCORRECT',
          remaining_attempts: remainingAttempts
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 8. OTP is valid! Generate reset token
    const resetToken = crypto.randomUUID()

    // Token expires in 10 minutes
    const tokenExpiresAt = new Date()
    tokenExpiresAt.setMinutes(tokenExpiresAt.getMinutes() + 10)

    // 9. Store reset token
    const { error: tokenError } = await supabaseClient
      .from('reset_tokens')
      .insert({
        email: normalizedEmail,
        token: resetToken,
        expires_at: tokenExpiresAt.toISOString(),
        used: false
      })

    if (tokenError) {
      console.error('Error creating reset token:', tokenError)
      throw tokenError
    }

    // 10. Mark OTP as used
    await supabaseClient
      .from('otp_tokens')
      .update({ used: true })
      .eq('id', otpRecord.id)

    // 11. Return reset token to client
    return new Response(
      JSON.stringify({
        success: true,
        reset_token: resetToken,
        expires_at: tokenExpiresAt.toISOString(),
        message: 'OTP verified successfully'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in verify-password-otp:', error)

    return new Response(
      JSON.stringify({
        error: 'Internal server error'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
