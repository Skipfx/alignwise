import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentAchievementsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  final Function(Map<String, dynamic>) onShareAchievement;

  const RecentAchievementsWidget({
    super.key,
    required this.achievements,
    required this.onShareAchievement,
  });

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber[200]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: Colors.amber[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No recent achievements',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete activities to unlock new badges',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildRecentAchievementCard(achievement),
          );
        },
      ),
    );
  }

  Widget _buildRecentAchievementCard(Map<String, dynamic> achievement) {
    final badgeRarity = achievement['badge_rarity'] ?? 'common';
    final title = achievement['title'] ?? 'Achievement';
    final completedAt = achievement['completed_at'] ?? '';
    final points = achievement['points_awarded'] ?? 0;

    Color rarityColor = _getRarityColor(badgeRarity);
    IconData badgeIcon = _getBadgeIcon(badgeRarity);

    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rarityColor.withAlpha(77),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withAlpha(38),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Achievement Badge with Animation Effect
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: rarityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: rarityColor, width: 2),
                ),
                child: Icon(
                  badgeIcon,
                  size: 26,
                  color: rarityColor,
                ),
              ),
              // Shine effect for recent achievements
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withAlpha(77),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Achievement Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          // Points Earned
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars,
                  size: 12,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 4),
                Text(
                  '+$points pts',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[800],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatRecentDate(completedAt),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: () => onShareAchievement(achievement),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.share,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey[600]!;
      case 'rare':
        return Colors.blue[600]!;
      case 'epic':
        return Colors.purple[600]!;
      case 'legendary':
        return Colors.amber[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getBadgeIcon(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Icons.military_tech;
      case 'rare':
        return Icons.workspace_premium;
      case 'epic':
        return Icons.diamond;
      case 'legendary':
        return Icons.emoji_events;
      default:
        return Icons.military_tech;
    }
  }

  String _formatRecentDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}
