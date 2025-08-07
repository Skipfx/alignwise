import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class MacroProgressRing extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final String unit;
  final Color color;
  final AnimationController animationController;

  const MacroProgressRing({
    Key? key,
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = consumed / target;
    final remaining = target - consumed;
    final percentage = (progress * 100).round();

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: Stack(
                children: [
                  // Background circle
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    backgroundColor: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  // Progress circle
                  CircularProgressIndicator(
                    value:
                        (progress * animationController.value).clamp(0.0, 1.0),
                    strokeWidth: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 1.0
                          ? AppTheme.lightTheme.colorScheme.error
                          : color,
                    ),
                  ),
                  // Center content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${consumed.toStringAsFixed(1)}',
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: progress > 1.0
                                ? AppTheme.lightTheme.colorScheme.error
                                : color,
                          ),
                        ),
                        Text(
                          unit,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            fontSize: 8.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              remaining > 0
                  ? '${remaining.toStringAsFixed(1)}$unit left'
                  : '${remaining.abs().toStringAsFixed(1)}$unit over',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: remaining > 0
                    ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    : AppTheme.lightTheme.colorScheme.error,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 0.5.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$percentage%',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
