-- Location: supabase/migrations/20250807013703_comprehensive_alignwise_wellness_platform.sql
-- Schema Analysis: Extending existing subscription management schema with comprehensive wellness features
-- Integration Type: MAJOR_EXTENSION - Adding all wellness platform functionality to existing user system
-- Dependencies: user_profiles (existing), customers (existing), subscriptions (existing), exercises (existing)

-- 1. Wellness-specific Custom Types
CREATE TYPE public.activity_type AS ENUM ('cardio', 'strength', 'flexibility', 'sports', 'other');
CREATE TYPE public.workout_status AS ENUM ('planned', 'in_progress', 'completed', 'skipped');
CREATE TYPE public.meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');
CREATE TYPE public.meditation_type AS ENUM ('mindfulness', 'breathing', 'body_scan', 'loving_kindness', 'sleep');
CREATE TYPE public.mood_level AS ENUM ('very_sad', 'sad', 'neutral', 'happy', 'very_happy');
CREATE TYPE public.intensity_level AS ENUM ('low', 'moderate', 'high', 'very_high');
CREATE TYPE public.program_difficulty AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE public.program_status AS ENUM ('active', 'inactive', 'draft');
CREATE TYPE public.achievement_type AS ENUM ('workout_streak', 'total_workouts', 'program_completion', 'calorie_burn', 'distance_covered', 'social_challenge', 'nutrition_goal', 'mindfulness_streak', 'special_event');
CREATE TYPE public.badge_rarity AS ENUM ('common', 'rare', 'epic', 'legendary');
CREATE TYPE public.activity_visibility AS ENUM ('public', 'friends', 'private');
CREATE TYPE public.challenge_type AS ENUM ('fitness', 'nutrition', 'mindfulness', 'water', 'general');
CREATE TYPE public.challenge_status AS ENUM ('upcoming', 'active', 'completed', 'cancelled');
CREATE TYPE public.reaction_type AS ENUM ('like', 'love', 'celebrate', 'encourage', 'fire');
CREATE TYPE public.friend_status AS ENUM ('pending', 'accepted', 'blocked');

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

-- 4. Fitness Programs Tables
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

-- 5. Mindfulness & Meditation Tables
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

-- 6. Achievement System Tables
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

-- 7. Community Feed and Social Features
CREATE TABLE public.community_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL, -- 'workout_completed', 'meditation_session', 'meal_logged', 'goal_achieved', 'challenge_joined', 'custom_post'
    title TEXT NOT NULL,
    description TEXT,
    activity_data JSONB, -- Stores activity-specific data like workout details, meditation duration, etc.
    media_urls TEXT[], -- Array of image/video URLs
    visibility public.activity_visibility DEFAULT 'friends',
    related_workout_id UUID REFERENCES public.workouts(id) ON DELETE SET NULL,
    related_meditation_id UUID REFERENCES public.meditations(id) ON DELETE SET NULL,
    related_meal_id UUID REFERENCES public.meals(id) ON DELETE SET NULL,
    tags TEXT[],
    location_name TEXT,
    is_achievement BOOLEAN DEFAULT false,
    achievement_badge TEXT, -- Badge name/ID for achievements
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.user_friends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    requested_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status public.friend_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMPTZ,
    UNIQUE(requester_id, requested_id),
    CHECK (requester_id != requested_id)
);

CREATE TABLE public.activity_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID REFERENCES public.community_activities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    reaction_type public.reaction_type DEFAULT 'like',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(activity_id, user_id, reaction_type)
);

CREATE TABLE public.activity_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID REFERENCES public.community_activities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    comment_text TEXT NOT NULL,
    parent_comment_id UUID REFERENCES public.activity_comments(id) ON DELETE CASCADE, -- For replies
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 8. Community Challenges
CREATE TABLE public.community_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    challenge_type public.challenge_type NOT NULL,
    status public.challenge_status DEFAULT 'upcoming',
    target_value INTEGER, -- e.g., 10000 steps, 30 days, 8 glasses of water
    target_unit TEXT, -- 'steps', 'minutes', 'days', 'glasses'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_team_challenge BOOLEAN DEFAULT false,
    max_participants INTEGER,
    reward_description TEXT,
    badge_icon TEXT,
    cover_image_url TEXT,
    rules TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.challenge_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID REFERENCES public.community_challenges(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    progress_value INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    team_name TEXT, -- For team challenges
    UNIQUE(challenge_id, user_id)
);

-- 9. Water Intake and Goal Tracking
CREATE TABLE public.water_intake (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    amount_ml INTEGER NOT NULL,
    intake_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    intake_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

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

-- 10. Story-style Highlights (24-hour temporary content)
CREATE TABLE public.user_stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    media_url TEXT NOT NULL, -- Image or short video
    story_type TEXT DEFAULT 'wellness_win', -- 'milestone', 'daily_win', 'motivation', 'workout_selfie'
    description TEXT,
    visibility public.activity_visibility DEFAULT 'friends',
    expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '24 hours'),
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.story_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id UUID REFERENCES public.user_stories(id) ON DELETE CASCADE,
    viewer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    viewed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(story_id, viewer_id)
);

-- 11. User Activity Settings (Privacy controls)
CREATE TABLE public.user_activity_settings (
    user_id UUID PRIMARY KEY REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    auto_share_workouts BOOLEAN DEFAULT true,
    auto_share_meditations BOOLEAN DEFAULT true,
    auto_share_meals BOOLEAN DEFAULT false,
    auto_share_achievements BOOLEAN DEFAULT true,
    default_visibility public.activity_visibility DEFAULT 'friends',
    allow_friend_requests BOOLEAN DEFAULT true,
    show_activity_in_feed BOOLEAN DEFAULT true,
    notification_reactions BOOLEAN DEFAULT true,
    notification_comments BOOLEAN DEFAULT true,
    notification_friend_requests BOOLEAN DEFAULT true,
    notification_challenge_invites BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 12. Essential Indexes for Performance
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

CREATE INDEX idx_meditations_user_id ON public.meditations(user_id);
CREATE INDEX idx_meditations_date ON public.meditations(session_date);
CREATE INDEX idx_meditations_type ON public.meditations(meditation_type);
CREATE INDEX idx_meditation_templates_type ON public.meditation_templates(meditation_type);
CREATE INDEX idx_meditation_templates_premium ON public.meditation_templates(is_premium);

CREATE INDEX idx_achievement_definitions_type ON public.achievement_definitions(achievement_type);
CREATE INDEX idx_achievement_definitions_active ON public.achievement_definitions(is_active);
CREATE INDEX idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX idx_user_achievements_completed ON public.user_achievements(user_id, is_completed);
CREATE INDEX idx_user_achievement_progress_user_id ON public.user_achievement_progress(user_id);

CREATE INDEX idx_community_activities_user_id ON public.community_activities(user_id);
CREATE INDEX idx_community_activities_created_at ON public.community_activities(created_at DESC);
CREATE INDEX idx_community_activities_visibility ON public.community_activities(visibility);
CREATE INDEX idx_community_activities_type ON public.community_activities(activity_type);
CREATE INDEX idx_community_activities_achievement ON public.community_activities(is_achievement);

CREATE INDEX idx_user_friends_requester ON public.user_friends(requester_id);
CREATE INDEX idx_user_friends_requested ON public.user_friends(requested_id);
CREATE INDEX idx_user_friends_status ON public.user_friends(status);

CREATE INDEX idx_activity_reactions_activity ON public.activity_reactions(activity_id);
CREATE INDEX idx_activity_reactions_user ON public.activity_reactions(user_id);
CREATE INDEX idx_activity_comments_activity ON public.activity_comments(activity_id);
CREATE INDEX idx_activity_comments_parent ON public.activity_comments(parent_comment_id);

CREATE INDEX idx_community_challenges_status ON public.community_challenges(status);
CREATE INDEX idx_community_challenges_type ON public.community_challenges(challenge_type);
CREATE INDEX idx_community_challenges_dates ON public.community_challenges(start_date, end_date);

CREATE INDEX idx_challenge_participants_challenge ON public.challenge_participants(challenge_id);
CREATE INDEX idx_challenge_participants_user ON public.challenge_participants(user_id);
CREATE INDEX idx_challenge_participants_completed ON public.challenge_participants(is_completed);

CREATE INDEX idx_water_intake_user_id ON public.water_intake(user_id);
CREATE INDEX idx_water_intake_date ON public.water_intake(intake_date);
CREATE INDEX idx_user_goals_user_id ON public.user_goals(user_id);
CREATE INDEX idx_user_goals_active ON public.user_goals(is_active);
CREATE INDEX idx_body_measurements_user_id ON public.body_measurements(user_id);
CREATE INDEX idx_body_measurements_date ON public.body_measurements(measurement_date);

CREATE INDEX idx_user_stories_user_id ON public.user_stories(user_id);
CREATE INDEX idx_user_stories_expires ON public.user_stories(expires_at);
CREATE INDEX idx_user_stories_created ON public.user_stories(created_at DESC);

-- 13. Enable Row Level Security on all tables
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fitness_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_program_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meditations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meditation_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievement_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievement_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_intake ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activity_settings ENABLE ROW LEVEL SECURITY;

-- 14. Helper Functions (Must be created BEFORE RLS policies)
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

CREATE OR REPLACE FUNCTION public.can_access_friendship(requester_uuid UUID, requested_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid()
    AND (up.id = requester_uuid OR up.id = requested_uuid)
)
$$;

-- 15. RLS Policies using correct patterns

-- Pattern 2: Simple User Ownership for user-specific tables
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

CREATE POLICY "users_manage_own_enrollments"
ON public.user_program_enrollments
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_activities"
ON public.community_activities
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_reactions"
ON public.activity_reactions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_comments"
ON public.activity_comments
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_stories"
ON public.user_stories
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_activity_settings"
ON public.user_activity_settings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

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

CREATE POLICY "public_read_meditation_templates"
ON public.meditation_templates
FOR SELECT
TO public
USING (true);

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

-- Pattern 6: Role-based access for premium meditation templates
CREATE POLICY "premium_meditation_access"
ON public.meditation_templates
FOR SELECT
TO authenticated
USING (NOT is_premium OR public.can_access_premium_content());

-- Pattern 7: Complex Relationships for friend system
CREATE POLICY "users_manage_own_friendships"
ON public.user_friends
FOR ALL
TO authenticated
USING (public.can_access_friendship(requester_id, requested_id))
WITH CHECK (requester_id = auth.uid());

-- Pattern 5: User Validation for meal ingredients (relationship table)
CREATE POLICY "users_manage_meal_ingredients"
ON public.meal_ingredients
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.meals m 
        WHERE m.id = meal_ingredients.meal_id 
        AND m.user_id = auth.uid()
    )
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

-- Challenge participation policies
CREATE POLICY "users_manage_own_challenge_participation"
ON public.challenge_participants
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Story views tracking
CREATE POLICY "users_manage_story_views"
ON public.story_views
FOR ALL
TO authenticated
USING (viewer_id = auth.uid())
WITH CHECK (viewer_id = auth.uid());

-- 16. Utility Functions for wellness features
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

-- Get personalized community feed for user
CREATE OR REPLACE FUNCTION public.get_community_feed(
    requesting_user_id UUID DEFAULT auth.uid(),
    feed_limit INTEGER DEFAULT 20,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE(
    activity_id UUID,
    user_id UUID,
    user_name TEXT,
    user_avatar TEXT,
    activity_type TEXT,
    title TEXT,
    description TEXT,
    activity_data JSONB,
    media_urls TEXT[],
    tags TEXT[],
    is_achievement BOOLEAN,
    achievement_badge TEXT,
    created_at TIMESTAMPTZ,
    reaction_count INTEGER,
    comment_count INTEGER,
    user_has_reacted BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
WITH friend_ids AS (
    SELECT CASE 
        WHEN uf.requester_id = requesting_user_id THEN uf.requested_id
        ELSE uf.requester_id
    END as friend_id
    FROM public.user_friends uf
    WHERE (uf.requester_id = requesting_user_id OR uf.requested_id = requesting_user_id)
    AND uf.status = 'accepted'
),
visible_activities AS (
    SELECT ca.*
    FROM public.community_activities ca
    WHERE (
        ca.visibility = 'public' 
        OR (ca.visibility = 'friends' AND (ca.user_id IN (SELECT friend_id FROM friend_ids) OR ca.user_id = requesting_user_id))
        OR ca.user_id = requesting_user_id
    )
    AND ca.created_at >= CURRENT_TIMESTAMP - INTERVAL '30 days' -- Only recent activities
)
SELECT 
    va.id as activity_id,
    va.user_id,
    up.full_name as user_name,
    up.avatar_url as user_avatar,
    va.activity_type,
    va.title,
    va.description,
    va.activity_data,
    va.media_urls,
    va.tags,
    va.is_achievement,
    va.achievement_badge,
    va.created_at,
    COALESCE(reaction_stats.reaction_count, 0)::INTEGER as reaction_count,
    COALESCE(comment_stats.comment_count, 0)::INTEGER as comment_count,
    COALESCE(user_reactions.has_reacted, false) as user_has_reacted
FROM visible_activities va
JOIN public.user_profiles up ON va.user_id = up.id
LEFT JOIN (
    SELECT 
        ar.activity_id,
        COUNT(ar.id)::INTEGER as reaction_count
    FROM public.activity_reactions ar
    GROUP BY ar.activity_id
) reaction_stats ON va.id = reaction_stats.activity_id
LEFT JOIN (
    SELECT 
        ac.activity_id,
        COUNT(ac.id)::INTEGER as comment_count
    FROM public.activity_comments ac
    GROUP BY ac.activity_id
) comment_stats ON va.id = comment_stats.activity_id
LEFT JOIN (
    SELECT 
        ar.activity_id,
        true as has_reacted
    FROM public.activity_reactions ar
    WHERE ar.user_id = requesting_user_id
) user_reactions ON va.id = user_reactions.activity_id
ORDER BY va.created_at DESC
LIMIT feed_limit OFFSET offset_count
$$;

-- Clean up expired stories
CREATE OR REPLACE FUNCTION public.cleanup_expired_stories()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.user_stories
    WHERE expires_at < CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

-- 17. Comprehensive Mock Data for AlignWise Wellness Platform
DO $$
DECLARE
    existing_admin_id UUID;
    existing_user_id UUID;
    food_item1_id UUID := gen_random_uuid();
    food_item2_id UUID := gen_random_uuid();
    food_item3_id UUID := gen_random_uuid();
    food_item4_id UUID := gen_random_uuid();
    existing_exercise1_id UUID;
    existing_exercise2_id UUID;
    existing_exercise3_id UUID;
    existing_exercise4_id UUID;
    meal1_id UUID := gen_random_uuid();
    meal2_id UUID := gen_random_uuid();
    workout1_id UUID := gen_random_uuid();
    workout2_id UUID := gen_random_uuid();
    program1_id UUID := gen_random_uuid();
    program2_id UUID := gen_random_uuid();
    workout1_prog_id UUID := gen_random_uuid();
    workout2_prog_id UUID := gen_random_uuid();
    meditation_template1_id UUID := gen_random_uuid();
    meditation_template2_id UUID := gen_random_uuid();
    meditation1_id UUID := gen_random_uuid();
    achievement1_id UUID := gen_random_uuid();
    achievement2_id UUID := gen_random_uuid();
    achievement3_id UUID := gen_random_uuid();
    challenge1_id UUID := gen_random_uuid();
    challenge2_id UUID := gen_random_uuid();
    activity1_id UUID := gen_random_uuid();
    activity2_id UUID := gen_random_uuid();
    story1_id UUID := gen_random_uuid();
BEGIN
    -- Get existing user IDs from the subscription system
    SELECT id INTO existing_admin_id FROM public.user_profiles WHERE email = 'admin@alignwise.com' LIMIT 1;
    SELECT id INTO existing_user_id FROM public.user_profiles WHERE email = 'user@alignwise.com' LIMIT 1;
    
    -- Get existing exercise IDs
    SELECT id INTO existing_exercise1_id FROM public.exercises WHERE name = 'Push-ups' LIMIT 1;
    SELECT id INTO existing_exercise2_id FROM public.exercises WHERE name = 'Squats' LIMIT 1;
    
    -- If we don't have the basic exercises, get any exercises
    IF existing_exercise1_id IS NULL THEN
        SELECT id INTO existing_exercise1_id FROM public.exercises LIMIT 1;
    END IF;
    IF existing_exercise2_id IS NULL THEN
        SELECT id INTO existing_exercise2_id FROM public.exercises LIMIT 1 OFFSET 1;
    END IF;

    -- Only proceed if users exist
    IF existing_admin_id IS NOT NULL AND existing_user_id IS NOT NULL THEN
        
        -- Insert comprehensive food items database
        INSERT INTO public.food_items (id, name, brand, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g) VALUES
            (food_item1_id, 'Chicken Breast', 'Generic', 165, 31.0, 0.0, 3.6, 0.0, 0.0, 74),
            (food_item2_id, 'Brown Rice', 'Generic', 123, 2.6, 23.0, 0.9, 1.8, 0.4, 7),
            (food_item3_id, 'Greek Yogurt', 'Generic', 97, 9.0, 3.6, 5.0, 0.0, 3.6, 36),
            (food_item4_id, 'Banana', 'Generic', 89, 1.1, 22.8, 0.3, 2.6, 12.2, 1);

        -- Insert meditation templates
        INSERT INTO public.meditation_templates (id, title, description, meditation_type, duration_minutes, is_premium, difficulty_level, tags) VALUES
            (meditation_template1_id, 'Morning Mindfulness', 'Start your day with peaceful awareness and intention setting', 'mindfulness', 10, false, 1, ARRAY['morning', 'beginner', 'awareness']),
            (meditation_template2_id, 'Deep Breathing for Sleep', 'Relaxing breathing exercises to prepare for restful sleep', 'breathing', 15, true, 2, ARRAY['evening', 'sleep', 'relaxation']);

        -- Insert fitness programs
        INSERT INTO public.fitness_programs (id, title, description, difficulty, duration_weeks, workouts_per_week, equipment_required, muscle_groups_targeted, is_premium, created_by) VALUES
            (program1_id, 'Beginner Foundation', 'A comprehensive 8-week program designed for fitness beginners to build strength, endurance, and healthy habits', 'beginner', 8, 3, ARRAY['bodyweight', 'resistance_bands'], ARRAY['full_body', 'core', 'cardiovascular'], false, existing_admin_id),
            (program2_id, 'Advanced HIIT Challenge', 'Intense 6-week high-intensity interval training program for experienced fitness enthusiasts', 'advanced', 6, 4, ARRAY['bodyweight', 'dumbbells', 'kettlebell'], ARRAY['full_body', 'cardio', 'explosive_power'], true, existing_admin_id);

        -- Insert program workouts
        INSERT INTO public.program_workouts (id, program_id, week_number, day_number, workout_title, workout_description, estimated_duration) VALUES
            (workout1_prog_id, program1_id, 1, 1, 'Foundation Upper Body', 'Focus on basic upper body movements with proper form and control', 30),
            (workout2_prog_id, program1_id, 1, 3, 'Foundation Lower Body', 'Build lower body strength with bodyweight exercises and stability work', 35);

        -- Insert program exercises if we have exercise IDs
        IF existing_exercise1_id IS NOT NULL AND existing_exercise2_id IS NOT NULL THEN
            INSERT INTO public.program_exercises (program_workout_id, exercise_id, sets, reps, weight_recommendation, exercise_order) VALUES
                (workout1_prog_id, existing_exercise1_id, 3, 12, 'bodyweight', 1),
                (workout2_prog_id, existing_exercise2_id, 3, 15, 'bodyweight', 1);
        END IF;

        -- Insert achievement definitions
        INSERT INTO public.achievement_definitions (id, title, description, achievement_type, badge_rarity, target_value, target_unit, points_awarded) VALUES
            (achievement1_id, 'Fitness Explorer', 'Complete your first workout program and embark on your fitness journey', 'program_completion', 'common', 1, 'programs', 100),
            (achievement2_id, 'Consistency Champion', 'Maintain a 7-day workout streak and build lasting habits', 'workout_streak', 'rare', 7, 'days', 250),
            (achievement3_id, 'Mindful Master', 'Complete 30 meditation sessions and develop inner peace', 'mindfulness_streak', 'epic', 30, 'sessions', 500);

        -- Insert user goals
        INSERT INTO public.user_goals (user_id, goal_type, target_weight_kg, current_weight_kg, target_calories, target_protein, target_carbs, target_fat, target_water_ml) VALUES
            (existing_user_id, 'weight_loss', 70.0, 75.0, 2000, 150.0, 200.0, 65.0, 2500),
            (existing_admin_id, 'muscle_gain', 80.0, 75.0, 2800, 200.0, 300.0, 95.0, 3000);

        -- Insert sample meals
        INSERT INTO public.meals (id, user_id, meal_type, name, description, calories, protein, carbs, fat, fiber) VALUES
            (meal1_id, existing_user_id, 'lunch', 'Grilled Chicken Power Bowl', 'Nutritious lunch with grilled chicken, brown rice, and vegetables', 450, 35.0, 40.0, 8.0, 3.5),
            (meal2_id, existing_admin_id, 'breakfast', 'Greek Yogurt Berry Parfait', 'High-protein breakfast with Greek yogurt, banana, and berries', 320, 20.0, 35.0, 8.5, 4.2);

        -- Insert meal ingredients
        INSERT INTO public.meal_ingredients (meal_id, food_item_id, quantity) VALUES
            (meal1_id, food_item1_id, 150.0), -- Chicken
            (meal1_id, food_item2_id, 100.0), -- Rice
            (meal2_id, food_item3_id, 200.0), -- Greek Yogurt
            (meal2_id, food_item4_id, 120.0); -- Banana

        -- Insert user program enrollment
        INSERT INTO public.user_program_enrollments (user_id, program_id, current_week, current_day, completion_percentage) VALUES
            (existing_user_id, program1_id, 1, 2, 15.0);

        -- Insert sample workouts
        INSERT INTO public.workouts (id, user_id, name, activity_type, status, duration_minutes, calories_burned, intensity) VALUES
            (workout1_id, existing_user_id, 'Morning Cardio Session', 'cardio', 'completed', 30, 250, 'moderate'),
            (workout2_id, existing_admin_id, 'Strength Training Upper', 'strength', 'completed', 45, 320, 'high');

        -- Insert workout exercises if we have exercise IDs
        IF existing_exercise1_id IS NOT NULL AND existing_exercise2_id IS NOT NULL THEN
            INSERT INTO public.workout_exercises (workout_id, exercise_id, sets, reps, exercise_order) VALUES
                (workout1_id, existing_exercise1_id, 3, 15, 1),
                (workout1_id, existing_exercise2_id, 3, 20, 2),
                (workout2_id, existing_exercise1_id, 4, 12, 1);
        END IF;

        -- Insert meditation sessions
        INSERT INTO public.meditations (user_id, meditation_type, title, duration_minutes, mood_before, mood_after, is_completed, background_sound) VALUES
            (existing_user_id, 'mindfulness', 'Morning Mindfulness', 10, 'neutral', 'happy', true, 'rain'),
            (existing_admin_id, 'breathing', 'Evening Breathing', 15, 'sad', 'neutral', true, 'ocean');

        -- Insert community challenges
        INSERT INTO public.community_challenges (id, creator_id, title, description, challenge_type, target_value, target_unit, start_date, end_date, status, max_participants) VALUES
            (challenge1_id, existing_admin_id, 'January Fitness Kickstart', 'Join thousands of users in completing 20 workouts this month and start the year strong', 'fitness', 20, 'workouts', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', 'active', 10000),
            (challenge2_id, existing_admin_id, 'Mindful February', 'Cultivate daily mindfulness with meditation sessions throughout February', 'mindfulness', 28, 'days', CURRENT_DATE + INTERVAL '1 day', CURRENT_DATE + INTERVAL '29 days', 'upcoming', 5000);

        -- Insert challenge participation
        INSERT INTO public.challenge_participants (challenge_id, user_id, progress_value) VALUES
            (challenge1_id, existing_user_id, 5),
            (challenge1_id, existing_admin_id, 3),
            (challenge2_id, existing_user_id, 0);

        -- Create friendship between users
        INSERT INTO public.user_friends (requester_id, requested_id, status, accepted_at) VALUES
            (existing_user_id, existing_admin_id, 'accepted', CURRENT_TIMESTAMP);

        -- Create activity settings for users
        INSERT INTO public.user_activity_settings (user_id, auto_share_workouts, auto_share_meditations, auto_share_achievements) VALUES
            (existing_admin_id, true, true, true),
            (existing_user_id, true, false, true);

        -- Create sample community activities
        INSERT INTO public.community_activities (id, user_id, activity_type, title, description, is_achievement, achievement_badge, related_workout_id, tags) VALUES
            (activity1_id, existing_user_id, 'workout_completed', 'Completed Morning Cardio Session!', 'Just finished a great 30-minute cardio workout. Feeling energized and ready to tackle the day!', false, null, workout1_id, ARRAY['cardio', 'morning', 'energy']),
            (activity2_id, existing_admin_id, 'achievement_unlocked', 'Achievement Unlocked: Fitness Explorer!', 'Completed my first workout program and officially started my fitness journey', true, 'fitness_explorer', null, ARRAY['achievement', 'milestone', 'fitness']);

        -- Create sample reactions and comments
        INSERT INTO public.activity_reactions (activity_id, user_id, reaction_type) VALUES
            (activity1_id, existing_admin_id, 'fire'),
            (activity2_id, existing_user_id, 'celebrate');

        INSERT INTO public.activity_comments (activity_id, user_id, comment_text) VALUES
            (activity1_id, existing_admin_id, 'Amazing work! Keep up the great momentum! 💪'),
            (activity2_id, existing_user_id, 'Congratulations! That is such an inspiring achievement! 🎉');

        -- Insert user achievements
        INSERT INTO public.user_achievements (user_id, achievement_id, progress_value, is_completed, completed_at) VALUES
            (existing_user_id, achievement1_id, 1, true, CURRENT_TIMESTAMP),
            (existing_admin_id, achievement2_id, 5, false, null);

        INSERT INTO public.user_achievement_progress (user_id, achievement_id, current_progress, target_progress, progress_percentage) VALUES
            (existing_admin_id, achievement2_id, 5, 7, 71.43),
            (existing_user_id, achievement3_id, 12, 30, 40.0);

        -- Insert water intake tracking
        INSERT INTO public.water_intake (user_id, amount_ml, intake_time) VALUES
            (existing_user_id, 250, NOW() - INTERVAL '2 hours'),
            (existing_user_id, 500, NOW() - INTERVAL '4 hours'),
            (existing_user_id, 300, NOW() - INTERVAL '6 hours'),
            (existing_admin_id, 400, NOW() - INTERVAL '1 hour'),
            (existing_admin_id, 350, NOW() - INTERVAL '3 hours');

        -- Insert body measurements
        INSERT INTO public.body_measurements (user_id, weight_kg, body_fat_percentage, muscle_mass_kg) VALUES
            (existing_user_id, 74.5, 18.2, 32.5),
            (existing_admin_id, 76.2, 15.8, 38.2);

        -- Create sample story
        INSERT INTO public.user_stories (id, user_id, title, media_url, story_type, description) VALUES
            (story1_id, existing_user_id, 'Post-Workout Achievement!', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400', 'workout_selfie', 'Feeling incredible after completing my morning cardio session! 💪');

        -- Track story view
        INSERT INTO public.story_views (story_id, viewer_id) VALUES
            (story1_id, existing_admin_id);

    ELSE
        RAISE NOTICE 'Existing user profiles not found. Please ensure subscription management migration is applied first.';
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error in comprehensive wellness data: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error in comprehensive wellness data: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error in comprehensive wellness data creation: %', SQLERRM;
END $$;

-- 18. Cleanup function for all AlignWise wellness data
CREATE OR REPLACE FUNCTION public.cleanup_alignwise_wellness_test_data()
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

    -- Delete wellness data in dependency order (children first)
    DELETE FROM public.story_views WHERE story_id IN (
        SELECT id FROM public.user_stories WHERE user_id = ANY(user_ids_to_clean)
    );
    DELETE FROM public.user_stories WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.activity_comments WHERE activity_id IN (
        SELECT id FROM public.community_activities WHERE user_id = ANY(user_ids_to_clean)
    );
    DELETE FROM public.activity_reactions WHERE activity_id IN (
        SELECT id FROM public.community_activities WHERE user_id = ANY(user_ids_to_clean)
    );
    DELETE FROM public.community_activities WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.challenge_participants WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.community_challenges WHERE creator_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_friends WHERE requester_id = ANY(user_ids_to_clean) OR requested_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_activity_settings WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_achievement_progress WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_achievements WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.program_exercises WHERE program_workout_id IN (
        SELECT pw.id FROM public.program_workouts pw
        JOIN public.fitness_programs fp ON pw.program_id = fp.id
        WHERE fp.created_by = ANY(user_ids_to_clean)
    );
    DELETE FROM public.program_workouts WHERE program_id IN (
        SELECT id FROM public.fitness_programs WHERE created_by = ANY(user_ids_to_clean)
    );
    DELETE FROM public.fitness_programs WHERE created_by = ANY(user_ids_to_clean);
    DELETE FROM public.user_program_enrollments WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.workout_exercises WHERE workout_id IN (
        SELECT id FROM public.workouts WHERE user_id = ANY(user_ids_to_clean)
    );
    DELETE FROM public.workouts WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.meditations WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.meal_ingredients WHERE meal_id IN (
        SELECT id FROM public.meals WHERE user_id = ANY(user_ids_to_clean)
    );
    DELETE FROM public.meals WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.water_intake WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_goals WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.body_measurements WHERE user_id = ANY(user_ids_to_clean);

    -- Clean up reference data
    DELETE FROM public.food_items WHERE name LIKE '%Generic%';
    DELETE FROM public.meditation_templates WHERE title IN ('Morning Mindfulness', 'Deep Breathing for Sleep');
    DELETE FROM public.achievement_definitions WHERE title IN ('Fitness Explorer', 'Consistency Champion', 'Mindful Master');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents AlignWise wellness data deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'AlignWise wellness cleanup failed: %', SQLERRM;
END;
$$;