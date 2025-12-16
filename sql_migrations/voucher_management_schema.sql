-- CHUYÊN GIA 20 NĂM: VOUCHER MANAGEMENT SYSTEM DESIGN
-- Tách biệt hoàn toàn voucher workflow khỏi notification system

-- 1. CLUB VOUCHER REQUESTS TABLE
CREATE TABLE club_voucher_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Voucher Information
  voucher_id UUID NOT NULL REFERENCES user_vouchers(id) ON DELETE CASCADE,
  voucher_code VARCHAR(50) NOT NULL,
  
  -- User Information  
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user_email VARCHAR(255) NOT NULL,
  user_name VARCHAR(100),
  
  -- Club Information
  club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  requested_to_club_name VARCHAR(100),
  
  -- Business Logic
  spa_value INTEGER NOT NULL CHECK (spa_value > 0),
  voucher_type VARCHAR(50) NOT NULL DEFAULT 'spa_redemption',
  
  -- Workflow Status
  status VARCHAR(20) NOT NULL DEFAULT 'pending' 
    CHECK (status IN ('pending', 'approved', 'rejected', 'expired', 'cancelled')),
  
  -- Timestamps
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
  
  -- Processing Information
  processed_by UUID REFERENCES profiles(id), -- Club manager who processed
  rejection_reason TEXT,
  approval_notes TEXT,
  
  -- Audit Trail
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(voucher_id, club_id) -- Prevent duplicate requests
);

-- 2. CLUB VOUCHER CONFIGURATIONS TABLE  
CREATE TABLE club_voucher_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  
  -- Auto-approval settings
  auto_approve_enabled BOOLEAN DEFAULT false,
  auto_approve_max_value INTEGER DEFAULT 1000, -- Max SPA value for auto-approval
  
  -- Business hours
  business_hours_only BOOLEAN DEFAULT true,
  business_start_time TIME DEFAULT '08:00:00',
  business_end_time TIME DEFAULT '22:00:00',
  
  -- Request limits
  max_requests_per_day INTEGER DEFAULT 50,
  max_requests_per_user_per_day INTEGER DEFAULT 3,
  
  -- Notification preferences
  email_notifications BOOLEAN DEFAULT true,
  sms_notifications BOOLEAN DEFAULT false,
  push_notifications BOOLEAN DEFAULT true,
  
  -- Audit
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(club_id)
);

-- 3. VOUCHER REQUEST AUDIT LOG
CREATE TABLE voucher_request_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES club_voucher_requests(id) ON DELETE CASCADE,
  
  -- Change tracking
  old_status VARCHAR(20),
  new_status VARCHAR(20) NOT NULL,
  changed_by UUID REFERENCES profiles(id),
  change_reason TEXT,
  
  -- Metadata
  ip_address INET,
  user_agent TEXT,
  
  -- Timestamp
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. INDEXES FOR PERFORMANCE
CREATE INDEX idx_club_voucher_requests_club_id ON club_voucher_requests(club_id);
CREATE INDEX idx_club_voucher_requests_user_id ON club_voucher_requests(user_id);
CREATE INDEX idx_club_voucher_requests_status ON club_voucher_requests(status);
CREATE INDEX idx_club_voucher_requests_requested_at ON club_voucher_requests(requested_at);
CREATE INDEX idx_club_voucher_requests_expires_at ON club_voucher_requests(expires_at);
CREATE INDEX idx_voucher_request_audit_request_id ON voucher_request_audit(request_id);

-- 5. RLS POLICIES (Row Level Security)
ALTER TABLE club_voucher_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_voucher_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE voucher_request_audit ENABLE ROW LEVEL SECURITY;

-- Club managers can see their club's requests
CREATE POLICY "Club managers can view their requests" ON club_voucher_requests
  FOR SELECT USING (
    club_id IN (
      SELECT club_id FROM club_managers 
      WHERE user_id = auth.uid()
    )
  );

-- Users can see their own requests
CREATE POLICY "Users can view their own requests" ON club_voucher_requests
  FOR SELECT USING (user_id = auth.uid());

-- 6. FUNCTIONS FOR BUSINESS LOGIC
CREATE OR REPLACE FUNCTION auto_expire_voucher_requests()
RETURNS void AS $$
BEGIN
  UPDATE club_voucher_requests 
  SET status = 'expired', 
      updated_at = NOW()
  WHERE status = 'pending' 
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- 7. TRIGGERS
CREATE OR REPLACE FUNCTION audit_voucher_request_changes()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    INSERT INTO voucher_request_audit (
      request_id, old_status, new_status, changed_by, created_at
    ) VALUES (
      NEW.id, OLD.status, NEW.status, auth.uid(), NOW()
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_audit_voucher_requests
  AFTER UPDATE ON club_voucher_requests
  FOR EACH ROW EXECUTE FUNCTION audit_voucher_request_changes();

-- 8. CLEANUP JOB (Run daily)
CREATE OR REPLACE FUNCTION cleanup_old_voucher_requests()
RETURNS void AS $$
BEGIN
  -- Archive old completed requests (older than 30 days)
  DELETE FROM club_voucher_requests 
  WHERE status IN ('approved', 'rejected', 'expired', 'cancelled')
    AND updated_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;