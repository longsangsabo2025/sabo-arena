-- ============================================================================
-- PHASE 1: CRITICAL TABLES - PAYMENT & TOURNAMENT SYSTEM
-- ============================================================================
-- Generated: October 23, 2025
-- Purpose: Create 4 critical tables for core payment and tournament features
-- Risk: HIGH - App won't work without these tables
-- ============================================================================

-- ============================================================================
-- TABLE 1: payments - Core Payment Records
-- ============================================================================
-- Purpose: Store all payment transactions
-- Usage: 11 references in real_payment_service.dart
-- Dependencies: users, clubs tables

CREATE TABLE IF NOT EXISTS public.payments (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Foreign Keys
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Payment Details
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(3) DEFAULT 'VND',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded')),
    payment_method VARCHAR(50),  -- momo, bank_transfer, cash, etc.
    
    -- Transaction Info
    transaction_id VARCHAR(255) UNIQUE,  -- External transaction ID
    reference_id VARCHAR(255),  -- Internal reference
    payment_type VARCHAR(50),  -- tournament_fee, club_membership, voucher, etc.
    
    -- Related Entities
    tournament_id UUID,  -- If payment is for tournament
    voucher_id UUID,     -- If voucher is applied
    
    -- Payment Gateway Response
    gateway_response JSONB,  -- Store full response from gateway
    error_message TEXT,
    
    -- Metadata
    description TEXT,
    metadata JSONB,  -- Additional flexible data
    
    -- Timestamps
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_club_id ON public.payments(club_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_tournament_id ON public.payments(tournament_id);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON public.payments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payments_transaction_id ON public.payments(transaction_id);

-- RLS Policies
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Users can view their own payments
CREATE POLICY "Users can view own payments" ON public.payments
    FOR SELECT
    USING (auth.uid() = user_id);

-- Club admins can view club payments
CREATE POLICY "Club admins can view club payments" ON public.payments
    FOR SELECT
    USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- Service role can do everything
CREATE POLICY "Service role full access" ON public.payments
    FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

COMMENT ON TABLE public.payments IS 'Core payment transactions for all payment types';

-- ============================================================================
-- TABLE 2: payment_methods - Payment Gateway Configuration
-- ============================================================================
-- Purpose: Store payment method configurations for clubs
-- Usage: 10 references in payment_method_service.dart
-- Dependencies: clubs table

CREATE TABLE IF NOT EXISTS public.payment_methods (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Foreign Keys
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Method Details
    method_type VARCHAR(50) NOT NULL CHECK (method_type IN ('momo', 'bank_transfer', 'cash', 'vnpay', 'zalopay')),
    method_name VARCHAR(100) NOT NULL,
    
    -- Configuration
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    
    -- Gateway Config (encrypted in production)
    config JSONB NOT NULL,  -- Store API keys, merchant IDs, etc.
    
    -- Display Info
    display_order INTEGER DEFAULT 0,
    icon_url TEXT,
    qr_code_url TEXT,  -- For QR-based payments
    
    -- Bank Transfer Specific
    bank_name VARCHAR(100),
    account_number VARCHAR(50),
    account_holder VARCHAR(100),
    
    -- Limits
    min_amount DECIMAL(10,2),
    max_amount DECIMAL(10,2),
    daily_limit DECIMAL(10,2),
    
    -- Fees
    transaction_fee_percent DECIMAL(5,2) DEFAULT 0,
    transaction_fee_fixed DECIMAL(10,2) DEFAULT 0,
    
    -- Metadata
    description TEXT,
    metadata JSONB,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_payment_methods_club_id ON public.payment_methods(club_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_method_type ON public.payment_methods(method_type);
CREATE INDEX IF NOT EXISTS idx_payment_methods_is_active ON public.payment_methods(is_active);

-- Unique constraint: One default method per club per type
CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_methods_club_default 
    ON public.payment_methods(club_id, method_type) 
    WHERE is_default = true AND deleted_at IS NULL;

-- RLS Policies
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

-- Club admins can manage their payment methods
CREATE POLICY "Club admins can manage payment methods" ON public.payment_methods
    FOR ALL
    USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- Anyone can view active payment methods for clubs
CREATE POLICY "Anyone can view active payment methods" ON public.payment_methods
    FOR SELECT
    USING (is_active = true AND deleted_at IS NULL);

COMMENT ON TABLE public.payment_methods IS 'Payment gateway configurations for clubs';

-- ============================================================================
-- TABLE 3: payment_transactions - Payment Transaction History
-- ============================================================================
-- Purpose: Detailed transaction log for refunds and reconciliation
-- Usage: 5 references in payment_refund_service.dart
-- Dependencies: payments, users tables

CREATE TABLE IF NOT EXISTS public.payment_transactions (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Foreign Keys
    payment_id UUID REFERENCES public.payments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    
    -- Transaction Details
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('charge', 'refund', 'chargeback', 'adjustment')),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'VND',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    
    -- Gateway Info
    gateway VARCHAR(50),  -- momo, vnpay, etc.
    gateway_transaction_id VARCHAR(255),
    gateway_response JSONB,
    
    -- Refund Specific
    refund_reason TEXT,
    refund_amount DECIMAL(10,2),
    original_transaction_id UUID REFERENCES public.payment_transactions(id),
    
    -- Reconciliation
    reconciled BOOLEAN DEFAULT false,
    reconciled_at TIMESTAMPTZ,
    reconciled_by UUID REFERENCES public.users(id),
    
    -- Metadata
    notes TEXT,
    metadata JSONB,
    
    -- Timestamps
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_payment_transactions_payment_id ON public.payment_transactions(payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id ON public.payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_type ON public.payment_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON public.payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_gateway ON public.payment_transactions(gateway);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_created_at ON public.payment_transactions(created_at DESC);

-- RLS Policies
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

-- Users can view their own transactions
CREATE POLICY "Users can view own transactions" ON public.payment_transactions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Club admins can view club-related transactions
CREATE POLICY "Club admins can view club transactions" ON public.payment_transactions
    FOR SELECT
    USING (
        payment_id IN (
            SELECT id FROM public.payments
            WHERE club_id IN (
                SELECT club_id FROM public.club_members
                WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
            )
        )
    );

COMMENT ON TABLE public.payment_transactions IS 'Detailed payment transaction log for refunds and reconciliation';

-- ============================================================================
-- TABLE 4: tournament_payments - Tournament Entry Fees & Prizes
-- ============================================================================
-- Purpose: Track tournament-specific payments (entry fees, prize distributions)
-- Usage: 9 references in payment_method_service.dart, tournament_registration_screen.dart
-- Dependencies: tournaments, users, clubs tables

CREATE TABLE IF NOT EXISTS public.tournament_payments (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Foreign Keys
    tournament_id UUID NOT NULL,  -- References tournaments(id)
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL,
    payment_id UUID REFERENCES public.payments(id) ON DELETE SET NULL,
    
    -- Payment Type
    payment_type VARCHAR(50) NOT NULL CHECK (payment_type IN ('entry_fee', 'prize_distribution', 'refund', 'penalty')),
    
    -- Amount Details
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'VND',
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'processing', 'completed', 'failed', 'refunded')),
    
    -- Tournament Registration
    registration_id UUID,  -- Link to tournament_participants if needed
    
    -- Prize Distribution
    prize_position INTEGER,  -- 1st, 2nd, 3rd place
    prize_type VARCHAR(50),  -- cash, voucher, spa_points
    
    -- Payment Method
    payment_method VARCHAR(50),
    transaction_reference VARCHAR(255),
    
    -- Receipt & Verification
    receipt_url TEXT,
    receipt_image_url TEXT,
    verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES public.users(id),
    
    -- Refund Info
    refund_reason TEXT,
    refunded_at TIMESTAMPTZ,
    refund_transaction_id UUID,
    
    -- Metadata
    notes TEXT,
    metadata JSONB,
    
    -- Timestamps
    paid_at TIMESTAMPTZ,
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_tournament_payments_tournament_id ON public.tournament_payments(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_payments_user_id ON public.tournament_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_tournament_payments_club_id ON public.tournament_payments(club_id);
CREATE INDEX IF NOT EXISTS idx_tournament_payments_payment_id ON public.tournament_payments(payment_id);
CREATE INDEX IF NOT EXISTS idx_tournament_payments_status ON public.tournament_payments(status);
CREATE INDEX IF NOT EXISTS idx_tournament_payments_type ON public.tournament_payments(payment_type);
CREATE INDEX IF NOT EXISTS idx_tournament_payments_created_at ON public.tournament_payments(created_at DESC);

-- RLS Policies
ALTER TABLE public.tournament_payments ENABLE ROW LEVEL SECURITY;

-- Users can view their own tournament payments
CREATE POLICY "Users can view own tournament payments" ON public.tournament_payments
    FOR SELECT
    USING (auth.uid() = user_id);

-- Club admins can view their tournament payments
CREATE POLICY "Club admins can view tournament payments" ON public.tournament_payments
    FOR SELECT
    USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- Tournament participants can view tournament payments
CREATE POLICY "Participants can view tournament payments" ON public.tournament_payments
    FOR SELECT
    USING (
        tournament_id IN (
            SELECT tournament_id FROM public.tournament_participants
            WHERE user_id = auth.uid()
        )
    );

COMMENT ON TABLE public.tournament_payments IS 'Tournament entry fees and prize distributions';

-- ============================================================================
-- PHASE 1 MIGRATION COMPLETE
-- ============================================================================
-- Created 4 critical tables:
-- 1. payments (11 refs) - Core payment processing
-- 2. payment_methods (10 refs) - Payment gateway config
-- 3. payment_transactions (5 refs) - Transaction history
-- 4. tournament_payments (9 refs) - Tournament fees
--
-- Total: 35 references across payment and tournament systems
-- Impact: Payment and tournament registration will work
-- ============================================================================
