-- Location: supabase/migrations/20250806170132728932_fitness_programs_achievements.sql
-- Schema Analysis: Extending existing wellness schema with fitness programs and achievements
-- Integration Type: PARTIAL_EXISTS - Adding fitness programs and gamification to existing wellness system
-- Dependencies: user_profiles (existing), workouts (existing), exercises (existing)

-- 1. Custom Types for Fitness Programs and Achievements
CREATE TYPE public.program_difficulty AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE public.program_status AS ENUM ('active', 'inactive', 'draft');
CREATE TYPE public.achievement_type AS ENUM ('workout_streak', 'total_workouts', 'program_completion', 'calorie_burn', 'distance_covered', 'social_challenge', 'nutrition_goal', 'mindfulness_streak', 'special_event');
CREATE TYPE public.badge_rarity AS ENUM ('common', 'rare', 'epic', 'legendary');

-- 2. Fitness Programs Tables
CREATE TABLE public.fitness_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    difficulty public.program_difficulty NOT NULL,
    duration_weeks INTEGER NOT NULL CHECK (duration_weeks > 0),
    workouts_per_week INTEGER DEFAULT 3 CHECK (workouts_per_week > 0),
    hero_image_url TEXT,
    equipment_required TEXT[],
    muscle_groups_targeted TEXT[],
    estimated_time_per_workout INTEGER, -- in minutes
    total_estimated_calories INTEGER,
    is_premium BOOLEAN DEFAULT false,
    status public.program_status DEFAULT 'active',
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.program_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID REFERENCES public.fitness_programs(id) ON DELETE CASCADE,
    week_number INTEGER NOT NULL CHECK (week_number > 0),
    day_number INTEGER NOT NULL CHECK (day_number BETWEEN 1 AND 7),
    workout_title TEXT NOT NULL,
    workout_description TEXT,
    estimated_duration INTEGER, -- in minutes
    rest_day BOOLEAN DEFAULT false,
    workout_order INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(program_id, week_number, day_number)
);

CREATE TABLE public.program_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_workout_id UUID REFERENCES public.program_workouts(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
    sets INTEGER,
    reps INTEGER,
    duration_seconds INTEGER,
    rest_seconds INTEGER DEFAULT 60,
    weight_recommendation TEXT, -- e.g., "bodyweight", "light", "moderate", "heavy"
    exercise_order INTEGER DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.user_program_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    program_id UUID REFERENCES public.fitness_programs(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    current_week INTEGER DEFAULT 1,
    current_day INTEGER DEFAULT 1,
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, program_id)
);

-- 3. Achievement System Tables
CREATE TABLE public.achievement_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    achievement_type public.achievement_type NOT NULL,
    badge_rarity public.badge_rarity DEFAULT 'common',
    badge_icon_url TEXT,
    target_value INTEGER, -- e.g., 30 for "30 days streak", 100 for "100 workouts"
    target_unit TEXT, -- e.g., "days", "workouts", "calories", "programs"
    unlock_criteria JSONB, -- flexible criteria for complex achievements
    points_awarded INTEGER DEFAULT 10,
    is_active BOOLEAN DEFAULT true,
    is_hidden BOOLEAN DEFAULT false, -- secret achievements
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES public.achievement_definitions(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    progress_value INTEGER DEFAULT 0, -- current progress towards achievement
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    shared_on_social BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_id)
);

CREATE TABLE public.user_achievement_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES public.achievement_definitions(id) ON DELETE CASCADE,
    current_progress INTEGER DEFAULT 0,
    target_progress INTEGER NOT NULL,
    progress_percentage DECIMAL(5,2) DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_id)
);

-- 4. Challenge System Tables (Social Features)
CREATE TABLE public.community_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    challenge_type TEXT NOT NULL, -- 'team', 'individual', 'global'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    target_metric TEXT NOT NULL, -- 'total_workouts', 'calories_burned', 'programs_completed'
    target_value INTEGER,
    prize_description TEXT,
    max_participants INTEGER,
    current_participants INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.user_challenge_participation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    challenge_id UUID REFERENCES public.community_challenges(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    current_progress INTEGER DEFAULT 0,
    final_position INTEGER,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, challenge_id)
);

-- 5. Performance Tracking Tables
CREATE TABLE public.program_progress_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    program_id UUID REFERENCES public.fitness_programs(id) ON DELETE CASCADE,
    workout_date DATE DEFAULT CURRENT_DATE,
    week_number INTEGER NOT NULL,
    day_number INTEGER NOT NULL,
    workout_completed BOOLEAN DEFAULT false,
    workout_duration_minutes INTEGER,
    calories_burned INTEGER,
    difficulty_rating INTEGER CHECK (difficulty_rating BETWEEN 1 AND 5),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Indexes for Performance
CREATE INDEX idx_fitness_programs_difficulty ON public.fitness_programs(difficulty);
CREATE INDEX idx_fitness_programs_status ON public.fitness_programs(status);
CREATE INDEX idx_fitness_programs_premium ON public.fitness_programs(is_premium);
CREATE INDEX idx_program_workouts_program_id ON public.program_workouts(program_id);
CREATE INDEX idx_program_workouts_week_day ON public.program_workouts(program_id, week_number, day_number);
CREATE INDEX idx_program_exercises_workout_id ON public.program_exercises(program_workout_id);
CREATE INDEX idx_program_exercises_exercise_id ON public.program_exercises(exercise_id);
CREATE INDEX idx_user_program_enrollments_user_id ON public.user_program_enrollments(user_id);
CREATE INDEX idx_user_program_enrollments_program_id ON public.user_program_enrollments(program_id);
CREATE INDEX idx_user_program_enrollments_active ON public.user_program_enrollments(user_id, is_active);
CREATE INDEX idx_achievement_definitions_type ON public.achievement_definitions(achievement_type);
CREATE INDEX idx_achievement_definitions_active ON public.achievement_definitions(is_active);
CREATE INDEX idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX idx_user_achievements_completed ON public.user_achievements(user_id, is_completed);
CREATE INDEX idx_user_achievement_progress_user_id ON public.user_achievement_progress(user_id);
CREATE INDEX idx_community_challenges_active ON public.community_challenges(is_active, start_date, end_date);
CREATE INDEX idx_user_challenge_participation_user_id ON public.user_challenge_participation(user_id);
CREATE INDEX idx_user_challenge_participation_challenge_id ON public.user_challenge_participation(challenge_id);
CREATE INDEX idx_program_progress_tracking_user_id ON public.program_progress_tracking(user_id);
CREATE INDEX idx_program_progress_tracking_program_id ON public.program_progress_tracking(program_id);

-- 7. Enable Row Level Security
ALTER TABLE public.fitness_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_program_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievement_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievement_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_challenge_participation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_progress_tracking ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies using correct patterns

-- Pattern 4: Public Read, Private Write for fitness programs
CREATE POLICY "public_read_fitness_programs"
ON public.fitness_programs
FOR SELECT
TO public
USING (status = 'active');

CREATE POLICY "authenticated_manage_fitness_programs"
ON public.fitness_programs
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Pattern 4: Public Read for program workouts and exercises
CREATE POLICY "public_read_program_workouts"
ON public.program_workouts
FOR SELECT
TO public
USING (true);

CREATE POLICY "public_read_program_exercises"
ON public.program_exercises
FOR SELECT
TO public
USING (true);

-- Pattern 2: Simple User Ownership for user enrollments
CREATE POLICY "users_manage_own_enrollments"
ON public.user_program_enrollments
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 4: Public Read for achievement definitions
CREATE POLICY "public_read_achievement_definitions"
ON public.achievement_definitions
FOR SELECT
TO public
USING (is_active = true AND is_hidden = false);

CREATE POLICY "authenticated_manage_achievement_definitions"
ON public.achievement_definitions
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Pattern 2: Simple User Ownership for user achievements
CREATE POLICY "users_manage_own_achievements"
ON public.user_achievements
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_achievement_progress"
ON public.user_achievement_progress
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 4: Public Read for community challenges
CREATE POLICY "public_read_community_challenges"
ON public.community_challenges
FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "authenticated_manage_community_challenges"
ON public.community_challenges
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Pattern 2: Simple User Ownership for challenge participation
CREATE POLICY "users_manage_own_challenge_participation"
ON public.user_challenge_participation
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Simple User Ownership for progress tracking
CREATE POLICY "users_manage_own_progress_tracking"
ON public.program_progress_tracking
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 9. Utility Functions
CREATE OR REPLACE FUNCTION public.get_user_program_progress(user_uuid UUID DEFAULT auth.uid(), program_uuid UUID DEFAULT NULL)
RETURNS TABLE(
    program_id UUID,
    program_title TEXT,
    current_week INTEGER,
    current_day INTEGER,
    completion_percentage DECIMAL(5,2),
    total_workouts INTEGER,
    completed_workouts INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    upe.program_id,
    fp.title as program_title,
    upe.current_week,
    upe.current_day,
    upe.completion_percentage,
    COUNT(pw.id)::INTEGER as total_workouts,
    COUNT(CASE WHEN ppt.workout_completed = true THEN 1 END)::INTEGER as completed_workouts
FROM public.user_program_enrollments upe
JOIN public.fitness_programs fp ON upe.program_id = fp.id
LEFT JOIN public.program_workouts pw ON fp.id = pw.program_id
LEFT JOIN public.program_progress_tracking ppt ON (
    upe.user_id = ppt.user_id 
    AND upe.program_id = ppt.program_id
)
WHERE upe.user_id = user_uuid 
    AND upe.is_active = true
    AND (program_uuid IS NULL OR upe.program_id = program_uuid)
GROUP BY upe.program_id, fp.title, upe.current_week, upe.current_day, upe.completion_percentage
$$;

CREATE OR REPLACE FUNCTION public.get_user_achievement_summary(user_uuid UUID DEFAULT auth.uid())
RETURNS TABLE(
    total_achievements INTEGER,
    completed_achievements INTEGER,
    completion_percentage DECIMAL(5,2),
    total_points INTEGER,
    recent_achievements JSONB
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    COUNT(ua.id)::INTEGER as total_achievements,
    COUNT(CASE WHEN ua.is_completed = true THEN 1 END)::INTEGER as completed_achievements,
    CASE 
        WHEN COUNT(ua.id) > 0 THEN 
            ROUND((COUNT(CASE WHEN ua.is_completed = true THEN 1 END)::DECIMAL / COUNT(ua.id)) * 100, 2)
        ELSE 0 
    END as completion_percentage,
    COALESCE(SUM(CASE WHEN ua.is_completed = true THEN ad.points_awarded ELSE 0 END), 0)::INTEGER as total_points,
    COALESCE(
        jsonb_agg(
            CASE WHEN ua.is_completed = true AND ua.completed_at >= NOW() - INTERVAL '30 days' 
            THEN jsonb_build_object(
                'title', ad.title,
                'badge_rarity', ad.badge_rarity,
                'completed_at', ua.completed_at
            ) END
        ) FILTER (WHERE ua.is_completed = true AND ua.completed_at >= NOW() - INTERVAL '30 days'),
        '[]'::jsonb
    ) as recent_achievements
FROM public.user_achievements ua
JOIN public.achievement_definitions ad ON ua.achievement_id = ad.id
WHERE ua.user_id = user_uuid
$$;

-- 10. Mock Data for Fitness Programs and Achievements
DO $$
DECLARE
    existing_user_id UUID;
    existing_admin_id UUID;
    program1_id UUID := gen_random_uuid();
    program2_id UUID := gen_random_uuid();
    workout1_id UUID := gen_random_uuid();
    workout2_id UUID := gen_random_uuid();
    achievement1_id UUID := gen_random_uuid();
    achievement2_id UUID := gen_random_uuid();
    challenge1_id UUID := gen_random_uuid();
    existing_exercise1_id UUID;
    existing_exercise2_id UUID;
BEGIN
    -- Get existing user IDs
    SELECT id INTO existing_admin_id FROM public.user_profiles WHERE email = 'admin@alignwise.com' LIMIT 1;
    SELECT id INTO existing_user_id FROM public.user_profiles WHERE email = 'user@alignwise.com' LIMIT 1;
    
    -- Get existing exercise IDs
    SELECT id INTO existing_exercise1_id FROM public.exercises WHERE name = 'Push-ups' LIMIT 1;
    SELECT id INTO existing_exercise2_id FROM public.exercises WHERE name = 'Squats' LIMIT 1;

    IF existing_admin_id IS NOT NULL AND existing_user_id IS NOT NULL THEN
        
        -- Insert sample fitness programs
        INSERT INTO public.fitness_programs (id, title, description, difficulty, duration_weeks, workouts_per_week, equipment_required, muscle_groups_targeted, is_premium, created_by) VALUES
            (program1_id, 'Beginner Foundation', 'A comprehensive 8-week program designed for fitness beginners to build strength, endurance, and healthy habits', 'beginner', 8, 3, ARRAY['bodyweight', 'resistance_bands'], ARRAY['full_body', 'core', 'cardiovascular'], false, existing_admin_id),
            (program2_id, 'HIIT Challenge', 'Intense 6-week high-intensity interval training program for advanced fitness enthusiasts', 'advanced', 6, 4, ARRAY['bodyweight', 'dumbbells', 'kettlebell'], ARRAY['full_body', 'cardio', 'explosive_power'], true, existing_admin_id);

        -- Insert program workouts
        INSERT INTO public.program_workouts (id, program_id, week_number, day_number, workout_title, workout_description, estimated_duration) VALUES
            (workout1_id, program1_id, 1, 1, 'Foundation Upper Body', 'Focus on basic upper body movements with proper form', 30),
            (workout2_id, program1_id, 1, 3, 'Foundation Lower Body', 'Build lower body strength with bodyweight exercises', 35);

        -- Insert program exercises
        IF existing_exercise1_id IS NOT NULL AND existing_exercise2_id IS NOT NULL THEN
            INSERT INTO public.program_exercises (program_workout_id, exercise_id, sets, reps, weight_recommendation, exercise_order) VALUES
                (workout1_id, existing_exercise1_id, 3, 12, 'bodyweight', 1),
                (workout2_id, existing_exercise2_id, 3, 15, 'bodyweight', 1);
        END IF;

        -- Insert user program enrollment
        INSERT INTO public.user_program_enrollments (user_id, program_id, current_week, current_day, completion_percentage) VALUES
            (existing_user_id, program1_id, 1, 2, 15.0);

        -- Insert achievement definitions
        INSERT INTO public.achievement_definitions (id, title, description, achievement_type, badge_rarity, target_value, target_unit, points_awarded) VALUES
            (achievement1_id, 'Fitness Explorer', 'Complete your first workout program', 'program_completion', 'common', 1, 'programs', 100),
            (achievement2_id, 'Consistency King', 'Maintain a 7-day workout streak', 'workout_streak', 'rare', 7, 'days', 250);

        -- Insert user achievements
        INSERT INTO public.user_achievements (user_id, achievement_id, progress_value, is_completed, completed_at) VALUES
            (existing_user_id, achievement1_id, 1, true, CURRENT_TIMESTAMP);

        INSERT INTO public.user_achievement_progress (user_id, achievement_id, current_progress, target_progress, progress_percentage) VALUES
            (existing_user_id, achievement2_id, 3, 7, 42.86);

        -- Insert community challenge
        INSERT INTO public.community_challenges (id, title, description, challenge_type, start_date, end_date, target_metric, target_value, max_participants, created_by) VALUES
            (challenge1_id, 'January Fitness Kickstart', 'Join thousands of users in completing 20 workouts this month', 'global', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', 'total_workouts', 20, 10000, existing_admin_id);

        -- Insert user challenge participation
        INSERT INTO public.user_challenge_participation (user_id, challenge_id, current_progress) VALUES
            (existing_user_id, challenge1_id, 5);

        -- Insert program progress tracking
        INSERT INTO public.program_progress_tracking (user_id, program_id, week_number, day_number, workout_completed, workout_duration_minutes, calories_burned, difficulty_rating) VALUES
            (existing_user_id, program1_id, 1, 1, true, 28, 180, 3);

    ELSE
        RAISE NOTICE 'Existing user profiles not found. Please ensure wellness migration is applied first.';
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error in fitness programs and achievements data creation: %', SQLERRM;
END $$;

-- 11. Cleanup function for fitness programs and achievements data
CREATE OR REPLACE FUNCTION public.cleanup_fitness_achievements_test_data()
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

    -- Delete data in dependency order
    DELETE FROM public.program_progress_tracking WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_challenge_participation WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_achievement_progress WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_achievements WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_program_enrollments WHERE user_id = ANY(user_ids_to_clean);
    
    DELETE FROM public.program_exercises WHERE program_workout_id IN (
        SELECT pw.id FROM public.program_workouts pw
        JOIN public.fitness_programs fp ON pw.program_id = fp.id
        WHERE fp.created_by = ANY(user_ids_to_clean)
    );
    DELETE FROM public.program_workouts WHERE program_id IN (
        SELECT id FROM public.fitness_programs WHERE created_by = ANY(user_ids_to_clean)
    );
    DELETE FROM public.fitness_programs WHERE created_by = ANY(user_ids_to_clean);
    DELETE FROM public.community_challenges WHERE created_by = ANY(user_ids_to_clean);
    DELETE FROM public.achievement_definitions WHERE title IN ('Fitness Explorer', 'Consistency King');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents fitness/achievements data deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Fitness/achievements cleanup failed: %', SQLERRM;
END;
$$;