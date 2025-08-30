import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class IngredientListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> ingredients;
  final Function(int) onRemoveIngredient;
  final Function(int, int) onUpdateQuantity;
  final Function(int, int) onReorder;

  const IngredientListWidget({
    super.key,
    required this.ingredients,
    required this.onRemoveIngredient,
    required this.onUpdateQuantity,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      onReorder: onReorder,
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        final quantity = ingredient['quantity'] as int? ?? 1;
        final calories = (ingredient['calories'] as int? ?? 0) * quantity;
        final protein = ((ingredient['protein'] as double? ?? 0.0) * quantity)
            .toStringAsFixed(1);
        final carbs = ((ingredient['carbs'] as double? ?? 0.0) * quantity)
            .toStringAsFixed(1);
        final fat = ((ingredient['fat'] as double? ?? 0.0) * quantity)
            .toStringAsFixed(1);

        return Container(
          key: ValueKey(ingredient['name']),
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(3.w),
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
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'drag_indicator',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      ingredient['name'] as String,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemoveIngredient(index),
                    icon: CustomIconWidget(
                      iconName: 'delete',
                      color: AppTheme.lightTheme.colorScheme.error,
                      size: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Text(
                    'Quantity:',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
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
                        IconButton(
                          onPressed: quantity > 1
                              ? () => onUpdateQuantity(index, quantity - 1)
                              : null,
                          icon: CustomIconWidget(
                            iconName: 'remove',
                            color: quantity > 1
                                ? AppTheme.lightTheme.primaryColor
                                : AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w),
                          child: Text(
                            '$quantity',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              onUpdateQuantity(index, quantity + 1),
                          icon: CustomIconWidget(
                            iconName: 'add',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    ingredient['unit'] as String? ?? 'serving',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNutrientInfo('Cal', '$calories'),
                    _buildNutrientInfo('P', '${protein}g'),
                    _buildNutrientInfo('C', '${carbs}g'),
                    _buildNutrientInfo('F', '${fat}g'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutrientInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
