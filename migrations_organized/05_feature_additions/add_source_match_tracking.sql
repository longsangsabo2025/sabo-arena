-- =====================================================
-- ADD SOURCE MATCH TRACKING COLUMNS
-- =====================================================
-- Thêm columns để track rõ ràng player đến từ match nào
-- Thay thế cho logic phức tạp trong winner_advances_to/loser_advances_to
-- =====================================================

-- Add columns to matches table
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS player1_source_match TEXT,
ADD COLUMN IF NOT EXISTS player2_source_match TEXT,
ADD COLUMN IF NOT EXISTS player1_source_type TEXT CHECK (player1_source_type IN ('winner', 'loser')),
ADD COLUMN IF NOT EXISTS player2_source_type TEXT CHECK (player2_source_type IN ('winner', 'loser'));

-- Add comments
COMMENT ON COLUMN matches.player1_source_match IS 'Source match for player 1 (e.g., "M107")';
COMMENT ON COLUMN matches.player2_source_match IS 'Source match for player 2 (e.g., "M108")';
COMMENT ON COLUMN matches.player1_source_type IS 'Whether player 1 is winner or loser of source match';
COMMENT ON COLUMN matches.player2_source_type IS 'Whether player 2 is winner or loser of source match';

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_matches_player1_source ON matches(player1_source_match);
CREATE INDEX IF NOT EXISTS idx_matches_player2_source ON matches(player2_source_match);

-- =====================================================
-- UPDATE AUTO-FILL TRIGGER to use new columns
-- =====================================================
CREATE OR REPLACE FUNCTION auto_fill_players_from_source()
RETURNS TRIGGER AS $$
DECLARE
  v_source_match_number INT;
  v_source_match RECORD;
  v_player_id UUID;
BEGIN
  -- Chỉ xử lý khi match vừa completed
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    
    -- ==========================================
    -- AUTO-FILL NEXT MATCHES based on advancement
    -- ==========================================
    -- Check if there are matches waiting for this match's winner/loser
    
    -- Find matches where this match is player1_source
    FOR v_source_match IN 
      SELECT * FROM matches 
      WHERE player1_source_match = 'M' || NEW.match_number
        AND tournament_id = NEW.tournament_id
        AND player1_id IS NULL
    LOOP
      -- Determine which player to use
      IF v_source_match.player1_source_type = 'winner' THEN
        v_player_id := NEW.winner_id;
      ELSIF v_source_match.player1_source_type = 'loser' THEN
        -- Loser is the non-winner
        IF NEW.player1_id = NEW.winner_id THEN
          v_player_id := NEW.player2_id;
        ELSE
          v_player_id := NEW.player1_id;
        END IF;
      END IF;
      
      -- Fill player1_id
      IF v_player_id IS NOT NULL THEN
        UPDATE matches
        SET player1_id = v_player_id,
            updated_at = NOW()
        WHERE match_number = v_source_match.match_number
          AND tournament_id = NEW.tournament_id;
        
        RAISE NOTICE 'Auto-filled Player1 in Match % from Match % (% type)', 
          v_source_match.match_number, NEW.match_number, v_source_match.player1_source_type;
      END IF;
    END LOOP;
    
    -- Find matches where this match is player2_source
    FOR v_source_match IN 
      SELECT * FROM matches 
      WHERE player2_source_match = 'M' || NEW.match_number
        AND tournament_id = NEW.tournament_id
        AND player2_id IS NULL
    LOOP
      -- Determine which player to use
      IF v_source_match.player2_source_type = 'winner' THEN
        v_player_id := NEW.winner_id;
      ELSIF v_source_match.player2_source_type = 'loser' THEN
        IF NEW.player1_id = NEW.winner_id THEN
          v_player_id := NEW.player2_id;
        ELSE
          v_player_id := NEW.player1_id;
        END IF;
      END IF;
      
      -- Fill player2_id
      IF v_player_id IS NOT NULL THEN
        UPDATE matches
        SET player2_id = v_player_id,
            updated_at = NOW()
        WHERE match_number = v_source_match.match_number
          AND tournament_id = NEW.tournament_id;
        
        RAISE NOTICE 'Auto-filled Player2 in Match % from Match % (% type)', 
          v_source_match.match_number, NEW.match_number, v_source_match.player2_source_type;
      END IF;
    END LOOP;
    
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Replace old trigger
DROP TRIGGER IF EXISTS trigger_auto_fill_cross_finals ON matches;
DROP TRIGGER IF EXISTS trigger_auto_fill_players_from_source ON matches;

CREATE TRIGGER trigger_auto_fill_players_from_source
  AFTER UPDATE ON matches
  FOR EACH ROW
  EXECUTE FUNCTION auto_fill_players_from_source();

COMMENT ON FUNCTION auto_fill_players_from_source() IS 
  'Auto-fills next match players based on player1/2_source_match and player1/2_source_type columns';

COMMENT ON TRIGGER trigger_auto_fill_players_from_source ON matches IS
  'Automatically populates match players when source matches complete';
