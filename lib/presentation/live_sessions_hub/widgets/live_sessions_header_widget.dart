import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class LiveSessionsHeaderWidget extends StatelessWidget {
  final int liveSessionsCount;
  final int upcomingCount;

  const LiveSessionsHeaderWidget({
    super.key,
    required this.liveSessionsCount,
    required this.upcomingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withAlpha(26),
            AppTheme.lightMint.withAlpha(26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.w),
        border: Border.all(
          color: AppTheme.primaryBlue.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Live Sessions Hub',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),

          SizedBox(height: 1.h),

          // Subtitle
          Text(
            'Join real-time wellness experiences with expert instructors',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textPrimaryLight.withAlpha(179),
              height: 1.3,
            ),
          ),

          SizedBox(height: 3.h),

          // Stats row
          Row(
            children: [
              // Live sessions count
              Expanded(
                child: _buildStatCard(
                  icon: Icons.circle,
                  iconColor: Colors.red,
                  title: 'Live Now',
                  count: liveSessionsCount,
                  subtitle: liveSessionsCount == 1 ? 'session' : 'sessions',
                ),
              ),

              SizedBox(width: 3.w),

              // Upcoming sessions count
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  iconColor: AppTheme.primaryBlue,
                  title: 'Upcoming',
                  count: upcomingCount,
                  subtitle: upcomingCount == 1 ? 'session' : 'sessions',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title row
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight.withAlpha(204),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          // Count
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textPrimaryLight.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }
}