import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SessionProgressWidget extends StatelessWidget {
  final int totalDuration;
  final int remainingTime;
  final String sessionTitle;
  final String instructorName;

  const SessionProgressWidget({
    super.key,
    required this.totalDuration,
    required this.remainingTime,
    required this.sessionTitle,
    required this.instructorName,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (totalDuration - remainingTime) / totalDuration;
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          sessionTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'with $instructorName',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),
        SizedBox(
          width: 60.w,
          height: 60.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60.w,
                height: 60.w,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.lightTheme.colorScheme.secondary,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'remaining',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
