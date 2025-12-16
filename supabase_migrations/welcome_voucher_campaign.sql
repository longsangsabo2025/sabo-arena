-- =====================================================
-- WELCOME VOUCHER CAMPAIGN SYSTEM
-- Tự động tặng voucher cho user mới đăng ký
-- =====================================================

-- 1. Bảng quản lý chiến dịch welcome voucher
CREATE TABLE IF NOT EXISTS welcome_voucher_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Campaign info
  name TEXT NOT NULL,
  description TEXT,
  
  -- Voucher config
  voucher_template_id UUID REFERENCES voucher_templates(id) ON DELETE CASCADE,
  voucher_code_prefix TEXT DEFAULT 'WELCOME', -- Prefix for auto-generated codes
  
  -- Trigger conditions
  trigger_on_first_login BOOLEAN DEFAULT true,
  trigger_on_email_verified BOOLEAN DEFAULT false,
  
  -- Campaign status
  is_active BOOLEAN DEFAULT true,
  start_date TIMESTAMPTZ DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  
  -- Limitations
  max_redemptions INTEGER, -- NULL = unlimited
  current_redemptions INTEGER DEFAULT 0,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- 2. Bảng club tham gia campaign (club phải đăng ký)
CREATE TABLE IF NOT EXISTS welcome_campaign_clubs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  campaign_id UUID REFERENCES welcome_voucher_campaigns(id) ON DELETE CASCADE,
  club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
  
  -- Registration status
  status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT,
  
  -- Timestamps
  registered_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(campaign_id, club_id)
);

-- 3. Bảng tracking user đã nhận voucher (tránh duplicate)
CREATE TABLE IF NOT EXISTS welcome_voucher_issued (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  campaign_id UUID REFERENCES welcome_voucher_campaigns(id) ON DELETE CASCADE,
  voucher_id UUID REFERENCES user_vouchers(id) ON DELETE CASCADE,
  
  issued_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, campaign_id)
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_welcome_campaigns_active ON welcome_voucher_campaigns(is_active, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_welcome_campaign_clubs_status ON welcome_campaign_clubs(campaign_id, status);
CREATE INDEX IF NOT EXISTS idx_welcome_voucher_issued_user ON welcome_voucher_issued(user_id);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Enable RLS for security
ALTER TABLE welcome_voucher_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE welcome_campaign_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE welcome_voucher_issued ENABLE ROW LEVEL SECURITY;

-- Admins can manage campaigns
CREATE POLICY "Admins can manage welcome campaigns"
  ON welcome_voucher_campaigns FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Club owners can view campaigns and register
CREATE POLICY "Club owners can view campaigns"
  ON welcome_voucher_campaigns FOR SELECT
  USING (is_active = true);

CREATE POLICY "Club owners can register for campaigns"
  ON welcome_campaign_clubs FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM clubs 
      WHERE id = club_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Club owners can view their registrations"
  ON welcome_campaign_clubs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM clubs 
      WHERE id = club_id AND owner_id = auth.uid()
    )
  );

-- Admins can approve/reject club registrations
CREATE POLICY "Admins can manage club registrations"
  ON welcome_campaign_clubs FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Users can view their issued vouchers
CREATE POLICY "Users can view their welcome vouchers"
  ON welcome_voucher_issued FOR SELECT
  USING (user_id = auth.uid());

-- =====================================================
-- FUNCTION: Auto-issue welcome voucher on first login
-- =====================================================

CREATE OR REPLACE FUNCTION issue_welcome_voucher_on_first_login()
RETURNS TRIGGER AS $$
DECLARE
  v_campaign RECORD;
  v_club RECORD;
  v_voucher_id UUID;
  v_voucher_code TEXT;
  v_template RECORD;
BEGIN
  -- Check if this is the first login (by checking if user has no issued welcome vouchers yet)
  IF EXISTS (
    SELECT 1 FROM welcome_voucher_issued WHERE user_id = NEW.id
  ) THEN
    RETURN NEW; -- User already received welcome voucher
  END IF;

  -- Get active campaign
  SELECT * INTO v_campaign
  FROM welcome_voucher_campaigns
  WHERE is_active = true
    AND trigger_on_first_login = true
    AND (start_date IS NULL OR start_date <= NOW())
    AND (end_date IS NULL OR end_date >= NOW())
    AND (max_redemptions IS NULL OR current_redemptions < max_redemptions)
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NEW; -- No active campaign
  END IF;

  -- Get an approved participating club (randomly)
  SELECT c.* INTO v_club
  FROM welcome_campaign_clubs wcc
  JOIN clubs c ON c.id = wcc.club_id
  WHERE wcc.campaign_id = v_campaign.id
    AND wcc.status = 'approved'
  ORDER BY RANDOM()
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NEW; -- No approved clubs in campaign
  END IF;

  -- Get voucher template details
  SELECT * INTO v_template
  FROM voucher_templates
  WHERE id = v_campaign.voucher_template_id;

  IF NOT FOUND THEN
    RETURN NEW; -- Template not found
  END IF;

  -- Generate unique voucher code
  v_voucher_code := v_campaign.voucher_code_prefix || '-' || 
                    UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));

  -- Create voucher for user
  INSERT INTO user_vouchers (
    user_id,
    template_id,
    voucher_code,
    club_id,
    status,
    issued_at,
    valid_from,
    valid_until,
    can_be_used_multiple_times,
    usage_limit,
    description
  ) VALUES (
    NEW.id,
    v_campaign.voucher_template_id,
    v_voucher_code,
    v_club.id,
    'active',
    NOW(),
    NOW(),
    NOW() + INTERVAL '30 days', -- Valid for 30 days
    false, -- One-time use
    1,
    'Voucher chào mừng thành viên mới tại ' || v_club.name
  ) RETURNING id INTO v_voucher_id;

  -- Track issued voucher
  INSERT INTO welcome_voucher_issued (
    user_id,
    campaign_id,
    voucher_id
  ) VALUES (
    NEW.id,
    v_campaign.id,
    v_voucher_id
  );

  -- Update campaign redemption count
  UPDATE welcome_voucher_campaigns
  SET current_redemptions = current_redemptions + 1,
      updated_at = NOW()
  WHERE id = v_campaign.id;

  -- Send notification to user (optional)
  INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    data
  ) VALUES (
    NEW.id,
    '🎉 Chúc mừng! Bạn nhận được voucher chào mừng',
    'Bạn vừa nhận được voucher "' || v_template.name || '" tại ' || v_club.name || '. Hãy sử dụng ngay!',
    'voucher',
    jsonb_build_object(
      'voucher_id', v_voucher_id,
      'voucher_code', v_voucher_code,
      'club_id', v_club.id
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRIGGER: Issue welcome voucher when user confirmed
-- =====================================================

-- Trigger when user email is confirmed (sign up completion)
CREATE OR REPLACE TRIGGER trigger_welcome_voucher_on_confirm
  AFTER UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW
  WHEN (OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL)
  EXECUTE FUNCTION issue_welcome_voucher_on_first_login();

-- =====================================================
-- SEED DATA: Create default welcome campaign
-- =====================================================

-- Insert default welcome campaign for Sabo Billiard
DO $$
DECLARE
  v_campaign_id UUID;
  v_template_id UUID;
  v_sabo_club_id UUID;
BEGIN
  -- Find or create welcome voucher template
  SELECT id INTO v_template_id
  FROM voucher_templates
  WHERE name = 'Welcome Package - 2h Free Play'
  LIMIT 1;

  IF NOT FOUND THEN
    INSERT INTO voucher_templates (
      name,
      description,
      voucher_type,
      discount_type,
      discount_value,
      conditions,
      is_active
    ) VALUES (
      'Welcome Package - 2h Free Play',
      '2 giờ chơi miễn phí + Free trái cây, trà đá. Áp dụng mọi khung giờ.',
      'time_based',
      'percentage',
      100,
      jsonb_build_object(
        'max_discount', 200000,
        'free_hours', 2,
        'free_items', ARRAY['Trái cây', 'Trà đá'],
        'valid_time_slots', 'all'
      ),
      true
    ) RETURNING id INTO v_template_id;
  END IF;

  -- Create welcome campaign
  INSERT INTO welcome_voucher_campaigns (
    name,
    description,
    voucher_template_id,
    voucher_code_prefix,
    trigger_on_first_login,
    is_active,
    start_date
  ) VALUES (
    'Welcome New Members 2025',
    'Chương trình chào mừng thành viên mới - Tặng 2h chơi + Free đồ uống',
    v_template_id,
    'WELCOME2025',
    true,
    true,
    NOW()
  ) RETURNING id INTO v_campaign_id;

  -- Find Sabo Billiard club
  SELECT id INTO v_sabo_club_id
  FROM clubs
  WHERE LOWER(name) LIKE '%sabo%billiard%'
  LIMIT 1;

  -- Auto-approve Sabo Billiard to join campaign
  IF v_sabo_club_id IS NOT NULL THEN
    INSERT INTO welcome_campaign_clubs (
      campaign_id,
      club_id,
      status,
      approved_at
    ) VALUES (
      v_campaign_id,
      v_sabo_club_id,
      'approved',
      NOW()
    );
  END IF;

  RAISE NOTICE 'Welcome voucher campaign created successfully!';
END $$;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to check if user is eligible for welcome voucher
CREATE OR REPLACE FUNCTION check_user_welcome_voucher_eligibility(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_already_received BOOLEAN;
  v_active_campaign RECORD;
BEGIN
  -- Check if user already received welcome voucher
  SELECT EXISTS (
    SELECT 1 FROM welcome_voucher_issued WHERE user_id = p_user_id
  ) INTO v_already_received;

  IF v_already_received THEN
    RETURN jsonb_build_object(
      'eligible', false,
      'reason', 'User already received welcome voucher',
      'already_received', true
    );
  END IF;

  -- Check if there's an active campaign
  SELECT * INTO v_active_campaign
  FROM welcome_voucher_campaigns
  WHERE is_active = true
    AND (start_date IS NULL OR start_date <= NOW())
    AND (end_date IS NULL OR end_date >= NOW())
    AND (max_redemptions IS NULL OR current_redemptions < max_redemptions)
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'eligible', false,
      'reason', 'No active campaign available',
      'already_received', false
    );
  END IF;

  RETURN jsonb_build_object(
    'eligible', true,
    'campaign_id', v_active_campaign.id,
    'campaign_name', v_active_campaign.name,
    'already_received', false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE welcome_voucher_campaigns IS 'Quản lý chiến dịch tặng voucher chào mừng thành viên mới';
COMMENT ON TABLE welcome_campaign_clubs IS 'Danh sách club tham gia chiến dịch welcome voucher';
COMMENT ON TABLE welcome_voucher_issued IS 'Tracking user đã nhận welcome voucher (tránh duplicate)';
