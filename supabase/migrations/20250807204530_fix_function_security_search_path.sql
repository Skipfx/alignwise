-- Fix Function Search Path Security Issues
-- All functions must include SET search_path = '' for security compliance
-- This migration updates all functions to have immutable search_path

-- 1. Fix get_daily_nutrition_summary function
CREATE OR REPLACE FUNCTION public.get_daily_nutrition_summary(target_date text DEFAULT NULL::text)
RETURNS TABLE(total_calories bigint, total_protein numeric, total_carbs numeric, total_fat numeric, total_fiber numeric, meal_count bigint)
LANGUAGE sql
STABLE 
SECURITY DEFINER
SET search_path = ''
AS $$
SELECT
    COALESCE(SUM(m.calories), 0) as total_calories,
    COALESCE(SUM(m.protein), 0) as total_protein,
    COALESCE(SUM(m.carbs), 0) as total_carbs,
    COALESCE(SUM(m.fat), 0) as total_fat,
    COALESCE(SUM(m.fiber), 0) as total_fiber,
    COUNT(*) as meal_count
FROM public.meals m
WHERE m.user_id = auth.uid()
    AND (target_date IS NULL OR m.meal_date = target_date::DATE);
$$;

-- 2. Fix get_weekly_workout_stats function
CREATE OR REPLACE FUNCTION public.get_weekly_workout_stats(start_date text DEFAULT NULL::text)
RETURNS TABLE(total_workouts bigint, total_minutes bigint, total_calories bigint, completion_rate numeric)
LANGUAGE sql
STABLE 
SECURITY DEFINER
SET search_path = ''
AS $$
WITH date_range AS (
    SELECT 
        COALESCE(start_date::DATE, CURRENT_DATE - INTERVAL '7 days') as start_dt,
        CURRENT_DATE as end_dt
),
workout_stats AS (
    SELECT 
        COUNT(*) as total_workouts,
        COALESCE(SUM(duration_minutes), 0) as total_minutes,
        COALESCE(SUM(calories_burned), 0) as total_calories,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_workouts
    FROM public.workouts w, date_range dr
    WHERE w.user_id = auth.uid()
        AND w.workout_date BETWEEN dr.start_dt AND dr.end_dt
)
SELECT 
    ws.total_workouts,
    ws.total_minutes,
    ws.total_calories,
    CASE 
        WHEN ws.total_workouts > 0 THEN 
            ROUND((ws.completed_workouts * 100.0 / ws.total_workouts), 2)
        ELSE 0
    END as completion_rate
FROM workout_stats ws;
$$;

-- 3. Fix get_user_program_progress function
CREATE OR REPLACE FUNCTION public.get_user_program_progress()
RETURNS TABLE(program_id uuid, program_name text, completion_percentage numeric, current_week integer, total_weeks integer)
LANGUAGE sql
STABLE 
SECURITY DEFINER
SET search_path = ''
AS $$
SELECT 
    upe.program_id,
    fp.name as program_name,
    upe.completion_percentage,
    upe.current_week,
    fp.duration_weeks as total_weeks
FROM public.user_program_enrollments upe
JOIN public.fitness_programs fp ON upe.program_id = fp.id
WHERE upe.user_id = auth.uid()
    AND upe.is_active = true;
$$;

-- 4. Fix get_user_achievement_summary function
CREATE OR REPLACE FUNCTION public.get_user_achievement_summary()
RETURNS TABLE(total_achievements bigint, completed_achievements bigint, completion_percentage numeric, total_points bigint, recent_achievements jsonb)
LANGUAGE sql
STABLE 
SECURITY DEFINER
SET search_path = ''
AS $$
WITH achievement_stats AS (
    SELECT 
        COUNT(*) as total_achievements,
        COUNT(CASE WHEN ua.is_completed THEN 1 END) as completed_achievements,
        COALESCE(SUM(CASE WHEN ua.is_completed THEN ad.points_awarded ELSE 0 END), 0) as total_points
    FROM public.user_achievements ua
    JOIN public.achievement_definitions ad ON ua.achievement_definition_id = ad.id
    WHERE ua.user_id = auth.uid()
),
recent_achievements AS (
    SELECT jsonb_agg(
        jsonb_build_object(
            'title', ad.title,
            'completed_at', ua.completed_at,
            'points', ad.points_awarded
        ) ORDER BY ua.completed_at DESC
    ) as recent_list
    FROM public.user_achievements ua
    JOIN public.achievement_definitions ad ON ua.achievement_definition_id = ad.id
    WHERE ua.user_id = auth.uid()
        AND ua.is_completed = true
    LIMIT 5
)
SELECT 
    ast.total_achievements,
    ast.completed_achievements,
    CASE 
        WHEN ast.total_achievements > 0 THEN 
            ROUND((ast.completed_achievements * 100.0 / ast.total_achievements), 2)
        ELSE 0
    END as completion_percentage,
    ast.total_points,
    COALESCE(ra.recent_list, '[]'::jsonb) as recent_achievements
FROM achievement_stats ast
CROSS JOIN recent_achievements ra;
$$;

-- 5. Fix get_community_feed function
CREATE OR REPLACE FUNCTION public.get_community_feed(feed_limit integer DEFAULT 20, offset_count integer DEFAULT 0)
RETURNS TABLE(id uuid, user_id uuid, user_name text, activity_type public.activity_type, title text, description text, activity_data jsonb, media_urls text[], likes_count integer, comments_count integer, created_at timestamp with time zone, user_has_liked boolean)
LANGUAGE sql
STABLE 
SECURITY DEFINER
SET search_path = ''
AS $$
SELECT 
    ca.id,
    ca.user_id,
    up.full_name as user_name,
    ca.activity_type,
    ca.title,
    ca.description,
    ca.activity_data,
    ca.media_urls,
    ca.likes_count,
    ca.comments_count,
    ca.created_at,
    EXISTS(
        SELECT 1 FROM public.activity_reactions ar 
        WHERE ar.activity_id = ca.id AND ar.user_id = auth.uid()
    ) as user_has_liked
FROM public.community_activities ca
JOIN public.user_profiles up ON ca.user_id = up.id
WHERE ca.visibility IN ('public', 'friends')
ORDER BY ca.created_at DESC
LIMIT feed_limit
OFFSET offset_count;
$$;

-- 6. Fix cleanup_wellness_test_data function
CREATE OR REPLACE FUNCTION public.cleanup_wellness_test_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    -- Delete in dependency order
    DELETE FROM public.meal_ingredients;
    DELETE FROM public.workout_exercises;
    DELETE FROM public.activity_reactions;
    DELETE FROM public.activity_comments;
    DELETE FROM public.challenge_participants;
    DELETE FROM public.user_program_enrollments;
    DELETE FROM public.user_achievements;
    DELETE FROM public.meditations;
    DELETE FROM public.meals;
    DELETE FROM public.workouts;
    DELETE FROM public.water_intake;
    DELETE FROM public.community_activities;
    DELETE FROM public.user_goals;
    DELETE FROM public.food_items;
    DELETE FROM public.fitness_programs;
    DELETE FROM public.meditation_templates;
    DELETE FROM public.achievement_definitions;
    DELETE FROM public.community_challenges;
    
    RAISE NOTICE 'Wellness test data cleaned up successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;

-- 7. Fix handle_new_user trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'free')::public.user_role
  );
  RETURN NEW;
END;
$$;

-- 8. Fix is_premium_user function
CREATE OR REPLACE FUNCTION public.is_premium_user(user_uuid uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
STABLE 
SECURITY DEFINER
SET search_path = ''
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    JOIN public.customers c ON up.id = c.user_id
    JOIN public.subscriptions s ON c.id = s.customer_id
    WHERE up.id = user_uuid 
    AND s.status IN ('active', 'trialing')
    AND (s.current_period_end IS NULL OR s.current_period_end > NOW())
);
$$;

-- 9. Fix is_in_trial function
CREATE OR REPLACE FUNCTION public.is_in_trial(user_uuid uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
STABLE 
SECURITY DEFINER
SET search_path = ''
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    JOIN public.customers c ON up.id = c.user_id
    JOIN public.subscriptions s ON c.id = s.customer_id
    WHERE up.id = user_uuid 
    AND s.status = 'trialing'
    AND s.trial_end > NOW()
);
$$;

-- 10. Fix cleanup_subscription_test_data function
CREATE OR REPLACE FUNCTION public.cleanup_subscription_test_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    auth_user_ids_to_delete UUID[];
BEGIN
    -- Get auth user IDs for cleanup
    SELECT ARRAY_AGG(id) INTO auth_user_ids_to_delete
    FROM auth.users
    WHERE email LIKE '%@alignwise.com';

    -- Delete in dependency order (children first)
    DELETE FROM public.subscriptions WHERE customer_id IN (
        SELECT id FROM public.customers WHERE user_id = ANY(auth_user_ids_to_delete)
    );
    DELETE FROM public.payment_methods WHERE customer_id IN (
        SELECT id FROM public.customers WHERE user_id = ANY(auth_user_ids_to_delete)
    );
    DELETE FROM public.customers WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.user_profiles WHERE id = ANY(auth_user_ids_to_delete);
    
    -- Clean up products and prices for testing
    DELETE FROM public.prices WHERE stripe_price_id LIKE '%_aud';
    DELETE FROM public.products WHERE stripe_product_id = 'prod_premium_alignwise';

    -- Delete auth.users last
    DELETE FROM auth.users WHERE id = ANY(auth_user_ids_to_delete);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;

-- 11. Fix cleanup_exercises_data function
CREATE OR REPLACE FUNCTION public.cleanup_exercises_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    -- Delete basic exercises created by this migration
    DELETE FROM public.exercises WHERE name IN (
        'Push-ups', 'Squats', 'Pull-ups', 'Burpees', 'Plank', 
        'Mountain Climbers', 'Lunges', 'Jumping Jacks'
    );

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents exercise deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Exercise cleanup failed: %', SQLERRM;
END;
$$;

-- Migration completed: All functions now have immutable search_path for security compliance