# OAuth Configuration Guide for Supabase

The "OAuth client was not found. Error 401: invalid_client" error occurs when OAuth providers are not properly configured in your Supabase project. Follow these steps to fix the issue:

## 🔧 Fix Steps

### 1. Supabase Dashboard Configuration

**Go to your Supabase project dashboard:**
1. Navigate to Authentication > Providers
2. Configure each OAuth provider you want to use:

#### Google OAuth Setup
1. Enable Google provider in Supabase
2. Add your Google OAuth credentials:
   - **Client ID (Web)**: Get from Google Cloud Console
   - **Client Secret**: Get from Google Cloud Console
3. Set redirect URL: `https://[your-project-ref].supabase.co/auth/v1/callback`

#### Apple OAuth Setup
1. Enable Apple provider in Supabase
2. Add your Apple OAuth credentials:
   - **Services ID**: From Apple Developer Console
   - **Team ID**: Your Apple Developer Team ID
   - **Key ID**: From your Apple Sign In key
   - **Private Key**: Your Apple Sign In private key
3. Configure redirect URL in Apple Developer Console

#### Facebook OAuth Setup
1. Enable Facebook provider in Supabase
2. Add your Facebook OAuth credentials:
   - **App ID**: From Facebook Developers Console
   - **App Secret**: From Facebook Developers Console
3. Set redirect URL: `https://[your-project-ref].supabase.co/auth/v1/callback`

### 2. Environment Variables Setup

Update your `env.json` file with the OAuth client IDs:

```json
{
  "GOOGLE_WEB_CLIENT_ID": "your-google-web-client-id.apps.googleusercontent.com",
  "GOOGLE_SERVER_CLIENT_ID": "your-google-server-client-id.apps.googleusercontent.com"
}
```

### 3. Platform-Specific Configuration

#### For Web (Google)
- Use the Web Client ID in your Flutter web app
- No additional platform configuration needed

#### For iOS (Google & Apple)
- Add Google Service Info plist to iOS project
- Configure URL schemes in iOS Info.plist
- Apple Sign In works automatically on iOS

#### For Android (Google & Facebook)
- Add Google Services JSON to Android project
- Configure signing certificate fingerprints
- Add Facebook App ID to strings.xml

### 4. Common OAuth Setup Issues

**Google OAuth:**
- Ensure OAuth consent screen is configured
- Add authorized domains to Google Cloud Console
- Verify SHA-1/SHA-256 fingerprints for Android

**Apple OAuth:**
- Verify Services ID configuration
- Ensure return URL is properly set
- Check private key format and permissions

**Facebook OAuth:**
- Verify App Domains in Facebook settings
- Ensure Privacy Policy URL is set
- Check App Review status if needed

### 5. Testing OAuth Configuration

1. Test each provider individually
2. Check Supabase Auth logs for specific error messages
3. Verify redirect URLs match exactly
4. Test on both development and production environments

## 🚨 Important Notes

- OAuth configuration must be done in the Supabase dashboard
- Environment variables are for client-side configuration only
- Redirect URLs must match exactly (including https/http)
- Some providers require app review for production use

## 📞 Support

If you continue experiencing issues:
1. Check Supabase Auth logs in the dashboard
2. Verify all redirect URLs and credentials
3. Test with a fresh OAuth app configuration
4. Contact Supabase support with specific error messages