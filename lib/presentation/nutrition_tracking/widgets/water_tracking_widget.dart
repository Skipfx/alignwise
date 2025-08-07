import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WaterTrackingWidget extends StatelessWidget {
  final int currentGlasses;
  final int targetGlasses;
  final VoidCallback onAddGlass;
  final VoidCallback onRemoveGlass;

  const WaterTrackingWidget({
    Key? key,
    required this.currentGlasses,
    required this.targetGlasses,
    required this.onAddGlass,
    required this.onRemoveGlass,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = currentGlasses / targetGlasses;
    final remainingGlasses = targetGlasses - currentGlasses;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'local_drink',
                color: Colors.blue,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Water Intake',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$currentGlasses / $targetGlasses glasses',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            height: 1.h,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  remainingGlasses > 0
                      ? '$remainingGlasses more glasses to go!'
                      : 'Daily goal achieved! 🎉',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: remainingGlasses > 0
                        ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                        : AppTheme.lightTheme.primaryColor,
                    fontWeight: remainingGlasses <= 0 ? FontWeight.w500 : null,
                  ),
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: currentGlasses > 0 ? onRemoveGlass : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: currentGlasses > 0
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomIconWidget(
                        iconName: 'remove',
                        color: currentGlasses > 0 ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  InkWell(
                    onTap: onAddGlass,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomIconWidget(
                        iconName: 'add',
                        color: Colors.blue,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 1.w,
            runSpacing: 1.h,
            children: List.generate(targetGlasses, (index) {
              final isFilled = index < currentGlasses;
              return Container(
                width: 8.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isFilled
                      ? Colors.blue
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'local_drink',
                    color: isFilled
                        ? Colors.white
                        : Colors.blue.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
