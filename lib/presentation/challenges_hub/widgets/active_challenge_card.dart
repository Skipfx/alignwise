import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActiveChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final double progress;
  final int currentStreak;
  final int totalDays;
  final List<Map<String, dynamic>> dailyTasks;
  final String imageUrl;
  final VoidCallback onTap;

  const ActiveChallengeCard({
    super.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.currentStreak,
    required this.totalDays,
    required this.dailyTasks,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Image and Progress
            Container(
              height: 20.h,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightTheme.primaryColor,
                    AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background Image
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CustomImageWidget(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Progress Ring
                  Positioned(
                    top: 2.h,
                    right: 4.w,
                    child: SizedBox(
                      width: 15.w,
                      height: 15.w,
                      child: Stack(
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                          Center(
                            child: Text(
                              '${(progress * 100).toInt()}%',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Title and Streak
                  Positioned(
                    bottom: 2.h,
                    left: 4.w,
                    right: 4.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'local_fire_department',
                              color: Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '$currentStreak day streak',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    description,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontSize: 12.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  // Daily Tasks Preview
                  Text(
                    'Today\'s Tasks',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  ...dailyTasks
                      .take(3)
                      .map((task) => Padding(
                            padding: EdgeInsets.only(bottom: 0.5.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 4.w,
                                  height: 4.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (task['completed'] as bool)
                                        ? AppTheme.lightTheme.primaryColor
                                        : AppTheme
                                            .lightTheme.colorScheme.outline,
                                  ),
                                  child: (task['completed'] as bool)
                                      ? CustomIconWidget(
                                          iconName: 'check',
                                          color: Colors.white,
                                          size: 12,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Text(
                                    task['title'] as String,
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      fontSize: 11.sp,
                                      decoration: (task['completed'] as bool)
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: (task['completed'] as bool)
                                          ? AppTheme.lightTheme.colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.6)
                                          : AppTheme
                                              .lightTheme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      ,
                  if (dailyTasks.length > 3) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      '+${dailyTasks.length - 3} more tasks',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
