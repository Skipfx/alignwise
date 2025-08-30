import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class ActivityFeedCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final Function(String) onReaction;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const ActivityFeedCard({
    super.key,
    required this.activity,
    required this.onReaction,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final userName = activity['user_name'] ?? 'Unknown User';
    final userAvatar = activity['user_avatar'];
    final title = activity['title'] ?? '';
    final description = activity['description'] ?? '';
    final mediaUrls = activity['media_urls'] as List<dynamic>? ?? [];
    final isAchievement = activity['is_achievement'] ?? false;
    final achievementBadge = activity['achievement_badge'];
    final reactionCount = activity['reaction_count'] ?? 0;
    final commentCount = activity['comment_count'] ?? 0;
    final userHasReacted = activity['user_has_reacted'] ?? false;
    final createdAt = DateTime.tryParse(activity['created_at'] ?? '') ?? DateTime.now();
    final tags = activity['tags'] as List<dynamic>? ?? [];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: Offset(0, 2)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          _buildHeader(userName, userAvatar, createdAt, isAchievement, achievementBadge),
          
          // Content
          if (title.isNotEmpty) _buildTitle(title),
          if (description.isNotEmpty) _buildDescription(description),
          
          // Activity data (workout/meditation stats)
          if (activity['activity_data'] != null) _buildActivityData(),
          
          // Media content
          if (mediaUrls.isNotEmpty) _buildMediaContent(mediaUrls),
          
          // Tags
          if (tags.isNotEmpty) _buildTags(tags),
          
          // Interaction bar
          _buildInteractionBar(reactionCount, commentCount, userHasReacted),
        ]));
  }

  Widget _buildHeader(String userName, String? userAvatar, DateTime createdAt, bool isAchievement, String? achievementBadge) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 6.w,
            
            backgroundImage: userAvatar != null
                ? CachedNetworkImageProvider(userAvatar)
                : null,
            child: userAvatar == null
                ? Text(
                    userName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold))
                : null),
          SizedBox(width: 3.w),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600)),
                    if (isAchievement) ...[
                      SizedBox(width: 1.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.w),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events, size: 10.sp, color: Colors.white),
                            SizedBox(width: 1.w),
                            Text(
                              _getAchievementText(achievementBadge),
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                          ])),
                    ],
                  ]),
                Text(
                  _getTimeAgo(createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp)),
              ])),
          
          // More options button
          IconButton(
            onPressed: () {
              // Show more options
            },
            icon: Icon(
              Icons.more_horiz,
              
              size: 20.sp)),
        ]));
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600)));
  }

  Widget _buildDescription(String description) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.w, 4.w, 0),
      child: Text(
        description,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          
          height: 1.4)));
  }

  Widget _buildActivityData() {
    final activityData = activity['activity_data'] as Map<String, dynamic>;
    final activityType = activity['activity_type'] ?? '';

    if (activityType == 'workout_completed') {
      return _buildWorkoutStats(activityData);
    } else if (activityType == 'meditation_session') {
      return _buildMeditationStats(activityData);
    } else if (activityType == 'meal_logged') {
      return _buildMealStats(activityData);
    }
    
    return SizedBox.shrink();
  }

  Widget _buildWorkoutStats(Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 3.w, 4.w, 0),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (data['duration_minutes'] != null)
            _buildStatItem(
              Icons.timer_outlined,
              '${data['duration_minutes']}',
              'minutes'),
          if (data['distance_km'] != null)
            _buildStatItem(
              Icons.straighten,
              '${data['distance_km']}',
              'km'),
          if (data['calories_burned'] != null)
            _buildStatItem(
              Icons.local_fire_department,
              '${data['calories_burned']}',
              'calories'),
        ]));
  }

  Widget _buildMeditationStats(Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 3.w, 4.w, 0),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.purple.withAlpha(26),
        borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (data['duration_minutes'] != null)
            _buildStatItem(
              Icons.timer_outlined,
              '${data['duration_minutes']}',
              'minutes'),
          if (data['mood_before'] != null)
            _buildStatItem(
              Icons.sentiment_neutral,
              data['mood_before'],
              'before'),
          if (data['mood_after'] != null)
            _buildStatItem(
              Icons.sentiment_very_satisfied,
              data['mood_after'],
              'after'),
        ]));
  }

  Widget _buildMealStats(Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 3.w, 4.w, 0),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(26),
        borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (data['calories'] != null)
            _buildStatItem(
              Icons.local_fire_department,
              '${data['calories']}',
              'calories'),
          if (data['protein'] != null)
            _buildStatItem(
              Icons.fitness_center,
              '${data['protein']}g',
              'protein'),
          if (data['meal_type'] != null)
            _buildStatItem(
              Icons.restaurant,
              data['meal_type'],
              'meal'),
        ]));
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: Colors.grey),
            SizedBox(width: 1.w),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600)),
          ]),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp)),
      ]);
  }

  Widget _buildMediaContent(List<dynamic> mediaUrls) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 3.w, 4.w, 0),
      child: Column(
        children: mediaUrls.take(3).map<Widget>((url) {
          return Container(
            margin: EdgeInsets.only(bottom: 2.w),
            height: 40.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: url.toString(),
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator())),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      
                      size: 24.sp))))));
        }).toList()));
  }

  Widget _buildTags(List<dynamic> tags) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 3.w, 4.w, 0),
      child: Wrap(
        spacing: 2.w,
        runSpacing: 1.w,
        children: tags.map<Widget>((tag) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300)),
            child: Text(
              '#$tag',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500)));
        }).toList()));
  }

  Widget _buildInteractionBar(int reactionCount, int commentCount, bool userHasReacted) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          // Like button
          GestureDetector(
            onTap: () => onReaction('like'),
            child: Row(
              children: [
                Icon(
                  userHasReacted ? Icons.favorite : Icons.favorite_border,
                  color: userHasReacted ? Colors.red : Colors.grey,
                  size: 20.sp),
                SizedBox(width: 1.w),
                Text(
                  '$reactionCount',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp)),
              ])),
          SizedBox(width: 6.w),
          
          // Comment button
          GestureDetector(
            onTap: onComment,
            child: Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  
                  size: 20.sp),
                SizedBox(width: 1.w),
                Text(
                  '$commentCount',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp)),
              ])),
          SizedBox(width: 6.w),
          
          // Share button
          GestureDetector(
            onTap: onShare,
            child: Icon(
              Icons.share_outlined,
              
              size: 20.sp)),
          
          Spacer(),
          
          // Encourage button
          GestureDetector(
            onTap: () => onReaction('encourage'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.w),
              decoration: BoxDecoration(
                
                borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.thumb_up_outlined,
                    
                    size: 14.sp),
                  SizedBox(width: 1.w),
                  Text(
                    'Encourage',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600)),
                ]))),
        ]));
  }

  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String _getAchievementText(String? badge) {
    if (badge == null) return 'Achievement';
    
    switch (badge) {
      case 'early_bird':
        return 'Early Bird';
      case 'cardio_champion':
        return 'Cardio Champion';
      case 'zen_master':
        return 'Zen Master';
      case 'consistency_king':
        return 'Consistency King';
      default:
        return 'Achievement';
    }
  }
}