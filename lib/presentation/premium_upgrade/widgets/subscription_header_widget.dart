import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SubscriptionHeaderWidget extends StatelessWidget {
  final VoidCallback onClose;

  const SubscriptionHeaderWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Premium Upgrade',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: CustomIconWidget(
              iconName: 'close',
              color: AppTheme.textSecondaryLight,
              size: 6.w,
            ),
            padding: EdgeInsets.all(2.w),
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.cardColor,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
