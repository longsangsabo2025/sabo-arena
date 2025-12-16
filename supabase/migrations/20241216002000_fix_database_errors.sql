-- Fix database errors in SABO Arena
-- This migration fixes the table reference mismatch and database function errors

-- Step 1: Fix the handle_new_user function to reference the correct table 'users' instead of 'users'
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.users (
        id, 
        email, 
        full_name, 
        role,
        display_name,
        username,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'player')::public.user_role,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || extract(epoch from now())::bigint::text),
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$;

-- Step 2: Create missing RPC functions that are referenced in the code
CREATE OR REPLACE FUNCTION public.get_user_ranking(user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_rank INTEGER;
BEGIN
    SELECT COUNT(*) + 1 INTO user_rank
    FROM public.users
    WHERE ranking_points > (
        SELECT ranking_points 
        FROM public.users 
        WHERE id = user_id
    ) AND is_active = true;
    
    RETURN COALESCE(user_rank, 0);
END;
$$;

-- Step 3: Create tournament participant management functions
CREATE OR REPLACE FUNCTION public.increment_tournament_participants(tournament_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.tournaments 
    SET current_participants = current_participants + 1 
    WHERE id = tournament_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_tournament_participants(tournament_id UUID)  
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.tournaments 
    SET current_participants = GREATEST(current_participants - 1, 0)
    WHERE id = tournament_id;
END;
$$;

-- Step 4: Add missing columns to tournament_participants table if they don't exist
DO $$
BEGIN
    -- Add payment_status column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'tournament_participants' 
        AND column_name = 'payment_status'
    ) THEN
        ALTER TABLE public.tournament_participants 
        ADD COLUMN payment_status TEXT DEFAULT 'pending';
    END IF;

    -- Add registered_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'tournament_participants' 
        AND column_name = 'registered_at'
    ) THEN
        ALTER TABLE public.tournament_participants 
        ADD COLUMN registered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;
    END IF;
END
$$;

-- Step 5: Update RLS policies to use correct table references
-- Drop existing policies that might reference old table names
DROP POLICY IF EXISTS "public_can_read_users" ON public.users;
DROP POLICY IF EXISTS "users_manage_own_users" ON public.users;

-- Create updated RLS policies
CREATE POLICY "public_can_read_users" ON public.users
    FOR SELECT TO public
    USING (is_active = true);

CREATE POLICY "users_manage_own_profile" ON public.users  
    FOR ALL TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Step 6: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.tournaments TO authenticated;
GRANT ALL ON public.tournament_participants TO authenticated;
GRANT ALL ON public.matches TO authenticated;
GRANT ALL ON public.clubs TO authenticated;
GRANT ALL ON public.posts TO authenticated;
GRANT ALL ON public.user_achievements TO authenticated;
GRANT ALL ON public.user_follows TO authenticated;

-- Step 7: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_display_name ON public.users (display_name);
CREATE INDEX IF NOT EXISTS idx_tournament_participants_registered_at ON public.tournament_participants (registered_at);
CREATE INDEX IF NOT EXISTS idx_tournament_participants_payment_status ON public.tournament_participants (payment_status);

-- Step 8: Update any existing data to ensure consistency
UPDATE public.tournaments 
SET current_participants = (
    SELECT COUNT(*) 
    FROM public.tournament_participants 
    WHERE tournament_id = tournaments.id
)
WHERE current_participants != (
    SELECT COUNT(*) 
    FROM public.tournament_participants 
    WHERE tournament_id = tournaments.id
);