import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class ChallengeDiscoveryCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final VoidCallback onJoin;

  const ChallengeDiscoveryCard({
    super.key,
    required this.challenge,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final title = challenge['title'] ?? 'Challenge';
    final description = challenge['description'] ?? '';
    final challengeType = challenge['challenge_type'] ?? '';
    final targetValue = challenge['target_value'] ?? 0;
    final targetUnit = challenge['target_unit'] ?? '';
    final coverImageUrl = challenge['cover_image_url'];
    final badgeIcon = challenge['badge_icon'] ?? '';
    final startDate =
        DateTime.tryParse(challenge['start_date'] ?? '') ?? DateTime.now();
    final endDate =
        DateTime.tryParse(challenge['end_date'] ?? '') ?? DateTime.now();

    return Container(
        width: 70.w,
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  offset: Offset(0, 4)),
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover image with overlay
          _buildCoverImage(coverImageUrl, challengeType, badgeIcon),

          // Challenge content
          Expanded(
              child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Challenge type badge
                        _buildChallengeTypeBadge(challengeType),
                        SizedBox(height: 2.w),

                        // Title
                        Text(title,
                            style: GoogleFonts.inter(
                                fontSize: 14.sp, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: 2.w),

                        // Target info
                        Text('Goal: $targetValue $targetUnit',
                            style: GoogleFonts.inter(
                                fontSize: 12.sp, fontWeight: FontWeight.w500)),
                        SizedBox(height: 1.w),

                        // Duration
                        Text(_getDurationText(startDate, endDate),
                            style: GoogleFonts.inter(fontSize: 11.sp)),

                        Spacer(),

                        // Join button
                        _buildJoinButton(),
                      ]))),
        ]));
  }

  Widget _buildCoverImage(
      String? coverImageUrl, String challengeType, String badgeIcon) {
    return Container(
        height: 12.h,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            gradient: _getChallengeGradient(challengeType)),
        child: Stack(children: [
          // Background image
          if (coverImageUrl != null)
            ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                    imageUrl: coverImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                            gradient: _getChallengeGradient(challengeType))),
                    errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                            gradient: _getChallengeGradient(challengeType))))),

          // Overlay gradient
          Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(colors: [
                    Colors.black.withAlpha(77),
                    Colors.transparent,
                    Colors.black.withAlpha(26),
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter))),

          // Badge icon
          Positioned(
              top: 3.w,
              right: 3.w,
              child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                      color: Colors.white.withAlpha(230),
                      shape: BoxShape.circle),
                  child: Icon(_getChallengeIcon(challengeType), size: 16.sp))),

          // Participants count (mock data)
          Positioned(
              bottom: 2.w,
              left: 3.w,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                      color: Colors.black.withAlpha(153),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people, color: Colors.white, size: 10.sp),
                    SizedBox(width: 1.w),
                    Text('${_getMockParticipantCount()} joined',
                        style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                  ]))),
        ]));
  }

  Widget _buildChallengeTypeBadge(String challengeType) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
        decoration: BoxDecoration(
            color: _getChallengeColor(challengeType).withAlpha(51),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _getChallengeColor(challengeType).withAlpha(128),
                width: 1)),
        child: Text(_getChallengeTypeLabel(challengeType),
            style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: _getChallengeColor(challengeType))));
  }

  Widget _buildJoinButton() {
    return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
            onPressed: onJoin,
            style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.5.w),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_circle_outline, size: 16.sp),
              SizedBox(width: 2.w),
              Text('Join Challenge',
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, fontWeight: FontWeight.w600)),
            ])));
  }

  LinearGradient _getChallengeGradient(String challengeType) {
    switch (challengeType) {
      case 'fitness':
        return LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case 'nutrition':
        return LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case 'mindfulness':
        return LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case 'water':
        return LinearGradient(
            colors: [Colors.blue, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      default:
        return LinearGradient(
            colors: [Colors.grey, Colors.grey.shade300],
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight);
    }
  }

  Color _getChallengeColor(String challengeType) {
    switch (challengeType) {
      case 'fitness':
        return Colors.orange;
      case 'nutrition':
        return Colors.green;
      case 'mindfulness':
        return Colors.purple;
      case 'water':
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  IconData _getChallengeIcon(String challengeType) {
    switch (challengeType) {
      case 'fitness':
        return Icons.fitness_center;
      case 'nutrition':
        return Icons.restaurant;
      case 'mindfulness':
        return Icons.self_improvement;
      case 'water':
        return Icons.water_drop;
      default:
        return Icons.emoji_events;
    }
  }

  String _getChallengeTypeLabel(String challengeType) {
    switch (challengeType) {
      case 'fitness':
        return 'FITNESS';
      case 'nutrition':
        return 'NUTRITION';
      case 'mindfulness':
        return 'MINDFULNESS';
      case 'water':
        return 'HYDRATION';
      default:
        return challengeType.toUpperCase();
    }
  }

  String _getDurationText(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    final daysRemaining = endDate.difference(now).inDays;

    if (daysRemaining > 0) {
      return '$daysRemaining days remaining';
    } else if (daysRemaining == 0) {
      return 'Ends today';
    } else {
      return 'Challenge ended';
    }
  }

  int _getMockParticipantCount() {
    // Generate a mock participant count based on challenge type
    switch (challenge['challenge_type']) {
      case 'fitness':
        return 127;
      case 'nutrition':
        return 89;
      case 'mindfulness':
        return 156;
      case 'water':
        return 203;
      default:
        return 45;
    }
  }
}