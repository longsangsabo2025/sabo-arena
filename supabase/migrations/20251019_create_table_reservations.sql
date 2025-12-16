-- =====================================================
-- TABLE RESERVATION SYSTEM
-- Created: 2025-10-19
-- Purpose: Enable table booking functionality for clubs
-- =====================================================

-- =====================================================
-- 1. CREATE TABLE: table_reservations
-- =====================================================
CREATE TABLE IF NOT EXISTS public.table_reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  table_number INT NOT NULL,
  
  -- Thời gian đặt
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  duration_hours DECIMAL(3,1) NOT NULL,
  
  -- Giá cả
  price_per_hour DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  deposit_amount DECIMAL(10,2) DEFAULT 0,
  
  -- Trạng thái
  status VARCHAR(20) DEFAULT 'pending' NOT NULL,
  -- Status: pending, confirmed, cancelled, completed, no_show
  payment_status VARCHAR(20) DEFAULT 'unpaid' NOT NULL,
  -- Payment Status: unpaid, deposit_paid, fully_paid, refunded
  payment_method VARCHAR(50),
  payment_transaction_id VARCHAR(255),
  
  -- Thông tin bổ sung
  notes TEXT,
  special_requests TEXT,
  number_of_players INT DEFAULT 2,
  
  -- Xác nhận và hủy
  confirmed_at TIMESTAMPTZ,
  confirmed_by UUID REFERENCES auth.users(id),
  cancelled_at TIMESTAMPTZ,
  cancelled_by UUID REFERENCES auth.users(id),
  cancellation_reason TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT valid_time_range CHECK (end_time > start_time),
  CONSTRAINT valid_duration CHECK (duration_hours > 0 AND duration_hours <= 24),
  CONSTRAINT valid_table_number CHECK (table_number > 0),
  CONSTRAINT valid_status CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'no_show')),
  CONSTRAINT valid_payment_status CHECK (payment_status IN ('unpaid', 'deposit_paid', 'fully_paid', 'refunded'))
);

-- =====================================================
-- 2. CREATE TABLE: table_availability
-- =====================================================
CREATE TABLE IF NOT EXISTS public.table_availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
  table_number INT NOT NULL,
  date DATE NOT NULL,
  time_slot TIME NOT NULL,
  is_available BOOLEAN DEFAULT true,
  reason VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  CONSTRAINT valid_table_number_availability CHECK (table_number > 0),
  UNIQUE(club_id, table_number, date, time_slot)
);

-- =====================================================
-- 3. CREATE INDEXES for Performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_reservations_club_id ON public.table_reservations(club_id);
CREATE INDEX IF NOT EXISTS idx_reservations_user_id ON public.table_reservations(user_id);
CREATE INDEX IF NOT EXISTS idx_reservations_time_range ON public.table_reservations(start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_reservations_status ON public.table_reservations(status);
CREATE INDEX IF NOT EXISTS idx_reservations_payment_status ON public.table_reservations(payment_status);
CREATE INDEX IF NOT EXISTS idx_reservations_club_start_time ON public.table_reservations(club_id, start_time);

CREATE INDEX IF NOT EXISTS idx_availability_club_date ON public.table_availability(club_id, date);
CREATE INDEX IF NOT EXISTS idx_availability_club_table ON public.table_availability(club_id, table_number);

-- =====================================================
-- 4. CREATE FUNCTION: update_updated_at_column
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. CREATE TRIGGERS
-- =====================================================
CREATE TRIGGER update_table_reservations_updated_at
  BEFORE UPDATE ON public.table_reservations
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_table_availability_updated_at
  BEFORE UPDATE ON public.table_availability
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- 6. ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE public.table_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.table_availability ENABLE ROW LEVEL SECURITY;

-- RLS Policies for table_reservations

-- Policy: Users can view their own reservations
CREATE POLICY "Users can view own reservations"
  ON public.table_reservations
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Club owners can view all reservations for their clubs
CREATE POLICY "Club owners can view club reservations"
  ON public.table_reservations
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.clubs
      WHERE clubs.id = table_reservations.club_id
      AND clubs.owner_id = auth.uid()
    )
  );

-- Policy: Users can create reservations
CREATE POLICY "Users can create reservations"
  ON public.table_reservations
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own pending reservations (cancel only)
CREATE POLICY "Users can update own reservations"
  ON public.table_reservations
  FOR UPDATE
  USING (auth.uid() = user_id AND status = 'pending')
  WITH CHECK (auth.uid() = user_id);

-- Policy: Club owners can update reservations for their clubs
CREATE POLICY "Club owners can update club reservations"
  ON public.table_reservations
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.clubs
      WHERE clubs.id = table_reservations.club_id
      AND clubs.owner_id = auth.uid()
    )
  );

-- RLS Policies for table_availability

-- Policy: Everyone can view table availability
CREATE POLICY "Anyone can view table availability"
  ON public.table_availability
  FOR SELECT
  USING (true);

-- Policy: Club owners can manage availability for their clubs
CREATE POLICY "Club owners can manage availability"
  ON public.table_availability
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.clubs
      WHERE clubs.id = table_availability.club_id
      AND clubs.owner_id = auth.uid()
    )
  );

-- =====================================================
-- 7. CREATE VIEW: reservation_details
-- =====================================================
CREATE OR REPLACE VIEW public.reservation_details AS
SELECT 
  r.id,
  r.club_id,
  r.user_id,
  r.table_number,
  r.start_time,
  r.end_time,
  r.duration_hours,
  r.price_per_hour,
  r.total_price,
  r.deposit_amount,
  r.status,
  r.payment_status,
  r.payment_method,
  r.notes,
  r.special_requests,
  r.number_of_players,
  r.confirmed_at,
  r.cancelled_at,
  r.cancellation_reason,
  r.created_at,
  r.updated_at,
  -- Club info
  c.name as club_name,
  c.address as club_address,
  c.phone as club_phone,
  c.profile_image_url as club_image,
  -- User info (from public.users if exists, otherwise from auth.users)
  COALESCE(u.full_name, u.display_name, au.email) as user_name,
  COALESCE(u.phone_number, '') as user_phone,
  au.email as user_email
FROM public.table_reservations r
LEFT JOIN public.clubs c ON r.club_id = c.id
LEFT JOIN auth.users au ON r.user_id = au.id
LEFT JOIN public.users u ON r.user_id = u.id;

-- Grant access to view
GRANT SELECT ON public.reservation_details TO authenticated;

-- =====================================================
-- 8. HELPER FUNCTIONS
-- =====================================================

-- Function: Check if table is available
CREATE OR REPLACE FUNCTION public.is_table_available(
  p_club_id UUID,
  p_table_number INT,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ
)
RETURNS BOOLEAN AS $$
DECLARE
  conflict_count INT;
BEGIN
  -- Check for overlapping reservations
  SELECT COUNT(*) INTO conflict_count
  FROM public.table_reservations
  WHERE club_id = p_club_id
    AND table_number = p_table_number
    AND status NOT IN ('cancelled', 'no_show')
    AND (
      (start_time <= p_start_time AND end_time > p_start_time) OR
      (start_time < p_end_time AND end_time >= p_end_time) OR
      (start_time >= p_start_time AND end_time <= p_end_time)
    );
  
  RETURN conflict_count = 0;
END;
$$ LANGUAGE plpgsql;

-- Function: Get available tables for a time slot
CREATE OR REPLACE FUNCTION public.get_available_tables(
  p_club_id UUID,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ
)
RETURNS TABLE(table_number INT) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT t.table_num
  FROM generate_series(1, (SELECT total_tables FROM public.clubs WHERE id = p_club_id)) t(table_num)
  WHERE public.is_table_available(p_club_id, t.table_num, p_start_time, p_end_time);
END;
$$ LANGUAGE plpgsql;

-- Function: Auto-cancel expired pending reservations
CREATE OR REPLACE FUNCTION public.auto_cancel_expired_reservations()
RETURNS void AS $$
BEGIN
  UPDATE public.table_reservations
  SET 
    status = 'cancelled',
    cancelled_at = NOW(),
    cancellation_reason = 'Auto-cancelled: Payment timeout'
  WHERE status = 'pending'
    AND payment_status = 'unpaid'
    AND created_at < NOW() - INTERVAL '30 minutes';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 9. COMMENTS
-- =====================================================
COMMENT ON TABLE public.table_reservations IS 'Stores all table reservation bookings';
COMMENT ON TABLE public.table_availability IS 'Manages table availability schedules';
COMMENT ON FUNCTION public.is_table_available IS 'Checks if a specific table is available for a time range';
COMMENT ON FUNCTION public.get_available_tables IS 'Returns list of available tables for a given time slot';
COMMENT ON FUNCTION public.auto_cancel_expired_reservations IS 'Auto-cancels reservations that were not paid within 30 minutes';

-- =====================================================
-- 10. INITIAL DATA (Optional)
-- =====================================================
-- You can add sample data here if needed for testing

-- =====================================================
-- Migration Complete
-- =====================================================
