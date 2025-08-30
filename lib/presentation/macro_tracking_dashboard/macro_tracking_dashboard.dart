import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/app_export.dart';
import './widgets/macro_progress_ring.dart';
import './widgets/meal_macro_breakdown.dart';
import './widgets/macro_goal_adjustment.dart';
import './widgets/weekly_macro_trends.dart';
import './widgets/macro_food_suggestions.dart';

class MacroTrackingDashboard extends StatefulWidget {
  const MacroTrackingDashboard({super.key});

  @override
  State<MacroTrackingDashboard> createState() => _MacroTrackingDashboardState();
}

class _MacroTrackingDashboardState extends State<MacroTrackingDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedMacroGoal = 'maintenance';

  // Daily macro targets with different presets
  final Map<String, Map<String, double>> _macroPresets = {
    'cutting': {
      'calories': 1800,
      'protein': 140,
      'carbs': 135,
      'fat': 60,
    },
    'maintenance': {
      'calories': 2000,
      'protein': 150,
      'carbs': 250,
      'fat': 67,
    },
    'bulking': {
      'calories': 2400,
      'protein': 180,
      'carbs': 300,
      'fat': 80,
    },
  };

  // Mock consumed macro data
  double _consumedProtein = 85.5;
  double _consumedCarbs = 180.2;
  double _consumedFat = 45.8;

  // Mock meal data with macro breakdown
  final Map<String, List<Map<String, dynamic>>> _mealMacros = {
    'Breakfast': [
      {
        'name': 'Greek Yogurt Bowl',
        'protein': 20.0,
        'carbs': 25.0,
        'fat': 8.0,
        'calories': 240,
      },
      {
        'name': 'Granola',
        'protein': 4.5,
        'carbs': 35.0,
        'fat': 12.0,
        'calories': 245,
      },
    ],
    'Lunch': [
      {
        'name': 'Chicken Salad',
        'protein': 35.0,
        'carbs': 15.0,
        'fat': 18.0,
        'calories': 350,
      },
      {
        'name': 'Sweet Potato',
        'protein': 2.0,
        'carbs': 26.0,
        'fat': 0.1,
        'calories': 112,
      },
    ],
    'Dinner': [
      {
        'name': 'Salmon Fillet',
        'protein': 22.0,
        'carbs': 0.0,
        'fat': 13.0,
        'calories': 206,
      },
    ],
    'Snacks': [
      {
        'name': 'Mixed Nuts',
        'protein': 6.0,
        'carbs': 6.0,
        'fat': 15.0,
        'calories': 170,
      },
    ],
  };

  // Weekly macro consistency data
  final List<Map<String, dynamic>> _weeklyMacroData = [
    {'day': 'Mon', 'protein': 145, 'carbs': 230, 'fat': 65},
    {'day': 'Tue', 'protein': 160, 'carbs': 245, 'fat': 70},
    {'day': 'Wed', 'protein': 138, 'carbs': 220, 'fat': 62},
    {'day': 'Thu', 'protein': 155, 'carbs': 265, 'fat': 75},
    {'day': 'Fri', 'protein': 142, 'carbs': 210, 'fat': 58},
    {'day': 'Sat', 'protein': 170, 'carbs': 280, 'fat': 80},
    {'day': 'Sun', 'protein': 85.5, 'carbs': 180.2, 'fat': 45.8},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, double> get _currentTargets => _macroPresets[_selectedMacroGoal]!;

  double get _consumedCalories {
    double total = 0;
    for (var meals in _mealMacros.values) {
      for (var meal in meals) {
        total += meal['calories'];
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Macro Tracking'),
        leading: IconButton(
          onPressed: () => Navigator.pushNamed(context, '/nutrition-tracking'),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showMacroGoalAdjustment(),
            icon: CustomIconWidget(
              iconName: 'tune',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildMacroHeader(),
              _buildCalorieDistributionChart(),
              _buildMealMacroBreakdown(),
              _buildWeeklyTrends(),
              _buildAchievementBadges(),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMacroFoodSuggestions(),
        child: CustomIconWidget(
          iconName: 'restaurant_menu',
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildMacroHeader() {
    return Container(
      margin: EdgeInsets.all(4.w),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Macro Targets',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedMacroGoal.toUpperCase(),
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MacroProgressRing(
                label: 'Protein',
                consumed: _consumedProtein,
                target: _currentTargets['protein']!,
                unit: 'g',
                color: const Color(0xFF6BCF7F),
                animationController: _animationController,
              ),
              MacroProgressRing(
                label: 'Carbs',
                consumed: _consumedCarbs,
                target: _currentTargets['carbs']!,
                unit: 'g',
                color: const Color(0xFF4A90E2),
                animationController: _animationController,
              ),
              MacroProgressRing(
                label: 'Fat',
                consumed: _consumedFat,
                target: _currentTargets['fat']!,
                unit: 'g',
                color: const Color(0xFFF5A623),
                animationController: _animationController,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieDistributionChart() {
    return Container(
      margin: EdgeInsets.all(4.w),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calorie Distribution',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => _showDetailedMacroRatios(),
                child: CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 25.w,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 8.w,
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF6BCF7F),
                          value: _consumedProtein * 4,
                          title:
                              '${((_consumedProtein * 4) / _consumedCalories * 100).round()}%',
                          radius: 6.w,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFF4A90E2),
                          value: _consumedCarbs * 4,
                          title:
                              '${((_consumedCarbs * 4) / _consumedCalories * 100).round()}%',
                          radius: 6.w,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFF5A623),
                          value: _consumedFat * 9,
                          title:
                              '${((_consumedFat * 9) / _consumedCalories * 100).round()}%',
                          radius: 6.w,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMacroLegendItem(
                        'Protein',
                        '${(_consumedProtein * 4).round()} kcal',
                        const Color(0xFF6BCF7F)),
                    SizedBox(height: 1.h),
                    _buildMacroLegendItem(
                        'Carbs',
                        '${(_consumedCarbs * 4).round()} kcal',
                        const Color(0xFF4A90E2)),
                    SizedBox(height: 1.h),
                    _buildMacroLegendItem(
                        'Fat',
                        '${(_consumedFat * 9).round()} kcal',
                        const Color(0xFFF5A623)),
                    SizedBox(height: 2.h),
                    Text(
                      'Total: ${_consumedCalories.round()} kcal',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMealMacroBreakdown() {
    return MealMacroBreakdown(
      mealData: _mealMacros,
      onMealTap: (mealName) => _showMealDetails(mealName),
    );
  }

  Widget _buildWeeklyTrends() {
    return WeeklyMacroTrends(
      weeklyData: _weeklyMacroData,
      targets: _currentTargets,
    );
  }

  Widget _buildAchievementBadges() {
    return Container(
      margin: EdgeInsets.all(4.w),
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
            'This Week\'s Achievements',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAchievementBadge(
                'Protein\nTarget',
                '5/7',
                const Color(0xFF6BCF7F),
                'fitness_center',
              ),
              _buildAchievementBadge(
                'Balanced\nMacros',
                '4/7',
                const Color(0xFF4A90E2),
                'balance',
              ),
              _buildAchievementBadge(
                'Consistency',
                '7/7',
                const Color(0xFFF5A623),
                'trending_up',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(
      String title, String progress, Color color, String iconName) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 28,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          progress,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showMacroGoalAdjustment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MacroGoalAdjustment(
        currentGoal: _selectedMacroGoal,
        macroPresets: _macroPresets,
        onGoalChanged: (newGoal) {
          setState(() {
            _selectedMacroGoal = newGoal;
          });
        },
      ),
    );
  }

  void _showMacroFoodSuggestions() {
    final remainingProtein = _currentTargets['protein']! - _consumedProtein;
    final remainingCarbs = _currentTargets['carbs']! - _consumedCarbs;
    final remainingFat = _currentTargets['fat']! - _consumedFat;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MacroFoodSuggestions(
        remainingProtein: remainingProtein,
        remainingCarbs: remainingCarbs,
        remainingFat: remainingFat,
      ),
    );
  }

  void _showDetailedMacroRatios() {
    final proteinPercentage =
        ((_consumedProtein * 4) / _consumedCalories * 100).round();
    final carbsPercentage =
        ((_consumedCarbs * 4) / _consumedCalories * 100).round();
    final fatPercentage =
        ((_consumedFat * 9) / _consumedCalories * 100).round();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Macro Ratio Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Protein', '$proteinPercentage%',
                '${_currentTargets["protein"]!.round()}g target'),
            _buildDetailRow('Carbohydrates', '$carbsPercentage%',
                '${_currentTargets["carbs"]!.round()}g target'),
            _buildDetailRow('Fat', '$fatPercentage%',
                '${_currentTargets["fat"]!.round()}g target'),
            SizedBox(height: 2.h),
            Text(
              'Recommended ratios for $_selectedMacroGoal: 30% protein, 40% carbs, 30% fat',
              style: AppTheme.lightTheme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String percentage, String target) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.lightTheme.textTheme.bodyMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(percentage,
                  style: AppTheme.lightTheme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(target, style: AppTheme.lightTheme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  void _showMealDetails(String mealName) {
    final mealItems = _mealMacros[mealName] ?? [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$mealName Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: mealItems
              .map((item) => ListTile(
                    title: Text(item['name']),
                    subtitle: Text(
                        '${item['calories']} kcal • P: ${item['protein']}g • C: ${item['carbs']}g • F: ${item['fat']}g'),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
