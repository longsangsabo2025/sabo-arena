-- Migration to create challenges table for opponent tab functionality
-- Location: supabase/migrations/20251020_create_challenges_table.sql

-- Create challenges table
CREATE TABLE IF NOT EXISTS public.challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenger_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    challenged_id UUID REFERENCES public.users(id) ON DELETE CASCADE, -- NULL = OPEN challenge
    challenge_type TEXT NOT NULL CHECK (challenge_type IN ('thach_dau', 'giao_luu')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'in_progress', 'completed', 'cancelled')),
    stakes_type TEXT DEFAULT 'none' CHECK (stakes_type IN ('none', 'spa_points', 'prize')),
    stakes_amount INTEGER DEFAULT 0 CHECK (stakes_amount >= 0),
    game_type TEXT DEFAULT '8_ball' CHECK (game_type IN ('8_ball', '9_ball', '10_ball', 'straight_pool', 'one_pocket')),
    race_to INTEGER DEFAULT 3 CHECK (race_to > 0),
    spa_bonus INTEGER DEFAULT 0 CHECK (spa_bonus >= 0),
    match_conditions JSONB DEFAULT '{}',
    message TEXT,
    response_message TEXT,
    location TEXT,
    scheduled_time TIMESTAMPTZ,
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_challenges_challenger_id ON public.challenges(challenger_id);
CREATE INDEX IF NOT EXISTS idx_challenges_challenged_id ON public.challenges(challenged_id);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON public.challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenges_challenge_type ON public.challenges(challenge_type);
CREATE INDEX IF NOT EXISTS idx_challenges_created_at ON public.challenges(created_at DESC);

-- Create composite index for common queries
CREATE INDEX IF NOT EXISTS idx_challenges_type_status_challenged 
    ON public.challenges(challenge_type, status, challenged_id);

-- Enable Row Level Security
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Policy 1: Users can view:
--   - OPEN challenges (challenged_id IS NULL)
--   - Challenges they created (challenger_id = auth.uid())
--   - Challenges sent to them (challenged_id = auth.uid())
CREATE POLICY "users_can_view_relevant_challenges"
ON public.challenges
FOR SELECT
TO authenticated
USING (
    challenged_id IS NULL OR
    challenger_id = auth.uid() OR
    challenged_id = auth.uid()
);

-- Policy 2: Users can create challenges
CREATE POLICY "users_can_create_challenges"
ON public.challenges
FOR INSERT
TO authenticated
WITH CHECK (
    challenger_id = auth.uid()
);

-- Policy 3: Users can update their own challenges OR challenges sent to them
CREATE POLICY "users_can_update_their_challenges"
ON public.challenges
FOR UPDATE
TO authenticated
USING (
    challenger_id = auth.uid() OR
    challenged_id = auth.uid()
)
WITH CHECK (
    challenger_id = auth.uid() OR
    challenged_id = auth.uid()
);

-- Policy 4: Users can delete their own challenges (only if pending)
CREATE POLICY "users_can_delete_pending_challenges"
ON public.challenges
FOR DELETE
TO authenticated
USING (
    challenger_id = auth.uid() AND
    status = 'pending'
);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION public.update_challenges_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_challenges_updated_at
    BEFORE UPDATE ON public.challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.update_challenges_updated_at();

-- Add comment to table
COMMENT ON TABLE public.challenges IS 'Stores challenges/invites between users for competitive matches or social games';
COMMENT ON COLUMN public.challenges.challenged_id IS 'NULL means OPEN challenge that anyone can accept';
COMMENT ON COLUMN public.challenges.challenge_type IS 'thach_dau = competitive match, giao_luu = social/friendly match';
COMMENT ON COLUMN public.challenges.stakes_type IS 'Type of stakes: none, spa_points, or prize';
COMMENT ON COLUMN public.challenges.spa_bonus IS 'Bonus SPA points for winner (from opponent matching)';

-- Verify policies
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'challenges'
ORDER BY policyname;
