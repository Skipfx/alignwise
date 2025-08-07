import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementProgressCardWidget extends StatelessWidget {
  final String title;
  final String description;
  final int currentProgress;
  final int targetProgress;
  final String progressUnit;
  final String badgeRarity;
  final VoidCallback onTap;

  const AchievementProgressCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.currentProgress,
    required this.targetProgress,
    required this.progressUnit,
    required this.badgeRarity,
    required this.onTap,
  });

  double get _progressPercentage {
    if (targetProgress == 0) return 0.0;
    return (currentProgress / targetProgress).clamp(0.0, 1.0);
  }

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
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with rarity badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _rarityColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeRarity.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _rarityColor,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Achievement Title
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Achievement Description
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Progress Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$currentProgress / $targetProgress $progressUnit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _rarityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progressPercentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_rarityColor),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 8),

            // Progress Percentage
            Text(
              '${(_progressPercentage * 100).toInt()}% Complete',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            // Completion Motivation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 14,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${targetProgress - currentProgress} more to unlock',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
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
}
