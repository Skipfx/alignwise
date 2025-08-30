import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/gemini_service.dart';

class AiAssistantWidget extends StatefulWidget {
  final GeminiService geminiService;
  final String mealType;
  final Function(MealSuggestion) onMealGenerated;
  final VoidCallback onUseIngredients;
  final MealSuggestion? aiGeneratedMeal;
  final bool isGenerating;
  final Function(bool) onGeneratingChanged;

  const AiAssistantWidget({
    super.key,
    required this.geminiService,
    required this.mealType,
    required this.onMealGenerated,
    required this.onUseIngredients,
    required this.aiGeneratedMeal,
    required this.isGenerating,
    required this.onGeneratingChanged,
  });

  @override
  State<AiAssistantWidget> createState() => _AiAssistantWidgetState();
}

class _AiAssistantWidgetState extends State<AiAssistantWidget> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _restrictionsController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    _caloriesController.dispose();
    _restrictionsController.dispose();
    super.dispose();
  }

  Future<void> _generateMeal() async {
    if (_promptController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a description for your meal');
      return;
    }

    widget.onGeneratingChanged(true);

    try {
      final targetCalories = int.tryParse(_caloriesController.text);
      final meal = await widget.geminiService.generateMeal(
        prompt: _promptController.text.trim(),
        dietaryRestrictions: _restrictionsController.text.trim().isNotEmpty
            ? _restrictionsController.text.trim()
            : null,
        targetCalories: targetCalories,
        mealType: widget.mealType,
      );

      widget.onMealGenerated(meal);
    } on GeminiException catch (e) {
      _showErrorDialog('AI meal generation failed: ${e.message}');
    } catch (e) {
      _showErrorDialog('An unexpected error occurred: $e');
    } finally {
      widget.onGeneratingChanged(false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text('Generation Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🤖 AI-Powered Meal Generation',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Powered by Google Gemini',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          TextField(
            controller: _promptController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Describe your ideal meal',
              hintText:
                  'e.g., "A healthy high-protein lunch with chicken and vegetables"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'restaurant_menu',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Calories',
                    hintText: 'Optional',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: TextField(
                  controller: _restrictionsController,
                  decoration: InputDecoration(
                    labelText: 'Dietary Restrictions',
                    hintText: 'e.g., vegan, gluten-free',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isGenerating ? null : _generateMeal,
              icon: widget.isGenerating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : CustomIconWidget(
                      iconName: 'auto_awesome',
                      color: Colors.white,
                      size: 24,
                    ),
              label: Text(
                widget.isGenerating ? 'Generating...' : 'Generate Meal with AI',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: widget.aiGeneratedMeal == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'psychology',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 48,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'AI meal will appear here',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Describe your ideal meal above',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildMealSuggestion(),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSuggestion() {
    final meal = widget.aiGeneratedMeal!;

    return SingleChildScrollView(
      child: Container(
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
                Expanded(
                  child: Text(
                    meal.mealName,
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(meal.confidence * 100).toInt()}% confident',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (meal.description.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(
                meal.description,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
            ],
            SizedBox(height: 2.h),
            Row(
              children: [
                _buildInfoChip('⏱️ ${meal.prepTime + meal.cookTime} min'),
                SizedBox(width: 2.w),
                _buildInfoChip('🍽️ ${meal.servings} servings'),
                SizedBox(width: 2.w),
                _buildInfoChip('📊 ${meal.difficulty}'),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutritionInfo(
                      'Calories', '${meal.nutrition.totalCalories}'),
                  _buildNutritionInfo('Protein',
                      '${meal.nutrition.protein.toStringAsFixed(1)}g'),
                  _buildNutritionInfo(
                      'Carbs', '${meal.nutrition.carbs.toStringAsFixed(1)}g'),
                  _buildNutritionInfo(
                      'Fat', '${meal.nutrition.fat.toStringAsFixed(1)}g'),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Ingredients (${meal.ingredients.length})',
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            ...meal.ingredients.take(3).map((ingredient) => Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'fiber_manual_record',
                        color: AppTheme.lightTheme.primaryColor,
                        size: 8,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          '${ingredient.amount} ${ingredient.unit} ${ingredient.name}',
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
            if (meal.ingredients.length > 3)
              Text(
                'and ${meal.ingredients.length - 3} more ingredients...',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onUseIngredients,
                icon: CustomIconWidget(
                  iconName: 'add_shopping_cart',
                  color: Colors.white,
                  size: 20,
                ),
                label: Text('Use These Ingredients'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTheme.lightTheme.textTheme.bodySmall,
      ),
    );
  }

  Widget _buildNutritionInfo(String label, String value) {
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
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
