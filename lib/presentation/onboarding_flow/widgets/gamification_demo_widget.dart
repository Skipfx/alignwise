import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GamificationDemoWidget extends StatefulWidget {
  const GamificationDemoWidget({super.key});

  @override
  State<GamificationDemoWidget> createState() => _GamificationDemoWidgetState();
}

class _GamificationDemoWidgetState extends State<GamificationDemoWidget>
    with TickerProviderStateMixin {
  late AnimationController _badgeController;
  late AnimationController _streakController;
  late Animation<double> _badgeAnimation;
  late Animation<double> _streakAnimation;

  final List<Map<String, dynamic>> _badges = [
    {'icon': 'emoji_events', 'color': Colors.amber, 'label': 'First Week'},
    {
      'icon': 'local_fire_department',
      'color': Colors.orange,
      'label': '7 Day Streak'
    },
    {'icon': 'star', 'color': Colors.purple, 'label': 'Goal Crusher'},
  ];

  int _currentBadgeIndex = 0;

  @override
  void initState() {
    super.initState();

    _badgeController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _streakController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _badgeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ));

    _streakAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _streakController,
      curve: Curves.easeInOut,
    ));

    _badgeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _currentBadgeIndex = (_currentBadgeIndex + 1) % _badges.length;
            });
            _badgeController.reset();
            _badgeController.forward();
          }
        });
      }
    });

    _badgeController.forward();
    _streakController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _badgeAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _badgeAnimation.value,
              child: Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _badges[_currentBadgeIndex]['color'],
                  boxShadow: [
                    BoxShadow(
                      color: _badges[_currentBadgeIndex]['color']
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: _badges[_currentBadgeIndex]['icon'],
                    color: Colors.white,
                    size: 8.w,
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 2.h),
        AnimatedBuilder(
          animation: _streakController,
          builder: (context, child) {
            return Transform.scale(
              scale: _streakAnimation.value,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'local_fire_department',
                      color: Colors.orange,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '7 Day Streak!',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
