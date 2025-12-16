-- =====================================================
-- TOURNAMENT PRIZE VOUCHER SYSTEM
-- Hệ thống voucher giải thưởng giải đấu
-- =====================================================

-- 1. Bảng link giải đấu với voucher template
CREATE TABLE IF NOT EXISTS tournament_prize_vouchers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Tournament info
  tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
  
  -- Prize position
  position INTEGER NOT NULL, -- 1 = Nhất, 2 = Nhì, 3 = Ba
  position_label TEXT, -- "NHẤT", "NHÌ", "BA", "TOP 4-8"
  
  -- Voucher config
  voucher_value DECIMAL(10,2) NOT NULL, -- 700000, 500000, 300000, 200000, 100000
  voucher_code_prefix TEXT DEFAULT 'PRIZE', -- PRIZE-BILLIARD-NHẤT-0111
  voucher_description TEXT,
  
  -- Validity
  valid_days INTEGER DEFAULT 30, -- Voucher hết hạn sau 30 ngày
  
  -- Status
  is_issued BOOLEAN DEFAULT false, -- Đã phát voucher chưa
  issued_at TIMESTAMPTZ,
  issued_by UUID REFERENCES auth.users(id),
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_prize_position CHECK (position > 0)
);

-- 2. Extend user_vouchers để support tournament prizes
-- (Table này đã tồn tại, chỉ cần thêm columns)
ALTER TABLE user_vouchers 
  ADD COLUMN IF NOT EXISTS voucher_value DECIMAL(10,2), -- Mệnh giá voucher
  ADD COLUMN IF NOT EXISTS tournament_id UUID REFERENCES tournaments(id),
  ADD COLUMN IF NOT EXISTS prize_position INTEGER,
  ADD COLUMN IF NOT EXISTS can_use_for_table_payment BOOLEAN DEFAULT true;

-- 3. Table payment history with voucher
CREATE TABLE IF NOT EXISTS table_voucher_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Reservation info
  reservation_id UUID, -- Link to table_reservations nếu có
  club_id UUID REFERENCES clubs(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Table session info
  table_number INTEGER NOT NULL,
  session_start_time TIMESTAMPTZ NOT NULL,
  session_end_time TIMESTAMPTZ,
  duration_hours DECIMAL(5,2),
  
  -- Payment info
  original_amount DECIMAL(10,2) NOT NULL, -- Tiền bàn gốc
  voucher_id UUID REFERENCES user_vouchers(id) ON DELETE SET NULL,
  voucher_code TEXT NOT NULL,
  voucher_discount DECIMAL(10,2) NOT NULL, -- Số tiền voucher trừ
  final_amount DECIMAL(10,2) NOT NULL, -- Số tiền phải trả sau khi dùng voucher
  
  -- Payment method for remaining
  remaining_payment_method TEXT, -- 'cash', 'bank_transfer', 'momo', etc.
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'cancelled')),
  
  -- Timestamps
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_payment_amounts CHECK (
    voucher_discount >= 0 AND 
    final_amount >= 0 AND
    original_amount >= voucher_discount
  )
);

-- 4. Create indexes
CREATE INDEX IF NOT EXISTS idx_tournament_prize_vouchers_tournament 
  ON tournament_prize_vouchers(tournament_id);

CREATE INDEX IF NOT EXISTS idx_tournament_prize_vouchers_position 
  ON tournament_prize_vouchers(tournament_id, position);

CREATE INDEX IF NOT EXISTS idx_user_vouchers_tournament 
  ON user_vouchers(tournament_id, user_id);

CREATE INDEX IF NOT EXISTS idx_table_voucher_payments_club_user 
  ON table_voucher_payments(club_id, user_id);

CREATE INDEX IF NOT EXISTS idx_table_voucher_payments_voucher 
  ON table_voucher_payments(voucher_id);

-- 5. Function: Issue tournament prize vouchers tự động
CREATE OR REPLACE FUNCTION issue_tournament_prize_vouchers(
  p_tournament_id UUID,
  p_user_id UUID,
  p_position INTEGER
)
RETURNS JSONB AS $$
DECLARE
  v_prize_config RECORD;
  v_voucher_code TEXT;
  v_voucher_id UUID;
  v_tournament_title TEXT;
  v_club_id UUID;
BEGIN
  -- Get tournament info
  SELECT title, club_id INTO v_tournament_title, v_club_id
  FROM tournaments WHERE id = p_tournament_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Tournament not found';
  END IF;
  
  -- Get prize voucher config
  SELECT * INTO v_prize_config
  FROM tournament_prize_vouchers
  WHERE tournament_id = p_tournament_id
    AND position = p_position;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No voucher config for position %', p_position;
  END IF;
  
  -- Generate voucher code: PRIZE-BILLIARD-NHẤT-0111
  v_voucher_code := v_prize_config.voucher_code_prefix || '-' || 
                    v_prize_config.position_label || '-' || 
                    TO_CHAR(NOW(), 'MMDD') || '-' ||
                    SUBSTRING(gen_random_uuid()::TEXT, 1, 4);
  
  -- Create user voucher
  INSERT INTO user_vouchers (
    user_id,
    voucher_code,
    voucher_value,
    status,
    rewards,
    expires_at,
    tournament_id,
    prize_position,
    can_use_for_table_payment
  ) VALUES (
    p_user_id,
    v_voucher_code,
    v_prize_config.voucher_value,
    'active',
    jsonb_build_object(
      'discount_amount', v_prize_config.voucher_value,
      'description', 'Giải thưởng ' || v_prize_config.position_label || ' - ' || v_tournament_title
    ),
    NOW() + INTERVAL '1 day' * v_prize_config.valid_days,
    p_tournament_id,
    p_position,
    true
  )
  RETURNING id INTO v_voucher_id;
  
  -- Mark as issued
  UPDATE tournament_prize_vouchers
  SET is_issued = true,
      issued_at = NOW()
  WHERE tournament_id = p_tournament_id
    AND position = p_position;
  
  RETURN jsonb_build_object(
    'success', true,
    'voucher_id', v_voucher_id,
    'voucher_code', v_voucher_code,
    'voucher_value', v_prize_config.voucher_value,
    'expires_at', NOW() + INTERVAL '1 day' * v_prize_config.valid_days
  );
END;
$$ LANGUAGE plpgsql;

-- 6. Function: Apply voucher to table payment
CREATE OR REPLACE FUNCTION apply_voucher_to_table_payment(
  p_user_id UUID,
  p_club_id UUID,
  p_voucher_code TEXT,
  p_original_amount DECIMAL,
  p_table_number INTEGER,
  p_session_start TIMESTAMPTZ,
  p_session_end TIMESTAMPTZ DEFAULT NOW()
)
RETURNS JSONB AS $$
DECLARE
  v_voucher RECORD;
  v_discount DECIMAL;
  v_final_amount DECIMAL;
  v_payment_id UUID;
  v_duration DECIMAL;
BEGIN
  -- Get voucher
  SELECT * INTO v_voucher
  FROM user_vouchers
  WHERE voucher_code = p_voucher_code
    AND user_id = p_user_id
    AND status = 'active'
    AND can_use_for_table_payment = true
    AND (expires_at IS NULL OR expires_at > NOW());
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Voucher không hợp lệ hoặc đã hết hạn';
  END IF;
  
  -- Calculate discount
  v_discount := LEAST(v_voucher.voucher_value, p_original_amount);
  v_final_amount := GREATEST(0, p_original_amount - v_discount);
  
  -- Calculate duration
  v_duration := EXTRACT(EPOCH FROM (p_session_end - p_session_start)) / 3600.0;
  
  -- Create payment record
  INSERT INTO table_voucher_payments (
    club_id,
    user_id,
    table_number,
    session_start_time,
    session_end_time,
    duration_hours,
    original_amount,
    voucher_id,
    voucher_code,
    voucher_discount,
    final_amount,
    payment_status,
    paid_at
  ) VALUES (
    p_club_id,
    p_user_id,
    p_table_number,
    p_session_start,
    p_session_end,
    v_duration,
    p_original_amount,
    v_voucher.id,
    p_voucher_code,
    v_discount,
    v_final_amount,
    'completed',
    NOW()
  )
  RETURNING id INTO v_payment_id;
  
  -- Mark voucher as used
  UPDATE user_vouchers
  SET status = 'used',
      used_at = NOW(),
      updated_at = NOW()
  WHERE id = v_voucher.id;
  
  RETURN jsonb_build_object(
    'success', true,
    'payment_id', v_payment_id,
    'original_amount', p_original_amount,
    'voucher_discount', v_discount,
    'final_amount', v_final_amount,
    'voucher_value_remaining', v_voucher.voucher_value - v_discount
  );
END;
$$ LANGUAGE plpgsql;

-- 7. RLS Policies
ALTER TABLE tournament_prize_vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE table_voucher_payments ENABLE ROW LEVEL SECURITY;

-- Users can view prize vouchers của giải đấu họ tham gia
CREATE POLICY "Users can view tournament prize vouchers"
  ON tournament_prize_vouchers FOR SELECT
  USING (
    tournament_id IN (
      SELECT tournament_id FROM tournament_participants 
      WHERE user_id = auth.uid()
    )
  );

-- Club owners can manage prize vouchers
CREATE POLICY "Club owners can manage prize vouchers"
  ON tournament_prize_vouchers FOR ALL
  USING (
    tournament_id IN (
      SELECT id FROM tournaments 
      WHERE club_id IN (
        SELECT id FROM clubs WHERE owner_id = auth.uid()
      )
    )
  );

-- Users can view their own table payments
CREATE POLICY "Users can view their table payments"
  ON table_voucher_payments FOR SELECT
  USING (user_id = auth.uid());

-- Club owners can view their club's table payments
CREATE POLICY "Club owners can view club table payments"
  ON table_voucher_payments FOR SELECT
  USING (
    club_id IN (
      SELECT id FROM clubs WHERE owner_id = auth.uid()
    )
  );

-- Users can create table payments
CREATE POLICY "Users can create table payments"
  ON table_voucher_payments FOR INSERT
  WITH CHECK (user_id = auth.uid());

COMMENT ON TABLE tournament_prize_vouchers IS 'Cấu hình voucher giải thưởng cho từng vị trí trong giải đấu';
COMMENT ON TABLE table_voucher_payments IS 'Lịch sử thanh toán tiền bàn bằng voucher';
COMMENT ON FUNCTION issue_tournament_prize_vouchers IS 'Tự động phát voucher cho user thắng giải';
COMMENT ON FUNCTION apply_voucher_to_table_payment IS 'Áp dụng voucher để thanh toán tiền bàn';
