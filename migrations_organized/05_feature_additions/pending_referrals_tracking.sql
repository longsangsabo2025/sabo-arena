-- =====================================================
-- PENDING REFERRALS TRACKING SYSTEM
-- Server-side tracking để không mất referral code qua App Store
-- =====================================================

-- 1. Bảng pending_referrals: Track referral clicks từ website
CREATE TABLE IF NOT EXISTS pending_referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Referral info
  referral_code TEXT NOT NULL,
  referrer_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  target_user_id UUID, -- User được giới thiệu (từ QR URL)
  
  -- Device tracking data (để match sau khi install app)
  device_fingerprint TEXT, -- Browser fingerprint từ FingerprintJS
  ip_address TEXT,
  user_agent TEXT,
  
  -- Click metadata
  click_timestamp TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days',
  source_url TEXT, -- Full URL: /user/xxx?ref=LONGSANG1
  utm_params JSONB, -- UTM parameters nếu có
  
  -- Claim status
  claimed_at TIMESTAMPTZ,
  claimed_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  claim_method TEXT, -- 'exact_match', 'ip_match', 'manual'
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Indexes cho performance
CREATE INDEX IF NOT EXISTS idx_pending_referrals_device_fingerprint 
  ON pending_referrals(device_fingerprint) WHERE claimed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_pending_referrals_ip_address 
  ON pending_referrals(ip_address) WHERE claimed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_pending_referrals_expires_at 
  ON pending_referrals(expires_at) WHERE claimed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_pending_referrals_claimed 
  ON pending_referrals(claimed_at, claimed_by_user_id);

CREATE INDEX IF NOT EXISTS idx_pending_referrals_referral_code 
  ON pending_referrals(referral_code);

-- 3. Enable RLS
ALTER TABLE pending_referrals ENABLE ROW LEVEL SECURITY;

-- Service role can do everything (for API endpoints)
CREATE POLICY "Service role full access"
  ON pending_referrals FOR ALL
  USING (true)
  WITH CHECK (true);

-- Users can view their own pending referrals
CREATE POLICY "Users can view their pending referrals"
  ON pending_referrals FOR SELECT
  USING (
    referrer_user_id = auth.uid() OR
    claimed_by_user_id = auth.uid()
  );

-- =====================================================
-- FUNCTION: track_referral_click
-- Called by website when user clicks QR link
-- =====================================================
CREATE OR REPLACE FUNCTION track_referral_click(
  p_referral_code TEXT,
  p_target_user_id UUID,
  p_device_fingerprint TEXT,
  p_ip_address TEXT,
  p_user_agent TEXT,
  p_source_url TEXT DEFAULT NULL,
  p_utm_params JSONB DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_referrer_user_id UUID;
  v_pending_referral_id UUID;
BEGIN
  -- Get referrer user ID from code
  SELECT user_id INTO v_referrer_user_id
  FROM referral_codes
  WHERE code = p_referral_code
    AND is_active = true;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Invalid referral code'
    );
  END IF;
  
  -- Insert pending referral record
  INSERT INTO pending_referrals (
    referral_code,
    referrer_user_id,
    target_user_id,
    device_fingerprint,
    ip_address,
    user_agent,
    source_url,
    utm_params
  ) VALUES (
    p_referral_code,
    v_referrer_user_id,
    p_target_user_id,
    p_device_fingerprint,
    p_ip_address,
    p_user_agent,
    p_source_url,
    p_utm_params
  ) RETURNING id INTO v_pending_referral_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'pending_referral_id', v_pending_referral_id,
    'message', 'Referral click tracked successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Error tracking referral: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: claim_pending_referral
-- Called by app after user registration
-- =====================================================
CREATE OR REPLACE FUNCTION claim_pending_referral(
  p_new_user_id UUID,
  p_device_fingerprint TEXT DEFAULT NULL,
  p_ip_address TEXT DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_pending_referral pending_referrals%ROWTYPE;
  v_referral_code_record referral_codes%ROWTYPE;
  v_referee_bonus INT := 50;
  v_referrer_bonus INT := 50;
  v_match_method TEXT;
BEGIN
  -- Find matching pending referral (prioritize device fingerprint)
  SELECT * INTO v_pending_referral
  FROM pending_referrals
  WHERE claimed_at IS NULL
    AND expires_at > NOW()
    AND (
      -- Best match: device fingerprint
      (p_device_fingerprint IS NOT NULL AND device_fingerprint = p_device_fingerprint) OR
      -- Fallback: IP + User Agent
      (p_ip_address IS NOT NULL AND ip_address = p_ip_address AND user_agent = p_user_agent)
    )
  ORDER BY 
    -- Prioritize exact fingerprint match
    CASE 
      WHEN p_device_fingerprint IS NOT NULL AND device_fingerprint = p_device_fingerprint THEN 1
      ELSE 2 
    END,
    click_timestamp DESC
  LIMIT 1;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'No matching pending referral found'
    );
  END IF;
  
  -- Determine match method
  IF p_device_fingerprint IS NOT NULL AND v_pending_referral.device_fingerprint = p_device_fingerprint THEN
    v_match_method := 'exact_match';
  ELSE
    v_match_method := 'ip_match';
  END IF;
  
  -- Check if user already used a referral code (prevent double claiming)
  IF EXISTS (
    SELECT 1 FROM referral_usage
    WHERE referred_user_id = p_new_user_id
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'User already claimed a referral bonus'
    );
  END IF;
  
  -- Get referral code details
  SELECT * INTO v_referral_code_record
  FROM referral_codes
  WHERE code = v_pending_referral.referral_code;
  
  -- Extract rewards from JSON
  IF v_referral_code_record.rewards IS NOT NULL THEN
    v_referee_bonus := COALESCE((v_referral_code_record.rewards->>'referee_bonus')::INT, 50);
    v_referrer_bonus := COALESCE((v_referral_code_record.rewards->>'referrer_bonus')::INT, 50);
  END IF;
  
  -- Mark pending referral as claimed
  UPDATE pending_referrals
  SET claimed_at = NOW(),
      claimed_by_user_id = p_new_user_id,
      claim_method = v_match_method,
      updated_at = NOW()
  WHERE id = v_pending_referral.id;
  
  -- Record referral usage
  INSERT INTO referral_usage (
    referral_code_id,
    referrer_id,
    referred_user_id,
    spa_awarded_referrer,
    spa_awarded_referred
  ) VALUES (
    v_referral_code_record.id,
    v_pending_referral.referrer_user_id,
    p_new_user_id,
    v_referrer_bonus,
    v_referee_bonus
  );
  
  -- Update referral code usage count
  UPDATE referral_codes
  SET current_uses = current_uses + 1,
      updated_at = NOW()
  WHERE id = v_referral_code_record.id;
  
  -- Award SPA to referee (người được giới thiệu)
  UPDATE users
  SET spa_balance = COALESCE(spa_balance, 0) + v_referee_bonus
  WHERE id = p_new_user_id;
  
  -- Record transaction for referee
  INSERT INTO spa_transactions (
    user_id,
    amount,
    transaction_type,
    description,
    status
  ) VALUES (
    p_new_user_id,
    v_referee_bonus,
    'referral_bonus',
    'Thưởng giới thiệu từ ' || v_pending_referral.referral_code,
    'completed'
  );
  
  -- Award SPA to referrer (người giới thiệu)
  UPDATE users
  SET spa_balance = COALESCE(spa_balance, 0) + v_referrer_bonus
  WHERE id = v_pending_referral.referrer_user_id;
  
  -- Record transaction for referrer
  INSERT INTO spa_transactions (
    user_id,
    amount,
    transaction_type,
    description,
    status
  ) VALUES (
    v_pending_referral.referrer_user_id,
    v_referrer_bonus,
    'referral_reward',
    'Thưởng giới thiệu thành công: ' || v_pending_referral.referral_code,
    'completed'
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'referral_code', v_pending_referral.referral_code,
    'referee_bonus', v_referee_bonus,
    'referrer_bonus', v_referrer_bonus,
    'match_method', v_match_method,
    'message', 'Referral claimed successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Error claiming referral: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: cleanup_expired_pending_referrals
-- Scheduled job to clean old records (run daily)
-- =====================================================
CREATE OR REPLACE FUNCTION cleanup_expired_pending_referrals()
RETURNS JSONB AS $$
DECLARE
  v_deleted_count INT;
BEGIN
  DELETE FROM pending_referrals
  WHERE expires_at < NOW()
    AND claimed_at IS NULL;
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  
  RETURN jsonb_build_object(
    'success', true,
    'deleted_count', v_deleted_count,
    'message', 'Cleanup completed'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON TABLE pending_referrals IS 
'Track referral clicks from website to match with app registrations after install';

COMMENT ON FUNCTION track_referral_click IS 
'Called by website when user clicks QR link with referral code';

COMMENT ON FUNCTION claim_pending_referral IS 
'Called by app after user registration to claim pending referral bonus';

COMMENT ON FUNCTION cleanup_expired_pending_referrals IS 
'Scheduled cleanup of expired pending referrals (run daily)';
