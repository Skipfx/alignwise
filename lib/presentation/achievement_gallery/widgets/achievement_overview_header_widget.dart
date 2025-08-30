import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementOverviewHeaderWidget extends StatelessWidget {
  final int totalBadges;
  final int completedBadges;
  final double completionPercentage;
  final int currentStreak;
  final int totalPoints;

  const AchievementOverviewHeaderWidget({
    super.key,
    required this.totalBadges,
    required this.completedBadges,
    required this.completionPercentage,
    required this.currentStreak,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple[600]!,
            Colors.pink[500]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievement Progress',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$completedBadges of $totalBadges badges earned',
                      style: GoogleFonts.inter(
                        color: Colors.white.withAlpha(230),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${completionPercentage.toInt()}%',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress Ring and Stats
          Row(
            children: [
              // Achievement Progress Circle
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: completionPercentage / 100,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withAlpha(77),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.military_tech,
                            color: Colors.white,
                            size: 24,
                          ),
                          Text(
                            '$completedBadges',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Stats Grid
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Points',
                        _formatNumber(totalPoints),
                        Icons.stars,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Current Streak',
                        '$currentStreak days',
                        Icons.local_fire_department,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Next Milestone Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Milestone',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _getNextMilestoneText(),
                        style: GoogleFonts.inter(
                          color: Colors.white.withAlpha(230),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _getBadgesUntilNextMilestone().toString(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'left',
                  style: GoogleFonts.inter(
                    color: Colors.white.withAlpha(204),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withAlpha(230),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _getNextMilestoneText() {
    final nextMilestone = _getNextMilestone();
    switch (nextMilestone) {
      case 5:
        return 'Achievement Starter';
      case 10:
        return 'Badge Collector';
      case 25:
        return 'Achievement Hunter';
      case 50:
        return 'Badge Master';
      case 100:
        return 'Achievement Legend';
      default:
        return 'Ultimate Champion';
    }
  }

  int _getNextMilestone() {
    const milestones = [5, 10, 25, 50, 100, 200];
    for (final milestone in milestones) {
      if (completedBadges < milestone) {
        return milestone;
      }
    }
    return 500; // Ultimate goal
  }

  int _getBadgesUntilNextMilestone() {
    return _getNextMilestone() - completedBadges;
  }
}
