import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/breathing_exercises_widget.dart';
import './widgets/daily_meditation_hero_widget.dart';
import './widgets/meditation_categories_widget.dart';
import './widgets/mood_tracking_widget.dart';
import './widgets/recent_sessions_widget.dart';
import './widgets/sleep_sounds_widget.dart';
import './widgets/streak_counter_widget.dart';

class MindfulnessHub extends StatefulWidget {
  const MindfulnessHub({super.key});

  @override
  State<MindfulnessHub> createState() => _MindfulnessHubState();
}

class _MindfulnessHubState extends State<MindfulnessHub>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  String? _todaysMood;

  // Mock data
  final Map<String, dynamic> _dailyRecommendation = {
    "title": "Morning Clarity",
    "description":
        "Start your day with focused breathing and gentle awareness meditation",
    "image":
        "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
  };

  final List<Map<String, dynamic>> _meditationCategories = [
    {
      "name": "Sleep",
      "sessionCount": 24,
      "popularity": 4.8,
      "image":
          "https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    },
    {
      "name": "Focus",
      "sessionCount": 18,
      "popularity": 4.7,
      "image":
          "https://images.unsplash.com/photo-1499209974431-9dddcece7f88?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    },
    {
      "name": "Anxiety",
      "sessionCount": 15,
      "popularity": 4.9,
      "image":
          "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    },
    {
      "name": "Gratitude",
      "sessionCount": 12,
      "popularity": 4.6,
      "image":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    },
  ];

  final List<Map<String, dynamic>> _breathingExercises = [
    {
      "name": "Box Breathing",
      "description":
          "Inhale for 4, hold for 4, exhale for 4, hold for 4. Perfect for reducing stress and improving focus.",
    },
    {
      "name": "4-7-8 Technique",
      "description":
          "Inhale for 4, hold for 7, exhale for 8. Great for relaxation and better sleep.",
    },
    {
      "name": "Equal Breathing",
      "description":
          "Inhale and exhale for equal counts. Helps balance the nervous system.",
    },
  ];

  final List<Map<String, dynamic>> _recentSessions = [
    {
      "id": 1,
      "title": "Evening Wind Down",
      "type": "Meditation",
      "duration": 15,
      "date": DateTime.now().subtract(const Duration(days: 1)),
      "note":
          "Felt very relaxed after this session. Great for bedtime routine.",
      "isFavorite": true,
    },
    {
      "id": 2,
      "title": "Box Breathing",
      "type": "Breathing",
      "duration": 5,
      "date": DateTime.now().subtract(const Duration(days: 2)),
      "note": "",
      "isFavorite": false,
    },
    {
      "id": 3,
      "title": "Deep Sleep Sounds",
      "type": "Sleep",
      "duration": 30,
      "date": DateTime.now().subtract(const Duration(days: 3)),
      "note": "Ocean waves helped me fall asleep quickly.",
      "isFavorite": true,
    },
  ];

  final List<Map<String, dynamic>> _sleepSounds = [
    {
      "id": 1,
      "name": "Ocean Waves",
      "category": "Ocean",
    },
    {
      "id": 2,
      "name": "Forest Rain",
      "category": "Nature",
    },
    {
      "id": 3,
      "name": "White Noise",
      "category": "White Noise",
    },
    {
      "id": 4,
      "name": "Gentle Rain",
      "category": "Rain",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildMeditationTab(),
                  _buildBreathingTab(),
                  _buildProgressTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mindfulness Hub',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Find your inner peace',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/user-profile'),
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: CustomIconWidget(
                iconName: 'person',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorPadding: EdgeInsets.all(1.w),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Meditate'),
          Tab(text: 'Breathe'),
          Tab(text: 'Progress'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _refreshContent,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 2.h),
            StreakCounterWidget(
              currentStreak: 7,
              weeklyMinutes: 85,
              weeklyGoal: 120,
            ),
            DailyMeditationHeroWidget(
              dailyRecommendation: _dailyRecommendation,
              onDurationSelected: _startMeditation,
            ),
            MoodTrackingWidget(
              onMoodSubmit: _logMood,
              todaysMood: _todaysMood,
            ),
            RecentSessionsWidget(
              recentSessions: _recentSessions,
              onSessionTap: _replaySession,
              onFavoriteToggle: _toggleFavorite,
              onShareSession: _shareSession,
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMeditationTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 2.h),
          DailyMeditationHeroWidget(
            dailyRecommendation: _dailyRecommendation,
            onDurationSelected: _startMeditation,
          ),
          SizedBox(height: 2.h),
          MeditationCategoriesWidget(
            categories: _meditationCategories,
            onCategoryTap: _openCategory,
          ),
          SizedBox(height: 2.h),
          SleepSoundsWidget(
            sleepSounds: _sleepSounds,
            onSoundPlay: _playSleepSound,
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildBreathingTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 2.h),
          BreathingExercisesWidget(
            exercises: _breathingExercises,
            onExerciseStart: _startBreathingExercise,
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 2.h),
          StreakCounterWidget(
            currentStreak: 7,
            weeklyMinutes: 85,
            weeklyGoal: 120,
          ),
          SizedBox(height: 2.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Mood Trends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map((day) {
                    return Column(
                      children: [
                        Text(
                          day,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          ['😊', '🙂', '😊', '😔', '🙂', '😊', '😊'][[
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ].indexOf(day)],
                          style: TextStyle(fontSize: 6.w),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          RecentSessionsWidget(
            recentSessions: _recentSessions,
            onSessionTap: _replaySession,
            onFavoriteToggle: _toggleFavorite,
            onShareSession: _shareSession,
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem('home', 'Home', '/dashboard-home', false),
              _buildNavItem(
                  'restaurant', 'Nutrition', '/nutrition-tracking', false),
              _buildNavItem(
                  'fitness_center', 'Fitness', '/fitness-tracking', false),
              _buildNavItem(
                  'self_improvement', 'Mindfulness', '/mindfulness-hub', true),
              _buildNavItem(
                  'emoji_events', 'Challenges', '/challenges-hub', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      String iconName, String label, String route, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: isActive
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshContent() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Refresh content
    });
  }

  void _startMeditation(int duration) {
    Navigator.pushNamed(context, '/meditation-session');
  }

  void _logMood(String mood, String? note) {
    setState(() {
      _todaysMood = mood;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mood logged successfully!'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      ),
    );
  }

  void _openCategory(Map<String, dynamic> category) {
    Navigator.pushNamed(context, '/meditation-session');
  }

  void _startBreathingExercise(Map<String, dynamic> exercise, int duration) {
    Navigator.pushNamed(context, '/meditation-session');
  }

  void _replaySession(Map<String, dynamic> session) {
    Navigator.pushNamed(context, '/meditation-session');
  }

  void _toggleFavorite(Map<String, dynamic> session) {
    setState(() {
      final index = _recentSessions.indexWhere((s) => s["id"] == session["id"]);
      if (index != -1) {
        _recentSessions[index]["isFavorite"] =
            !(_recentSessions[index]["isFavorite"] as bool);
      }
    });
  }

  void _shareSession(Map<String, dynamic> session) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session shared successfully!'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      ),
    );
  }

  void _playSleepSound(Map<String, dynamic> sound, int? timerMinutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Playing ${sound["name"]}${timerMinutes != null ? " for ${timerMinutes}min" : " continuously"}'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      ),
    );
  }
}
