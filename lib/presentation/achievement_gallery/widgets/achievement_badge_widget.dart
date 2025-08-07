import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final String title;
  final String description;
  final String badgeRarity;
  final String? badgeIconUrl;
  final bool isUnlocked;
  final String? unlockedAt;
  final int points;
  final VoidCallback onTap;

  const AchievementBadgeWidget({
    super.key,
    required this.title,
    required this.description,
    required this.badgeRarity,
    this.badgeIconUrl,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.points,
    required this.onTap,
  });

  Color get _rarityColor {
    switch (badgeRarity.toLowerCase()) {
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

  IconData get _badgeIcon {
    switch (badgeRarity.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked ? _rarityColor.withAlpha(77) : Colors.grey[200]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? _rarityColor.withAlpha(38)
                  : Colors.grey.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Badge Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color:
                    isUnlocked ? _rarityColor.withAlpha(26) : Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isUnlocked ? _rarityColor : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Icon(
                _badgeIcon,
                size: 32,
                color: isUnlocked ? _rarityColor : Colors.grey[400],
              ),
            ),

            const SizedBox(height: 12),

            // Badge Title
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? Colors.black87 : Colors.grey[500],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // Badge Description
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // Rarity and Points Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? _rarityColor.withAlpha(26)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeRarity.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? _rarityColor : Colors.grey[500],
                    ),
                  ),
                ),
                if (isUnlocked) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        size: 12,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$points',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // Unlocked Date
            if (isUnlocked && unlockedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Unlocked ${_formatDate(unlockedAt!)}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            // Locked State
            if (!isUnlocked) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 12,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Locked',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}
