import 'package:flutter/foundation.dart';

import './auth_service.dart';
import './supabase_service.dart';

class WellnessService {
  static WellnessService? _instance;

  WellnessService._();

  // Add public constructor for backwards compatibility
  factory WellnessService() => instance;

  static WellnessService get instance {
    _instance ??= WellnessService._();
    return _instance!;
  }

  final _supabaseService = SupabaseService.instance;
  final _authService = AuthService.instance;

  // Add missing methods for nutrition tracking
  Future<List<Map<String, dynamic>>> getMealsForToday() async {
    return getMeals(date: DateTime.now());
  }

  Future<int> getDailyWaterIntake() async {
    try {
      final waterEntries = await getWaterIntake(date: DateTime.now());
      return waterEntries.fold<int>(
          0, (sum, entry) => sum + (entry['amount_ml'] as int? ?? 0));
    } catch (error) {
      debugPrint('❌ Failed to get daily water intake: $error');
      return 0;
    }
  }

  Future<Map<String, dynamic>> getUserGoals() async {
    try {
      if (!_authService.isAuthenticated) {
        return {
          'daily_calories': 2000,
          'daily_protein': 150.0,
          'daily_carbs': 250.0,
          'daily_fat': 65.0,
          'daily_water_ml': 2000,
          'weekly_workouts': 3,
        };
      }

      final response = await _supabaseService.client
          .from('user_goals')
          .select()
          .eq('user_id', _authService.currentUserId!)
          .maybeSingle();

      if (response != null) {
        return Map<String, dynamic>.from(response);
      }

      // Return default goals if none set
      return {
        'daily_calories': 2000,
        'daily_protein': 150.0,
        'daily_carbs': 250.0,
        'daily_fat': 65.0,
        'daily_water_ml': 2000,
        'weekly_workouts': 3,
      };
    } catch (error) {
      debugPrint('❌ Failed to get user goals: $error');
      return {
        'daily_calories': 2000,
        'daily_protein': 150.0,
        'daily_carbs': 250.0,
        'daily_fat': 65.0,
        'daily_water_ml': 2000,
        'weekly_workouts': 3,
      };
    }
  }

  Future<Map<String, dynamic>> logMeal({
    required String mealType,
    required String name,
    String? description,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    double fiber = 0.0,
    String? photoUrl,
    String? aiAnalysis,
    String? notes,
  }) async {
    try {
      final response = await _supabaseService.addMeal(
        mealType: mealType,
        name: name,
        description: description,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        photoUrl: photoUrl,
        notes: notes != null && aiAnalysis != null
            ? '$notes\n\nAI Analysis: $aiAnalysis'
            : notes ?? aiAnalysis,
      );

      return response;
    } catch (error) {
      throw Exception('Failed to log meal: $error');
    }
  }

  Future<Map<String, dynamic>> logWater(int amountMl, {String? notes}) async {
    return logWaterIntake(amountMl, notes: notes);
  }

  // Add missing methods for fitness programs
  Future<List<Map<String, dynamic>>> getFitnessPrograms() async {
    try {
      final response = await _supabaseService.client
          .from('fitness_programs')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to get fitness programs: $error');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getActivePrograms() async {
    try {
      if (!_authService.isAuthenticated) {
        return [];
      }

      final response = await _supabaseService.client
          .from('user_program_enrollments')
          .select('''
            *,
            fitness_programs (
              id,
              name,
              description,
              duration_weeks,
              difficulty_level,
              program_type
            )
          ''')
          .eq('user_id', _authService.currentUserId!)
          .eq('is_active', true)
          .order('enrolled_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to get active programs: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>> getProgramStats() async {
    try {
      if (!_authService.isAuthenticated) {
        return {
          'total_programs': 0,
          'active_programs': 0,
          'completed_programs': 0,
          'total_workouts': 0,
        };
      }

      final response = await _supabaseService.client.rpc(
        'get_user_program_stats',
      );

      if (response != null && response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first);
      }

      return {
        'total_programs': 0,
        'active_programs': 0,
        'completed_programs': 0,
        'total_workouts': 0,
      };
    } catch (error) {
      debugPrint('❌ Failed to get program stats: $error');
      return {
        'total_programs': 0,
        'active_programs': 0,
        'completed_programs': 0,
        'total_workouts': 0,
      };
    }
  }

  // Add missing methods for achievements
  Future<List<Map<String, dynamic>>> getRecentAchievements() async {
    try {
      if (!_authService.isAuthenticated) {
        return [];
      }

      final response = await _supabaseService.client
          .from('user_achievements')
          .select('''
            *,
            achievement_definitions (
              title,
              description,
              badge_rarity,
              points_awarded
            )
          ''')
          .eq('user_id', _authService.currentUserId!)
          .eq('is_completed', true)
          .order('completed_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to get recent achievements: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>> getAchievementStats() async {
    return getAchievementSummary();
  }

  // NUTRITION METHODS
  Future<List<Map<String, dynamic>>> getMeals({
    String? mealType,
    DateTime? date,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      var query = _supabaseService.client
          .from('meals')
          .select()
          .eq('user_id', _authService.currentUserId!);

      if (mealType != null) {
        query = query.eq('meal_type', mealType);
      }

      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        query = query.eq('meal_date', dateStr);
      }

      final result = await query.order('meal_time', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (error) {
      debugPrint('❌ Failed to get meals: $error');
      throw Exception('Failed to get meals: $error');
    }
  }

  Future<Map<String, dynamic>> getDailyNutritionSummary({
    DateTime? date,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        return {
          'total_calories': 0,
          'total_protein': 0.0,
          'total_carbs': 0.0,
          'total_fat': 0.0,
          'total_fiber': 0.0,
          'meal_count': 0,
        };
      }

      final params = <String, dynamic>{};

      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        params['target_date'] = dateStr;
      }

      final response = await _supabaseService.client.rpc(
        'get_daily_nutrition_summary',
        params: params,
      );

      if (response != null && response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first);
      }

      return {
        'total_calories': 0,
        'total_protein': 0.0,
        'total_carbs': 0.0,
        'total_fat': 0.0,
        'total_fiber': 0.0,
        'meal_count': 0,
      };
    } catch (error) {
      debugPrint('❌ Failed to get nutrition summary: $error');
      return {
        'total_calories': 0,
        'total_protein': 0.0,
        'total_carbs': 0.0,
        'total_fat': 0.0,
        'total_fiber': 0.0,
        'meal_count': 0,
      };
    }
  }

  Future<Map<String, dynamic>> addMeal({
    required String mealType,
    required String name,
    String? description,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    double fiber = 0.0,
    String? photoUrl,
    String? notes,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.client
          .from('meals')
          .insert({
            'user_id': _authService.currentUserId,
            'meal_type': mealType,
            'name': name,
            'description': description,
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
            'fiber': fiber,
            'photo_url': photoUrl,
            'notes': notes,
            'meal_date': DateTime.now().toIso8601String().split('T')[0],
            'meal_time':
                DateTime.now().toIso8601String().split('T')[1].split('.')[0],
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to add meal: $error');
      throw Exception('Failed to add meal: $error');
    }
  }

  // FITNESS METHODS
  Future<List<Map<String, dynamic>>> getWorkouts({
    String? status,
    DateTime? date,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      var query = _supabaseService.client
          .from('workouts')
          .select()
          .eq('user_id', _authService.currentUserId!);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        query = query.eq('workout_date', dateStr);
      }

      final result = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (error) {
      debugPrint('❌ Failed to get workouts: $error');
      throw Exception('Failed to get workouts: $error');
    }
  }

  Future<Map<String, dynamic>> getWeeklyWorkoutStats({
    DateTime? startDate,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        return {
          'total_workouts': 0,
          'total_minutes': 0,
          'total_calories': 0,
          'completion_rate': 0.0,
        };
      }

      final params = <String, dynamic>{};

      if (startDate != null) {
        final startStr =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        params['start_date'] = startStr;
      }

      final response = await _supabaseService.client.rpc(
        'get_weekly_workout_stats',
        params: params,
      );

      if (response != null && response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first);
      }

      return {
        'total_workouts': 0,
        'total_minutes': 0,
        'total_calories': 0,
        'completion_rate': 0.0,
      };
    } catch (error) {
      debugPrint('❌ Failed to get workout stats: $error');
      return {
        'total_workouts': 0,
        'total_minutes': 0,
        'total_calories': 0,
        'completion_rate': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> createWorkout({
    required String name,
    required String activityType,
    String status = 'planned',
    int? durationMinutes,
    int? caloriesBurned,
    String intensity = 'moderate',
    String? notes,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.client
          .from('workouts')
          .insert({
            'user_id': _authService.currentUserId,
            'name': name,
            'activity_type': activityType,
            'status': status,
            'duration_minutes': durationMinutes,
            'calories_burned': caloriesBurned,
            'intensity': intensity,
            'notes': notes,
            'workout_date': DateTime.now().toIso8601String().split('T')[0],
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to create workout: $error');
      throw Exception('Failed to create workout: $error');
    }
  }

  // MINDFULNESS METHODS
  Future<List<Map<String, dynamic>>> getMeditations({
    String? meditationType,
    DateTime? date,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      var query = _supabaseService.client
          .from('meditations')
          .select()
          .eq('user_id', _authService.currentUserId!);

      if (meditationType != null) {
        query = query.eq('meditation_type', meditationType);
      }

      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        query = query.eq('session_date', dateStr);
      }

      final result = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (error) {
      debugPrint('❌ Failed to get meditations: $error');
      throw Exception('Failed to get meditations: $error');
    }
  }

  Future<Map<String, dynamic>> startMeditationSession({
    required String meditationType,
    required String title,
    required int durationMinutes,
    String? guidedSessionUrl,
    String? backgroundSound,
    String? moodBefore,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.client
          .from('meditations')
          .insert({
            'user_id': _authService.currentUserId,
            'meditation_type': meditationType,
            'title': title,
            'duration_minutes': durationMinutes,
            'guided_session_url': guidedSessionUrl,
            'background_sound': backgroundSound,
            'mood_before': moodBefore,
            'session_date': DateTime.now().toIso8601String().split('T')[0],
            'started_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to start meditation: $error');
      throw Exception('Failed to start meditation: $error');
    }
  }

  // WATER INTAKE METHODS
  Future<List<Map<String, dynamic>>> getWaterIntake({
    DateTime? date,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      var query = _supabaseService.client
          .from('water_intake')
          .select()
          .eq('user_id', _authService.currentUserId!);

      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        query = query.eq('intake_date', dateStr);
      }

      final result = await query.order('intake_time', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (error) {
      debugPrint('❌ Failed to get water intake: $error');
      throw Exception('Failed to get water intake: $error');
    }
  }

  Future<Map<String, dynamic>> logWaterIntake(
    int amountMl, {
    String? notes,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.client
          .from('water_intake')
          .insert({
            'user_id': _authService.currentUserId,
            'amount_ml': amountMl,
            'notes': notes,
            'intake_date': DateTime.now().toIso8601String().split('T')[0],
            'intake_time':
                DateTime.now().toIso8601String().split('T')[1].split('.')[0],
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to log water intake: $error');
      throw Exception('Failed to log water intake: $error');
    }
  }

  // COMMUNITY METHODS
  Future<List<Map<String, dynamic>>> getCommunityFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabaseService.client.rpc(
        'get_community_feed',
        params: {
          'feed_limit': limit,
          'offset_count': offset,
        },
      );

      if (response != null) {
        return List<Map<String, dynamic>>.from(response);
      }

      return [];
    } catch (error) {
      debugPrint('❌ Failed to get community feed: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>> createActivity({
    required String activityType,
    required String title,
    String? description,
    Map<String, dynamic>? activityData,
    List<String>? mediaUrls,
    String visibility = 'friends',
    List<String>? tags,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.client
          .from('community_activities')
          .insert({
            'user_id': _authService.currentUserId,
            'activity_type': activityType,
            'title': title,
            'description': description,
            'activity_data': activityData,
            'media_urls': mediaUrls,
            'visibility': visibility,
            'tags': tags,
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to create activity: $error');
      throw Exception('Failed to create activity: $error');
    }
  }

  // ACHIEVEMENT METHODS
  Future<List<Map<String, dynamic>>> getUserAchievements({
    bool? isCompleted,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      var query = _supabaseService.client.from('user_achievements').select('''
            *,
            achievement_definitions (
              title,
              description,
              badge_rarity,
              points_awarded,
              target_value,
              target_unit
            )
          ''').eq('user_id', _authService.currentUserId!);

      if (isCompleted != null) {
        query = query.eq('is_completed', isCompleted);
      }

      final result = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (error) {
      debugPrint('❌ Failed to get achievements: $error');
      throw Exception('Failed to get achievements: $error');
    }
  }

  Future<Map<String, dynamic>> getAchievementSummary() async {
    try {
      if (!_authService.isAuthenticated) {
        return {
          'total_achievements': 0,
          'completed_achievements': 0,
          'completion_percentage': 0.0,
          'total_points': 0,
          'recent_achievements': [],
        };
      }

      final response = await _supabaseService.client.rpc(
        'get_user_achievement_summary',
      );

      if (response != null && response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first);
      }

      return {
        'total_achievements': 0,
        'completed_achievements': 0,
        'completion_percentage': 0.0,
        'total_points': 0,
        'recent_achievements': [],
      };
    } catch (error) {
      debugPrint('❌ Failed to get achievement summary: $error');
      return {
        'total_achievements': 0,
        'completion_percentage': 0.0,
        'total_points': 0,
        'recent_achievements': [],
      };
    }
  }

  // UTILITY METHODS
  Future<bool> isPremiumUser() async {
    return await _authService.isPremiumUser();
  }

  Future<bool> isInTrial() async {
    return await _authService.isInTrial();
  }

  // FOOD SEARCH METHODS
  Future<List<Map<String, dynamic>>> searchFoodItems(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      // Search in the food_database table for matching food items
      final response = await _supabaseService.client
          .from('food_database')
          .select('*')
          .or('name.ilike.%$query%,brand.ilike.%$query%')
          .limit(20)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to search food items: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getFoodItemById(String foodId) async {
    try {
      final response = await _supabaseService.client
          .from('food_database')
          .select('*')
          .eq('id', foodId)
          .maybeSingle();

      if (response != null) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (error) {
      debugPrint('❌ Failed to get food item by ID: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPopularFoods({int limit = 10}) async {
    try {
      final response = await _supabaseService.client
          .from('food_database')
          .select('*')
          .eq('is_popular', true)
          .limit(limit)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to get popular foods: $error');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFoodsByCategory(String category) async {
    try {
      final response = await _supabaseService.client
          .from('food_database')
          .select('*')
          .eq('category', category)
          .limit(50)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to get foods by category: $error');
      return [];
    }
  }
}
