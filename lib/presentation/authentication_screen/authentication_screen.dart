import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import './widgets/auth_toggle_button.dart';
import './widgets/custom_text_field.dart';
import './widgets/social_login_button.dart';
import './widgets/wellness_logo.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({Key? key}) : super(key: key);

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with TickerProviderStateMixin {
  bool _isSignIn = true;
  bool _isLoading = false;
  bool _showValidation = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final _supabaseService = SupabaseService.instance;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    _fadeController.forward();

    // Check if user is already signed in
    _checkAuthState();
  }

  void _checkAuthState() {
    if (_supabaseService.isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard-home');
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isSignIn) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != _passwordController.text) {
        return 'Passwords do not match';
      }
    }
    return null;
  }

  String? _validateName(String? value) {
    if (!_isSignIn) {
      if (value == null || value.isEmpty) {
        return 'Name is required';
      }
      if (value.length < 2) {
        return 'Name must be at least 2 characters';
      }
    }
    return null;
  }

  bool _isFormValid() {
    final emailValid = _validateEmail(_emailController.text) == null;
    final passwordValid = _validatePassword(_passwordController.text) == null;
    final nameValid = _isSignIn || _validateName(_nameController.text) == null;
    final confirmPasswordValid = _isSignIn ||
        _validateConfirmPassword(_confirmPasswordController.text) == null;

    return emailValid && passwordValid && nameValid && confirmPasswordValid;
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _showValidation = false;
    });

    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _handleAuthentication() async {
    setState(() {
      _showValidation = true;
    });

    if (!_isFormValid()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isSignIn) {
        // Sign In
        final response = await _supabaseService.signIn(
          email: email,
          password: password,
        );

        if (response.user != null) {
          HapticFeedback.lightImpact();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard-home');
          }
        }
      } else {
        // Sign Up
        final fullName = _nameController.text.trim();
        final response = await _supabaseService.signUp(
          email: email,
          password: password,
          fullName: fullName.isNotEmpty ? fullName : null,
        );

        if (response.user != null) {
          HapticFeedback.lightImpact();
          _showSuccessSnackBar(
            'Account created successfully! Please check your email to verify your account.',
          );

          // Switch to sign in mode
          setState(() {
            _isSignIn = true;
            _showValidation = false;
          });

          // Clear form fields
          _nameController.clear();
          _confirmPasswordController.clear();
        }
      }
    } on AuthException catch (error) {
      _showErrorSnackBar(_getAuthErrorMessage(error));
    } catch (error) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getAuthErrorMessage(AuthException error) {
    switch (error.message.toLowerCase()) {
      case 'invalid login credentials':
        return 'Invalid email or password. Please check your credentials.';
      case 'user not found':
        return 'No account found with this email address.';
      case 'email already registered':
      case 'user already registered':
        return 'An account with this email already exists. Please sign in instead.';
      case 'weak password':
        return 'Password should be at least 6 characters long.';
      case 'invalid email':
        return 'Please enter a valid email address.';
      default:
        return error.message;
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(4.w),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(4.w),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;

      switch (provider.toLowerCase()) {
        case 'google':
          success = await _supabaseService.signInWithGoogle();
          break;
        case 'apple':
          success = await _supabaseService.signInWithApple();
          break;
        case 'facebook':
          success = await _supabaseService.signInWithFacebook();
          break;
        default:
          _showErrorSnackBar('$provider login is not available yet.');
          return;
      }

      if (success) {
        HapticFeedback.lightImpact();
        if (mounted) {
          // Show success message
          _showSuccessSnackBar('Successfully signed in with $provider!');

          // Navigate to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard-home');
        }
      } else {
        _showErrorSnackBar(
            '$provider login was cancelled or failed. Please try again.');
      }
    } on AuthException catch (error) {
      String errorMessage = _getSocialAuthErrorMessage(error, provider);
      _showErrorSnackBar(errorMessage);
    } catch (error) {
      String errorMessage = _getSocialAuthErrorMessage(null, provider);
      _showErrorSnackBar(errorMessage);
      print('Social login error ($provider): $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getSocialAuthErrorMessage(AuthException? authError, String provider) {
    if (authError != null) {
      switch (authError.message.toLowerCase()) {
        case 'user_not_found':
          return 'No account found. Please sign up first or try a different method.';
        case 'invalid_credentials':
          return '$provider authentication failed. Please try again.';
        case 'email_already_exists':
          return 'An account with this email already exists. Please sign in instead.';
        case 'weak_password':
          return 'Please use a stronger password.';
        case 'invalid_email':
          return 'Please check your email address.';
        case 'oauth configuration error':
        case 'invalid_client':
          return 'OAuth configuration issue. Please contact support if this problem persists.';
        default:
          if (authError.message.toLowerCase().contains('oauth') ||
              authError.message.toLowerCase().contains('client')) {
            return '$provider OAuth is not properly configured. Please contact support.';
          }
          return authError.message;
      }
    }

    switch (provider.toLowerCase()) {
      case 'google':
        return 'Google sign-in failed. Please check your internet connection and try again, or contact support if the issue persists.';
      case 'apple':
        return 'Apple sign-in failed. Please make sure you\'re signed in to iCloud and try again, or contact support if the issue persists.';
      case 'facebook':
        return 'Facebook sign-in failed. Please check your Facebook app permissions and try again, or contact support if the issue persists.';
      default:
        return '$provider sign-in failed. Please try again or contact support.';
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Password',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a password reset link.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              if (email.isEmpty || _validateEmail(email) != null) {
                _showErrorSnackBar('Please enter a valid email address.');
                return;
              }

              try {
                await _supabaseService.resetPassword(email);
                Navigator.pop(context);
                _showSuccessSnackBar(
                  'Password reset email sent! Check your inbox.',
                );
              } catch (error) {
                _showErrorSnackBar(
                    'Failed to send reset email. Please try again.');
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    SizedBox(height: 8.h),

                    // Logo Section
                    const WellnessLogo(),

                    SizedBox(height: 6.h),

                    // Auth Toggle
                    AuthToggleButton(
                      isSignIn: _isSignIn,
                      onToggle: _toggleAuthMode,
                    ),

                    SizedBox(height: 4.h),

                    // Form Fields
                    if (!_isSignIn) ...[
                      CustomTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        iconName: 'person',
                        controller: _nameController,
                        validator: _validateName,
                        showValidation: _showValidation,
                      ),
                      SizedBox(height: 2.h),
                    ],

                    CustomTextField(
                      label: 'Email',
                      hint: 'Enter your email',
                      iconName: 'email',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      validator: _validateEmail,
                      showValidation: _showValidation,
                    ),

                    SizedBox(height: 2.h),

                    CustomTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      iconName: 'lock',
                      isPassword: true,
                      controller: _passwordController,
                      validator: _validatePassword,
                      showValidation: _showValidation,
                    ),

                    if (!_isSignIn) ...[
                      SizedBox(height: 2.h),
                      CustomTextField(
                        label: 'Confirm Password',
                        hint: 'Confirm your password',
                        iconName: 'lock',
                        isPassword: true,
                        controller: _confirmPasswordController,
                        validator: _validateConfirmPassword,
                        showValidation: _showValidation,
                      ),
                    ],

                    if (_isSignIn) ...[
                      SizedBox(height: 1.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 3.h),

                    // Main Action Button
                    Container(
                      width: double.infinity,
                      height: 6.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleAuthentication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormValid() && !_showValidation
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 5.w,
                                height: 5.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Text(
                                _isSignIn ? 'Sign In' : 'Create Account',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text(
                            'Or continue with',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 3.h),

                    // Social Login Buttons
                    SocialLoginButton(
                      iconName: 'g_translate',
                      label: 'Continue with Google',
                      onPressed: () => _handleSocialLogin('Google'),
                    ),

                    SocialLoginButton(
                      iconName: 'apple',
                      label: 'Continue with Apple',
                      onPressed: () => _handleSocialLogin('Apple'),
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                    ),

                    SocialLoginButton(
                      iconName: 'facebook',
                      label: 'Continue with Facebook',
                      onPressed: () => _handleSocialLogin('Facebook'),
                      backgroundColor: const Color(0xFF1877F2),
                      textColor: Colors.white,
                    ),

                    SizedBox(height: 4.h),

                    // Terms and Privacy
                    if (!_isSignIn)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Text(
                          'By creating an account, you agree to our Terms of Service and Privacy Policy',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),

                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
