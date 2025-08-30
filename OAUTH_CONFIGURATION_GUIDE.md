# 📧 Supabase Email Authentication Configuration Guide

## 🚨 CRITICAL: Email Configuration Required

Your authentication system is now properly implemented in code, but **email verification and password reset will NOT work** until you configure Supabase properly.

## 📋 Required Supabase Dashboard Configuration

### 1. Email Templates Configuration
Go to **Authentication > Email Templates** in your Supabase dashboard:

#### ✅ Confirm Signup Template:
- **Subject:** Welcome to AlignWise - Please verify your email
- **Body:** Update the redirect URL in the email template to:
  - **Web:** `https://your-app-domain.com/auth/confirm`
  - **Mobile:** `io.supabase.alignwise://auth/confirm`

#### ✅ Magic Link Template:
- **Subject:** Your AlignWise sign-in link
- **Body:** Update redirect URL to match your app's deep link scheme

#### ✅ Reset Password Template:
- **Subject:** Reset your AlignWise password
- **Body:** Update the reset link to:
  - **Web:** `https://your-app-domain.com/auth/reset-password`
  - **Mobile:** `io.supabase.alignwise://auth/reset-password`

### 2. Redirect URLs Configuration
Go to **Authentication > URL Configuration**:

Add these **Redirect URLs:**
```
# For web deployment
https://your-app-domain.com/auth/callback
https://your-app-domain.com/auth/confirm
https://your-app-domain.com/auth/reset-password

# For mobile app
io.supabase.alignwise://auth/callback
io.supabase.alignwise://auth/confirm  
io.supabase.alignwise://auth/reset-password
```

### 3. Site URL Configuration
Set your **Site URL** to:
- **Development:** `http://localhost:3000` or your local dev URL
- **Production:** `https://your-actual-domain.com`

## 🔧 Replace Placeholder URLs

In the code files generated, replace these placeholder URLs:

### Update in `lib/services/supabase_service.dart`:
```dart
// Replace these lines:
'https://your-app-domain.com/auth/callback'
'https://your-app-domain.com/auth/confirm'  
'https://your-app-domain.com/auth/reset-password'

// With your actual domain:
'https://alignwise.app/auth/callback'
'https://alignwise.app/auth/confirm'
'https://alignwise.app/auth/reset-password'
```

### Update in `lib/services/auth_service.dart`:
Same URL replacements as above.

## 📧 SMTP Configuration (Recommended)

### Option 1: Use Supabase Built-in SMTP (Limited)
- Default rate limits apply
- May have deliverability issues

### Option 2: Configure Custom SMTP Provider
Go to **Authentication > SMTP Settings**:

**Recommended Providers:**
- **SendGrid** (reliable, good free tier)
- **Mailgun** (developer-friendly)
- **Amazon SES** (cost-effective for scale)

**Configuration:**
- Enable custom SMTP
- Add your SMTP credentials
- Test email delivery

## 🧪 Testing Email Flows

### Test Account Verification:
1. Sign up with a real email address
2. Check email for verification link
3. Click link → should redirect to app
4. Verify user can sign in after confirmation

### Test Password Reset:
1. Go to sign-in page
2. Click "Forgot Password"
3. Enter email, click send
4. Check email for reset link
5. Click link → should redirect to app
6. Complete password reset flow

## ⚠️ Common Issues & Solutions

### Issue: No emails received
**Solutions:**
- Check spam/junk folder
- Verify SMTP configuration
- Check Supabase logs for email errors
- Verify email templates are enabled

### Issue: Email links broken
**Solutions:**
- Ensure redirect URLs match exactly
- Check deep link configuration
- Verify URL schemes in iOS/Android config

### Issue: Deep links not working
**Solutions:**
- Rebuild app after adding URL schemes
- Test on physical device (simulators may not handle deep links)
- Verify AndroidManifest.xml and Info.plist changes

## 🚀 Production Deployment

### Before Going Live:
1. ✅ Configure custom SMTP provider
2. ✅ Update all placeholder URLs to production domains
3. ✅ Test email flows end-to-end
4. ✅ Verify deep linking on actual devices
5. ✅ Set up proper domain verification for email deliverability
6. ✅ Configure rate limiting and abuse prevention

## 📞 Need Help?

If emails still don't work after this configuration:
1. Check Supabase dashboard logs
2. Verify all URLs match exactly
3. Test with multiple email providers
4. Contact Supabase support with specific error messages

---

**✅ After configuration, users will receive proper verification and password reset emails with working links that redirect back to your app correctly.**