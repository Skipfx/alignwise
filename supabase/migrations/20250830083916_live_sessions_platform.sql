-- Location: supabase/migrations/20250830083916_live_sessions_platform.sql
-- Schema Analysis: Existing wellness platform with user_profiles, community features, and fitness programs
-- Integration Type: Addition - Live sessions platform for real-time wellness experiences
-- Dependencies: user_profiles table for instructor/participant relationships

-- 1. Types and Enums
CREATE TYPE public.session_status AS ENUM ('scheduled', 'live', 'ended', 'cancelled');
CREATE TYPE public.session_type AS ENUM ('yoga', 'hiit', 'meditation', 'nutrition', 'pilates', 'strength', 'cardio', 'dance');
CREATE TYPE public.difficulty_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE public.participant_status AS ENUM ('registered', 'joined', 'left', 'completed');

-- 2. Core Tables

-- Live Sessions table
CREATE TABLE public.live_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    instructor_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    session_type public.session_type NOT NULL,
    difficulty_level public.difficulty_level DEFAULT 'beginner',
    duration_minutes INTEGER NOT NULL DEFAULT 30,
    max_participants INTEGER DEFAULT 100,
    current_participants INTEGER DEFAULT 0,
    status public.session_status DEFAULT 'scheduled',
    scheduled_start TIMESTAMPTZ NOT NULL,
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,
    stream_url TEXT,
    chat_enabled BOOLEAN DEFAULT true,
    recording_enabled BOOLEAN DEFAULT false,
    recording_url TEXT,
    required_equipment TEXT[],
    session_image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Session Participants table
CREATE TABLE public.session_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.live_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status public.participant_status DEFAULT 'registered',
    joined_at TIMESTAMPTZ,
    left_at TIMESTAMPTZ,
    heart_rate_sharing BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(session_id, user_id)
);

-- Session Chat Messages table
CREATE TABLE public.session_chat (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.live_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type TEXT DEFAULT 'text', -- 'text', 'emoji', 'system'
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Session Reactions table
CREATE TABLE public.session_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.live_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    reaction_type TEXT NOT NULL, -- 'heart', 'fire', 'clap', 'muscle'
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Session Polls table
CREATE TABLE public.session_polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.live_sessions(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    options JSONB NOT NULL, -- Array of poll options with vote counts
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Session Poll Votes table
CREATE TABLE public.session_poll_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID REFERENCES public.session_polls(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    option_index INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(poll_id, user_id)
);

-- Session Q&A table
CREATE TABLE public.session_qna (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.live_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    answer TEXT,
    answered_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    answered_at TIMESTAMPTZ,
    is_answered BOOLEAN DEFAULT false,
    upvotes INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Session Bookmarks table
CREATE TABLE public.session_bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.live_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(session_id, user_id)
);

-- Session Ratings table
CREATE TABLE public.session_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.live_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(session_id, user_id)
);

-- Instructor Following table
CREATE TABLE public.instructor_followers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instructor_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    follower_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(instructor_id, follower_id)
);

-- 3. Essential Indexes
CREATE INDEX idx_live_sessions_instructor_id ON public.live_sessions(instructor_id);
CREATE INDEX idx_live_sessions_status ON public.live_sessions(status);
CREATE INDEX idx_live_sessions_scheduled_start ON public.live_sessions(scheduled_start);
CREATE INDEX idx_live_sessions_session_type ON public.live_sessions(session_type);
CREATE INDEX idx_session_participants_session_id ON public.session_participants(session_id);
CREATE INDEX idx_session_participants_user_id ON public.session_participants(user_id);
CREATE INDEX idx_session_chat_session_id ON public.session_chat(session_id);
CREATE INDEX idx_session_chat_created_at ON public.session_chat(created_at);
CREATE INDEX idx_session_reactions_session_id ON public.session_reactions(session_id);
CREATE INDEX idx_session_polls_session_id ON public.session_polls(session_id);
CREATE INDEX idx_session_qna_session_id ON public.session_qna(session_id);
CREATE INDEX idx_session_bookmarks_user_id ON public.session_bookmarks(user_id);
CREATE INDEX idx_instructor_followers_instructor_id ON public.instructor_followers(instructor_id);
CREATE INDEX idx_instructor_followers_follower_id ON public.instructor_followers(follower_id);

-- 4. Functions

-- Function to update participant count
CREATE OR REPLACE FUNCTION public.update_session_participant_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'joined' THEN
        UPDATE public.live_sessions 
        SET current_participants = current_participants + 1
        WHERE id = NEW.session_id;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != 'joined' AND NEW.status = 'joined' THEN
            UPDATE public.live_sessions 
            SET current_participants = current_participants + 1
            WHERE id = NEW.session_id;
        ELSIF OLD.status = 'joined' AND NEW.status != 'joined' THEN
            UPDATE public.live_sessions 
            SET current_participants = GREATEST(0, current_participants - 1)
            WHERE id = NEW.session_id;
        END IF;
    ELSIF TG_OP = 'DELETE' AND OLD.status = 'joined' THEN
        UPDATE public.live_sessions 
        SET current_participants = GREATEST(0, current_participants - 1)
        WHERE id = OLD.session_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Function to get live sessions feed
CREATE OR REPLACE FUNCTION public.get_live_sessions_feed(user_uuid UUID DEFAULT NULL)
RETURNS TABLE(
    session_id UUID,
    title TEXT,
    description TEXT,
    instructor_name TEXT,
    instructor_avatar TEXT,
    session_type TEXT,
    difficulty_level TEXT,
    duration_minutes INTEGER,
    max_participants INTEGER,
    current_participants INTEGER,
    status TEXT,
    scheduled_start TIMESTAMPTZ,
    is_bookmarked BOOLEAN,
    is_following_instructor BOOLEAN,
    required_equipment TEXT[]
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT 
        ls.id,
        ls.title,
        ls.description,
        up.full_name,
        up.avatar_url,
        ls.session_type::TEXT,
        ls.difficulty_level::TEXT,
        ls.duration_minutes,
        ls.max_participants,
        ls.current_participants,
        ls.status::TEXT,
        ls.scheduled_start,
        (sb.id IS NOT NULL) as is_bookmarked,
        (if_follow.id IS NOT NULL) as is_following_instructor,
        ls.required_equipment
    FROM public.live_sessions ls
    JOIN public.user_profiles up ON ls.instructor_id = up.id
    LEFT JOIN public.session_bookmarks sb ON ls.id = sb.session_id AND sb.user_id = user_uuid
    LEFT JOIN public.instructor_followers if_follow ON ls.instructor_id = if_follow.instructor_id AND if_follow.follower_id = user_uuid
    WHERE ls.status IN ('scheduled', 'live')
    ORDER BY 
        CASE WHEN ls.status = 'live' THEN 1 ELSE 2 END,
        ls.scheduled_start ASC;
$$;

-- Function to join session
CREATE OR REPLACE FUNCTION public.join_live_session(session_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    session_max_participants INTEGER;
    session_current_participants INTEGER;
BEGIN
    -- Get session participant limits
    SELECT max_participants, current_participants 
    INTO session_max_participants, session_current_participants
    FROM public.live_sessions 
    WHERE id = session_uuid AND status = 'live';
    
    -- Check if session exists and is live
    IF session_max_participants IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if session is full
    IF session_current_participants >= session_max_participants THEN
        RETURN FALSE;
    END IF;
    
    -- Insert or update participant record
    INSERT INTO public.session_participants (session_id, user_id, status, joined_at)
    VALUES (session_uuid, user_uuid, 'joined', CURRENT_TIMESTAMP)
    ON CONFLICT (session_id, user_id)
    DO UPDATE SET 
        status = 'joined',
        joined_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$;

-- 5. Triggers
CREATE TRIGGER update_session_participant_count_trigger
    AFTER INSERT OR UPDATE OR DELETE ON public.session_participants
    FOR EACH ROW
    EXECUTE FUNCTION public.update_session_participant_count();

-- 6. RLS Setup
ALTER TABLE public.live_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_chat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_poll_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_qna ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.instructor_followers ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Live Sessions - Public read, instructors manage own
CREATE POLICY "public_read_live_sessions"
ON public.live_sessions
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "instructors_manage_own_sessions"
ON public.live_sessions
FOR ALL
TO authenticated
USING (instructor_id = auth.uid())
WITH CHECK (instructor_id = auth.uid());

-- Session Participants - Users manage own participation
CREATE POLICY "users_manage_own_session_participation"
ON public.session_participants
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Session Chat - Participants can read/write in joined sessions
CREATE POLICY "participants_access_session_chat"
ON public.session_chat
FOR SELECT
TO authenticated
USING (
    session_id IN (
        SELECT session_id FROM public.session_participants 
        WHERE user_id = auth.uid() AND status = 'joined'
    )
);

CREATE POLICY "participants_create_chat_messages"
ON public.session_chat
FOR INSERT
TO authenticated
WITH CHECK (
    user_id = auth.uid() AND
    session_id IN (
        SELECT session_id FROM public.session_participants 
        WHERE user_id = auth.uid() AND status = 'joined'
    )
);

-- Session Reactions - Participants can react
CREATE POLICY "users_manage_own_session_reactions"
ON public.session_reactions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Session Polls - Instructors create, participants vote
CREATE POLICY "instructors_manage_session_polls"
ON public.session_polls
FOR ALL
TO authenticated
USING (
    session_id IN (
        SELECT id FROM public.live_sessions WHERE instructor_id = auth.uid()
    )
)
WITH CHECK (
    session_id IN (
        SELECT id FROM public.live_sessions WHERE instructor_id = auth.uid()
    )
);

CREATE POLICY "participants_view_session_polls"
ON public.session_polls
FOR SELECT
TO authenticated
USING (
    session_id IN (
        SELECT session_id FROM public.session_participants 
        WHERE user_id = auth.uid() AND status = 'joined'
    )
);

-- Session Poll Votes - Users manage own votes
CREATE POLICY "users_manage_own_poll_votes"
ON public.session_poll_votes
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Session Q&A - Users manage own questions
CREATE POLICY "users_manage_own_session_questions"
ON public.session_qna
FOR ALL
TO authenticated
USING (user_id = auth.uid() OR answered_by = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Session Bookmarks - Users manage own bookmarks
CREATE POLICY "users_manage_own_session_bookmarks"
ON public.session_bookmarks
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Session Ratings - Users manage own ratings
CREATE POLICY "users_manage_own_session_ratings"
ON public.session_ratings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Instructor Followers - Users manage own following
CREATE POLICY "users_manage_own_instructor_following"
ON public.instructor_followers
FOR ALL
TO authenticated
USING (follower_id = auth.uid())
WITH CHECK (follower_id = auth.uid());

-- 7. Mock Data
DO $$
DECLARE
    instructor_id UUID;
    user_id UUID;
    session1_id UUID := gen_random_uuid();
    session2_id UUID := gen_random_uuid();
    session3_id UUID := gen_random_uuid();
    poll_id UUID := gen_random_uuid();
BEGIN
    -- Get existing users
    SELECT id INTO instructor_id FROM public.user_profiles WHERE role = 'admin' LIMIT 1;
    SELECT id INTO user_id FROM public.user_profiles WHERE role = 'free' LIMIT 1;
    
    IF instructor_id IS NOT NULL AND user_id IS NOT NULL THEN
        -- Create sample live sessions
        INSERT INTO public.live_sessions (id, title, description, instructor_id, session_type, difficulty_level, duration_minutes, max_participants, status, scheduled_start, required_equipment, session_image_url) VALUES
        (session1_id, 'Morning Yoga Flow', 'Start your day with energizing yoga poses and breathing exercises', instructor_id, 'yoga', 'beginner', 45, 50, 'live', CURRENT_TIMESTAMP + INTERVAL '10 minutes', ARRAY['yoga mat', 'water bottle'], 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=800&q=80'),
        (session2_id, 'HIIT Power Session', 'High-intensity interval training for maximum calorie burn', instructor_id, 'hiit', 'intermediate', 30, 30, 'scheduled', CURRENT_TIMESTAMP + INTERVAL '2 hours', ARRAY['dumbbells', 'resistance band'], 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=800&q=80'),
        (session3_id, 'Mindfulness Meditation', 'Deep relaxation and stress relief through guided meditation', instructor_id, 'meditation', 'beginner', 20, 100, 'scheduled', CURRENT_TIMESTAMP + INTERVAL '4 hours', ARRAY['meditation cushion'], 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=800&q=80');
        
        -- Create sample participants
        INSERT INTO public.session_participants (session_id, user_id, status, joined_at) VALUES
        (session1_id, user_id, 'joined', CURRENT_TIMESTAMP),
        (session2_id, user_id, 'registered', CURRENT_TIMESTAMP);
        
        -- Create sample chat messages
        INSERT INTO public.session_chat (session_id, user_id, message) VALUES
        (session1_id, user_id, 'Great session! Loving the energy 🔥'),
        (session1_id, instructor_id, 'Thank you! Remember to stay hydrated everyone! 💧');
        
        -- Create sample reactions
        INSERT INTO public.session_reactions (session_id, user_id, reaction_type) VALUES
        (session1_id, user_id, 'heart'),
        (session1_id, user_id, 'fire');
        
        -- Create sample poll
        INSERT INTO public.session_polls (id, session_id, question, options) VALUES
        (poll_id, session1_id, 'How are you feeling?', '{"Energized": 0, "Relaxed": 0, "Challenged": 0, "Great": 0}'::jsonb);
        
        -- Create sample Q&A
        INSERT INTO public.session_qna (session_id, user_id, question) VALUES
        (session1_id, user_id, 'What modifications would you recommend for beginners?');
        
        -- Create sample bookmarks
        INSERT INTO public.session_bookmarks (session_id, user_id) VALUES
        (session2_id, user_id),
        (session3_id, user_id);
        
        -- Create sample instructor following
        INSERT INTO public.instructor_followers (instructor_id, follower_id) VALUES
        (instructor_id, user_id);
        
    END IF;
END $$;