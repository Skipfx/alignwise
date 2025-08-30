import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PremiumFeaturesWidget extends StatelessWidget {
  const PremiumFeaturesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': 'restaurant_menu',
        'title': 'Unlimited Meal Library',
        'description': 'Access to 10,000+ recipes and meal plans',
        'color': AppTheme.successLight,
      },
      {
        'icon': 'psychology',
        'title': 'AI Nutrition Coaching',
        'description': 'Personalized recommendations powered by AI',
        'color': AppTheme.accentLight,
      },
      {
        'icon': 'fitness_center',
        'title': 'Exclusive Workout Programs',
        'description': 'Premium workout plans from top trainers',
        'color': AppTheme.warningLight,
      },
      {
        'icon': 'support_agent',
        'title': 'Priority Support',
        'description': '24/7 dedicated customer support',
        'color': AppTheme.primaryLight,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Features',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        ...features.map((feature) => _buildFeatureCard(feature)),
      ],
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: (feature['color'] as Color).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: feature['icon'] as String,
              color: feature['color'] as Color,
              size: 6.w,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'] as String,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  feature['description'] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: 'check_circle',
            color: AppTheme.successLight,
            size: 5.w,
          ),
        ],
      ),
    );
  }
}
