-- Location: supabase/migrations/20250807203640_fix_missing_wellness_tables.sql
-- Schema Analysis: Existing schema has user_profiles, customers, subscriptions, products, prices, payment_methods, exercises
-- Integration Type: Addition - Adding missing wellness platform tables
-- Dependencies: References existing user_profiles table

-- Step 1: Create Custom Types
CREATE TYPE public.meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');
CREATE TYPE public.workout_status AS ENUM ('planned', 'in_progress', 'completed', 'cancelled');
CREATE TYPE public.workout_intensity AS ENUM ('light', 'moderate', 'vigorous');
CREATE TYPE public.meditation_type AS ENUM ('mindfulness', 'breathing', 'body_scan', 'loving_kindness', 'visualization');
CREATE TYPE public.badge_rarity AS ENUM ('common', 'rare', 'epic', 'legendary');
CREATE TYPE public.activity_type AS ENUM ('workout', 'meal', 'meditation', 'achievement', 'challenge', 'water');
CREATE TYPE public.visibility_type AS ENUM ('public', 'friends', 'private');
CREATE TYPE public.reaction_type AS ENUM ('like', 'love', 'clap', 'fire');
CREATE TYPE public.goal_type AS ENUM ('weight_loss', 'weight_gain', 'muscle_gain', 'maintenance', 'endurance', 'strength');
CREATE TYPE public.challenge_status AS ENUM ('upcoming', 'active', 'completed', 'cancelled');
CREATE TYPE public.challenge_type AS ENUM ('fitness', 'nutrition', 'mindfulness', 'water', 'mixed');

-- Step 2: Nutrition Tables
CREATE TABLE public.food_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    brand TEXT,
    barcode TEXT UNIQUE,
    calories_per_100g INTEGER NOT NULL,
    protein_per_100g DECIMAL(5,2) DEFAULT 0,
    carbs_per_100g DECIMAL(5,2) DEFAULT 0,
    fat_per_100g DECIMAL(5,2) DEFAULT 0,
    fiber_per_100g DECIMAL(5,2) DEFAULT 0,
    sugar_per_100g DECIMAL(5,2) DEFAULT 0,
    sodium_per_100g DECIMAL(5,2) DEFAULT 0,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    meal_type public.meal_type NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    calories INTEGER NOT NULL DEFAULT 0,
    protein DECIMAL(5,2) DEFAULT 0,
    carbs DECIMAL(5,2) DEFAULT 0,
    fat DECIMAL(5,2) DEFAULT 0,
    fiber DECIMAL(5,2) DEFAULT 0,
    photo_url TEXT,
    notes TEXT,
    meal_date DATE DEFAULT CURRENT_DATE,
    meal_time TIME DEFAULT CURRENT_TIME,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.meal_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_id UUID REFERENCES public.meals(id) ON DELETE CASCADE,
    food_item_id UUID REFERENCES public.food_items(id) ON DELETE CASCADE,
    quantity_grams DECIMAL(8,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.water_intake (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    amount_ml INTEGER NOT NULL,
    intake_date DATE DEFAULT CURRENT_DATE,
    intake_time TIME DEFAULT CURRENT_TIME,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Step 3: Fitness Tables
CREATE TABLE public.workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    status public.workout_status DEFAULT 'planned'::public.workout_status,
    duration_minutes INTEGER,
    calories_burned INTEGER,
    intensity public.workout_intensity DEFAULT 'moderate'::public.workout_intensity,
    notes TEXT,
    workout_date DATE DEFAULT CURRENT_DATE,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.workout_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID REFERENCES public.workouts(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
    sets INTEGER DEFAULT 1,
    reps INTEGER,
    weight_kg DECIMAL(5,2),
    duration_seconds INTEGER,
    distance_km DECIMAL(8,3),
    rest_seconds INTEGER DEFAULT 60,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.fitness_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    difficulty TEXT NOT NULL,
    duration_weeks INTEGER NOT NULL,
    workouts_per_week INTEGER DEFAULT 3,
    estimated_duration_minutes INTEGER,
    is_premium BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'active',
    image_url TEXT,
    tags TEXT[],
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.user_program_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    program_id UUID REFERENCES public.fitness_programs(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    current_week INTEGER DEFAULT 1,
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user_id, program_id)
);

-- Step 4: Mindfulness Tables
CREATE TABLE public.meditation_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    meditation_type public.meditation_type NOT NULL,
    duration_minutes INTEGER NOT NULL,
    guided_audio_url TEXT,
    background_sound TEXT,
    instructions TEXT,
    is_premium BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.meditations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    template_id UUID REFERENCES public.meditation_templates(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    meditation_type public.meditation_type NOT NULL,
    duration_minutes INTEGER NOT NULL,
    guided_session_url TEXT,
    background_sound TEXT,
    mood_before TEXT,
    mood_after TEXT,
    notes TEXT,
    session_date DATE DEFAULT CURRENT_DATE,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Step 5: Achievement System Tables
CREATE TABLE public.achievement_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    badge_icon TEXT,
    badge_rarity public.badge_rarity DEFAULT 'common'::public.badge_rarity,
    points_awarded INTEGER DEFAULT 0,
    target_value INTEGER,
    target_unit TEXT,
    achievement_type TEXT NOT NULL,
    conditions JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    achievement_definition_id UUID REFERENCES public.achievement_definitions(id) ON DELETE CASCADE,
    progress INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_definition_id)
);

-- Step 6: Community Tables
CREATE TABLE public.community_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    activity_type public.activity_type NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    activity_data JSONB,
    media_urls TEXT[],
    visibility public.visibility_type DEFAULT 'friends'::public.visibility_type,
    tags TEXT[],
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.activity_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    activity_id UUID REFERENCES public.community_activities(id) ON DELETE CASCADE,
    reaction_type public.reaction_type NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, activity_id)
);

CREATE TABLE public.activity_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    activity_id UUID REFERENCES public.community_activities(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES public.activity_comments(id) ON DELETE CASCADE,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.community_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    challenge_type public.challenge_type NOT NULL,
    status public.challenge_status DEFAULT 'upcoming'::public.challenge_status,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    target_value INTEGER,
    target_unit TEXT,
    reward_points INTEGER DEFAULT 0,
    max_participants INTEGER,
    participants_count INTEGER DEFAULT 0,
    is_team_challenge BOOLEAN DEFAULT false,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.challenge_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    challenge_id UUID REFERENCES public.community_challenges(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    current_progress INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    UNIQUE(user_id, challenge_id)
);

-- Step 7: Goals Table
CREATE TABLE public.user_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    goal_type public.goal_type NOT NULL,
    target_weight_kg DECIMAL(5,2),
    current_weight_kg DECIMAL(5,2),
    target_calories INTEGER,
    target_protein DECIMAL(5,2),
    target_carbs DECIMAL(5,2),
    target_fat DECIMAL(5,2),
    target_water_ml INTEGER DEFAULT 2000,
    workouts_per_week INTEGER DEFAULT 3,
    meditation_minutes_per_day INTEGER DEFAULT 10,
    target_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Step 8: Essential Indexes
CREATE INDEX idx_meals_user_id ON public.meals(user_id);
CREATE INDEX idx_meals_date ON public.meals(meal_date);
CREATE INDEX idx_meals_type ON public.meals(meal_type);
CREATE INDEX idx_workouts_user_id ON public.workouts(user_id);
CREATE INDEX idx_workouts_date ON public.workouts(workout_date);
CREATE INDEX idx_workouts_status ON public.workouts(status);
CREATE INDEX idx_meditations_user_id ON public.meditations(user_id);
CREATE INDEX idx_meditations_date ON public.meditations(session_date);
CREATE INDEX idx_water_intake_user_id ON public.water_intake(user_id);
CREATE INDEX idx_water_intake_date ON public.water_intake(intake_date);
CREATE INDEX idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX idx_community_activities_user_id ON public.community_activities(user_id);
CREATE INDEX idx_community_activities_type ON public.community_activities(activity_type);
CREATE INDEX idx_food_items_name ON public.food_items(name);
CREATE INDEX idx_food_items_barcode ON public.food_items(barcode);

-- Step 9: Enable RLS on all tables
ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_intake ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fitness_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_program_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meditation_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meditations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievement_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;

-- Step 10: RLS Policies

-- Food Items (public read, authenticated write)
CREATE POLICY "public_read_food_items" ON public.food_items
    FOR SELECT TO public USING (true);
CREATE POLICY "authenticated_manage_food_items" ON public.food_items
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- User-owned data policies
CREATE POLICY "users_manage_own_meals" ON public.meals
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_meal_ingredients" ON public.meal_ingredients
    FOR ALL TO authenticated USING (
        meal_id IN (SELECT id FROM public.meals WHERE user_id = auth.uid())
    ) WITH CHECK (
        meal_id IN (SELECT id FROM public.meals WHERE user_id = auth.uid())
    );

CREATE POLICY "users_manage_own_water_intake" ON public.water_intake
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_workouts" ON public.workouts
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_workout_exercises" ON public.workout_exercises
    FOR ALL TO authenticated USING (
        workout_id IN (SELECT id FROM public.workouts WHERE user_id = auth.uid())
    ) WITH CHECK (
        workout_id IN (SELECT id FROM public.workouts WHERE user_id = auth.uid())
    );

CREATE POLICY "users_manage_own_meditations" ON public.meditations
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_achievements" ON public.user_achievements
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_activities" ON public.community_activities
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "authenticated_read_public_activities" ON public.community_activities
    FOR SELECT TO authenticated USING (visibility = 'public' OR user_id = auth.uid());

CREATE POLICY "users_manage_own_reactions" ON public.activity_reactions
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_comments" ON public.activity_comments
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_goals" ON public.user_goals
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_enrollments" ON public.user_program_enrollments
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_challenge_participation" ON public.challenge_participants
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Public read policies for shared content
CREATE POLICY "public_read_fitness_programs" ON public.fitness_programs
    FOR SELECT TO authenticated USING (status = 'active');

CREATE POLICY "public_read_meditation_templates" ON public.meditation_templates
    FOR SELECT TO authenticated USING (is_active = true);

CREATE POLICY "public_read_achievement_definitions" ON public.achievement_definitions
    FOR SELECT TO authenticated USING (is_active = true);

CREATE POLICY "public_read_community_challenges" ON public.community_challenges
    FOR SELECT TO authenticated USING (true);

-- Step 11: Create Required Functions

CREATE OR REPLACE FUNCTION public.get_daily_nutrition_summary(target_date TEXT DEFAULT NULL)
RETURNS TABLE(
    total_calories BIGINT,
    total_protein NUMERIC,
    total_carbs NUMERIC,
    total_fat NUMERIC,
    total_fiber NUMERIC,
    meal_count BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
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

CREATE OR REPLACE FUNCTION public.get_weekly_workout_stats(start_date TEXT DEFAULT NULL)
RETURNS TABLE(
    total_workouts BIGINT,
    total_minutes BIGINT,
    total_calories BIGINT,
    completion_rate NUMERIC
)
LANGUAGE sql
STABLE
SECURITY DEFINER
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

CREATE OR REPLACE FUNCTION public.get_user_program_progress()
RETURNS TABLE(
    program_id UUID,
    program_name TEXT,
    completion_percentage NUMERIC,
    current_week INTEGER,
    total_weeks INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
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

CREATE OR REPLACE FUNCTION public.get_user_achievement_summary()
RETURNS TABLE(
    total_achievements BIGINT,
    completed_achievements BIGINT,
    completion_percentage NUMERIC,
    total_points BIGINT,
    recent_achievements JSONB
)
LANGUAGE sql
STABLE
SECURITY DEFINER
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

CREATE OR REPLACE FUNCTION public.get_community_feed(feed_limit INTEGER DEFAULT 20, offset_count INTEGER DEFAULT 0)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    user_name TEXT,
    activity_type public.activity_type,
    title TEXT,
    description TEXT,
    activity_data JSONB,
    media_urls TEXT[],
    likes_count INTEGER,
    comments_count INTEGER,
    created_at TIMESTAMPTZ,
    user_has_liked BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
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

-- Step 12: Mock Data
DO $$
DECLARE
    admin_user_id UUID;
    regular_user_id UUID;
    food_item1_id UUID := gen_random_uuid();
    food_item2_id UUID := gen_random_uuid();
    meal1_id UUID := gen_random_uuid();
    meal2_id UUID := gen_random_uuid();
    workout1_id UUID := gen_random_uuid();
    program1_id UUID := gen_random_uuid();
    template1_id UUID := gen_random_uuid();
    achievement1_id UUID := gen_random_uuid();
    challenge1_id UUID := gen_random_uuid();
BEGIN
    -- Get existing user IDs
    SELECT id INTO admin_user_id FROM public.user_profiles WHERE email = 'admin@alignwise.com' LIMIT 1;
    SELECT id INTO regular_user_id FROM public.user_profiles WHERE email = 'user@alignwise.com' LIMIT 1;
    
    -- Insert food items
    INSERT INTO public.food_items (id, name, description, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, is_verified) VALUES
        (food_item1_id, 'Chicken Breast', 'Lean protein source', 165, 31.0, 0.0, 3.6, 0.0, true),
        (food_item2_id, 'Brown Rice', 'Whole grain carbohydrate', 112, 2.6, 23.0, 0.9, 1.8, true),
        (gen_random_uuid(), 'Broccoli', 'Nutrient-dense vegetable', 34, 2.8, 7.0, 0.4, 2.6, true),
        (gen_random_uuid(), 'Salmon', 'Omega-3 rich fish', 208, 25.4, 0.0, 12.4, 0.0, true);
    
    -- Insert meals
    INSERT INTO public.meals (id, user_id, meal_type, name, calories, protein, carbs, fat, fiber, meal_date) VALUES
        (meal1_id, regular_user_id, 'breakfast', 'Protein Smoothie', 320, 25.0, 35.0, 8.0, 5.0, CURRENT_DATE),
        (meal2_id, regular_user_id, 'lunch', 'Chicken and Rice Bowl', 450, 40.0, 50.0, 12.0, 3.0, CURRENT_DATE),
        (gen_random_uuid(), admin_user_id, 'dinner', 'Grilled Salmon with Broccoli', 380, 35.0, 15.0, 22.0, 4.0, CURRENT_DATE);
    
    -- Insert water intake
    INSERT INTO public.water_intake (user_id, amount_ml, intake_date) VALUES
        (regular_user_id, 500, CURRENT_DATE),
        (regular_user_id, 400, CURRENT_DATE),
        (admin_user_id, 600, CURRENT_DATE);
    
    -- Insert workouts
    INSERT INTO public.workouts (id, user_id, name, activity_type, status, duration_minutes, calories_burned, intensity, workout_date) VALUES
        (workout1_id, regular_user_id, 'Morning Run', 'cardio', 'completed', 30, 300, 'moderate', CURRENT_DATE),
        (gen_random_uuid(), admin_user_id, 'Strength Training', 'strength', 'completed', 45, 250, 'vigorous', CURRENT_DATE),
        (gen_random_uuid(), regular_user_id, 'Yoga Session', 'flexibility', 'planned', 60, 150, 'light', CURRENT_DATE + 1);
    
    -- Insert fitness programs
    INSERT INTO public.fitness_programs (id, name, description, difficulty, duration_weeks, workouts_per_week, is_premium, created_by) VALUES
        (program1_id, 'Beginner Strength Training', 'Perfect for those new to weightlifting', 'beginner', 8, 3, false, admin_user_id),
        (gen_random_uuid(), 'Advanced HIIT Program', 'High-intensity interval training for experienced athletes', 'advanced', 12, 5, true, admin_user_id);
    
    -- Insert meditation templates
    INSERT INTO public.meditation_templates (id, title, description, meditation_type, duration_minutes, is_premium) VALUES
        (template1_id, '5-Minute Breathing', 'Quick breathing exercise for stress relief', 'breathing', 5, false),
        (gen_random_uuid(), 'Body Scan Meditation', 'Full body relaxation and awareness', 'body_scan', 20, false),
        (gen_random_uuid(), 'Advanced Mindfulness', 'Deep mindfulness practice for experienced meditators', 'mindfulness', 30, true);
    
    -- Insert meditations
    INSERT INTO public.meditations (user_id, template_id, title, meditation_type, duration_minutes, is_completed, session_date) VALUES
        (regular_user_id, template1_id, '5-Minute Breathing', 'breathing', 5, true, CURRENT_DATE),
        (admin_user_id, template1_id, '5-Minute Breathing', 'breathing', 5, true, CURRENT_DATE);
    
    -- Insert achievement definitions
    INSERT INTO public.achievement_definitions (id, title, description, badge_rarity, points_awarded, target_value, achievement_type, is_active) VALUES
        (achievement1_id, 'First Workout', 'Complete your first workout session', 'common', 10, 1, 'fitness', true),
        (gen_random_uuid(), 'Meditation Streak', 'Meditate for 7 consecutive days', 'rare', 50, 7, 'mindfulness', true),
        (gen_random_uuid(), 'Hydration Hero', 'Drink 8 glasses of water in a day', 'common', 20, 8, 'nutrition', true);
    
    -- Insert user achievements
    INSERT INTO public.user_achievements (user_id, achievement_definition_id, progress, is_completed, completed_at) VALUES
        (regular_user_id, achievement1_id, 1, true, CURRENT_TIMESTAMP),
        (admin_user_id, achievement1_id, 1, true, CURRENT_TIMESTAMP);
    
    -- Insert community challenges
    INSERT INTO public.community_challenges (id, title, description, challenge_type, status, start_date, end_date, target_value, target_unit, reward_points, created_by) VALUES
        (challenge1_id, '30-Day Fitness Challenge', 'Complete at least 20 workouts in 30 days', 'fitness', 'active', CURRENT_DATE, CURRENT_DATE + 30, 20, 'workouts', 100, admin_user_id),
        (gen_random_uuid(), 'Mindfulness Week', 'Meditate every day for a week', 'mindfulness', 'upcoming', CURRENT_DATE + 7, CURRENT_DATE + 14, 7, 'sessions', 75, admin_user_id);
    
    -- Insert community activities
    INSERT INTO public.community_activities (user_id, activity_type, title, description, visibility) VALUES
        (regular_user_id, 'workout', 'Completed Morning Run!', 'Just finished a great 5K run around the neighborhood', 'public'),
        (admin_user_id, 'achievement', 'First Workout Achievement Unlocked!', 'Earned my first fitness achievement', 'public');
    
    -- Insert user goals
    INSERT INTO public.user_goals (user_id, goal_type, target_weight_kg, current_weight_kg, target_calories, target_water_ml, workouts_per_week) VALUES
        (regular_user_id, 'weight_loss', 70.0, 75.0, 2000, 2500, 4),
        (admin_user_id, 'maintenance', 80.0, 80.0, 2200, 2000, 3);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inserting mock data: %', SQLERRM;
END $$;

-- Step 13: Cleanup Functions
CREATE OR REPLACE FUNCTION public.cleanup_wellness_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
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
END $$;