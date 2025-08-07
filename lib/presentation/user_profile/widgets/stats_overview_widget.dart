import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StatsOverviewWidget extends StatelessWidget {
  final Map<String, dynamic> statsData;

  const StatsOverviewWidget({
    Key? key,
    required this.statsData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Wellness Journey",
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),
          _buildStatsGrid(),
          SizedBox(height: 3.h),
          _buildAchievementHighlights(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final List<Map<String, dynamic>> stats = [
      {
        "title": "Workouts",
        "value": statsData["totalWorkouts"] as int? ?? 127,
        "icon": "fitness_center",
        "color": AppTheme.primaryLight,
        "unit": "completed",
      },
      {
        "title": "Meditation",
        "value": statsData["meditationMinutes"] as int? ?? 2340,
        "icon": "self_improvement",
        "color": AppTheme.accentLight,
        "unit": "minutes",
      },
      {
        "title": "Challenges",
        "value": statsData["challengesCompleted"] as int? ?? 18,
        "icon": "emoji_events",
        "color": AppTheme.secondaryLight,
        "unit": "finished",
      },
      {
        "title": "Streak",
        "value": statsData["currentStreak"] as int? ?? 23,
        "icon": "local_fire_department",
        "color": AppTheme.warningLight,
        "unit": "days",
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(stat);
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: (stat["color"] as Color).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: stat["icon"] as String,
              color: stat["color"] as Color,
              size: 6.w,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            "${stat["value"]}",
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: stat["color"] as Color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            stat["title"] as String,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            stat["unit"] as String,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementHighlights() {
    final List<Map<String, dynamic>> achievements =
        statsData["recentAchievements"] as List<Map<String, dynamic>>? ??
            [
              {
                "title": "Consistency Champion",
                "description": "Completed 7-day wellness challenge",
                "icon": "military_tech",
                "date": "2 days ago",
                "color": AppTheme.successLight,
              },
              {
                "title": "Mindful Master",
                "description": "Reached 100 hours of meditation",
                "icon": "psychology",
                "date": "1 week ago",
                "color": AppTheme.accentLight,
              },
            ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Achievements",
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        ...achievements
            .map((achievement) => _buildAchievementCard(achievement))
            .toList(),
      ],
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: (achievement["color"] as Color).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: (achievement["color"] as Color).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: achievement["icon"] as String,
              color: achievement["color"] as Color,
              size: 6.w,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement["title"] as String,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  achievement["description"] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  achievement["date"] as String,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
