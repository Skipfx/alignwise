import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/stripe_service.dart';

class PricingPlansWidget extends StatelessWidget {
  final bool isYearly;
  final ValueChanged<bool> onToggle;

  const PricingPlansWidget({
    super.key,
    required this.isYearly,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        _buildPlanToggle(),
        SizedBox(height: 3.h),
        _buildPlanCards(),
      ],
    );
  }

  Widget _buildPlanToggle() {
    return Container(
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: !isYearly ? AppTheme.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(1.5.w),
                ),
                child: Text(
                  'Monthly',
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color:
                        !isYearly ? Colors.white : AppTheme.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: isYearly ? AppTheme.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(1.5.w),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Yearly',
                      style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(
                            color:
                                isYearly
                                    ? Colors.white
                                    : AppTheme.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Positioned(
                      top: -1.h,
                      right: 2.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successLight,
                          borderRadius: BorderRadius.circular(1.w),
                        ),
                        child: Text(
                          'SAVE 20%',
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCards() {
    return Row(
      children: [
        Expanded(child: _buildPlanCard(false)),
        SizedBox(width: 3.w),
        Expanded(child: _buildPlanCard(true)),
      ],
    );
  }

  Widget _buildPlanCard(bool isYearlyPlan) {
    final isSelected = isYearly == isYearlyPlan;

    // Updated pricing remains the same
    final price =
        isYearlyPlan
            ? StripeService.getYearlyPrice()
            : StripeService.getMonthlyPrice();
    final period = isYearlyPlan ? 'year' : 'month';
    final monthlyEquivalent =
        isYearlyPlan ? StripeService.getYearlyMonthlyEquivalent() : null;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color:
            isSelected
                ? AppTheme.primaryLight.withValues(alpha: 0.1)
                : Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color:
              isSelected
                  ? AppTheme.primaryLight
                  : AppTheme.shadowLight.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: AppTheme.primaryLight.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isYearlyPlan)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: BorderRadius.circular(1.w),
              ),
              child: Text(
                'BEST VALUE',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isYearlyPlan) SizedBox(height: 1.h),
          Text(
            isYearlyPlan ? 'Annual' : 'Monthly',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.primaryLight : null,
            ),
          ),
          SizedBox(height: 1.h),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: price,
                  style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected
                            ? AppTheme.primaryLight
                            : AppTheme.textPrimaryLight,
                  ),
                ),
                TextSpan(
                  text: '/$period',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (monthlyEquivalent != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              '$monthlyEquivalent/month',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.successLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: 2.h),
          _buildFeatureList(),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      'Unlimited AI coaching',
      'Advanced analytics',
      'Premium content library',
      'Priority support',
      '7-day free trial',
    ];

    return Column(
      children:
          features
              .map(
                (feature) => Padding(
                  padding: EdgeInsets.only(bottom: 0.5.h),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'check',
                        color: AppTheme.successLight,
                        size: 4.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          feature,
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}
