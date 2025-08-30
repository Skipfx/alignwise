import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExerciseCounterWidget extends StatelessWidget {
  final String label;
  final int currentValue;
  final int targetValue;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool isTimeBased;

  const ExerciseCounterWidget({
    super.key,
    required this.label,
    required this.currentValue,
    required this.targetValue,
    this.onIncrement,
    this.onDecrement,
    this.isTimeBased = false,
  });

  String _formatValue(int value) {
    if (isTimeBased) {
      final minutes = value ~/ 60;
      final seconds = value % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Decrement button
              GestureDetector(
                onTap: currentValue > 0 ? onDecrement : null,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: currentValue > 0
                        ? AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: currentValue > 0
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: 'remove',
                    color: currentValue > 0
                        ? AppTheme.lightTheme.primaryColor
                        : AppTheme.lightTheme.colorScheme.outline,
                    size: 5.w,
                  ),
                ),
              ),

              // Counter display
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatValue(currentValue),
                      style: AppTheme.lightTheme.textTheme.headlineMedium
                          ?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (targetValue > 0) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        '/ ${_formatValue(targetValue)}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Increment button
              GestureDetector(
                onTap: onIncrement,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.lightTheme.primaryColor,
                      width: 1,
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: 'add',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 5.w,
                  ),
                ),
              ),
            ],
          ),

          // Progress bar
          if (targetValue > 0) ...[
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: currentValue / targetValue,
              backgroundColor: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.lightTheme.primaryColor,
              ),
              minHeight: 4,
            ),
          ],
        ],
      ),
    );
  }
}
