import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
          'Supabase client not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static Future<void> initialize(
      String supabaseUrl, String supabaseAnonKey) async {
    try {
      // Initialize Supabase with proper configuration including redirect URLs
      await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
          authOptions: FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
            // Configure redirect URLs for email verification and password reset
          ),
          realtimeClientOptions:
              const RealtimeClientOptions(logLevel: RealtimeLogLevel.info),
          storageOptions: const StorageClientOptions(retryAttempts: 10));
      _client = Supabase.instance.client;
      debugPrint('✅ SupabaseService initialized successfully');
    } catch (error) {
      debugPrint('❌ SupabaseService initialization failed: $error');
      throw Exception('SupabaseService initialization failed: $error');
    }
  }

  // Authentication Helper Methods
  bool get isSignedIn => _client?.auth.currentUser != null;

  User? get currentUser => _client?.auth.currentUser;

  // Enhanced password reset with proper redirect URL
  Future<void> resetPassword(String email) async {
    try {
      await _client!.auth.resetPasswordForEmail(email,
          redirectTo: kIsWeb
              ? 'https://your-app-domain.com/auth/reset-password'
              : 'io.supabase.alignwise://auth/reset-password');
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  // Enhanced sign up with email confirmation redirect
  Future<AuthResponse> signUp(
      String email, String password, String fullName) async {
    try {
      final response = await _client!.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': 'free',
          },
          emailRedirectTo: kIsWeb
              ? 'https://your-app-domain.com/auth/confirm'
              : 'io.supabase.alignwise://auth/confirm');

      if (response.user != null && response.user!.emailConfirmedAt == null) {
        debugPrint(
            '📧 Email confirmation required for: ${response.user!.email}');
      }

      if (response.user != null) {
        // Create user profile
        await _createUserProfile(response.user!, fullName: fullName);
      }

      return response;
    } catch (error) {
      throw Exception('Sign-up failed: $error');
    }
  }

  // Enhanced sign in with email verification check
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _client!.auth
          .signInWithPassword(email: email, password: password);

      // Check if email is confirmed
      if (response.user != null && response.user!.emailConfirmedAt == null) {
        throw Exception(
            'Email not verified. Please check your email and click the verification link.');
      }

      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  // Resend email confirmation
  Future<void> resendEmailConfirmation(String email) async {
    try {
      await _client!.auth.resend(
          type: OtpType.signup,
          email: email,
          emailRedirectTo: kIsWeb
              ? 'https://your-app-domain.com/auth/confirm'
              : 'io.supabase.alignwise://auth/confirm');
      debugPrint('✅ Email confirmation resent');
    } catch (error) {
      throw Exception('Failed to resend confirmation: $error');
    }
  }

  // Check if user's email is verified
  bool get isEmailVerified =>
      _client?.auth.currentUser?.emailConfirmedAt != null;

  // Authentication Methods
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final success = await _client!.auth.signInWithOAuth(OAuthProvider.google);
      if (success) {
        // Return a mock AuthResponse-like structure since OAuth returns bool
        return AuthResponse(
          session: _client!.auth.currentSession,
          user: _client!.auth.currentUser,
        );
      }
      return null;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  Future<AuthResponse?> signInWithFacebook() async {
    try {
      final success =
          await _client!.auth.signInWithOAuth(OAuthProvider.facebook);
      if (success) {
        // Return a mock AuthResponse-like structure since OAuth returns bool
        return AuthResponse(
          session: _client!.auth.currentSession,
          user: _client!.auth.currentUser,
        );
      }
      return null;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  Future<void> signOut() async {
    try {
      await _client!.auth.signOut();
    } catch (error) {
      throw Exception('Sign-out failed: $error');
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile(User user, {String? fullName}) async {
    try {
      await _client!.from('user_profiles').insert({
        'id': user.id,
        'email': user.email,
        'full_name': fullName ?? user.userMetadata?['full_name'] ?? '',
        'avatar_url': user.userMetadata?['avatar_url'],
        'role': 'free',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Profile might already exist, which is fine
      debugPrint('Profile creation note: $e');
    }
  }

  // Nutrition Tracking Methods
  Future<List<dynamic>> getMeals({String? mealType, DateTime? date}) async {
    try {
      var query = _client!.from('meals').select();

      if (mealType != null) {
        query = query.eq('meal_type', mealType);
      }

      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        query = query.eq('meal_date', dateStr);
      }

      return await query.order('meal_time', ascending: false);
    } catch (error) {
      throw Exception('Failed to get meals: $error');
    }
  }

  Future<Map<String, dynamic>> getDailyNutritionSummary(
      {DateTime? date}) async {
    try {
      final params = <String, dynamic>{};

      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        params['target_date'] = dateStr;
      }

      final response =
          await _client!.rpc('get_daily_nutrition_summary', params: params);

      if (response != null && response is List && response.isNotEmpty) {
        return response.first ??
            {
              'total_calories': 0,
              'total_protein': 0.0,
              'total_carbs': 0.0,
              'total_fat': 0.0,
              'total_fiber': 0.0,
              'meal_count': 0,
            };
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
      debugPrint('Failed to get nutrition summary: $error');
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

  Future<List<dynamic>> searchFoodItems(String query) async {
    try {
      return await _client!
          .from('food_items')
          .select()
          .ilike('name', '%$query%')
          .limit(20);
    } catch (error) {
      throw Exception('Failed to search food items: $error');
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
      final response = await _client!
          .from('meals')
          .insert({
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
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to add meal: $error');
    }
  }

  // Fitness Tracking Methods
  Future<List<dynamic>> getWorkouts({String? status, DateTime? date}) async {
    try {
      var query = _client!.from('workouts').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        query = query.eq('workout_date', dateStr);
      }

      return await query.order('created_at', ascending: false);
    } catch (error) {
      throw Exception('Failed to get workouts: $error');
    }
  }

  Future<Map<String, dynamic>> getWeeklyWorkoutStats(
      {DateTime? startDate}) async {
    try {
      final params = <String, dynamic>{};

      if (startDate != null) {
        final startStr =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        params['start_date'] = startStr;
      }

      final response =
          await _client!.rpc('get_weekly_workout_stats', params: params);

      if (response != null && response is List && response.isNotEmpty) {
        return response.first ??
            {
              'total_workouts': 0,
              'total_minutes': 0,
              'total_calories': 0,
              'completion_rate': 0.0,
            };
      }

      return {
        'total_workouts': 0,
        'total_minutes': 0,
        'total_calories': 0,
        'completion_rate': 0.0,
      };
    } catch (error) {
      debugPrint('Failed to get workout stats: $error');
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
      final response = await _client!
          .from('workouts')
          .insert({
            'name': name,
            'activity_type': activityType,
            'status': status,
            'duration_minutes': durationMinutes,
            'calories_burned': caloriesBurned,
            'intensity': intensity,
            'notes': notes,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create workout: $error');
    }
  }

  Future<Map<String, dynamic>> updateWorkoutStatus(
      String workoutId, String status) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
      };

      if (status == 'in_progress') {
        updates['started_at'] = DateTime.now().toIso8601String();
      } else if (status == 'completed') {
        updates['completed_at'] = DateTime.now().toIso8601String();
      }

      final response = await _client!
          .from('workouts')
          .update(updates)
          .eq('id', workoutId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update workout: $error');
    }
  }

  // Fitness Programs Methods
  Future<List<dynamic>> getFitnessPrograms(
      {String? difficulty, bool? isPremium}) async {
    try {
      var query = _client!.from('fitness_programs').select();

      query = query.eq('status', 'active');

      if (difficulty != null) {
        query = query.eq('difficulty', difficulty);
      }

      if (isPremium != null) {
        query = query.eq('is_premium', isPremium);
      }

      return await query.order('created_at', ascending: false);
    } catch (error) {
      throw Exception('Failed to get fitness programs: $error');
    }
  }

  Future<Map<String, dynamic>> enrollInProgram(String programId) async {
    try {
      final response = await _client!
          .from('user_program_enrollments')
          .insert({
            'program_id': programId,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to enroll in program: $error');
    }
  }

  Future<List<dynamic>> getUserProgramProgress() async {
    try {
      final response = await _client!.rpc('get_user_program_progress');
      return response ?? [];
    } catch (error) {
      debugPrint('Failed to get program progress: $error');
      return [];
    }
  }

  // Mindfulness & Meditation Methods
  Future<List<dynamic>> getMeditations(
      {String? meditationType, DateTime? date}) async {
    try {
      var query = _client!.from('meditations').select();

      if (meditationType != null) {
        query = query.eq('meditation_type', meditationType);
      }

      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        query = query.eq('session_date', dateStr);
      }

      return await query.order('created_at', ascending: false);
    } catch (error) {
      throw Exception('Failed to get meditations: $error');
    }
  }

  Future<List<dynamic>> getMeditationTemplates({String? meditationType}) async {
    try {
      var query = _client!.from('meditation_templates').select();

      if (meditationType != null) {
        query = query.eq('meditation_type', meditationType);
      }

      return await query.order('duration_minutes', ascending: true);
    } catch (error) {
      throw Exception('Failed to get meditation templates: $error');
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
      final response = await _client!
          .from('meditations')
          .insert({
            'meditation_type': meditationType,
            'title': title,
            'duration_minutes': durationMinutes,
            'guided_session_url': guidedSessionUrl,
            'background_sound': backgroundSound,
            'mood_before': moodBefore,
            'started_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to start meditation: $error');
    }
  }

  Future<Map<String, dynamic>> completeMeditationSession({
    required String meditationId,
    String? moodAfter,
    String? notes,
  }) async {
    try {
      final response = await _client!
          .from('meditations')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
            'mood_after': moodAfter,
            'notes': notes,
          })
          .eq('id', meditationId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to complete meditation: $error');
    }
  }

  // Achievement System Methods
  Future<List<dynamic>> getUserAchievements({bool? isCompleted}) async {
    try {
      var query = _client!.from('user_achievements').select('''
            *,
            achievement_definitions (
              title,
              description,
              badge_rarity,
              points_awarded,
              target_value,
              target_unit
            )
          ''');

      if (isCompleted != null) {
        query = query.eq('is_completed', isCompleted);
      }

      final result = await query.order('created_at', ascending: false);
      return result;
    } catch (error) {
      throw Exception('Failed to get achievements: $error');
    }
  }

  Future<Map<String, dynamic>> getAchievementSummary() async {
    try {
      final response = await _client!.rpc('get_user_achievement_summary');

      if (response != null && response is List && response.isNotEmpty) {
        return response.first ??
            {
              'total_achievements': 0,
              'completed_achievements': 0,
              'completion_percentage': 0.0,
              'total_points': 0,
              'recent_achievements': [],
            };
      }

      return {
        'total_achievements': 0,
        'completed_achievements': 0,
        'completion_percentage': 0.0,
        'total_points': 0,
        'recent_achievements': [],
      };
    } catch (error) {
      debugPrint('Failed to get achievement summary: $error');
      return {
        'total_achievements': 0,
        'completed_achievements': 0,
        'completion_percentage': 0.0,
        'total_points': 0,
        'recent_achievements': [],
      };
    }
  }

  // Community Feed Methods
  Future<List<dynamic>> getCommunityFeed(
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _client!.rpc('get_community_feed', params: {
        'feed_limit': limit,
        'offset_count': offset,
      });
      return response ?? [];
    } catch (error) {
      debugPrint('Failed to get community feed: $error');
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
      final response = await _client!
          .from('community_activities')
          .insert({
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

      return response;
    } catch (error) {
      throw Exception('Failed to create activity: $error');
    }
  }

  Future<void> reactToActivity(String activityId, String reactionType) async {
    try {
      await _client!.from('activity_reactions').upsert({
        'activity_id': activityId,
        'reaction_type': reactionType,
      });
    } catch (error) {
      throw Exception('Failed to react to activity: $error');
    }
  }

  Future<Map<String, dynamic>> addComment(String activityId, String commentText,
      {String? parentCommentId}) async {
    try {
      final response = await _client!
          .from('activity_comments')
          .insert({
            'activity_id': activityId,
            'comment_text': commentText,
            'parent_comment_id': parentCommentId,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to add comment: $error');
    }
  }

  // Water Intake Methods
  Future<List<dynamic>> getWaterIntake({DateTime? date}) async {
    try {
      var query = _client!.from('water_intake').select();

      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        query = query.eq('intake_date', dateStr);
      }

      return await query.order('intake_time', ascending: false);
    } catch (error) {
      throw Exception('Failed to get water intake: $error');
    }
  }

  Future<Map<String, dynamic>> logWaterIntake(int amountMl,
      {String? notes}) async {
    try {
      final response = await _client!
          .from('water_intake')
          .insert({
            'amount_ml': amountMl,
            'notes': notes,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to log water intake: $error');
    }
  }

  // User Goals Methods
  Future<List<dynamic>> getUserGoals({bool? isActive}) async {
    try {
      var query = _client!.from('user_goals').select();

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      return await query.order('created_at', ascending: false);
    } catch (error) {
      throw Exception('Failed to get user goals: $error');
    }
  }

  Future<Map<String, dynamic>> createOrUpdateGoal({
    required String goalType,
    double? targetWeightKg,
    double? currentWeightKg,
    int? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    int targetWaterMl = 2000,
    int workoutsPerWeek = 3,
    int meditationMinutesPerDay = 10,
    DateTime? targetDate,
  }) async {
    try {
      final response = await _client!
          .from('user_goals')
          .upsert({
            'goal_type': goalType,
            'target_weight_kg': targetWeightKg,
            'current_weight_kg': currentWeightKg,
            'target_calories': targetCalories,
            'target_protein': targetProtein,
            'target_carbs': targetCarbs,
            'target_fat': targetFat,
            'target_water_ml': targetWaterMl,
            'workouts_per_week': workoutsPerWeek,
            'meditation_minutes_per_day': meditationMinutesPerDay,
            'target_date': targetDate?.toIso8601String().split('T')[0],
            'is_active': true,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to save goal: $error');
    }
  }

  // Challenge Methods
  Future<List<dynamic>> getChallenges(
      {String? challengeType, String? status}) async {
    try {
      var query = _client!.from('community_challenges').select();

      if (challengeType != null) {
        query = query.eq('challenge_type', challengeType);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      return await query.order('created_at', ascending: false);
    } catch (error) {
      throw Exception('Failed to get challenges: $error');
    }
  }

  Future<Map<String, dynamic>> joinChallenge(String challengeId) async {
    try {
      final response = await _client!
          .from('challenge_participants')
          .insert({
            'challenge_id': challengeId,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to join challenge: $error');
    }
  }

  // Utility Methods
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final userId = _client!.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      final response = await _client!
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  Future<bool> isPremiumUser() async {
    try {
      final response = await _client!.rpc('is_premium_user');
      return response == true;
    } catch (error) {
      return false;
    }
  }

  // Real-time subscriptions
  RealtimeChannel subscribeToTable(
      String tableName, void Function(dynamic) callback) {
    return _client!.channel('public:$tableName').onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: tableName,
        callback: callback);
  }
}
