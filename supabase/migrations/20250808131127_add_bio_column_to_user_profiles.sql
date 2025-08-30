-- Add missing bio column to user_profiles table
-- This fixes the error: column "bio" of relation "user_profiles" does not exist

-- Add bio column to existing user_profiles table
ALTER TABLE public.user_profiles 
ADD COLUMN bio TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.user_profiles.bio IS 'User biography or description text';

-- Create index for bio column if needed for search functionality
CREATE INDEX idx_user_profiles_bio ON public.user_profiles USING gin(to_tsvector('english', bio)) 
WHERE bio IS NOT NULL;

-- Update RLS policies to include bio column access (if needed)
-- Note: Existing policies should automatically cover the new column
-- as they use "FOR ALL" which includes SELECT, INSERT, UPDATE, DELETE operations

-- Log successful completion
DO $$
BEGIN
    RAISE NOTICE 'Successfully added bio column to user_profiles table';
    RAISE NOTICE 'Existing test data migration should now work properly';
END $$;