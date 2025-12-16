-- =====================================================
-- Migration: Add elo_enabled column to tournaments
-- Date: 2025-11-07
-- Description: Add missing elo_enabled boolean column
-- =====================================================

-- Add elo_enabled column with default true
ALTER TABLE tournaments 
ADD COLUMN IF NOT EXISTS elo_enabled BOOLEAN DEFAULT true NOT NULL;

-- Add comment
COMMENT ON COLUMN tournaments.elo_enabled IS 'Whether ELO rating is enabled for this tournament';

-- Create index for filtering tournaments by elo_enabled
CREATE INDEX IF NOT EXISTS idx_tournaments_elo_enabled 
ON tournaments(elo_enabled) 
WHERE elo_enabled = true;

-- =====================================================
-- VERIFICATION QUERY:
-- SELECT column_name, data_type, is_nullable, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'tournaments' AND column_name = 'elo_enabled';
-- =====================================================
