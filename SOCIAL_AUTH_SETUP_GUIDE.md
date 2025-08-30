# Social Authentication Setup Guide for AlignWise

This guide will help you configure Google Sign-In, Apple Sign-In, and Facebook Login for the AlignWise Flutter application.

## 🚀 Quick Start Checklist

### ✅ Prerequisites Completed
- [x] Social authentication packages added to pubspec.yaml
- [x] SocialAuthService implemented
- [x] UI updated with social login buttons
- [x] Android and iOS configurations prepared

### 📋 Configuration Required (Replace Placeholder Values)

## 1. Google Sign-In Setup

### A. Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing project
3. Add your Android and iOS apps to the project
4. Download configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS

### B. Android Configuration
1. Place `google-services.json` in `android/app/` directory
2. Update `android/build.gradle`:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
3. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### C. iOS Configuration
1. Place `GoogleService-Info.plist` in `ios/Runner/` directory
2. Update `ios/Runner/Info.plist` with your Google client ID:
   ```xml
   <string>com.googleusercontent.apps.YOUR_ACTUAL_GOOGLE_CLIENT_ID</string>
   ```
   Replace `YOUR_ACTUAL_GOOGLE_CLIENT_ID` with the reversed client ID from GoogleService-Info.plist

### D. Web Configuration (Optional)
If supporting web, add to `web/index.html`:
```html
<script src="https://apis.google.com/js/platform.js" async defer></script>
<meta name="google-signin-client_id" content="YOUR_GOOGLE_CLIENT_ID">
```

## 2. Apple Sign-In Setup

### A. Apple Developer Console Setup
1. Go to [Apple Developer Console](https://developer.apple.com/account/)
2. Navigate to Certificates, Identifiers & Profiles
3. Select your App ID
4. Enable "Sign In with Apple" capability
5. Configure your app's domain and return URLs

### B. iOS Configuration
Apple Sign-In is automatically configured for iOS. No additional setup required.

### C. Android Configuration (Optional)
For Android support, you need to set up a web service:
1. Create a Services ID in Apple Developer Console
2. Configure the domain and return URLs
3. The current implementation will work for iOS only

## 3. Facebook Login Setup

### A. Facebook Developers Console Setup
1. Go to [Facebook for Developers](https://developers.facebook.com/)
2. Create a new app or select existing app
3. Add Facebook Login product
4. Configure OAuth redirect URIs:
   - Add your domain for web
   - Configure deep linking for mobile

### B. Get App Credentials
From your Facebook app dashboard, note down:
- App ID
- Client Token (from Settings > Advanced)

### C. Android Configuration
1. Update `android/app/src/main/res/values/strings.xml`:
   ```xml
   <string name="facebook_app_id">YOUR_ACTUAL_FACEBOOK_APP_ID</string>
   <string name="facebook_client_token">YOUR_ACTUAL_FACEBOOK_CLIENT_TOKEN</string>
   <string name="fb_login_protocol_scheme">fbYOUR_ACTUAL_FACEBOOK_APP_ID</string>
   ```

2. Add your app's key hash to Facebook console:
   ```bash
   keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
   ```

### D. iOS Configuration
1. Update `ios/Runner/Info.plist`:
   ```xml
   <key>FacebookAppID</key>
   <string>YOUR_ACTUAL_FACEBOOK_APP_ID</string>
   <key>FacebookClientToken</key>
   <string>YOUR_ACTUAL_FACEBOOK_CLIENT_TOKEN</string>
   ```

2. Update the URL scheme:
   ```xml
   <string>fbYOUR_ACTUAL_FACEBOOK_APP_ID</string>
   ```

## 4. Supabase Configuration

### A. Enable Social Providers in Supabase Dashboard
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to Authentication > Providers
4. Enable Google, Apple, and Facebook providers

### B. Configure OAuth Settings
For each provider, configure:

**Google:**
- Client ID: From Firebase/Google Cloud Console
- Client Secret: From Firebase/Google Cloud Console

**Apple:**
- Services ID: From Apple Developer Console  
- Team ID: Your Apple Developer Team ID
- Key ID: From Apple Developer Console
- Private Key: Download from Apple Developer Console

**Facebook:**
- App ID: From Facebook Developers Console
- App Secret: From Facebook Developers Console

### C. Redirect URLs
Add these redirect URLs in each provider's configuration:
- `https://YOUR_SUPABASE_PROJECT_ID.supabase.co/auth/v1/callback`
- `io.supabase.alignwise://auth/callback` (for mobile deep linking)

## 5. Testing the Implementation

### A. Test Flow
1. Launch the app
2. Navigate to authentication screen
3. Try each social login button:
   - Google Sign-In
   - Apple Sign-In (iOS only)
   - Facebook Login

### B. Debugging Common Issues

**Google Sign-In Issues:**
- Verify google-services.json/GoogleService-Info.plist are correctly placed
- Check that the correct client ID is used in iOS URL scheme
- Ensure Firebase project has correct package name/bundle ID

**Apple Sign-In Issues:**
- Verify "Sign In with Apple" capability is enabled
- Check that the app is properly configured in Apple Developer Console
- Ensure you're testing on a device (not simulator for full functionality)

**Facebook Login Issues:**
- Verify App ID and Client Token are correctly set
- Check that key hashes are added to Facebook console
- Ensure OAuth redirect URIs are properly configured

### C. Logs and Debugging
The implementation includes detailed logging. Check:
- Flutter console for debug messages
- Android logcat for Android-specific issues  
- Xcode console for iOS-specific issues

## 6. Production Deployment

### A. Before Going Live
- [ ] Replace all placeholder values with actual credentials
- [ ] Test on physical devices
- [ ] Verify all redirect URLs are correctly configured
- [ ] Test account linking and profile creation
- [ ] Verify error handling works correctly

### B. Security Considerations
- Never commit credentials to version control
- Use environment variables for sensitive data
- Regularly rotate client secrets and tokens
- Monitor authentication logs for suspicious activity

## 7. Troubleshooting

### Common Error Messages

**"Failed to get Google ID token"**
- Check internet connection
- Verify Google services configuration
- Ensure correct client ID in URL scheme

**"Sign in with Apple is not available"**
- Ensure you're running on iOS 13+ or macOS 10.15+
- Check that capability is enabled in Xcode project

**"Facebook Sign-In failed"**
- Verify Facebook app configuration
- Check that app is not in development mode (for production)
- Ensure correct redirect URIs

## 8. Support and Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google Sign-In Documentation](https://developers.google.com/identity/sign-in/flutter)
- [Apple Sign-In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Facebook Login Documentation](https://developers.facebook.com/docs/facebook-login/)

## 📞 Need Help?

If you encounter issues during setup:
1. Check the logs for specific error messages
2. Verify all configuration steps are completed
3. Test on different devices/platforms
4. Consult the official documentation for each provider

Remember: Social authentication requires proper configuration on multiple platforms. Take time to carefully complete each step.