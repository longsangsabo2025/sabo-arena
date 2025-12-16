-- =====================================================
-- MIGRATION: AUTO POST TOURNAMENT MATCHES FEATURE
-- Tự động đăng bài khi có trận Cross Finals
-- Created: 2025-10-26
-- =====================================================

-- =====================================================
-- BƯỚC 1: MỞ RỘNG BẢNG POSTS
-- =====================================================
ALTER TABLE posts
ADD COLUMN IF NOT EXISTS match_id uuid REFERENCES matches(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS auto_posted boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS post_trigger text CHECK (post_trigger IN ('announcement', 'reminder', 'live', 'result')),
ADD COLUMN IF NOT EXISTS scheduled_post_time timestamptz,
ADD COLUMN IF NOT EXISTS is_pinned boolean DEFAULT false;

-- Tạo index cho performance
CREATE INDEX IF NOT EXISTS idx_posts_match_id ON posts(match_id);
CREATE INDEX IF NOT EXISTS idx_posts_auto_posted ON posts(auto_posted);
CREATE INDEX IF NOT EXISTS idx_posts_tournament_match ON posts(tournament_id, match_id) WHERE tournament_id IS NOT NULL AND match_id IS NOT NULL;

-- =====================================================
-- BƯỚC 2: TẠO BẢNG TOURNAMENT POST SETTINGS
-- =====================================================
CREATE TABLE IF NOT EXISTS tournament_post_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    club_id uuid REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Auto post configuration
    auto_post_enabled boolean DEFAULT true,
    post_cross_finals boolean DEFAULT true,
    post_semifinals boolean DEFAULT true,
    post_finals boolean DEFAULT true,
    post_third_place boolean DEFAULT false,
    post_all_rounds boolean DEFAULT false,
    
    -- Reminder settings
    reminder_minutes_before integer DEFAULT 60 CHECK (reminder_minutes_before > 0),
    send_reminder boolean DEFAULT true,
    
    -- Content settings
    include_player_stats boolean DEFAULT true,
    include_tournament_info boolean DEFAULT true,
    enable_live_stream boolean DEFAULT false,
    auto_pin_posts boolean DEFAULT true,
    
    -- Timestamps
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    
    -- Constraints
    UNIQUE(tournament_id)
);

-- Index cho performance
CREATE INDEX IF NOT EXISTS idx_tournament_post_settings_tournament ON tournament_post_settings(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_post_settings_club ON tournament_post_settings(club_id);

-- =====================================================
-- BƯỚC 3: FUNCTION KIỂM TRA TRẬN CROSS FINALS
-- =====================================================
CREATE OR REPLACE FUNCTION is_cross_finals_match(match_id uuid)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
    match_record RECORD;
BEGIN
    SELECT 
        bracket_type,
        stage_round,
        is_final,
        is_third_place,
        winner_advances_to,
        loser_advances_to
    INTO match_record
    FROM matches
    WHERE id = match_id;
    
    -- Cross Finals = WB player vs LB player
    -- Thường là round cuối của Winner Bracket gặp Winner của Loser Bracket
    IF match_record.bracket_type = 'WB' AND 
       match_record.loser_advances_to IS NOT NULL AND
       NOT match_record.is_final THEN
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$;

-- =====================================================
-- BƯỚC 4: FUNCTION TẠO AUTO POST CHO TRẬN ĐẤU
-- =====================================================
CREATE OR REPLACE FUNCTION create_tournament_match_post(
    p_match_id uuid,
    p_trigger_type text DEFAULT 'announcement'
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_match RECORD;
    v_tournament RECORD;
    v_settings RECORD;
    v_player1 RECORD;
    v_player2 RECORD;
    v_post_id uuid;
    v_content text;
    v_post_exists boolean;
BEGIN
    -- Lấy thông tin match
    SELECT * INTO v_match
    FROM matches
    WHERE id = p_match_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Match not found: %', p_match_id;
    END IF;
    
    -- Lấy thông tin tournament
    SELECT * INTO v_tournament
    FROM tournaments
    WHERE id = v_match.tournament_id;
    
    -- Lấy settings
    SELECT * INTO v_settings
    FROM tournament_post_settings
    WHERE tournament_id = v_match.tournament_id;
    
    -- Nếu không có settings hoặc auto post disabled, return null
    IF NOT FOUND OR NOT v_settings.auto_post_enabled THEN
        RETURN NULL;
    END IF;
    
    -- Kiểm tra xem đã có post cho match này chưa (với trigger type này)
    SELECT EXISTS(
        SELECT 1 FROM posts 
        WHERE match_id = p_match_id 
        AND post_trigger = p_trigger_type
    ) INTO v_post_exists;
    
    IF v_post_exists THEN
        RETURN NULL; -- Đã có post rồi, không tạo nữa
    END IF;
    
    -- Lấy thông tin players
    SELECT * INTO v_player1
    FROM users
    WHERE id = v_match.player1_id;
    
    SELECT * INTO v_player2
    FROM users
    WHERE id = v_match.player2_id;
    
    -- Tạo nội dung post dựa vào trigger type
    CASE p_trigger_type
        WHEN 'announcement' THEN
            v_content := format(
                E'🏆 TRẬN ĐẤU QUAN TRỌNG - %s 🏆\n\n' ||
                E'🎯 Trận: %s\n' ||
                E'⚔️ %s (ELO: %s, Rank: %s)\n' ||
                E'    VS\n' ||
                E'⚔️ %s (ELO: %s, Rank: %s)\n\n' ||
                E'📍 Địa điểm: %s\n' ||
                E'🎮 Môn thi đấu: %s\n\n' ||
                E'👉 Click để xem chi tiết và theo dõi trận đấu!',
                v_tournament.title,
                CASE 
                    WHEN v_match.is_final THEN 'CHUNG KẾT'
                    WHEN v_match.is_third_place THEN 'TRANH HẠNG 3'
                    WHEN is_cross_finals_match(p_match_id) THEN 'CROSS FINALS'
                    ELSE 'Vòng ' || v_match.stage_round
                END,
                v_player1.display_name,
                v_player1.elo_rating::text,
                v_player1.rank,
                v_player2.display_name,
                v_player2.elo_rating::text,
                v_player2.rank,
                v_tournament.venue_address,
                v_tournament.game_format
            );
            
        WHEN 'reminder' THEN
            v_content := format(
                E'⏰ NHẮC NHỞ: Trận đấu sắp diễn ra!\n\n' ||
                E'🏆 %s\n' ||
                E'⚔️ %s vs %s\n\n' ||
                E'⏱️ Bắt đầu sau %s phút nữa!\n' ||
                E'👉 Chuẩn bị theo dõi ngay!',
                v_tournament.title,
                v_player1.display_name,
                v_player2.display_name,
                v_settings.reminder_minutes_before::text
            );
            
        WHEN 'live' THEN
            v_content := format(
                E'🔴 ĐANG DIỄN RA TRỰC TIẾP!\n\n' ||
                E'🏆 %s\n' ||
                E'⚔️ %s vs %s\n\n' ||
                E'📺 Click để xem LIVESTREAM ngay!',
                v_tournament.title,
                v_player1.display_name,
                v_player2.display_name
            );
            
        WHEN 'result' THEN
            v_content := format(
                E'✅ KẾT QUẢ TRẬN ĐẤU\n\n' ||
                E'🏆 %s\n' ||
                E'🎯 %s: %s - %s\n\n' ||
                E'🏅 Người chiến thắng: %s\n' ||
                E'👉 Xem chi tiết trận đấu!',
                v_tournament.title,
                v_player1.display_name || ' vs ' || v_player2.display_name,
                v_match.player1_score::text,
                v_match.player2_score::text,
                CASE 
                    WHEN v_match.winner_id = v_match.player1_id THEN v_player1.display_name
                    WHEN v_match.winner_id = v_match.player2_id THEN v_player2.display_name
                    ELSE 'Hòa'
                END
            );
    END CASE;
    
    -- Tạo post
    INSERT INTO posts (
        user_id,
        content,
        post_type,
        tournament_id,
        match_id,
        club_id,
        auto_posted,
        post_trigger,
        is_pinned,
        is_public,
        visibility,
        created_at,
        updated_at
    ) VALUES (
        v_tournament.organizer_id,
        v_content,
        'tournament_match',
        v_match.tournament_id,
        p_match_id,
        v_tournament.club_id,
        true,
        p_trigger_type,
        v_settings.auto_pin_posts,
        true,
        'public',
        now(),
        now()
    )
    RETURNING id INTO v_post_id;
    
    RETURN v_post_id;
END;
$$;

-- =====================================================
-- BƯỚC 5: TRIGGER KHI TẠO CROSS FINALS MATCH
-- =====================================================
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
    
    -- Kiểm tra xem có nên post không
    IF NEW.is_final AND v_settings.post_finals THEN
        v_should_post := true;
    ELSIF NEW.is_third_place AND v_settings.post_third_place THEN
        v_should_post := true;
    ELSIF is_cross_finals_match(NEW.id) AND v_settings.post_cross_finals THEN
        v_should_post := true;
    ELSIF NEW.stage_round >= (
        SELECT MAX(stage_round) - 1 
        FROM matches 
        WHERE tournament_id = NEW.tournament_id
    ) AND v_settings.post_semifinals THEN
        v_should_post := true;
    ELSIF v_settings.post_all_rounds THEN
        v_should_post := true;
    END IF;
    
    -- Nếu nên post, tạo announcement post
    IF v_should_post THEN
        PERFORM create_tournament_match_post(NEW.id, 'announcement');
    END IF;
    
    RETURN NEW;
END;
$$;

-- Tạo trigger
DROP TRIGGER IF EXISTS auto_post_tournament_match ON matches;
CREATE TRIGGER auto_post_tournament_match
    AFTER INSERT ON matches
    FOR EACH ROW
    EXECUTE FUNCTION trigger_auto_post_on_match_create();

-- =====================================================
-- BƯỚC 6: TRIGGER KHI MATCH BẮT ĐẦU LIVE
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_auto_post_on_match_live()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Khi match chuyển sang is_live = true
    IF NEW.is_live = true AND OLD.is_live = false THEN
        -- Tạo live post
        PERFORM create_tournament_match_post(NEW.id, 'live');
    END IF;
    
    -- Khi match hoàn thành
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Tạo result post
        PERFORM create_tournament_match_post(NEW.id, 'result');
        
        -- Unpin announcement và reminder posts
        UPDATE posts
        SET is_pinned = false
        WHERE match_id = NEW.id
        AND post_trigger IN ('announcement', 'reminder');
    END IF;
    
    RETURN NEW;
END;
$$;

-- Tạo trigger
DROP TRIGGER IF EXISTS auto_post_match_live ON matches;
CREATE TRIGGER auto_post_match_live
    AFTER UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION trigger_auto_post_on_match_live();

-- =====================================================
-- BƯỚC 7: FUNCTION TẠO DEFAULT SETTINGS KHI TẠO TOURNAMENT
-- =====================================================
CREATE OR REPLACE FUNCTION create_default_tournament_post_settings()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Tạo default settings cho tournament mới
    INSERT INTO tournament_post_settings (
        tournament_id,
        club_id,
        auto_post_enabled,
        post_cross_finals,
        post_semifinals,
        post_finals,
        post_third_place,
        post_all_rounds,
        reminder_minutes_before,
        send_reminder,
        include_player_stats,
        include_tournament_info,
        enable_live_stream,
        auto_pin_posts
    ) VALUES (
        NEW.id,
        NEW.club_id,
        true,  -- Mặc định bật auto post
        true,  -- Post cross finals
        true,  -- Post semifinals
        true,  -- Post finals
        false, -- Không post third place
        false, -- Không post tất cả các vòng
        60,    -- Nhắc trước 60 phút
        true,  -- Bật reminder
        true,  -- Include player stats
        true,  -- Include tournament info
        false, -- Live stream tắt mặc định
        true   -- Auto pin posts
    );
    
    RETURN NEW;
END;
$$;

-- Tạo trigger
DROP TRIGGER IF EXISTS create_tournament_post_settings ON tournaments;
CREATE TRIGGER create_tournament_post_settings
    AFTER INSERT ON tournaments
    FOR EACH ROW
    EXECUTE FUNCTION create_default_tournament_post_settings();

-- =====================================================
-- BƯỚC 8: RLS POLICIES
-- =====================================================

-- Enable RLS cho tournament_post_settings
ALTER TABLE tournament_post_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Mọi người đều có thể xem settings
CREATE POLICY "Anyone can view tournament post settings"
    ON tournament_post_settings FOR SELECT
    USING (true);

-- Policy: Chỉ organizer hoặc club owner mới sửa được settings
CREATE POLICY "Only organizer or club owner can update settings"
    ON tournament_post_settings FOR UPDATE
    USING (
        auth.uid() IN (
            SELECT organizer_id FROM tournaments WHERE id = tournament_id
            UNION
            SELECT owner_id FROM clubs WHERE id = club_id
        )
    );

-- Policy: Chỉ organizer hoặc club owner mới insert được settings
CREATE POLICY "Only organizer or club owner can insert settings"
    ON tournament_post_settings FOR INSERT
    WITH CHECK (
        auth.uid() IN (
            SELECT organizer_id FROM tournaments WHERE id = tournament_id
            UNION
            SELECT owner_id FROM clubs WHERE id = club_id
        )
    );

-- =====================================================
-- BƯỚC 9: TẠO DEFAULT SETTINGS CHO CÁC TOURNAMENT ĐÃ TỒN TẠI
-- =====================================================
INSERT INTO tournament_post_settings (
    tournament_id,
    club_id,
    auto_post_enabled,
    post_cross_finals,
    post_semifinals,
    post_finals
)
SELECT 
    id,
    club_id,
    true,
    true,
    true,
    true
FROM tournaments
WHERE id NOT IN (SELECT tournament_id FROM tournament_post_settings)
ON CONFLICT (tournament_id) DO NOTHING;

-- =====================================================
-- HOÀN THÀNH MIGRATION
-- =====================================================
COMMENT ON TABLE tournament_post_settings IS 'Cấu hình tự động đăng bài cho các trận đấu trong giải đấu';
COMMENT ON COLUMN posts.match_id IS 'ID của trận đấu liên quan (nếu là post về match)';
COMMENT ON COLUMN posts.auto_posted IS 'Post được tạo tự động bởi hệ thống';
COMMENT ON COLUMN posts.post_trigger IS 'Loại trigger: announcement, reminder, live, result';
