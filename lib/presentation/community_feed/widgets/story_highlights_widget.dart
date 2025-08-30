import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class StoryHighlightsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> stories;
  final Function(Map<String, dynamic>) onStoryTap;

  const StoryHighlightsWidget({
    super.key,
    required this.stories,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: EdgeInsets.fromLTRB(4.w, 3.w, 4.w, 2.w),
          child: Text('Daily Wellness Wins',
              style: GoogleFonts.inter(
                  fontSize: 16.sp, fontWeight: FontWeight.w600))),
      SizedBox(
          height: 20.h,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              itemCount: stories.length + 1, // +1 for "Add Your Story"
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddStoryCard();
                }

                final story = stories[index - 1];
                return _buildStoryCard(story);
              })),
    ]);
  }

  Widget _buildAddStoryCard() {
    return Container(
        width: 25.w,
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        child: Column(children: [
          Container(
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 2),
                  color: Colors.white),
              child: Center(child: Icon(Icons.add, size: 24.sp))),
          SizedBox(height: 1.w),
          Text('Your Story',
              style: GoogleFonts.inter(
                  fontSize: 10.sp, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]));
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final userProfile = story['user_profiles'] as Map<String, dynamic>? ?? {};
    final userName = userProfile['full_name'] ?? 'Unknown';
    final userAvatar = userProfile['avatar_url'];
    final mediaUrl = story['media_url'] ?? '';
    final storyType = story['story_type'] ?? '';
    final title = story['title'] ?? '';

    return GestureDetector(
        onTap: () => onStoryTap(story),
        child: Container(
            width: 25.w,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            child: Column(children: [
              Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _getStoryGradient(storyType)),
                  child: Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(18.w),
                          child: Stack(children: [
                            // Story background image
                            CachedNetworkImage(
                                imageUrl: mediaUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => Container(
                                    color: Colors.grey.shade200,
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))),
                                errorWidget: (context, url, error) => Container(
                                    child: Center(
                                        child: Icon(_getStoryIcon(storyType),
                                            size: 16.sp)))),

                            // User avatar overlay (small)
                            if (userAvatar != null)
                              Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                      width: 6.w,
                                      height: 6.w,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 1.5)),
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6.w),
                                          child: CachedNetworkImage(
                                              imageUrl: userAvatar,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) =>
                                                  Container(
                                                      child: Text(
                                                          userName
                                                              .substring(0, 1)
                                                              .toUpperCase(),
                                                          style: GoogleFonts.inter(
                                                              fontSize: 8.sp,
                                                              fontWeight:
                                                                  FontWeight.bold),
                                                          textAlign: TextAlign.center)))))),

                            // Story type badge
                            Positioned(
                                top: 2,
                                left: 2,
                                child: Container(
                                    padding: EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(153),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Icon(_getStoryIcon(storyType),
                                        color: Colors.white, size: 10.sp))),
                          ])))),
              SizedBox(height: 1.w),
              Text(userName.split(' ').first, // First name only
                  style: GoogleFonts.inter(
                      fontSize: 10.sp, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ])));
  }

  LinearGradient _getStoryGradient(String storyType) {
    switch (storyType) {
      case 'workout_selfie':
        return LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case 'milestone':
        return LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case 'motivation':
        return LinearGradient(
            colors: [Colors.blue, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case 'daily_win':
        return LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      default:
        return LinearGradient(
            colors: [Colors.grey, Colors.grey.shade400],
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight);
    }
  }

  IconData _getStoryIcon(String storyType) {
    switch (storyType) {
      case 'workout_selfie':
        return Icons.fitness_center;
      case 'milestone':
        return Icons.emoji_events;
      case 'motivation':
        return Icons.psychology;
      case 'daily_win':
        return Icons.star;
      case 'wellness_win':
        return Icons.favorite;
      default:
        return Icons.camera_alt;
    }
  }
}