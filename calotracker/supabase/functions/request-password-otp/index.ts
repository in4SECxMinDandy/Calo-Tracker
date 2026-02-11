// Edge Function: Request Password Reset OTP
// POST /request-password-otp
// Body: { email: string }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as bcrypt from "https://deno.land/x/bcrypt@v0.4.1/mod.ts"
import { Resend } from 'https://esm.sh/resend@2.0.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestBody {
  email: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Parse and validate request
    const { email }: RequestBody = await req.json()

    if (!email || typeof email !== 'string') {
      return new Response(
        JSON.stringify({ error: 'Email is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const normalizedEmail = email.toLowerCase().trim()

    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(normalizedEmail)) {
      return new Response(
        JSON.stringify({ error: 'Invalid email format' }),
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

    // 3. Check rate limit (3 requests per 15 minutes per email)
    const { data: rateLimitOk } = await supabaseClient.rpc('check_rate_limit', {
      p_identifier: normalizedEmail,
      p_action: 'request_otp',
      p_max_attempts: 3,
      p_window_minutes: 15
    })

    if (!rateLimitOk) {
      // SECURITY: Return success to prevent email enumeration
      return new Response(
        JSON.stringify({
          success: true,
          message: 'If the email exists, an OTP has been sent'
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 4. Check if user exists (direct query - more efficient than listUsers)
    let userExists = false
    try {
      const { data: user, error: userError } = await supabaseClient.auth.admin.getUserByEmail(normalizedEmail)
      userExists = !!user && !userError
    } catch (e) {
      // If getUserByEmail not available, user doesn't exist
      userExists = false
    }

    // SECURITY: Always return same response regardless of user existence
    // This prevents email enumeration attacks
    if (!userExists) {
      // Add artificial delay to match success timing
      await new Promise(resolve => setTimeout(resolve, 100))

      return new Response(
        JSON.stringify({
          success: true,
          message: 'If the email exists, an OTP has been sent'
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 5. Generate cryptographically secure 6-digit OTP
    const otpArray = new Uint32Array(1)
    crypto.getRandomValues(otpArray)
    const otp = (100000 + (otpArray[0] % 900000)).toString()

    // 6. Hash OTP using bcrypt (never store plaintext)
    const otpHash = await bcrypt.hash(otp)

    // 7. Invalidate any existing OTPs for this email
    await supabaseClient
      .from('otp_tokens')
      .update({ used: true })
      .eq('email', normalizedEmail)
      .eq('purpose', 'password_reset')
      .eq('used', false)

    // 8. Store OTP hash in database (expires in 5 minutes)
    const expiresAt = new Date()
    expiresAt.setMinutes(expiresAt.getMinutes() + 5)

    const { error: insertError } = await supabaseClient
      .from('otp_tokens')
      .insert({
        email: normalizedEmail,
        otp_hash: otpHash,
        purpose: 'password_reset',
        expires_at: expiresAt.toISOString(),
        max_attempts: 5,
        attempts: 0,
        used: false
      })

    if (insertError) {
      console.error('Error inserting OTP:', insertError)
      throw insertError
    }

    // 9. Send OTP via email
    // TODO: Replace with your actual email service (SendGrid, AWS SES, etc.)
    // For now, we'll use Supabase's built-in email (requires SMTP configuration)

    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
          .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
          .header { text-align: center; margin-bottom: 30px; }
          .logo { font-size: 32px; font-weight: 700; color: #2196F3; }
          .otp-box { background: #f0f9ff; border: 2px dashed #2196F3; border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0; }
          .otp-code { font-size: 42px; font-weight: 700; color: #1976D2; letter-spacing: 8px; font-family: 'Courier New', monospace; }
          .warning { background: #fff3e0; border-left: 4px solid #ff9800; padding: 16px; margin: 20px 0; border-radius: 4px; }
          .footer { text-align: center; color: #666; font-size: 14px; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">🔒 CaloTracker</div>
            <h2 style="color: #333; margin: 10px 0;">Yêu cầu đặt lại mật khẩu</h2>
          </div>

          <p style="color: #666; line-height: 1.6;">
            Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn.
            Vui lòng sử dụng mã OTP dưới đây:
          </p>

          <div class="otp-box">
            <p style="margin: 0 0 10px; color: #666; font-size: 14px;">MÃ XÁC THỰC CỦA BẠN</p>
            <div class="otp-code">${otp}</div>
            <p style="margin: 10px 0 0; color: #999; font-size: 12px;">Mã có hiệu lực trong 5 phút</p>
          </div>

          <div class="warning">
            <strong>⚠️ Lưu ý bảo mật:</strong>
            <ul style="margin: 10px 0 0; padding-left: 20px; color: #666;">
              <li>Không chia sẻ mã này với bất kỳ ai</li>
              <li>CaloTracker sẽ không bao giờ yêu cầu mã OTP qua điện thoại hoặc email</li>
              <li>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này</li>
            </ul>
          </div>

          <p style="color: #666; line-height: 1.6;">
            Sau khi nhập mã OTP thành công, bạn sẽ có thể tạo mật khẩu mới cho tài khoản.
          </p>

          <div class="footer">
            <p>Email này được gửi tự động, vui lòng không trả lời.</p>
            <p>© 2026 CaloTracker. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `

    // Send OTP email via Resend
    try {
      const resendApiKey = Deno.env.get('RESEND_API_KEY')

      if (!resendApiKey) {
        console.error('RESEND_API_KEY is not set in secrets')
        // Continue - OTP is stored in DB, user just won't receive email
      } else {
        const resend = new Resend(resendApiKey)

        // Send the email with OTP
        // NOTE: 'onboarding@resend.dev' only sends to the email you signed up with on Resend
        // To send to ANY user, verify your own domain at https://resend.com/domains
        // Then change 'from' to: 'CaloTracker <noreply@yourdomain.com>'
        const { data: emailData, error: emailSendError } = await resend.emails.send({
          from: 'CaloTracker <onboarding@resend.dev>',
          to: [normalizedEmail],
          subject: 'CaloTracker - Mã xác thực đặt lại mật khẩu',
          html: emailHtml,
        })

        if (emailSendError) {
          console.error('Resend API error:', JSON.stringify(emailSendError))
        } else {
          console.log(`OTP email sent successfully (ID: ${emailData?.id})`)
        }
      }
    } catch (emailError) {
      console.error('Error sending email:', emailError)
      // Continue even if email fails - OTP is still stored
    }

    // 10. Return success (same response for security)
    return new Response(
      JSON.stringify({
        success: true,
        message: 'If the email exists, an OTP has been sent'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in request-password-otp:', error)

    return new Response(
      JSON.stringify({
        error: 'Internal server error'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
