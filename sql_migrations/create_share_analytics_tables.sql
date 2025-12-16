-- 📊 SHARE ANALYTICS TABLES
-- Track share events, engagement, and conversion metrics

-- Drop existing tables if any
DROP TABLE IF EXISTS public.share_performance;
DROP TABLE IF EXISTS public.share_analytics;

-- Share Analytics Table
CREATE TABLE public.share_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    content_type TEXT NOT NULL, -- 'tournament', 'match', 'leaderboard'
    content_id TEXT NOT NULL,
    share_method TEXT NOT NULL, -- 'rich_image', 'text_only'
    share_destination TEXT, -- 'whatsapp', 'facebook', 'messenger', etc.
    referral_code TEXT, -- QR code or deep link code
    event_type TEXT NOT NULL, -- 'share_initiated', 'share_completed', 'share_cancelled', 'link_clicked', 'qr_scanned'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Share Performance Table
CREATE TABLE public.share_performance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    content_type TEXT NOT NULL,
    content_id TEXT NOT NULL,
    processing_time_ms INTEGER NOT NULL, -- Time to generate image
    image_size_bytes INTEGER NOT NULL, -- Size of generated image
    was_successful BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_share_analytics_user ON public.share_analytics(user_id);
CREATE INDEX idx_share_analytics_content ON public.share_analytics(content_type, content_id);
CREATE INDEX idx_share_analytics_event ON public.share_analytics(event_type);
CREATE INDEX idx_share_analytics_created ON public.share_analytics(created_at DESC);

CREATE INDEX idx_share_performance_content ON public.share_performance(content_type, content_id);
CREATE INDEX idx_share_performance_created ON public.share_performance(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.share_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.share_performance ENABLE ROW LEVEL SECURITY;

-- RLS Policies for share_analytics
-- Users can view their own analytics
CREATE POLICY "Users can view own share analytics"
    ON public.share_analytics
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own analytics
CREATE POLICY "Users can insert own share analytics"
    ON public.share_analytics
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Service role can do everything (for admin dashboard)
CREATE POLICY "Service role can manage share analytics"
    ON public.share_analytics
    FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role')
    WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- RLS Policies for share_performance
-- Service role only (internal metrics)
CREATE POLICY "Service role can manage share performance"
    ON public.share_performance
    FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role')
    WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- Public can insert performance metrics (for tracking)
CREATE POLICY "Public can insert share performance"
    ON public.share_performance
    FOR INSERT
    WITH CHECK (true);

-- Comments for documentation
COMMENT ON TABLE public.share_analytics IS 'Track share events and engagement metrics';
COMMENT ON TABLE public.share_performance IS 'Track share generation performance metrics';

COMMENT ON COLUMN public.share_analytics.event_type IS 'share_initiated | share_completed | share_cancelled | link_clicked | qr_scanned';
COMMENT ON COLUMN public.share_analytics.share_method IS 'rich_image | text_only';
COMMENT ON COLUMN public.share_analytics.share_destination IS 'Platform where content was shared (whatsapp, facebook, etc)';

-- Grant permissions
GRANT SELECT, INSERT ON public.share_analytics TO authenticated;
GRANT SELECT, INSERT ON public.share_analytics TO anon;
GRANT SELECT, INSERT ON public.share_performance TO authenticated;
GRANT SELECT, INSERT ON public.share_performance TO anon;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Share analytics tables created successfully!';
    RAISE NOTICE '📊 Tables: share_analytics, share_performance';
    RAISE NOTICE '🔒 RLS enabled with appropriate policies';
END $$;
