import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/gemini_service.dart';
import '../../services/meal_storage_service.dart';
import './widgets/category_filter_widget.dart';
import './widgets/meal_card_widget.dart';
import './widgets/meal_search_widget.dart';

class MealLibrary extends StatefulWidget {
  const MealLibrary({Key? key}) : super(key: key);

  @override
  State<MealLibrary> createState() => _MealLibraryState();
}

class _MealLibraryState extends State<MealLibrary> {
  final MealStorageService _mealStorageService = MealStorageService();
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allMeals = [];
  List<Map<String, dynamic>> _filteredMeals = [];
  List<Map<String, dynamic>> _selectedMeals = [];
  String _selectedCategory = 'All';
  String _selectedSort = 'Recent';
  bool _isGridView = true;
  bool _isMultiSelectMode = false;
  bool _isLoading = true;

  final List<String> _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack'
  ];
  final List<String> _sortOptions = [
    'Recent',
    'Alphabetical',
    'Calories',
    'Prep Time'
  ];

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeals() async {
    try {
      final meals = await _mealStorageService.getSavedMeals();
      setState(() {
        _allMeals = meals;
        _filteredMeals = meals;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _searchMeals(String query) {
    if (query.isEmpty) {
      setState(() => _filteredMeals = _allMeals);
    } else {
      setState(() {
        _filteredMeals = _allMeals.where((meal) {
          final name = (meal['name'] as String? ?? '').toLowerCase();
          final description =
              (meal['description'] as String? ?? '').toLowerCase();
          final tags = (meal['tags'] as List? ?? []).join(' ').toLowerCase();

          return name.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase()) ||
              tags.contains(query.toLowerCase());
        }).toList();
      });
    }
    _applyFilters();
  }

  void _filterByCategory(String category) {
    setState(() => _selectedCategory = category);
    _applyFilters();
  }

  void _sortMeals(String sortType) {
    setState(() => _selectedSort = sortType);
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_filteredMeals);

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((meal) {
        final mealType = meal['meal_type'] as String? ?? '';
        return mealType.toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'Alphabetical':
        filtered.sort((a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
        break;
      case 'Calories':
        filtered.sort((a, b) {
          final aCalories = (a['nutrition'] as Map?)?['calories'] as int? ?? 0;
          final bCalories = (b['nutrition'] as Map?)?['calories'] as int? ?? 0;
          return bCalories.compareTo(aCalories);
        });
        break;
      case 'Prep Time':
        filtered.sort((a, b) {
          final aPrepTime = a['prep_time'] as int? ?? 0;
          final bPrepTime = b['prep_time'] as int? ?? 0;
          return aPrepTime.compareTo(bPrepTime);
        });
        break;
      case 'Recent':
      default:
        filtered.sort((a, b) {
          final aCreated =
              DateTime.tryParse(a['created_at'] as String? ?? '') ??
                  DateTime.now();
          final bCreated =
              DateTime.tryParse(b['created_at'] as String? ?? '') ??
                  DateTime.now();
          return bCreated.compareTo(aCreated);
        });
        break;
    }

    setState(() => _filteredMeals = filtered);
  }

  void _toggleViewMode() {
    setState(() => _isGridView = !_isGridView);
  }

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedMeals.clear();
      }
    });
  }

  void _toggleMealSelection(Map<String, dynamic> meal) {
    setState(() {
      if (_selectedMeals.any((m) => m['id'] == meal['id'])) {
        _selectedMeals.removeWhere((m) => m['id'] == meal['id']);
      } else {
        _selectedMeals.add(meal);
      }
    });
  }

  Future<void> _deleteMeal(String mealId) async {
    try {
      await _mealStorageService.deleteMeal(mealId);
      await _loadMeals();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal deleted successfully'),
          backgroundColor: AppTheme.lightTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete meal'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _duplicateMeal(Map<String, dynamic> meal) async {
    try {
      final duplicatedMeal = Map<String, dynamic>.from(meal);
      duplicatedMeal.remove('id');
      duplicatedMeal['name'] = '${meal['name']} (Copy)';
      duplicatedMeal['created_at'] = DateTime.now().toIso8601String();

      await _mealStorageService.saveMeal(duplicatedMeal);
      await _loadMeals();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal duplicated successfully'),
          backgroundColor: AppTheme.lightTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to duplicate meal'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _logMeal(Map<String, dynamic> meal, String mealType) async {
    try {
      await _mealStorageService.logMeal(meal, mealType);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal logged to $mealType'),
          backgroundColor: AppTheme.lightTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log meal'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }

  void _showMealLogOptions(Map<String, dynamic> meal) {
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
            Text(
              'Log "${meal['name']}" to:',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ...['Breakfast', 'Lunch', 'Dinner', 'Snacks'].map(
              (mealType) => ListTile(
                leading: CustomIconWidget(
                  iconName: _getMealTypeIcon(mealType),
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                title: Text(mealType),
                onTap: () {
                  Navigator.pop(context);
                  _logMeal(meal, mealType);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMealTypeIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'wb_sunny';
      case 'lunch':
        return 'wb_cloudy';
      case 'dinner':
        return 'nights_stay';
      case 'snacks':
        return 'local_cafe';
      default:
        return 'restaurant';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Meal Library'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleViewMode,
            icon: CustomIconWidget(
              iconName: _isGridView ? 'view_list' : 'view_module',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: _toggleMultiSelect,
            icon: CustomIconWidget(
              iconName: _isMultiSelectMode ? 'close' : 'check_box',
              color: _isMultiSelectMode
                  ? AppTheme.lightTheme.colorScheme.error
                  : AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 2.h),
                  Text('Loading your meal library...'),
                ],
              ),
            )
          : Column(
              children: [
                MealSearchWidget(
                  searchController: _searchController,
                  onSearchChanged: _searchMeals,
                ),
                CategoryFilterWidget(
                  categories: _categories,
                  sortOptions: _sortOptions,
                  selectedCategory: _selectedCategory,
                  selectedSort: _selectedSort,
                  onCategorySelected: _filterByCategory,
                  onSortSelected: _sortMeals,
                ),
                Expanded(
                  child: _filteredMeals.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'restaurant_menu',
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                size: 48,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _allMeals.isEmpty
                                    ? 'No meals in your library yet'
                                    : 'No meals match your search',
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              if (_allMeals.isEmpty)
                                Text(
                                  'Create your first meal!',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : _isGridView
                          ? _buildGridView()
                          : _buildListView(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/meal-builder')
            .then((_) => _loadMeals()),
        icon: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
        label: Text('Create Meal'),
      ),
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 3.w,
          childAspectRatio: 0.75,
        ),
        itemCount: _filteredMeals.length,
        itemBuilder: (context, index) {
          final meal = _filteredMeals[index];
          final isSelected = _selectedMeals.any((m) => m['id'] == meal['id']);

          return MealCardWidget(
            meal: meal,
            isGridView: true,
            isMultiSelectMode: _isMultiSelectMode,
            isSelected: isSelected,
            onTap: _isMultiSelectMode
                ? () => _toggleMealSelection(meal)
                : () => _showMealLogOptions(meal),
            onLongPress: () {
              if (!_isMultiSelectMode) {
                _toggleMultiSelect();
              }
              _toggleMealSelection(meal);
            },
            onDelete: () => _deleteMeal(meal['id']),
            onDuplicate: () => _duplicateMeal(meal),
            onLog: () => _showMealLogOptions(meal),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: _filteredMeals.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final meal = _filteredMeals[index];
        final isSelected = _selectedMeals.any((m) => m['id'] == meal['id']);

        return MealCardWidget(
          meal: meal,
          isGridView: false,
          isMultiSelectMode: _isMultiSelectMode,
          isSelected: isSelected,
          onTap: _isMultiSelectMode
              ? () => _toggleMealSelection(meal)
              : () => _showMealLogOptions(meal),
          onLongPress: () {
            if (!_isMultiSelectMode) {
              _toggleMultiSelect();
            }
            _toggleMealSelection(meal);
          },
          onDelete: () => _deleteMeal(meal['id']),
          onDuplicate: () => _duplicateMeal(meal),
          onLog: () => _showMealLogOptions(meal),
        );
      },
    );
  }
}
