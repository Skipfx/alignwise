import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MacroGoalAdjustment extends StatefulWidget {
  final String currentGoal;
  final Map<String, Map<String, double>> macroPresets;
  final Function(String) onGoalChanged;

  const MacroGoalAdjustment({
    Key? key,
    required this.currentGoal,
    required this.macroPresets,
    required this.onGoalChanged,
  }) : super(key: key);

  @override
  State<MacroGoalAdjustment> createState() => _MacroGoalAdjustmentState();
}

class _MacroGoalAdjustmentState extends State<MacroGoalAdjustment> {
  late String _selectedGoal;
  late Map<String, double> _customMacros;
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.currentGoal;
    _customMacros = Map.from(widget.macroPresets[_selectedGoal]!);
  }

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
          Container(
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
                      'Adjust Macro Goals',
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
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preset Goals',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  ...widget.macroPresets.keys
                      .map((goal) => _buildGoalPreset(goal)),
                  SizedBox(height: 3.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Custom Configuration',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch(
                        value: _isCustomMode,
                        onChanged: (value) {
                          setState(() {
                            _isCustomMode = value;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isCustomMode) ...[
                    SizedBox(height: 2.h),
                    _buildCustomSlider(
                        'Calories', _customMacros['calories']!, 1200, 3500,
                        (value) {
                      setState(() {
                        _customMacros['calories'] = value;
                      });
                    }),
                    _buildCustomSlider(
                        'Protein (g)', _customMacros['protein']!, 50, 300,
                        (value) {
                      setState(() {
                        _customMacros['protein'] = value;
                      });
                    }),
                    _buildCustomSlider(
                        'Carbs (g)', _customMacros['carbs']!, 50, 400, (value) {
                      setState(() {
                        _customMacros['carbs'] = value;
                      });
                    }),
                    _buildCustomSlider(
                        'Fat (g)', _customMacros['fat']!, 20, 150, (value) {
                      setState(() {
                        _customMacros['fat'] = value;
                      });
                    }),
                  ],
                  SizedBox(height: 3.h),
                  _buildMacroRatioInfo(),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onGoalChanged(
                          _isCustomMode ? 'custom' : _selectedGoal);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Changes'),
                  ),
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPreset(String goal) {
    final isSelected = _selectedGoal == goal && !_isCustomMode;
    final macros = widget.macroPresets[goal]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = goal;
          _isCustomMode = false;
          _customMacros = Map.from(macros);
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 1.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
              : AppTheme.lightTheme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal.toUpperCase(),
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.lightTheme.primaryColor : null,
                  ),
                ),
                if (isSelected)
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 20,
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              _getGoalDescription(goal),
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMacroInfo(
                    '${macros['calories']!.round()} kcal', 'Calories'),
                _buildMacroInfo('${macros['protein']!.round()}g', 'Protein'),
                _buildMacroInfo('${macros['carbs']!.round()}g', 'Carbs'),
                _buildMacroInfo('${macros['fat']!.round()}g', 'Fat'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroInfo(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomSlider(String label, double value, double min, double max,
      Function(double) onChanged) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value.round().toString(),
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 10).round(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRatioInfo() {
    final totalCalories = _customMacros['calories']!;
    final proteinCals = _customMacros['protein']! * 4;
    final carbsCals = _customMacros['carbs']! * 4;
    final fatCals = _customMacros['fat']! * 9;

    final proteinPercent = (proteinCals / totalCalories * 100).round();
    final carbsPercent = (carbsCals / totalCalories * 100).round();
    final fatPercent = (fatCals / totalCalories * 100).round();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macro Ratio Preview',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Protein: $proteinPercent% • Carbs: $carbsPercent% • Fat: $fatPercent%',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getGoalDescription(String goal) {
    switch (goal) {
      case 'cutting':
        return 'Lower calorie intake for weight loss with high protein';
      case 'maintenance':
        return 'Balanced intake to maintain current weight';
      case 'bulking':
        return 'Higher calorie intake for muscle gain and growth';
      default:
        return 'Custom macro configuration';
    }
  }
}
