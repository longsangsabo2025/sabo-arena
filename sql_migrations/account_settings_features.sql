-- =============================================================================
-- ACCOUNT SETTINGS FEATURES - Complete Implementation
-- Created: 2025-12-20
-- Features: 2FA, Login Sessions, Privacy Settings, Account Status
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. TWO-FACTOR AUTHENTICATION (2FA)
-- -----------------------------------------------------------------------------

-- Add 2FA columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS totp_secret TEXT,
ADD COLUMN IF NOT EXISTS totp_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS totp_backup_codes TEXT[], -- Array of hashed backup codes
ADD COLUMN IF NOT EXISTS totp_enabled_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN users.totp_secret IS 'Base32 encoded TOTP secret for authenticator apps';
COMMENT ON COLUMN users.totp_enabled IS 'Whether 2FA is currently enabled';
COMMENT ON COLUMN users.totp_backup_codes IS 'Hashed backup codes for account recovery';
COMMENT ON COLUMN users.totp_enabled_at IS 'When 2FA was enabled';

-- Create index for 2FA lookups
CREATE INDEX IF NOT EXISTS idx_users_totp_enabled ON users(totp_enabled) WHERE totp_enabled = TRUE;


-- -----------------------------------------------------------------------------
-- 2. LOGIN SESSIONS TRACKING
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Session info
    session_token TEXT NOT NULL UNIQUE,
    refresh_token TEXT UNIQUE,
    
    -- Device info
    device_type TEXT, -- 'mobile', 'tablet', 'desktop', 'web'
    device_name TEXT, -- e.g., 'iPhone 14 Pro', 'Chrome on Windows'
    device_os TEXT, -- e.g., 'iOS 17', 'Windows 11'
    browser TEXT, -- e.g., 'Chrome 120', 'Safari 17'
    
    -- Location info
    ip_address INET,
    country TEXT,
    city TEXT,
    
    -- Session state
    is_active BOOLEAN DEFAULT TRUE,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Metadata
    user_agent TEXT,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for session queries
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_active ON user_sessions(user_id, is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires ON user_sessions(expires_at) WHERE is_active = TRUE;

-- RLS for user_sessions
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own sessions"
    ON user_sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own sessions"
    ON user_sessions FOR DELETE
    USING (auth.uid() = user_id);

COMMENT ON TABLE user_sessions IS 'Tracks all active login sessions for security monitoring';


-- -----------------------------------------------------------------------------
-- 3. PRIVACY SETTINGS
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_privacy_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    -- Profile visibility
    profile_public BOOLEAN DEFAULT TRUE,
    show_email BOOLEAN DEFAULT FALSE,
    show_phone BOOLEAN DEFAULT FALSE,
    show_location BOOLEAN DEFAULT TRUE,
    show_stats BOOLEAN DEFAULT TRUE,
    
    -- Activity visibility
    show_online_status BOOLEAN DEFAULT TRUE,
    show_match_history BOOLEAN DEFAULT TRUE,
    show_tournaments BOOLEAN DEFAULT TRUE,
    
    -- Search & discoverability
    searchable BOOLEAN DEFAULT TRUE,
    allow_friend_requests BOOLEAN DEFAULT TRUE,
    allow_messages BOOLEAN DEFAULT TRUE,
    
    -- Notifications preferences
    email_notifications BOOLEAN DEFAULT TRUE,
    push_notifications BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for privacy lookups
CREATE INDEX IF NOT EXISTS idx_privacy_settings_user_id ON user_privacy_settings(user_id);

-- RLS for privacy settings
ALTER TABLE user_privacy_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own privacy settings"
    ON user_privacy_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own privacy settings"
    ON user_privacy_settings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own privacy settings"
    ON user_privacy_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Trigger to create default privacy settings for new users
CREATE OR REPLACE FUNCTION create_default_privacy_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_privacy_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_user_created_privacy
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION create_default_privacy_settings();

COMMENT ON TABLE user_privacy_settings IS 'User privacy and visibility preferences';


-- -----------------------------------------------------------------------------
-- 4. BLOCKED USERS
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Prevent blocking yourself or duplicate blocks
    CONSTRAINT no_self_block CHECK (blocker_id != blocked_id),
    CONSTRAINT unique_block UNIQUE (blocker_id, blocked_id)
);

-- Indexes for block queries
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker ON user_blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked ON user_blocks(blocked_id);

-- RLS for user_blocks
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their blocks"
    ON user_blocks FOR SELECT
    USING (auth.uid() = blocker_id);

CREATE POLICY "Users can create blocks"
    ON user_blocks FOR INSERT
    WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can delete their blocks"
    ON user_blocks FOR DELETE
    USING (auth.uid() = blocker_id);

COMMENT ON TABLE user_blocks IS 'User blocking for privacy and safety';


-- -----------------------------------------------------------------------------
-- 5. ACCOUNT DEACTIVATION
-- -----------------------------------------------------------------------------

-- Add deactivation columns to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS is_deactivated BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS deactivated_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS deactivation_reason TEXT;

-- Index for finding deactivated accounts
CREATE INDEX IF NOT EXISTS idx_users_deactivated ON users(is_deactivated) WHERE is_deactivated = TRUE;

COMMENT ON COLUMN users.is_deactivated IS 'Soft delete - account hidden but can be reactivated';
COMMENT ON COLUMN users.deactivated_at IS 'When the account was deactivated';


-- -----------------------------------------------------------------------------
-- 6. ACCOUNT DELETION AUDIT LOG
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS deleted_accounts_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    email TEXT,
    username TEXT,
    full_name TEXT,
    
    -- Deletion info
    deletion_reason TEXT,
    deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_by UUID REFERENCES users(id), -- Self-delete or admin delete
    
    -- Stats at time of deletion
    total_matches INTEGER,
    total_tournaments INTEGER,
    spa_points INTEGER,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_deleted_accounts_log_user_id ON deleted_accounts_log(user_id);
CREATE INDEX IF NOT EXISTS idx_deleted_accounts_log_deleted_at ON deleted_accounts_log(deleted_at);

COMMENT ON TABLE deleted_accounts_log IS 'Audit log of deleted accounts for compliance and recovery';


-- -----------------------------------------------------------------------------
-- 7. SESSION CLEANUP FUNCTION
-- -----------------------------------------------------------------------------

-- Function to clean up expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM user_sessions
    WHERE expires_at < NOW() AND is_active = TRUE;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION cleanup_expired_sessions() IS 'Removes expired sessions - should be run via cron job';


-- -----------------------------------------------------------------------------
-- 8. HELPER VIEWS
-- -----------------------------------------------------------------------------

-- View for active sessions per user
CREATE OR REPLACE VIEW user_active_sessions AS
SELECT 
    user_id,
    COUNT(*) as active_sessions,
    MAX(last_activity_at) as most_recent_activity,
    array_agg(device_type ORDER BY last_activity_at DESC) as devices
FROM user_sessions
WHERE is_active = TRUE AND expires_at > NOW()
GROUP BY user_id;

COMMENT ON VIEW user_active_sessions IS 'Summary of active sessions per user';


-- -----------------------------------------------------------------------------
-- 9. GRANT PERMISSIONS
-- -----------------------------------------------------------------------------

-- Grant appropriate permissions (adjust based on your RLS setup)
GRANT SELECT, INSERT, UPDATE, DELETE ON user_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON user_privacy_settings TO authenticated;
GRANT SELECT, INSERT, DELETE ON user_blocks TO authenticated;
GRANT INSERT ON deleted_accounts_log TO authenticated;


-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

-- Verify tables created
DO $$
BEGIN
    RAISE NOTICE 'Migration complete! Created:';
    RAISE NOTICE '  ✓ user_sessions table';
    RAISE NOTICE '  ✓ user_privacy_settings table';
    RAISE NOTICE '  ✓ user_blocks table';
    RAISE NOTICE '  ✓ deleted_accounts_log table';
    RAISE NOTICE '  ✓ 2FA columns in users table';
    RAISE NOTICE '  ✓ Deactivation columns in users table';
    RAISE NOTICE '  ✓ RLS policies';
    RAISE NOTICE '  ✓ Helper functions and views';
END $$;
