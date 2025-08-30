import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MealSectionWidget extends StatefulWidget {
  final String mealType;
  final List<Map<String, dynamic>> foodItems;
  final VoidCallback onAddFood;
  final Function(int) onRemoveFood;
  final Function(int, int) onUpdateQuantity;

  const MealSectionWidget({
    super.key,
    required this.mealType,
    required this.foodItems,
    required this.onAddFood,
    required this.onRemoveFood,
    required this.onUpdateQuantity,
  });

  @override
  State<MealSectionWidget> createState() => _MealSectionWidgetState();
}

class _MealSectionWidgetState extends State<MealSectionWidget> {
  bool _isExpanded = true;

  int _calculateTotalCalories() {
    return (widget.foodItems as List).fold(0, (sum, item) {
      final itemMap = item as Map<String, dynamic>;
      final calories = itemMap['calories'] as int? ?? 0;
      final quantity = itemMap['quantity'] as int? ?? 1;
      return sum + (calories * quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _calculateTotalCalories();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: _getMealIcon(),
                    color: AppTheme.lightTheme.primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mealType,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (totalCalories > 0) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            '$totalCalories calories',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${(widget.foodItems as List).length} items',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  CustomIconWidget(
                    iconName: _isExpanded ? 'expand_less' : 'expand_more',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            if ((widget.foodItems as List).isEmpty)
              Container(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    CustomIconWidget(
                      iconName: 'restaurant',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'No food logged yet',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextButton.icon(
                      onPressed: widget.onAddFood,
                      icon: CustomIconWidget(
                        iconName: 'add',
                        color: AppTheme.lightTheme.primaryColor,
                        size: 16,
                      ),
                      label: Text('Add Food'),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (widget.foodItems as List).length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item =
                      (widget.foodItems as List)[index] as Map<String, dynamic>;
                  return _buildFoodItem(item, index);
                },
              ),
            Container(
              padding: EdgeInsets.all(4.w),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onAddFood,
                  icon: CustomIconWidget(
                    iconName: 'add',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 16,
                  ),
                  label: Text('Add Food'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> item, int index) {
    final name = item['name'] as String? ?? 'Unknown Food';
    final calories = item['calories'] as int? ?? 0;
    final quantity = item['quantity'] as int? ?? 1;
    final unit = item['unit'] as String? ?? 'serving';
    final protein = item['protein'] as double? ?? 0.0;
    final carbs = item['carbs'] as double? ?? 0.0;
    final fat = item['fat'] as double? ?? 0.0;

    return Dismissible(
      key: Key('food_item_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        color: AppTheme.lightTheme.colorScheme.error,
        child: CustomIconWidget(
          iconName: 'delete',
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) => widget.onRemoveFood(index),
      child: InkWell(
        onLongPress: () => _showFoodDetails(item),
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${calories * quantity} cal • P: ${(protein * quantity).toStringAsFixed(1)}g • C: ${(carbs * quantity).toStringAsFixed(1)}g • F: ${(fat * quantity).toStringAsFixed(1)}g',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: quantity > 1
                          ? () => widget.onUpdateQuantity(index, quantity - 1)
                          : null,
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8)),
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        child: CustomIconWidget(
                          iconName: 'remove',
                          color: quantity > 1
                              ? AppTheme.lightTheme.primaryColor
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
                      child: Text(
                        '$quantity',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.onUpdateQuantity(index, quantity + 1),
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(8)),
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        child: CustomIconWidget(
                          iconName: 'add',
                          color: AppTheme.lightTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMealIcon() {
    switch (widget.mealType.toLowerCase()) {
      case 'breakfast':
        return 'wb_sunny';
      case 'lunch':
        return 'wb_sunny_outlined';
      case 'dinner':
        return 'nights_stay';
      case 'snacks':
        return 'local_cafe';
      default:
        return 'restaurant';
    }
  }

  void _showFoodDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              item['name'] as String? ?? 'Food Details',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            _buildNutritionRow('Calories', '${item['calories']} kcal'),
            _buildNutritionRow('Protein', '${item['protein']}g'),
            _buildNutritionRow('Carbohydrates', '${item['carbs']}g'),
            _buildNutritionRow('Fat', '${item['fat']}g'),
            _buildNutritionRow('Fiber', '${item['fiber'] ?? 0}g'),
            _buildNutritionRow('Sugar', '${item['sugar'] ?? 0}g'),
            _buildNutritionRow('Sodium', '${item['sodium'] ?? 0}mg'),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
