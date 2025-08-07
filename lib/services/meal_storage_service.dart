import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MealStorageService {
  static const String _savedMealsKey = 'saved_meals';
  static const String _recentMealsKey = 'recent_meals';
  static const String _mealHistoryKey = 'meal_history';

  Future<void> saveMeal(Map<String, dynamic> meal) async {
    final prefs = await SharedPreferences.getInstance();
    final savedMeals = await getSavedMeals();

    meal['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    savedMeals.add(meal);

    await prefs.setString(_savedMealsKey, jsonEncode(savedMeals));
  }

  Future<List<Map<String, dynamic>>> getSavedMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMealsJson = prefs.getString(_savedMealsKey);

    if (savedMealsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(savedMealsJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteMeal(String mealId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedMeals = await getSavedMeals();

    savedMeals.removeWhere((meal) => meal['id'] == mealId);
    await prefs.setString(_savedMealsKey, jsonEncode(savedMeals));
  }

  Future<void> updateMeal(
      String mealId, Map<String, dynamic> updatedMeal) async {
    final prefs = await SharedPreferences.getInstance();
    final savedMeals = await getSavedMeals();

    final index = savedMeals.indexWhere((meal) => meal['id'] == mealId);
    if (index != -1) {
      savedMeals[index] = {...updatedMeal, 'id': mealId};
      await prefs.setString(_savedMealsKey, jsonEncode(savedMeals));
    }
  }

  Future<void> addToRecentMeals(Map<String, dynamic> meal) async {
    final prefs = await SharedPreferences.getInstance();
    final recentMeals = await getRecentMeals();

    // Remove if already exists
    recentMeals.removeWhere((m) => m['name'] == meal['name']);

    // Add to front
    recentMeals.insert(0, meal);

    // Keep only last 10
    if (recentMeals.length > 10) {
      recentMeals.removeRange(10, recentMeals.length);
    }

    await prefs.setString(_recentMealsKey, jsonEncode(recentMeals));
  }

  Future<List<Map<String, dynamic>>> getRecentMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final recentMealsJson = prefs.getString(_recentMealsKey);

    if (recentMealsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(recentMealsJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMealsByCategory(String category) async {
    final savedMeals = await getSavedMeals();
    return savedMeals.where((meal) => meal['meal_type'] == category).toList();
  }

  Future<List<Map<String, dynamic>>> searchMeals(String query) async {
    final savedMeals = await getSavedMeals();
    return savedMeals.where((meal) {
      final name = (meal['name'] as String? ?? '').toLowerCase();
      final description = (meal['description'] as String? ?? '').toLowerCase();
      final tags = (meal['tags'] as List? ?? []).join(' ').toLowerCase();

      return name.contains(query.toLowerCase()) ||
          description.contains(query.toLowerCase()) ||
          tags.contains(query.toLowerCase());
    }).toList();
  }

  Future<void> logMeal(Map<String, dynamic> meal, String mealType) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final historyJson = prefs.getString(_mealHistoryKey) ?? '{}';
    final Map<String, dynamic> history = jsonDecode(historyJson);

    if (history[dateKey] == null) {
      history[dateKey] = {};
    }

    if (history[dateKey][mealType] == null) {
      history[dateKey][mealType] = [];
    }

    final logEntry = {
      ...meal,
      'logged_at': DateTime.now().toIso8601String(),
    };

    history[dateKey][mealType].add(logEntry);

    await prefs.setString(_mealHistoryKey, jsonEncode(history));
    await addToRecentMeals(meal);
  }

  Future<Map<String, dynamic>> getMealHistory(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_mealHistoryKey) ?? '{}';
    final Map<String, dynamic> history = jsonDecode(historyJson);

    return history[date] ?? {};
  }
}
