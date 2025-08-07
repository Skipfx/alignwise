import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SubscriptionCardWidget extends StatelessWidget {
  final Map<String, dynamic> subscriptionData;

  const SubscriptionCardWidget({
    Key? key,
    required this.subscriptionData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPremium = subscriptionData['isPremium'] ?? false;
    final String planName = subscriptionData['planName'] ?? 'Free Plan';
    final String nextBilling = subscriptionData['nextBilling'] ?? '';
    final String amount = subscriptionData['amount'] ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: isPremium
            ? LinearGradient(
                colors: [AppTheme.primaryLight, AppTheme.accentLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : null,
        color: isPremium ? null : AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: isPremium ? Colors.transparent : AppTheme.primaryLight.withAlpha(51),
          width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.diamond : Icons.free_breakfast,
                color: isPremium ? Colors.white : AppTheme.primaryLight,
                size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isPremium ? Colors.white : AppTheme.primaryDark)),
                    if (isPremium && nextBilling.isNotEmpty)
                      Text(
                        'Next billing: $nextBilling',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isPremium ? Colors.white70 : AppTheme.primaryDark)),
                  ])),
              if (isPremium && amount.isNotEmpty)
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isPremium ? Colors.white : AppTheme.primaryDark)),
            ]),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/premium-upgrade');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium ? Colors.white : AppTheme.primaryLight,
                foregroundColor: isPremium ? AppTheme.primaryLight : Colors.white,
                padding: EdgeInsets.symmetric(vertical: 3.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w))),
              child: Text(
                isPremium ? 'Manage Subscription' : 'Upgrade to Premium',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600)))),
        ]));
  }
}