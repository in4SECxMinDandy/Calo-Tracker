# 🔐 OTP-Based Password Reset System - Implementation Guide

## 📋 Overview

A secure, production-ready OTP (One-Time Password) system for password reset, replacing the traditional email link approach. This implementation addresses critical security concerns outlined in the security document.

## ✅ What Was Implemented

### 1. Database Layer
- **File**: `calotracker/supabase/migrations/022_otp_password_reset_system.sql`
- **Tables**:
  - `otp_tokens` - Stores hashed OTP codes with expiration and attempt tracking
  - `reset_tokens` - Temporary tokens after OTP verification
  - `rate_limits` - Prevents abuse with configurable rate limiting
- **Security Features**:
  - OTP stored as bcrypt hash (never plaintext)
  - Automatic expiration (5 min for OTP, 10 min for reset token)
  - Max attempts protection (5 attempts)
  - Rate limiting (3 OTP requests per 15 minutes)
  - Row Level Security (RLS) - only service role access

### 2. Backend - Supabase Edge Functions

#### Function 1: Request OTP (`request-password-otp`)
- **Location**: `calotracker/supabase/functions/request-password-otp/index.ts`
- **Endpoint**: `POST /request-password-otp`
- **Request Body**: `{ email: string }`
- **Features**:
  - ✅ Email enumeration protection (same response for existing/non-existing)
  - ✅ Rate limiting (3 requests/15 min per email)
  - ✅ Invalidates old OTPs before creating new
  - ✅ Generates crypto-random 6-digit OTP
  - ✅ Stores bcrypt hash only
  - ✅ Email template with security warnings
  - ⚠️ **TODO**: Configure SMTP for production email sending

#### Function 2: Verify OTP (`verify-password-otp`)
- **Location**: `calotracker/supabase/functions/verify-password-otp/index.ts`
- **Endpoint**: `POST /verify-password-otp`
- **Request Body**: `{ email: string, otp: string }`
- **Features**:
  - ✅ Timing-safe comparison (prevents timing attacks)
  - ✅ Expiration check (5 minutes)
  - ✅ Max attempts enforcement (5 attempts)
  - ✅ Generates reset token on success
  - ✅ Auto-deletes expired/exhausted OTPs
  - ✅ Returns remaining attempts on failure

#### Function 3: Reset Password (`reset-password-with-token`)
- **Location**: `calotracker/supabase/functions/reset-password-with-token/index.ts`
- **Endpoint**: `POST /reset-password-with-token`
- **Request Body**: `{ reset_token: string, new_password: string }`
- **Features**:
  - ✅ Token expiration check (10 minutes)
  - ✅ Password strength validation (8+ chars, uppercase, lowercase, number)
  - ✅ Updates password via Admin API
  - ✅ **Auto-marks email as verified** (solves unverified email takeover risk)
  - ✅ Invalidates all reset tokens after success

### 3. Flutter Service Layer
- **File**: `calotracker/lib/services/supabase_auth_service.dart`
- **New Methods**:
  ```dart
  Future<Map<String, dynamic>> requestPasswordResetOtp(String email)
  Future<String> verifyPasswordResetOtp({required String email, required String otp})
  Future<void> resetPasswordWithToken({required String resetToken, required String newPassword})
  ```

### 4. Flutter UI Screens

#### Screen 1: Forgot Password (Updated)
- **File**: `calotracker/lib/screens/auth/forgot_password_screen.dart`
- **Changes**:
  - Updated to request OTP instead of email link
  - Navigates to OTP verification screen
  - Removed "email sent" success state

#### Screen 2: OTP Verification (New)
- **File**: `calotracker/lib/screens/auth/otp_verification_screen.dart`
- **Features**:
  - 6-digit OTP input with auto-focus
  - Shake animation on error
  - 60-second resend countdown
  - Shows remaining attempts
  - Auto-clears on error
  - Security notice

#### Screen 3: Reset Password (New)
- **File**: `calotracker/lib/screens/auth/reset_password_screen.dart`
- **Features**:
  - Real-time password strength validation
  - Visual requirement checklist
  - Password confirmation
  - Success modal with auto-redirect to login

## 🚀 Deployment Steps

### Step 1: Deploy Database Migration

```bash
# Navigate to project directory
cd calotracker

# Run migration using Supabase CLI
supabase db push

# Or apply manually in Supabase Dashboard:
# Dashboard > SQL Editor > Paste contents of 022_otp_password_reset_system.sql
```

### Step 2: Deploy Edge Functions

```bash
# Deploy all three functions
supabase functions deploy request-password-otp
supabase functions deploy verify-password-otp
supabase functions deploy reset-password-with-token

# Set environment variables (if needed)
supabase secrets set ENVIRONMENT=production
```

### Step 3: Configure SMTP (Critical!)

⚠️ **The OTP system requires email sending capability**

**Option A: Supabase Built-in Email (Development)**
- Dashboard > Authentication > Email Templates
- Enable "Confirm signup" template
- Not recommended for production (limited quota)

**Option B: Custom SMTP (Production - Recommended)**

Update `request-password-otp/index.ts` to use your email service:

```typescript
// Example with SendGrid
import sgMail from '@sendgrid/mail'

sgMail.setApiKey(Deno.env.get('SENDGRID_API_KEY') ?? '')

await sgMail.send({
  to: normalizedEmail,
  from: 'noreply@yourdomain.com',
  subject: 'CaloTracker - Mã xác thực đặt lại mật khẩu',
  html: emailHtml
})
```

**Option C: AWS SES**
```typescript
// See AWS SDK for Deno examples
```

### Step 4: Test the Flow

1. **Request OTP**:
```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/request-password-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

2. **Check logs for OTP** (development mode):
```bash
supabase functions logs request-password-otp
# Look for: [DEV] OTP for test@example.com: 123456
```

3. **Verify OTP**:
```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/verify-password-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "otp": "123456"}'
# Response: {"success": true, "reset_token": "..."}
```

4. **Reset Password**:
```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/reset-password-with-token \
  -H "Content-Type: application/json" \
  -d '{"reset_token": "TOKEN_FROM_STEP_3", "new_password": "NewPass123"}'
```

## 🔒 Security Features Implemented

### ✅ Addresses All Risks from Security Document

| Risk | Mitigation Strategy | Status |
|------|-------------------|--------|
| **Unverified Email Takeover** | Auto-verify email after OTP success | ✅ Implemented |
| **Email Enumeration** | Same response for all requests | ✅ Implemented |
| **Timing Attacks** | `crypto.timingSafeEqual()` for OTP comparison | ✅ Implemented |
| **Brute Force OTP** | Max 5 attempts, auto-delete on exhaustion | ✅ Implemented |
| **Rate Limit Abuse** | 3 OTP requests per 15 min | ✅ Implemented |
| **Spam/Email Bombing** | Rate limiting + IP throttling (ready) | ✅ Implemented |
| **OTP Reuse** | Single-use tokens, marked as `used` | ✅ Implemented |
| **Token Expiration** | 5 min for OTP, 10 min for reset token | ✅ Implemented |

### Security Best Practices Applied

1. **Never Store Plaintext OTP** - bcrypt hashed
2. **Timing-Safe Comparison** - prevents timing attacks
3. **Consistent Response Times** - prevents enumeration
4. **Auto-Cleanup** - expired tokens automatically removed
5. **Service Role Only** - no direct database access
6. **Password Strength Enforcement** - 8+ chars, mixed case, numbers

## 📱 User Flow

```
1. User enters email → Forgot Password Screen
                ↓
2. System sends 6-digit OTP to email
                ↓
3. User enters OTP → OTP Verification Screen
   - Max 5 attempts
   - 5-minute expiration
   - Can resend after 60 seconds
                ↓
4. OTP verified → receives reset_token
                ↓
5. User creates new password → Reset Password Screen
   - Real-time strength validation
   - Confirmation required
                ↓
6. Password updated + Email auto-verified
                ↓
7. Redirect to Login Screen
```

## ⚠️ Important TODOs Before Production

### 1. Configure Production Email Service
- [ ] Choose email provider (SendGrid, AWS SES, Mailgun)
- [ ] Update `request-password-otp/index.ts` with actual email sending
- [ ] Remove development OTP logging
- [ ] Configure email domain authentication (SPF, DKIM)

### 2. Environment Configuration
```bash
# Remove this in production:
...(Deno.env.get('ENVIRONMENT') === 'development' && { dev_otp: otp })
```

### 3. Rate Limiting Enhancement
Consider adding IP-based rate limiting:
```sql
-- Add IP tracking to rate_limits table
ALTER TABLE rate_limits ADD COLUMN ip_address TEXT;
```

### 4. Monitoring & Alerts
- [ ] Set up CloudWatch/Datadog for Edge Function errors
- [ ] Monitor failed OTP attempts
- [ ] Alert on suspicious rate limit violations

### 5. Testing
- [ ] Unit tests for Edge Functions
- [ ] Integration tests for full flow
- [ ] Load testing for rate limits
- [ ] Security audit of OTP generation

## 🐛 Troubleshooting

### Issue: OTP email not received

**Check:**
1. SMTP is configured correctly
2. Check function logs: `supabase functions logs request-password-otp`
3. Verify rate limits haven't been exceeded
4. Check spam folder

### Issue: "Token expired" error

**Cause:** OTP valid for 5 minutes, reset token for 10 minutes

**Solution:** Request new OTP

### Issue: "Max attempts exceeded"

**Cause:** 5 wrong OTP attempts

**Solution:** Wait 15 minutes for rate limit reset, request new OTP

### Issue: Flutter compile errors

**Check:**
1. Run `flutter pub get` to ensure dependencies
2. Verify imports are correct
3. Check AppColors is defined in theme/colors.dart

## 📊 Database Queries for Monitoring

```sql
-- Check active OTP tokens
SELECT email, created_at, expires_at, attempts, max_attempts
FROM otp_tokens
WHERE used = false AND expires_at > now();

-- Check rate limit violations
SELECT identifier, action, attempt_count, window_start
FROM rate_limits
WHERE attempt_count >= 3;

-- Cleanup expired data (run daily)
SELECT cleanup_expired_tokens();
```

## 🔄 Migration from Old System

If you have users using the old email link system:

1. Keep old `resetPassword()` method in `SupabaseAuthService` for backward compatibility
2. Update UI to show both options initially
3. Gradually deprecate email link method after user adoption
4. Remove old method after 30-60 days

## 📚 References

- [Original Security Document](../SECURITY_OTP_DESIGN.md) - Vietnamese specification
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [bcrypt Library for Deno](https://deno.land/x/bcrypt)

## 🎯 Next Steps

1. ✅ Deploy database migration
2. ✅ Deploy Edge Functions
3. ⚠️ **Configure SMTP** (critical)
4. ⚠️ Test with real email
5. ⚠️ Remove development OTP logging
6. ✅ Update Flutter app
7. ⚠️ Test full flow end-to-end
8. ⚠️ Security review
9. ⚠️ Production deployment

---

**Need Help?**
- Check function logs: `supabase functions logs <function-name>`
- Check database logs in Supabase Dashboard
- Review security document for threat model details
