import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MacroFoodSuggestions extends StatefulWidget {
  final double remainingProtein;
  final double remainingCarbs;
  final double remainingFat;

  const MacroFoodSuggestions({
    Key? key,
    required this.remainingProtein,
    required this.remainingCarbs,
    required this.remainingFat,
  }) : super(key: key);

  @override
  State<MacroFoodSuggestions> createState() => _MacroFoodSuggestionsState();
}

class _MacroFoodSuggestionsState extends State<MacroFoodSuggestions> {
  String _selectedMacro = 'protein';

  // Mock food suggestions based on macro needs
  final Map<String, List<Map<String, dynamic>>> _foodSuggestions = {
    'protein': [
      {
        'name': 'Greek Yogurt',
        'serving': '1 cup (170g)',
        'protein': 20.0,
        'carbs': 9.0,
        'fat': 0.0,
        'calories': 100,
        'category': 'Dairy',
        'icon': 'local_dining',
      },
      {
        'name': 'Chicken Breast',
        'serving': '100g',
        'protein': 31.0,
        'carbs': 0.0,
        'fat': 3.6,
        'calories': 165,
        'category': 'Meat',
        'icon': 'restaurant',
      },
      {
        'name': 'Protein Powder',
        'serving': '1 scoop (30g)',
        'protein': 25.0,
        'carbs': 3.0,
        'fat': 1.0,
        'calories': 120,
        'category': 'Supplement',
        'icon': 'sports_bar',
      },
      {
        'name': 'Eggs',
        'serving': '2 large',
        'protein': 12.0,
        'carbs': 1.0,
        'fat': 10.0,
        'calories': 140,
        'category': 'Protein',
        'icon': 'egg',
      },
      {
        'name': 'Tuna',
        'serving': '100g',
        'protein': 30.0,
        'carbs': 0.0,
        'fat': 1.0,
        'calories': 132,
        'category': 'Fish',
        'icon': 'set_meal',
      },
    ],
    'carbs': [
      {
        'name': 'Brown Rice',
        'serving': '1 cup cooked',
        'protein': 5.0,
        'carbs': 45.0,
        'fat': 2.0,
        'calories': 216,
        'category': 'Grain',
        'icon': 'rice_bowl',
      },
      {
        'name': 'Sweet Potato',
        'serving': '1 medium (150g)',
        'protein': 2.0,
        'carbs': 26.0,
        'fat': 0.1,
        'calories': 112,
        'category': 'Vegetable',
        'icon': 'local_florist',
      },
      {
        'name': 'Banana',
        'serving': '1 medium',
        'protein': 1.3,
        'carbs': 27.0,
        'fat': 0.3,
        'calories': 105,
        'category': 'Fruit',
        'icon': 'nature',
      },
      {
        'name': 'Oatmeal',
        'serving': '1 cup cooked',
        'protein': 6.0,
        'carbs': 32.0,
        'fat': 2.0,
        'calories': 166,
        'category': 'Grain',
        'icon': 'breakfast_dining',
      },
      {
        'name': 'Whole Wheat Pasta',
        'serving': '100g cooked',
        'protein': 5.0,
        'carbs': 25.0,
        'fat': 1.0,
        'calories': 124,
        'category': 'Grain',
        'icon': 'ramen_dining',
      },
    ],
    'fat': [
      {
        'name': 'Avocado',
        'serving': '1/2 medium',
        'protein': 2.0,
        'carbs': 9.0,
        'fat': 15.0,
        'calories': 160,
        'category': 'Fruit',
        'icon': 'eco',
      },
      {
        'name': 'Almonds',
        'serving': '30g',
        'protein': 6.0,
        'carbs': 6.0,
        'fat': 14.0,
        'calories': 164,
        'category': 'Nuts',
        'icon': 'nature',
      },
      {
        'name': 'Olive Oil',
        'serving': '1 tbsp',
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 14.0,
        'calories': 119,
        'category': 'Oil',
        'icon': 'opacity',
      },
      {
        'name': 'Salmon',
        'serving': '100g',
        'protein': 25.0,
        'carbs': 0.0,
        'fat': 13.0,
        'calories': 208,
        'category': 'Fish',
        'icon': 'set_meal',
      },
      {
        'name': 'Peanut Butter',
        'serving': '2 tbsp',
        'protein': 8.0,
        'carbs': 8.0,
        'fat': 16.0,
        'calories': 188,
        'category': 'Nut Butter',
        'icon': 'cookie',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildRemainingMacros(),
          _buildMacroTabs(),
          Expanded(
            child: _buildFoodSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Macro-Friendly Foods',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingMacros() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Remaining Daily Targets',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRemainingMacro(
                  'Protein', widget.remainingProtein, const Color(0xFF6BCF7F)),
              _buildRemainingMacro(
                  'Carbs', widget.remainingCarbs, const Color(0xFF4A90E2)),
              _buildRemainingMacro(
                  'Fat', widget.remainingFat, const Color(0xFFF5A623)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingMacro(String label, double remaining, Color color) {
    final isNeeded = remaining > 0;

    return Column(
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          isNeeded ? '${remaining.toStringAsFixed(1)}g' : 'Target Hit!',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isNeeded ? color : const Color(0xFF6BCF7F),
          ),
        ),
        if (isNeeded)
          Text(
            'needed',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontSize: 10.sp,
            ),
          ),
      ],
    );
  }

  Widget _buildMacroTabs() {
    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildTabButton('Protein', 'protein', const Color(0xFF6BCF7F)),
          _buildTabButton('Carbs', 'carbs', const Color(0xFF4A90E2)),
          _buildTabButton('Fat', 'fat', const Color(0xFFF5A623)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String value, Color color) {
    final isSelected = _selectedMacro == value;
    final remaining = value == 'protein'
        ? widget.remainingProtein
        : value == 'carbs'
            ? widget.remainingCarbs
            : widget.remainingFat;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMacro = value;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? color
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              if (remaining > 0)
                Text(
                  '${remaining.toStringAsFixed(0)}g left',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? color
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontSize: 10.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodSuggestions() {
    final foods = _foodSuggestions[_selectedMacro] ?? [];
    final remainingMacro = _selectedMacro == 'protein'
        ? widget.remainingProtein
        : _selectedMacro == 'carbs'
            ? widget.remainingCarbs
            : widget.remainingFat;

    if (remainingMacro <= 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: const Color(0xFF6BCF7F),
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'Target Already Met!',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6BCF7F),
              ),
            ),
            Text(
              'You\'ve reached your ${_selectedMacro} goal for today.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return _buildFoodSuggestionCard(food);
      },
    );
  }

  Widget _buildFoodSuggestionCard(Map<String, dynamic> food) {
    final macroColor = _getMacroColor(_selectedMacro);
    final mainMacroValue = food[_selectedMacro] as double;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: macroColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: food['icon'],
              color: macroColor,
              size: 24,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      food['name'],
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: macroColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${mainMacroValue.toStringAsFixed(1)}g',
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: macroColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  food['serving'],
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    _buildNutrientChip(
                        'P', '${food['protein']}g', const Color(0xFF6BCF7F)),
                    SizedBox(width: 2.w),
                    _buildNutrientChip(
                        'C', '${food['carbs']}g', const Color(0xFF4A90E2)),
                    SizedBox(width: 2.w),
                    _buildNutrientChip(
                        'F', '${food['fat']}g', const Color(0xFFF5A623)),
                    SizedBox(width: 2.w),
                    _buildNutrientChip('Cal', '${food['calories']}',
                        AppTheme.lightTheme.primaryColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 9.sp,
        ),
      ),
    );
  }

  Color _getMacroColor(String macro) {
    switch (macro) {
      case 'protein':
        return const Color(0xFF6BCF7F);
      case 'carbs':
        return const Color(0xFF4A90E2);
      case 'fat':
        return const Color(0xFFF5A623);
      default:
        return AppTheme.lightTheme.primaryColor;
    }
  }
}
