import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import './supabase_service.dart';
import './social_auth_service.dart';

class AuthService {
  static AuthService? _instance;

  AuthService._();

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  SupabaseClient get _client => SupabaseService.instance.client;

  // Authentication State
  bool get isAuthenticated => _client.auth.currentUser != null;

  User? get currentUser => _client.auth.currentUser;

  String? get currentUserId => _client.auth.currentUser?.id;

  // Stream for auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Enhanced Sign Up with improved redirect URL configuration
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      debugPrint('🔐 Starting sign up for: $email');

      // Enhanced redirect URL configuration with fallback for different environments
      final redirectUrl = _getRedirectUrl('confirm');

      debugPrint('🔗 Using redirect URL: $redirectUrl');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': 'free',
        },
        emailRedirectTo: redirectUrl,
      );

      debugPrint(
          '📧 Sign up response: ${response.user?.email} - Email confirmed: ${response.user?.emailConfirmedAt != null}');

      if (response.user != null) {
        // Create user profile
        await _createUserProfile(response.user!, fullName: fullName);

        // Show helpful message to user about email verification
        debugPrint(
            '📮 Please check your email for verification link. If you experience issues, try the manual verification option.');
      }

      return response;
    } catch (error) {
      debugPrint('❌ Sign-up failed: $error');
      throw Exception('Sign-up failed: $error');
    }
  }

  // Enhanced redirect URL generation with better fallback handling
  String _getRedirectUrl(String type) {
    if (kIsWeb) {
      // For web, use the current origin
      return '${Uri.base.origin}/auth/$type';
    } else {
      // For mobile, use the custom URL scheme
      return 'io.supabase.alignwise://auth/$type';
    }
  }

  // Enhanced Sign In with better email verification handling
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Starting sign in for: $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint(
          '✅ Sign in response: ${response.user?.email} - Email confirmed: ${response.user?.emailConfirmedAt != null}');

      // Enhanced email verification check with better user guidance
      if (response.user != null && response.user!.emailConfirmedAt == null) {
        throw Exception(
            'Email not verified. Please check your email and click the verification link. If you\'re having trouble, try using the "Resend Verification" option.');
      }

      return response;
    } catch (error) {
      debugPrint('❌ Sign-in failed: $error');
      throw Exception('Sign-in failed: $error');
    }
  }

  // Enhanced Sign Out with social providers
  Future<void> signOut() async {
    try {
      // Sign out from social providers first
      await SocialAuthService.instance.signOutFromSocialProviders();

      // Then sign out from Supabase
      await _client.auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (error) {
      debugPrint('❌ Sign-out failed: $error');
      throw Exception('Sign-out failed: $error');
    }
  }

  // Enhanced Password Reset with better redirect URL handling
  Future<void> resetPassword(String email) async {
    try {
      final redirectUrl = _getRedirectUrl('reset-password');
      debugPrint('🔗 Using password reset redirect URL: $redirectUrl');

      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );
      debugPrint('✅ Password reset email sent');
    } catch (error) {
      debugPrint('❌ Password reset failed: $error');
      throw Exception('Password reset failed: $error');
    }
  }

  // Enhanced email confirmation with better error handling
  Future<void> resendEmailConfirmation(String email) async {
    try {
      final redirectUrl = _getRedirectUrl('confirm');
      debugPrint('🔗 Resending confirmation with redirect URL: $redirectUrl');

      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: redirectUrl,
      );
      debugPrint('✅ Email confirmation resent');
    } catch (error) {
      debugPrint('❌ Failed to resend confirmation: $error');
      throw Exception('Failed to resend confirmation: $error');
    }
  }

  // New method: Manual email verification for users experiencing redirect issues
  Future<void> verifyEmailWithOtp({
    required String email,
    required String otp,
  }) async {
    try {
      debugPrint('🔐 Attempting manual email verification for: $email');

      final response = await _client.auth.verifyOTP(
        type: OtpType.signup,
        token: otp,
        email: email,
      );

      if (response.user != null) {
        debugPrint('✅ Email verified successfully via OTP');
      } else {
        throw Exception('Verification failed - invalid OTP');
      }
    } catch (error) {
      debugPrint('❌ OTP verification failed: $error');
      throw Exception('OTP verification failed: $error');
    }
  }

  // New method: Request OTP for manual verification
  Future<void> requestEmailOtp(String email) async {
    try {
      await _client.auth.signInWithOtp(email: email);
      debugPrint('✅ OTP sent to email for manual verification');
    } catch (error) {
      debugPrint('❌ Failed to send OTP: $error');
      throw Exception('Failed to send OTP: $error');
    }
  }

  // Check if user's email is verified
  bool get isEmailVerified =>
      _client.auth.currentUser?.emailConfirmedAt != null;

  // Enhanced auth callback handling with better error recovery
  Future<void> handleAuthCallback(Uri uri) async {
    try {
      debugPrint('🔗 Handling auth callback: $uri');
      debugPrint('🔗 Query parameters: ${uri.queryParameters}');

      // Check for error parameters first
      final params = uri.queryParameters;
      if (params.containsKey('error')) {
        final error = params['error'] ?? 'Unknown error';
        final errorDescription = params['error_description'] ?? '';
        debugPrint('❌ Auth error in callback: $error - $errorDescription');
        throw Exception('Authentication error: $errorDescription');
      }

      // Use getSessionFromUrl which handles the auth flow properly
      await _client.auth.getSessionFromUrl(uri);

      final user = _client.auth.currentUser;
      debugPrint('✅ Auth callback processed - User: ${user?.email}');
      debugPrint('✅ Email confirmed: ${user?.emailConfirmedAt != null}');

      if (user != null && user.emailConfirmedAt == null) {
        debugPrint('⚠️ User authenticated but email not confirmed');
        throw Exception(
            'Email verification is still pending. Please check your email.');
      }
    } catch (error) {
      debugPrint('❌ Auth callback failed: $error');
      throw Exception('Auth callback failed: $error');
    }
  }

  // New method: Handle deep link manually if automatic handling fails
  Future<void> handleManualDeepLink(String deepLinkUrl) async {
    try {
      debugPrint('🔗 Attempting to handle deep link manually: $deepLinkUrl');

      final uri = Uri.parse(deepLinkUrl);
      await handleAuthCallback(uri);
    } catch (error) {
      debugPrint('❌ Manual deep link handling failed: $error');
      throw Exception('Failed to process verification link: $error');
    }
  }

  // New method: Open email verification in external browser as fallback
  Future<void> openEmailVerificationFallback(String email) async {
    try {
      // This will open the default email app
      final emailUri = Uri(
        scheme: 'mailto',
        path: '',
        queryParameters: {
          'subject': 'AlignWise Email Verification Help',
          'body':
              'I am having trouble with email verification for account: $email. Please help me verify my account manually.',
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        debugPrint('✅ Opened email app for verification help');
      } else {
        debugPrint('❌ Cannot open email app');
      }
    } catch (error) {
      debugPrint('❌ Failed to open email verification fallback: $error');
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile(User user, {String? fullName}) async {
    try {
      await _client.from('user_profiles').insert({
        'id': user.id,
        'email': user.email,
        'full_name': fullName ?? user.userMetadata?['full_name'] ?? '',
        'avatar_url': user.userMetadata?['avatar_url'],
        'role': 'free',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ User profile created successfully');
    } catch (e) {
      // Profile might already exist, which is fine
      debugPrint('ℹ️ Profile creation note: $e');
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated) return null;

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', currentUserId!)
          .maybeSingle();

      // If no profile exists, create one from auth user data
      if (response == null) {
        final authUser = currentUser;
        if (authUser != null) {
          await _createUserProfile(authUser);
          // Try to fetch again after creation
          final newResponse = await _client
              .from('user_profiles')
              .select()
              .eq('id', currentUserId!)
              .maybeSingle();
          return newResponse;
        }
      }

      return response;
    } catch (error) {
      debugPrint('❌ Failed to get user profile: $error');
      // Return fallback data from auth user if database fails
      final authUser = currentUser;
      if (authUser != null) {
        return {
          'id': authUser.id,
          'email': authUser.email,
          'full_name': authUser.userMetadata?['full_name'] ??
              authUser.email
                  ?.split('@')
                  .first
                  .split('.')
                  .map((e) =>
                      e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '')
                  .join(' ') ??
              'User',
          'avatar_url': authUser.userMetadata?['avatar_url'],
          'role': 'free',
          'is_active': true,
          'created_at': authUser.createdAt,
          'updated_at': DateTime.now().toIso8601String(),
        };
      }
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? avatarUrl,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;
      if (preferences != null) updates['preferences'] = preferences;

      final response = await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', currentUserId!)
          .select()
          .single();

      return response;
    } catch (error) {
      debugPrint('❌ Failed to update user profile: $error');
      throw Exception('Failed to update user profile: $error');
    }
  }

  // Check if user is premium
  Future<bool> isPremiumUser() async {
    try {
      if (!isAuthenticated) return false;

      final response = await _client.rpc('is_premium_user');
      return response == true;
    } catch (error) {
      debugPrint('❌ Failed to check premium status: $error');
      return false;
    }
  }

  // Check if user is in trial
  Future<bool> isInTrial() async {
    try {
      if (!isAuthenticated) return false;

      final response = await _client.rpc('is_in_trial');
      return response == true;
    } catch (error) {
      debugPrint('❌ Failed to check trial status: $error');
      return false;
    }
  }

  // New method: Get verification status and provide guidance
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'isAuthenticated': false,
          'isVerified': false,
          'message': 'Not authenticated',
        };
      }

      final isVerified = user.emailConfirmedAt != null;
      return {
        'isAuthenticated': true,
        'isVerified': isVerified,
        'email': user.email,
        'message': isVerified
            ? 'Email verified successfully'
            : 'Email verification pending. Please check your inbox or try the manual verification option.',
      };
    } catch (error) {
      debugPrint('❌ Failed to get verification status: $error');
      return {
        'isAuthenticated': false,
        'isVerified': false,
        'message': 'Error checking verification status',
      };
    }
  }
}
