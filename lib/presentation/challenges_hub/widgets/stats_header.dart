import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StatsHeader extends StatefulWidget {
  final int activeChallenges;
  final int totalPoints;
  final int completedChallenges;
  final int currentStreak;

  const StatsHeader({
    Key? key,
    required this.activeChallenges,
    required this.totalPoints,
    required this.completedChallenges,
    required this.currentStreak,
  }) : super(key: key);

  @override
  State<StatsHeader> createState() => _StatsHeaderState();
}

class _StatsHeaderState extends State<StatsHeader>
    with TickerProviderStateMixin {
  late AnimationController _pointsController;
  late AnimationController _challengesController;
  late Animation<int> _pointsAnimation;
  late Animation<int> _challengesAnimation;

  @override
  void initState() {
    super.initState();

    _pointsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _challengesController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pointsAnimation = IntTween(
      begin: 0,
      end: widget.totalPoints,
    ).animate(CurvedAnimation(
      parent: _pointsController,
      curve: Curves.easeOutCubic,
    ));

    _challengesAnimation = IntTween(
      begin: 0,
      end: widget.activeChallenges,
    ).animate(CurvedAnimation(
      parent: _challengesController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _pointsController.forward();
    _challengesController.forward();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _challengesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.primaryColor,
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Stats Row
          Row(
            children: [
              // Active Challenges
              Expanded(
                child: _buildStatItem(
                  icon: 'emoji_events',
                  label: 'Active',
                  value: AnimatedBuilder(
                    animation: _challengesAnimation,
                    builder: (context, child) {
                      return Text(
                        '${_challengesAnimation.value}',
                        style: AppTheme.lightTheme.textTheme.headlineMedium
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 24.sp,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 8.h,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              // Total Points
              Expanded(
                child: _buildStatItem(
                  icon: 'stars',
                  label: 'Points',
                  value: AnimatedBuilder(
                    animation: _pointsAnimation,
                    builder: (context, child) {
                      return Text(
                        '${_formatNumber(_pointsAnimation.value)}',
                        style: AppTheme.lightTheme.textTheme.headlineMedium
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 24.sp,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          // Secondary Stats Row
          Row(
            children: [
              // Completed Challenges
              Expanded(
                child: _buildSecondaryStatItem(
                  icon: 'check_circle',
                  label: 'Completed',
                  value: '${widget.completedChallenges}',
                ),
              ),
              SizedBox(width: 4.w),
              // Current Streak
              Expanded(
                child: _buildSecondaryStatItem(
                  icon: 'local_fire_department',
                  label: 'Streak',
                  value: '${widget.currentStreak} days',
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String label,
    required Widget value,
  }) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 8.w.clamp(28.0, 36.0),
        ),
        SizedBox(height: 1.h),
        value,
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryStatItem({
    required String icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: icon,
            color: iconColor ?? Colors.white.withValues(alpha: 0.9),
            size: 5.w.clamp(18.0, 24.0),
          ),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
              ),
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 9.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}
