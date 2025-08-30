import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class UpcomingSessionsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final Function(String sessionId, bool isBookmarked) onBookmark;
  final Function(String instructorId, bool isFollowing) onFollowInstructor;

  const UpcomingSessionsWidget({
    super.key,
    required this.sessions,
    required this.onBookmark,
    required this.onFollowInstructor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 3.h),
          child: _buildSessionCard(session),
        );
      },
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final isBookmarked = session['is_bookmarked'] ?? false;
    final isFollowing = session['is_following_instructor'] ?? false;
    final scheduledStart = DateTime.tryParse(session['scheduled_start'] ?? '');

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Session image
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3.w),
                  child: CustomImageWidget(
                    imageUrl: session['session_image_url'] ??
                        'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=300&q=80',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(width: 4.w),

              // Session info
              Expanded(
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
                      session['title'] ?? 'Upcoming Session',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 1.h),

                    // Duration and max participants
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 4.w,
                          color: AppTheme.textPrimaryLight.withAlpha(153),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${session['duration_minutes'] ?? 30} min',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textPrimaryLight.withAlpha(179),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.people,
                          size: 4.w,
                          color: AppTheme.textPrimaryLight.withAlpha(153),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Max ${session['max_participants'] ?? 100}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textPrimaryLight.withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bookmark button
              GestureDetector(
                onTap: () => onBookmark(session['session_id'], isBookmarked),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.textPrimaryLight.withAlpha(51),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked
                        ? AppTheme.primaryBlue
                        : AppTheme.textPrimaryLight.withAlpha(153),
                    size: 5.w,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Instructor info
          Row(
            children: [
              // Instructor avatar
              Container(
                width: 10.w,
                height: 10.w,
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

              SizedBox(width: 3.w),

              // Instructor name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['instructor_name'] ?? 'Instructor',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Wellness Instructor',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textPrimaryLight.withAlpha(153),
                      ),
                    ),
                  ],
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
                    horizontal: 4.w,
                    vertical: 2.w,
                  ),
                  decoration: BoxDecoration(
                    color: isFollowing
                        ? AppTheme.primaryBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2.w),
                    border: Border.all(
                      color: AppTheme.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isFollowing ? Colors.white : AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Scheduled time and reminder button
          Row(
            children: [
              // Scheduled time
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 2.w,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withAlpha(26),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 4.w,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      scheduledStart != null
                          ? _formatScheduledTime(scheduledStart)
                          : 'Time TBA',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Set reminder button
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement calendar integration
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 3.w,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Set Reminder',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Required equipment
          if (session['required_equipment'] != null &&
              (session['required_equipment'] as List).isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              'Equipment needed:',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight.withAlpha(204),
              ),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: (session['required_equipment'] as List)
                  .map<Widget>((equipment) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimaryLight.withAlpha(26),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Text(
                    equipment.toString(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.textPrimaryLight.withAlpha(179),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatScheduledTime(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.isNegative) {
      return 'Session has started';
    } else if (difference.inHours > 24) {
      return 'Starts in ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return 'In ${difference.inMinutes} minutes';
    }
  }
}