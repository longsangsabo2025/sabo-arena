-- Script to create tables needed for voucher notification system

-- 1. Table to store club notifications
CREATE TABLE IF NOT EXISTS club_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL, -- 'voucher_usage_request', 'general', etc.
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}', -- Store additional data like voucher info
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

-- 2. Update user_redemptions table to support voucher system
-- Check if voucher_code column exists, if not add it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_redemptions' AND column_name='voucher_code') THEN
        ALTER TABLE user_redemptions ADD COLUMN voucher_code VARCHAR(20) UNIQUE;
    END IF;
END $$;

-- Check if status column exists, if not add it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_redemptions' AND column_name='status') THEN
        ALTER TABLE user_redemptions ADD COLUMN status VARCHAR(20) DEFAULT 'delivered';
    END IF;
END $$;

-- Check if requested_at column exists, if not add it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_redemptions' AND column_name='requested_at') THEN
        ALTER TABLE user_redemptions ADD COLUMN requested_at TIMESTAMPTZ;
    END IF;
END $$;

-- Check if used_at column exists, if not add it  
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_redemptions' AND column_name='used_at') THEN
        ALTER TABLE user_redemptions ADD COLUMN used_at TIMESTAMPTZ;
    END IF;
END $$;

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_club_notifications_club_id ON club_notifications(club_id);
CREATE INDEX IF NOT EXISTS idx_club_notifications_is_read ON club_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_club_notifications_type ON club_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_user_redemptions_voucher_code ON user_redemptions(voucher_code);
CREATE INDEX IF NOT EXISTS idx_user_redemptions_status ON user_redemptions(status);

-- 4. Create function to generate unique voucher codes
CREATE OR REPLACE FUNCTION generate_voucher_code() 
RETURNS VARCHAR(20) AS $$
DECLARE
    code VARCHAR(20);
    attempts INT := 0;
BEGIN
    LOOP
        -- Generate code: CLUB prefix + 8 random characters
        code := 'CLUB' || LPAD(FLOOR(RANDOM() * 99999999)::TEXT, 8, '0');
        
        -- Check if code already exists
        IF NOT EXISTS (SELECT 1 FROM user_redemptions WHERE voucher_code = code) THEN
            RETURN code;
        END IF;
        
        attempts := attempts + 1;
        IF attempts > 100 THEN
            RAISE EXCEPTION 'Could not generate unique voucher code after 100 attempts';
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger to auto-generate voucher codes for new redemptions
CREATE OR REPLACE FUNCTION auto_generate_voucher_code()
RETURNS TRIGGER AS $$
BEGIN
    -- Only generate code if not already set
    IF NEW.voucher_code IS NULL THEN
        NEW.voucher_code := generate_voucher_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_voucher_code ON user_redemptions;
CREATE TRIGGER trigger_auto_voucher_code
    BEFORE INSERT ON user_redemptions
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_voucher_code();

-- 6. Update existing redemptions to have voucher codes if they don't have any
UPDATE user_redemptions 
SET voucher_code = generate_voucher_code() 
WHERE voucher_code IS NULL;

-- 7. Set default status for existing redemptions
UPDATE user_redemptions 
SET status = 'delivered' 
WHERE status IS NULL;

-- 8. Enable RLS (Row Level Security) if needed
ALTER TABLE club_notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for club_notifications
DROP POLICY IF EXISTS "Club staff can view their notifications" ON club_notifications;
CREATE POLICY "Club staff can view their notifications" ON club_notifications
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM club_memberships cm 
            WHERE cm.club_id = club_notifications.club_id 
            AND cm.user_id = auth.uid()
            AND cm.role IN ('owner', 'admin', 'staff')
        )
    );

DROP POLICY IF EXISTS "Club staff can update their notifications" ON club_notifications;
CREATE POLICY "Club staff can update their notifications" ON club_notifications
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM club_memberships cm 
            WHERE cm.club_id = club_notifications.club_id 
            AND cm.user_id = auth.uid()
            AND cm.role IN ('owner', 'admin', 'staff')
        )
    );

-- Grant necessary permissions
GRANT SELECT, INSERT ON club_notifications TO authenticated;
GRANT SELECT, UPDATE ON user_redemptions TO authenticated;

COMMENT ON TABLE club_notifications IS 'Store notifications for clubs, including voucher usage requests';
COMMENT ON COLUMN club_notifications.notification_type IS 'Type of notification: voucher_usage_request, general, etc.';
COMMENT ON COLUMN club_notifications.data IS 'Additional JSON data for the notification';
COMMENT ON COLUMN user_redemptions.voucher_code IS 'Unique voucher code for this redemption';
COMMENT ON COLUMN user_redemptions.status IS 'Status: delivered, pending_approval, used, cancelled';
COMMENT ON COLUMN user_redemptions.requested_at IS 'When user requested to use this voucher';  
COMMENT ON COLUMN user_redemptions.used_at IS 'When voucher was actually used/confirmed by club';

SELECT 'Voucher notification system setup completed successfully!' as message;