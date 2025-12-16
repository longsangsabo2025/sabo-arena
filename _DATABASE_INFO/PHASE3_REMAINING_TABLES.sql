-- ============================================================================
-- PHASE 3: REMAINING TABLES - ANALYTICS, CONFIG & MISC
-- ============================================================================
-- Generated: October 23, 2025
-- Purpose: Create remaining 13 tables for complete feature set
-- ============================================================================

-- ============================================================================
-- TABLE 17: chat_room_settings - User Chat Preferences
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.chat_room_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    notifications_enabled BOOLEAN DEFAULT true,
    sound_enabled BOOLEAN DEFAULT true,
    is_muted BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    custom_nickname VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, room_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_room_settings_user_id ON public.chat_room_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_room_settings_room_id ON public.chat_room_settings(room_id);

ALTER TABLE public.chat_room_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own chat settings" ON public.chat_room_settings
    FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 18: club_activity_logs - Club Activity History
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.club_activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    activity_type VARCHAR(50) NOT NULL,
    action VARCHAR(100) NOT NULL,
    description TEXT,
    entity_type VARCHAR(50),
    entity_id UUID,
    metadata JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_club_activity_logs_club_id ON public.club_activity_logs(club_id);
CREATE INDEX IF NOT EXISTS idx_club_activity_logs_user_id ON public.club_activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_club_activity_logs_activity_type ON public.club_activity_logs(activity_type);
CREATE INDEX IF NOT EXISTS idx_club_activity_logs_created_at ON public.club_activity_logs(created_at DESC);

ALTER TABLE public.club_activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Club admins can view activity logs" ON public.club_activity_logs
    FOR SELECT USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================================
-- TABLE 19: elo_history - Historical ELO Data
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.elo_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL,
    old_elo INTEGER NOT NULL,
    new_elo INTEGER NOT NULL,
    elo_change INTEGER NOT NULL,
    reason VARCHAR(100) NOT NULL,
    match_id UUID,
    tournament_id UUID,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_elo_history_user_id ON public.elo_history(user_id);
CREATE INDEX IF NOT EXISTS idx_elo_history_club_id ON public.elo_history(club_id);
CREATE INDEX IF NOT EXISTS idx_elo_history_created_at ON public.elo_history(created_at DESC);

ALTER TABLE public.elo_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own elo history" ON public.elo_history
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 20: tournament_elo_logs - Tournament ELO Changes
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.tournament_elo_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    match_id UUID,
    old_elo INTEGER NOT NULL,
    new_elo INTEGER NOT NULL,
    elo_change INTEGER NOT NULL,
    opponent_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    opponent_elo INTEGER,
    result VARCHAR(20) CHECK (result IN ('win', 'loss', 'draw')),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tournament_elo_logs_tournament_id ON public.tournament_elo_logs(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_elo_logs_user_id ON public.tournament_elo_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_tournament_elo_logs_created_at ON public.tournament_elo_logs(created_at DESC);

ALTER TABLE public.tournament_elo_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own tournament elo logs" ON public.tournament_elo_logs
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 21: transactions - General Transaction Records
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('credit', 'debit', 'transfer', 'refund', 'adjustment')),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'VND',
    balance_after DECIMAL(10,2),
    description TEXT,
    reference_type VARCHAR(50),
    reference_id UUID,
    status VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_club_id ON public.transactions(club_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON public.transactions(created_at DESC);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions" ON public.transactions
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 22: notification_analytics - Notification Metrics
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.notification_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('sent', 'delivered', 'opened', 'clicked', 'dismissed')),
    platform VARCHAR(20) CHECK (platform IN ('android', 'ios', 'web')),
    device_id VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_analytics_notification_id ON public.notification_analytics(notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_analytics_user_id ON public.notification_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_analytics_event_type ON public.notification_analytics(event_type);
CREATE INDEX IF NOT EXISTS idx_notification_analytics_created_at ON public.notification_analytics(created_at DESC);

-- No RLS - analytics data

-- ============================================================================
-- TABLE 23: user_journey_events - User Behavior Tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_journey_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    session_id UUID,
    event_name VARCHAR(100) NOT NULL,
    event_category VARCHAR(50),
    screen_name VARCHAR(100),
    action VARCHAR(100),
    properties JSONB,
    platform VARCHAR(20),
    app_version VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_journey_events_user_id ON public.user_journey_events(user_id);
CREATE INDEX IF NOT EXISTS idx_user_journey_events_session_id ON public.user_journey_events(session_id);
CREATE INDEX IF NOT EXISTS idx_user_journey_events_event_name ON public.user_journey_events(event_name);
CREATE INDEX IF NOT EXISTS idx_user_journey_events_created_at ON public.user_journey_events(created_at DESC);

-- No RLS - analytics data

-- ============================================================================
-- TABLE 24: platform_settings - Platform Configuration
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.platform_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    data_type VARCHAR(20) DEFAULT 'string' CHECK (data_type IN ('string', 'number', 'boolean', 'json')),
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    is_editable BOOLEAN DEFAULT true,
    category VARCHAR(50),
    updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_platform_settings_key ON public.platform_settings(setting_key);
CREATE INDEX IF NOT EXISTS idx_platform_settings_category ON public.platform_settings(category);
CREATE INDEX IF NOT EXISTS idx_platform_settings_is_public ON public.platform_settings(is_public);

ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view public settings" ON public.platform_settings
    FOR SELECT USING (is_public = true);

-- ============================================================================
-- TABLE 25: game_formats - Game Format Definitions
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.game_formats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    format_name VARCHAR(100) NOT NULL UNIQUE,
    game_type VARCHAR(50) NOT NULL,
    description TEXT,
    rules JSONB,
    scoring_system JSONB,
    time_limits JSONB,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_game_formats_game_type ON public.game_formats(game_type);
CREATE INDEX IF NOT EXISTS idx_game_formats_is_active ON public.game_formats(is_active);

ALTER TABLE public.game_formats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active game formats" ON public.game_formats
    FOR SELECT USING (is_active = true);

-- ============================================================================
-- TABLE 26: ranking_definitions - Rank System Configuration
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.ranking_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rank_name VARCHAR(100) NOT NULL,
    rank_level INTEGER NOT NULL,
    min_elo INTEGER NOT NULL,
    max_elo INTEGER,
    icon_url TEXT,
    color_code VARCHAR(7),
    description TEXT,
    benefits JSONB,
    requirements JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(rank_level)
);

CREATE INDEX IF NOT EXISTS idx_ranking_definitions_rank_level ON public.ranking_definitions(rank_level);
CREATE INDEX IF NOT EXISTS idx_ranking_definitions_elo_range ON public.ranking_definitions(min_elo, max_elo);
CREATE INDEX IF NOT EXISTS idx_ranking_definitions_is_active ON public.ranking_definitions(is_active);

ALTER TABLE public.ranking_definitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active ranks" ON public.ranking_definitions
    FOR SELECT USING (is_active = true);

-- ============================================================================
-- TABLE 27: prize_pool_configurations - Prize Pool Rules
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.prize_pool_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_name VARCHAR(100) NOT NULL,
    tournament_type VARCHAR(50),
    participant_ranges JSONB NOT NULL,
    prize_distribution JSONB NOT NULL,
    calculation_method VARCHAR(50) DEFAULT 'percentage' CHECK (calculation_method IN ('percentage', 'fixed', 'dynamic')),
    description TEXT,
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prize_pool_configs_tournament_type ON public.prize_pool_configurations(tournament_type);
CREATE INDEX IF NOT EXISTS idx_prize_pool_configs_is_default ON public.prize_pool_configurations(is_default);
CREATE INDEX IF NOT EXISTS idx_prize_pool_configs_is_active ON public.prize_pool_configurations(is_active);

ALTER TABLE public.prize_pool_configurations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active prize pool configs" ON public.prize_pool_configurations
    FOR SELECT USING (is_active = true);

-- ============================================================================
-- TABLE 28: invoices - Invoice Management
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL,
    payment_id UUID REFERENCES public.payments(id) ON DELETE SET NULL,
    amount DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'VND',
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'issued', 'paid', 'cancelled', 'overdue')),
    issue_date DATE,
    due_date DATE,
    paid_date DATE,
    items JSONB,
    notes TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON public.invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON public.invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_club_id ON public.invoices(club_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON public.invoices(due_date);

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own invoices" ON public.invoices
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Club admins can view club invoices" ON public.invoices
    FOR SELECT USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================================
-- TABLE 29: typing_indicators - Chat Typing Status
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.typing_indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT true,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(room_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_typing_indicators_room_id ON public.typing_indicators(room_id);
CREATE INDEX IF NOT EXISTS idx_typing_indicators_user_id ON public.typing_indicators(user_id);
CREATE INDEX IF NOT EXISTS idx_typing_indicators_is_typing ON public.typing_indicators(is_typing);

ALTER TABLE public.typing_indicators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own typing indicators" ON public.typing_indicators
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Room members can view typing indicators" ON public.typing_indicators
    FOR SELECT USING (
        room_id IN (
            SELECT room_id FROM public.chat_room_members
            WHERE user_id = auth.uid()
        )
    );

-- ============================================================================
-- PHASE 3 MIGRATION COMPLETE
-- ============================================================================
-- Created 13 remaining tables:
-- 17. chat_room_settings
-- 18. club_activity_logs
-- 19. elo_history
-- 20. tournament_elo_logs
-- 21. transactions
-- 22. notification_analytics
-- 23. user_journey_events
-- 24. platform_settings
-- 25. game_formats
-- 26. ranking_definitions
-- 27. prize_pool_configurations
-- 28. invoices
-- 29. typing_indicators
--
-- Total: 29 tables created across all phases
-- Remaining: 2 storage buckets (club_assets, tournament_assets)
-- ============================================================================
