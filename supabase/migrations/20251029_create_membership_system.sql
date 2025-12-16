-- =============================================
-- MEMBERSHIP POLICIES & TYPES TABLES
-- Lưu trữ chính sách và loại thành viên CLB
-- =============================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 1. MEMBERSHIP TYPES TABLE
-- Các loại thành viên (VIP, Regular, Student, Day Pass, etc.)
-- =============================================

CREATE TABLE IF NOT EXISTS public.membership_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Type Information
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color VARCHAR(7) DEFAULT '#4CAF50', -- Hex color code
    icon VARCHAR(50) DEFAULT 'card_membership',
    
    -- Pricing
    monthly_fee DECIMAL(10, 2) DEFAULT 0,
    daily_fee DECIMAL(10, 2),
    yearly_fee DECIMAL(10, 2),
    
    -- Benefits (stored as JSONB array)
    benefits JSONB DEFAULT '[]'::JSONB,
    
    -- Settings
    is_active BOOLEAN DEFAULT true,
    requires_approval BOOLEAN DEFAULT false,
    max_members INT, -- Limit số lượng thành viên loại này
    
    -- Priority (higher = more priority)
    priority INT DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(club_id, name)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_membership_types_club_id ON public.membership_types(club_id);
CREATE INDEX IF NOT EXISTS idx_membership_types_is_active ON public.membership_types(club_id, is_active);

-- =============================================
-- 2. MEMBERSHIP POLICIES TABLE
-- Chính sách thành viên của CLB
-- =============================================

CREATE TABLE IF NOT EXISTS public.membership_policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL UNIQUE REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Registration Settings
    requires_approval BOOLEAN DEFAULT true,
    allow_guest_access BOOLEAN DEFAULT false,
    requires_deposit BOOLEAN DEFAULT false,
    deposit_amount DECIMAL(10, 2) DEFAULT 0,
    
    -- Limits
    max_members_limit INT DEFAULT 500,
    min_age INT DEFAULT 16,
    max_age INT,
    
    -- Renewal
    enable_auto_renewal BOOLEAN DEFAULT true,
    renewal_reminder_days INT DEFAULT 7, -- Nhắc nhở trước X ngày
    
    -- Registration Requirements (JSONB array)
    required_documents JSONB DEFAULT '["CMND/CCCD", "Số điện thoại", "Email", "Ảnh đại diện"]'::JSONB,
    
    -- Terms & Conditions
    terms_and_conditions TEXT,
    privacy_policy TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_membership_policies_club_id ON public.membership_policies(club_id);

-- =============================================
-- 3. CLUB NOTIFICATION SETTINGS TABLE
-- Cài đặt thông báo tự động cho CLB
-- =============================================

CREATE TABLE IF NOT EXISTS public.club_notification_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL UNIQUE REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Member Notifications
    notify_on_new_member BOOLEAN DEFAULT true,
    notify_on_member_request BOOLEAN DEFAULT true,
    notify_on_member_approval BOOLEAN DEFAULT true,
    notify_on_member_rejection BOOLEAN DEFAULT false,
    
    -- Tournament Notifications
    notify_on_tournament_registration BOOLEAN DEFAULT true,
    notify_on_tournament_start BOOLEAN DEFAULT true,
    notify_on_tournament_end BOOLEAN DEFAULT true,
    
    -- Match Notifications
    notify_on_match_created BOOLEAN DEFAULT true,
    notify_on_score_input BOOLEAN DEFAULT true,
    notify_on_match_completed BOOLEAN DEFAULT false,
    
    -- Social Notifications
    notify_on_new_post BOOLEAN DEFAULT true,
    notify_on_post_like BOOLEAN DEFAULT false,
    notify_on_post_comment BOOLEAN DEFAULT true,
    
    -- Rank Notifications
    notify_on_rank_verification BOOLEAN DEFAULT true,
    notify_on_rank_change BOOLEAN DEFAULT true,
    
    -- Notification Channels
    enable_push BOOLEAN DEFAULT true,
    enable_email BOOLEAN DEFAULT false,
    enable_sms BOOLEAN DEFAULT false,
    
    -- Quiet Hours
    enable_quiet_hours BOOLEAN DEFAULT false,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_club_notification_settings_club_id ON public.club_notification_settings(club_id);

-- =============================================
-- 4. TRIGGERS FOR UPDATED_AT
-- =============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
DROP TRIGGER IF EXISTS update_membership_types_updated_at ON public.membership_types;
CREATE TRIGGER update_membership_types_updated_at
    BEFORE UPDATE ON public.membership_types
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_membership_policies_updated_at ON public.membership_policies;
CREATE TRIGGER update_membership_policies_updated_at
    BEFORE UPDATE ON public.membership_policies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_club_notification_settings_updated_at ON public.club_notification_settings;
CREATE TRIGGER update_club_notification_settings_updated_at
    BEFORE UPDATE ON public.club_notification_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 5. RLS POLICIES
-- =============================================

-- Enable RLS
ALTER TABLE public.membership_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.membership_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_notification_settings ENABLE ROW LEVEL SECURITY;

-- Membership Types Policies
-- Anyone can view active membership types
CREATE POLICY "public_can_view_active_membership_types"
    ON public.membership_types
    FOR SELECT
    TO authenticated
    USING (is_active = true);

-- Club owners/admins can manage membership types
CREATE POLICY "club_owners_can_manage_membership_types"
    ON public.membership_types
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.club_members cm
            WHERE cm.club_id = membership_types.club_id
            AND cm.user_id = auth.uid()
            AND cm.role IN ('owner', 'admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.club_members cm
            WHERE cm.club_id = membership_types.club_id
            AND cm.user_id = auth.uid()
            AND cm.role IN ('owner', 'admin')
        )
    );

-- Membership Policies Policies
-- Club members can view policies
CREATE POLICY "club_members_can_view_policies"
    ON public.membership_policies
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.club_members cm
            WHERE cm.club_id = membership_policies.club_id
            AND cm.user_id = auth.uid()
        )
    );

-- Club owners can manage policies
CREATE POLICY "club_owners_can_manage_policies"
    ON public.membership_policies
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.club_members cm
            WHERE cm.club_id = membership_policies.club_id
            AND cm.user_id = auth.uid()
            AND cm.role = 'owner'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.club_members cm
            WHERE cm.club_id = membership_policies.club_id
            AND cm.user_id = auth.uid()
            AND cm.role = 'owner'
        )
    );

-- Club Notification Settings Policies
-- Club owners/admins can manage notification settings
CREATE POLICY "club_owners_can_manage_notification_settings"
    ON public.club_notification_settings
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.club_members cm
            WHERE cm.club_id = club_notification_settings.club_id
            AND cm.user_id = auth.uid()
            AND cm.role IN ('owner', 'admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.club_members cm
            WHERE cm.club_id = club_notification_settings.club_id
            AND cm.user_id = auth.uid()
            AND cm.role IN ('owner', 'admin')
        )
    );

-- =============================================
-- 6. SAMPLE DATA (Optional)
-- =============================================

COMMENT ON TABLE public.membership_types IS 'Các loại thành viên của CLB (VIP, Regular, Student, etc.)';
COMMENT ON TABLE public.membership_policies IS 'Chính sách thành viên của CLB (yêu cầu phê duyệt, giới hạn, v.v.)';
COMMENT ON TABLE public.club_notification_settings IS 'Cài đặt thông báo tự động cho CLB';

-- =============================================
-- DEPLOYMENT COMPLETE
-- =============================================
