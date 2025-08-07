import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TeamChallengeCard extends StatelessWidget {
  final String title;
  final String teamName;
  final List<Map<String, dynamic>> teamMembers;
  final double teamProgress;
  final int rank;
  final int totalTeams;
  final String imageUrl;
  final VoidCallback onTap;

  const TeamChallengeCard({
    Key? key,
    required this.title,
    required this.teamName,
    required this.teamMembers,
    required this.teamProgress,
    required this.rank,
    required this.totalTeams,
    required this.imageUrl,
    required this.onTap,
  }) : super(key: key);

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
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Team Avatar
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.lightTheme.primaryColor,
                          AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: 'groups',
                      color: Colors.white,
                      size: 6.w.clamp(20.0, 28.0),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Team Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          title,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Rank Badge
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: _getRankColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#$rank',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.sp,
                      ),
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
                  // Team Members
                  Row(
                    children: [
                      // Member Avatars
                      SizedBox(
                        height: 8.w,
                        child: Stack(
                          children: teamMembers.take(4).map((member) {
                            final index = teamMembers.indexOf(member);
                            return Positioned(
                              left: index * 5.w,
                              child: Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.lightTheme.cardColor,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: CustomImageWidget(
                                    imageUrl: member['avatar'] as String,
                                    width: 8.w,
                                    height: 8.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(width: (teamMembers.length * 5.w) + 2.w),
                      if (teamMembers.length > 4)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.lightTheme.colorScheme.outline,
                          ),
                          child: Center(
                            child: Text(
                              '+${teamMembers.length - 4}',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '${teamMembers.length} members',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  // Progress
                  Row(
                    children: [
                      Text(
                        'Team Progress',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(teamProgress * 100).toInt()}%',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.lightTheme.primaryColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  LinearProgressIndicator(
                    value: teamProgress,
                    backgroundColor: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.lightTheme.primaryColor,
                    ),
                    minHeight: 6,
                  ),
                  SizedBox(height: 1.h),
                  // Rank Info
                  Text(
                    'Rank $rank of $totalTeams teams',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor() {
    if (rank == 1) {
      return const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      return const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      return const Color(0xFFCD7F32); // Bronze
    } else {
      return AppTheme.lightTheme.primaryColor;
    }
  }
}
