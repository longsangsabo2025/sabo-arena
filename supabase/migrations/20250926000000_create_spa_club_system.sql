-- =====================================================
-- SPA Club Management System Migration
-- Purpose: Create tables for SPA bonus system managed by clubs
-- =====================================================

-- 1. Club SPA Balance Table
CREATE TABLE IF NOT EXISTS club_spa_balance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    total_spa_allocated DECIMAL(12,2) DEFAULT 0.00, -- Total SPA allocated by admin
    available_spa DECIMAL(12,2) DEFAULT 0.00, -- Available SPA for rewards
    spent_spa DECIMAL(12,2) DEFAULT 0.00, -- SPA spent on rewards
    reserved_spa DECIMAL(12,2) DEFAULT 0.00, -- SPA reserved for ongoing challenges
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(club_id)
);

-- 2. SPA Rewards Table (rewards that club owners can setup)
CREATE TABLE IF NOT EXISTS spa_rewards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    reward_name VARCHAR(200) NOT NULL,
    reward_description TEXT,
    reward_type VARCHAR(50) NOT NULL CHECK (reward_type IN ('discount_code', 'physical_item', 'service', 'merchandise', 'other')),
    spa_cost DECIMAL(10,2) NOT NULL CHECK (spa_cost > 0),
    reward_value VARCHAR(500), -- JSON or string describing the actual reward
    quantity_available INTEGER DEFAULT NULL, -- NULL for unlimited
    quantity_claimed INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ DEFAULT NULL,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. SPA Transactions Table (track all SPA movements)
CREATE TABLE IF NOT EXISTS spa_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN (
        'admin_allocation', 'challenge_bonus', 'reward_redemption', 'bonus_adjustment', 'refund'
    )),
    spa_amount DECIMAL(10,2) NOT NULL,
    balance_before DECIMAL(10,2) NOT NULL,
    balance_after DECIMAL(10,2) NOT NULL,
    reference_id UUID, -- Reference to match_id, reward_id, etc.
    reference_type VARCHAR(50), -- 'match', 'reward', 'adjustment'
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- 4. User SPA Balances Table
CREATE TABLE IF NOT EXISTS user_spa_balances (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    spa_balance DECIMAL(10,2) DEFAULT 0.00,
    total_earned DECIMAL(10,2) DEFAULT 0.00,
    total_spent DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, club_id)
);

-- 5. SPA Reward Redemptions Table  
CREATE TABLE IF NOT EXISTS spa_reward_redemptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reward_id UUID NOT NULL REFERENCES spa_rewards(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    spa_cost DECIMAL(10,2) NOT NULL,
    redemption_status VARCHAR(50) DEFAULT 'pending' CHECK (redemption_status IN ('pending', 'approved', 'delivered', 'cancelled')),
    redemption_code VARCHAR(100), -- Generated code for user to claim
    notes TEXT,
    redeemed_at TIMESTAMPTZ DEFAULT NOW(),
    delivered_at TIMESTAMPTZ DEFAULT NULL,
    delivered_by UUID REFERENCES auth.users(id)
);

-- 6. Create indexes for performance
CREATE INDEX idx_club_spa_balance_club_id ON club_spa_balance(club_id);
CREATE INDEX idx_spa_rewards_club_id_active ON spa_rewards(club_id, is_active);
CREATE INDEX idx_spa_transactions_club_id ON spa_transactions(club_id);
CREATE INDEX idx_spa_transactions_user_id ON spa_transactions(user_id);
CREATE INDEX idx_spa_transactions_created_at ON spa_transactions(created_at);
CREATE INDEX idx_user_spa_balances_user_club ON user_spa_balances(user_id, club_id);
CREATE INDEX idx_spa_reward_redemptions_user_id ON spa_reward_redemptions(user_id);
CREATE INDEX idx_spa_reward_redemptions_club_id ON spa_reward_redemptions(club_id);

-- 7. Enable Row Level Security
ALTER TABLE club_spa_balance ENABLE ROW LEVEL SECURITY;
ALTER TABLE spa_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE spa_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_spa_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE spa_reward_redemptions ENABLE ROW LEVEL SECURITY;

-- 8. Create RLS Policies

-- Club SPA Balance Policies
CREATE POLICY "Club owners can view their club SPA balance" ON club_spa_balance
    FOR SELECT USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() AND role = 'owner'
        )
    );

CREATE POLICY "Admin can view all club SPA balances" ON club_spa_balance
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- SPA Rewards Policies  
CREATE POLICY "Club members can view active rewards" ON spa_rewards
    FOR SELECT USING (
        is_active = true AND club_id IN (
            SELECT club_id FROM club_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Club owners can manage rewards" ON spa_rewards
    FOR ALL USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() AND role = 'owner'
        )
    );

-- User SPA Balances Policies
CREATE POLICY "Users can view their own SPA balances" ON user_spa_balances
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Club owners can view member SPA balances" ON user_spa_balances
    FOR SELECT USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() AND role = 'owner'
        )
    );

-- SPA Transactions Policies
CREATE POLICY "Users can view their own SPA transactions" ON spa_transactions
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Club owners can view club SPA transactions" ON spa_transactions
    FOR SELECT USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() AND role = 'owner'
        )
    );

-- Reward Redemptions Policies
CREATE POLICY "Users can view their own redemptions" ON spa_reward_redemptions
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Club owners can view club redemptions" ON spa_reward_redemptions
    FOR SELECT USING (
        club_id IN (
            SELECT club_id FROM club_members 
            WHERE user_id = auth.uid() AND role = 'owner'
        )
    );

-- 9. Create helpful functions

-- Function to add SPA to club balance (admin only)
CREATE OR REPLACE FUNCTION add_spa_to_club(
    p_club_id UUID,
    p_spa_amount DECIMAL(10,2),
    p_description TEXT DEFAULT 'Admin SPA allocation'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_check BOOLEAN;
    v_balance_before DECIMAL(10,2);
    v_balance_after DECIMAL(10,2);
BEGIN
    -- Check if user is admin
    SELECT EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role = 'admin'
    ) INTO v_admin_check;
    
    IF NOT v_admin_check THEN
        RAISE EXCEPTION 'Only admin can allocate SPA to clubs';
    END IF;
    
    -- Get current balance
    SELECT available_spa INTO v_balance_before
    FROM club_spa_balance WHERE club_id = p_club_id;
    
    IF v_balance_before IS NULL THEN
        -- Create new balance record
        INSERT INTO club_spa_balance (club_id, total_spa_allocated, available_spa)
        VALUES (p_club_id, p_spa_amount, p_spa_amount);
        v_balance_before := 0;
        v_balance_after := p_spa_amount;
    ELSE
        -- Update existing balance
        UPDATE club_spa_balance 
        SET 
            total_spa_allocated = total_spa_allocated + p_spa_amount,
            available_spa = available_spa + p_spa_amount,
            updated_at = NOW()
        WHERE club_id = p_club_id;
        v_balance_after := v_balance_before + p_spa_amount;
    END IF;
    
    -- Record transaction
    INSERT INTO spa_transactions (
        club_id, transaction_type, spa_amount, 
        balance_before, balance_after, description, created_by
    ) VALUES (
        p_club_id, 'admin_allocation', p_spa_amount,
        v_balance_before, v_balance_after, p_description, auth.uid()
    );
    
    RETURN TRUE;
END;
$$;

-- Function to award SPA bonus to user
CREATE OR REPLACE FUNCTION award_spa_bonus(
    p_user_id UUID,
    p_club_id UUID,
    p_spa_amount DECIMAL(10,2),
    p_match_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_club_balance DECIMAL(10,2);
    v_user_balance DECIMAL(10,2);
BEGIN
    -- Check club has enough SPA
    SELECT available_spa INTO v_club_balance
    FROM club_spa_balance WHERE club_id = p_club_id;
    
    IF v_club_balance IS NULL OR v_club_balance < p_spa_amount THEN
        RAISE EXCEPTION 'Club does not have enough SPA balance';
    END IF;
    
    -- Deduct from club balance
    UPDATE club_spa_balance 
    SET 
        available_spa = available_spa - p_spa_amount,
        spent_spa = spent_spa + p_spa_amount,
        updated_at = NOW()
    WHERE club_id = p_club_id;
    
    -- Add to user balance
    INSERT INTO user_spa_balances (user_id, club_id, spa_balance, total_earned)
    VALUES (p_user_id, p_club_id, p_spa_amount, p_spa_amount)
    ON CONFLICT (user_id, club_id) 
    DO UPDATE SET 
        spa_balance = user_spa_balances.spa_balance + p_spa_amount,
        total_earned = user_spa_balances.total_earned + p_spa_amount,
        updated_at = NOW();
    
    -- Get updated user balance for transaction record
    SELECT spa_balance INTO v_user_balance
    FROM user_spa_balances 
    WHERE user_id = p_user_id AND club_id = p_club_id;
    
    -- Record transaction
    INSERT INTO spa_transactions (
        club_id, user_id, transaction_type, spa_amount,
        balance_before, balance_after, reference_id, reference_type,
        description, created_by
    ) VALUES (
        p_club_id, p_user_id, 'challenge_bonus', p_spa_amount,
        COALESCE(v_user_balance - p_spa_amount, 0), v_user_balance,
        p_match_id, 'match', 'SPA bonus from challenge victory', auth.uid()
    );
    
    RETURN TRUE;
END;
$$;

-- Add some default rewards examples
INSERT INTO spa_rewards (club_id, reward_name, reward_description, reward_type, spa_cost, reward_value, created_by)
SELECT 
    c.id,
    'Mã giảm giá 10%',
    'Mã giảm giá 10% cho dịch vụ tại câu lạc bộ',
    'discount_code',
    100.00,
    '{"discount_percent": 10, "max_discount": 50000, "applicable_services": ["table_booking", "equipment_rental"]}',
    NULL
FROM clubs c
WHERE NOT EXISTS (SELECT 1 FROM spa_rewards WHERE club_id = c.id)
LIMIT 5;

COMMENT ON TABLE club_spa_balance IS 'Stores SPA balance for each club allocated by admin';
COMMENT ON TABLE spa_rewards IS 'Rewards that club owners can setup for members to redeem with SPA';
COMMENT ON TABLE spa_transactions IS 'Complete audit trail of all SPA movements';
COMMENT ON TABLE user_spa_balances IS 'Individual user SPA balances per club';
COMMENT ON TABLE spa_reward_redemptions IS 'Track reward redemptions by users';