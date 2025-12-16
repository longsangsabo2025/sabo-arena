-- =====================================================
-- PAYMENT SYSTEM FOR SABO ARENA
-- Created: 2025-01-17
-- Description: Complete payment system with QR code support
-- =====================================================

-- =====================================================
-- 1. CLUB PAYMENT SETTINGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS club_payment_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Payment methods enabled
    cash_enabled BOOLEAN DEFAULT true,
    bank_enabled BOOLEAN DEFAULT false,
    ewallet_enabled BOOLEAN DEFAULT false,
    vnpay_enabled BOOLEAN DEFAULT false,
    
    -- Bank account info
    bank_accounts JSONB DEFAULT '[]'::jsonb,
    -- Structure: [{ bank_name, account_number, account_name, qr_image_url, is_active }]
    
    -- E-wallet info
    ewallet_accounts JSONB DEFAULT '[]'::jsonb,
    -- Structure: [{ wallet_type, phone_number, owner_name, qr_image_url, is_active }]
    
    -- VNPay configuration
    vnpay_config JSONB,
    -- Structure: { tmn_code, hash_secret, enabled }
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_club_payment_settings UNIQUE(club_id)
);

-- Index
CREATE INDEX idx_club_payment_settings_club_id ON club_payment_settings(club_id);

-- RLS Policies
ALTER TABLE club_payment_settings ENABLE ROW LEVEL SECURITY;

-- Club owners and admins can read their payment settings
CREATE POLICY "Club owners and admins can read payment settings"
ON club_payment_settings FOR SELECT
USING (
    club_id IN (
        SELECT club_id FROM club_members 
        WHERE user_id = auth.uid() 
        AND role IN ('owner', 'admin')
    )
);

-- Club owners and admins can update payment settings
CREATE POLICY "Club owners and admins can update payment settings"
ON club_payment_settings FOR UPDATE
USING (
    club_id IN (
        SELECT club_id FROM club_members 
        WHERE user_id = auth.uid() 
        AND role IN ('owner', 'admin')
    )
);

-- Club owners and admins can insert payment settings
CREATE POLICY "Club owners and admins can insert payment settings"
ON club_payment_settings FOR INSERT
WITH CHECK (
    club_id IN (
        SELECT club_id FROM club_members 
        WHERE user_id = auth.uid() 
        AND role IN ('owner', 'admin')
    )
);

-- =====================================================
-- 2. PAYMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Payment details
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    payment_method VARCHAR(50) NOT NULL, -- 'cash', 'bank', 'momo', 'zalopay', 'vnpay'
    payment_info JSONB, -- Additional payment method specific info
    
    -- QR Code data
    qr_data TEXT,
    qr_image_url TEXT,
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled', 'expired')),
    
    -- Transaction info
    transaction_id VARCHAR(100), -- External transaction ID from payment gateway
    webhook_data JSONB, -- Data from payment gateway webhook
    
    -- Related entities
    invoice_id UUID, -- Link to invoice if exists
    booking_id UUID, -- Link to booking if exists
    tournament_id UUID, -- Link to tournament registration if exists
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '15 minutes',
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes
CREATE INDEX idx_payments_club_id ON payments(club_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_created_at ON payments(created_at DESC);
CREATE INDEX idx_payments_transaction_id ON payments(transaction_id) WHERE transaction_id IS NOT NULL;

-- RLS Policies
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Users can read their own payments
CREATE POLICY "Users can read their own payments"
ON payments FOR SELECT
USING (user_id = auth.uid());

-- Club owners and admins can read all club payments
CREATE POLICY "Club owners and admins can read club payments"
ON payments FOR SELECT
USING (
    club_id IN (
        SELECT club_id FROM club_members 
        WHERE user_id = auth.uid() 
        AND role IN ('owner', 'admin')
    )
);

-- System can insert payments
CREATE POLICY "Authenticated users can create payments"
ON payments FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- System can update payment status
CREATE POLICY "System can update payments"
ON payments FOR UPDATE
USING (true);

-- =====================================================
-- 3. PAYMENT QR IMAGES STORAGE
-- =====================================================
-- Create storage bucket for payment QR codes
INSERT INTO storage.buckets (id, name, public) 
VALUES ('payment-qr-codes', 'payment-qr-codes', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for payment QR codes
CREATE POLICY "Club admins can upload QR codes"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'payment-qr-codes' AND
    auth.uid() IN (
        SELECT user_id FROM club_members 
        WHERE role IN ('owner', 'admin')
    )
);

CREATE POLICY "Anyone can view QR codes"
ON storage.objects FOR SELECT
USING (bucket_id = 'payment-qr-codes');

CREATE POLICY "Club admins can update QR codes"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'payment-qr-codes' AND
    auth.uid() IN (
        SELECT user_id FROM club_members 
        WHERE role IN ('owner', 'admin')
    )
);

CREATE POLICY "Club admins can delete QR codes"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'payment-qr-codes' AND
    auth.uid() IN (
        SELECT user_id FROM club_members 
        WHERE role IN ('owner', 'admin')
    )
);

-- =====================================================
-- 4. FUNCTIONS
-- =====================================================

-- Function to update club balance after payment
CREATE OR REPLACE FUNCTION update_club_balance(
    p_club_id UUID,
    p_amount DECIMAL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update club's total revenue (if you have such field)
    -- This is a placeholder - adjust based on your actual club schema
    UPDATE clubs 
    SET updated_at = NOW()
    WHERE id = p_club_id;
    
    -- You can add more logic here like updating club statistics
END;
$$;

-- Function to get payment statistics
CREATE OR REPLACE FUNCTION get_payment_stats(
    p_club_id UUID,
    p_from_date TIMESTAMPTZ,
    p_to_date TIMESTAMPTZ
)
RETURNS TABLE (
    total_payments BIGINT,
    total_amount DECIMAL,
    completed_payments BIGINT,
    completed_amount DECIMAL,
    pending_payments BIGINT,
    pending_amount DECIMAL,
    payment_method_breakdown JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_payments,
        COALESCE(SUM(amount), 0) as total_amount,
        COUNT(*) FILTER (WHERE status = 'completed')::BIGINT as completed_payments,
        COALESCE(SUM(amount) FILTER (WHERE status = 'completed'), 0) as completed_amount,
        COUNT(*) FILTER (WHERE status = 'pending')::BIGINT as pending_payments,
        COALESCE(SUM(amount) FILTER (WHERE status = 'pending'), 0) as pending_amount,
        jsonb_object_agg(
            payment_method, 
            jsonb_build_object(
                'count', count,
                'amount', amount
            )
        ) as payment_method_breakdown
    FROM payments
    WHERE club_id = p_club_id
        AND created_at BETWEEN p_from_date AND p_to_date
    GROUP BY club_id;
    
    -- If no data, return zeros
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT 
            0::BIGINT,
            0::DECIMAL,
            0::BIGINT,
            0::DECIMAL,
            0::BIGINT,
            0::DECIMAL,
            '{}'::JSONB;
    END IF;
END;
$$;

-- Function to auto-expire pending payments
CREATE OR REPLACE FUNCTION expire_old_payments()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE payments
    SET status = 'expired'
    WHERE status = 'pending'
        AND expires_at < NOW();
END;
$$;

-- =====================================================
-- 5. TRIGGERS
-- =====================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_club_payment_settings_updated_at
    BEFORE UPDATE ON club_payment_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 6. SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Add default payment settings for existing clubs
-- INSERT INTO club_payment_settings (club_id, cash_enabled)
-- SELECT id, true FROM clubs
-- ON CONFLICT (club_id) DO NOTHING;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

COMMENT ON TABLE club_payment_settings IS 'Stores payment configuration for each club';
COMMENT ON TABLE payments IS 'Tracks all payment transactions in the system';
COMMENT ON FUNCTION update_club_balance IS 'Updates club balance after successful payment';
COMMENT ON FUNCTION get_payment_stats IS 'Returns payment statistics for a club within a date range';
COMMENT ON FUNCTION expire_old_payments IS 'Automatically expires old pending payments';
