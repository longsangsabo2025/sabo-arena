-- =====================================================
-- MISSING TABLES MIGRATION
-- Auto-generated from schema consistency check
-- =====================================================

-- =====================================================
-- Table: chat_participants
-- =====================================================

CREATE TABLE IF NOT EXISTS chat_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_chat_participants_user_id ON chat_participants(user_id);
CREATE INDEX idx_chat_participants_room_id ON chat_participants(room_id);

-- =====================================================
-- Table: chat_room_settings
-- =====================================================

CREATE TABLE IF NOT EXISTS chat_room_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_chat_room_settings_user_id ON chat_room_settings(user_id);
CREATE INDEX idx_chat_room_settings_room_id ON chat_room_settings(room_id);

-- =====================================================
-- Table: club_activity_logs
-- =====================================================

CREATE TABLE IF NOT EXISTS club_activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: Add proper columns and indexes based on requirements

-- =====================================================
-- Table: club_payment_config
-- =====================================================

CREATE TABLE IF NOT EXISTS club_payment_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_method TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_club_payment_config_user_id ON club_payment_config(user_id);
CREATE INDEX idx_club_payment_config_club_id ON club_payment_config(club_id);
CREATE INDEX idx_club_payment_config_status ON club_payment_config(status);
CREATE INDEX idx_club_payment_config_created_at ON club_payment_config(created_at);

-- =====================================================
-- Table: club_payment_settings
-- =====================================================

CREATE TABLE IF NOT EXISTS club_payment_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_method TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_club_payment_settings_user_id ON club_payment_settings(user_id);
CREATE INDEX idx_club_payment_settings_club_id ON club_payment_settings(club_id);
CREATE INDEX idx_club_payment_settings_status ON club_payment_settings(status);
CREATE INDEX idx_club_payment_settings_created_at ON club_payment_settings(created_at);

-- =====================================================
-- Table: club_payments
-- =====================================================

CREATE TABLE IF NOT EXISTS club_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_method TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_club_payments_user_id ON club_payments(user_id);
CREATE INDEX idx_club_payments_club_id ON club_payments(club_id);
CREATE INDEX idx_club_payments_status ON club_payments(status);
CREATE INDEX idx_club_payments_created_at ON club_payments(created_at);

-- =====================================================
-- Table: club_promotions
-- =====================================================

CREATE TABLE IF NOT EXISTS club_promotions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_club_promotions_club_id ON club_promotions(club_id);
CREATE INDEX idx_club_promotions_status ON club_promotions(status);

-- =====================================================
-- Table: club_spa_balance
-- =====================================================

CREATE TABLE IF NOT EXISTS club_spa_balance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount INTEGER DEFAULT 0,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_club_spa_balance_user_id ON club_spa_balance(user_id);
CREATE INDEX idx_club_spa_balance_club_id ON club_spa_balance(club_id);

-- =====================================================
-- Table: club_spa_balances
-- =====================================================

CREATE TABLE IF NOT EXISTS club_spa_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount INTEGER DEFAULT 0,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_club_spa_balances_user_id ON club_spa_balances(user_id);
CREATE INDEX idx_club_spa_balances_club_id ON club_spa_balances(club_id);

-- =====================================================
-- Table: device_tokens
-- =====================================================

CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: Add proper columns and indexes based on requirements

-- =====================================================
-- Table: elo_history
-- =====================================================

CREATE TABLE IF NOT EXISTS elo_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: Add proper columns and indexes based on requirements

-- =====================================================
-- Table: game_formats
-- =====================================================

CREATE TABLE IF NOT EXISTS game_formats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: Add proper columns and indexes based on requirements

-- =====================================================
-- Table: invoices
-- =====================================================

CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: Add proper columns and indexes based on requirements

-- =====================================================
-- Table: notification_analytics
-- =====================================================

CREATE TABLE IF NOT EXISTS notification_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: Add proper columns and indexes based on requirements

-- =====================================================
-- Table: payment_methods
-- =====================================================

CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_method TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id);
CREATE INDEX idx_payment_methods_club_id ON payment_methods(club_id);
CREATE INDEX idx_payment_methods_status ON payment_methods(status);
CREATE INDEX idx_payment_methods_created_at ON payment_methods(created_at);

-- =====================================================
-- Table: payment_transactions
-- =====================================================

CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_method TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_payment_transactions_user_id ON payment_transactions(user_id);
CREATE INDEX idx_payment_transactions_club_id ON payment_transactions(club_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX idx_payment_transactions_created_at ON payment_transactions(created_at);

-- =====================================================
-- Table: payments
-- =====================================================

CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_method TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_club_id ON payments(club_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_created_at ON payments(created_at);

-- =====================================================
-- Table: platform_settings
-- =====================================================

CREATE TABLE IF NOT EXISTS platform_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: Add proper columns and indexes based on requirements

-- =====================================================
-- Table: prize_pool_configurations
-- =====================================================

CREATE TABLE IF NOT EXISTS prize_pool_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: Add proper columns and indexes based on requirements

-- =====================================================
-- Table: promotion_redemptions
-- =====================================================

CREATE TABLE IF NOT EXISTS promotion_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_promotion_redemptions_club_id ON promotion_redemptions(club_id);
CREATE INDEX idx_promotion_redemptions_status ON promotion_redemptions(status);

-- =====================================================
-- Table: ranking_definitions
-- =====================================================

CREATE TABLE IF NOT EXISTS ranking_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: Add proper columns and indexes based on requirements

-- =====================================================
-- Table: spa_reward_redemptions
-- =====================================================

CREATE TABLE IF NOT EXISTS spa_reward_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount INTEGER DEFAULT 0,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_spa_reward_redemptions_user_id ON spa_reward_redemptions(user_id);
CREATE INDEX idx_spa_reward_redemptions_club_id ON spa_reward_redemptions(club_id);

-- =====================================================
-- Table: spa_rewards
-- =====================================================

CREATE TABLE IF NOT EXISTS spa_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount INTEGER DEFAULT 0,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_spa_rewards_user_id ON spa_rewards(user_id);
CREATE INDEX idx_spa_rewards_club_id ON spa_rewards(club_id);

-- =====================================================
-- Table: tournament_elo_logs
-- =====================================================

CREATE TABLE IF NOT EXISTS tournament_elo_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_tournament_elo_logs_tournament_id ON tournament_elo_logs(tournament_id);

-- =====================================================
-- Table: tournament_formats
-- =====================================================

CREATE TABLE IF NOT EXISTS tournament_formats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_tournament_formats_tournament_id ON tournament_formats(tournament_id);

-- =====================================================
-- Table: tournament_payments
-- =====================================================

CREATE TABLE IF NOT EXISTS tournament_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_method TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_tournament_payments_user_id ON tournament_payments(user_id);
CREATE INDEX idx_tournament_payments_club_id ON tournament_payments(club_id);
CREATE INDEX idx_tournament_payments_status ON tournament_payments(status);
CREATE INDEX idx_tournament_payments_created_at ON tournament_payments(created_at);

-- =====================================================
-- Table: tournament_templates
-- =====================================================

CREATE TABLE IF NOT EXISTS tournament_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_tournament_templates_tournament_id ON tournament_templates(tournament_id);

-- =====================================================
-- Table: transactions
-- =====================================================

CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_method TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_club_id ON transactions(club_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);

-- =====================================================
-- Table: typing_indicators
-- =====================================================

CREATE TABLE IF NOT EXISTS typing_indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: Add proper columns and indexes based on requirements

-- =====================================================
-- Table: user_journey_events
-- =====================================================

CREATE TABLE IF NOT EXISTS user_journey_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: Add proper columns and indexes based on requirements

-- =====================================================
-- Table: user_spa_balances
-- =====================================================

CREATE TABLE IF NOT EXISTS user_spa_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    amount INTEGER DEFAULT 0,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_user_spa_balances_user_id ON user_spa_balances(user_id);
CREATE INDEX idx_user_spa_balances_club_id ON user_spa_balances(club_id);

