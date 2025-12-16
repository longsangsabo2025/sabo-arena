-- =====================================================
-- Payment Gateway Configuration
-- Created: 2025-01-18
-- Description: Store API keys for MoMo, ZaloPay, VNPay
-- =====================================================

-- =====================================================
-- 1. CLUB PAYMENT CONFIG TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS club_payment_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT club_payment_config_club_unique UNIQUE (club_id)
);

-- Indexes
CREATE INDEX idx_club_payment_config_club_id ON club_payment_config(club_id);

-- Comments
COMMENT ON TABLE club_payment_config IS 'Payment gateway API keys configuration for clubs';
COMMENT ON COLUMN club_payment_config.config IS 'JSON config for MoMo, ZaloPay, VNPay keys';

-- Example config structure:
-- {
--   "momo": {
--     "partner_code": "MOMOXXX",
--     "access_key": "xxx",
--     "secret_key": "xxx",
--     "enabled": true
--   },
--   "zalopay": {
--     "app_id": "2553",
--     "key1": "xxx",
--     "key2": "xxx",
--     "enabled": true
--   },
--   "vnpay": {
--     "tmn_code": "VNPAYXXX",
--     "hash_secret": "xxx",
--     "enabled": true
--   }
-- }

-- =====================================================
-- 2. ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE club_payment_config ENABLE ROW LEVEL SECURITY;

-- Club owners/admins can view their config
CREATE POLICY "Club admins can view their payment config"
    ON club_payment_config FOR SELECT
    USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

-- Club owners/admins can insert config
CREATE POLICY "Club admins can insert payment config"
    ON club_payment_config FOR INSERT
    WITH CHECK (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

-- Club owners/admins can update their config
CREATE POLICY "Club admins can update payment config"
    ON club_payment_config FOR UPDATE
    USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

-- =====================================================
-- 3. FUNCTIONS & TRIGGERS
-- =====================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_club_payment_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_club_payment_config_updated_at
    BEFORE UPDATE ON club_payment_config
    FOR EACH ROW
    EXECUTE FUNCTION update_club_payment_config_updated_at();

-- =====================================================
-- 4. GRANT PERMISSIONS
-- =====================================================

GRANT SELECT, INSERT, UPDATE ON club_payment_config TO authenticated;
