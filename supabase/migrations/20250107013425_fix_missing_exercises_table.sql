-- Location: supabase/migrations/20250107013425_fix_missing_exercises_table.sql
-- Schema Analysis: Fixing missing exercises table that fitness programs depend on
-- Integration Type: PARTIAL_EXISTS - Adding missing table to support existing fitness programs
-- Dependencies: user_profiles (existing)

-- 1. Create the missing exercises table that fitness programs migration expects
CREATE TABLE IF NOT EXISTS public.exercises (
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

-- 2. Create index for performance
CREATE INDEX IF NOT EXISTS idx_exercises_category ON public.exercises(category);

-- 3. Enable Row Level Security
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies - Public read access for exercises
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

-- 5. Insert essential exercise data that fitness programs expect
DO $$
BEGIN
    -- Insert basic exercises that are referenced in fitness programs migration
    INSERT INTO public.exercises (name, category, muscle_groups, equipment_needed, difficulty_level, instructions) 
    VALUES
        ('Push-ups', 'chest', ARRAY['chest', 'shoulders', 'triceps'], ARRAY['bodyweight'], 2, 'Start in plank position, lower body to ground, push back up'),
        ('Squats', 'legs', ARRAY['quadriceps', 'glutes', 'hamstrings'], ARRAY['bodyweight'], 2, 'Stand with feet shoulder-width apart, lower hips down and back, return to standing'),
        ('Pull-ups', 'back', ARRAY['lats', 'biceps', 'rhomboids'], ARRAY['pull-up bar'], 4, 'Hang from bar with arms extended, pull body up until chin clears bar'),
        ('Burpees', 'full_body', ARRAY['full_body', 'cardio'], ARRAY['bodyweight'], 3, 'Start standing, drop to plank, do push-up, jump feet to hands, jump up with arms overhead'),
        ('Plank', 'core', ARRAY['core', 'shoulders'], ARRAY['bodyweight'], 2, 'Hold push-up position with forearms on ground, keep body in straight line'),
        ('Mountain Climbers', 'cardio', ARRAY['core', 'shoulders', 'legs'], ARRAY['bodyweight'], 3, 'Start in plank position, alternate bringing knees to chest rapidly'),
        ('Lunges', 'legs', ARRAY['quadriceps', 'glutes', 'hamstrings'], ARRAY['bodyweight'], 2, 'Step forward into lunge position, return to standing, alternate legs'),
        ('Jumping Jacks', 'cardio', ARRAY['full_body', 'cardio'], ARRAY['bodyweight'], 1, 'Jump while spreading legs and raising arms overhead, return to start position');

EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Some exercises already exist, skipping duplicates';
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error in exercise data creation: %', SQLERRM;
END $$;

-- 6. Create cleanup function for exercises
CREATE OR REPLACE FUNCTION public.cleanup_exercises_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
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