import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SessionCategoriesWidget extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  final TabController controller;

  const SessionCategoriesWidget({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 12.w,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == selectedCategory;

              return Padding(
                padding: EdgeInsets.only(right: 3.w),
                child: GestureDetector(
                  onTap: () => onCategoryChanged(category),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.w,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryLight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6.w),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryLight
                            : AppTheme.textPrimaryLight.withAlpha(77),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 5.w,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimaryLight.withAlpha(179),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _getCategoryDisplayName(category),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected ? Colors.white : AppTheme.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.grid_view;
      case 'yoga':
        return Icons.self_improvement;
      case 'hiit':
        return Icons.flash_on;
      case 'meditation':
        return Icons.spa;
      case 'nutrition':
        return Icons.restaurant;
      case 'pilates':
        return Icons.accessibility_new;
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.favorite;
      case 'dance':
        return Icons.music_note;
      default:
        return Icons.fitness_center;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return 'All';
      case 'yoga':
        return 'Yoga';
      case 'hiit':
        return 'HIIT';
      case 'meditation':
        return 'Meditation';
      case 'nutrition':
        return 'Nutrition';
      case 'pilates':
        return 'Pilates';
      case 'strength':
        return 'Strength';
      case 'cardio':
        return 'Cardio';
      case 'dance':
        return 'Dance';
      default:
        return category.toUpperCase();
    }
  }
}