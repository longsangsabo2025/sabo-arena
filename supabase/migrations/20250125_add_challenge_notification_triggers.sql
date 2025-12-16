-- Migration: Add automatic notification triggers for challenges
-- Date: 2025-01-25
-- Purpose: Automatically create notification records when challenges are created or accepted

-- =====================================================
-- FUNCTION: Create notification for new challenge
-- =====================================================
CREATE OR REPLACE FUNCTION notify_challenge_created()
RETURNS TRIGGER AS $$
DECLARE
    challenger_name TEXT;
    challenge_type_vi TEXT;
BEGIN
    -- Only send notification if challenged_id is set (not open challenge)
    IF NEW.challenged_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Get challenger's display name
    SELECT display_name INTO challenger_name
    FROM users
    WHERE id = NEW.challenger_id;

    -- Translate challenge type
    challenge_type_vi := CASE 
        WHEN NEW.challenge_type = 'thach_dau' THEN 'thách đấu'
        ELSE 'giao lưu'
    END;

    -- Create notification for challenged user
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        data,
        is_read,
        created_at
    ) VALUES (
        NEW.challenged_id,
        'challenge',
        '🎱 Lời mời ' || challenge_type_vi || '!',
        COALESCE(challenger_name, 'Người chơi') || ' đã ' || 
        CASE WHEN NEW.challenge_type = 'thach_dau' THEN 'thách đấu' ELSE 'mời giao lưu' END || 
        ' bạn! Hãy vào ứng dụng để chấp nhận hoặc từ chối.',
        jsonb_build_object(
            'challenge_id', NEW.id,
            'challenger_id', NEW.challenger_id,
            'challenge_type', NEW.challenge_type,
            'stakes_amount', COALESCE(NEW.stakes_amount, 0)
        ),
        FALSE,
        NOW()
    );

    RAISE NOTICE 'Created notification for new challenge: % to user %', NEW.id, NEW.challenged_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Create notification when challenge accepted
-- =====================================================
CREATE OR REPLACE FUNCTION notify_challenge_accepted()
RETURNS TRIGGER AS $$
DECLARE
    challenged_name TEXT;
BEGIN
    -- Only notify if status changed to 'accepted'
    IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN
        
        -- Get challenged user's display name
        SELECT display_name INTO challenged_name
        FROM users
        WHERE id = NEW.challenged_id;

        -- Create notification for challenger
        INSERT INTO notifications (
            user_id,
            type,
            title,
            message,
            data,
            is_read,
            created_at
        ) VALUES (
            NEW.challenger_id,
            'challenge_accepted',
            'Thách đấu được chấp nhận! ⚔️',
            COALESCE(challenged_name, 'Người chơi') || ' đã chấp nhận thách đấu của bạn. Hãy chuẩn bị cho trận đấu!',
            jsonb_build_object(
                'challenge_id', NEW.id,
                'challenged_id', NEW.challenged_id,
                'challenger_id', NEW.challenger_id
            ),
            FALSE,
            NOW()
        );

        RAISE NOTICE 'Created notification for accepted challenge: % to user %', NEW.id, NEW.challenger_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Create notification when challenge declined
-- =====================================================
CREATE OR REPLACE FUNCTION notify_challenge_declined()
RETURNS TRIGGER AS $$
DECLARE
    challenged_name TEXT;
BEGIN
    -- Only notify if status changed to 'declined'
    IF NEW.status = 'declined' AND (OLD.status IS NULL OR OLD.status != 'declined') THEN
        
        -- Get challenged user's display name (if available)
        IF NEW.challenged_id IS NOT NULL THEN
            SELECT display_name INTO challenged_name
            FROM users
            WHERE id = NEW.challenged_id;
        END IF;

        -- Create notification for challenger
        INSERT INTO notifications (
            user_id,
            type,
            title,
            message,
            data,
            is_read,
            created_at
        ) VALUES (
            NEW.challenger_id,
            'challenge_declined',
            'Thách đấu bị từ chối 😔',
            COALESCE(challenged_name, 'Người chơi') || ' đã từ chối thách đấu của bạn.',
            jsonb_build_object(
                'challenge_id', NEW.id,
                'challenger_id', NEW.challenger_id
            ),
            FALSE,
            NOW()
        );

        RAISE NOTICE 'Created notification for declined challenge: % to user %', NEW.id, NEW.challenger_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- DROP existing triggers if they exist
-- =====================================================
DROP TRIGGER IF EXISTS trigger_notify_challenge_created ON challenges;
DROP TRIGGER IF EXISTS trigger_notify_challenge_accepted ON challenges;
DROP TRIGGER IF EXISTS trigger_notify_challenge_declined ON challenges;

-- =====================================================
-- CREATE TRIGGERS
-- =====================================================

-- Trigger for new challenges (INSERT)
CREATE TRIGGER trigger_notify_challenge_created
    AFTER INSERT ON challenges
    FOR EACH ROW
    EXECUTE FUNCTION notify_challenge_created();

-- Trigger for accepted/declined challenges (UPDATE)
CREATE TRIGGER trigger_notify_challenge_accepted
    AFTER UPDATE ON challenges
    FOR EACH ROW
    WHEN (NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted'))
    EXECUTE FUNCTION notify_challenge_accepted();

CREATE TRIGGER trigger_notify_challenge_declined
    AFTER UPDATE ON challenges
    FOR EACH ROW
    WHEN (NEW.status = 'declined' AND (OLD.status IS NULL OR OLD.status != 'declined'))
    EXECUTE FUNCTION notify_challenge_declined();

-- =====================================================
-- COMMENTS for documentation
-- =====================================================
COMMENT ON FUNCTION notify_challenge_created() IS 
    'Automatically creates notification when a new challenge is created';

COMMENT ON FUNCTION notify_challenge_accepted() IS 
    'Automatically creates notification when a challenge is accepted';

COMMENT ON FUNCTION notify_challenge_declined() IS 
    'Automatically creates notification when a challenge is declined';

COMMENT ON TRIGGER trigger_notify_challenge_created ON challenges IS 
    'Sends notification to challenged user when new challenge is created';

COMMENT ON TRIGGER trigger_notify_challenge_accepted ON challenges IS 
    'Sends notification to challenger when their challenge is accepted';

COMMENT ON TRIGGER trigger_notify_challenge_declined ON challenges IS 
    'Sends notification to challenger when their challenge is declined';
