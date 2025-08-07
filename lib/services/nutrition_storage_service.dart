import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NutritionStorageService {
  static final NutritionStorageService _instance =
      NutritionStorageService._internal();
  SharedPreferences? _prefs;

  factory NutritionStorageService() {
    return _instance;
  }

  NutritionStorageService._internal();

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save daily nutrition data
  Future<void> saveDailyNutrition(
      String date, Map<String, List<Map<String, dynamic>>> mealData) async {
    await _initPrefs();
    final key = 'nutrition_$date';
    final jsonString = jsonEncode(mealData);
    await _prefs!.setString(key, jsonString);
  }

  // Load daily nutrition data
  Future<Map<String, List<Map<String, dynamic>>>> loadDailyNutrition(
      String date) async {
    await _initPrefs();
    final key = 'nutrition_$date';
    final jsonString = _prefs!.getString(key);

    if (jsonString != null) {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final Map<String, List<Map<String, dynamic>>> mealData = {};

      for (String mealType in ['Breakfast', 'Lunch', 'Dinner', 'Snacks']) {
        if (decoded[mealType] != null) {
          mealData[mealType] = List<Map<String, dynamic>>.from(
              (decoded[mealType] as List)
                  .map((item) => Map<String, dynamic>.from(item)));
        } else {
          mealData[mealType] = [];
        }
      }
      return mealData;
    }

    // Return empty structure if no data found
    return {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snacks': [],
    };
  }

  // Save nutrition goals
  Future<void> saveNutritionGoals({
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required int water,
  }) async {
    await _initPrefs();
    final goals = {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'water': water,
    };
    await _prefs!.setString('nutrition_goals', jsonEncode(goals));
  }

  // Load nutrition goals
  Future<Map<String, dynamic>> loadNutritionGoals() async {
    await _initPrefs();
    final jsonString = _prefs!.getString('nutrition_goals');

    if (jsonString != null) {
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    }

    // Return default goals
    return {
      'calories': 2000,
      'protein': 150.0,
      'carbs': 250.0,
      'fat': 67.0,
      'water': 8,
    };
  }

  // Save water intake for today
  Future<void> saveWaterIntake(String date, int glasses) async {
    await _initPrefs();
    await _prefs!.setInt('water_$date', glasses);
  }

  // Load water intake for today
  Future<int> loadWaterIntake(String date) async {
    await _initPrefs();
    return _prefs!.getInt('water_$date') ?? 0;
  }

  // Get weekly nutrition data
  Future<List<Map<String, dynamic>>> getWeeklyNutritionData(
      List<String> dates) async {
    List<Map<String, dynamic>> weeklyData = [];

    for (String date in dates) {
      final mealData = await loadDailyNutrition(date);
      final totalCalories = _calculateTotalCalories(mealData);

      weeklyData.add({
        'date': date,
        'calories': totalCalories,
        'target': 2000, // Could be loaded from goals
      });
    }

    return weeklyData;
  }

  int _calculateTotalCalories(
      Map<String, List<Map<String, dynamic>>> mealData) {
    int total = 0;
    mealData.forEach((mealType, foods) {
      for (var food in foods) {
        final calories = food['calories'] as int? ?? 0;
        final quantity = food['quantity'] as int? ?? 1;
        total += calories * quantity;
      }
    });
    return total;
  }
}
