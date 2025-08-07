import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/breathing_animation_widget.dart';
import './widgets/gamification_demo_widget.dart';
import './widgets/onboarding_page_widget.dart';
import './widgets/page_indicator_widget.dart';
import './widgets/permission_card_widget.dart';
import './widgets/workout_animation_widget.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  // Permission states
  bool _cameraPermissionGranted = false;
  bool _healthPermissionGranted = false;
  bool _notificationPermissionGranted = false;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Track Your Nutrition\nEffortlessly',
      'description':
          'Scan barcodes, snap photos of meals, or search our extensive food database. Get detailed nutrition insights with AI-powered meal recognition.',
      'imageUrl':
          'https://images.unsplash.com/photo-1490645935967-10de6ba17061?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3',
      'hasAnimation': false,
    },
    {
      'title': 'Achieve Your\nFitness Goals',
      'description':
          'Custom workouts, progress tracking, and adaptive programs. From HIIT to yoga, find the perfect routine for your lifestyle.',
      'imageUrl':
          'https://images.pexels.com/photos/416778/pexels-photo-416778.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
      'hasAnimation': true,
      'animationType': 'workout',
    },
    {
      'title': 'Find Your Inner\nBalance',
      'description':
          'Guided meditation, breathing exercises, and mood tracking. Build mindfulness habits that support your mental wellness journey.',
      'imageUrl':
          'https://images.pixabay.com/photo/2017/03/26/21/54/yoga-2176668_1280.jpg',
      'hasAnimation': true,
      'animationType': 'breathing',
    },
    {
      'title': 'Stay Motivated\nWith Challenges',
      'description':
          'Earn badges, maintain streaks, and join community challenges. Turn your wellness journey into an engaging adventure.',
      'imageUrl':
          'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3',
      'hasAnimation': true,
      'animationType': 'gamification',
    },
    {
      'title': 'Grant Permissions\nfor Best Experience',
      'description':
          'Enable camera for food scanning, health data sync, and notifications to get the most out of AlignWise.',
      'imageUrl':
          'https://images.pexels.com/photos/267350/pexels-photo-267350.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
      'hasAnimation': false,
      'isPermissionPage': true,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    Navigator.pushReplacementNamed(context, '/dashboard-home');
    HapticFeedback.mediumImpact();
  }

  void _completeOnboarding() {
    Navigator.pushReplacementNamed(context, '/dashboard-home');
    HapticFeedback.mediumImpact();
  }

  void _requestCameraPermission() {
    setState(() {
      _cameraPermissionGranted = !_cameraPermissionGranted;
    });
    HapticFeedback.selectionClick();

    if (_cameraPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Camera permission granted for food scanning'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _requestHealthPermission() {
    setState(() {
      _healthPermissionGranted = !_healthPermissionGranted;
    });
    HapticFeedback.selectionClick();

    if (_healthPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Health data access granted for fitness tracking'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _requestNotificationPermission() {
    setState(() {
      _notificationPermissionGranted = !_notificationPermissionGranted;
    });
    HapticFeedback.selectionClick();

    if (_notificationPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notifications enabled for wellness reminders'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildAnimationWidget(String animationType) {
    switch (animationType) {
      case 'workout':
        return const WorkoutAnimationWidget();
      case 'breathing':
        return const BreathingAnimationWidget();
      case 'gamification':
        return const GamificationDemoWidget();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPermissionPage() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'security',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 10.w,
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _onboardingData[_currentPage]['title'],
                    style:
                        AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _onboardingData[_currentPage]['description'],
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    PermissionCardWidget(
                      iconName: 'camera_alt',
                      title: 'Camera Access',
                      description:
                          'Scan barcodes and capture meal photos for nutrition tracking',
                      isGranted: _cameraPermissionGranted,
                      onTap: _requestCameraPermission,
                    ),
                    PermissionCardWidget(
                      iconName: 'favorite',
                      title: 'Health Data',
                      description:
                          'Sync with HealthKit/Google Fit for comprehensive tracking',
                      isGranted: _healthPermissionGranted,
                      onTap: _requestHealthPermission,
                    ),
                    PermissionCardWidget(
                      iconName: 'notifications',
                      title: 'Notifications',
                      description:
                          'Receive reminders and motivational wellness nudges',
                      isGranted: _notificationPermissionGranted,
                      onTap: _requestNotificationPermission,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                HapticFeedback.selectionClick();
              },
              itemCount: _totalPages,
              itemBuilder: (context, index) {
                final pageData = _onboardingData[index];

                if (pageData['isPermissionPage'] == true) {
                  return _buildPermissionPage();
                }

                return OnboardingPageWidget(
                  title: pageData['title'],
                  description: pageData['description'],
                  imageUrl: pageData['imageUrl'],
                  animationWidget: pageData['hasAnimation'] == true
                      ? _buildAnimationWidget(pageData['animationType'])
                      : null,
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              child: Column(
                children: [
                  PageIndicatorWidget(
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              HapticFeedback.lightImpact();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                            ),
                            child: Text(
                              'Back',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: TextButton(
                            onPressed: _skipOnboarding,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                            ),
                            child: Text(
                              'Skip',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(width: 4.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentPage == _totalPages - 1
                                ? 'Get Started'
                                : 'Next',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
