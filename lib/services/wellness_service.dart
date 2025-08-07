import './supabase_service.dart';

class WellnessService {
  static final _instance = WellnessService._internal();
  factory WellnessService() => _instance;
  WellnessService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;

  // Nutrition Methods
  Future<Map<String, dynamic>> getTodayNutrition() async {
    try {
      return await _supabaseService.getDailyNutritionSummary();
    } catch (e) {
      throw Exception('Failed to get nutrition data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMealsForToday() async {
    try {
      final meals = await _supabaseService.getMeals(date: DateTime.now());
      return List<Map<String, dynamic>>.from(meals);
    } catch (e) {
      throw Exception('Failed to get meals: $e');
    }
  }

  Future<void> logMeal({
    required String mealType,
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    try {
      await _supabaseService.addMeal(
        mealType: mealType,
        name: name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
    } catch (e) {
      throw Exception('Failed to log meal: $e');
    }
  }

  // Fitness Methods
  Future<Map<String, dynamic>> getWeeklyFitnessStats() async {
    try {
      return await _supabaseService.getWeeklyWorkoutStats();
    } catch (e) {
      throw Exception('Failed to get fitness stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentWorkouts({int limit = 5}) async {
    try {
      final workouts = await _supabaseService.getWorkouts();
      final recentWorkouts = List<Map<String, dynamic>>.from(workouts);
      return recentWorkouts.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get workouts: $e');
    }
  }

  Future<void> startWorkout({
    required String name,
    required String activityType,
    String intensity = 'moderate',
  }) async {
    try {
      await _supabaseService.createWorkout(
        name: name,
        activityType: activityType,
        status: 'in_progress',
        intensity: intensity,
      );
    } catch (e) {
      throw Exception('Failed to start workout: $e');
    }
  }

  // Water Intake Methods
  Future<int> getTodayWaterIntake() async {
    try {
      final waterIntakes =
          await _supabaseService.getWaterIntake(date: DateTime.now());
      int totalMl = 0;
      for (var intake in waterIntakes) {
        totalMl += (intake['amount_ml'] as int? ?? 0);
      }
      return totalMl;
    } catch (e) {
      throw Exception('Failed to get water intake: $e');
    }
  }

  Future<void> logWater(int amountMl) async {
    try {
      await _supabaseService.logWaterIntake(amountMl);
    } catch (e) {
      throw Exception('Failed to log water: $e');
    }
  }

  // Mindfulness Methods
  Future<List<Map<String, dynamic>>> getMeditationTemplates(
      {String? type}) async {
    try {
      final templates =
          await _supabaseService.getMeditationTemplates(meditationType: type);
      return List<Map<String, dynamic>>.from(templates);
    } catch (e) {
      throw Exception('Failed to get meditation templates: $e');
    }
  }

  Future<void> startMeditation({
    required String type,
    required String title,
    required int duration,
    String? backgroundSound,
  }) async {
    try {
      await _supabaseService.startMeditationSession(
        meditationType: type,
        title: title,
        durationMinutes: duration,
        backgroundSound: backgroundSound,
      );
    } catch (e) {
      throw Exception('Failed to start meditation: $e');
    }
  }

  // Achievement Methods
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    try {
      final achievements = await _supabaseService.getUserAchievements();
      return List<Map<String, dynamic>>.from(achievements);
    } catch (e) {
      throw Exception('Failed to get achievements: $e');
    }
  }

  Future<Map<String, dynamic>> getAchievementProgress() async {
    try {
      return await _supabaseService.getAchievementSummary();
    } catch (e) {
      throw Exception('Failed to get achievement progress: $e');
    }
  }

  // Community Methods
  Future<List<Map<String, dynamic>>> getCommunityFeed() async {
    try {
      final feed = await _supabaseService.getCommunityFeed();
      return List<Map<String, dynamic>>.from(feed);
    } catch (e) {
      throw Exception('Failed to get community feed: $e');
    }
  }

  Future<void> shareActivity({
    required String type,
    required String title,
    String? description,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabaseService.createActivity(
        activityType: type,
        title: title,
        description: description,
        activityData: data,
      );
    } catch (e) {
      throw Exception('Failed to share activity: $e');
    }
  }

  // Goals Methods
  Future<Map<String, dynamic>?> getCurrentGoals() async {
    try {
      final goals = await _supabaseService.getUserGoals(isActive: true);
      return goals.isNotEmpty ? Map<String, dynamic>.from(goals.first) : null;
    } catch (e) {
      throw Exception('Failed to get goals: $e');
    }
  }

  Future<void> updateGoals({
    required String goalType,
    double? targetWeight,
    double? currentWeight,
    int? targetCalories,
    int? targetWater,
  }) async {
    try {
      await _supabaseService.createOrUpdateGoal(
        goalType: goalType,
        targetWeightKg: targetWeight,
        currentWeightKg: currentWeight,
        targetCalories: targetCalories,
        targetWaterMl: targetWater ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to update goals: $e');
    }
  }

  // Fitness Programs Methods
  Future<List<Map<String, dynamic>>> getFitnessPrograms() async {
    try {
      final programs = await _supabaseService.getFitnessPrograms();
      return List<Map<String, dynamic>>.from(programs);
    } catch (e) {
      throw Exception('Failed to get fitness programs: $e');
    }
  }

  Future<void> enrollInProgram(String programId) async {
    try {
      await _supabaseService.enrollInProgram(programId);
    } catch (e) {
      throw Exception('Failed to enroll in program: $e');
    }
  }

  // Challenge Methods
  Future<List<Map<String, dynamic>>> getActiveChallenges() async {
    try {
      final challenges = await _supabaseService.getChallenges(status: 'active');
      return List<Map<String, dynamic>>.from(challenges);
    } catch (e) {
      throw Exception('Failed to get challenges: $e');
    }
  }

  Future<void> joinChallenge(String challengeId) async {
    try {
      await _supabaseService.joinChallenge(challengeId);
    } catch (e) {
      throw Exception('Failed to join challenge: $e');
    }
  }

  // User Profile Methods
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      return await _supabaseService.getUserProfile();
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<bool> isPremium() async {
    try {
      return await _supabaseService.isPremiumUser();
    } catch (e) {
      return false;
    }
  }
}