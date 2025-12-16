
-- Migration: Add club_id to challenges table
-- Date: 2025-10-21
-- Description: Add club relationship to challenges for better club info display

-- Add club_id column
ALTER TABLE public.challenges 
ADD COLUMN IF NOT EXISTS club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_challenges_club_id ON public.challenges(club_id);

-- Add comment
COMMENT ON COLUMN public.challenges.club_id IS 'Reference to the club where the challenge takes place';

COMMIT;
