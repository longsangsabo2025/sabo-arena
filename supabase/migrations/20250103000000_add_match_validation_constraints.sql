-- ============================================================================
-- MIGRATION: Add Match Validation Constraints
-- Purpose: Prevent duplicate users and invalid match states at DATABASE LEVEL
-- Date: 2025-01-03
-- ============================================================================

-- 1. PREVENT DUPLICATE USERS IN SAME MATCH
-- ============================================================================
ALTER TABLE matches 
ADD CONSTRAINT check_no_duplicate_players 
CHECK (
  player1_id IS NULL OR 
  player2_id IS NULL OR 
  player1_id != player2_id
);

COMMENT ON CONSTRAINT check_no_duplicate_players ON matches IS 
'Ensures a user cannot play against themselves - player1_id must be different from player2_id';

-- 2. ENSURE BOTH PLAYERS EXIST BEFORE STATUS = 'pending'
-- ============================================================================
ALTER TABLE matches 
ADD CONSTRAINT check_pending_requires_both_players 
CHECK (
  status != 'pending' OR 
  (player1_id IS NOT NULL AND player2_id IS NOT NULL)
);

COMMENT ON CONSTRAINT check_pending_requires_both_players ON matches IS 
'Ensures matches cannot be set to pending status without both players assigned';

-- 3. ENSURE WINNER IS ONE OF THE PLAYERS
-- ============================================================================
ALTER TABLE matches 
ADD CONSTRAINT check_winner_is_player 
CHECK (
  winner_id IS NULL OR 
  winner_id = player1_id OR 
  winner_id = player2_id
);

COMMENT ON CONSTRAINT check_winner_is_player ON matches IS 
'Ensures winner must be either player1 or player2 of the match';

-- 4. ENSURE COMPLETED MATCHES HAVE WINNER AND SCORES
-- ============================================================================
ALTER TABLE matches 
ADD CONSTRAINT check_completed_has_winner_and_scores 
CHECK (
  status != 'completed' OR 
  (
    winner_id IS NOT NULL AND 
    player1_score IS NOT NULL AND 
    player2_score IS NOT NULL
  )
);

COMMENT ON CONSTRAINT check_completed_has_winner_and_scores ON matches IS 
'Ensures completed matches must have winner_id and both player scores';

-- 5. PREVENT ADVANCEMENT LOOPS (Optional - for extra safety)
-- ============================================================================
-- This prevents a match from advancing to itself
ALTER TABLE matches 
ADD CONSTRAINT check_no_self_advancement 
CHECK (
  (winner_advances_to IS NULL OR winner_advances_to != display_order) AND
  (loser_advances_to IS NULL OR loser_advances_to != display_order)
);

COMMENT ON CONSTRAINT check_no_self_advancement ON matches IS 
'Prevents a match from advancing winners/losers back to itself';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Test 1: Try to create match with duplicate players (should FAIL)
-- INSERT INTO matches (tournament_id, match_number, player1_id, player2_id, status) 
-- VALUES ('some-uuid', 999, 'user-uuid', 'user-uuid', 'pending');

-- Test 2: Try to set status=pending without both players (should FAIL)
-- UPDATE matches SET status = 'pending' WHERE player2_id IS NULL LIMIT 1;

-- Test 3: Try to set winner to non-player (should FAIL)
-- UPDATE matches SET winner_id = 'random-uuid' WHERE match_number = 1;

-- ============================================================================
-- ROLLBACK (if needed)
-- ============================================================================
-- ALTER TABLE matches DROP CONSTRAINT check_no_duplicate_players;
-- ALTER TABLE matches DROP CONSTRAINT check_pending_requires_both_players;
-- ALTER TABLE matches DROP CONSTRAINT check_winner_is_player;
-- ALTER TABLE matches DROP CONSTRAINT check_completed_has_winner_and_scores;
-- ALTER TABLE matches DROP CONSTRAINT check_no_self_advancement;
