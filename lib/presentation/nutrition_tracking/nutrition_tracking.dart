import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/gemini_service.dart';
import '../../services/nutrition_storage_service.dart';
import './widgets/add_food_bottom_sheet.dart';
import './widgets/calorie_progress_widget.dart';
import './widgets/meal_section_widget.dart';
import './widgets/water_tracking_widget.dart';

class NutritionTracking extends StatefulWidget {
  const NutritionTracking({Key? key}) : super(key: key);

  @override
  State<NutritionTracking> createState() => _NutritionTrackingState();
}

class _NutritionTrackingState extends State<NutritionTracking>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final NutritionStorageService _storageService = NutritionStorageService();
  final GeminiService _geminiService = GeminiService();

  int _currentWaterGlasses = 3;
  int _targetWaterGlasses = 8;

  // Daily nutrition targets (will be loaded from storage)
  int _targetCalories = 2000;
  double _targetProtein = 150.0;
  double _targetCarbs = 250.0;
  double _targetFat = 67.0;

  // Real meal data (replacing mock data)
  Map<String, List<Map<String, dynamic>>> _mealData = {
    'Breakfast': [],
    'Lunch': [],
    'Dinner': [],
    'Snacks': [],
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTodayData();
    _loadNutritionGoals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _todayDateKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTodayData() async {
    try {
      final todayData = await _storageService.loadDailyNutrition(_todayDateKey);
      final waterIntake = await _storageService.loadWaterIntake(_todayDateKey);

      setState(() {
        _mealData = todayData;
        _currentWaterGlasses = waterIntake;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNutritionGoals() async {
    try {
      final goals = await _storageService.loadNutritionGoals();
      setState(() {
        _targetCalories = goals['calories'] as int;
        _targetProtein = goals['protein'] as double;
        _targetCarbs = goals['carbs'] as double;
        _targetFat = goals['fat'] as double;
        _targetWaterGlasses = goals['water'] as int;
      });
    } catch (e) {
      // Use default values
    }
  }

  Future<void> _saveTodayData() async {
    await _storageService.saveDailyNutrition(_todayDateKey, _mealData);
    await _storageService.saveWaterIntake(_todayDateKey, _currentWaterGlasses);
  }

  int _calculateTotalCalories() {
    int total = 0;
    _mealData.forEach((mealType, foods) {
      for (var food in foods as List) {
        final foodMap = food as Map<String, dynamic>;
        final calories = foodMap['calories'] as int? ?? 0;
        final quantity = foodMap['quantity'] as int? ?? 1;
        total += calories * quantity;
      }
    });
    return total;
  }

  double _calculateTotalMacro(String macroType) {
    double total = 0.0;
    _mealData.forEach((mealType, foods) {
      for (var food in foods as List) {
        final foodMap = food as Map<String, dynamic>;
        final macro = foodMap[macroType] as double? ?? 0.0;
        final quantity = foodMap['quantity'] as int? ?? 1;
        total += macro * quantity;
      }
    });
    return total;
  }

  void _addFoodToMeal(String mealType, Map<String, dynamic> food) {
    setState(() {
      (_mealData[mealType] as List).add(food);
    });
    _saveTodayData();
  }

  void _removeFoodFromMeal(String mealType, int index) {
    setState(() {
      (_mealData[mealType] as List).removeAt(index);
    });
    _saveTodayData();
  }

  void _updateFoodQuantity(String mealType, int index, int newQuantity) {
    setState(() {
      ((_mealData[mealType] as List)[index]
          as Map<String, dynamic>)['quantity'] = newQuantity;
    });
    _saveTodayData();
  }

  void _showAddFoodBottomSheet(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFoodBottomSheet(
        mealType: mealType,
        onFoodAdded: (food) => _addFoodToMeal(mealType, food),
        geminiService: _geminiService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Nutrition Tracking'),
          leading: IconButton(
            onPressed: () => Navigator.pushNamed(context, '/dashboard-home'),
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 2.h),
              Text('Loading nutrition data...'),
            ],
          ),
        ),
      );
    }

    final consumedCalories = _calculateTotalCalories();
    final consumedProtein = _calculateTotalMacro('protein');
    final consumedCarbs = _calculateTotalMacro('carbs');
    final consumedFat = _calculateTotalMacro('fat');

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Nutrition Tracking'),
        leading: IconButton(
          onPressed: () => Navigator.pushNamed(context, '/dashboard-home'),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/meal-library'),
            icon: CustomIconWidget(
              iconName: 'restaurant_menu',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/user-profile'),
            icon: CustomIconWidget(
              iconName: 'person',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Weekly'),
            Tab(text: 'Goals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayView(
              consumedCalories, consumedProtein, consumedCarbs, consumedFat),
          _buildWeeklyView(),
          _buildGoalsView(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showQuickAddOptions(),
              child: CustomIconWidget(
                iconName: 'add',
                color: Colors.white,
                size: 24,
              ),
            )
          : null,
    );
  }

  Widget _buildTodayView(int consumedCalories, double consumedProtein,
      double consumedCarbs, double consumedFat) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadTodayData();
        await _loadNutritionGoals();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            CalorieProgressWidget(
              consumedCalories: consumedCalories,
              targetCalories: _targetCalories,
              consumedProtein: consumedProtein,
              targetProtein: _targetProtein,
              consumedCarbs: consumedCarbs,
              targetCarbs: _targetCarbs,
              consumedFat: consumedFat,
              targetFat: _targetFat,
            ),
            ..._mealData.keys.map((mealType) => MealSectionWidget(
                  mealType: mealType,
                  foodItems: _mealData[mealType] ?? [],
                  onAddFood: () => _showAddFoodBottomSheet(mealType),
                  onRemoveFood: (index) => _removeFoodFromMeal(mealType, index),
                  onUpdateQuantity: (index, quantity) =>
                      _updateFoodQuantity(mealType, index, quantity),
                )),
            WaterTrackingWidget(
              currentGlasses: _currentWaterGlasses,
              targetGlasses: _targetWaterGlasses,
              onAddGlass: () {
                setState(() => _currentWaterGlasses++);
                _saveTodayData();
              },
              onRemoveGlass: () {
                setState(() => _currentWaterGlasses =
                    (_currentWaterGlasses - 1).clamp(0, _targetWaterGlasses));
                _saveTodayData();
              },
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getWeeklyData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 2.h),
                Text('Loading weekly data...'),
              ],
            ),
          );
        }

        final weeklyData = snapshot.data ?? [];

        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.all(4.w),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
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
                      'Weekly Overview',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      height: 30.h,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: weeklyData.map((data) {
                          final calories = data['calories'] as int;
                          final target = data['target'] as int;
                          final progress = calories / target;
                          final isToday = data['day'] == 'Today';

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '$calories',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isToday
                                      ? AppTheme.lightTheme.primaryColor
                                      : null,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Container(
                                width: 8.w,
                                height: (20.h * progress).clamp(2.h, 20.h),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? AppTheme.lightTheme.primaryColor
                                      : progress > 1.0
                                          ? AppTheme
                                              .lightTheme.colorScheme.error
                                          : AppTheme
                                              .lightTheme.colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                data['day'] as String,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  fontWeight: isToday
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isToday
                                      ? AppTheme.lightTheme.primaryColor
                                      : null,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildWeeklyStatCard(
                            'Avg Calories',
                            '${_calculateWeeklyAverage(weeklyData)}',
                            'kcal/day'),
                        _buildWeeklyStatCard(
                            'Best Day', _getBestDay(weeklyData), ''),
                        _buildWeeklyStatCard('Streak',
                            '${_calculateStreak(weeklyData)}', 'days'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getWeeklyData() async {
    final today = DateTime.now();
    final weeklyData = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final mealData = await _storageService.loadDailyNutrition(dateKey);
      final calories = _calculateCaloriesFromMealData(mealData);

      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = i == 0 ? 'Today' : dayNames[date.weekday - 1];

      weeklyData.add({
        'day': dayName,
        'calories': calories,
        'target': _targetCalories,
        'date': dateKey,
      });
    }

    return weeklyData;
  }

  int _calculateCaloriesFromMealData(
      Map<String, List<Map<String, dynamic>>> mealData) {
    int total = 0;
    mealData.forEach((mealType, foods) {
      for (var food in foods) {
        final calories = food['calories'] as int? ?? 0;
        final quantity = food['quantity'] as int? ?? 1;
        total += calories * quantity;
      }
    });
    return total;
  }

  String _calculateWeeklyAverage(List<Map<String, dynamic>> weeklyData) {
    if (weeklyData.isEmpty) return '0';
    final total =
        weeklyData.fold<int>(0, (sum, data) => sum + (data['calories'] as int));
    return (total / weeklyData.length).round().toString();
  }

  String _getBestDay(List<Map<String, dynamic>> weeklyData) {
    if (weeklyData.isEmpty) return 'None';
    final best = weeklyData.reduce(
        (a, b) => (a['calories'] as int) > (b['calories'] as int) ? a : b);
    return '${best['day']} (${best['calories']} cal)';
  }

  String _calculateStreak(List<Map<String, dynamic>> weeklyData) {
    int streak = 0;
    for (int i = weeklyData.length - 1; i >= 0; i--) {
      final calories = weeklyData[i]['calories'] as int;
      final target = weeklyData[i]['target'] as int;
      if (calories >= target * 0.8) {
        // 80% of target counts as success
        streak++;
      } else {
        break;
      }
    }
    return streak.toString();
  }

  Widget _buildWeeklyStatCard(String title, String value, String subtitle) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(4.w),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
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
                  'Daily Nutrition Goals',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                _buildGoalItem('Calories', _targetCalories, 'kcal',
                    'local_fire_department'),
                _buildGoalItem(
                    'Protein', _targetProtein.toInt(), 'g', 'fitness_center'),
                _buildGoalItem(
                    'Carbohydrates', _targetCarbs.toInt(), 'g', 'grain'),
                _buildGoalItem('Fat', _targetFat.toInt(), 'g', 'opacity'),
                _buildGoalItem(
                    'Water', _targetWaterGlasses, 'glasses', 'local_drink'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String label, int value, String unit, String iconName) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.primaryColor,
            size: 24,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$value $unit',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.primaryColor,
            ),
          ),
          SizedBox(width: 2.w),
          CustomIconWidget(
            iconName: 'edit',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
        ],
      ),
    );
  }

  void _showQuickAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Add Food with AI',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAddOption(
                  'Scan Photo',
                  'camera_alt',
                  () {
                    Navigator.pop(context);
                    _showAddFoodBottomSheet('Breakfast');
                  },
                ),
                _buildQuickAddOption(
                  'Create Meal',
                  'restaurant_menu',
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/meal-builder');
                  },
                ),
                _buildQuickAddOption(
                  'Meal Library',
                  'library_books',
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/meal-library');
                  },
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAddOption(
                  'Scan Barcode',
                  'qr_code_scanner',
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/barcode-scanner');
                  },
                ),
                _buildQuickAddOption(
                  'Manual Add',
                  'edit',
                  () {
                    Navigator.pop(context);
                    _showAddFoodBottomSheet('Breakfast');
                  },
                ),
                SizedBox(width: 20.w), // Spacer to maintain alignment
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddOption(
      String label, String iconName, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: AppTheme.lightTheme.primaryColor,
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
