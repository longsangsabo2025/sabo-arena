-- Fix claim_pending_referral function to use correct column names

CREATE OR REPLACE FUNCTION claim_pending_referral(
  p_new_user_id UUID,
  p_device_fingerprint TEXT DEFAULT NULL,
  p_ip_address TEXT DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_pending_referral pending_referrals%ROWTYPE;
  v_referral_code_record referral_codes%ROWTYPE;
  v_referee_bonus INT := 50;  -- Default bonus for referee
  v_referrer_bonus INT := 50; -- Default bonus for referrer
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
  
  -- Record referral usage with bonus_awarded as JSONB
  INSERT INTO referral_usage (
    referral_code_id,
    referrer_id,
    referred_user_id,
    bonus_awarded,
    status,
    used_at
  ) VALUES (
    v_referral_code_record.id,
    v_pending_referral.referrer_user_id,
    p_new_user_id,
    jsonb_build_object(
      'referee_bonus', v_referee_bonus,
      'referrer_bonus', v_referrer_bonus
    ),
    'completed',
    NOW()
  );
  
  -- Update referral code usage count
  UPDATE referral_codes
  SET current_uses = current_uses + 1,
      updated_at = NOW()
  WHERE id = v_referral_code_record.id;
  
  -- Award SPA to referee (người được giới thiệu)
  UPDATE users
  SET spa_points = COALESCE(spa_points, 0) + v_referee_bonus
  WHERE id = p_new_user_id;
  
  -- Award SPA to referrer (người giới thiệu)
  UPDATE users
  SET spa_points = COALESCE(spa_points, 0) + v_referrer_bonus
  WHERE id = v_pending_referral.referrer_user_id;
  
  -- Return success
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Pending referral claimed successfully',
    'referral_code', v_pending_referral.referral_code,
    'referee_bonus', v_referee_bonus,
    'referrer_bonus', v_referrer_bonus,
    'match_method', v_match_method
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Error claiming referral: ' || SQLERRM
    );
END;
$$;
