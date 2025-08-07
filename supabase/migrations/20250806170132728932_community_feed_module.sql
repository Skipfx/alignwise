-- Location: supabase/migrations/20250806170132728932_community_feed_module.sql
-- Schema Analysis: Adding community feed features to existing wellness platform
-- Integration Type: NEW_MODULE - Adding social/community functionality
-- Dependencies: user_profiles (existing), workouts (existing), meditations (existing), meals (existing)

-- 1. Community-specific Types
CREATE TYPE public.activity_visibility AS ENUM ('public', 'friends', 'private');
CREATE TYPE public.challenge_type AS ENUM ('fitness', 'nutrition', 'mindfulness', 'water', 'general');
CREATE TYPE public.challenge_status AS ENUM ('upcoming', 'active', 'completed', 'cancelled');
CREATE TYPE public.reaction_type AS ENUM ('like', 'love', 'celebrate', 'encourage', 'fire');
CREATE TYPE public.friend_status AS ENUM ('pending', 'accepted', 'blocked');

-- 2. Community Feed Activities Table
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

-- 3. Friend System
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

-- 4. Activity Reactions (Likes, Comments, etc.)
CREATE TABLE public.activity_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID REFERENCES public.community_activities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    reaction_type public.reaction_type DEFAULT 'like',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(activity_id, user_id, reaction_type)
);

-- 5. Activity Comments
CREATE TABLE public.activity_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID REFERENCES public.community_activities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    comment_text TEXT NOT NULL,
    parent_comment_id UUID REFERENCES public.activity_comments(id) ON DELETE CASCADE, -- For replies
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Community Challenges
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

-- 7. Challenge Participants
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

-- 8. Challenge Teams (for team-based challenges)
CREATE TABLE public.challenge_teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID REFERENCES public.community_challenges(id) ON DELETE CASCADE,
    team_name TEXT NOT NULL,
    team_captain_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    team_description TEXT,
    team_motto TEXT,
    max_members INTEGER DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 9. Challenge Team Members
CREATE TABLE public.challenge_team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES public.challenge_teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_captain BOOLEAN DEFAULT false,
    UNIQUE(team_id, user_id)
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

-- 11. Story Views (track who viewed stories)
CREATE TABLE public.story_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id UUID REFERENCES public.user_stories(id) ON DELETE CASCADE,
    viewer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    viewed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(story_id, viewer_id)
);

-- 12. User Activity Settings (Privacy controls)
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

-- 13. Essential Indexes for Performance
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

CREATE INDEX idx_user_stories_user_id ON public.user_stories(user_id);
CREATE INDEX idx_user_stories_expires ON public.user_stories(expires_at);
CREATE INDEX idx_user_stories_created ON public.user_stories(created_at DESC);

-- 14. Enable Row Level Security
ALTER TABLE public.community_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activity_settings ENABLE ROW LEVEL SECURITY;

-- 15. RLS Policies using correct patterns

-- Pattern 2: Simple User Ownership
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

-- Pattern 4: Public Read, Private Write for challenges
CREATE POLICY "public_read_challenges"
ON public.community_challenges
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "users_manage_own_challenges"
ON public.community_challenges
FOR ALL
TO authenticated
USING (creator_id = auth.uid())
WITH CHECK (creator_id = auth.uid());

-- Pattern 7: Complex Relationships for friend system
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

CREATE POLICY "users_manage_own_friendships"
ON public.user_friends
FOR ALL
TO authenticated
USING (public.can_access_friendship(requester_id, requested_id))
WITH CHECK (requester_id = auth.uid());

-- Challenge participation policies
CREATE POLICY "users_manage_own_challenge_participation"
ON public.challenge_participants
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_read_challenge_teams"
ON public.challenge_teams
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "team_captains_manage_teams"
ON public.challenge_teams
FOR ALL
TO authenticated
USING (team_captain_id = auth.uid())
WITH CHECK (team_captain_id = auth.uid());

CREATE POLICY "users_manage_team_memberships"
ON public.challenge_team_members
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

-- 16. Community Feed Functions

-- Get personalized feed for user
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

-- Get friend suggestions based on mutual connections
CREATE OR REPLACE FUNCTION public.get_friend_suggestions(
    requesting_user_id UUID DEFAULT auth.uid(),
    suggestion_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
    user_id UUID,
    full_name TEXT,
    avatar_url TEXT,
    mutual_friends_count INTEGER,
    common_interests TEXT[]
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
WITH user_friends AS (
    SELECT CASE 
        WHEN uf.requester_id = requesting_user_id THEN uf.requested_id
        ELSE uf.requester_id
    END as friend_id
    FROM public.user_friends uf
    WHERE (uf.requester_id = requesting_user_id OR uf.requested_id = requesting_user_id)
    AND uf.status = 'accepted'
),
potential_friends AS (
    SELECT DISTINCT
        CASE 
            WHEN uf2.requester_id IN (SELECT friend_id FROM user_friends) THEN uf2.requested_id
            ELSE uf2.requester_id
        END as suggested_user_id
    FROM public.user_friends uf2
    WHERE (uf2.requester_id IN (SELECT friend_id FROM user_friends) 
           OR uf2.requested_id IN (SELECT friend_id FROM user_friends))
    AND uf2.status = 'accepted'
    AND NOT EXISTS (
        SELECT 1 FROM public.user_friends uf3
        WHERE ((uf3.requester_id = requesting_user_id AND uf3.requested_id = CASE WHEN uf2.requester_id IN (SELECT friend_id FROM user_friends) THEN uf2.requested_id ELSE uf2.requester_id END)
               OR (uf3.requested_id = requesting_user_id AND uf3.requester_id = CASE WHEN uf2.requester_id IN (SELECT friend_id FROM user_friends) THEN uf2.requested_id ELSE uf2.requester_id END))
    )
    AND CASE WHEN uf2.requester_id IN (SELECT friend_id FROM user_friends) THEN uf2.requested_id ELSE uf2.requester_id END != requesting_user_id
)
SELECT 
    pf.suggested_user_id as user_id,
    up.full_name,
    up.avatar_url,
    0 as mutual_friends_count, -- Simplified for now
    ARRAY[]::TEXT[] as common_interests -- Simplified for now
FROM potential_friends pf
JOIN public.user_profiles up ON pf.suggested_user_id = up.id
WHERE up.is_active = true
LIMIT suggestion_limit
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

-- 17. Mock Data for Community Features
DO $$
DECLARE
    existing_admin_id UUID;
    existing_user_id UUID;
    activity1_id UUID := gen_random_uuid();
    activity2_id UUID := gen_random_uuid();
    challenge1_id UUID := gen_random_uuid();
    story1_id UUID := gen_random_uuid();
BEGIN
    -- Get existing user IDs
    SELECT id INTO existing_admin_id FROM public.user_profiles WHERE email = 'admin@alignwise.com' LIMIT 1;
    SELECT id INTO existing_user_id FROM public.user_profiles WHERE email = 'user@alignwise.com' LIMIT 1;

    IF existing_admin_id IS NOT NULL AND existing_user_id IS NOT NULL THEN
        
        -- Create friendship between users
        INSERT INTO public.user_friends (requester_id, requested_id, status, accepted_at)
        VALUES (existing_user_id, existing_admin_id, 'accepted', CURRENT_TIMESTAMP);

        -- Create activity settings for users
        INSERT INTO public.user_activity_settings (user_id) VALUES
            (existing_admin_id),
            (existing_user_id);

        -- Create sample community activities
        INSERT INTO public.community_activities (id, user_id, activity_type, title, description, is_achievement, achievement_badge) VALUES
            (activity1_id, existing_user_id, 'workout_completed', 'Completed Morning Cardio!', 'Just finished a great 30-minute run in the park. Feeling energized!', true, 'cardio_champion'),
            (activity2_id, existing_admin_id, 'meditation_session', 'Peaceful Morning Meditation', 'Started the day with 15 minutes of mindfulness. Ready to take on the day!', false, null);

        -- Create sample community challenge
        INSERT INTO public.community_challenges (id, creator_id, title, description, challenge_type, target_value, target_unit, start_date, end_date, status) VALUES
            (challenge1_id, existing_admin_id, '30-Day Fitness Challenge', 'Complete at least 20 minutes of exercise every day for 30 days', 'fitness', 30, 'days', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', 'active');

        -- Join users to challenge
        INSERT INTO public.challenge_participants (challenge_id, user_id, progress_value) VALUES
            (challenge1_id, existing_user_id, 5),
            (challenge1_id, existing_admin_id, 3);

        -- Create sample reactions
        INSERT INTO public.activity_reactions (activity_id, user_id, reaction_type) VALUES
            (activity1_id, existing_admin_id, 'fire'),
            (activity2_id, existing_user_id, 'love');

        -- Create sample comments
        INSERT INTO public.activity_comments (activity_id, user_id, comment_text) VALUES
            (activity1_id, existing_admin_id, 'Amazing work! Keep it up! 💪'),
            (activity2_id, existing_user_id, 'Love starting the day with meditation too! 🧘‍♀️');

        -- Create sample story
        INSERT INTO public.user_stories (id, user_id, title, media_url, story_type, description) VALUES
            (story1_id, existing_user_id, 'Post-Workout Glow', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400', 'workout_selfie', 'Feeling great after that morning run!');

        -- Track story view
        INSERT INTO public.story_views (story_id, viewer_id) VALUES
            (story1_id, existing_admin_id);

    ELSE
        RAISE NOTICE 'Existing user profiles not found. Please ensure previous migrations are applied first.';
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error in community feed data: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error in community feed data: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error in community feed data creation: %', SQLERRM;
END $$;

-- 18. Cleanup function for community data
CREATE OR REPLACE FUNCTION public.cleanup_community_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_ids_to_clean UUID[];
BEGIN
    -- Get user IDs for test accounts
    SELECT ARRAY_AGG(id) INTO user_ids_to_clean
    FROM public.user_profiles
    WHERE email LIKE '%@alignwise.com';

    -- Delete community data in dependency order
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
    DELETE FROM public.challenge_team_members WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.challenge_teams WHERE team_captain_id = ANY(user_ids_to_clean);
    DELETE FROM public.challenge_participants WHERE user_id = ANY(user_ids_to_clean);
    DELETE FROM public.community_challenges WHERE creator_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_friends WHERE requester_id = ANY(user_ids_to_clean) OR requested_id = ANY(user_ids_to_clean);
    DELETE FROM public.user_activity_settings WHERE user_id = ANY(user_ids_to_clean);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents community data deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Community cleanup failed: %', SQLERRM;
END;
$$;