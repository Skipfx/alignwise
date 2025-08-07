import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  late final Dio _dio;
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal() {
    _initializeService();
  }

  void _initializeService() {
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY must be provided via --dart-define');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://generativelanguage.googleapis.com/v1',
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Dio get dio => _dio;
  String get authApiKey => apiKey;

  Future<NutritionAnalysis> analyzeFoodImage(File image,
      {String? additionalPrompt}) async {
    try {
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final prompt = '''
        ${additionalPrompt ?? 'Analyze this food image and provide detailed nutritional information.'}
        
        Please identify all visible food items and provide comprehensive nutritional data in the following JSON format:
        {
          "foods": [
            {
              "name": "Food Name",
              "quantity": "estimated serving size",
              "unit": "serving/gram/cup/etc",
              "calories": calories_per_serving,
              "protein": protein_in_grams,
              "carbs": carbs_in_grams,
              "fat": fat_in_grams,
              "fiber": fiber_in_grams,
              "sugar": sugar_in_grams,
              "sodium": sodium_in_mg,
              "confidence": confidence_score_0_to_1
            }
          ],
          "total_estimated_calories": total_calories,
          "meal_category": "breakfast/lunch/dinner/snack",
          "analysis_notes": "any additional observations"
        }
        
        Be as accurate as possible with nutritional values and provide realistic serving size estimates.
      ''';

      final response = await _dio.post(
        '/models/gemini-1.5-flash-002:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 2048,
            'temperature': 0.1,
          },
        },
      );

      if (response.data['candidates'] != null &&
          response.data['candidates'].isNotEmpty &&
          response.data['candidates'][0]['content'] != null) {
        final parts = response.data['candidates'][0]['content']['parts'];
        final text = parts.isNotEmpty ? parts[0]['text'] : '';

        return _parseNutritionResponse(text);
      } else {
        throw GeminiException(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to analyze image',
        );
      }
    } on DioException catch (e) {
      throw GeminiException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ?? e.message,
      );
    }
  }

  Future<NutritionAnalysis> analyzeBarcodeProduct(String barcode) async {
    try {
      final prompt = '''
        I have a product with barcode: $barcode
        
        Please provide nutritional information for this product. If you can identify the specific product, provide detailed nutritional data. If you cannot identify the specific product from the barcode, provide typical nutritional information for common products with similar barcodes.
        
        Respond in the following JSON format:
        {
          "foods": [
            {
              "name": "Product Name",
              "brand": "Brand Name (if known)",
              "quantity": "serving size",
              "unit": "serving/gram/ml/etc",
              "calories": calories_per_serving,
              "protein": protein_in_grams,
              "carbs": carbs_in_grams,
              "fat": fat_in_grams,
              "fiber": fiber_in_grams,
              "sugar": sugar_in_grams,
              "sodium": sodium_in_mg,
              "confidence": confidence_score_0_to_1,
              "barcode": "$barcode"
            }
          ],
          "total_estimated_calories": calories_per_serving,
          "meal_category": "snack",
          "analysis_notes": "Product identification notes"
        }
      ''';

      final response = await _dio.post(
        '/models/gemini-1.5-flash-002:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 1024,
            'temperature': 0.1,
          },
        },
      );

      if (response.data['candidates'] != null &&
          response.data['candidates'].isNotEmpty &&
          response.data['candidates'][0]['content'] != null) {
        final parts = response.data['candidates'][0]['content']['parts'];
        final text = parts.isNotEmpty ? parts[0]['text'] : '';

        return _parseNutritionResponse(text);
      } else {
        throw GeminiException(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to analyze barcode',
        );
      }
    } on DioException catch (e) {
      throw GeminiException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ?? e.message,
      );
    }
  }

  Future<MealSuggestion> generateMeal({
    required String prompt,
    String? dietaryRestrictions,
    int? targetCalories,
    String? mealType,
  }) async {
    try {
      final fullPrompt = '''
        Generate a complete meal based on the following requirements:
        - Request: $prompt
        ${dietaryRestrictions != null ? '- Dietary restrictions: $dietaryRestrictions' : ''}
        ${targetCalories != null ? '- Target calories: $targetCalories' : ''}
        ${mealType != null ? '- Meal type: $mealType' : ''}
        
        Please provide a complete meal suggestion with ingredients, instructions, and nutritional information in the following JSON format:
        {
          "meal_name": "Name of the meal",
          "description": "Brief description of the meal",
          "meal_type": "breakfast/lunch/dinner/snack",
          "prep_time": preparation_time_in_minutes,
          "cook_time": cooking_time_in_minutes,
          "servings": number_of_servings,
          "ingredients": [
            {
              "name": "Ingredient name",
              "amount": "quantity",
              "unit": "measurement unit",
              "calories": calories_per_ingredient,
              "protein": protein_in_grams,
              "carbs": carbs_in_grams,
              "fat": fat_in_grams
            }
          ],
          "instructions": [
            "Step 1 instruction",
            "Step 2 instruction"
          ],
          "nutrition": {
            "total_calories": total_calories,
            "protein": total_protein_grams,
            "carbs": total_carbs_grams,
            "fat": total_fat_grams,
            "fiber": total_fiber_grams,
            "sugar": total_sugar_grams,
            "sodium": total_sodium_mg
          },
          "tags": ["tag1", "tag2"],
          "difficulty": "easy/medium/hard",
          "confidence": confidence_score_0_to_1
        }
        
        Provide realistic nutritional values and practical cooking instructions.
      ''';

      final response = await _dio.post(
        '/models/gemini-1.5-flash-002:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 3000,
            'temperature': 0.7,
          },
        },
      );

      if (response.data['candidates'] != null &&
          response.data['candidates'].isNotEmpty &&
          response.data['candidates'][0]['content'] != null) {
        final parts = response.data['candidates'][0]['content']['parts'];
        final text = parts.isNotEmpty ? parts[0]['text'] : '';

        return _parseMealResponse(text);
      } else {
        throw GeminiException(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to generate meal',
        );
      }
    } on DioException catch (e) {
      throw GeminiException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ?? e.message,
      );
    }
  }

  MealSuggestion _parseMealResponse(String responseText) {
    try {
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        throw Exception('No valid JSON found in response');
      }

      final jsonText = responseText.substring(jsonStart, jsonEnd);
      final jsonData = jsonDecode(jsonText) as Map<String, dynamic>;

      return MealSuggestion.fromJson(jsonData);
    } catch (e) {
      return MealSuggestion.fallback(responseText);
    }
  }

  NutritionAnalysis _parseNutritionResponse(String responseText) {
    try {
      // Extract JSON from response text
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        throw Exception('No valid JSON found in response');
      }

      final jsonText = responseText.substring(jsonStart, jsonEnd);
      final jsonData = jsonDecode(jsonText) as Map<String, dynamic>;

      return NutritionAnalysis.fromJson(jsonData);
    } catch (e) {
      // Fallback to basic parsing if JSON fails
      return NutritionAnalysis.fallback(responseText);
    }
  }
}

class NutritionAnalysis {
  final List<FoodItem> foods;
  final int totalEstimatedCalories;
  final String mealCategory;
  final String analysisNotes;

  NutritionAnalysis({
    required this.foods,
    required this.totalEstimatedCalories,
    required this.mealCategory,
    required this.analysisNotes,
  });

  factory NutritionAnalysis.fromJson(Map<String, dynamic> json) {
    return NutritionAnalysis(
      foods: (json['foods'] as List? ?? [])
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalEstimatedCalories: json['total_estimated_calories'] as int? ?? 0,
      mealCategory: json['meal_category'] as String? ?? 'snack',
      analysisNotes: json['analysis_notes'] as String? ?? '',
    );
  }

  factory NutritionAnalysis.fallback(String responseText) {
    return NutritionAnalysis(
      foods: [
        FoodItem(
          name: 'Unknown Food',
          quantity: '1',
          unit: 'serving',
          calories: 200,
          protein: 10.0,
          carbs: 20.0,
          fat: 8.0,
          fiber: 3.0,
          sugar: 5.0,
          sodium: 200,
          confidence: 0.3,
        ),
      ],
      totalEstimatedCalories: 200,
      mealCategory: 'snack',
      analysisNotes: 'AI analysis available: $responseText',
    );
  }
}

class FoodItem {
  final String name;
  final String? brand;
  final String quantity;
  final String unit;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final int sodium;
  final double confidence;
  final String? barcode;

  FoodItem({
    required this.name,
    this.brand,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.confidence,
    this.barcode,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String? ?? 'Unknown Food',
      brand: json['brand'] as String?,
      quantity: json['quantity'] as String? ?? '1',
      unit: json['unit'] as String? ?? 'serving',
      calories: json['calories'] as int? ?? 0,
      protein: (json['protein'] as num? ?? 0).toDouble(),
      carbs: (json['carbs'] as num? ?? 0).toDouble(),
      fat: (json['fat'] as num? ?? 0).toDouble(),
      fiber: (json['fiber'] as num? ?? 0).toDouble(),
      sugar: (json['sugar'] as num? ?? 0).toDouble(),
      sodium: json['sodium'] as int? ?? 0,
      confidence: (json['confidence'] as num? ?? 0.5).toDouble(),
      barcode: json['barcode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'confidence': confidence,
      'barcode': barcode,
    };
  }

  // Convert to the format expected by the UI
  Map<String, dynamic> toMealFormat() {
    return {
      'name': brand != null ? '$brand $name' : name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'quantity': 1,
      'unit': '$quantity $unit',
    };
  }
}

class MealSuggestion {
  final String mealName;
  final String description;
  final String mealType;
  final int prepTime;
  final int cookTime;
  final int servings;
  final List<MealIngredient> ingredients;
  final List<String> instructions;
  final MealNutrition nutrition;
  final List<String> tags;
  final String difficulty;
  final double confidence;

  MealSuggestion({
    required this.mealName,
    required this.description,
    required this.mealType,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.nutrition,
    required this.tags,
    required this.difficulty,
    required this.confidence,
  });

  factory MealSuggestion.fromJson(Map<String, dynamic> json) {
    return MealSuggestion(
      mealName: json['meal_name'] as String? ?? 'AI Generated Meal',
      description: json['description'] as String? ?? '',
      mealType: json['meal_type'] as String? ?? 'lunch',
      prepTime: json['prep_time'] as int? ?? 15,
      cookTime: json['cook_time'] as int? ?? 30,
      servings: json['servings'] as int? ?? 2,
      ingredients: (json['ingredients'] as List? ?? [])
          .map((e) => MealIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      instructions: (json['instructions'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      nutrition: MealNutrition.fromJson(
          json['nutrition'] as Map<String, dynamic>? ?? {}),
      tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      difficulty: json['difficulty'] as String? ?? 'medium',
      confidence: (json['confidence'] as num? ?? 0.7).toDouble(),
    );
  }

  factory MealSuggestion.fallback(String responseText) {
    return MealSuggestion(
      mealName: 'AI Generated Meal',
      description: 'A healthy and delicious meal created by AI',
      mealType: 'lunch',
      prepTime: 15,
      cookTime: 30,
      servings: 2,
      ingredients: [
        MealIngredient(
          name: 'Mixed ingredients',
          amount: '1',
          unit: 'portion',
          calories: 400,
          protein: 20.0,
          carbs: 45.0,
          fat: 15.0,
        ),
      ],
      instructions: [
        'Prepare ingredients as suggested by AI',
        'Cook according to preferences'
      ],
      nutrition: MealNutrition(
        totalCalories: 400,
        protein: 20.0,
        carbs: 45.0,
        fat: 15.0,
        fiber: 8.0,
        sugar: 10.0,
        sodium: 300,
      ),
      tags: ['ai-generated', 'healthy'],
      difficulty: 'medium',
      confidence: 0.5,
    );
  }

  Map<String, dynamic> toStorageFormat() {
    return {
      'name': mealName,
      'description': description,
      'meal_type': mealType,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'servings': servings,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'nutrition': nutrition.toJson(),
      'tags': tags,
      'difficulty': difficulty,
      'confidence': confidence,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

class MealIngredient {
  final String name;
  final String amount;
  final String unit;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  MealIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MealIngredient.fromJson(Map<String, dynamic> json) {
    return MealIngredient(
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '1',
      unit: json['unit'] as String? ?? 'unit',
      calories: json['calories'] as int? ?? 0,
      protein: (json['protein'] as num? ?? 0).toDouble(),
      carbs: (json['carbs'] as num? ?? 0).toDouble(),
      fat: (json['fat'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class MealNutrition {
  final int totalCalories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final int sodium;

  MealNutrition({
    required this.totalCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
  });

  factory MealNutrition.fromJson(Map<String, dynamic> json) {
    return MealNutrition(
      totalCalories: json['total_calories'] as int? ?? 0,
      protein: (json['protein'] as num? ?? 0).toDouble(),
      carbs: (json['carbs'] as num? ?? 0).toDouble(),
      fat: (json['fat'] as num? ?? 0).toDouble(),
      fiber: (json['fiber'] as num? ?? 0).toDouble(),
      sugar: (json['sugar'] as num? ?? 0).toDouble(),
      sodium: json['sodium'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_calories': totalCalories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
    };
  }
}

class GeminiException implements Exception {
  final int statusCode;
  final String message;

  GeminiException({required this.statusCode, required this.message});

  @override
  String toString() => 'GeminiException: $statusCode - $message';
}
