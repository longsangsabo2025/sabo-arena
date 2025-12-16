-- Location: supabase/migrations/20241215092415_sabo_arena_complete_platform.sql
-- Schema Analysis: Fresh project - no existing schema
-- Integration Type: Complete billiards tournament platform with authentication
-- Dependencies: None (fresh start)

-- 1. ENUMS AND CUSTOM TYPES
CREATE TYPE public.user_role AS ENUM ('player', 'club_owner', 'admin');
CREATE TYPE public.tournament_status AS ENUM ('upcoming', 'ongoing', 'completed', 'cancelled');
CREATE TYPE public.match_status AS ENUM ('pending', 'in_progress', 'completed');
CREATE TYPE public.skill_level AS ENUM ('beginner', 'intermediate', 'advanced', 'professional');
CREATE TYPE public.post_type AS ENUM ('text', 'image', 'video', 'tournament_share');

-- 2. CORE TABLES

-- User profiles (Critical intermediary table for PostgREST compatibility)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    username TEXT UNIQUE,
    bio TEXT,
    avatar_url TEXT,
    phone TEXT,
    date_of_birth DATE,
    role public.user_role DEFAULT 'player'::public.user_role,
    skill_level public.skill_level DEFAULT 'beginner'::public.skill_level,
    total_wins INTEGER DEFAULT 0,
    total_losses INTEGER DEFAULT 0,
    total_tournaments INTEGER DEFAULT 0,
    ranking_points INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Clubs
CREATE TABLE public.clubs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    website_url TEXT,
    cover_image_url TEXT,
    profile_image_url TEXT,
    established_year INTEGER,
    total_tables INTEGER DEFAULT 1,
    opening_hours JSONB,
    amenities TEXT[],
    price_per_hour DECIMAL(10,2),
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Club members junction table
CREATE TABLE public.club_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_favorite BOOLEAN DEFAULT false,
    UNIQUE(club_id, user_id)
);

-- Tournaments
CREATE TABLE public.tournaments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE,
    organizer_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    tournament_type TEXT DEFAULT 'single_elimination',
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    registration_deadline TIMESTAMPTZ NOT NULL,
    max_participants INTEGER NOT NULL,
    current_participants INTEGER DEFAULT 0,
    entry_fee DECIMAL(10,2) DEFAULT 0.00,
    prize_pool DECIMAL(10,2) DEFAULT 0.00,
    prize_distribution JSONB,
    rules TEXT,
    requirements TEXT,
    skill_level_required public.skill_level,
    status public.tournament_status DEFAULT 'upcoming'::public.tournament_status,
    cover_image_url TEXT,
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Tournament participants
CREATE TABLE public.tournament_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    registered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    payment_status TEXT DEFAULT 'pending',
    seed_number INTEGER,
    notes TEXT,
    UNIQUE(tournament_id, user_id)
);

-- Matches
CREATE TABLE public.matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE,
    player1_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    player2_id UUID REFERENCES public.users(id),
    winner_id UUID REFERENCES public.users(id),
    round_number INTEGER NOT NULL,
    match_number INTEGER NOT NULL,
    scheduled_time TIMESTAMPTZ,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    player1_score INTEGER DEFAULT 0,
    player2_score INTEGER DEFAULT 0,
    status public.match_status DEFAULT 'pending'::public.match_status,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Social posts
CREATE TABLE public.posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT,
    post_type public.post_type DEFAULT 'text'::public.post_type,
    image_urls TEXT[],
    location TEXT,
    hashtags TEXT[],
    tournament_id UUID REFERENCES public.tournaments(id),
    club_id UUID REFERENCES public.clubs(id),
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Post interactions (likes, shares)
CREATE TABLE public.post_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    interaction_type TEXT NOT NULL, -- 'like', 'share'
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_id, interaction_type)
);

-- Comments
CREATE TABLE public.comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES public.comments(id),
    content TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Followers/Following
CREATE TABLE public.user_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    following_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, following_id)
);

-- Achievements
CREATE TABLE public.achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    icon_url TEXT,
    badge_color TEXT DEFAULT '#FFD700',
    points_required INTEGER DEFAULT 0,
    tournaments_required INTEGER DEFAULT 0,
    wins_required INTEGER DEFAULT 0,
    category TEXT DEFAULT 'general'
);

-- User achievements
CREATE TABLE public.user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES public.achievements(id) ON DELETE CASCADE,
    earned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    tournament_id UUID REFERENCES public.tournaments(id),
    UNIQUE(user_id, achievement_id)
);

-- Club reviews
CREATE TABLE public.club_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    visit_date DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(club_id, user_id)
);

-- 3. INDEXES FOR PERFORMANCE
CREATE INDEX idx_users_username ON public.users(username);
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_skill_level ON public.users(skill_level);

CREATE INDEX idx_clubs_owner_id ON public.clubs(owner_id);
CREATE INDEX idx_clubs_location ON public.clubs(latitude, longitude);
CREATE INDEX idx_clubs_is_active ON public.clubs(is_active);

CREATE INDEX idx_club_members_club_id ON public.club_members(club_id);
CREATE INDEX idx_club_members_user_id ON public.club_members(user_id);

CREATE INDEX idx_tournaments_club_id ON public.tournaments(club_id);
CREATE INDEX idx_tournaments_organizer_id ON public.tournaments(organizer_id);
CREATE INDEX idx_tournaments_status ON public.tournaments(status);
CREATE INDEX idx_tournaments_start_date ON public.tournaments(start_date);

CREATE INDEX idx_tournament_participants_tournament_id ON public.tournament_participants(tournament_id);
CREATE INDEX idx_tournament_participants_user_id ON public.tournament_participants(user_id);

CREATE INDEX idx_matches_tournament_id ON public.matches(tournament_id);
CREATE INDEX idx_matches_players ON public.matches(player1_id, player2_id);
CREATE INDEX idx_matches_status ON public.matches(status);

CREATE INDEX idx_posts_user_id ON public.posts(user_id);
CREATE INDEX idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX idx_posts_is_public ON public.posts(is_public);

CREATE INDEX idx_post_interactions_post_id ON public.post_interactions(post_id);
CREATE INDEX idx_post_interactions_user_id ON public.post_interactions(user_id);

CREATE INDEX idx_comments_post_id ON public.comments(post_id);
CREATE INDEX idx_comments_user_id ON public.comments(user_id);
CREATE INDEX idx_comments_parent ON public.comments(parent_comment_id);

CREATE INDEX idx_user_follows_follower ON public.user_follows(follower_id);
CREATE INDEX idx_user_follows_following ON public.user_follows(following_id);

CREATE INDEX idx_user_achievements_user_id ON public.user_achievements(user_id);

-- 4. FUNCTIONS (BEFORE RLS POLICIES)

-- Function for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, role)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'player')::public.user_role
    );
    RETURN NEW;
END;
$$;

-- Function to update post counts
CREATE OR REPLACE FUNCTION public.update_post_interaction_counts()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.interaction_type = 'like' THEN
            UPDATE public.posts 
            SET like_count = like_count + 1 
            WHERE id = NEW.post_id;
        ELSIF NEW.interaction_type = 'share' THEN
            UPDATE public.posts 
            SET share_count = share_count + 1 
            WHERE id = NEW.post_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.interaction_type = 'like' THEN
            UPDATE public.posts 
            SET like_count = like_count - 1 
            WHERE id = OLD.post_id;
        ELSIF OLD.interaction_type = 'share' THEN
            UPDATE public.posts 
            SET share_count = share_count - 1 
            WHERE id = OLD.post_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

-- Function to update comment counts
CREATE OR REPLACE FUNCTION public.update_comment_counts()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.posts 
        SET comment_count = comment_count + 1 
        WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.posts 
        SET comment_count = comment_count - 1 
        WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

-- Function to update user stats after match
CREATE OR REPLACE FUNCTION public.update_user_tournament_stats()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only update when match is completed and has a winner
    IF NEW.status = 'completed' AND NEW.winner_id IS NOT NULL THEN
        -- Update winner stats
        UPDATE public.users 
        SET total_wins = total_wins + 1,
            ranking_points = ranking_points + 10
        WHERE id = NEW.winner_id;
        
        -- Update loser stats
        IF NEW.player1_id = NEW.winner_id THEN
            UPDATE public.users 
            SET total_losses = total_losses + 1
            WHERE id = NEW.player2_id;
        ELSE
            UPDATE public.users 
            SET total_losses = total_losses + 1
            WHERE id = NEW.player1_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- 5. ENABLE RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_reviews ENABLE ROW LEVEL SECURITY;

-- 6. RLS POLICIES USING CORRECT PATTERNS

-- Pattern 1: Core user table (users)
CREATE POLICY "users_manage_own_users"
ON public.users
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 4: Public read, private write for clubs
CREATE POLICY "public_can_read_clubs"
ON public.clubs
FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "club_owners_manage_own_clubs"
ON public.clubs
FOR ALL
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- Pattern 2: Simple user ownership for club_members
CREATE POLICY "users_manage_own_club_memberships"
ON public.club_members
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 4: Public read for tournaments
CREATE POLICY "public_can_read_tournaments"
ON public.tournaments
FOR SELECT
TO public
USING (is_public = true);

CREATE POLICY "tournament_organizers_manage_tournaments"
ON public.tournaments
FOR ALL
TO authenticated
USING (organizer_id = auth.uid())
WITH CHECK (organizer_id = auth.uid());

-- Pattern 2: Simple user ownership for tournament participants
CREATE POLICY "users_manage_own_tournament_participation"
ON public.tournament_participants
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Public read for matches, organizers can manage
CREATE POLICY "public_can_read_matches"
ON public.matches
FOR SELECT
TO public
USING (true);

CREATE POLICY "tournament_organizers_manage_matches"
ON public.matches
FOR ALL
TO authenticated
USING (
    tournament_id IN (
        SELECT id FROM public.tournaments 
        WHERE organizer_id = auth.uid()
    )
)
WITH CHECK (
    tournament_id IN (
        SELECT id FROM public.tournaments 
        WHERE organizer_id = auth.uid()
    )
);

-- Pattern 4: Public read, private write for posts
CREATE POLICY "public_can_read_posts"
ON public.posts
FOR SELECT
TO public
USING (is_public = true);

CREATE POLICY "users_manage_own_posts"
ON public.posts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Simple user ownership for post interactions
CREATE POLICY "users_manage_own_post_interactions"
ON public.post_interactions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 4: Public read for comments, users manage own
CREATE POLICY "public_can_read_comments"
ON public.comments
FOR SELECT
TO public
USING (true);

CREATE POLICY "users_manage_own_comments"
ON public.comments
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Simple user ownership for follows
CREATE POLICY "users_manage_own_follows"
ON public.user_follows
FOR ALL
TO authenticated
USING (follower_id = auth.uid())
WITH CHECK (follower_id = auth.uid());

-- Public read for achievements
CREATE POLICY "public_can_read_achievements"
ON public.achievements
FOR SELECT
TO public
USING (true);

-- Users can view all user achievements but only manage their own
CREATE POLICY "public_can_read_user_achievements"
ON public.user_achievements
FOR SELECT
TO public
USING (true);

CREATE POLICY "users_manage_own_achievements"
ON public.user_achievements
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Simple user ownership for club reviews
CREATE POLICY "users_manage_own_club_reviews"
ON public.club_reviews
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 7. TRIGGERS
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_post_interaction_change
    AFTER INSERT OR DELETE ON public.post_interactions
    FOR EACH ROW EXECUTE FUNCTION public.update_post_interaction_counts();

CREATE TRIGGER on_comment_change
    AFTER INSERT OR DELETE ON public.comments
    FOR EACH ROW EXECUTE FUNCTION public.update_comment_counts();

CREATE TRIGGER on_match_completed
    AFTER UPDATE ON public.matches
    FOR EACH ROW EXECUTE FUNCTION public.update_user_tournament_stats();

-- 8. STORAGE BUCKETS AND POLICIES

-- Public bucket for shared content (posts, tournament images)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'public-content',
    'public-content',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'video/mp4', 'video/webm']
);

-- Private bucket for user avatars and profile content
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'user-content',
    'user-content',
    false,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
);

-- Storage policies for public content
CREATE POLICY "public_can_view_public_content"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'public-content');

CREATE POLICY "authenticated_users_upload_public_content"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'public-content');

CREATE POLICY "owners_manage_public_content"
ON storage.objects
FOR ALL
TO authenticated
USING (bucket_id = 'public-content' AND owner = auth.uid())
WITH CHECK (bucket_id = 'public-content');

-- Storage policies for user content (private)
CREATE POLICY "users_view_own_content"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'user-content' AND owner = auth.uid());

CREATE POLICY "users_upload_own_content"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'user-content' 
    AND owner = auth.uid()
    AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "users_update_own_content"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'user-content' AND owner = auth.uid())
WITH CHECK (bucket_id = 'user-content' AND owner = auth.uid());

CREATE POLICY "users_delete_own_content"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'user-content' AND owner = auth.uid());

-- 9. DEFAULT ACHIEVEMENTS
INSERT INTO public.achievements (name, description, icon_url, badge_color, points_required, category) VALUES
('First Tournament', 'Participated in your first tournament', NULL, '#FFD700', 0, 'participation'),
('Winner Winner', 'Won your first tournament', NULL, '#FF6B35', 0, 'victory'),
('Social Player', 'Made 10 posts on the platform', NULL, '#4ECDC4', 0, 'social'),
('Club Explorer', 'Visited 5 different clubs', NULL, '#45B7D1', 0, 'exploration'),
('Rising Star', 'Earned 100 ranking points', NULL, '#96CEB4', 100, 'ranking'),
('Veteran Player', 'Participated in 10 tournaments', NULL, '#FECA57', 0, 'participation'),
('Champion', 'Won 5 tournaments', NULL, '#FF9FF3', 0, 'victory'),
('Social Butterfly', 'Have 50 followers', NULL, '#54A0FF', 0, 'social'),
('Master Player', 'Reached professional skill level', NULL, '#5F27CD', 0, 'skill'),
('Arena Legend', 'Earned 1000 ranking points', NULL, '#00D2D3', 1000, 'ranking');

-- 10. MOCK DATA WITH COMPLETE AUTH USERS
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    player1_uuid UUID := gen_random_uuid();
    player2_uuid UUID := gen_random_uuid();
    club_owner_uuid UUID := gen_random_uuid();
    
    club1_uuid UUID := gen_random_uuid();
    club2_uuid UUID := gen_random_uuid();
    
    tournament1_uuid UUID := gen_random_uuid();
    tournament2_uuid UUID := gen_random_uuid();
    
    post1_uuid UUID := gen_random_uuid();
    post2_uuid UUID := gen_random_uuid();
BEGIN
    -- Create complete auth.users records
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@saboarena.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin SABO", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (player1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'player1@example.com', crypt('player123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Nguyen Van Duc", "role": "player"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (player2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'player2@example.com', crypt('player123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Tran Thi Mai", "role": "player"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (club_owner_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'owner@club.com', crypt('owner123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Le Minh Hoang", "role": "club_owner"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create clubs
    INSERT INTO public.clubs (id, owner_id, name, description, address, phone, email, total_tables, is_verified, latitude, longitude) VALUES
        (club1_uuid, club_owner_uuid, 'Golden Billiards Club', 'Premier billiards club with professional tables and friendly atmosphere', '123 Nguyen Hue St, District 1, Ho Chi Minh City', '+84 28 1234 5678', 'info@goldenbilliards.com', 12, true, 10.7769, 106.7009),
        (club2_uuid, admin_uuid, 'SABO Arena Central', 'The official SABO Arena with tournament-grade facilities', '456 Le Loi Blvd, District 1, Ho Chi Minh City', '+84 28 8765 4321', 'central@saboarena.com', 20, true, 10.7756, 106.7019);

    -- Create tournaments
    INSERT INTO public.tournaments (id, club_id, organizer_id, title, description, start_date, registration_deadline, max_participants, entry_fee, prize_pool, skill_level_required) VALUES
        (tournament1_uuid, club1_uuid, club_owner_uuid, 'Winter Championship 2024', 'Annual winter tournament for intermediate and advanced players', 
         now() + interval '30 days', now() + interval '25 days', 32, 500000, 5000000, 'intermediate'),
        (tournament2_uuid, club2_uuid, admin_uuid, 'SABO Arena Open', 'Open tournament for all skill levels with prizes', 
         now() + interval '15 days', now() + interval '10 days', 64, 200000, 2000000, 'beginner');

    -- Register players in tournaments
    INSERT INTO public.tournament_participants (tournament_id, user_id, payment_status) VALUES
        (tournament1_uuid, player1_uuid, 'completed'),
        (tournament1_uuid, player2_uuid, 'completed'),
        (tournament2_uuid, player1_uuid, 'completed'),
        (tournament2_uuid, player2_uuid, 'pending');

    -- Create some matches
    INSERT INTO public.matches (tournament_id, player1_id, player2_id, round_number, match_number, scheduled_time, status) VALUES
        (tournament1_uuid, player1_uuid, player2_uuid, 1, 1, now() + interval '32 days', 'pending');

    -- Create social posts
    INSERT INTO public.posts (id, user_id, content, post_type, hashtags, like_count, comment_count) VALUES
        (post1_uuid, player1_uuid, 'Just finished an amazing practice session at Golden Billiards! Ready for the upcoming tournament 🎱', 'text', 
         ARRAY['billiards', 'practice', 'tournament'], 15, 3),
        (post2_uuid, player2_uuid, 'New to billiards but loving every moment of it! Any tips for a beginner?', 'text',
         ARRAY['beginner', 'tips', 'billiards'], 8, 5);

    -- Create some interactions
    INSERT INTO public.post_interactions (post_id, user_id, interaction_type) VALUES
        (post1_uuid, player2_uuid, 'like'),
        (post1_uuid, club_owner_uuid, 'like'),
        (post2_uuid, player1_uuid, 'like'),
        (post2_uuid, admin_uuid, 'like');

    -- Create comments
    INSERT INTO public.comments (post_id, user_id, content) VALUES
        (post1_uuid, player2_uuid, 'Good luck in the tournament!'),
        (post1_uuid, club_owner_uuid, 'Thanks for choosing our club for practice!'),
        (post2_uuid, player1_uuid, 'Focus on your stance and follow through. Practice makes perfect!'),
        (post2_uuid, admin_uuid, 'Welcome to the SABO Arena community! Join our beginner workshops.');

    -- Create follows
    INSERT INTO public.user_follows (follower_id, following_id) VALUES
        (player2_uuid, player1_uuid),
        (player1_uuid, club_owner_uuid),
        (player2_uuid, admin_uuid);

    -- Create club memberships
    INSERT INTO public.club_members (club_id, user_id, is_favorite) VALUES
        (club1_uuid, player1_uuid, true),
        (club1_uuid, player2_uuid, false),
        (club2_uuid, player1_uuid, false),
        (club2_uuid, player2_uuid, true);

    -- Give some achievements
    INSERT INTO public.user_achievements (user_id, achievement_id, tournament_id) VALUES
        (player1_uuid, (SELECT id FROM public.achievements WHERE name = 'First Tournament'), tournament1_uuid),
        (player1_uuid, (SELECT id FROM public.achievements WHERE name = 'Social Player'), NULL),
        (player2_uuid, (SELECT id FROM public.achievements WHERE name = 'First Tournament'), tournament2_uuid);

    -- Add some club reviews
    INSERT INTO public.club_reviews (club_id, user_id, rating, review_text, visit_date) VALUES
        (club1_uuid, player1_uuid, 5, 'Excellent facility with professional tables. Staff is very friendly and helpful!', current_date - 5),
        (club1_uuid, player2_uuid, 4, 'Great place to practice. Clean environment and good equipment.', current_date - 2),
        (club2_uuid, player1_uuid, 5, 'The official SABO Arena is amazing! Perfect for tournaments.', current_date - 10);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 11. CLEANUP FUNCTION FOR DEVELOPMENT
CREATE OR REPLACE FUNCTION public.cleanup_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    auth_user_ids_to_delete UUID[];
BEGIN
    -- Get auth user IDs first
    SELECT ARRAY_AGG(id) INTO auth_user_ids_to_delete
    FROM auth.users
    WHERE email LIKE '%@example.com' OR email LIKE '%@saboarena.com' OR email LIKE '%@club.com';

    -- Delete in dependency order (children first)
    DELETE FROM public.user_achievements WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.club_reviews WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.user_follows WHERE follower_id = ANY(auth_user_ids_to_delete) OR following_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.comments WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.post_interactions WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.posts WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.matches WHERE player1_id = ANY(auth_user_ids_to_delete) OR player2_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.tournament_participants WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.tournaments WHERE organizer_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.club_members WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.clubs WHERE owner_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.users WHERE id = ANY(auth_user_ids_to_delete);

    -- Delete auth.users last
    DELETE FROM auth.users WHERE id = ANY(auth_user_ids_to_delete);
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;