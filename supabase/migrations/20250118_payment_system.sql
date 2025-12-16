-- =====================================================
-- Payment System Migration
-- Created: 2025-01-18
-- Description: Payment methods and tournament payments
-- =====================================================

-- =====================================================
-- 1. PAYMENT METHODS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('bank_transfer', 'cash', 'momo', 'zalopay', 'vnpay', 'other')),
    bank_name TEXT,
    account_number TEXT,
    account_name TEXT,
    qr_code_url TEXT,
    qr_code_path TEXT,
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    
    -- Constraints
    CONSTRAINT payment_methods_club_type_unique UNIQUE (club_id, type, account_number)
);

-- Indexes for payment_methods
CREATE INDEX idx_payment_methods_club_id ON payment_methods(club_id);
CREATE INDEX idx_payment_methods_club_active ON payment_methods(club_id, is_active);
CREATE INDEX idx_payment_methods_club_default ON payment_methods(club_id, is_default);
CREATE INDEX idx_payment_methods_type ON payment_methods(type);

-- Comment
COMMENT ON TABLE payment_methods IS 'Payment methods configured by clubs for tournament registration';
COMMENT ON COLUMN payment_methods.type IS 'Payment method type: bank_transfer, cash, momo, zalopay, vnpay, other';
COMMENT ON COLUMN payment_methods.qr_code_url IS 'Public URL to QR code image';
COMMENT ON COLUMN payment_methods.qr_code_path IS 'Storage path for QR code image';
COMMENT ON COLUMN payment_methods.is_default IS 'Default payment method shown to users';

-- =====================================================
-- 2. TOURNAMENT PAYMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS tournament_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    payment_method_id UUID NOT NULL REFERENCES payment_methods(id) ON DELETE RESTRICT,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'verifying', 'verified', 'rejected', 'refunded')),
    proof_image_url TEXT,
    proof_image_path TEXT,
    transaction_note TEXT,
    transaction_reference TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    paid_at TIMESTAMP WITH TIME ZONE,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id),
    rejection_reason TEXT,
    
    -- Constraints
    CONSTRAINT tournament_payments_user_tournament_unique UNIQUE (tournament_id, user_id)
);

-- Indexes for tournament_payments
CREATE INDEX idx_tournament_payments_tournament_id ON tournament_payments(tournament_id);
CREATE INDEX idx_tournament_payments_user_id ON tournament_payments(user_id);
CREATE INDEX idx_tournament_payments_club_id ON tournament_payments(club_id);
CREATE INDEX idx_tournament_payments_status ON tournament_payments(status);
CREATE INDEX idx_tournament_payments_club_status ON tournament_payments(club_id, status);
CREATE INDEX idx_tournament_payments_verified_by ON tournament_payments(verified_by);
CREATE INDEX idx_tournament_payments_created_at ON tournament_payments(created_at DESC);

-- Comment
COMMENT ON TABLE tournament_payments IS 'Payment records for tournament registrations';
COMMENT ON COLUMN tournament_payments.status IS 'Payment status: pending, paid, verifying, verified, rejected, refunded';
COMMENT ON COLUMN tournament_payments.proof_image_url IS 'Screenshot of bank transfer confirmation';
COMMENT ON COLUMN tournament_payments.verified_by IS 'Admin user who verified the payment';

-- =====================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_payments ENABLE ROW LEVEL SECURITY;

-- Payment Methods Policies
-- Club owners/admins can manage their payment methods
CREATE POLICY "Club admins can view their payment methods"
    ON payment_methods FOR SELECT
    USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "Club admins can insert payment methods"
    ON payment_methods FOR INSERT
    WITH CHECK (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "Club admins can update their payment methods"
    ON payment_methods FOR UPDATE
    USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "Club admins can delete their payment methods"
    ON payment_methods FOR DELETE
    USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

-- Public can view active payment methods (for registration)
CREATE POLICY "Public can view active payment methods"
    ON payment_methods FOR SELECT
    USING (is_active = true);

-- Tournament Payments Policies
-- Users can view their own payments
CREATE POLICY "Users can view their own payments"
    ON tournament_payments FOR SELECT
    USING (user_id = auth.uid());

-- Users can create their own payments
CREATE POLICY "Users can create their own payments"
    ON tournament_payments FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Users can update their own pending payments
CREATE POLICY "Users can update their own pending payments"
    ON tournament_payments FOR UPDATE
    USING (user_id = auth.uid() AND status IN ('pending', 'rejected'));

-- Club admins can view all payments for their tournaments
CREATE POLICY "Club admins can view tournament payments"
    ON tournament_payments FOR SELECT
    USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

-- Club admins can update payment status (verify/reject)
CREATE POLICY "Club admins can update payment status"
    ON tournament_payments FOR UPDATE
    USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

-- =====================================================
-- 4. FUNCTIONS & TRIGGERS
-- =====================================================

-- Function: Ensure only one default payment method per club
CREATE OR REPLACE FUNCTION ensure_single_default_payment_method()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = true THEN
        -- Unset other defaults for this club
        UPDATE payment_methods
        SET is_default = false
        WHERE club_id = NEW.club_id
          AND id != NEW.id
          AND is_default = true;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_single_default_payment_method
    BEFORE INSERT OR UPDATE ON payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_payment_method();

-- Function: Update payment method updated_at
CREATE OR REPLACE FUNCTION update_payment_method_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_payment_method_updated_at
    BEFORE UPDATE ON payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_method_updated_at();

-- Function: Notify on payment status change
CREATE OR REPLACE FUNCTION notify_payment_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status != OLD.status THEN
        -- Insert notification (assuming you have a notifications table)
        -- INSERT INTO notifications (user_id, type, title, message, ...)
        -- VALUES (NEW.user_id, 'payment_status', ...);
        
        -- For now, just log
        RAISE NOTICE 'Payment % status changed from % to %', NEW.id, OLD.status, NEW.status;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_payment_status_change
    AFTER UPDATE ON tournament_payments
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION notify_payment_status_change();

-- =====================================================
-- 5. STORAGE BUCKETS
-- =====================================================

-- Create storage bucket for payment QR codes (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('club_assets', 'club_assets', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage bucket for payment proofs (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('tournament_assets', 'tournament_assets', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for club_assets (QR codes)
CREATE POLICY "Club admins can upload QR codes"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'club_assets'
        AND (storage.foldername(name))[1] = 'payment_qr_codes'
    );

CREATE POLICY "Public can view QR codes"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'club_assets'
        AND (storage.foldername(name))[1] = 'payment_qr_codes'
    );

CREATE POLICY "Club admins can delete their QR codes"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'club_assets'
        AND (storage.foldername(name))[1] = 'payment_qr_codes'
    );

-- Storage policies for tournament_assets (payment proofs)
CREATE POLICY "Users can upload payment proofs"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'tournament_assets'
        AND (storage.foldername(name))[1] = 'payment_proofs'
    );

CREATE POLICY "Users and admins can view payment proofs"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'tournament_assets'
        AND (storage.foldername(name))[1] = 'payment_proofs'
    );

-- =====================================================
-- 6. SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Insert sample payment method (uncomment to use)
-- INSERT INTO payment_methods (club_id, type, bank_name, account_number, account_name, is_default)
-- VALUES (
--     'your-club-id-here',
--     'bank_transfer',
--     'Vietcombank',
--     '1234567890',
--     'NGUYEN VAN A',
--     true
-- );

-- =====================================================
-- 7. VIEWS (Optional - for reporting)
-- =====================================================

-- View: Payment statistics by club
CREATE OR REPLACE VIEW payment_statistics AS
SELECT 
    c.id AS club_id,
    c.name AS club_name,
    COUNT(DISTINCT pm.id) AS payment_methods_count,
    COUNT(DISTINCT tp.id) AS total_payments,
    COUNT(DISTINCT CASE WHEN tp.status = 'verified' THEN tp.id END) AS verified_payments,
    COUNT(DISTINCT CASE WHEN tp.status = 'verifying' THEN tp.id END) AS pending_payments,
    COALESCE(SUM(CASE WHEN tp.status = 'verified' THEN tp.amount ELSE 0 END), 0) AS total_revenue
FROM clubs c
LEFT JOIN payment_methods pm ON c.id = pm.club_id AND pm.is_active = true
LEFT JOIN tournament_payments tp ON c.id = tp.club_id
GROUP BY c.id, c.name;

COMMENT ON VIEW payment_statistics IS 'Payment statistics aggregated by club';

-- =====================================================
-- END OF MIGRATION
-- =====================================================

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON payment_methods TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON tournament_payments TO authenticated;
GRANT SELECT ON payment_statistics TO authenticated;
