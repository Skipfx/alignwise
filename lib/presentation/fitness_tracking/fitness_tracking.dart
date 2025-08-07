import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/activity_metrics_card.dart';
import './widgets/fitness_program_card.dart';
import './widgets/quick_workout_button.dart';
import './widgets/recent_workout_card.dart';
import './widgets/workout_creation_modal.dart';

class FitnessTracking extends StatefulWidget {
  const FitnessTracking({Key? key}) : super(key: key);

  @override
  State<FitnessTracking> createState() => _FitnessTrackingState();
}

class _FitnessTrackingState extends State<FitnessTracking>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  // Mock data for activity metrics
  final List<Map<String, dynamic>> _activityMetrics = [
    {
      'title': 'Steps',
      'value': '8,247',
      'unit': 'steps',
      'progress': 0.68,
      'color': AppTheme.lightTheme.colorScheme.primary,
      'icon': 'directions_walk',
    },
    {
      'title': 'Distance',
      'value': '5.2',
      'unit': 'km',
      'progress': 0.52,
      'color': const Color(0xFFE76F51),
      'icon': 'straighten',
    },
    {
      'title': 'Calories',
      'value': '420',
      'unit': 'kcal',
      'progress': 0.84,
      'color': const Color(0xFFFF4D4F),
      'icon': 'local_fire_department',
    },
    {
      'title': 'Active Time',
      'value': '45',
      'unit': 'min',
      'progress': 0.75,
      'color': const Color(0xFF52C41A),
      'icon': 'timer',
    },
  ];

  // Mock data for quick workouts
  final List<Map<String, dynamic>> _quickWorkouts = [
    {
      'type': 'HIIT',
      'duration': '15 min',
      'difficulty': 'High',
      'icon': 'local_fire_department',
      'color': const Color(0xFFFF4D4F),
    },
    {
      'type': 'Strength',
      'duration': '30 min',
      'difficulty': 'Medium',
      'icon': 'fitness_center',
      'color': AppTheme.lightTheme.colorScheme.primary,
    },
    {
      'type': 'Cardio',
      'duration': '20 min',
      'difficulty': 'Low',
      'icon': 'directions_run',
      'color': const Color(0xFFE76F51),
    },
    {
      'type': 'Yoga',
      'duration': '25 min',
      'difficulty': 'Low',
      'icon': 'self_improvement',
      'color': const Color(0xFF8B5CF6),
    },
  ];

  // Mock data for recent workouts
  final List<Map<String, dynamic>> _recentWorkouts = [
    {
      'type': 'Morning HIIT',
      'date': 'Today, 7:30 AM',
      'duration': '18 min',
      'calories': '245 kcal',
      'intensity': 'High',
      'icon': 'local_fire_department',
      'color': const Color(0xFFFF4D4F),
    },
    {
      'type': 'Upper Body Strength',
      'date': 'Yesterday, 6:00 PM',
      'duration': '35 min',
      'calories': '180 kcal',
      'intensity': 'Medium',
      'icon': 'fitness_center',
      'color': AppTheme.lightTheme.colorScheme.primary,
    },
    {
      'type': 'Evening Yoga',
      'date': 'Aug 4, 8:00 PM',
      'duration': '30 min',
      'calories': '95 kcal',
      'intensity': 'Low',
      'icon': 'self_improvement',
      'color': const Color(0xFF8B5CF6),
    },
  ];

  // Mock data for fitness programs
  final List<Map<String, dynamic>> _fitnessPrograms = [
    {
      'name': '30-Day Strength Builder',
      'description':
          'Build muscle and increase strength with progressive resistance training designed for all fitness levels.',
      'level': 'Intermediate',
      'duration': 45,
      'equipment': 'Weights',
      'difficulty': 'Medium',
      'totalDays': 30,
      'completedDays': 12,
      'color': AppTheme.lightTheme.colorScheme.primary,
      'image':
          'https://images.pexels.com/photos/1552242/pexels-photo-1552242.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    },
    {
      'name': 'HIIT Fat Burner',
      'description':
          'High-intensity interval training program to maximize calorie burn and improve cardiovascular fitness.',
      'level': 'Advanced',
      'duration': 20,
      'equipment': 'Bodyweight',
      'difficulty': 'High',
      'totalDays': 21,
      'completedDays': 7,
      'color': const Color(0xFFFF4D4F),
      'image':
          'https://images.pexels.com/photos/4162449/pexels-photo-4162449.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    },
    {
      'name': 'Flexibility & Mobility',
      'description':
          'Improve your range of motion and reduce muscle tension with daily stretching and mobility exercises.',
      'level': 'Beginner',
      'duration': 25,
      'equipment': 'Mat',
      'difficulty': 'Low',
      'totalDays': 14,
      'completedDays': 14,
      'color': const Color(0xFF52C41A),
      'image':
          'https://images.pexels.com/photos/3822906/pexels-photo-3822906.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isRefreshing = false);
  }

  void _startWorkout(String workoutType) {
    Navigator.pushNamed(context, '/workout-session');
  }

  void _repeatWorkout(Map<String, dynamic> workout) {
    Navigator.pushNamed(context, '/workout-session');
  }

  void _shareWorkout(Map<String, dynamic> workout) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${workout['type']} workout...'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  void _openProgram(Map<String, dynamic> program) {
    Navigator.pushNamed(context, '/workout-session');
  }

  void _showWorkoutCreationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutCreationModal(
        onWorkoutCreated: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Custom workout created successfully!'),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Fitness Tracking',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/user-profile'),
            child: Container(
              margin: EdgeInsets.only(right: 4.w),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'person',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Workouts'),
            Tab(text: 'Programs'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTodayView(),
            _buildWorkoutsView(),
            _buildProgramsView(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showWorkoutCreationModal,
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        child: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildTodayView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Activity Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.lightTheme.colorScheme.primary,
                  AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'today',
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Today\'s Activity',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (_isRefreshing)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Keep moving! You\'re 68% towards your daily step goal.',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Activity Metrics Grid
          Wrap(
            spacing: 3.w,
            runSpacing: 3.w,
            children: _activityMetrics
                .map((metric) => ActivityMetricsCard(
                      title: metric['title'] as String,
                      value: metric['value'] as String,
                      unit: metric['unit'] as String,
                      progress: metric['progress'] as double,
                      progressColor: metric['color'] as Color,
                      icon: metric['icon'] as String,
                    ))
                .toList(),
          ),

          SizedBox(height: 4.h),

          // Quick Start Section
          Row(
            children: [
              Text(
                'Quick Start',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _tabController.animateTo(1),
                child: Text(
                  'View All',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          Wrap(
            spacing: 3.w,
            runSpacing: 3.w,
            children: _quickWorkouts
                .map((workout) => QuickWorkoutButton(
                      workoutType: workout['type'] as String,
                      duration: workout['duration'] as String,
                      difficulty: workout['difficulty'] as String,
                      icon: workout['icon'] as String,
                      color: workout['color'] as Color,
                      onTap: () => _startWorkout(workout['type'] as String),
                    ))
                .toList(),
          ),

          SizedBox(height: 4.h),

          // Heart Rate Zone (if available)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'favorite',
                      color: const Color(0xFFFF4D4F),
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Heart Rate Zone',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '142 BPM',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF4D4F),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                LinearProgressIndicator(
                  value: 0.7,
                  backgroundColor:
                      const Color(0xFFFF4D4F).withValues(alpha: 0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFFF4D4F)),
                  minHeight: 6,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Fat Burn Zone (70% of max HR)',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildWorkoutsView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Workouts Header
          Row(
            children: [
              Text(
                'Recent Workouts',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showWorkoutCreationModal,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'add',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Create',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Recent Workouts List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentWorkouts.length,
            itemBuilder: (context, index) {
              final workout = _recentWorkouts[index];
              return RecentWorkoutCard(
                workout: workout,
                onTap: () => Navigator.pushNamed(context, '/workout-session'),
                onRepeat: () => _repeatWorkout(workout),
                onShare: () => _shareWorkout(workout),
              );
            },
          ),

          SizedBox(height: 4.h),

          // Workout Stats
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week\'s Summary',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildWeeklyStatItem(
                        'Workouts',
                        '5',
                        'fitness_center',
                        AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildWeeklyStatItem(
                        'Total Time',
                        '2h 15m',
                        'timer',
                        const Color(0xFFE76F51),
                      ),
                    ),
                    Expanded(
                      child: _buildWeeklyStatItem(
                        'Calories',
                        '1,240',
                        'local_fire_department',
                        const Color(0xFFFF4D4F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildProgramsView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Programs Header
          Text(
            'Fitness Programs',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Structured workout plans with adaptive difficulty',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),

          SizedBox(height: 4.h),

          // Programs List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _fitnessPrograms.length,
            itemBuilder: (context, index) {
              final program = _fitnessPrograms[index];
              return FitnessProgramCard(
                program: program,
                onTap: () => _openProgram(program),
              );
            },
          ),

          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatItem(
      String title, String value, String icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomIconWidget(
            iconName: icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
