import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SessionHeroWidget extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onJoin;
  final Function(bool isBookmarked) onBookmark;

  const SessionHeroWidget({
    super.key,
    required this.session,
    required this.onJoin,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = session['status'] == 'live';
    final isBookmarked = session['is_bookmarked'] ?? false;
    final scheduledStart = DateTime.tryParse(session['scheduled_start'] ?? '');

    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.w),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: CustomImageWidget(
                imageUrl: session['session_image_url'] ??
                    'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=800&q=80',
                fit: BoxFit.cover,
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(77),
                      Colors.black.withAlpha(204),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Live badge
            if (isLive)
              Positioned(
                top: 4.w,
                left: 4.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.w,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 2.w,
                        height: 2.w,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bookmark button
            Positioned(
              top: 4.w,
              right: 4.w,
              child: GestureDetector(
                onTap: () => onBookmark(isBookmarked),
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                    size: 6.w,
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session type badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.w,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Text(
                        session['session_type']?.toString().toUpperCase() ??
                            'WELLNESS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Title
                    Text(
                      session['title'] ?? 'Live Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 1.h),

                    // Instructor info
                    Row(
                      children: [
                        // Instructor avatar
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: CustomImageWidget(
                              imageUrl: session['instructor_avatar'] ??
                                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        SizedBox(width: 3.w),

                        // Instructor name and details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session['instructor_name'] ?? 'Instructor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${session['difficulty_level']?.toString().toUpperCase() ?? 'BEGINNER'} • ${session['duration_minutes'] ?? 30} min',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(204),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Participants count
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: Colors.white.withAlpha(204),
                          size: 5.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${session['current_participants'] ?? 0}/${session['max_participants'] ?? 100} joined',
                          style: TextStyle(
                            color: Colors.white.withAlpha(204),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 3.h),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onJoin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isLive ? Colors.red : AppTheme.primaryLight,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 4.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3.w),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isLive ? 'Join Live Session' : 'Set Reminder',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Time info for scheduled sessions
                    if (!isLive && scheduledStart != null) ...[
                      SizedBox(height: 2.h),
                      Center(
                        child: Text(
                          _formatScheduledTime(scheduledStart),
                          style: TextStyle(
                            color: Colors.white.withAlpha(204),
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScheduledTime(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.inHours > 24) {
      return 'Starts ${difference.inDays} days from now';
    } else if (difference.inHours > 0) {
      return 'Starts in ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return 'Starts in ${difference.inMinutes} minutes';
    }
  }
}