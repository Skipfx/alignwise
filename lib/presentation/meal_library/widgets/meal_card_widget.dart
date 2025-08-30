import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MealCardWidget extends StatelessWidget {
  final Map<String, dynamic> meal;
  final bool isGridView;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onLog;

  const MealCardWidget({
    super.key,
    required this.meal,
    required this.isGridView,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onDuplicate,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    final nutrition = meal['nutrition'] as Map<String, dynamic>? ?? {};
    final calories = nutrition['calories'] as int? ?? 0;
    final protein = nutrition['protein'] as int? ?? 0;
    final carbs = nutrition['carbs'] as int? ?? 0;
    final fat = nutrition['fat'] as int? ?? 0;
    final mealType = meal['meal_type'] as String? ?? 'lunch';
    final isAiGenerated = meal['ai_generated'] as bool? ?? false;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
              : AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppTheme.lightTheme.primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isGridView ? _buildGridCard() : _buildListCard(),
      ),
    );
  }

  Widget _buildGridCard() {
    final nutrition = meal['nutrition'] as Map<String, dynamic>? ?? {};
    final calories = nutrition['calories'] as int? ?? 0;
    final protein = nutrition['protein'] as int? ?? 0;
    final carbs = nutrition['carbs'] as int? ?? 0;
    final fat = nutrition['fat'] as int? ?? 0;
    final isAiGenerated = meal['ai_generated'] as bool? ?? false;
    
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20.w,
                decoration: BoxDecoration(
                  color: _getMealTypeColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: _getMealTypeIcon(),
                        color: _getMealTypeColor(),
                        size: 32,
                      ),
                      if (isAiGenerated) ...[
                        SizedBox(height: 0.5.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 1.w, vertical: 0.2.h),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'AI',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 8.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                meal['name'] as String? ?? 'Unnamed Meal',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.h),
              Text(
                '$calories cal',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('P: ${protein}g',
                      style: AppTheme.lightTheme.textTheme.bodySmall),
                  Text('C: ${carbs}g',
                      style: AppTheme.lightTheme.textTheme.bodySmall),
                  Text('F: ${fat}g',
                      style: AppTheme.lightTheme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
        if (isMultiSelectMode)
          Positioned(
            top: 2.w,
            right: 2.w,
            child: Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
              child: CustomIconWidget(
                iconName: isSelected ? 'check' : 'circle',
                color: isSelected ? Colors.white : Colors.transparent,
                size: 16,
              ),
            ),
          )
        else
          Positioned(
            top: 2.w,
            right: 2.w,
            child: PopupMenuButton(
              icon: CustomIconWidget(
                iconName: 'more_vert',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 16,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'log',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'add_circle',
                        color: AppTheme.lightTheme.primaryColor,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Text('Quick Log'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'content_copy',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Text('Duplicate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'delete',
                        color: AppTheme.lightTheme.colorScheme.error,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'log':
                    onLog();
                    break;
                  case 'duplicate':
                    onDuplicate();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildListCard() {
    final nutrition = meal['nutrition'] as Map<String, dynamic>? ?? {};
    final calories = nutrition['calories'] as int? ?? 0;
    final protein = nutrition['protein'] as int? ?? 0;
    final carbs = nutrition['carbs'] as int? ?? 0;
    final fat = nutrition['fat'] as int? ?? 0;
    final isAiGenerated = meal['ai_generated'] as bool? ?? false;
    
    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          if (isMultiSelectMode)
            Container(
              margin: EdgeInsets.only(right: 3.w),
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
              child: CustomIconWidget(
                iconName: isSelected ? 'check' : 'circle',
                color: isSelected ? Colors.white : Colors.transparent,
                size: 20,
              ),
            ),
          Container(
            width: 16.w,
            height: 16.w,
            decoration: BoxDecoration(
              color: _getMealTypeColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: _getMealTypeIcon(),
                  color: _getMealTypeColor(),
                  size: 24,
                ),
                if (isAiGenerated) ...[
                  SizedBox(height: 0.5.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.2.h),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AI',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 8.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['name'] as String? ?? 'Unnamed Meal',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                if (meal['description'] != null &&
                    (meal['description'] as String).isNotEmpty)
                  Text(
                    meal['description'] as String,
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Text(
                      '$calories cal',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text('P: ${protein}g',
                        style: AppTheme.lightTheme.textTheme.bodySmall),
                    SizedBox(width: 2.w),
                    Text('C: ${carbs}g',
                        style: AppTheme.lightTheme.textTheme.bodySmall),
                    SizedBox(width: 2.w),
                    Text('F: ${fat}g',
                        style: AppTheme.lightTheme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          if (!isMultiSelectMode)
            PopupMenuButton(
              icon: CustomIconWidget(
                iconName: 'more_vert',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'log',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'add_circle',
                        color: AppTheme.lightTheme.primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text('Quick Log'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'content_copy',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text('Duplicate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'delete',
                        color: AppTheme.lightTheme.colorScheme.error,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'log':
                    onLog();
                    break;
                  case 'duplicate':
                    onDuplicate();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
            ),
        ],
      ),
    );
  }

  String _getMealTypeIcon() {
    switch ((meal['meal_type'] as String? ?? 'lunch').toLowerCase()) {
      case 'breakfast':
        return 'wb_sunny';
      case 'lunch':
        return 'wb_cloudy';
      case 'dinner':
        return 'nights_stay';
      case 'snack':
        return 'local_cafe';
      default:
        return 'restaurant';
    }
  }

  Color _getMealTypeColor() {
    switch ((meal['meal_type'] as String? ?? 'lunch').toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return AppTheme.lightTheme.primaryColor;
    }
  }
}