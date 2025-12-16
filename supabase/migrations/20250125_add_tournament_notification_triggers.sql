-- =====================================================
-- TOURNAMENT NOTIFICATION TRIGGERS
-- Tự động gửi thông báo khi có sự kiện tournament
-- =====================================================

-- =====================================================
-- 1. Trigger khi tournament được tạo (thông báo cho members của club)
-- =====================================================
CREATE OR REPLACE FUNCTION notify_tournament_created()
RETURNS TRIGGER AS $$
DECLARE
    v_club_name text;
    v_creator_name text;
    v_member_id uuid;
BEGIN
    -- Lấy thông tin club và creator
    SELECT 
        c.name,
        u.display_name
    INTO v_club_name, v_creator_name
    FROM clubs c
    LEFT JOIN users u ON u.id = NEW.organizer_id
    WHERE c.id = NEW.club_id;

    -- Gửi notification cho TẤT CẢ members của club (trừ creator)
    FOR v_member_id IN 
        SELECT user_id 
        FROM club_members 
        WHERE club_id = NEW.club_id 
        AND user_id != NEW.organizer_id
        AND status = 'active'
    LOOP
        INSERT INTO notifications (
            user_id,
            type,
            title,
            message,
            data,
            created_at
        ) VALUES (
            v_member_id,
            'tournament',
            '🏆 Giải đấu mới!',
            format('%s vừa tạo giải đấu "%s" tại %s. Hãy đăng ký tham gia ngay!',
                COALESCE(v_creator_name, 'Admin'),
                NEW.title,
                COALESCE(v_club_name, 'club')
            ),
            jsonb_build_object(
                'tournament_id', NEW.id,
                'club_id', NEW.club_id,
                'tournament_name', NEW.title,
                'start_date', NEW.start_date,
                'max_players', NEW.max_participants
            ),
            NOW()
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_tournament_created
    AFTER INSERT ON tournaments
    FOR EACH ROW
    EXECUTE FUNCTION notify_tournament_created();

-- =====================================================
-- 2. Trigger khi tournament bắt đầu (thông báo cho participants)
-- =====================================================
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

CREATE TRIGGER trigger_notify_tournament_started
    AFTER UPDATE ON tournaments
    FOR EACH ROW
    EXECUTE FUNCTION notify_tournament_started();

-- =====================================================
-- 3. Trigger khi tournament kết thúc (thông báo cho participants)
-- =====================================================
CREATE OR REPLACE FUNCTION notify_tournament_completed()
RETURNS TRIGGER AS $$
DECLARE
    v_tournament_name text;
    v_club_name text;
    v_participant_id uuid;
    v_winner_name text;
BEGIN
    -- Chỉ trigger khi status chuyển sang 'completed'
    IF OLD.status != 'completed' AND NEW.status = 'completed' THEN
        -- Lấy thông tin tournament, club và winner  
        -- Note: tournaments table không có winner_id, bỏ qua phần này
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
                'tournament_completed',
                'Giải đấu đã kết thúc! 🏆',
                format('Giải đấu "%s" đã kết thúc! Vào xem kết quả chi tiết.',
                    v_tournament_name
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

CREATE TRIGGER trigger_notify_tournament_completed
    AFTER UPDATE ON tournaments
    FOR EACH ROW
    EXECUTE FUNCTION notify_tournament_completed();

-- =====================================================
-- 4. Trigger khi user đăng ký tham gia tournament (thông báo cho creator)
-- =====================================================
CREATE OR REPLACE FUNCTION notify_tournament_registration()
RETURNS TRIGGER AS $$
DECLARE
    v_tournament_name text;
    v_club_name text;
    v_player_name text;
    v_organizer_id uuid;
BEGIN
    -- Lấy thông tin tournament, club, player và organizer
    SELECT 
        t.title,
        c.name,
        u.display_name,
        t.organizer_id
    INTO v_tournament_name, v_club_name, v_player_name, v_organizer_id
    FROM tournaments t
    JOIN clubs c ON c.id = t.club_id
    LEFT JOIN users u ON u.id = NEW.user_id
    WHERE t.id = NEW.tournament_id;

    -- Gửi notification cho organizer (chủ giải)
    IF v_organizer_id IS NOT NULL THEN
        INSERT INTO notifications (
            user_id,
            type,
            title,
            message,
            data,
            created_at
        ) VALUES (
            v_organizer_id,
            'tournament_registration',
            '📝 Có người đăng ký tham gia!',
            format('%s vừa đăng ký tham gia giải đấu "%s".',
                COALESCE(v_player_name, 'Một người chơi'),
                v_tournament_name
            ),
            jsonb_build_object(
                'tournament_id', NEW.tournament_id,
                'player_id', NEW.user_id,
                'player_name', v_player_name,
                'tournament_name', v_tournament_name
            ),
            NOW()
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_tournament_registration
    AFTER INSERT ON tournament_participants
    FOR EACH ROW
    EXECUTE FUNCTION notify_tournament_registration();

-- =====================================================
-- 5. Trigger khi có match mới trong tournament (thông báo cho 2 players)
-- =====================================================
CREATE OR REPLACE FUNCTION notify_tournament_match_created()
RETURNS TRIGGER AS $$
DECLARE
    v_tournament_name text;
    v_club_name text;
    v_player1_name text;
    v_player2_name text;
BEGIN
    -- Chỉ xử lý matches thuộc tournament
    IF NEW.tournament_id IS NOT NULL THEN
        -- Lấy thông tin tournament, club và players
        SELECT 
            t.title,
            c.name,
            u1.display_name,
            u2.display_name
        INTO v_tournament_name, v_club_name, v_player1_name, v_player2_name
        FROM tournaments t
        JOIN clubs c ON c.id = t.club_id
        LEFT JOIN users u1 ON u1.id = NEW.player1_id
        LEFT JOIN users u2 ON u2.id = NEW.player2_id
        WHERE t.id = NEW.tournament_id;

        -- Notification cho player 1
        IF NEW.player1_id IS NOT NULL THEN
            INSERT INTO notifications (
                user_id,
                type,
                title,
                message,
                data,
                created_at
            ) VALUES (
                NEW.player1_id,
                'tournament_match',
                '🎱 Trận đấu mới trong giải!',
                format('Bạn có trận đấu với %s trong giải "%s". %s',
                    COALESCE(v_player2_name, 'đối thủ'),
                    v_tournament_name,
                    CASE 
                        WHEN NEW.scheduled_time IS NOT NULL THEN 
                            format('Thời gian: %s', to_char(NEW.scheduled_time, 'DD/MM HH24:MI'))
                        ELSE 'Vào xem chi tiết.'
                    END
                ),
                jsonb_build_object(
                    'match_id', NEW.id,
                    'tournament_id', NEW.tournament_id,
                    'tournament_name', v_tournament_name,
                    'opponent_id', NEW.player2_id,
                    'opponent_name', v_player2_name,
                    'scheduled_time', NEW.scheduled_time
                ),
                NOW()
            );
        END IF;

        -- Notification cho player 2
        IF NEW.player2_id IS NOT NULL THEN
            INSERT INTO notifications (
                user_id,
                type,
                title,
                message,
                data,
                created_at
            ) VALUES (
                NEW.player2_id,
                'tournament_match',
                '🎱 Trận đấu mới trong giải!',
                format('Bạn có trận đấu với %s trong giải "%s". %s',
                    COALESCE(v_player1_name, 'đối thủ'),
                    v_tournament_name,
                    CASE 
                        WHEN NEW.scheduled_time IS NOT NULL THEN 
                            format('Thời gian: %s', to_char(NEW.scheduled_time, 'DD/MM HH24:MI'))
                        ELSE 'Vào xem chi tiết.'
                    END
                ),
                jsonb_build_object(
                    'match_id', NEW.id,
                    'tournament_id', NEW.tournament_id,
                    'tournament_name', v_tournament_name,
                    'opponent_id', NEW.player1_id,
                    'opponent_name', v_player1_name,
                    'scheduled_time', NEW.scheduled_time
                ),
                NOW()
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_tournament_match_created
    AFTER INSERT ON matches
    FOR EACH ROW
    EXECUTE FUNCTION notify_tournament_match_created();

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Kiểm tra các triggers đã được tạo:
-- SELECT 
--     t.tgname as trigger_name,
--     c.relname as table_name,
--     p.proname as function_name
-- FROM pg_trigger t
-- JOIN pg_class c ON t.tgrelid = c.oid
-- JOIN pg_proc p ON t.tgfoid = p.oid
-- WHERE c.relname IN ('tournaments', 'tournament_participants', 'matches')
-- AND NOT t.tgisinternal
-- AND p.proname LIKE 'notify_tournament%'
-- ORDER BY c.relname, t.tgname;
