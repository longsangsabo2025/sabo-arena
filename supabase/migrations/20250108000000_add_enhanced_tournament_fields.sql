-- Migration: Add enhanced tournament creation fields
-- Date: 2025-01-08
-- Purpose: Add missing fields for enhanced tournament creation wizard

-- Add prize distribution fields
ALTER TABLE public.tournaments 
ADD COLUMN prize_source TEXT DEFAULT 'entry_fees' CHECK (prize_source IN ('entry_fees', 'sponsor', 'hybrid')),
ADD COLUMN distribution_template TEXT DEFAULT 'top_4' CHECK (distribution_template IN ('winner_takes_all', 'top_3', 'top_4', 'dong_hang_3', 'custom')),
ADD COLUMN organizer_fee_percent DECIMAL(5,2) DEFAULT 10.00 CHECK (organizer_fee_percent >= 0 AND organizer_fee_percent <= 100),
ADD COLUMN sponsor_contribution DECIMAL(10,2) DEFAULT 0.00 CHECK (sponsor_contribution >= 0),
ADD COLUMN custom_distribution JSONB DEFAULT NULL;

-- Add rank restriction fields
ALTER TABLE public.tournaments 
ADD COLUMN min_rank TEXT DEFAULT NULL,
ADD COLUMN max_rank TEXT DEFAULT NULL;

-- Add venue and contact fields
ALTER TABLE public.tournaments 
ADD COLUMN venue_address TEXT DEFAULT NULL,
ADD COLUMN venue_contact TEXT DEFAULT NULL,
ADD COLUMN venue_phone TEXT DEFAULT NULL;

-- Add additional rules fields
ALTER TABLE public.tournaments 
ADD COLUMN special_rules TEXT DEFAULT NULL,
ADD COLUMN registration_fee_waiver BOOLEAN DEFAULT false;

-- Add indexes for commonly queried fields
CREATE INDEX idx_tournaments_prize_source ON public.tournaments(prize_source);
CREATE INDEX idx_tournaments_distribution_template ON public.tournaments(distribution_template);
CREATE INDEX idx_tournaments_min_rank ON public.tournaments(min_rank);
CREATE INDEX idx_tournaments_max_rank ON public.tournaments(max_rank);
CREATE INDEX idx_tournaments_registration_fee_waiver ON public.tournaments(registration_fee_waiver);

-- Add comments for documentation
COMMENT ON COLUMN public.tournaments.prize_source IS 'Source of prize money: entry_fees, sponsor, or hybrid';
COMMENT ON COLUMN public.tournaments.distribution_template IS 'Prize distribution template: winner_takes_all, top_3, top_4, dong_hang_3, or custom';
COMMENT ON COLUMN public.tournaments.organizer_fee_percent IS 'Percentage fee taken by organizer (0-100)';
COMMENT ON COLUMN public.tournaments.sponsor_contribution IS 'Additional prize money from sponsors in USD';
COMMENT ON COLUMN public.tournaments.custom_distribution IS 'Custom prize distribution as JSON array of {position, percentage}';
COMMENT ON COLUMN public.tournaments.min_rank IS 'Minimum rank required to participate';
COMMENT ON COLUMN public.tournaments.max_rank IS 'Maximum rank allowed to participate';
COMMENT ON COLUMN public.tournaments.venue_address IS 'Detailed venue address for the tournament';
COMMENT ON COLUMN public.tournaments.venue_contact IS 'Contact person name for venue inquiries';
COMMENT ON COLUMN public.tournaments.venue_phone IS 'Contact phone number for venue inquiries';
COMMENT ON COLUMN public.tournaments.special_rules IS 'Additional special rules for the tournament';
COMMENT ON COLUMN public.tournaments.registration_fee_waiver IS 'Whether registration fee is waived for this tournament';

-- Update the updated_at trigger to include new fields
CREATE OR REPLACE FUNCTION public.update_tournament_timestamp()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Ensure trigger exists for tournaments table
DROP TRIGGER IF EXISTS on_tournament_update ON public.tournaments;
CREATE TRIGGER on_tournament_update
    BEFORE UPDATE ON public.tournaments
    FOR EACH ROW EXECUTE FUNCTION public.update_tournament_timestamp();