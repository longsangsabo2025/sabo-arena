-- 🔒 ATOMIC ADVANCEMENT FUNCTION
-- Prevents race conditions when multiple matches complete simultaneously
-- Uses FOR UPDATE lock to ensure only one advancement operation at a time per target match

CREATE OR REPLACE FUNCTION advance_player_atomic(
  p_target_display_order INT,
  p_player_id UUID,
  p_tournament_id UUID
) RETURNS JSON AS $$
DECLARE
  v_match_id UUID;
  v_match_number INT;
  v_player1 UUID;
  v_player2 UUID;
  v_slot TEXT;
  v_both_filled BOOLEAN;
BEGIN
  -- Lock row FOR UPDATE to prevent concurrent modifications
  SELECT id, match_number, player1_id, player2_id 
  INTO v_match_id, v_match_number, v_player1, v_player2
  FROM matches 
  WHERE tournament_id = p_tournament_id 
    AND display_order = p_target_display_order
  FOR UPDATE;
  
  -- Check if match exists
  IF v_match_id IS NULL THEN
    RETURN json_build_object(
      'success', false, 
      'error', 'Target match not found',
      'display_order', p_target_display_order
    );
  END IF;
  
  -- Determine which slot to fill
  IF v_player1 IS NULL THEN
    v_slot := 'player1_id';
    v_both_filled := false;
  ELSIF v_player2 IS NULL THEN
    v_slot := 'player2_id';
    v_both_filled := true; -- Will be filled after this update
  ELSE
    -- Both slots already filled
    RETURN json_build_object(
      'success', false,
      'error', 'Both slots already filled',
      'match_number', v_match_number,
      'player1_id', v_player1,
      'player2_id', v_player2
    );
  END IF;
  
  -- Atomic update
  IF v_slot = 'player1_id' THEN
    UPDATE matches 
    SET player1_id = p_player_id 
    WHERE id = v_match_id;
  ELSE
    UPDATE matches 
    SET player2_id = p_player_id 
    WHERE id = v_match_id;
  END IF;
  
  -- If both slots now filled, update status to 'pending' (ready to play)
  IF v_both_filled THEN
    UPDATE matches 
    SET status = 'pending'
    WHERE id = v_match_id;
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'match_id', v_match_id,
    'match_number', v_match_number,
    'slot', v_slot,
    'match_ready', v_both_filled
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION advance_player_atomic TO authenticated;

-- Example usage:
-- SELECT advance_player_atomic(11201, 'player-uuid', 'tournament-uuid');
