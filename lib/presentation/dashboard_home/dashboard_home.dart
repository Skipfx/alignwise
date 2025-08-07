import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/activity_feed_card.dart';
import './widgets/bottom_tab_navigation.dart';
import './widgets/daily_progress_ring.dart';
import './widgets/metric_card.dart';
import './widgets/quick_action_button.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome>
    with TickerProviderStateMixin {
  late AnimationController _greetingAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _greetingAnimation;
  late Animation<double> _cardAnimation;

  int _selectedTabIndex = 0;
  final _supabaseService = SupabaseService.instance;
  DateTime _selectedDate = DateTime.now();
  bool _isRefreshing = false;
  
  // Mock dashboard data
  final Map<String, dynamic> _dashboardData = {
    "wellnessScore": 78.0,
    "todayMetrics": {
      "calories": {"consumed": 1520, "goal": 2000},
      "steps": {"taken": 8247},
      "water": {"consumed": 6, "goal": 8},
      "mindfulness": {"minutes": 15}
    },
    "recentActivities": <Map<String, dynamic>>[]
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthState();
  }

  void _checkAuthState() {
    if (!_supabaseService.isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/authentication-screen');
      });
    }
  }

  void _initializeAnimations() {
    _greetingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _greetingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _greetingAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _greetingAnimationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _greetingAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    try {
      await _supabaseService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/authentication-screen');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getUserName() {
    final user = _supabaseService.currentUser;
    if (user?.userMetadata?['full_name'] != null) {
      return user!.userMetadata!['full_name'];
    }
    return user?.email
            ?.split('@')
            .first
            .split('.')
            .map((e) => e[0].toUpperCase() + e.substring(1))
            .join(' ') ??
        'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Sign Out Button
            Padding(
              padding: EdgeInsets.fromLTRB(6.w, 3.h, 6.w, 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FadeTransition(
                    opacity: _greetingAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _getUserName(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color:
                                    AppTheme.lightTheme.colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                    onSelected: (value) {
                      if (value == 'sign_out') {
                        _handleSignOut();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'sign_out',
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              size: 20,
                              color: AppTheme.lightTheme.colorScheme.error,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                color: AppTheme.lightTheme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Main Content
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 2.h),
                  _buildHeroSection(),
                  SizedBox(height: 3.h),
                  _buildMetricsSection(),
                  SizedBox(height: 3.h),
                  _buildActivityFeed(),
                  SizedBox(height: 12.h), // Bottom navigation space
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildQuickActions(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomTabNavigation(
        currentIndex: _selectedTabIndex,
        onTap: (index) => setState(() => _selectedTabIndex = index),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Date Picker
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'calendar_today',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  _formatSelectedDate(),
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 1.w),
                CustomIconWidget(
                  iconName: 'keyboard_arrow_down',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 4.w,
                ),
              ],
            ),
          ),
        ),
        // Notification Bell
        GestureDetector(
          onTap: () {
            // Handle notification tap
          },
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
            child: Stack(
              children: [
                CustomIconWidget(
                  iconName: 'notifications_outlined',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 6.w,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 2.w,
                    height: 2.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          Text(
            'Good ${_getGreeting()}, Sarah!',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Here\'s your wellness overview for today',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          DailyProgressRing(
            wellnessScore: (_dashboardData["wellnessScore"] as double),
            onTap: _showWellnessDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    final metrics = _dashboardData["todayMetrics"] as Map<String, dynamic>;

    return Container(
      height: 25.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        children: [
          MetricCard(
            title: 'Calories',
            value: '${(metrics["calories"] as Map)["consumed"]}',
            unit: '/${(metrics["calories"] as Map)["goal"]}',
            iconName: 'local_fire_department',
            iconColor: AppTheme.lightTheme.colorScheme.error,
            onTap: () => Navigator.pushNamed(context, '/nutrition-tracking'),
          ),
          SizedBox(width: 3.w),
          MetricCard(
            title: 'Steps',
            value: '${(metrics["steps"] as Map)["taken"]}',
            unit: 'steps',
            iconName: 'directions_walk',
            iconColor: AppTheme.lightTheme.colorScheme.secondary,
            onTap: () => Navigator.pushNamed(context, '/fitness-tracking'),
          ),
          SizedBox(width: 3.w),
          MetricCard(
            title: 'Water',
            value: '${(metrics["water"] as Map)["consumed"]}',
            unit: '/${(metrics["water"] as Map)["goal"]} glasses',
            iconName: 'local_drink',
            iconColor: AppTheme.lightTheme.colorScheme.tertiary,
            onTap: () => _showWaterTracker(),
          ),
          SizedBox(width: 3.w),
          MetricCard(
            title: 'Mindfulness',
            value: '${(metrics["mindfulness"] as Map)["minutes"]}',
            unit: 'min',
            iconName: 'self_improvement',
            iconColor: AppTheme.lightTheme.colorScheme.primary,
            onTap: () => Navigator.pushNamed(context, '/mindfulness-hub'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    final activities = _dashboardData["recentActivities"] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Handle view all
                },
                child: Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        activities.isEmpty
            ? _buildEmptyState()
            : Column(
                children:
                    (activities as List<Map<String, dynamic>>).map((activity) {
                  return ActivityFeedCard(
                    type: activity["type"] as String,
                    title: activity["title"] as String,
                    description: activity["description"] as String,
                    imageUrl: activity["imageUrl"] as String?,
                    iconName: activity["iconName"] as String,
                    iconColor:
                        Color(int.parse(activity["iconColor"] as String)),
                    timestamp: DateTime.parse(activity["timestamp"] as String),
                    onTap: () => _handleActivityTap(activity),
                    onDismiss: () => _handleActivityDismiss(activity),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(8.w),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'timeline',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 15.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Start Your Wellness Journey',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'Log your first meal, complete a workout, or try a meditation to see your activity here.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/nutrition-tracking'),
            child: Text('Log Your First Meal'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QuickActionButton(
          iconName: 'camera_alt',
          backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
          tooltip: 'Log Meal',
          onPressed: () => Navigator.pushNamed(context, '/barcode-scanner'),
        ),
        SizedBox(height: 2.h),
        QuickActionButton(
          iconName: 'play_arrow',
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          tooltip: 'Start Workout',
          onPressed: () => Navigator.pushNamed(context, '/workout-session'),
        ),
        SizedBox(height: 2.h),
        QuickActionButton(
          iconName: 'self_improvement',
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          tooltip: 'Begin Meditation',
          onPressed: () => Navigator.pushNamed(context, '/meditation-session'),
        ),
      ],
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isRefreshing = false);
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppTheme.lightTheme.colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showWellnessDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 60.h,
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Wellness Score Breakdown',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3.h),
            Expanded(
              child: ListView(
                children: [
                  _buildScoreItem('Nutrition', 85,
                      AppTheme.lightTheme.colorScheme.secondary),
                  _buildScoreItem(
                      'Fitness', 75, AppTheme.lightTheme.colorScheme.error),
                  _buildScoreItem('Mindfulness', 70,
                      AppTheme.lightTheme.colorScheme.tertiary),
                  _buildScoreItem(
                      'Sleep', 80, AppTheme.lightTheme.colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String category, int score, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            '$score%',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showWaterTracker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Water Intake'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Track your daily water intake'),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Add water logic
                  },
                  child: Text('+1 Glass'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleActivityTap(Map<String, dynamic> activity) {
    final type = activity["type"] as String;
    switch (type) {
      case 'recommendation':
        Navigator.pushNamed(context, '/nutrition-tracking');
        break;
      case 'challenge':
        Navigator.pushNamed(context, '/challenges-hub');
        break;
      case 'workout':
        Navigator.pushNamed(context, '/fitness-tracking');
        break;
      case 'mindfulness':
        Navigator.pushNamed(context, '/mindfulness-hub');
        break;
      default:
        break;
    }
  }

  void _handleActivityDismiss(Map<String, dynamic> activity) {
    setState(() {
      (_dashboardData["recentActivities"] as List).remove(activity);
    });
  }

  String _formatSelectedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) return 'Yesterday';

    return '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}';
  }
}