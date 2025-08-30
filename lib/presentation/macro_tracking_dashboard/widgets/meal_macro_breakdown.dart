import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MealMacroBreakdown extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> mealData;
  final Function(String) onMealTap;

  const MealMacroBreakdown({
    super.key,
    required this.mealData,
    required this.onMealTap,
  });

  @override
  State<MealMacroBreakdown> createState() => _MealMacroBreakdownState();
}

class _MealMacroBreakdownState extends State<MealMacroBreakdown> {
  final Set<String> _expandedMeals = {};

  @override
  Widget build(BuildContext context) {
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
            'Meal-by-Meal Breakdown',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          ...widget.mealData.keys
              .map((mealType) => _buildMealSection(mealType)),
        ],
      ),
    );
  }

  Widget _buildMealSection(String mealType) {
    final mealItems = widget.mealData[mealType] ?? [];
    final isExpanded = _expandedMeals.contains(mealType);

    // Calculate meal totals
    double totalProtein = 0, totalCarbs = 0, totalFat = 0, totalCalories = 0;
    for (var item in mealItems) {
      totalProtein += item['protein'] ?? 0.0;
      totalCarbs += item['carbs'] ?? 0.0;
      totalFat += item['fat'] ?? 0.0;
      totalCalories += item['calories'] ?? 0.0;
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedMeals.remove(mealType);
                } else {
                  _expandedMeals.add(mealType);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: _getMealColor(mealType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: _getMealIcon(mealType),
                      color: _getMealColor(mealType),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              mealType,
                              style: AppTheme.lightTheme.textTheme.titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${mealItems.length} item${mealItems.length != 1 ? 's' : ''}',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                CustomIconWidget(
                                  iconName: isExpanded
                                      ? 'expand_less'
                                      : 'expand_more',
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${totalCalories.round()} kcal',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: _getMealColor(mealType),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'P: ${totalProtein.round()}g • C: ${totalCarbs.round()}g • F: ${totalFat.round()}g',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              height: 1,
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.1),
            ),
            ...mealItems
                .asMap()
                .entries
                .map((entry) => _buildFoodItem(entry.value)),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> item) {
    return Container(
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          SizedBox(width: 10.w), // Indent for food items
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown Food',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    _buildMacroChip(
                        'P', '${item['protein']}g', const Color(0xFF6BCF7F)),
                    SizedBox(width: 2.w),
                    _buildMacroChip(
                        'C', '${item['carbs']}g', const Color(0xFF4A90E2)),
                    SizedBox(width: 2.w),
                    _buildMacroChip(
                        'F', '${item['fat']}g', const Color(0xFFF5A623)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${item['calories']} kcal',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
        ),
      ),
    );
  }

  Color _getMealColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return const Color(0xFFF39C12);
      case 'lunch':
        return const Color(0xFF3498DB);
      case 'dinner':
        return const Color(0xFF8E44AD);
      case 'snacks':
        return const Color(0xFFE74C3C);
      default:
        return AppTheme.lightTheme.primaryColor;
    }
  }

  String _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'breakfast_dining';
      case 'lunch':
        return 'lunch_dining';
      case 'dinner':
        return 'dinner_dining';
      case 'snacks':
        return 'cookie';
      default:
        return 'restaurant';
    }
  }
}
