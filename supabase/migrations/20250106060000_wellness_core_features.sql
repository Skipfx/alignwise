-- Location: supabase/migrations/20250106060000_wellness_core_features.sql
-- Schema Analysis: Extending existing subscription management schema
-- Integration Type: PARTIAL_EXISTS - Adding wellness features to existing user system
-- Dependencies: user_profiles (existing), customers (existing), subscriptions (existing)

-- 1. Custom Types for Wellness Features
CREATE TYPE public.activity_type AS ENUM ('cardio', 'strength', 'flexibility', 'sports', 'other');
CREATE TYPE public.workout_status AS ENUM ('planned', 'in_progress', 'completed', 'skipped');
CREATE TYPE public.meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');
CREATE TYPE public.meditation_type AS ENUM ('mindfulness', 'breathing', 'body_scan', 'loving_kindness', 'sleep');
CREATE TYPE public.mood_level AS ENUM ('very_sad', 'sad', 'neutral', 'happy', 'very_happy');
CREATE TYPE public.intensity_level AS ENUM ('low', 'moderate', 'high', 'very_high');

-- 2. Nutrition Tracking Tables
CREATE TABLE public.meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    meal_type public.meal_type NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    calories INTEGER DEFAULT 0,
    protein DECIMAL(8,2) DEFAULT 0,
    carbs DECIMAL(8,2) DEFAULT 0,
    fat DECIMAL(8,2) DEFAULT 0,
    fiber DECIMAL(8,2) DEFAULT 0,
    sugar DECIMAL(8,2) DEFAULT 0,
    sodium INTEGER DEFAULT 0, -- in mg
    meal_date DATE DEFAULT CURRENT_DATE,
    meal_time TIME DEFAULT CURRENT_TIME,
    photo_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.food_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    brand TEXT,
    calories_per_100g INTEGER NOT NULL,
    protein_per_100g DECIMAL(8,2) DEFAULT 0,
    carbs_per_100g DECIMAL(8,2) DEFAULT 0,
    fat_per_100g DECIMAL(8,2) DEFAULT 0,
    fiber_per_100g DECIMAL(8,2) DEFAULT 0,
    sugar_per_100g DECIMAL(8,2) DEFAULT 0,
    sodium_per_100g INTEGER DEFAULT 0,
    barcode TEXT UNIQUE,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.meal_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_id UUID REFERENCES public.meals(id) ON DELETE CASCADE,
    food_item_id UUID REFERENCES public.food_items(id) ON DELETE CASCADE,
    quantity DECIMAL(8,2) NOT NULL DEFAULT 100, -- in grams
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Fitness Tracking Tables
CREATE TABLE public.workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    activity_type public.activity_type NOT NULL,
    status public.workout_status DEFAULT 'planned',
    duration_minutes INTEGER,
    calories_burned INTEGER,
    intensity public.intensity_level DEFAULT 'moderate',
    notes TEXT,
    workout_date DATE DEFAULT CURRENT_DATE,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL, -- 'chest', 'back', 'legs', etc.
    muscle_groups TEXT[], -- array of muscle groups
    equipment_needed TEXT[],
    instructions TEXT,
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 5),
    video_url TEXT,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.workout_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID REFERENCES public.workouts(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
    sets INTEGER,
    reps INTEGER,
    weight_kg DECIMAL(8,2),
    duration_seconds INTEGER,
    distance_meters DECIMAL(10,2),
    rest_seconds INTEGER DEFAULT 60,
    notes TEXT,
    exercise_order INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Mindfulness & Meditation Tables
CREATE TABLE public.meditations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    meditation_type public.meditation_type NOT NULL,
    title TEXT NOT NULL,
    duration_minutes INTEGER NOT NULL,
    guided_session_url TEXT,
    background_sound TEXT, -- 'rain', 'ocean', 'forest', 'silence'
    mood_before public.mood_level,
    mood_after public.mood_level,
    notes TEXT,
    session_date DATE DEFAULT CURRENT_DATE,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.meditation_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    meditation_type public.meditation_type NOT NULL,
    duration_minutes INTEGER NOT NULL,
    instructions TEXT,
    audio_url TEXT,
    is_premium BOOLEAN DEFAULT false,
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 3), -- 1=beginner, 2=intermediate, 3=advanced
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Water Intake Tracking
CREATE TABLE public.water_intake (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    amount_ml INTEGER NOT NULL,
    intake_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    intake_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. User Goals and Preferences
CREATE TABLE public.user_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    goal_type TEXT NOT NULL, -- 'weight_loss', 'muscle_gain', 'maintenance', 'fitness'
    target_weight_kg DECIMAL(5,2),
    current_weight_kg DECIMAL(5,2),
    target_calories INTEGER,
    target_protein DECIMAL(8,2),
    target_carbs DECIMAL(8,2),
    target_fat DECIMAL(8,2),
    target_water_ml INTEGER DEFAULT 2000,
    workouts_per_week INTEGER DEFAULT 3,
    meditation_minutes_per_day INTEGER DEFAULT 10,
    target_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. Progress Tracking
CREATE TABLE public.body_measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    weight_kg DECIMAL(5,2),
    body_fat_percentage DECIMAL(5,2),
    muscle_mass_kg DECIMAL(5,2),
    waist_cm DECIMAL(5,2),
    chest_cm DECIMAL(5,2),
    arm_cm DECIMAL(5,2),
    thigh_cm DECIMAL(5,2),
    measurement_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 8. Essential Indexes for Performance
CREATE INDEX idx_meals_user_id ON public.meals(user_id);
CREATE INDEX idx_meals_date ON public.meals(meal_date);
CREATE INDEX idx_meals_type ON public.meals(meal_type);
CREATE INDEX idx_meal_ingredients_meal_id ON public.meal_ingredients(meal_id);
CREATE INDEX idx_meal_ingredients_food_item_id ON public.meal_ingredients(food_item_id);
CREATE INDEX idx_food_items_name ON public.food_items(name);
CREATE INDEX idx_food_items_barcode ON public.food_items(barcode);

CREATE INDEX idx_workouts_user_id ON public.workouts(user_id);
CREATE INDEX idx_workouts_date ON public.workouts(workout_date);
CREATE INDEX idx_workouts_status ON public.workouts(status);
CREATE INDEX idx_workout_exercises_workout_id ON public.workout_exercises(workout_id);
CREATE INDEX idx_workout_exercises_exercise_id ON public.workout_exercises(exercise_id);
CREATE INDEX idx_exercises_category ON public.exercises(category);

CREATE INDEX idx_meditations_user_id ON public.meditations(user_id);
CREATE INDEX idx_meditations_date ON public.meditations(session_date);
CREATE INDEX idx_meditations_type ON public.meditations(meditation_type);
CREATE INDEX idx_meditation_templates_type ON public.meditation_templates(meditation_type);
CREATE INDEX idx_meditation_templates_premium ON public.meditation_templates(is_premium);

CREATE INDEX idx_water_intake_user_id ON public.water_intake(user_id);
CREATE INDEX idx_water_intake_date ON public.water_intake(intake_date);
CREATE INDEX idx_user_goals_user_id ON public.user_goals(user_id);
CREATE INDEX idx_user_goals_active ON public.user_goals(is_active);
CREATE INDEX idx_body_measurements_user_id ON public.body_measurements(user_id);
CREATE INDEX idx_body_measurements_date ON public.body_measurements(measurement_date);

-- 9. Enable Row Level Security
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meditations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meditation_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_intake ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.body_measurements ENABLE ROW LEVEL SECURITY;

-- 10. RLS Policies using correct patterns

-- Pattern 2: Simple User Ownership for all user-specific tables
CREATE POLICY "users_manage_own_meals"
ON public.meals
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_workouts"
ON public.workouts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_meditations"
ON public.meditations
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_water_intake"
ON public.water_intake
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_goals"
ON public.user_goals
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_measurements"
ON public.body_measurements
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 5: User Validation for meal ingredients (relationship table)
CREATE OR REPLACE FUNCTION public.is_valid_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() AND up.is_active = true
)
$$;

CREATE POLICY "users_manage_meal_ingredients"
ON public.meal_ingredients
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.meals m 
        WHERE m.id = meal_ingredients.meal_id 
        AND m.user_id = auth.uid()
    ) AND public.is_valid_user()
);

CREATE POLICY "users_manage_workout_exercises"
ON public.workout_exercises
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.workouts w 
        WHERE w.id = workout_exercises.workout_id 
        AND w.user_id = auth.uid()
    )
);

-- Pattern 4: Public Read, Private Write for reference data
CREATE POLICY "public_read_food_items"
ON public.food_items
FOR SELECT
TO public
USING (true);

CREATE POLICY "authenticated_manage_food_items"
ON public.food_items
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "public_read_exercises"
ON public.exercises
FOR SELECT
TO public
USING (true);

CREATE POLICY "authenticated_manage_exercises"
ON public.exercises
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "public_read_meditation_templates"
ON public.meditation_templates
FOR SELECT
TO public
USING (true);

-- Pattern 6: Role-based access for premium meditation templates
CREATE OR REPLACE FUNCTION public.can_access_premium_content()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    JOIN public.customers c ON up.id = c.user_id
    JOIN public.subscriptions s ON c.id = s.customer_id
    WHERE up.id = auth.uid() 
    AND s.status IN ('active', 'trialing')
    AND (s.current_period_end IS NULL OR s.current_period_end > NOW())
) OR EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid() 
    AND au.raw_user_meta_data->>'role' = 'admin'
)
$$;

CREATE POLICY "premium_meditation_access"
ON public.meditation_templates
FOR SELECT
TO authenticated
USING (NOT is_premium OR public.can_access_premium_content());

-- 11. Utility Functions
CREATE OR REPLACE FUNCTION public.get_daily_nutrition_summary(user_uuid UUID DEFAULT auth.uid(), target_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    total_calories INTEGER,
    total_protein DECIMAL(8,2),
    total_carbs DECIMAL(8,2),
    total_fat DECIMAL(8,2),
    total_fiber DECIMAL(8,2),
    meal_count INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    COALESCE(SUM(m.calories), 0)::INTEGER as total_calories,
    COALESCE(SUM(m.protein), 0) as total_protein,
    COALESCE(SUM(m.carbs), 0) as total_carbs,
    COALESCE(SUM(m.fat), 0) as total_fat,
    COALESCE(SUM(m.fiber), 0) as total_fiber,
    COUNT(m.id)::INTEGER as meal_count
FROM public.meals m
WHERE m.user_id = user_uuid AND m.meal_date = target_date
$$;

CREATE OR REPLACE FUNCTION public.get_weekly_workout_stats(user_uuid UUID DEFAULT auth.uid(), start_date DATE DEFAULT CURRENT_DATE - INTERVAL '7 days')
RETURNS TABLE(
    total_workouts INTEGER,
    total_minutes INTEGER,
    total_calories INTEGER,
    completion_rate DECIMAL(5,2)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    COUNT(w.id)::INTEGER as total_workouts,
    COALESCE(SUM(w.duration_minutes), 0)::INTEGER as total_minutes,
    COALESCE(SUM(w.calories_burned), 0)::INTEGER as total_calories,
    CASE 
        WHEN COUNT(w.id) > 0 THEN 
            ROUND((COUNT(CASE WHEN w.status = 'completed' THEN 1 END)::DECIMAL / COUNT(w.id)) * 100, 2)
        ELSE 0 
    END as completion_rate
FROM public.workouts w
WHERE w.user_id = user_uuid 
    AND w.workout_date >= start_date 
    AND w.workout_date <= CURRENT_DATE
$$;

-- 12. Mock Data for Wellness Features
DO $$
DECLARE
    existing_admin_id UUID;
    existing_user_id UUID;
    food_item1_id UUID := gen_random_uuid();
    food_item2_id UUID := gen_random_uuid();
    exercise1_id UUID := gen_random_uuid();
    exercise2_id UUID := gen_random_uuid();
    meal1_id UUID := gen_random_uuid();
    workout1_id UUID := gen_random_uuid();
    meditation_template1_id UUID := gen_random_uuid();
BEGIN
    -- Get existing user IDs from the subscription system
    SELECT id INTO existing_admin_id FROM public.user_profiles WHERE email = 'admin@alignwise.com' LIMIT 1;
    SELECT id INTO existing_user_id FROM public.user_profiles WHERE email = 'user@alignwise.com' LIMIT 1;

    -- Only proceed if users exist
    IF existing_admin_id IS NOT NULL AND existing_user_id IS NOT NULL THEN
        
        -- Insert sample food items
        INSERT INTO public.food_items (id, name, brand, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g) VALUES
            (food_item1_id, 'Chicken Breast', 'Generic', 165, 31.0, 0.0, 3.6),
            (food_item2_id, 'Brown Rice', 'Generic', 123, 2.6, 23.0, 0.9);

        -- Insert sample exercises
        INSERT INTO public.exercises (id, name, category, muscle_groups, equipment_needed, difficulty_level) VALUES
            (exercise1_id, 'Push-ups', 'chest', ARRAY['chest', 'shoulders', 'triceps'], ARRAY['bodyweight'], 2),
            (exercise2_id, 'Squats', 'legs', ARRAY['quadriceps', 'glutes', 'hamstrings'], ARRAY['bodyweight'], 2);

        -- Insert meditation templates
        INSERT INTO public.meditation_templates (id, title, description, meditation_type, duration_minutes, is_premium, difficulty_level) VALUES
            (meditation_template1_id, 'Morning Mindfulness', 'Start your day with peaceful awareness', 'mindfulness', 10, false, 1);

        -- Insert sample user goals
        INSERT INTO public.user_goals (user_id, goal_type, target_weight_kg, current_weight_kg, target_calories, target_water_ml) VALUES
            (existing_user_id, 'weight_loss', 70.0, 75.0, 2000, 2500);

        -- Insert sample meal
        INSERT INTO public.meals (id, user_id, meal_type, name, calories, protein, carbs, fat) VALUES
            (meal1_id, existing_user_id, 'lunch', 'Grilled Chicken with Rice', 450, 35.0, 40.0, 8.0);

        -- Insert meal ingredients
        INSERT INTO public.meal_ingredients (meal_id, food_item_id, quantity) VALUES
            (meal1_id, food_item1_id, 150.0),
            (meal1_id, food_item2_id, 100.0);

        -- Insert sample workout
        INSERT INTO public.workouts (id, user_id, name, activity_type, status, duration_minutes, calories_burned) VALUES
            (workout1_id, existing_user_id, 'Morning Cardio', 'cardio', 'completed', 30, 250);

        -- Insert workout exercises
        INSERT INTO public.workout_exercises (workout_id, exercise_id, sets, reps, exercise_order) VALUES
            (workout1_id, exercise1_id, 3, 15, 1),
            (workout1_id, exercise2_id, 3, 20, 2);

        -- Insert sample meditation session
        INSERT INTO public.meditations (user_id, meditation_type, title, duration_minutes, mood_before, mood_after, is_completed) VALUES
            (existing_user_id, 'mindfulness', 'Morning Mindfulness', 10, 'neutral', 'happy', true);

        -- Insert water intake
        INSERT INTO public.water_intake (user_id, amount_ml, intake_time) VALUES
            (existing_user_id, 250, NOW() - INTERVAL '2 hours'),
            (existing_user_id, 500, NOW() - INTERVAL '4 hours');

        -- Insert body measurement
        INSERT INTO public.body_measurements (user_id, weight_kg, body_fat_percentage) VALUES
            (existing_user_id, 74.5, 18.2);

    ELSE
        RAISE NOTICE 'Existing user profiles not found. Please ensure subscription migration is applied first.';
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error in wellness data creation: %', SQLERRM;
END $$;

-- 13. Cleanup function for wellness data
CREATE OR REPLACE FUNCTION public.cleanup_wellness_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_ids_to_clean UUID[];
BEGIN
    -- Get user IDs for AlignWise test accounts
    SELECT ARRAY_AGG(id) INTO user_ids_to_clean
    FROM public.user_profiles
    WHERE email LIKE '%@alignwise.com';

    -- Delete wellness data in dependency order
    DELETE FROM public.meal_ingredients WHERE meal_id IN (
        SELECT id FROM public.meals WHERE user_id = ANY(user_ids_to_clean)
    );
    DELETE FROM public.workout_exercises WHERE workout_id IN (
        SELECT id FROM public.workouts WHERE user_id = ANY(user_ids_to_clean)
    );
    DELETE FROM public.meals WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.workouts WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.meditations WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.water_intake WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_goals WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.body_measurements WHERE user_id = ANY(user_ids_to_clean);

    -- Clean up reference data
    DELETE FROM public.food_items WHERE name LIKE '%Generic%';
    DELETE FROM public.exercises WHERE name IN ('Push-ups', 'Squats');
    DELETE FROM public.meditation_templates WHERE title = 'Morning Mindfulness';

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents wellness data deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Wellness cleanup failed: %', SQLERRM;
END;
$$;