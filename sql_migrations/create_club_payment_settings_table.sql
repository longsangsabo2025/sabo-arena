-- Create club_payment_settings table with proper JSONB structure
-- Run this in Supabase SQL Editor

-- Drop existing table if wrong structure
DROP TABLE IF EXISTS club_payment_settings CASCADE;

CREATE TABLE IF NOT EXISTS club_payment_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Payment methods enabled flags
    cash_enabled BOOLEAN DEFAULT true,
    bank_enabled BOOLEAN DEFAULT false,
    ewallet_enabled BOOLEAN DEFAULT false,
    vnpay_enabled BOOLEAN DEFAULT false,
    
    -- Bank accounts as JSONB array
    bank_accounts JSONB DEFAULT '[]'::jsonb,
    -- Structure: [{ bank_name, account_number, account_name, qr_image_url, is_active }]
    
    -- E-wallet accounts as JSONB array
    ewallet_accounts JSONB DEFAULT '[]'::jsonb,
    -- Structure: [{ wallet_type, phone_number, owner_name, qr_image_url, is_active }]
    
    -- VNPay configuration as JSONB
    vnpay_config JSONB,
    -- Structure: { tmn_code, hash_secret, enabled }
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_club_payment_settings UNIQUE(club_id)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_club_payment_settings_club_id ON club_payment_settings(club_id);

-- RLS Policies
ALTER TABLE club_payment_settings ENABLE ROW LEVEL SECURITY;

-- Club owners and admins can read their payment settings
DROP POLICY IF EXISTS "Club owners and admins can read payment settings" ON club_payment_settings;
CREATE POLICY "Club owners and admins can read payment settings"
ON club_payment_settings FOR SELECT
USING (
    club_id IN (
        SELECT club_id FROM club_members 
        WHERE user_id = auth.uid() 
        AND role IN ('owner', 'admin')
    )
);

-- Club owners and admins can insert payment settings
DROP POLICY IF EXISTS "Club owners and admins can insert payment settings" ON club_payment_settings;
CREATE POLICY "Club owners and admins can insert payment settings"
ON club_payment_settings FOR INSERT
WITH CHECK (
    club_id IN (
        SELECT club_id FROM club_members 
        WHERE user_id = auth.uid() 
        AND role IN ('owner', 'admin')
    )
);

-- Club owners and admins can update payment settings
DROP POLICY IF EXISTS "Club owners and admins can update payment settings" ON club_payment_settings;
CREATE POLICY "Club owners and admins can update payment settings"
ON club_payment_settings FOR UPDATE
USING (
    club_id IN (
        SELECT club_id FROM club_members 
        WHERE user_id = auth.uid() 
        AND role IN ('owner', 'admin')
    )
);

-- Initialize settings for existing clubs
INSERT INTO club_payment_settings (club_id, cash_enabled, bank_enabled)
SELECT id, true, true
FROM clubs
WHERE id NOT IN (SELECT club_id FROM club_payment_settings)
ON CONFLICT (club_id) DO NOTHING;

-- Verify
SELECT 
    c.name as club_name,
    cps.cash_enabled,
    cps.bank_enabled,
    cps.ewallet_enabled,
    cps.bank_accounts,
    cps.ewallet_accounts
FROM club_payment_settings cps
JOIN clubs c ON c.id = cps.club_id;
