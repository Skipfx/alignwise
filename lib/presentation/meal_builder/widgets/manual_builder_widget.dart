import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './ingredient_list_widget.dart';
import './ingredient_search_widget.dart';

class ManualBuilderWidget extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final Function(Map<String, dynamic>) onAddIngredient;
  final Function(int) onRemoveIngredient;
  final Function(int, int) onUpdateQuantity;
  final Function(int, int) onReorder;

  const ManualBuilderWidget({
    Key? key,
    required this.ingredients,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
    required this.onUpdateQuantity,
    required this.onReorder,
  }) : super(key: key);

  @override
  State<ManualBuilderWidget> createState() => _ManualBuilderWidgetState();
}

class _ManualBuilderWidgetState extends State<ManualBuilderWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🥗 Build Your Meal',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          IngredientSearchWidget(
            searchController: _searchController,
            onIngredientSelected: widget.onAddIngredient,
          ),
          SizedBox(height: 2.h),
          Text(
            'Ingredients (${widget.ingredients.length})',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Expanded(
            child: widget.ingredients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'restaurant',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 48,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No ingredients added yet',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Search and add ingredients above',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : IngredientListWidget(
                    ingredients: widget.ingredients,
                    onRemoveIngredient: widget.onRemoveIngredient,
                    onUpdateQuantity: widget.onUpdateQuantity,
                    onReorder: widget.onReorder,
                  ),
          ),
        ],
      ),
    );
  }
}
