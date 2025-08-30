import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FeaturedSessionsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final Function(Map<String, dynamic>) onJoinSession;
  final Function(String sessionId, bool isBookmarked) onBookmark;
  final Function(String instructorId, bool isFollowing) onFollowInstructor;
  final bool isLive;

  const FeaturedSessionsWidget({
    super.key,
    required this.sessions,
    required this.onJoinSession,
    required this.onBookmark,
    required this.onFollowInstructor,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: _buildSessionCard(session),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final isBookmarked = session['is_bookmarked'] ?? false;
    final isFollowing = session['is_following_instructor'] ?? false;
    final participants = session['current_participants'] ?? 0;
    final maxParticipants = session['max_participants'] ?? 100;
    final scheduledStart = DateTime.tryParse(session['scheduled_start'] ?? '');

    return Container(
      width: 70.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and live badge
          Container(
            height: 20.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
            ),
            child: Stack(
              children: [
                // Session image
                ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(4.w)),
                  child: CustomImageWidget(
                    imageUrl: session['session_image_url'] ??
                        'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=800&q=80',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                // Live badge
                if (isLive)
                  Positioned(
                    top: 3.w,
                    left: 3.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.5.w,
                        vertical: 1.w,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4.w),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 1.5.w,
                            height: 1.5.w,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bookmark button
                Positioned(
                  top: 3.w,
                  right: 3.w,
                  child: GestureDetector(
                    onTap: () =>
                        onBookmark(session['session_id'], isBookmarked),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(128),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.white,
                        size: 4.w,
                      ),
                    ),
                  ),
                ),

                // Participant count
                Positioned(
                  bottom: 3.w,
                  right: 3.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 1.w,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(179),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Text(
                      '$participants/$maxParticipants',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session type and difficulty
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.w,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(26),
                          borderRadius: BorderRadius.circular(1.5.w),
                        ),
                        child: Text(
                          session['session_type']?.toString().toUpperCase() ??
                              'WELLNESS',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.w,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimaryLight.withAlpha(26),
                          borderRadius: BorderRadius.circular(1.5.w),
                        ),
                        child: Text(
                          session['difficulty_level']
                                  ?.toString()
                                  .toUpperCase() ??
                              'BEGINNER',
                          style: TextStyle(
                            color: AppTheme.textPrimaryLight,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 1.5.h),

                  // Title
                  Text(
                    session['title'] ?? 'Live Session',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 1.h),

                  // Instructor info
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryBlue.withAlpha(77),
                            width: 1,
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

                      SizedBox(width: 2.w),

                      // Instructor name
                      Expanded(
                        child: Text(
                          session['instructor_name'] ?? 'Instructor',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Follow button
                      GestureDetector(
                        onTap: () => onFollowInstructor(
                          session['instructor_id'] ?? '',
                          isFollowing,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 1.w,
                          ),
                          decoration: BoxDecoration(
                            color: isFollowing
                                ? AppTheme.primaryBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2.w),
                            border: Border.all(
                              color: AppTheme.primaryBlue,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: isFollowing
                                  ? Colors.white
                                  : AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Duration and action button
                  Row(
                    children: [
                      // Duration
                      Icon(
                        Icons.access_time,
                        size: 4.w,
                        color: AppTheme.textPrimaryLight.withAlpha(153),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${session['duration_minutes'] ?? 30} min',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textPrimaryLight.withAlpha(153),
                        ),
                      ),

                      const Spacer(),

                      // Action button
                      ElevatedButton(
                        onPressed: () => onJoinSession(session),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isLive ? Colors.red : AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.5.w,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                          elevation: 0,
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          isLive ? 'Join' : 'Remind',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Countdown for scheduled sessions
                  if (!isLive && scheduledStart != null) ...[
                    SizedBox(height: 1.h),
                    Text(
                      _getCountdownText(scheduledStart),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCountdownText(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.isNegative) {
      return 'Session has started';
    } else if (difference.inHours > 24) {
      return 'Starts in ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return 'Starts in ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return 'Starts in ${difference.inMinutes} minutes';
    }
  }
}