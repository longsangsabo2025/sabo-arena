-- =====================================================
-- PROMOTION ANALYTICS SYSTEM - COMPLETE BACKEND
-- Hệ thống phân tích hiệu quả khuyến mãi
-- =====================================================

-- ============================================================
-- TABLE 1: promotion_analytics_daily - Thống kê theo ngày
-- ============================================================

CREATE TABLE IF NOT EXISTS public.promotion_analytics_daily (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promotion_id UUID NOT NULL REFERENCES public.club_promotions(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Date dimension
    date DATE NOT NULL,
    day_of_week INTEGER, -- 0=Sunday, 6=Saturday
    is_weekend BOOLEAN,
    
    -- Usage metrics
    total_redemptions INTEGER DEFAULT 0,
    unique_users INTEGER DEFAULT 0,
    new_users INTEGER DEFAULT 0, -- First-time users
    returning_users INTEGER DEFAULT 0,
    
    -- Financial metrics
    total_discount_given DECIMAL(12,2) DEFAULT 0,
    total_revenue_generated DECIMAL(12,2) DEFAULT 0,
    avg_discount_per_redemption DECIMAL(10,2),
    avg_order_value DECIMAL(10,2),
    
    -- Performance metrics
    conversion_rate DECIMAL(5,2), -- % users who saw vs used
    redemption_rate DECIMAL(5,2), -- % of total capacity used
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(promotion_id, date)
);

CREATE INDEX idx_promo_analytics_daily_promotion ON public.promotion_analytics_daily(promotion_id);
CREATE INDEX idx_promo_analytics_daily_club ON public.promotion_analytics_daily(club_id);
CREATE INDEX idx_promo_analytics_daily_date ON public.promotion_analytics_daily(date DESC);

COMMENT ON TABLE public.promotion_analytics_daily IS 'Thống kê promotion theo ngày';

-- ============================================================
-- TABLE 2: promotion_analytics_summary - Tổng hợp toàn bộ
-- ============================================================

CREATE TABLE IF NOT EXISTS public.promotion_analytics_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promotion_id UUID NOT NULL REFERENCES public.club_promotions(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Overall metrics
    total_redemptions INTEGER DEFAULT 0,
    total_unique_users INTEGER DEFAULT 0,
    total_discount_given DECIMAL(12,2) DEFAULT 0,
    total_revenue DECIMAL(12,2) DEFAULT 0,
    
    -- ROI calculation
    promotion_cost DECIMAL(12,2) DEFAULT 0, -- Total discount + operational cost
    revenue_attributed DECIMAL(12,2) DEFAULT 0,
    net_profit DECIMAL(12,2) DEFAULT 0,
    roi_percentage DECIMAL(8,2),
    
    -- Performance metrics
    avg_redemptions_per_day DECIMAL(10,2),
    peak_redemption_day DATE,
    peak_redemptions INTEGER,
    
    -- User engagement
    avg_redemptions_per_user DECIMAL(6,2),
    user_satisfaction_score DECIMAL(3,2), -- 1-5 scale
    
    -- Time analysis
    total_days_active INTEGER,
    first_redemption_at TIMESTAMPTZ,
    last_redemption_at TIMESTAMPTZ,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    last_calculated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(promotion_id)
);

CREATE INDEX idx_promo_analytics_summary_club ON public.promotion_analytics_summary(club_id);
CREATE INDEX idx_promo_analytics_summary_roi ON public.promotion_analytics_summary(roi_percentage DESC);

COMMENT ON TABLE public.promotion_analytics_summary IS 'Tổng hợp analytics cho toàn bộ promotion';

-- ============================================================
-- TABLE 3: voucher_analytics_summary - Tổng hợp voucher
-- ============================================================

CREATE TABLE IF NOT EXISTS public.voucher_analytics_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID NOT NULL REFERENCES public.voucher_campaigns(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Issuance metrics
    total_vouchers_issued INTEGER DEFAULT 0,
    total_vouchers_used INTEGER DEFAULT 0,
    total_vouchers_expired INTEGER DEFAULT 0,
    vouchers_unused INTEGER DEFAULT 0,
    
    -- Usage rate
    usage_rate DECIMAL(5,2), -- % issued vs used
    expiry_rate DECIMAL(5,2), -- % expired vs issued
    
    -- Financial impact
    total_discount_given DECIMAL(12,2) DEFAULT 0,
    avg_discount_per_voucher DECIMAL(10,2),
    total_bonus_time_minutes INTEGER DEFAULT 0,
    
    -- User metrics
    unique_users_issued INTEGER DEFAULT 0,
    unique_users_redeemed INTEGER DEFAULT 0,
    redemption_conversion DECIMAL(5,2), -- % users who used vs received
    
    -- Time metrics
    avg_days_to_use DECIMAL(6,2),
    first_issued_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    
    -- Campaign performance
    campaign_roi DECIMAL(8,2),
    campaign_effectiveness_score DECIMAL(3,2), -- 1-10 scale
    
    -- Metadata
    last_calculated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(campaign_id)
);

CREATE INDEX idx_voucher_analytics_campaign ON public.voucher_analytics_summary(campaign_id);
CREATE INDEX idx_voucher_analytics_club ON public.voucher_analytics_summary(club_id);
CREATE INDEX idx_voucher_analytics_usage_rate ON public.voucher_analytics_summary(usage_rate DESC);

COMMENT ON TABLE public.voucher_analytics_summary IS 'Tổng hợp analytics cho voucher campaigns';

-- ============================================================
-- RLS POLICIES
-- ============================================================

ALTER TABLE public.promotion_analytics_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_analytics_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voucher_analytics_summary ENABLE ROW LEVEL SECURITY;

-- Club owners can view their analytics
CREATE POLICY "Club owners can view promotion analytics"
    ON public.promotion_analytics_daily FOR SELECT
    USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "Club owners can view promotion summary"
    ON public.promotion_analytics_summary FOR SELECT
    USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "Club owners can view voucher analytics"
    ON public.voucher_analytics_summary FOR SELECT
    USING (
        club_id IN (
            SELECT club_id FROM public.club_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================
-- RPC FUNCTIONS - PROMOTION ANALYTICS
-- ============================================================

-- Function 1: Calculate daily promotion analytics
CREATE OR REPLACE FUNCTION calculate_promotion_daily_analytics(
    p_promotion_id UUID,
    p_date DATE
)
RETURNS JSONB AS $$
DECLARE
    v_analytics RECORD;
    v_promotion RECORD;
    v_result JSONB;
BEGIN
    -- Get promotion info
    SELECT * INTO v_promotion
    FROM public.club_promotions
    WHERE id = p_promotion_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Promotion not found');
    END IF;
    
    -- Calculate daily metrics
    SELECT
        COUNT(*) as total_redemptions,
        COUNT(DISTINCT pr.user_id) as unique_users,
        COALESCE(SUM(pr.discount_amount), 0) as total_discount,
        COALESCE(SUM(pr.final_amount), 0) as total_revenue,
        COALESCE(AVG(pr.discount_amount), 0) as avg_discount,
        COALESCE(AVG(pr.final_amount), 0) as avg_order_value
    INTO v_analytics
    FROM public.promotion_redemptions pr
    WHERE pr.promotion_id = p_promotion_id
      AND DATE(pr.redeemed_at) = p_date;
    
    -- Insert or update daily analytics
    INSERT INTO public.promotion_analytics_daily (
        promotion_id, club_id, date,
        day_of_week, is_weekend,
        total_redemptions, unique_users,
        total_discount_given, total_revenue_generated,
        avg_discount_per_redemption, avg_order_value
    ) VALUES (
        p_promotion_id, v_promotion.club_id, p_date,
        EXTRACT(DOW FROM p_date),
        EXTRACT(DOW FROM p_date) IN (0, 6),
        v_analytics.total_redemptions, v_analytics.unique_users,
        v_analytics.total_discount, v_analytics.total_revenue,
        v_analytics.avg_discount, v_analytics.avg_order_value
    )
    ON CONFLICT (promotion_id, date) DO UPDATE SET
        total_redemptions = EXCLUDED.total_redemptions,
        unique_users = EXCLUDED.unique_users,
        total_discount_given = EXCLUDED.total_discount_given,
        total_revenue_generated = EXCLUDED.total_revenue_generated,
        avg_discount_per_redemption = EXCLUDED.avg_discount_per_redemption,
        avg_order_value = EXCLUDED.avg_order_value,
        updated_at = NOW();
    
    RETURN jsonb_build_object(
        'success', true,
        'date', p_date,
        'redemptions', v_analytics.total_redemptions,
        'revenue', v_analytics.total_revenue
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 2: Calculate promotion ROI
CREATE OR REPLACE FUNCTION calculate_promotion_roi(
    p_promotion_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_summary RECORD;
    v_promotion RECORD;
    v_roi DECIMAL;
    v_net_profit DECIMAL;
BEGIN
    -- Get promotion
    SELECT * INTO v_promotion
    FROM public.club_promotions
    WHERE id = p_promotion_id;
    
    -- Calculate totals
    SELECT
        COUNT(*) as total_redemptions,
        COUNT(DISTINCT user_id) as unique_users,
        COALESCE(SUM(discount_amount), 0) as total_discount,
        COALESCE(SUM(final_amount), 0) as total_revenue,
        COALESCE(AVG(discount_amount), 0) as avg_discount,
        MIN(redeemed_at) as first_redemption,
        MAX(redeemed_at) as last_redemption
    INTO v_summary
    FROM public.promotion_redemptions
    WHERE promotion_id = p_promotion_id;
    
    -- Calculate ROI
    -- ROI = (Revenue - Cost) / Cost * 100
    v_net_profit := v_summary.total_revenue - v_summary.total_discount;
    
    IF v_summary.total_discount > 0 THEN
        v_roi := (v_net_profit / v_summary.total_discount) * 100;
    ELSE
        v_roi := 0;
    END IF;
    
    -- Update or create summary
    INSERT INTO public.promotion_analytics_summary (
        promotion_id, club_id,
        total_redemptions, total_unique_users,
        total_discount_given, total_revenue,
        promotion_cost, revenue_attributed, net_profit, roi_percentage,
        first_redemption_at, last_redemption_at,
        last_calculated_at
    ) VALUES (
        p_promotion_id, v_promotion.club_id,
        v_summary.total_redemptions, v_summary.unique_users,
        v_summary.total_discount, v_summary.total_revenue,
        v_summary.total_discount, v_summary.total_revenue, 
        v_net_profit, v_roi,
        v_summary.first_redemption, v_summary.last_redemption,
        NOW()
    )
    ON CONFLICT (promotion_id) DO UPDATE SET
        total_redemptions = EXCLUDED.total_redemptions,
        total_unique_users = EXCLUDED.total_unique_users,
        total_discount_given = EXCLUDED.total_discount_given,
        total_revenue = EXCLUDED.total_revenue,
        net_profit = EXCLUDED.net_profit,
        roi_percentage = EXCLUDED.roi_percentage,
        last_calculated_at = NOW();
    
    RETURN jsonb_build_object(
        'success', true,
        'promotion_id', p_promotion_id,
        'total_redemptions', v_summary.total_redemptions,
        'total_revenue', v_summary.total_revenue,
        'total_discount', v_summary.total_discount,
        'net_profit', v_net_profit,
        'roi_percentage', v_roi
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 3: Get club promotion metrics
CREATE OR REPLACE FUNCTION get_club_promotion_metrics(
    p_club_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_metrics JSONB;
    v_start DATE;
    v_end DATE;
BEGIN
    v_start := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
    v_end := COALESCE(p_end_date, CURRENT_DATE);
    
    SELECT jsonb_build_object(
        'period', jsonb_build_object(
            'start_date', v_start,
            'end_date', v_end,
            'days', v_end - v_start
        ),
        'overview', jsonb_build_object(
            'total_promotions', COUNT(DISTINCT cp.id),
            'active_promotions', COUNT(DISTINCT cp.id) FILTER (WHERE cp.is_active = true),
            'total_redemptions', COALESCE(SUM(pas.total_redemptions), 0),
            'total_revenue', COALESCE(SUM(pas.total_revenue), 0),
            'total_discount', COALESCE(SUM(pas.total_discount_given), 0),
            'avg_roi', COALESCE(AVG(pas.roi_percentage), 0)
        ),
        'top_performers', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'promotion_id', cp.id,
                    'title', cp.title,
                    'redemptions', pas.total_redemptions,
                    'revenue', pas.total_revenue,
                    'roi', pas.roi_percentage
                )
                ORDER BY pas.total_revenue DESC
            )
            FROM public.club_promotions cp
            JOIN public.promotion_analytics_summary pas ON cp.id = pas.promotion_id
            WHERE cp.club_id = p_club_id
            LIMIT 5
        ),
        'by_type', (
            SELECT jsonb_object_agg(
                cp.promotion_type,
                jsonb_build_object(
                    'count', COUNT(*),
                    'total_redemptions', COALESCE(SUM(pas.total_redemptions), 0),
                    'total_revenue', COALESCE(SUM(pas.total_revenue), 0)
                )
            )
            FROM public.club_promotions cp
            LEFT JOIN public.promotion_analytics_summary pas ON cp.id = pas.promotion_id
            WHERE cp.club_id = p_club_id
            GROUP BY cp.promotion_type
        )
    ) INTO v_metrics
    FROM public.club_promotions cp
    LEFT JOIN public.promotion_analytics_summary pas ON cp.id = pas.promotion_id
    WHERE cp.club_id = p_club_id;
    
    RETURN v_metrics;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 4: Compare promotions
CREATE OR REPLACE FUNCTION compare_promotions(
    p_promotion_ids UUID[]
)
RETURNS TABLE (
    promotion_id UUID,
    promotion_title TEXT,
    total_redemptions INTEGER,
    total_revenue DECIMAL,
    total_discount DECIMAL,
    roi_percentage DECIMAL,
    unique_users INTEGER,
    avg_discount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cp.id,
        cp.title,
        COALESCE(pas.total_redemptions, 0)::INTEGER,
        COALESCE(pas.total_revenue, 0),
        COALESCE(pas.total_discount_given, 0),
        COALESCE(pas.roi_percentage, 0),
        COALESCE(pas.total_unique_users, 0)::INTEGER,
        CASE 
            WHEN pas.total_redemptions > 0 
            THEN pas.total_discount_given / pas.total_redemptions
            ELSE 0
        END
    FROM public.club_promotions cp
    LEFT JOIN public.promotion_analytics_summary pas ON cp.id = pas.promotion_id
    WHERE cp.id = ANY(p_promotion_ids)
    ORDER BY pas.total_revenue DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- RPC FUNCTIONS - VOUCHER ANALYTICS
-- ============================================================

-- Function 5: Calculate voucher campaign analytics
CREATE OR REPLACE FUNCTION calculate_voucher_analytics(
    p_campaign_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_campaign RECORD;
    v_stats RECORD;
    v_usage_rate DECIMAL;
    v_result JSONB;
BEGIN
    -- Get campaign
    SELECT * INTO v_campaign
    FROM public.voucher_campaigns
    WHERE id = p_campaign_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Campaign not found');
    END IF;
    
    -- Calculate voucher statistics
    SELECT
        COUNT(*) as total_issued,
        COUNT(*) FILTER (WHERE status = 'used') as total_used,
        COUNT(*) FILTER (WHERE status = 'expired') as total_expired,
        COUNT(*) FILTER (WHERE status = 'active') as unused,
        COUNT(DISTINCT user_id) as unique_users_issued,
        COUNT(DISTINCT user_id) FILTER (WHERE status = 'used') as unique_users_redeemed,
        MIN(created_at) as first_issued,
        MAX(used_at) as last_used
    INTO v_stats
    FROM public.user_vouchers
    WHERE campaign_id = p_campaign_id;
    
    -- Calculate usage rate
    IF v_stats.total_issued > 0 THEN
        v_usage_rate := (v_stats.total_used::DECIMAL / v_stats.total_issued) * 100;
    ELSE
        v_usage_rate := 0;
    END IF;
    
    -- Update or create analytics
    INSERT INTO public.voucher_analytics_summary (
        campaign_id, club_id,
        total_vouchers_issued, total_vouchers_used,
        total_vouchers_expired, vouchers_unused,
        usage_rate,
        unique_users_issued, unique_users_redeemed,
        first_issued_at, last_used_at,
        last_calculated_at
    ) VALUES (
        p_campaign_id, v_campaign.club_id,
        v_stats.total_issued, v_stats.total_used,
        v_stats.total_expired, v_stats.unused,
        v_usage_rate,
        v_stats.unique_users_issued, v_stats.unique_users_redeemed,
        v_stats.first_issued, v_stats.last_used,
        NOW()
    )
    ON CONFLICT (campaign_id) DO UPDATE SET
        total_vouchers_issued = EXCLUDED.total_vouchers_issued,
        total_vouchers_used = EXCLUDED.total_vouchers_used,
        total_vouchers_expired = EXCLUDED.total_vouchers_expired,
        vouchers_unused = EXCLUDED.vouchers_unused,
        usage_rate = EXCLUDED.usage_rate,
        unique_users_issued = EXCLUDED.unique_users_issued,
        unique_users_redeemed = EXCLUDED.unique_users_redeemed,
        last_calculated_at = NOW();
    
    RETURN jsonb_build_object(
        'success', true,
        'campaign_id', p_campaign_id,
        'total_issued', v_stats.total_issued,
        'total_used', v_stats.total_used,
        'usage_rate', v_usage_rate
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- AUTO-UPDATE PROMOTION STATUS FUNCTION
-- ============================================================

-- Function: Auto-update expired promotions
CREATE OR REPLACE FUNCTION auto_update_promotion_status()
RETURNS INTEGER AS $$
DECLARE
    v_updated_count INTEGER := 0;
BEGIN
    -- Update expired promotions
    UPDATE public.club_promotions
    SET 
        is_active = false,
        updated_at = NOW()
    WHERE is_active = true
      AND end_date < NOW()
      AND is_active = true;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- SCHEDULED JOB SETUP (PostgreSQL pg_cron extension)
-- ============================================================

-- Note: This requires pg_cron extension to be enabled
-- Run daily at 00:00 to update promotion status
-- SELECT cron.schedule('update-promotion-status', '0 0 * * *', 'SELECT auto_update_promotion_status()');

-- Run daily at 01:00 to calculate yesterday's analytics
-- SELECT cron.schedule('calculate-daily-analytics', '0 1 * * *', $$
--   SELECT calculate_promotion_daily_analytics(id, CURRENT_DATE - 1)
--   FROM club_promotions WHERE is_active = true;
-- $$);

COMMENT ON FUNCTION calculate_promotion_roi IS 'Calculate ROI for a promotion campaign';
COMMENT ON FUNCTION get_club_promotion_metrics IS 'Get comprehensive promotion metrics for a club';
COMMENT ON FUNCTION compare_promotions IS 'Compare multiple promotions side-by-side';
COMMENT ON FUNCTION calculate_voucher_analytics IS 'Calculate analytics for voucher campaigns';
COMMENT ON FUNCTION auto_update_promotion_status IS 'Auto-update expired promotion status';
