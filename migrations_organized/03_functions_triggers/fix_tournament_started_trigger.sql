-- Fix notify_tournament_started function to use 'ongoing' status
CREATE OR REPLACE FUNCTION notify_tournament_started()
RETURNS TRIGGER AS $$
DECLARE
    v_tournament_name text;
    v_club_name text;
    v_participant_id uuid;
BEGIN
    -- Chỉ trigger khi status chuyển sang 'ongoing'
    IF OLD.status != 'ongoing' AND NEW.status = 'ongoing' THEN
        -- Lấy thông tin tournament và club
        SELECT 
            NEW.title,
            c.name
        INTO v_tournament_name, v_club_name
        FROM clubs c
        WHERE c.id = NEW.club_id;

        -- Gửi notification cho TẤT CẢ participants
        FOR v_participant_id IN 
            SELECT user_id 
            FROM tournament_participants 
            WHERE tournament_id = NEW.id
        LOOP
            INSERT INTO notifications (
                user_id,
                type,
                title,
                message,
                data,
                created_at
            ) VALUES (
                v_participant_id,
                'tournament_started',
                'Giải đấu đã bắt đầu! 🎱',
                format('Giải đấu "%s" tại %s đã bắt đầu! Vào xem lịch thi đấu của bạn.',
                    v_tournament_name,
                    COALESCE(v_club_name, 'club')
                ),
                jsonb_build_object(
                    'tournament_id', NEW.id,
                    'club_id', NEW.club_id,
                    'tournament_name', v_tournament_name
                ),
                NOW()
            );
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER trigger_notify_tournament_started
    AFTER UPDATE ON tournaments
    FOR EACH ROW
    EXECUTE FUNCTION notify_tournament_started();
