import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WorkoutCreationModal extends StatefulWidget {
  final VoidCallback onWorkoutCreated;

  const WorkoutCreationModal({
    Key? key,
    required this.onWorkoutCreated,
  }) : super(key: key);

  @override
  State<WorkoutCreationModal> createState() => _WorkoutCreationModalState();
}

class _WorkoutCreationModalState extends State<WorkoutCreationModal> {
  final TextEditingController _workoutNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _selectedExercises = [];

  final List<String> _categories = [
    'All',
    'Strength',
    'Cardio',
    'HIIT',
    'Yoga',
    'Flexibility'
  ];

  final List<Map<String, dynamic>> _exerciseLibrary = [
    {
      'name': 'Push-ups',
      'category': 'Strength',
      'muscle': 'Chest, Arms',
      'duration': '30 sec',
      'icon': 'fitness_center',
      'difficulty': 'Beginner',
    },
    {
      'name': 'Squats',
      'category': 'Strength',
      'muscle': 'Legs, Glutes',
      'duration': '45 sec',
      'icon': 'fitness_center',
      'difficulty': 'Beginner',
    },
    {
      'name': 'Burpees',
      'category': 'HIIT',
      'muscle': 'Full Body',
      'duration': '30 sec',
      'icon': 'local_fire_department',
      'difficulty': 'Advanced',
    },
    {
      'name': 'Mountain Climbers',
      'category': 'Cardio',
      'muscle': 'Core, Arms',
      'duration': '30 sec',
      'icon': 'directions_run',
      'difficulty': 'Intermediate',
    },
    {
      'name': 'Plank',
      'category': 'Strength',
      'muscle': 'Core',
      'duration': '60 sec',
      'icon': 'fitness_center',
      'difficulty': 'Beginner',
    },
    {
      'name': 'Jumping Jacks',
      'category': 'Cardio',
      'muscle': 'Full Body',
      'duration': '30 sec',
      'icon': 'directions_run',
      'difficulty': 'Beginner',
    },
  ];

  List<Map<String, dynamic>> get _filteredExercises {
    List<Map<String, dynamic>> filtered = _exerciseLibrary;

    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((exercise) => exercise['category'] == _selectedCategory)
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((exercise) =>
              (exercise['name'] as String)
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              (exercise['muscle'] as String)
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 12.w,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Text(
                  'Create Workout',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout Name Input
                  TextField(
                    controller: _workoutNameController,
                    decoration: InputDecoration(
                      labelText: 'Workout Name',
                      hintText: 'Enter workout name',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'edit',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Search Exercises',
                      hintText: 'Search by name or muscle group',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'search',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Category Filter
                  SizedBox(
                    height: 5.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = category),
                          child: Container(
                            margin: EdgeInsets.only(right: 2.w),
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.lightTheme.colorScheme.primary
                                  : AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category,
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Selected Exercises Count
                  if (_selectedExercises.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'check_circle',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '${_selectedExercises.length} exercises selected',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),
                  ],

                  // Exercise List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _filteredExercises[index];
                      final isSelected = _selectedExercises
                          .any((e) => e['name'] == exercise['name']);

                      return GestureDetector(
                        onTap: () => _toggleExercise(exercise),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 2.h),
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                    .withValues(alpha: 0.1)
                                : AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.lightTheme.colorScheme.primary
                                  : AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                          exercise['category'] as String)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CustomIconWidget(
                                  iconName: exercise['icon'] as String,
                                  color: _getCategoryColor(
                                      exercise['category'] as String),
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise['name'] as String,
                                      style: AppTheme
                                          .lightTheme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      exercise['muscle'] as String,
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.lightTheme.colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          exercise['duration'] as String,
                                          style: AppTheme
                                              .lightTheme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          exercise['difficulty'] as String,
                                          style: AppTheme
                                              .lightTheme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                CustomIconWidget(
                                  iconName: 'check_circle',
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  size: 24,
                                )
                              else
                                CustomIconWidget(
                                  iconName: 'add_circle_outline',
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleExercise(Map<String, dynamic> exercise) {
    setState(() {
      final isSelected =
          _selectedExercises.any((e) => e['name'] == exercise['name']);
      if (isSelected) {
        _selectedExercises.removeWhere((e) => e['name'] == exercise['name']);
      } else {
        _selectedExercises.add(exercise);
      }
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Strength':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'Cardio':
        return const Color(0xFFE76F51);
      case 'HIIT':
        return const Color(0xFFFF4D4F);
      case 'Yoga':
        return const Color(0xFF8B5CF6);
      case 'Flexibility':
        return const Color(0xFF52C41A);
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
