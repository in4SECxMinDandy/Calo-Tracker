// Edge Function: Reset Password with Token
// POST /reset-password-with-token
// Body: { reset_token: string, new_password: string }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestBody {
  reset_token: string
  new_password: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Parse and validate request
    const { reset_token, new_password }: RequestBody = await req.json()

    if (!reset_token || !new_password) {
      return new Response(
        JSON.stringify({ error: 'Reset token and new password are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Validate password strength
    if (new_password.length < 8) {
      return new Response(
        JSON.stringify({
          error: 'Password must be at least 8 characters long',
          code: 'PASSWORD_TOO_SHORT'
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Additional password validation
    const hasUpperCase = /[A-Z]/.test(new_password)
    const hasLowerCase = /[a-z]/.test(new_password)
    const hasNumber = /\d/.test(new_password)

    if (!hasUpperCase || !hasLowerCase || !hasNumber) {
      return new Response(
        JSON.stringify({
          error: 'Password must contain at least one uppercase letter, one lowercase letter, and one number',
          code: 'PASSWORD_TOO_WEAK'
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 3. Initialize Supabase client with service role
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

    // 4. Retrieve and validate reset token
    const { data: tokenRecords, error: fetchError } = await supabaseClient
      .from('reset_tokens')
      .select('*')
      .eq('token', reset_token)
      .eq('used', false)
      .limit(1)

    if (fetchError) {
      console.error('Error fetching reset token:', fetchError)
      throw fetchError
    }

    if (!tokenRecords || tokenRecords.length === 0) {
      return new Response(
        JSON.stringify({
          error: 'Invalid or expired reset token',
          code: 'TOKEN_INVALID'
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const tokenRecord = tokenRecords[0]

    // 5. Check if token has expired (10 minutes)
    const now = new Date()
    const expiresAt = new Date(tokenRecord.expires_at)

    if (now > expiresAt) {
      // Delete expired token
      await supabaseClient
        .from('reset_tokens')
        .delete()
        .eq('id', tokenRecord.id)

      return new Response(
        JSON.stringify({
          error: 'Reset token has expired. Please start the password reset process again.',
          code: 'TOKEN_EXPIRED'
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 6. Get user by email (direct query - more efficient than listUsers)
    let user = null
    try {
      const { data: userData, error: userError } = await supabaseClient.auth.admin.getUserByEmail(tokenRecord.email)
      if (!userError && userData) {
        user = userData
      }
    } catch (e) {
      // If getUserByEmail not available, user not found
      user = null
    }

    if (!user) {
      return new Response(
        JSON.stringify({
          error: 'User not found',
          code: 'USER_NOT_FOUND'
        }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 7. Update user's password and verify email in one call
    // Since user verified via OTP, we can safely mark email as confirmed
    const { error: updateError } = await supabaseClient.auth.admin.updateUserById(
      user.id,
      {
        password: new_password,
        email_confirm: true
      }
    )

    if (updateError) {
      console.error('Error updating password:', updateError)
      throw updateError
    }

    // 9. Mark reset token as used
    await supabaseClient
      .from('reset_tokens')
      .update({ used: true })
      .eq('id', tokenRecord.id)

    // 10. Invalidate all other reset tokens for this email
    await supabaseClient
      .from('reset_tokens')
      .delete()
      .eq('email', tokenRecord.email)
      .neq('id', tokenRecord.id)

    // 11. Optional: Send confirmation email
    // TODO: Implement email notification of password change

    // 12. Return success
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Password has been reset successfully',
        email_verified: true
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in reset-password-with-token:', error)

    return new Response(
      JSON.stringify({
        error: 'Internal server error'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
