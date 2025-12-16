-- =====================================================
-- LOYALTY PROGRAM SYSTEM - COMPLETE BACKEND
-- Hệ thống tích điểm & đổi thưởng cho CLB
-- =====================================================

-- ============================================================
-- TABLE 1: loyalty_programs - Cấu hình chương trình Loyalty
-- ============================================================

CREATE TABLE IF NOT EXISTS public.loyalty_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Program info
    program_name VARCHAR(200) NOT NULL DEFAULT 'Chương trình Khách hàng Thân thiết',
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    
    -- Points earning rules
    points_per_game INTEGER DEFAULT 10,
    points_per_vnd DECIMAL(10,2) DEFAULT 0.001, -- 1 point per 1,000 VND
    points_per_hour DECIMAL(10,2) DEFAULT 5.0,
    bonus_birthday_multiplier DECIMAL(3,2) DEFAULT 2.0, -- x2 điểm sinh nhật
    bonus_weekend_multiplier DECIMAL(3,2) DEFAULT 1.5, -- x1.5 cuối tuần
    
    -- Tier system configuration
    tier_system JSONB DEFAULT '{
        "bronze": {"min_points": 0, "max_points": 499, "discount": 5, "priority_booking": false},
        "silver": {"min_points": 500, "max_points": 1499, "discount": 10, "priority_booking": true},
        "gold": {"min_points": 1500, "max_points": 4999, "discount": 15, "priority_booking": true},
        "platinum": {"min_points": 5000, "max_points": null, "discount": 20, "priority_booking": true}
    }'::jsonb,
    
    -- Point expiry
    points_expire_months INTEGER DEFAULT 12, -- Điểm hết hạn sau 12 tháng
    enable_point_expiry BOOLEAN DEFAULT false,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    
    UNIQUE(club_id)
);

COMMENT ON TABLE public.loyalty_programs IS 'Cấu hình chương trình loyalty cho từng CLB';

-- ============================================================
-- TABLE 2: user_loyalty_points - Điểm tích lũy của User
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_loyalty_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    program_id UUID NOT NULL REFERENCES public.loyalty_programs(id) ON DELETE CASCADE,
    
    -- Points balance
    total_points_earned INTEGER DEFAULT 0,
    points_redeemed INTEGER DEFAULT 0,
    points_expired INTEGER DEFAULT 0,
    current_balance INTEGER DEFAULT 0,
    
    -- Tier information
    current_tier VARCHAR(50) DEFAULT 'bronze' CHECK (current_tier IN ('bronze', 'silver', 'gold', 'platinum')),
    tier_achieved_at TIMESTAMPTZ,
    next_tier VARCHAR(50),
    points_to_next_tier INTEGER,
    
    -- Tier benefits (cached from program config)
    tier_discount_percentage INTEGER DEFAULT 5,
    tier_priority_booking BOOLEAN DEFAULT false,
    tier_benefits JSONB DEFAULT '{}'::jsonb,
    
    -- Activity tracking
    total_transactions INTEGER DEFAULT 0,
    total_redemptions INTEGER DEFAULT 0,
    last_earned_at TIMESTAMPTZ,
    last_redeemed_at TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, club_id)
);

CREATE INDEX idx_user_loyalty_points_user_id ON public.user_loyalty_points(user_id);
CREATE INDEX idx_user_loyalty_points_club_id ON public.user_loyalty_points(club_id);
CREATE INDEX idx_user_loyalty_points_tier ON public.user_loyalty_points(current_tier);
CREATE INDEX idx_user_loyalty_points_balance ON public.user_loyalty_points(current_balance DESC);

COMMENT ON TABLE public.user_loyalty_points IS 'Điểm tích lũy và tier của user theo từng CLB';

-- ============================================================
-- TABLE 3: loyalty_transactions - Lịch sử giao dịch điểm
-- ============================================================

CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    program_id UUID NOT NULL REFERENCES public.loyalty_programs(id) ON DELETE CASCADE,
    
    -- Transaction details
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN (
        'earn_game', 'earn_purchase', 'earn_bonus', 'earn_birthday', 
        'redeem_reward', 'adjustment', 'expired', 'refund'
    )),
    points_amount INTEGER NOT NULL,
    balance_before INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    
    -- Multipliers applied
    base_points INTEGER,
    multiplier DECIMAL(3,2) DEFAULT 1.0,
    
    -- Reference to source
    reference_type VARCHAR(50), -- 'match', 'booking', 'purchase', 'reward', etc.
    reference_id UUID,
    
    -- Description
    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Expiry tracking (for earned points)
    expires_at TIMESTAMPTZ,
    is_expired BOOLEAN DEFAULT false,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

CREATE INDEX idx_loyalty_transactions_user_id ON public.loyalty_transactions(user_id);
CREATE INDEX idx_loyalty_transactions_club_id ON public.loyalty_transactions(club_id);
CREATE INDEX idx_loyalty_transactions_type ON public.loyalty_transactions(transaction_type);
CREATE INDEX idx_loyalty_transactions_created ON public.loyalty_transactions(created_at DESC);
CREATE INDEX idx_loyalty_transactions_expires ON public.loyalty_transactions(expires_at) WHERE expires_at IS NOT NULL;

COMMENT ON TABLE public.loyalty_transactions IS 'Lịch sử tất cả giao dịch điểm loyalty';

-- ============================================================
-- TABLE 4: loyalty_rewards - Phần thưởng đổi điểm
-- ============================================================

CREATE TABLE IF NOT EXISTS public.loyalty_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Reward info
    reward_name VARCHAR(200) NOT NULL,
    reward_description TEXT,
    reward_image_url TEXT,
    
    -- Reward type
    reward_type VARCHAR(50) NOT NULL CHECK (reward_type IN (
        'discount_voucher', 'free_game', 'free_hour', 
        'merchandise', 'food_drink', 'upgrade', 'special_event'
    )),
    
    -- Points cost
    points_cost INTEGER NOT NULL CHECK (points_cost > 0),
    
    -- Reward value/details
    reward_value JSONB NOT NULL DEFAULT '{}'::jsonb,
    -- Example: {"discount_percent": 20, "max_amount": 100000}
    -- Example: {"free_hours": 2, "table_type": "premium"}
    -- Example: {"item_name": "Cue stick", "quantity": 1}
    
    -- Availability
    quantity_total INTEGER, -- NULL = unlimited
    quantity_remaining INTEGER,
    quantity_redeemed INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    
    -- Eligibility
    tier_required VARCHAR(50) CHECK (tier_required IN ('bronze', 'silver', 'gold', 'platinum')),
    min_tier_required VARCHAR(50) DEFAULT 'bronze',
    
    -- Validity
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    
    -- Display
    display_order INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    tags VARCHAR(50)[],
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

CREATE INDEX idx_loyalty_rewards_club_id ON public.loyalty_rewards(club_id);
CREATE INDEX idx_loyalty_rewards_active ON public.loyalty_rewards(is_active) WHERE is_active = true;
CREATE INDEX idx_loyalty_rewards_tier ON public.loyalty_rewards(tier_required);
CREATE INDEX idx_loyalty_rewards_cost ON public.loyalty_rewards(points_cost);

COMMENT ON TABLE public.loyalty_rewards IS 'Catalog phần thưởng có thể đổi bằng điểm loyalty';

-- ============================================================
-- TABLE 5: loyalty_reward_redemptions - Lịch sử đổi thưởng
-- ============================================================

CREATE TABLE IF NOT EXISTS public.loyalty_reward_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reward_id UUID NOT NULL REFERENCES public.loyalty_rewards(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Redemption details
    points_spent INTEGER NOT NULL,
    user_tier_at_redemption VARCHAR(50),
    
    -- Redemption status
    redemption_status VARCHAR(50) DEFAULT 'pending' CHECK (redemption_status IN (
        'pending', 'approved', 'ready_to_collect', 
        'fulfilled', 'cancelled', 'expired'
    )),
    
    -- Redemption code (for verification)
    redemption_code VARCHAR(100) UNIQUE,
    
    -- Fulfillment tracking
    notes TEXT,
    admin_notes TEXT,
    redeemed_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    fulfilled_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    
    -- Fulfilled by
    approved_by UUID REFERENCES auth.users(id),
    fulfilled_by UUID REFERENCES auth.users(id),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_loyalty_redemptions_user_id ON public.loyalty_reward_redemptions(user_id);
CREATE INDEX idx_loyalty_redemptions_club_id ON public.loyalty_reward_redemptions(club_id);
CREATE INDEX idx_loyalty_redemptions_reward_id ON public.loyalty_reward_redemptions(reward_id);
CREATE INDEX idx_loyalty_redemptions_status ON public.loyalty_reward_redemptions(redemption_status);
CREATE INDEX idx_loyalty_redemptions_code ON public.loyalty_reward_redemptions(redemption_code);

COMMENT ON TABLE public.loyalty_reward_redemptions IS 'Lịch sử đổi thưởng từ điểm loyalty';

-- ============================================================
-- RLS POLICIES
-- ============================================================

-- Loyalty Programs
ALTER TABLE public.loyalty_programs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active loyalty programs"
    ON public.loyalty_programs FOR SELECT
    USING (is_active = true);

CREATE POLICY "Club owners can manage their loyalty program"
    ON public.loyalty_programs FOR ALL
    USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- User Loyalty Points
ALTER TABLE public.user_loyalty_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own loyalty points"
    ON public.user_loyalty_points FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Club owners can view member loyalty points"
    ON public.user_loyalty_points FOR SELECT
    USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- Loyalty Transactions
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own transactions"
    ON public.loyalty_transactions FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Club owners can view member transactions"
    ON public.loyalty_transactions FOR SELECT
    USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- Loyalty Rewards
ALTER TABLE public.loyalty_rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active rewards"
    ON public.loyalty_rewards FOR SELECT
    USING (is_active = true AND (valid_until IS NULL OR valid_until > NOW()));

CREATE POLICY "Club owners can manage rewards"
    ON public.loyalty_rewards FOR ALL
    USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- Loyalty Redemptions
ALTER TABLE public.loyalty_reward_redemptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own redemptions"
    ON public.loyalty_reward_redemptions FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can create redemptions"
    ON public.loyalty_reward_redemptions FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Club owners can manage redemptions"
    ON public.loyalty_reward_redemptions FOR ALL
    USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_loyalty_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_loyalty_programs_updated_at
    BEFORE UPDATE ON public.loyalty_programs
    FOR EACH ROW EXECUTE FUNCTION update_loyalty_updated_at();

CREATE TRIGGER update_user_loyalty_points_updated_at
    BEFORE UPDATE ON public.user_loyalty_points
    FOR EACH ROW EXECUTE FUNCTION update_loyalty_updated_at();

CREATE TRIGGER update_loyalty_rewards_updated_at
    BEFORE UPDATE ON public.loyalty_rewards
    FOR EACH ROW EXECUTE FUNCTION update_loyalty_updated_at();

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Function 1: Initialize or get user loyalty account
CREATE OR REPLACE FUNCTION get_or_create_user_loyalty(
    p_user_id UUID,
    p_club_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_loyalty_id UUID;
    v_program_id UUID;
BEGIN
    -- Get active program for club
    SELECT id INTO v_program_id
    FROM public.loyalty_programs
    WHERE club_id = p_club_id AND is_active = true
    LIMIT 1;
    
    IF v_program_id IS NULL THEN
        RAISE EXCEPTION 'No active loyalty program found for this club';
    END IF;
    
    -- Get or create user loyalty account
    INSERT INTO public.user_loyalty_points (
        user_id, club_id, program_id
    ) VALUES (
        p_user_id, p_club_id, v_program_id
    )
    ON CONFLICT (user_id, club_id) DO UPDATE
        SET program_id = v_program_id
    RETURNING id INTO v_loyalty_id;
    
    RETURN v_loyalty_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 2: Award loyalty points
CREATE OR REPLACE FUNCTION award_loyalty_points(
    p_user_id UUID,
    p_club_id UUID,
    p_points INTEGER,
    p_transaction_type VARCHAR,
    p_reference_type VARCHAR DEFAULT NULL,
    p_reference_id UUID DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_multiplier DECIMAL DEFAULT 1.0
)
RETURNS JSONB AS $$
DECLARE
    v_loyalty_account RECORD;
    v_program RECORD;
    v_transaction_id UUID;
    v_new_balance INTEGER;
    v_new_tier VARCHAR(50);
    v_tier_upgraded BOOLEAN := false;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- Get loyalty account
    SELECT * INTO v_loyalty_account
    FROM public.user_loyalty_points
    WHERE user_id = p_user_id AND club_id = p_club_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User loyalty account not found';
    END IF;
    
    -- Get program config
    SELECT * INTO v_program
    FROM public.loyalty_programs
    WHERE id = v_loyalty_account.program_id;
    
    -- Calculate expiry
    IF v_program.enable_point_expiry THEN
        v_expires_at := NOW() + (v_program.points_expire_months || ' months')::INTERVAL;
    END IF;
    
    -- Calculate new balance
    v_new_balance := v_loyalty_account.current_balance + p_points;
    
    -- Create transaction
    INSERT INTO public.loyalty_transactions (
        user_id, club_id, program_id, transaction_type,
        points_amount, balance_before, balance_after,
        base_points, multiplier, reference_type, reference_id,
        description, expires_at
    ) VALUES (
        p_user_id, p_club_id, v_loyalty_account.program_id, p_transaction_type,
        p_points, v_loyalty_account.current_balance, v_new_balance,
        FLOOR(p_points / p_multiplier), p_multiplier, p_reference_type, p_reference_id,
        p_description, v_expires_at
    ) RETURNING id INTO v_transaction_id;
    
    -- Update user loyalty account
    UPDATE public.user_loyalty_points
    SET 
        total_points_earned = total_points_earned + p_points,
        current_balance = v_new_balance,
        total_transactions = total_transactions + 1,
        last_earned_at = NOW(),
        updated_at = NOW()
    WHERE id = v_loyalty_account.id;
    
    -- Check tier upgrade
    v_new_tier := calculate_user_tier(v_new_balance, v_program.tier_system);
    
    IF v_new_tier != v_loyalty_account.current_tier THEN
        v_tier_upgraded := true;
        
        UPDATE public.user_loyalty_points
        SET 
            current_tier = v_new_tier,
            tier_achieved_at = NOW()
        WHERE id = v_loyalty_account.id;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'points_awarded', p_points,
        'new_balance', v_new_balance,
        'old_tier', v_loyalty_account.current_tier,
        'new_tier', v_new_tier,
        'tier_upgraded', v_tier_upgraded
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function: Calculate tier based on points
CREATE OR REPLACE FUNCTION calculate_user_tier(
    p_points INTEGER,
    p_tier_system JSONB
)
RETURNS VARCHAR AS $$
DECLARE
    v_tier_name VARCHAR;
    v_tier_config JSONB;
BEGIN
    -- Check platinum
    v_tier_config := p_tier_system->'platinum';
    IF p_points >= (v_tier_config->>'min_points')::INTEGER THEN
        RETURN 'platinum';
    END IF;
    
    -- Check gold
    v_tier_config := p_tier_system->'gold';
    IF p_points >= (v_tier_config->>'min_points')::INTEGER THEN
        RETURN 'gold';
    END IF;
    
    -- Check silver
    v_tier_config := p_tier_system->'silver';
    IF p_points >= (v_tier_config->>'min_points')::INTEGER THEN
        RETURN 'silver';
    END IF;
    
    -- Default bronze
    RETURN 'bronze';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function 3: Redeem loyalty reward
CREATE OR REPLACE FUNCTION redeem_loyalty_reward(
    p_user_id UUID,
    p_reward_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_reward RECORD;
    v_loyalty RECORD;
    v_redemption_id UUID;
    v_redemption_code VARCHAR;
    v_new_balance INTEGER;
BEGIN
    -- Get reward
    SELECT * INTO v_reward
    FROM public.loyalty_rewards
    WHERE id = p_reward_id AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Reward not found or inactive');
    END IF;
    
    -- Check validity
    IF v_reward.valid_until IS NOT NULL AND v_reward.valid_until < NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Reward has expired');
    END IF;
    
    -- Check quantity
    IF v_reward.quantity_remaining IS NOT NULL AND v_reward.quantity_remaining <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Reward out of stock');
    END IF;
    
    -- Get user loyalty account
    SELECT * INTO v_loyalty
    FROM public.user_loyalty_points
    WHERE user_id = p_user_id AND club_id = v_reward.club_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'User loyalty account not found');
    END IF;
    
    -- Check balance
    IF v_loyalty.current_balance < v_reward.points_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient points');
    END IF;
    
    -- Check tier requirement
    IF v_reward.tier_required IS NOT NULL THEN
        IF NOT is_tier_eligible(v_loyalty.current_tier, v_reward.tier_required) THEN
            RETURN jsonb_build_object('success', false, 'error', 'Tier requirement not met');
        END IF;
    END IF;
    
    -- Generate redemption code
    v_redemption_code := 'LYL-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
    
    -- Calculate new balance
    v_new_balance := v_loyalty.current_balance - v_reward.points_cost;
    
    -- Create redemption record
    INSERT INTO public.loyalty_reward_redemptions (
        reward_id, user_id, club_id, points_spent,
        user_tier_at_redemption, redemption_code
    ) VALUES (
        p_reward_id, p_user_id, v_reward.club_id, v_reward.points_cost,
        v_loyalty.current_tier, v_redemption_code
    ) RETURNING id INTO v_redemption_id;
    
    -- Create loyalty transaction (deduction)
    INSERT INTO public.loyalty_transactions (
        user_id, club_id, program_id, transaction_type,
        points_amount, balance_before, balance_after,
        reference_type, reference_id, description
    ) VALUES (
        p_user_id, v_reward.club_id, v_loyalty.program_id, 'redeem_reward',
        -v_reward.points_cost, v_loyalty.current_balance, v_new_balance,
        'reward_redemption', v_redemption_id, 'Đổi thưởng: ' || v_reward.reward_name
    );
    
    -- Update user loyalty points
    UPDATE public.user_loyalty_points
    SET 
        points_redeemed = points_redeemed + v_reward.points_cost,
        current_balance = v_new_balance,
        total_redemptions = total_redemptions + 1,
        last_redeemed_at = NOW(),
        updated_at = NOW()
    WHERE id = v_loyalty.id;
    
    -- Update reward quantity
    IF v_reward.quantity_remaining IS NOT NULL THEN
        UPDATE public.loyalty_rewards
        SET 
            quantity_remaining = quantity_remaining - 1,
            quantity_redeemed = quantity_redeemed + 1
        WHERE id = p_reward_id;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'redemption_id', v_redemption_id,
        'redemption_code', v_redemption_code,
        'points_spent', v_reward.points_cost,
        'new_balance', v_new_balance,
        'reward_name', v_reward.reward_name
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper: Check tier eligibility
CREATE OR REPLACE FUNCTION is_tier_eligible(
    p_user_tier VARCHAR,
    p_required_tier VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    v_tier_order INTEGER;
    v_required_order INTEGER;
BEGIN
    -- Tier hierarchy: bronze < silver < gold < platinum
    v_tier_order := CASE p_user_tier
        WHEN 'bronze' THEN 1
        WHEN 'silver' THEN 2
        WHEN 'gold' THEN 3
        WHEN 'platinum' THEN 4
        ELSE 0
    END;
    
    v_required_order := CASE p_required_tier
        WHEN 'bronze' THEN 1
        WHEN 'silver' THEN 2
        WHEN 'gold' THEN 3
        WHEN 'platinum' THEN 4
        ELSE 0
    END;
    
    RETURN v_tier_order >= v_required_order;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function 4: Get loyalty statistics
CREATE OR REPLACE FUNCTION get_loyalty_stats(
    p_club_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_members', COUNT(DISTINCT ulp.user_id),
        'total_points_issued', COALESCE(SUM(ulp.total_points_earned), 0),
        'total_points_redeemed', COALESCE(SUM(ulp.points_redeemed), 0),
        'active_balance', COALESCE(SUM(ulp.current_balance), 0),
        'tier_distribution', jsonb_build_object(
            'bronze', COUNT(*) FILTER (WHERE ulp.current_tier = 'bronze'),
            'silver', COUNT(*) FILTER (WHERE ulp.current_tier = 'silver'),
            'gold', COUNT(*) FILTER (WHERE ulp.current_tier = 'gold'),
            'platinum', COUNT(*) FILTER (WHERE ulp.current_tier = 'platinum')
        ),
        'total_redemptions', (
            SELECT COUNT(*) FROM public.loyalty_reward_redemptions WHERE club_id = p_club_id
        ),
        'pending_redemptions', (
            SELECT COUNT(*) FROM public.loyalty_reward_redemptions 
            WHERE club_id = p_club_id AND redemption_status = 'pending'
        )
    ) INTO v_stats
    FROM public.user_loyalty_points ulp
    WHERE ulp.club_id = p_club_id;
    
    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 5: Expire old loyalty points
CREATE OR REPLACE FUNCTION expire_loyalty_points()
RETURNS INTEGER AS $$
DECLARE
    v_expired_count INTEGER := 0;
    v_transaction RECORD;
BEGIN
    -- Find and expire transactions
    FOR v_transaction IN
        SELECT * FROM public.loyalty_transactions
        WHERE expires_at IS NOT NULL 
          AND expires_at < NOW()
          AND is_expired = false
          AND transaction_type LIKE 'earn_%'
    LOOP
        -- Create expiry transaction
        INSERT INTO public.loyalty_transactions (
            user_id, club_id, program_id, transaction_type,
            points_amount, balance_before, balance_after,
            reference_type, reference_id, description
        )
        SELECT 
            user_id, club_id, program_id, 'expired',
            -points_amount,
            (SELECT current_balance FROM public.user_loyalty_points 
             WHERE user_id = v_transaction.user_id AND club_id = v_transaction.club_id),
            (SELECT current_balance FROM public.user_loyalty_points 
             WHERE user_id = v_transaction.user_id AND club_id = v_transaction.club_id) - points_amount,
            'expired_transaction', v_transaction.id,
            'Điểm hết hạn từ giao dịch ' || v_transaction.id;
        
        -- Update user balance
        UPDATE public.user_loyalty_points
        SET 
            points_expired = points_expired + v_transaction.points_amount,
            current_balance = current_balance - v_transaction.points_amount
        WHERE user_id = v_transaction.user_id 
          AND club_id = v_transaction.club_id;
        
        -- Mark as expired
        UPDATE public.loyalty_transactions
        SET is_expired = true
        WHERE id = v_transaction.id;
        
        v_expired_count := v_expired_count + 1;
    END LOOP;
    
    RETURN v_expired_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- SEED DATA - Default Loyalty Program
-- ============================================================

-- Create default program for existing clubs (optional)
DO $$
DECLARE
    v_club RECORD;
    v_program_id UUID;
BEGIN
    FOR v_club IN SELECT id FROM public.clubs LIMIT 5
    LOOP
        INSERT INTO public.loyalty_programs (
            club_id, program_name, description, is_active
        ) VALUES (
            v_club.id,
            'Chương trình Khách hàng Thân thiết',
            'Tích điểm mỗi lần chơi, đổi quà hấp dẫn!',
            true
        )
        ON CONFLICT (club_id) DO NOTHING
        RETURNING id INTO v_program_id;
        
        -- Create sample rewards if program created
        IF v_program_id IS NOT NULL THEN
            INSERT INTO public.loyalty_rewards (club_id, reward_name, reward_type, points_cost, reward_value) VALUES
            (v_club.id, 'Giảm giá 10%', 'discount_voucher', 100, '{"discount_percent": 10, "max_amount": 50000}'::jsonb),
            (v_club.id, 'Giảm giá 20%', 'discount_voucher', 200, '{"discount_percent": 20, "max_amount": 100000}'::jsonb),
            (v_club.id, 'Miễn phí 1 giờ chơi', 'free_hour', 500, '{"hours": 1}'::jsonb),
            (v_club.id, 'Miễn phí 2 giờ chơi', 'free_hour', 900, '{"hours": 2}'::jsonb);
        END IF;
    END LOOP;
END $$;

COMMENT ON FUNCTION award_loyalty_points IS 'Award loyalty points to user with multiplier support';
COMMENT ON FUNCTION redeem_loyalty_reward IS 'Redeem a loyalty reward for points';
COMMENT ON FUNCTION get_loyalty_stats IS 'Get loyalty program statistics for club';
COMMENT ON FUNCTION expire_loyalty_points IS 'Expire old loyalty points based on program config';
