import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import './widgets/auth_toggle_button.dart';
import './widgets/custom_text_field.dart';
import './widgets/wellness_logo.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _emailSent = false;
  String? _pendingEmailVerification;
  bool _showManualVerification = false;
  final TextEditingController _otpController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  final _authService = AuthService.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    return _formKey.currentState!.validate();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message.replaceFirst('Exception: ', '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSignUp) {
        // Sign up
        final response = await _authService.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim());

        if (mounted) {
          if (response.user != null &&
              response.user!.emailConfirmedAt == null) {
            // Email verification required
            setState(() {
              _emailSent = true;
              _pendingEmailVerification = _emailController.text.trim();
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    '📧 Account created! Please check your email and click the verification link to continue.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5)));
          } else {
            // Email already verified or no verification needed
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Account created successfully!'),
                backgroundColor: Colors.green));
            Navigator.pushReplacementNamed(context, AppRoutes.dashboardHome);
          }
        }
      } else {
        // Sign in
        await _authService.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text);

        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboardHome);
        }
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = error.toString().replaceFirst('Exception: ', '');

        // Handle specific error cases
        if (errorMessage.contains('Email not verified')) {
          setState(() {
            _emailSent = true;
            _pendingEmailVerification = _emailController.text.trim();
          });
          errorMessage =
              '📧 Email not verified. Please check your email for the verification link.';
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResendVerification() async {
    if (_pendingEmailVerification == null) return;

    try {
      await _authService.resendEmailConfirmation(_pendingEmailVerification!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('📧 Verification email resent! Check your inbox.'),
            backgroundColor: Colors.green));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error: ${error.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: Colors.orange));
      return;
    }

    try {
      await _authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                '📧 Password reset email sent! Check your inbox and click the reset link.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error: ${error.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _openEmailApp() async {
    try {
      // Try to open default email app
      final Uri emailUri = Uri(scheme: 'mailto');
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback - show instructions
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Check Your Email'),
              content: const Text(
                'Please open your email app and look for the verification email from AlignWise. '
                'Click the "Confirm your mail" button in the email to verify your account.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to open email app: $e');
    }
  }

  Future<void> _signUp() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );

      if (mounted) {
        if (response.user != null && response.user!.emailConfirmedAt == null) {
          // Show verification dialog with multiple options
          _showEmailVerificationDialog();
        } else if (response.user != null) {
          // User is already verified, navigate to dashboard
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboardHome);
        }
      }
    } catch (error) {
      if (mounted) {
        _showErrorDialog('Sign Up Failed', error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mark_email_read, color: Theme.of(context).primaryColor),
            SizedBox(width: 2.w),
            Text('Email Verification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'ve sent a verification link to your email address.',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withAlpha(51)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Having trouble with the verification link?',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '• Check your spam/junk folder\n• Ensure your email app is set as default\n• Try manual verification with OTP code',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
            if (_showManualVerification) ...[
              SizedBox(height: 2.h),
              Text(
                'Enter the 6-digit code from your email:',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  hintText: 'Enter OTP code',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Back to Login'),
          ),
          TextButton(
            onPressed: _resendVerificationEmail,
            child: Text('Resend Email'),
          ),
          if (!_showManualVerification)
            TextButton(
              onPressed: () {
                setState(() => _showManualVerification = true);
                Navigator.of(context).pop();
                _showEmailVerificationDialog();
              },
              child: Text('Manual Verification'),
            ),
          if (_showManualVerification)
            ElevatedButton(
              onPressed: _verifyWithOtp,
              child: Text('Verify'),
            ),
        ],
      ),
    );
  }

  Future<void> _verifyWithOtp() async {
    if (_otpController.text.trim().length != 6) {
      _showErrorDialog('Invalid Code', 'Please enter a valid 6-digit code.');
      return;
    }

    try {
      setState(() => _isLoading = true);

      await AuthService.instance.verifyEmailWithOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboardHome);
        _showSuccessMessage('Email verified successfully!');
      }
    } catch (error) {
      if (mounted) {
        _showErrorDialog('Verification Failed',
            'Invalid code. Please try again or request a new verification email.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      setState(() => _isLoading = true);

      await AuthService.instance
          .resendEmailConfirmation(_emailController.text.trim());

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        _showSuccessMessage(
            'Verification email sent! Please check your inbox and spam folder.');

        // Show option for manual verification
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showEmailVerificationDialog();
          }
        });
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        _showErrorDialog('Resend Failed',
            'Failed to resend verification email. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
            child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 8.h),

                          // Logo and Title
                          const WellnessLogo(),
                          SizedBox(height: 6.h),

                          // Enhanced Email Verification Status
                          if (_emailSent &&
                              _pendingEmailVerification != null) ...[
                            Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                border: Border.all(color: Colors.blue[200]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.mark_email_read,
                                      color: Colors.blue[700], size: 8.w),
                                  SizedBox(height: 2.w),
                                  Text(
                                    '📧 Check Your Email',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  SizedBox(height: 1.w),
                                  Text(
                                    'We sent a verification link to:',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  SizedBox(height: 1.w),
                                  Text(
                                    _pendingEmailVerification!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  SizedBox(height: 2.w),
                                  Text(
                                    'Click the "Confirm your mail" button in the email to verify your account.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  SizedBox(height: 3.w),

                                  // Action buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _openEmailApp,
                                          icon: Icon(Icons.email, size: 4.w),
                                          label: const Text('Open Email'),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: Colors.blue[600]!),
                                            foregroundColor: Colors.blue[800],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 2.w),
                                      Expanded(
                                        child: TextButton(
                                          onPressed: _handleResendVerification,
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.blue[600],
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Resend Email'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 4.h),
                          ],

                          // Auth Toggle
                          AuthToggleButton(
                              isSignIn: !_isSignUp,
                              onToggle: () {
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                  _emailSent = false;
                                  _pendingEmailVerification = null;
                                });
                              }),
                          SizedBox(height: 4.h),

                          // Form Fields
                          if (_isSignUp) ...[
                            CustomTextField(
                                controller: _fullNameController,
                                hint: 'Full Name',
                                iconName: 'person',
                                label: 'Full Name',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Full name is required';
                                  }
                                  return null;
                                }),
                            SizedBox(height: 2.h),
                          ],

                          CustomTextField(
                              controller: _emailController,
                              hint: 'Email Address',
                              iconName: 'email',
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              }),
                          SizedBox(height: 2.h),

                          CustomTextField(
                              controller: _passwordController,
                              hint: 'Password',
                              iconName: 'lock',
                              label: 'Password',
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (_isSignUp && value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              }),

                          // Forgot Password (Sign In only)
                          if (!_isSignUp) ...[
                            SizedBox(height: 1.h),
                            Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                    onPressed: _handleForgotPassword,
                                    child: Text('Forgot Password?',
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontSize: 14.sp)))),
                          ],

                          SizedBox(height: 6.h),

                          // Auth Button
                          SizedBox(
                              height: 6.h,
                              child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleAuth,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 2),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2)
                                      : Text(
                                          _isSignUp
                                              ? 'Create Account'
                                              : 'Sign In',
                                          style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)))),

                          SizedBox(height: 6.h),

                          // Privacy Policy and Terms
                          Text(
                              'By continuing, you agree to our Terms of Service and Privacy Policy',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12.sp),
                              textAlign: TextAlign.center),

                          SizedBox(height: 4.h),
                        ])))));
  }
}
