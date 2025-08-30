import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WorkoutMetricsWidget extends StatelessWidget {
  final String elapsedTime;
  final int caloriesBurned;
  final int heartRate;
  final int completedExercises;
  final int totalExercises;

  const WorkoutMetricsWidget({
    super.key,
    required this.elapsedTime,
    required this.caloriesBurned,
    required this.heartRate,
    required this.completedExercises,
    required this.totalExercises,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Time metric
          Expanded(
            child: _buildMetricItem(
              icon: 'access_time',
              value: elapsedTime,
              label: 'TIME',
              color: AppTheme.lightTheme.primaryColor,
            ),
          ),

          _buildDivider(),

          // Calories metric
          Expanded(
            child: _buildMetricItem(
              icon: 'local_fire_department',
              value: caloriesBurned.toString(),
              label: 'KCAL',
              color: AppTheme.lightTheme.colorScheme.secondary,
            ),
          ),

          _buildDivider(),

          // Heart rate metric
          Expanded(
            child: _buildMetricItem(
              icon: 'favorite',
              value: heartRate > 0 ? heartRate.toString() : '--',
              label: 'BPM',
              color: AppTheme.lightTheme.colorScheme.error,
            ),
          ),

          _buildDivider(),

          // Progress metric
          Expanded(
            child: _buildMetricItem(
              icon: 'fitness_center',
              value: '$completedExercises/$totalExercises',
              label: 'SETS',
              color: AppTheme.lightTheme.colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: color,
          size: 5.w,
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 0.2.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 6.h,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}
