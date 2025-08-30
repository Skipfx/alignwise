-- Comprehensive test data for AlignWise wellness platform
-- This migration adds realistic test data to all existing tables for development and testing

-- Clean up existing test data first
DO $$
DECLARE
    test_user_ids UUID[];
BEGIN
    -- Get all test user IDs
    SELECT ARRAY_AGG(id) INTO test_user_ids
    FROM auth.users
    WHERE email LIKE '%@alignwise.test' OR email LIKE 'Mock-Email%';

    -- Delete dependent data in order (children first)
    DELETE FROM public.activity_reactions WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.activity_comments WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.challenge_participants WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.community_activities WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.community_challenges WHERE created_by = ANY(test_user_ids);
    DELETE FROM public.user_achievements WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.user_program_enrollments WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.workout_exercises WHERE workout_id IN (SELECT id FROM public.workouts WHERE user_id = ANY(test_user_ids));
    DELETE FROM public.workouts WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.meditations WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.meal_ingredients WHERE meal_id IN (SELECT id FROM public.meals WHERE user_id = ANY(test_user_ids));
    DELETE FROM public.meals WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.water_intake WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.user_goals WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.subscriptions WHERE customer_id IN (SELECT id FROM public.customers WHERE user_id = ANY(test_user_ids));
    DELETE FROM public.payment_methods WHERE customer_id IN (SELECT id FROM public.customers WHERE user_id = ANY(test_user_ids));
    DELETE FROM public.customers WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.fitness_programs WHERE created_by = ANY(test_user_ids);
    DELETE FROM public.user_profiles WHERE id = ANY(test_user_ids);
    DELETE FROM auth.users WHERE id = ANY(test_user_ids);
    
    RAISE NOTICE 'Cleaned up existing test data';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup error (this is normal on first run): %', SQLERRM;
END $$;

-- Generate comprehensive test data
DO $$
DECLARE
    -- Test user variables
    admin_id UUID := gen_random_uuid();
    premium_user_id UUID := gen_random_uuid();
    free_user_id UUID := gen_random_uuid();
    trainer_id UUID := gen_random_uuid();
    nutritionist_id UUID := gen_random_uuid();
    
    -- Program and template variables
    beginner_program_id UUID := gen_random_uuid();
    intermediate_program_id UUID := gen_random_uuid();
    advanced_program_id UUID := gen_random_uuid();
    
    -- Exercise and food variables
    pushup_exercise_id UUID := gen_random_uuid();
    squat_exercise_id UUID := gen_random_uuid();
    apple_food_id UUID := gen_random_uuid();
    chicken_food_id UUID := gen_random_uuid();
    rice_food_id UUID := gen_random_uuid();
    
    -- Meditation templates
    breathing_template_id UUID := gen_random_uuid();
    mindfulness_template_id UUID := gen_random_uuid();
    
    -- Achievement definitions
    first_workout_achievement_id UUID := gen_random_uuid();
    week_streak_achievement_id UUID := gen_random_uuid();
    nutrition_master_achievement_id UUID := gen_random_uuid();
    
    -- Challenge variables
    fitness_challenge_id UUID := gen_random_uuid();
    nutrition_challenge_id UUID := gen_random_uuid();
    
    -- Product variables
    premium_product_id UUID := gen_random_uuid();
    monthly_price_id UUID := gen_random_uuid();
    yearly_price_id UUID := gen_random_uuid();
    
BEGIN
    -- Create test auth users with complete field structure
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@alignwise.test', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (premium_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'premium@alignwise.test', crypt('premium123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Premium User", "role": "premium"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (free_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'free@alignwise.test', crypt('free123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Free User", "role": "free"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (trainer_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'trainer@alignwise.test', crypt('trainer123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Fitness Trainer", "role": "premium"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (nutritionist_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'nutritionist@alignwise.test', crypt('nutritionist123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Nutritionist Expert", "role": "premium"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create user profiles (trigger will handle this automatically, but we'll ensure they exist)
    INSERT INTO public.user_profiles (id, email, full_name, role, bio, avatar_url, is_active) VALUES
        (admin_id, 'admin@alignwise.test', 'Admin User', 'admin'::public.user_role, 'Platform administrator', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', true),
        (premium_user_id, 'premium@alignwise.test', 'Premium User', 'premium'::public.user_role, 'Fitness enthusiast and wellness advocate', 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150', true),
        (free_user_id, 'free@alignwise.test', 'Free User', 'free'::public.user_role, 'Just started my wellness journey', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150', true),
        (trainer_id, 'trainer@alignwise.test', 'Fitness Trainer', 'premium'::public.user_role, 'Certified fitness trainer with 10 years experience', 'https://images.unsplash.com/photo-1571019613914-85e59d379fc0?w=150', true),
        (nutritionist_id, 'nutritionist@alignwise.test', 'Nutritionist Expert', 'premium'::public.user_role, 'Registered dietitian specializing in sports nutrition', 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150', true)
    ON CONFLICT (id) DO UPDATE SET
        bio = EXCLUDED.bio,
        avatar_url = EXCLUDED.avatar_url;

    -- Create user goals
    INSERT INTO public.user_goals (user_id, goal_type, target_weight_kg, current_weight_kg, target_calories, target_protein, target_carbs, target_fat, target_water_ml, workouts_per_week, meditation_minutes_per_day, target_date, is_active) VALUES
        (premium_user_id, 'weight_loss'::public.goal_type, 70.0, 80.0, 1800, 120.0, 180.0, 50.0, 2500, 5, 15, '2024-06-01', true),
        (free_user_id, 'maintenance'::public.goal_type, 65.0, 65.0, 2000, 100.0, 250.0, 60.0, 2000, 3, 10, '2024-12-31', true),
        (trainer_id, 'muscle_gain'::public.goal_type, 85.0, 78.0, 2800, 180.0, 300.0, 80.0, 3000, 6, 20, '2024-08-01', true);

    -- Create exercise library
    INSERT INTO public.exercises (id, name, category, muscle_groups, difficulty_level, equipment_needed, instructions, video_url, calories_per_minute, is_premium) VALUES
        (pushup_exercise_id, 'Push-ups', 'strength', ARRAY['chest', 'shoulders', 'triceps'], 'beginner', ARRAY[], 'Start in plank position, lower body until chest nearly touches floor, push back up', 'https://example.com/pushup-video', 6, false),
        (squat_exercise_id, 'Squats', 'strength', ARRAY['quadriceps', 'glutes', 'hamstrings'], 'beginner', ARRAY[], 'Stand with feet shoulder-width apart, lower body as if sitting back in chair, return to start', 'https://example.com/squat-video', 8, false),
        (gen_random_uuid(), 'Deadlifts', 'strength', ARRAY['hamstrings', 'glutes', 'back'], 'intermediate', ARRAY['barbell'], 'Keep bar close to body, lift by extending hips and knees simultaneously', 'https://example.com/deadlift-video', 10, true),
        (gen_random_uuid(), 'Mountain Climbers', 'cardio', ARRAY['core', 'shoulders'], 'intermediate', ARRAY[], 'Start in plank, alternate bringing knees to chest rapidly', 'https://example.com/mountain-climbers-video', 12, false),
        (gen_random_uuid(), 'Burpees', 'cardio', ARRAY['full body'], 'advanced', ARRAY[], 'Squat down, jump back to plank, do push-up, jump feet to squat, jump up', 'https://example.com/burpees-video', 15, false);

    -- Create fitness programs
    INSERT INTO public.fitness_programs (id, name, description, difficulty, duration_weeks, workouts_per_week, created_by, program_data, is_premium, status) VALUES
        (beginner_program_id, 'Beginner Total Body', 'Perfect program for fitness beginners focusing on fundamental movements and building strength', 'beginner', 8, 3, trainer_id, '{"sessions": [{"name": "Upper Body", "exercises": ["push-ups", "dumbbell rows"]}, {"name": "Lower Body", "exercises": ["squats", "lunges"]}]}', false, 'active'),
        (intermediate_program_id, 'Intermediate Strength', 'Build muscle and strength with progressive overload techniques', 'intermediate', 12, 4, trainer_id, '{"sessions": [{"name": "Push Day", "exercises": ["bench press", "shoulder press"]}, {"name": "Pull Day", "exercises": ["deadlifts", "pull-ups"]}]}', true, 'active'),
        (advanced_program_id, 'Advanced Athletic Performance', 'High-intensity program for experienced athletes', 'advanced', 16, 5, trainer_id, '{"sessions": [{"name": "Power Training", "exercises": ["olympic lifts", "plyometrics"]}, {"name": "Strength Training", "exercises": ["heavy squats", "heavy deadlifts"]}]}', true, 'active');

    -- Create food items database
    INSERT INTO public.food_items (id, name, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, barcode) VALUES
        (apple_food_id, 'Apple', 'fruits', 52, 0.3, 14.0, 0.2, 2.4, 10.4, 1, '123456789'),
        (chicken_food_id, 'Chicken Breast (cooked)', 'protein', 165, 31.0, 0.0, 3.6, 0.0, 0.0, 74, '987654321'),
        (rice_food_id, 'Brown Rice (cooked)', 'grains', 123, 2.6, 25.0, 1.0, 1.8, 0.4, 10, '456789123'),
        (gen_random_uuid(), 'Salmon (cooked)', 'protein', 206, 22.0, 0.0, 12.0, 0.0, 0.0, 59, '789123456'),
        (gen_random_uuid(), 'Banana', 'fruits', 89, 1.1, 23.0, 0.3, 2.6, 12.0, 1, '321654987'),
        (gen_random_uuid(), 'Sweet Potato', 'vegetables', 86, 1.6, 20.0, 0.1, 3.0, 4.2, 54, '654987321'),
        (gen_random_uuid(), 'Greek Yogurt', 'dairy', 59, 10.0, 3.6, 0.4, 0.0, 3.6, 36, '147258369'),
        (gen_random_uuid(), 'Almonds', 'nuts', 579, 21.0, 22.0, 50.0, 12.0, 4.0, 1, '963852741'),
        (gen_random_uuid(), 'Spinach', 'vegetables', 23, 2.9, 3.6, 0.4, 2.2, 0.4, 79, '258741963'),
        (gen_random_uuid(), 'Oats', 'grains', 389, 17.0, 66.0, 7.0, 11.0, 1.0, 2, '741963258');

    -- Create sample meals
    INSERT INTO public.meals (user_id, meal_type, name, description, calories, protein, carbs, fat, fiber, photo_url, notes, meal_date, meal_time) VALUES
        (premium_user_id, 'breakfast'::public.meal_type, 'Power Breakfast', 'Greek yogurt with berries and granola', 320, 18.0, 42.0, 8.0, 6.0, 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400', 'Perfect start to the day', CURRENT_DATE, '07:30'),
        (premium_user_id, 'lunch'::public.meal_type, 'Grilled Chicken Salad', 'Mixed greens with grilled chicken and vinaigrette', 380, 35.0, 15.0, 18.0, 8.0, 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', 'Light and nutritious', CURRENT_DATE, '12:15'),
        (free_user_id, 'breakfast'::public.meal_type, 'Oatmeal Bowl', 'Steel cut oats with banana and honey', 280, 8.0, 58.0, 4.0, 8.0, 'https://images.unsplash.com/photo-1517909417274-7c5db8b0e191?w=400', 'Filling breakfast', CURRENT_DATE, '08:00'),
        (free_user_id, 'dinner'::public.meal_type, 'Salmon with Vegetables', 'Baked salmon with roasted sweet potatoes', 450, 32.0, 28.0, 22.0, 6.0, 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400', 'Omega-3 rich meal', CURRENT_DATE, '18:30');

    -- Create meal ingredients (linking meals to food items)
    INSERT INTO public.meal_ingredients (meal_id, food_item_id, quantity_grams) 
    SELECT m.id, apple_food_id, 100.0 
    FROM public.meals m WHERE m.name = 'Power Breakfast' LIMIT 1;
    
    INSERT INTO public.meal_ingredients (meal_id, food_item_id, quantity_grams) 
    SELECT m.id, chicken_food_id, 150.0 
    FROM public.meals m WHERE m.name = 'Grilled Chicken Salad' LIMIT 1;

    -- Create water intake records
    INSERT INTO public.water_intake (user_id, amount_ml, notes, intake_date, intake_time) VALUES
        (premium_user_id, 500, 'Morning hydration', CURRENT_DATE, '07:00'),
        (premium_user_id, 250, 'Pre-workout', CURRENT_DATE, '09:00'),
        (premium_user_id, 400, 'Post-workout', CURRENT_DATE, '10:30'),
        (free_user_id, 300, 'With breakfast', CURRENT_DATE, '08:00'),
        (free_user_id, 350, 'Afternoon water', CURRENT_DATE, '14:00');

    -- Create workouts
    INSERT INTO public.workouts (user_id, name, activity_type, status, duration_minutes, calories_burned, intensity, notes, workout_date, started_at, completed_at) VALUES
        (premium_user_id, 'Morning Strength Training', 'strength_training', 'completed'::public.workout_status, 45, 280, 'moderate'::public.workout_intensity, 'Great session, felt strong', CURRENT_DATE, CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '1 hour 15 minutes'),
        (premium_user_id, 'Cardio Session', 'cardio', 'completed'::public.workout_status, 30, 350, 'vigorous'::public.workout_intensity, 'High intensity interval training', CURRENT_DATE - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day 2 hours', CURRENT_TIMESTAMP - INTERVAL '1 day 1 hour 30 minutes'),
        (free_user_id, 'Beginner Workout', 'general_fitness', 'in_progress'::public.workout_status, null, null, 'light'::public.workout_intensity, 'Taking it easy', CURRENT_DATE, CURRENT_TIMESTAMP - INTERVAL '30 minutes', null);

    -- Create workout exercises
    INSERT INTO public.workout_exercises (workout_id, exercise_id, sets_completed, reps_per_set, weight_kg, rest_seconds, notes) 
    SELECT w.id, pushup_exercise_id, 3, ARRAY[12, 10, 8], null, 60, 'Getting stronger'
    FROM public.workouts w WHERE w.name = 'Morning Strength Training' LIMIT 1;
    
    INSERT INTO public.workout_exercises (workout_id, exercise_id, sets_completed, reps_per_set, weight_kg, rest_seconds, notes) 
    SELECT w.id, squat_exercise_id, 3, ARRAY[15, 15, 12], null, 90, 'Focus on form'
    FROM public.workouts w WHERE w.name = 'Morning Strength Training' LIMIT 1;

    -- Create meditation templates
    INSERT INTO public.meditation_templates (id, title, meditation_type, duration_minutes, description, audio_url, is_premium) VALUES
        (breathing_template_id, 'Basic Breathing', 'breathing'::public.meditation_type, 10, 'Simple breathing exercise for beginners', 'https://example.com/breathing-10min', false),
        (mindfulness_template_id, 'Mindful Awareness', 'mindfulness'::public.meditation_type, 15, 'Develop present moment awareness', 'https://example.com/mindfulness-15min', true),
        (gen_random_uuid(), 'Body Scan Relaxation', 'body_scan'::public.meditation_type, 20, 'Progressive muscle relaxation technique', 'https://example.com/bodyscan-20min', true),
        (gen_random_uuid(), 'Loving Kindness', 'loving_kindness'::public.meditation_type, 12, 'Cultivate compassion and goodwill', 'https://example.com/lovingkindness-12min', false),
        (gen_random_uuid(), 'Visualization Journey', 'visualization'::public.meditation_type, 18, 'Guided imagery for stress relief', 'https://example.com/visualization-18min', true);

    -- Create meditation sessions
    INSERT INTO public.meditations (user_id, template_id, meditation_type, title, duration_minutes, is_completed, guided_session_url, background_sound, mood_before, mood_after, notes, session_date, started_at, completed_at) VALUES
        (premium_user_id, breathing_template_id, 'breathing'::public.meditation_type, 'Morning Breathing', 10, true, 'https://example.com/breathing-10min', 'forest_sounds', 'anxious', 'calm', 'Really helped center me', CURRENT_DATE, CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '5 hours 50 minutes'),
        (free_user_id, mindfulness_template_id, 'mindfulness'::public.meditation_type, 'Evening Mindfulness', 15, true, 'https://example.com/mindfulness-15min', 'ocean_waves', 'stressed', 'peaceful', 'Exactly what I needed', CURRENT_DATE - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day 8 hours', CURRENT_TIMESTAMP - INTERVAL '1 day 7 hours 45 minutes');

    -- Create achievement definitions
    INSERT INTO public.achievement_definitions (id, title, description, badge_rarity, points_awarded, trigger_condition, target_value, target_unit, badge_image_url) VALUES
        (first_workout_achievement_id, 'First Steps', 'Complete your first workout', 'common'::public.badge_rarity, 10, 'workout_completed', 1, 'workout', 'https://images.unsplash.com/photo-1571019613914-85e59d379fc0?w=100'),
        (week_streak_achievement_id, 'Week Warrior', 'Complete workouts for 7 consecutive days', 'rare'::public.badge_rarity, 50, 'daily_workout_streak', 7, 'days', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=100'),
        (nutrition_master_achievement_id, 'Nutrition Master', 'Log meals for 30 consecutive days', 'epic'::public.badge_rarity, 100, 'daily_nutrition_streak', 30, 'days', 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=100'),
        (gen_random_uuid(), 'Hydration Hero', 'Drink 8 glasses of water in a day', 'common'::public.badge_rarity, 15, 'daily_water_goal', 8, 'glasses', 'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=100'),
        (gen_random_uuid(), 'Zen Master', 'Complete 100 meditation sessions', 'legendary'::public.badge_rarity, 200, 'meditation_sessions', 100, 'sessions', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=100');

    -- Create user achievements
    INSERT INTO public.user_achievements (user_id, achievement_definition_id, is_completed, progress_value, completed_at) VALUES
        (premium_user_id, first_workout_achievement_id, true, 1, CURRENT_TIMESTAMP - INTERVAL '1 week'),
        (premium_user_id, nutrition_master_achievement_id, false, 15, null),
        (free_user_id, first_workout_achievement_id, true, 1, CURRENT_TIMESTAMP - INTERVAL '3 days');

    -- Create program enrollments
    INSERT INTO public.user_program_enrollments (user_id, program_id, progress_percentage, current_week, is_active, enrolled_at) VALUES
        (premium_user_id, intermediate_program_id, 35.0, 3, true, CURRENT_TIMESTAMP - INTERVAL '3 weeks'),
        (free_user_id, beginner_program_id, 12.5, 1, true, CURRENT_TIMESTAMP - INTERVAL '1 week');

    -- Create community challenges
    INSERT INTO public.community_challenges (id, title, description, challenge_type, status, target_value, target_unit, start_date, end_date, created_by, participant_limit, reward_points, challenge_data) VALUES
        (fitness_challenge_id, '30-Day Fitness Challenge', 'Complete 30 workouts in 30 days', 'fitness'::public.challenge_type, 'active'::public.challenge_status, 30, 'workouts', CURRENT_DATE - INTERVAL '5 days', CURRENT_DATE + INTERVAL '25 days', trainer_id, 100, 150, '{"difficulty": "intermediate", "tracking": "workouts"}'),
        (nutrition_challenge_id, 'Healthy Eating Week', 'Log all meals for 7 consecutive days', 'nutrition'::public.challenge_type, 'active'::public.challenge_status, 7, 'days', CURRENT_DATE - INTERVAL '2 days', CURRENT_DATE + INTERVAL '5 days', nutritionist_id, 50, 75, '{"focus": "meal_logging", "bonus_points": {"vegetables": 5, "water": 3}}');

    -- Create challenge participants
    INSERT INTO public.challenge_participants (user_id, challenge_id, progress_value, joined_at, is_completed) VALUES
        (premium_user_id, fitness_challenge_id, 8, CURRENT_TIMESTAMP - INTERVAL '5 days', false),
        (free_user_id, nutrition_challenge_id, 3, CURRENT_TIMESTAMP - INTERVAL '2 days', false),
        (premium_user_id, nutrition_challenge_id, 5, CURRENT_TIMESTAMP - INTERVAL '2 days', false);

    -- Create community activities
    INSERT INTO public.community_activities (user_id, activity_type, title, description, activity_data, media_urls, visibility, tags) VALUES
        (premium_user_id, 'workout'::public.activity_type, 'Crushed leg day!', 'Just finished an intense leg workout. Feeling the burn but loving the progress!', '{"workout_duration": 45, "calories_burned": 380, "exercises": ["squats", "deadlifts", "lunges"]}', ARRAY['https://images.unsplash.com/photo-1571019613914-85e59d379fc0?w=400'], 'friends'::public.visibility_type, ARRAY['workout', 'legday', 'fitness']),
        (free_user_id, 'meal'::public.activity_type, 'Healthy breakfast prep', 'Meal prepped some overnight oats for the week. Ready to fuel my body right!', '{"meal_type": "breakfast", "calories": 320, "prep_time": 15}', ARRAY['https://images.unsplash.com/photo-1517909417274-7c5db8b0e191?w=400'], 'public'::public.visibility_type, ARRAY['mealprep', 'healthy', 'breakfast']),
        (trainer_id, 'achievement'::public.activity_type, 'New personal record!', 'Hit a new PR on deadlifts today - 200kg! Hard work paying off.', '{"achievement_type": "personal_record", "exercise": "deadlift", "weight": 200}', null, 'public'::public.visibility_type, ARRAY['pr', 'deadlift', 'strength']),
        (nutritionist_id, 'meditation'::public.activity_type, 'Morning mindfulness', 'Started the day with 20 minutes of meditation. Feeling centered and ready for anything.', '{"duration": 20, "type": "mindfulness", "mood_before": "tired", "mood_after": "energized"}', null, 'friends'::public.visibility_type, ARRAY['meditation', 'mindfulness', 'selfcare']);

    -- Create activity reactions
    INSERT INTO public.activity_reactions (activity_id, user_id, reaction_type) 
    SELECT ca.id, premium_user_id, 'like'::public.reaction_type
    FROM public.community_activities ca WHERE ca.title = 'Healthy breakfast prep' LIMIT 1;
    
    INSERT INTO public.activity_reactions (activity_id, user_id, reaction_type) 
    SELECT ca.id, free_user_id, 'fire'::public.reaction_type
    FROM public.community_activities ca WHERE ca.title = 'New personal record!' LIMIT 1;

    -- Create activity comments
    INSERT INTO public.activity_comments (activity_id, user_id, comment_text) 
    SELECT ca.id, free_user_id, 'Great work! Those look delicious and healthy.'
    FROM public.community_activities ca WHERE ca.title = 'Healthy breakfast prep' LIMIT 1;
    
    INSERT INTO public.activity_comments (activity_id, user_id, comment_text) 
    SELECT ca.id, premium_user_id, 'Incredible strength! What is your training routine?'
    FROM public.community_activities ca WHERE ca.title = 'New personal record!' LIMIT 1;

    -- Create Stripe products and prices
    INSERT INTO public.products (id, name, description, is_active, product_data) VALUES
        (premium_product_id, 'AlignWise Premium', 'Premium subscription with access to all features, personalized programs, and advanced analytics', true, '{"features": ["unlimited_programs", "ai_coaching", "advanced_analytics", "priority_support"]}');

    INSERT INTO public.prices (id, product_id, unit_amount, currency, interval_type, is_active, price_data) VALUES
        (monthly_price_id, premium_product_id, 999, 'aud', 'month', true, '{"billing_scheme": "per_unit", "tiers_mode": null}'),
        (yearly_price_id, premium_product_id, 7999, 'aud', 'year', true, '{"billing_scheme": "per_unit", "tiers_mode": null}');

    -- Create customers and subscriptions for premium users
    INSERT INTO public.customers (user_id, stripe_customer_id, email, customer_data) VALUES
        (premium_user_id, 'cus_test_premium_user', 'premium@alignwise.test', '{"name": "Premium User", "phone": null}');

    INSERT INTO public.subscriptions (customer_id, price_id, status, current_period_start, current_period_end, trial_end, stripe_subscription_id, subscription_data) VALUES
        ((SELECT id FROM public.customers WHERE user_id = premium_user_id), monthly_price_id, 'active'::public.subscription_status, CURRENT_TIMESTAMP - INTERVAL '15 days', CURRENT_TIMESTAMP + INTERVAL '15 days', null, 'sub_test_premium', '{"cancel_at_period_end": false, "latest_invoice": "in_test_premium"}');

    -- Create payment methods
    INSERT INTO public.payment_methods (customer_id, stripe_payment_method_id, payment_method_type, is_default, payment_method_data) VALUES
        ((SELECT id FROM public.customers WHERE user_id = premium_user_id), 'pm_test_card', 'card'::public.payment_method_type, true, '{"brand": "visa", "last4": "4242", "exp_month": 12, "exp_year": 2025}');

    RAISE NOTICE 'Successfully created comprehensive test data for AlignWise platform';
    RAISE NOTICE 'Test users created:';
    RAISE NOTICE '  - admin@alignwise.test (password: admin123)';
    RAISE NOTICE '  - premium@alignwise.test (password: premium123) - Has active subscription';
    RAISE NOTICE '  - free@alignwise.test (password: free123)';
    RAISE NOTICE '  - trainer@alignwise.test (password: trainer123)';
    RAISE NOTICE '  - nutritionist@alignwise.test (password: nutritionist123)';
    RAISE NOTICE 'Data includes: meals, workouts, meditations, achievements, challenges, community activities, and more';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating test data: %', SQLERRM;
        RAISE NOTICE 'Rolling back transaction...';
        RAISE;
END $$;

-- Create cleanup function for easy test data removal
CREATE OR REPLACE FUNCTION public.cleanup_alignwise_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    test_user_ids UUID[];
BEGIN
    -- Get all test user IDs
    SELECT ARRAY_AGG(id) INTO test_user_ids
    FROM auth.users
    WHERE email LIKE '%@alignwise.test';

    -- Delete in dependency order (children first, then parents)
    DELETE FROM public.activity_reactions WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.activity_comments WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.challenge_participants WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.community_activities WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.community_challenges WHERE created_by = ANY(test_user_ids);
    DELETE FROM public.user_achievements WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.user_program_enrollments WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.workout_exercises WHERE workout_id IN (SELECT id FROM public.workouts WHERE user_id = ANY(test_user_ids));
    DELETE FROM public.workouts WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.meditations WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.meal_ingredients WHERE meal_id IN (SELECT id FROM public.meals WHERE user_id = ANY(test_user_ids));
    DELETE FROM public.meals WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.water_intake WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.user_goals WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.subscriptions WHERE customer_id IN (SELECT id FROM public.customers WHERE user_id = ANY(test_user_ids));
    DELETE FROM public.payment_methods WHERE customer_id IN (SELECT id FROM public.customers WHERE user_id = ANY(test_user_ids));
    DELETE FROM public.customers WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.fitness_programs WHERE created_by = ANY(test_user_ids);
    DELETE FROM public.user_profiles WHERE id = ANY(test_user_ids);
    DELETE FROM auth.users WHERE id = ANY(test_user_ids);
    
    -- Clean up test data that doesn't depend on users
    DELETE FROM public.food_items WHERE barcode IN ('123456789', '987654321', '456789123', '789123456', '321654987', '654987321', '147258369', '963852741', '258741963', '741963258');
    DELETE FROM public.exercises WHERE name IN ('Push-ups', 'Squats', 'Deadlifts', 'Mountain Climbers', 'Burpees');
    DELETE FROM public.meditation_templates WHERE title IN ('Basic Breathing', 'Mindful Awareness', 'Body Scan Relaxation', 'Loving Kindness', 'Visualization Journey');
    DELETE FROM public.achievement_definitions WHERE title IN ('First Steps', 'Week Warrior', 'Nutrition Master', 'Hydration Hero', 'Zen Master');
    DELETE FROM public.prices WHERE product_id IN (SELECT id FROM public.products WHERE name = 'AlignWise Premium');
    DELETE FROM public.products WHERE name = 'AlignWise Premium';
    
    RAISE NOTICE 'Test data cleanup completed successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup error: %', SQLERRM;
END;
$$;

COMMENT ON FUNCTION public.cleanup_alignwise_test_data() IS 'Removes all test data from AlignWise platform. Call this function to clean up test users and associated data.';