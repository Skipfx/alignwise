import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for a minimum splash duration
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Check authentication status
      final authService = AuthService.instance;

      if (authService.isAuthenticated) {
        // Ensure user profile exists in database
        try {
          final profile = await authService.getCurrentUserProfile();
          if (profile == null) {
            debugPrint(
                '⚠️ User authenticated but no profile found, creating...');
            // This will create the profile automatically in getCurrentUserProfile
          }
        } catch (e) {
          debugPrint('⚠️ Profile check failed during splash: $e');
          // Continue to dashboard anyway as fallback data will be used
        }

        // User is logged in, go to dashboard
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardHome);
      } else {
        // User is not logged in, check if they've seen onboarding
        // For now, go directly to authentication
        Navigator.pushReplacementNamed(context, AppRoutes.authentication);
      }
    } catch (e) {
      debugPrint('❌ Splash screen initialization error: $e');
      // On error, go to authentication screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.authentication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 100.w,
        height: 100.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withAlpha(204),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'AW',
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.h),

            // App Name
            Text(
              'AlignWise',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),

            // Tagline
            Text(
              'Your Wellness Journey Starts Here',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white.withAlpha(230),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),

            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
