import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/wellness_service.dart';
import './widgets/add_food_bottom_sheet.dart';
import './widgets/calorie_progress_widget.dart';
import './widgets/meal_section_widget.dart';
import './widgets/water_tracking_widget.dart';

class NutritionTracking extends StatefulWidget {
  const NutritionTracking({super.key});

  @override
  State<NutritionTracking> createState() => _NutritionTrackingState();
}

class _NutritionTrackingState extends State<NutritionTracking>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final WellnessService _wellnessService = WellnessService();

  int _currentWaterGlasses = 0;
  int _targetWaterGlasses = 8;

  // Daily nutrition targets (loaded from Supabase)
  int _targetCalories = 2000;
  double _targetProtein = 150.0;
  double _targetCarbs = 250.0;
  double _targetFat = 67.0;

  // Real meal data from Supabase
  List<Map<String, dynamic>> _todayMeals = [];

  bool _isLoading = true;
  String? _error;

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

  Future<void> _loadTodayData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load meals from Supabase
      final meals = await _wellnessService.getMealsForToday();

      // Load water intake from Supabase
      final waterIntakeMl = await _wellnessService.getDailyWaterIntake();

      setState(() {
        _todayMeals = meals;
        _currentWaterGlasses =
            (waterIntakeMl / 250).round(); // Convert ml to glasses
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNutritionGoals() async {
    try {
      final goals = await _wellnessService.getUserGoals();
      setState(() {
        _targetCalories = goals['target_calories'] ?? 2000;
        _targetProtein = (goals['target_protein'] ?? 150.0).toDouble();
        _targetCarbs = (goals['target_carbs'] ?? 250.0).toDouble();
        _targetFat = (goals['target_fat'] ?? 67.0).toDouble();
        _targetWaterGlasses =
            ((goals['target_water_ml'] ?? 2000) / 250).round();
      });
        } catch (e) {
      // Use default values on error
      debugPrint('Error loading nutrition goals: $e');
    }
  }

  Map<String, List<Map<String, dynamic>>> _organizeMealsByType() {
    final organizedMeals = <String, List<Map<String, dynamic>>>{
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snacks': [],
    };

    for (final meal in _todayMeals) {
      final mealType = meal['meal_type'] as String? ?? 'Snacks';
      final capitalizedType = mealType[0].toUpperCase() + mealType.substring(1);

      if (organizedMeals.containsKey(capitalizedType)) {
        organizedMeals[capitalizedType]!.add(meal);
      } else {
        organizedMeals['Snacks']!.add(meal);
      }
    }

    return organizedMeals;
  }

  int _calculateTotalCalories() {
    return _todayMeals.fold<int>(0, (sum, meal) {
      return sum + ((meal['calories'] as int?) ?? 0);
    });
  }

  double _calculateTotalMacro(String macroType) {
    return _todayMeals.fold<double>(0.0, (sum, meal) {
      return sum + ((meal[macroType] as double?) ?? 0.0);
    });
  }

  void _addFoodToMeal(String mealType, Map<String, dynamic> food) async {
    try {
      await _wellnessService.logMeal(
        mealType: mealType.toLowerCase(),
        name: food['name'] ?? 'Unknown Food',
        calories: food['calories'] ?? 0,
        protein: (food['protein'] ?? 0.0).toDouble(),
        carbs: (food['carbs'] ?? 0.0).toDouble(),
        fat: (food['fat'] ?? 0.0).toDouble(),
      );

      // Reload data to reflect changes
      await _loadTodayData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding meal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddFoodBottomSheet(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFoodBottomSheet(
        mealType: mealType,
        onFoodAdded: (food) => _addFoodToMeal(mealType, food),
      ),
    );
  }

  Future<void> _logWaterIntake() async {
    try {
      await _wellnessService.logWater(250); // 250ml = 1 glass
      await _loadTodayData(); // Reload to update UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging water: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              Text('Loading nutrition data from Supabase...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
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
              CustomIconWidget(
                iconName: 'error',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 48,
              ),
              SizedBox(height: 2.h),
              Text('Error loading data: $_error'),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: _loadTodayData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final consumedCalories = _calculateTotalCalories();
    final consumedProtein = _calculateTotalMacro('protein');
    final consumedCarbs = _calculateTotalMacro('carbs');
    final consumedFat = _calculateTotalMacro('fat');
    final organizedMeals = _organizeMealsByType();

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
          _buildTodayView(consumedCalories, consumedProtein, consumedCarbs,
              consumedFat, organizedMeals),
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

  Widget _buildTodayView(
      int consumedCalories,
      double consumedProtein,
      double consumedCarbs,
      double consumedFat,
      Map<String, List<Map<String, dynamic>>> organizedMeals) {
    return RefreshIndicator(
      onRefresh: _loadTodayData,
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
            ...organizedMeals.keys.map((mealType) => MealSectionWidget(
                  mealType: mealType,
                  foodItems: organizedMeals[mealType] ?? [],
                  onAddFood: () => _showAddFoodBottomSheet(mealType),
                  onRemoveFood:
                      (index) {}, // TODO: Implement delete from Supabase
                  onUpdateQuantity: (index,
                      quantity) {}, // TODO: Implement update in Supabase
                )),
            WaterTrackingWidget(
              currentGlasses: _currentWaterGlasses,
              targetGlasses: _targetWaterGlasses,
              onAddGlass: _logWaterIntake,
              onRemoveGlass: () {
                // TODO: Implement water removal if needed
              },
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'trending_up',
            color: AppTheme.lightTheme.primaryColor,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'Weekly Analytics',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Coming soon - View your weekly nutrition trends',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
