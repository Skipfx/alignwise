-- Fix Database Schema Inconsistencies and Type Errors
-- This migration fixes issues with enum types, function signatures, and column references

-- 1. Fix community_activities table activity_type enum
-- The activity_type enum was referencing a non-existent type, let's fix it
DROP TYPE IF EXISTS public.activity_type CASCADE;
CREATE TYPE public.activity_type AS ENUM (
  'workout',
  'meal',
  'meditation', 
  'achievement',
  'challenge',
  'water',
  'community_post',
  'milestone'
);

-- Update community_activities table to use the correct activity_type
ALTER TABLE public.community_activities 
  ALTER COLUMN activity_type TYPE public.activity_type 
  USING activity_type::text::public.activity_type;

-- 2. Fix visibility_type enum to match what's used in the tables
DROP TYPE IF EXISTS public.visibility_type CASCADE;
CREATE TYPE public.visibility_type AS ENUM ('public', 'friends', 'private');

-- Update community_activities visibility column
ALTER TABLE public.community_activities 
  ALTER COLUMN visibility TYPE public.visibility_type 
  USING COALESCE(visibility::text::public.visibility_type, 'friends'::public.visibility_type);

-- 3. Add missing columns that functions expect
ALTER TABLE public.community_activities ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;
ALTER TABLE public.community_activities ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0;

-- 4. Fix get_community_feed function with correct column references and return type
CREATE OR REPLACE FUNCTION public.get_community_feed(feed_limit integer DEFAULT 20, offset_count integer DEFAULT 0)
RETURNS TABLE(
  id uuid,
  user_id uuid,
  user_name text,
  activity_type public.activity_type,
  title text,
  description text,
  activity_data jsonb,
  media_urls text[],
  likes_count integer,
  comments_count integer,
  created_at timestamp with time zone,
  user_has_liked boolean
)
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
  COALESCE(ca.likes_count, 0) as likes_count,
  COALESCE(ca.comments_count, 0) as comments_count,
  ca.created_at,
  EXISTS(
    SELECT 1 FROM public.activity_reactions ar 
    WHERE ar.activity_id = ca.id AND ar.user_id = auth.uid()
  ) as user_has_liked
FROM public.community_activities ca
JOIN public.user_profiles up ON ca.user_id = up.id
WHERE ca.visibility IN ('public'::public.visibility_type, 'friends'::public.visibility_type)
ORDER BY ca.created_at DESC
LIMIT feed_limit
OFFSET offset_count;
$$;

-- 5. Fix get_user_program_progress function with correct column references
CREATE OR REPLACE FUNCTION public.get_user_program_progress()
RETURNS TABLE(
  program_id uuid,
  program_title text,
  completion_percentage decimal(5,2),
  current_week integer,
  total_weeks integer
)
LANGUAGE sql
STABLE 
SECURITY DEFINER
SET search_path = ''
AS $$
SELECT 
  upe.program_id,
  fp.title as program_title,
  upe.completion_percentage,
  upe.current_week,
  fp.duration_weeks as total_weeks
FROM public.user_program_enrollments upe
JOIN public.fitness_programs fp ON upe.program_id = fp.id
WHERE upe.user_id = auth.uid()
  AND upe.is_active = true;
$$;

-- 6. Update sample data to use correct enum values
UPDATE public.community_activities 
SET activity_type = 'workout'::public.activity_type 
WHERE activity_type::text = 'workout';

UPDATE public.community_activities 
SET activity_type = 'achievement'::public.activity_type 
WHERE activity_type::text = 'achievement';

-- 7. Update visibility values
UPDATE public.community_activities 
SET visibility = 'public'::public.visibility_type 
WHERE visibility::text = 'public';

-- 8. Add indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_community_activities_likes_count ON public.community_activities(likes_count);
CREATE INDEX IF NOT EXISTS idx_community_activities_comments_count ON public.community_activities(comments_count);
CREATE INDEX IF NOT EXISTS idx_community_activities_visibility ON public.community_activities(visibility);

-- 9. Update RLS policies to use correct enum types
DROP POLICY IF EXISTS "authenticated_read_public_activities" ON public.community_activities;
CREATE POLICY "authenticated_read_public_activities"
ON public.community_activities
FOR SELECT 
TO authenticated
USING (
  visibility IN ('public'::public.visibility_type, 'friends'::public.visibility_type)
);

-- 10. Fix any remaining inconsistencies in existing data
-- Update all NULL activity_type values to 'community_post'
UPDATE public.community_activities 
SET activity_type = 'community_post'::public.activity_type
WHERE activity_type IS NULL;

-- Update all NULL visibility values to 'friends'
UPDATE public.community_activities 
SET visibility = 'friends'::public.visibility_type
WHERE visibility IS NULL;

-- 11. Ensure likes_count and comments_count are never null
UPDATE public.community_activities 
SET likes_count = 0 
WHERE likes_count IS NULL;

UPDATE public.community_activities 
SET comments_count = 0 
WHERE comments_count IS NULL;

-- Make these columns NOT NULL after setting defaults
ALTER TABLE public.community_activities 
  ALTER COLUMN likes_count SET NOT NULL,
  ALTER COLUMN comments_count SET NOT NULL;

-- Grant necessary permissions
GRANT SELECT ON public.community_activities TO authenticated;
GRANT SELECT ON public.user_profiles TO authenticated;
GRANT SELECT ON public.user_program_enrollments TO authenticated;
GRANT SELECT ON public.fitness_programs TO authenticated;

-- Execute a DO block instead of bare RAISE NOTICE
DO $$ 
BEGIN 
  RAISE NOTICE 'Schema inconsistencies fixed successfully';
END $$;