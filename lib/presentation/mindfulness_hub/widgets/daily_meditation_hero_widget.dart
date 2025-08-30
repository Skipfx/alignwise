import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DailyMeditationHeroWidget extends StatelessWidget {
  final Map<String, dynamic> dailyRecommendation;
  final Function(int duration) onDurationSelected;

  const DailyMeditationHeroWidget({
    super.key,
    required this.dailyRecommendation,
    required this.onDurationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> durations = [5, 10, 15, 30];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            CustomImageWidget(
              imageUrl: dailyRecommendation["image"] as String,
              width: double.infinity,
              height: 25.h,
              fit: BoxFit.cover,
            ),
            Container(
              width: double.infinity,
              height: 25.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.secondary
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Daily Recommendation',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color:
                                  AppTheme.lightTheme.colorScheme.onSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      dailyRecommendation["title"] as String,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      dailyRecommendation["description"] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: durations.map((duration) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: duration != durations.last ? 2.w : 0),
                            child: ElevatedButton(
                              onPressed: () => onDurationSelected(duration),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                              child: Text(
                                '${duration}m',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
