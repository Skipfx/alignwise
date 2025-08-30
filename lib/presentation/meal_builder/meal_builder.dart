import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/gemini_service.dart';
import '../../services/meal_storage_service.dart';
import './widgets/ai_assistant_widget.dart';
import './widgets/manual_builder_widget.dart';
import './widgets/nutrition_preview_widget.dart';

class MealBuilder extends StatefulWidget {
  const MealBuilder({super.key});

  @override
  State<MealBuilder> createState() => _MealBuilderState();
}

class _MealBuilderState extends State<MealBuilder>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _mealNameController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final MealStorageService _mealStorageService = MealStorageService();

  List<Map<String, dynamic>> _ingredients = [];
  MealSuggestion? _aiGeneratedMeal;
  bool _isGenerating = false;
  String _selectedMealType = 'lunch';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mealNameController.text = 'My Custom Meal';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mealNameController.dispose();
    super.dispose();
  }

  void _addIngredient(Map<String, dynamic> ingredient) {
    setState(() {
      _ingredients.add(ingredient);
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _updateIngredientQuantity(int index, int newQuantity) {
    setState(() {
      _ingredients[index]['quantity'] = newQuantity;
    });
  }

  void _reorderIngredients(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final ingredient = _ingredients.removeAt(oldIndex);
      _ingredients.insert(newIndex, ingredient);
    });
  }

  void _onAiMealGenerated(MealSuggestion meal) {
    setState(() {
      _aiGeneratedMeal = meal;
      _mealNameController.text = meal.mealName;
      _selectedMealType = meal.mealType;
    });
  }

  void _useAiMealIngredients() {
    if (_aiGeneratedMeal != null) {
      setState(() {
        _ingredients = _aiGeneratedMeal!.ingredients
            .map((ingredient) => {
                  'name': ingredient.name,
                  'amount': ingredient.amount,
                  'unit': ingredient.unit,
                  'calories': ingredient.calories,
                  'protein': ingredient.protein,
                  'carbs': ingredient.carbs,
                  'fat': ingredient.fat,
                  'quantity': 1,
                })
            .toList();
      });
    }
  }

  Map<String, int> _calculateNutrition() {
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var ingredient in _ingredients) {
      final quantity = ingredient['quantity'] as int? ?? 1;
      totalCalories += ((ingredient['calories'] as int? ?? 0) * quantity);
      totalProtein += ((ingredient['protein'] as double? ?? 0.0) * quantity);
      totalCarbs += ((ingredient['carbs'] as double? ?? 0.0) * quantity);
      totalFat += ((ingredient['fat'] as double? ?? 0.0) * quantity);
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein.round(),
      'carbs': totalCarbs.round(),
      'fat': totalFat.round(),
    };
  }

  Future<void> _saveMeal() async {
    if (_mealNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a meal name');
      return;
    }

    if (_ingredients.isEmpty && _aiGeneratedMeal == null) {
      _showErrorDialog('Please add ingredients or generate an AI meal');
      return;
    }

    try {
      final nutrition = _calculateNutrition();

      final mealData = {
        'name': _mealNameController.text.trim(),
        'meal_type': _selectedMealType,
        'ingredients': _ingredients,
        'nutrition': nutrition,
        'ai_generated': _aiGeneratedMeal != null,
        'ai_instructions': _aiGeneratedMeal?.instructions ?? [],
        'ai_description': _aiGeneratedMeal?.description ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _mealStorageService.saveMeal(mealData);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Meal "${_mealNameController.text}" saved successfully!'),
          backgroundColor: AppTheme.lightTheme.primaryColor,
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to save meal: $e');
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
            Text('Error'),
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
    final nutrition = _calculateNutrition();

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: TextField(
          controller: _mealNameController,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter meal name...',
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveMeal,
            child: Text('Save'),
          ),
          SizedBox(width: 2.w),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Manual Builder'),
            Tab(text: 'AI Assistant'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Text(
                  'Meal Type:',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedMealType,
                    isExpanded: true,
                    items: ['breakfast', 'lunch', 'dinner', 'snack']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMealType = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ManualBuilderWidget(
                  ingredients: _ingredients,
                  onAddIngredient: _addIngredient,
                  onRemoveIngredient: _removeIngredient,
                  onUpdateQuantity: _updateIngredientQuantity,
                  onReorder: _reorderIngredients,
                ),
                AiAssistantWidget(
                  geminiService: _geminiService,
                  mealType: _selectedMealType,
                  onMealGenerated: _onAiMealGenerated,
                  onUseIngredients: _useAiMealIngredients,
                  aiGeneratedMeal: _aiGeneratedMeal,
                  isGenerating: _isGenerating,
                  onGeneratingChanged: (generating) {
                    setState(() => _isGenerating = generating);
                  },
                ),
              ],
            ),
          ),
          NutritionPreviewWidget(
            calories: nutrition['calories']!,
            protein: nutrition['protein']!,
            carbs: nutrition['carbs']!,
            fat: nutrition['fat']!,
          ),
        ],
      ),
    );
  }
}
