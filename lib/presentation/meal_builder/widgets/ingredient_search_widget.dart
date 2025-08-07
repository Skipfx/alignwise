import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class IngredientSearchWidget extends StatefulWidget {
  final TextEditingController searchController;
  final Function(Map<String, dynamic>) onIngredientSelected;

  const IngredientSearchWidget({
    Key? key,
    required this.searchController,
    required this.onIngredientSelected,
  }) : super(key: key);

  @override
  State<IngredientSearchWidget> createState() => _IngredientSearchWidgetState();
}

class _IngredientSearchWidgetState extends State<IngredientSearchWidget> {
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  final List<Map<String, dynamic>> _commonIngredients = [
    {
      'name': 'Chicken Breast',
      'calories': 165,
      'protein': 31.0,
      'carbs': 0.0,
      'fat': 3.6,
      'unit': '100g',
    },
    {
      'name': 'Brown Rice',
      'calories': 111,
      'protein': 2.6,
      'carbs': 23.0,
      'fat': 0.9,
      'unit': '100g',
    },
    {
      'name': 'Broccoli',
      'calories': 34,
      'protein': 2.8,
      'carbs': 6.6,
      'fat': 0.4,
      'unit': '100g',
    },
    {
      'name': 'Avocado',
      'calories': 160,
      'protein': 2.0,
      'carbs': 8.5,
      'fat': 14.7,
      'unit': '100g',
    },
    {
      'name': 'Salmon Fillet',
      'calories': 206,
      'protein': 22.0,
      'carbs': 0.0,
      'fat': 12.0,
      'unit': '100g',
    },
    {
      'name': 'Greek Yogurt',
      'calories': 59,
      'protein': 10.0,
      'carbs': 3.6,
      'fat': 0.4,
      'unit': '100g',
    },
    {
      'name': 'Quinoa',
      'calories': 120,
      'protein': 4.4,
      'carbs': 22.0,
      'fat': 1.9,
      'unit': '100g',
    },
    {
      'name': 'Sweet Potato',
      'calories': 86,
      'protein': 1.6,
      'carbs': 20.0,
      'fat': 0.1,
      'unit': '100g',
    },
  ];

  void _searchIngredients(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      final results = _commonIngredients
          .where((ingredient) => (ingredient['name'] as String)
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.searchController,
          decoration: InputDecoration(
            hintText: 'Search ingredients...',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'search',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            suffixIcon: widget.searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      widget.searchController.clear();
                      _searchIngredients('');
                    },
                    icon: CustomIconWidget(
                      iconName: 'clear',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.lightTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
          onChanged: _searchIngredients,
        ),
        if (_searchResults.isNotEmpty) ...[
          SizedBox(height: 1.h),
          Container(
            constraints: BoxConstraints(maxHeight: 25.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
            ),
            child: ListView.separated(
              padding: EdgeInsets.all(2.w),
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => Divider(height: 0.5.h),
              itemBuilder: (context, index) {
                final ingredient = _searchResults[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 2.w),
                  title: Text(
                    ingredient['name'] as String,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${ingredient['calories']} cal • P: ${ingredient['protein']}g • C: ${ingredient['carbs']}g • F: ${ingredient['fat']}g',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      final ingredientWithQuantity =
                          Map<String, dynamic>.from(ingredient);
                      ingredientWithQuantity['quantity'] = 1;
                      widget.onIngredientSelected(ingredientWithQuantity);
                      widget.searchController.clear();
                      _searchIngredients('');
                    },
                    icon: CustomIconWidget(
                      iconName: 'add',
                      color: AppTheme.lightTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (_isSearching)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
