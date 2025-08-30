import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './auth_service.dart';

/// Service class for handling social authentication (Google, Apple)
/// Integrates with Supabase Auth for seamless social login experience
class SocialAuthService {
  static SocialAuthService? _instance;

  SocialAuthService._();

  static SocialAuthService get instance {
    _instance ??= SocialAuthService._();
    return _instance!;
  }

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _authService => AuthService.instance;

  // Google Sign-In configuration
  static const List<String> _googleScopes = [
    'email',
    'profile',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isGoogleInitialized = false;

  /// Initialize Google Sign-In with configuration
  Future<void> _initializeGoogleSignIn() async {
    if (!_isGoogleInitialized) {
      // GoogleSignIn instance is already initialized when created
      // We just need to track our initialization state
      _isGoogleInitialized = true;
    }
  }

  /// Sign in with Google
  /// Uses Google Sign-In plugin to get ID token and exchanges it with Supabase
  Future<AuthResponse> signInWithGoogle() async {
    try {
      debugPrint('🔵 Starting Google Sign-In...');

      if (!_isGoogleInitialized) {
        await _initializeGoogleSignIn();
      }

      // Try lightweight authentication first
      GoogleSignInAccount? currentUser =
          await _googleSignIn.attemptLightweightAuthentication();

      // If not signed in silently, show sign-in UI
      currentUser ??= await _googleSignIn.authenticate();

      debugPrint('🔵 Google user: ${currentUser.email}');

      // Get authentication details from the signed-in user
      final GoogleSignInAuthentication googleAuth = currentUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      debugPrint('🔵 Got Google ID token, authenticating with Supabase...');

      // Sign in to Supabase using Google ID token
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );

      debugPrint('🔵 Google Sign-In successful: ${response.user?.email}');

      // Create or update user profile
      if (response.user != null) {
        await _createOrUpdateSocialProfile(
          user: response.user!,
          provider: 'google',
          providerData: {
            'name': currentUser.displayName ?? '',
            'email': currentUser.email,
            'photo_url': currentUser.photoUrl,
            'id': currentUser.id,
          },
        );
      }

      return response;
    } catch (error) {
      debugPrint('❌ Google Sign-In failed: $error');

      // Handle specific error cases
      if (error is PlatformException) {
        if (error.code == 'sign_in_canceled') {
          throw Exception('Google Sign-In was cancelled');
        } else if (error.code == 'network_error') {
          throw Exception(
              'Network error during Google Sign-In. Please check your connection.');
        }
      }

      throw Exception('Google Sign-In failed: $error');
    }
  }

  /// Sign in with Apple
  /// Uses Sign in with Apple plugin and exchanges credentials with Supabase
  Future<AuthResponse> signInWithApple() async {
    try {
      debugPrint('🍎 Starting Apple Sign-In...');

      // Check if Sign in with Apple is available
      if (!await SignInWithApple.isAvailable()) {
        throw Exception('Sign in with Apple is not available on this device');
      }

      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      debugPrint(
          '🍎 Got Apple credential for: ${appleCredential.userIdentifier}');

      if (appleCredential.identityToken == null) {
        throw Exception('Failed to get Apple identity token');
      }

      debugPrint('🍎 Authenticating with Supabase...');

      // Sign in to Supabase using Apple identity token
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: appleCredential.identityToken!,
        nonce: rawNonce,
      );

      debugPrint('🍎 Apple Sign-In successful: ${response.user?.email}');

      // Create or update user profile
      if (response.user != null) {
        // Extract name from Apple credential if available
        String fullName = '';
        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          fullName =
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim();
        }

        await _createOrUpdateSocialProfile(
          user: response.user!,
          provider: 'apple',
          providerData: {
            'name': fullName.isNotEmpty
                ? fullName
                : response.user!.email?.split('@').first ?? 'User',
            'email': appleCredential.email ?? response.user!.email,
            'user_identifier': appleCredential.userIdentifier,
          },
        );
      }

      return response;
    } catch (error) {
      debugPrint('❌ Apple Sign-In failed: $error');

      if (error.toString().contains('canceled')) {
        throw Exception('Apple Sign-In was cancelled');
      } else if (error.toString().contains('not available')) {
        throw Exception('Sign in with Apple is not available on this device');
      }

      throw Exception('Apple Sign-In failed: $error');
    }
  }

  /// Sign in with Facebook - DEPRECATED
  /// Facebook authentication has been removed due to macOS compatibility issues
  /// Use Google or Apple Sign-In instead
  @Deprecated(
      'Facebook authentication is no longer supported due to macOS compatibility issues. Use signInWithGoogle() or signInWithApple() instead.')
  Future<AuthResponse> signInWithFacebook() async {
    throw UnsupportedError(
        'Facebook authentication is no longer supported due to macOS compatibility issues. '
        'Please use Google Sign-In or Apple Sign-In instead.');
  }

  /// Create or update user profile after social authentication
  /// Ensures user profile exists in the database with social provider information
  Future<void> _createOrUpdateSocialProfile({
    required User user,
    required String provider,
    required Map<String, dynamic> providerData,
  }) async {
    try {
      final profileData = {
        'id': user.id,
        'email': user.email ?? providerData['email'],
        'full_name':
            providerData['name'] ?? user.userMetadata?['full_name'] ?? 'User',
        'avatar_url':
            providerData['photo_url'] ?? user.userMetadata?['avatar_url'],
        'role': 'free',
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Try to update existing profile first
      final existingProfile = await _client
          .from('user_profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile != null) {
        // Update existing profile
        await _client
            .from('user_profiles')
            .update(profileData)
            .eq('id', user.id);
        debugPrint('✅ Updated existing user profile for $provider user');
      } else {
        // Create new profile
        profileData['created_at'] = DateTime.now().toIso8601String();
        await _client.from('user_profiles').insert(profileData);
        debugPrint('✅ Created new user profile for $provider user');
      }
    } catch (error) {
      debugPrint('⚠️ Failed to create/update user profile: $error');
      // Don't throw error as authentication was successful
    }
  }

  /// Sign out from all social providers
  Future<void> signOutFromSocialProviders() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      debugPrint('✅ Signed out from Google');

      // Note: Apple doesn't require explicit sign out
      debugPrint('✅ Social providers sign out completed');
    } catch (error) {
      debugPrint('⚠️ Error signing out from social providers: $error');
    }
  }

  /// Check if user is signed in with any social provider
  Future<Map<String, bool>> getSocialSignInStatus() async {
    try {
      // Check Google sign-in status by attempting lightweight authentication
      final GoogleSignInAccount? googleAccount =
          await _googleSignIn.attemptLightweightAuthentication();
      final bool googleSignedIn = googleAccount != null;

      return {
        'google': googleSignedIn,
        'facebook': false, // Facebook removed due to compatibility issues
        'apple': false, // Apple doesn't provide persistent sign-in status
      };
    } catch (error) {
      debugPrint('⚠️ Error checking social sign-in status: $error');
      return {
        'google': false,
        'facebook': false,
        'apple': false,
      };
    }
  }

  /// Generate a cryptographically secure nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Generate SHA256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}
