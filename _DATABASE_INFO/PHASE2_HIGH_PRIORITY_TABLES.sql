-- ============================================================================
-- PHASE 2: HIGH PRIORITY TABLES - CLUB FEATURES & SPA REWARDS
-- ============================================================================
-- Generated: October 23, 2025
-- Purpose: Create 12 high priority tables for club features and rewards
-- Dependencies: Phase 1 tables, users, clubs
-- ============================================================================

-- ============================================================================
-- TABLE 5: club_payments - Club Payment Records
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.club_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(3) DEFAULT 'VND',
    payment_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    payment_method VARCHAR(50),
    transaction_id VARCHAR(255),
    description TEXT,
    metadata JSONB,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_club_payments_club_id ON public.club_payments(club_id);
CREATE INDEX IF NOT EXISTS idx_club_payments_status ON public.club_payments(status);
CREATE INDEX IF NOT EXISTS idx_club_payments_created_at ON public.club_payments(created_at DESC);

ALTER TABLE public.club_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Club admins can manage club payments" ON public.club_payments
    FOR ALL USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================================
-- TABLE 6: club_payment_config - Club Payment Gateway Configuration
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.club_payment_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    gateway_type VARCHAR(50) NOT NULL,
    config JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(club_id, gateway_type)
);

CREATE INDEX IF NOT EXISTS idx_club_payment_config_club_id ON public.club_payment_config(club_id);

ALTER TABLE public.club_payment_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Club admins can manage payment config" ON public.club_payment_config
    FOR ALL USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================================
-- TABLE 7: club_payment_settings - Club Payment Preferences
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.club_payment_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    auto_accept_payments BOOLEAN DEFAULT false,
    require_receipt BOOLEAN DEFAULT true,
    payment_deadline_hours INTEGER DEFAULT 24,
    late_payment_penalty_percent DECIMAL(5,2) DEFAULT 0,
    settings JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(club_id)
);

CREATE INDEX IF NOT EXISTS idx_club_payment_settings_club_id ON public.club_payment_settings(club_id);

ALTER TABLE public.club_payment_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Club admins can manage payment settings" ON public.club_payment_settings
    FOR ALL USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================================
-- TABLE 8: club_promotions - Club Promotion Campaigns
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.club_promotions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    promotion_type VARCHAR(50) NOT NULL CHECK (promotion_type IN ('discount', 'cashback', 'free_game', 'spa_bonus', 'voucher')),
    discount_type VARCHAR(20) CHECK (discount_type IN ('percent', 'fixed')),
    discount_value DECIMAL(10,2),
    minimum_purchase DECIMAL(10,2),
    maximum_discount DECIMAL(10,2),
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    usage_limit INTEGER,
    usage_limit_per_user INTEGER DEFAULT 1,
    current_usage INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    terms_and_conditions TEXT,
    image_url TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_club_promotions_club_id ON public.club_promotions(club_id);
CREATE INDEX IF NOT EXISTS idx_club_promotions_is_active ON public.club_promotions(is_active);
CREATE INDEX IF NOT EXISTS idx_club_promotions_dates ON public.club_promotions(start_date, end_date);

ALTER TABLE public.club_promotions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active promotions" ON public.club_promotions
    FOR SELECT USING (is_active = true AND NOW() BETWEEN start_date AND end_date);

CREATE POLICY "Club admins can manage promotions" ON public.club_promotions
    FOR ALL USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================================
-- TABLE 9: promotion_redemptions - Promotion Usage Tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.promotion_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promotion_id UUID NOT NULL REFERENCES public.club_promotions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL,
    payment_id UUID REFERENCES public.payments(id) ON DELETE SET NULL,
    discount_amount DECIMAL(10,2),
    original_amount DECIMAL(10,2),
    final_amount DECIMAL(10,2),
    redeemed_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_promotion_redemptions_promotion_id ON public.promotion_redemptions(promotion_id);
CREATE INDEX IF NOT EXISTS idx_promotion_redemptions_user_id ON public.promotion_redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_promotion_redemptions_redeemed_at ON public.promotion_redemptions(redeemed_at DESC);

ALTER TABLE public.promotion_redemptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own redemptions" ON public.promotion_redemptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Club admins can view redemptions" ON public.promotion_redemptions
    FOR SELECT USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================================
-- TABLE 10: spa_rewards - SPA Reward Catalog
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.spa_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    reward_name VARCHAR(200) NOT NULL,
    description TEXT,
    reward_type VARCHAR(50) NOT NULL CHECK (reward_type IN ('free_game', 'discount', 'merchandise', 'voucher', 'cash')),
    spa_cost INTEGER NOT NULL CHECK (spa_cost > 0),
    cash_value DECIMAL(10,2),
    stock_quantity INTEGER,
    available_quantity INTEGER,
    is_active BOOLEAN DEFAULT true,
    image_url TEXT,
    terms TEXT,
    valid_days INTEGER DEFAULT 30,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_spa_rewards_club_id ON public.spa_rewards(club_id);
CREATE INDEX IF NOT EXISTS idx_spa_rewards_is_active ON public.spa_rewards(is_active);
CREATE INDEX IF NOT EXISTS idx_spa_rewards_spa_cost ON public.spa_rewards(spa_cost);

ALTER TABLE public.spa_rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active rewards" ON public.spa_rewards
    FOR SELECT USING (is_active = true);

CREATE POLICY "Club admins can manage rewards" ON public.spa_rewards
    FOR ALL USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================================
-- TABLE 11: spa_reward_redemptions - SPA Reward Usage
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.spa_reward_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reward_id UUID NOT NULL REFERENCES public.spa_rewards(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL,
    spa_spent INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'claimed', 'expired', 'cancelled')),
    voucher_code VARCHAR(50),
    expires_at TIMESTAMPTZ,
    redeemed_at TIMESTAMPTZ DEFAULT NOW(),
    claimed_at TIMESTAMPTZ,
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_spa_reward_redemptions_reward_id ON public.spa_reward_redemptions(reward_id);
CREATE INDEX IF NOT EXISTS idx_spa_reward_redemptions_user_id ON public.spa_reward_redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_spa_reward_redemptions_status ON public.spa_reward_redemptions(status);

ALTER TABLE public.spa_reward_redemptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own redemptions" ON public.spa_reward_redemptions
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 12: user_spa_balances - User SPA Points
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_spa_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    total_earned INTEGER DEFAULT 0,
    total_spent INTEGER DEFAULT 0,
    current_balance INTEGER DEFAULT 0,
    last_earned_at TIMESTAMPTZ,
    last_spent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, club_id)
);

CREATE INDEX IF NOT EXISTS idx_user_spa_balances_user_id ON public.user_spa_balances(user_id);
CREATE INDEX IF NOT EXISTS idx_user_spa_balances_club_id ON public.user_spa_balances(club_id);

ALTER TABLE public.user_spa_balances ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own balances" ON public.user_spa_balances
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Club admins can view balances" ON public.user_spa_balances
    FOR SELECT USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================================
-- TABLE 13: club_spa_balances - Club SPA Pool
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.club_spa_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    total_spa_allocated INTEGER DEFAULT 0,
    spent_spa INTEGER DEFAULT 0,
    available_spa INTEGER DEFAULT 0,
    reserved_spa INTEGER DEFAULT 0,
    last_allocation_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(club_id)
);

CREATE INDEX IF NOT EXISTS idx_club_spa_balances_club_id ON public.club_spa_balances(club_id);

ALTER TABLE public.club_spa_balances ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Club admins can manage spa balances" ON public.club_spa_balances
    FOR ALL USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================================
-- TABLE 14: tournament_templates - Reusable Tournament Templates
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.tournament_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    template_name VARCHAR(200) NOT NULL,
    description TEXT,
    tournament_format VARCHAR(50) NOT NULL,
    game_type VARCHAR(50),
    max_participants INTEGER,
    entry_fee DECIMAL(10,2),
    prize_pool_structure JSONB,
    rules JSONB,
    settings JSONB,
    is_public BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tournament_templates_club_id ON public.tournament_templates(club_id);
CREATE INDEX IF NOT EXISTS idx_tournament_templates_created_by ON public.tournament_templates(created_by);
CREATE INDEX IF NOT EXISTS idx_tournament_templates_is_public ON public.tournament_templates(is_public);

ALTER TABLE public.tournament_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view public templates" ON public.tournament_templates
    FOR SELECT USING (is_public = true);

CREATE POLICY "Club admins can manage templates" ON public.tournament_templates
    FOR ALL USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================================
-- TABLE 15: tournament_formats - Tournament Format Definitions
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.tournament_formats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    format_name VARCHAR(100) NOT NULL,
    format_type VARCHAR(50) NOT NULL CHECK (format_type IN ('single_elimination', 'double_elimination', 'round_robin', 'swiss', 'custom')),
    description TEXT,
    min_participants INTEGER,
    max_participants INTEGER,
    rules JSONB,
    settings JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(format_name)
);

CREATE INDEX IF NOT EXISTS idx_tournament_formats_format_type ON public.tournament_formats(format_type);
CREATE INDEX IF NOT EXISTS idx_tournament_formats_is_active ON public.tournament_formats(is_active);

ALTER TABLE public.tournament_formats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active formats" ON public.tournament_formats
    FOR SELECT USING (is_active = true);

-- ============================================================================
-- TABLE 16: device_tokens - FCM Device Tokens for Push Notifications
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    device_id VARCHAR(255),
    device_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON public.device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_token ON public.device_tokens(token);
CREATE INDEX IF NOT EXISTS idx_device_tokens_is_active ON public.device_tokens(is_active);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own device tokens" ON public.device_tokens
    FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- PHASE 2 MIGRATION COMPLETE
-- ============================================================================
-- Created 12 high priority tables:
-- 5. club_payments
-- 6. club_payment_config
-- 7. club_payment_settings
-- 8. club_promotions
-- 9. promotion_redemptions
-- 10. spa_rewards
-- 11. spa_reward_redemptions
-- 12. user_spa_balances
-- 13. club_spa_balances
-- 14. tournament_templates
-- 15. tournament_formats
-- 16. device_tokens
--
-- Impact: Club features, SPA rewards, tournament templates, push notifications
-- ============================================================================
