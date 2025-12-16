-- =====================================================
-- FIX: Remove round_name reference from trigger
-- The matches table doesn't have round_name column
-- Use only stage_round and is_final to detect semifinals
-- =====================================================

-- Update trigger function WITHOUT round_name check
CREATE OR REPLACE FUNCTION trigger_auto_post_on_match_create()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_settings RECORD;
    v_should_post boolean := false;
BEGIN
    -- Lấy settings của tournament
    SELECT * INTO v_settings
    FROM tournament_post_settings
    WHERE tournament_id = NEW.tournament_id;
    
    -- Nếu không có settings hoặc auto post disabled, skip
    IF NOT FOUND OR NOT v_settings.auto_post_enabled THEN
        RETURN NEW;
    END IF;
    
    -- CHỈ POST 2 BÁN KẾT + 1 CHUNG KẾT
    -- Kiểm tra xem match có phải semifinals hoặc final không
    IF NEW.is_final AND v_settings.post_finals THEN
        -- CHUNG KẾT
        v_should_post := true;
    ELSIF v_settings.post_semifinals THEN
        -- BÁN KẾT: Check if this is semifinal round
        -- Semifinal thường là round trước final
        DECLARE
            v_max_round integer;
            v_is_semifinal boolean := false;
        BEGIN
            -- Lấy round lớn nhất trong tournament
            SELECT MAX(stage_round) INTO v_max_round
            FROM matches 
            WHERE tournament_id = NEW.tournament_id;
            
            -- Nếu round này là max_round - 1, đó là semifinal
            -- Với single elimination bracket:
            -- - Final: round N (is_final = true)
            -- - Semifinals: round N-1 (có 2 trận)
            -- - Quarterfinals: round N-2 (có 4 trận)
            IF v_max_round IS NOT NULL AND NEW.stage_round = v_max_round - 1 THEN
                v_is_semifinal := true;
            END IF;
            
            IF v_is_semifinal THEN
                v_should_post := true;
            END IF;
        END;
    END IF;
    
    -- Nếu nên post, tạo announcement post
    IF v_should_post THEN
        PERFORM create_tournament_match_post(NEW.id, 'announcement');
    END IF;
    
    RETURN NEW;
END;
$$;

-- Update comment for clarity
COMMENT ON FUNCTION trigger_auto_post_on_match_create() IS 
'Tự động tạo post khi tạo trận đấu - CHỈ 2 BÁN KẾT + 1 CHUNG KẾT (dựa vào stage_round)';

-- Recreate trigger
DROP TRIGGER IF EXISTS auto_post_tournament_match ON matches;
CREATE TRIGGER auto_post_tournament_match
    AFTER INSERT ON matches
    FOR EACH ROW
    EXECUTE FUNCTION trigger_auto_post_on_match_create();

-- =====================================================
-- Verify trigger is active
-- =====================================================
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table, 
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'auto_post_tournament_match';
