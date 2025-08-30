import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CalorieProgressWidget extends StatelessWidget {
  final int consumedCalories;
  final int targetCalories;
  final double consumedProtein;
  final double targetProtein;
  final double consumedCarbs;
  final double targetCarbs;
  final double consumedFat;
  final double targetFat;

  const CalorieProgressWidget({
    super.key,
    required this.consumedCalories,
    required this.targetCalories,
    required this.consumedProtein,
    required this.targetProtein,
    required this.consumedCarbs,
    required this.targetCarbs,
    required this.consumedFat,
    required this.targetFat,
  });

  @override
  Widget build(BuildContext context) {
    final remainingCalories = targetCalories - consumedCalories;
    final progress = consumedCalories / targetCalories;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Calories',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Text(
                          '$consumedCalories',
                          style: AppTheme.lightTheme.textTheme.headlineSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' / $targetCalories kcal',
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      remainingCalories > 0
                          ? '$remainingCalories calories remaining'
                          : '${remainingCalories.abs()} calories over',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: remainingCalories > 0
                            ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                            : AppTheme.lightTheme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 1.0
                            ? AppTheme.lightTheme.colorScheme.error
                            : AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(progress * 100).round()}%',
                        style:
                            AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: progress > 1.0
                              ? AppTheme.lightTheme.colorScheme.error
                              : AppTheme.lightTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Column(
            children: [
              _buildMacroBar(
                'Protein',
                consumedProtein,
                targetProtein,
                AppTheme.lightTheme.colorScheme.secondary,
                'g',
              ),
              SizedBox(height: 1.5.h),
              _buildMacroBar(
                'Carbs',
                consumedCarbs,
                targetCarbs,
                AppTheme.lightTheme.colorScheme.tertiary,
                'g',
              ),
              SizedBox(height: 1.5.h),
              _buildMacroBar(
                'Fat',
                consumedFat,
                targetFat,
                AppTheme.lightTheme.colorScheme.secondaryContainer,
                'g',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar(
      String label, double consumed, double target, Color color, String unit) {
    final progress = consumed / target;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${consumed.toStringAsFixed(1)} / ${target.toStringAsFixed(1)}$unit',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Container(
          height: 1.h,
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: progress > 1.0
                    ? AppTheme.lightTheme.colorScheme.error
                    : color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
