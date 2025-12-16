-- Add score columns to challenges table
-- This allows CLB owners to input scores directly into challenges

ALTER TABLE challenges 
ADD COLUMN IF NOT EXISTS player1_score INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS player2_score INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS winner_id UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS match_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS end_time TIMESTAMPTZ;

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_challenges_winner ON challenges(winner_id);
CREATE INDEX IF NOT EXISTS idx_challenges_match_date ON challenges(match_date);

-- Comment
COMMENT ON COLUMN challenges.player1_score IS 'Score of challenger (player 1)';
COMMENT ON COLUMN challenges.player2_score IS 'Score of challenged (player 2)';
COMMENT ON COLUMN challenges.winner_id IS 'ID of the winner';
COMMENT ON COLUMN challenges.match_date IS 'Actual match date/time';
COMMENT ON COLUMN challenges.end_time IS 'When the match ended';
