-- =====================================================
-- AUTO FILL CROSS FINALS PLAYERS
-- =====================================================
-- Khi một match trong WB/LB-A/LB-B hoàn thành (status = 'completed'),
-- tự động fill winner/loser vào Cross Finals matches theo advancement rules
-- =====================================================

-- Function: Tự động fill players vào Cross Finals khi source match complete
CREATE OR REPLACE FUNCTION auto_fill_cross_finals_players()
RETURNS TRIGGER AS $$
DECLARE
  v_winner_id UUID;
  v_loser_id UUID;
  v_winner_advances_to TEXT;
  v_loser_advances_to TEXT;
  v_target_match_number INT;
  v_target_match RECORD;
BEGIN
  -- Chỉ xử lý khi match vừa completed (status changed to 'completed')
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    
    -- Get winner and advancement info
    v_winner_id := NEW.winner_id;
    v_winner_advances_to := NEW.winner_advances_to;
    v_loser_advances_to := NEW.loser_advances_to;
    
    -- Determine loser_id (the player who is NOT the winner)
    IF NEW.player1_id = v_winner_id THEN
      v_loser_id := NEW.player2_id;
    ELSIF NEW.player2_id = v_winner_id THEN
      v_loser_id := NEW.player1_id;
    END IF;

    -- ==========================================
    -- HANDLE WINNER ADVANCEMENT to Cross Finals
    -- ==========================================
    IF v_winner_advances_to IS NOT NULL AND v_winner_advances_to LIKE 'M%' THEN
      -- Extract match number from "M107", "M108", etc.
      v_target_match_number := CAST(SUBSTRING(v_winner_advances_to FROM 2) AS INT);
      
      -- Find the target Cross Finals match
      SELECT * INTO v_target_match
      FROM matches
      WHERE match_number = v_target_match_number
        AND tournament_id = NEW.tournament_id
        AND bracket_group = 'CROSS';
      
      IF FOUND THEN
        -- Fill player1_id if empty, otherwise fill player2_id
        IF v_target_match.player1_id IS NULL THEN
          UPDATE matches
          SET player1_id = v_winner_id,
              updated_at = NOW()
          WHERE match_number = v_target_match_number
            AND tournament_id = NEW.tournament_id
            AND bracket_group = 'CROSS';
          
          RAISE NOTICE 'Auto-filled Player1 in Match % with winner from Match %', 
            v_target_match_number, NEW.match_number;
        
        ELSIF v_target_match.player2_id IS NULL THEN
          UPDATE matches
          SET player2_id = v_winner_id,
              updated_at = NOW()
          WHERE match_number = v_target_match_number
            AND tournament_id = NEW.tournament_id
            AND bracket_group = 'CROSS';
          
          RAISE NOTICE 'Auto-filled Player2 in Match % with winner from Match %', 
            v_target_match_number, NEW.match_number;
        
        ELSE
          RAISE WARNING 'Match % already has both players filled!', v_target_match_number;
        END IF;
      END IF;
    END IF;

    -- ==========================================
    -- HANDLE LOSER ADVANCEMENT to Cross Finals (if applicable)
    -- ==========================================
    IF v_loser_advances_to IS NOT NULL AND v_loser_advances_to LIKE 'M%' AND v_loser_id IS NOT NULL THEN
      v_target_match_number := CAST(SUBSTRING(v_loser_advances_to FROM 2) AS INT);
      
      SELECT * INTO v_target_match
      FROM matches
      WHERE match_number = v_target_match_number
        AND tournament_id = NEW.tournament_id
        AND bracket_group = 'CROSS';
      
      IF FOUND THEN
        IF v_target_match.player1_id IS NULL THEN
          UPDATE matches
          SET player1_id = v_loser_id,
              updated_at = NOW()
          WHERE match_number = v_target_match_number
            AND tournament_id = NEW.tournament_id
            AND bracket_group = 'CROSS';
          
          RAISE NOTICE 'Auto-filled Player1 in Match % with loser from Match %', 
            v_target_match_number, NEW.match_number;
        
        ELSIF v_target_match.player2_id IS NULL THEN
          UPDATE matches
          SET player2_id = v_loser_id,
              updated_at = NOW()
          WHERE match_number = v_target_match_number
            AND tournament_id = NEW.tournament_id
            AND bracket_group = 'CROSS';
          
          RAISE NOTICE 'Auto-filled Player2 in Match % with loser from Match %', 
            v_target_match_number, NEW.match_number;
        
        ELSE
          RAISE WARNING 'Match % already has both players filled!', v_target_match_number;
        END IF;
      END IF;
    END IF;
    
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Fire khi có match update
DROP TRIGGER IF EXISTS trigger_auto_fill_cross_finals ON matches;
CREATE TRIGGER trigger_auto_fill_cross_finals
  AFTER UPDATE ON matches
  FOR EACH ROW
  EXECUTE FUNCTION auto_fill_cross_finals_players();

-- =====================================================
-- VERIFICATION
-- =====================================================
COMMENT ON FUNCTION auto_fill_cross_finals_players() IS 
  'Auto-fills Cross Finals match players when source matches (WB/LB-A/LB-B) are completed. 
   Uses winner_advances_to and loser_advances_to fields to determine target matches.';

COMMENT ON TRIGGER trigger_auto_fill_cross_finals ON matches IS
  'Automatically populates Cross Finals bracket players based on completed feeder matches.';
