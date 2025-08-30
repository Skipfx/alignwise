import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/wellness_service.dart';
import '../../widgets/custom_error_widget.dart';
import './widgets/achievement_badge_widget.dart';
import './widgets/achievement_category_tab_widget.dart';
import './widgets/achievement_overview_header_widget.dart';
import './widgets/achievement_progress_card_widget.dart';
import './widgets/recent_achievements_widget.dart';

class AchievementGallery extends StatefulWidget {
  const AchievementGallery({super.key});

  @override
  State<AchievementGallery> createState() => _AchievementGalleryState();
}

class _AchievementGalleryState extends State<AchievementGallery>
    with TickerProviderStateMixin {
  final WellnessService _wellnessService = WellnessService();
  late TabController _tabController;

  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _recentAchievements = [];
  Map<String, dynamic>? _achievementStats;
  bool _isLoading = true;
  String? _errorMessage;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'All',
      'icon': Icons.star,
      'color': Colors.purple,
    },
    {
      'name': 'Fitness',
      'icon': Icons.fitness_center,
      'color': Colors.blue,
    },
    {
      'name': 'Nutrition',
      'icon': Icons.restaurant,
      'color': Colors.green,
    },
    {
      'name': 'Mindfulness',
      'icon': Icons.self_improvement,
      'color': Colors.orange,
    },
    {
      'name': 'Social',
      'icon': Icons.people,
      'color': Colors.pink,
    },
    {
      'name': 'Special',
      'icon': Icons.emoji_events,
      'color': Colors.amber,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        _wellnessService.getUserAchievements(),
        _wellnessService.getRecentAchievements(),
        _wellnessService.getAchievementStats(),
      ]);

      setState(() {
        _achievements = results[0] as List<Map<String, dynamic>>;
        _recentAchievements = results[1] as List<Map<String, dynamic>>;
        _achievementStats = results[2] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading achievement gallery data: $e');
      setState(() {
        _errorMessage = 'Failed to load achievements. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  List<Map<String, dynamic>> _getFilteredAchievements() {
    final selectedTab = _categories[_tabController.index]['name'];
    if (selectedTab == 'All') {
      return _achievements;
    }
    return _achievements.where((achievement) {
      final type = achievement['achievement_type'] ?? '';
      switch (selectedTab) {
        case 'Fitness':
          return type.contains('workout') || type.contains('program');
        case 'Nutrition':
          return type.contains('nutrition') || type.contains('calorie');
        case 'Mindfulness':
          return type.contains('mindfulness') || type.contains('meditation');
        case 'Social':
          return type.contains('social') || type.contains('challenge');
        case 'Special':
          return type.contains('special') || type.contains('event');
        default:
          return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? CustomErrorWidget(
                    message: _errorMessage!,
                    onRetry: _refreshData,
                  )
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: CustomScrollView(slivers: [
                      SliverAppBar(
                          expandedHeight: 120.0,
                          floating: false,
                          pinned: true,
                          backgroundColor: Colors.white,
                          elevation: 0,
                          flexibleSpace: FlexibleSpaceBar(
                              title: Text('Achievement Gallery',
                                  style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                              centerTitle: true),
                          leading: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.black87),
                              onPressed: () => Navigator.pop(context)),
                          actions: [
                            IconButton(
                                icon: const Icon(Icons.share,
                                    color: Colors.black87),
                                onPressed: () {
                                  // TODO: Implement achievement sharing
                                }),
                          ]),
                      SliverToBoxAdapter(
                          child: Column(children: [
                        // Achievement Overview Header
                        AchievementOverviewHeaderWidget(
                            totalBadges:
                                _achievementStats?['total_achievements'] ?? 0,
                            completedBadges:
                                _achievementStats?['completed_achievements'] ??
                                    0,
                            completionPercentage:
                                (_achievementStats?['completion_percentage'] ??
                                        0)
                                    .toDouble(),
                            currentStreak:
                                _achievementStats?['current_streak'] ?? 0,
                            totalPoints:
                                _achievementStats?['total_points'] ?? 0),

                        const SizedBox(height: 20),

                        // Recent Achievements Section
                        if (_recentAchievements.isNotEmpty) ...[
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(children: [
                                Icon(Icons.new_releases,
                                    color: Colors.amber[600], size: 20),
                                const SizedBox(width: 8),
                                Text('Recent Unlocks',
                                    style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                              ])),
                          const SizedBox(height: 12),
                          RecentAchievementsWidget(
                              achievements: _recentAchievements,
                              onShareAchievement: (achievement) {
                                // TODO: Implement share functionality
                              }),
                          const SizedBox(height: 24),
                        ],

                        // Category Tabs
                        SizedBox(
                            height: 60,
                            child: TabBar(
                                controller: _tabController,
                                isScrollable: true,
                                indicatorColor: Colors.transparent,
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                tabs: _categories.map((category) {
                                  return AchievementCategoryTabWidget(
                                      name: category['name'],
                                      icon: category['icon'],
                                      color: category['color'],
                                      isSelected:
                                          _categories[_tabController.index]
                                                  ['name'] ==
                                              category['name']);
                                }).toList())),

                        const SizedBox(height: 16),

                        // Achievements Grid
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: AnimatedBuilder(
                                animation: _tabController,
                                builder: (context, child) {
                                  final filteredAchievements =
                                      _getFilteredAchievements();

                                  if (filteredAchievements.isEmpty) {
                                    return SizedBox(
                                        height: 200,
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.emoji_events_outlined,
                                                  size: 64,
                                                  color: Colors.grey[400]),
                                              const SizedBox(height: 16),
                                              Text(
                                                  'No achievements in this category yet',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      color: Colors.grey[600])),
                                              const SizedBox(height: 8),
                                              Text(
                                                  'Keep working towards your goals!',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      color: Colors.grey[500])),
                                            ]));
                                  }

                                  return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 16,
                                              mainAxisSpacing: 16,
                                              childAspectRatio: 0.9),
                                      itemCount: filteredAchievements.length,
                                      itemBuilder: (context, index) {
                                        final achievement =
                                            filteredAchievements[index];
                                        final isCompleted =
                                            achievement['is_completed'] ??
                                                false;
                                        final progress =
                                            achievement['progress_value'] ?? 0;
                                        final target =
                                            achievement['target_value'] ?? 100;

                                        if (isCompleted) {
                                          final achievementDef = achievement[
                                                  'achievement_definitions']
                                              as Map<String, dynamic>?;
                                          return AchievementBadgeWidget(
                                              title: achievementDef?['title'] ??
                                                  achievement['title'] ??
                                                  'Unknown Achievement',
                                              description: achievementDef?[
                                                      'description'] ??
                                                  achievement['description'] ??
                                                  '',
                                              badgeRarity: achievementDef?[
                                                      'badge_rarity'] ??
                                                  achievement['badge_rarity'] ??
                                                  'common',
                                              badgeIconUrl:
                                                  achievement['badge_icon_url'],
                                              isUnlocked: true,
                                              unlockedAt:
                                                  achievement['completed_at'],
                                              points: achievementDef?[
                                                      'points_awarded'] ??
                                                  achievement[
                                                      'points_awarded'] ??
                                                  0,
                                              onTap: () {
                                                // TODO: Show achievement details
                                              });
                                        } else {
                                          final achievementDef = achievement[
                                                  'achievement_definitions']
                                              as Map<String, dynamic>?;
                                          return AchievementProgressCardWidget(
                                              title: achievementDef?['title'] ??
                                                  achievement['title'] ??
                                                  'Unknown Achievement',
                                              description: achievementDef?[
                                                      'description'] ??
                                                  achievement['description'] ??
                                                  '',
                                              currentProgress: progress,
                                              targetProgress: target,
                                              progressUnit: achievementDef?[
                                                      'target_unit'] ??
                                                  achievement['target_unit'] ??
                                                  'points',
                                              badgeRarity: achievementDef?[
                                                      'badge_rarity'] ??
                                                  achievement['badge_rarity'] ??
                                                  'common',
                                              onTap: () {
                                                // TODO: Show achievement details
                                              });
                                        }
                                      });
                                })),
                        const SizedBox(height: 100),
                      ])),
                    ])),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // TODO: Navigate to achievement hunting mode
            },
            backgroundColor: Colors.amber[600],
            icon: const Icon(Icons.search, color: Colors.white),
            label: Text('Hunt Achievements',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600))));
  }
}
