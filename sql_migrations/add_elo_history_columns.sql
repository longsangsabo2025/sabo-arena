-- Add missing columns to elo_history table for tournament rewards tracking

-- Add change_reason column if not exists
ALTER TABLE elo_history 
ADD COLUMN IF NOT EXISTS change_reason TEXT;

-- Add tournament_id column if not exists  
ALTER TABLE elo_history
ADD COLUMN IF NOT EXISTS tournament_id UUID REFERENCES tournaments(id);

-- Add indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_elo_history_tournament 
ON elo_history(tournament_id);

CREATE INDEX IF NOT EXISTS idx_elo_history_reason 
ON elo_history(change_reason);

-- Update existing records to have a default reason
UPDATE elo_history 
SET change_reason = 'match_result'
WHERE change_reason IS NULL;

-- Verify
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'elo_history'
ORDER BY ordinal_position;
