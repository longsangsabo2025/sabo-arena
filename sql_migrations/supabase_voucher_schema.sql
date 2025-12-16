-- 🎯 CHUYÊN GIA 20 NĂM: VOUCHER MANAGEMENT DATABASE SCHEMA
-- Professional approach: Separate voucher workflow from notification system

-- ===============================================================
-- 1. CLUB VOUCHER REQUESTS - Core business table
-- ===============================================================
CREATE TABLE IF NOT EXISTS club_voucher_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Voucher Information
  voucher_id UUID NOT NULL REFERENCES user_vouchers(id) ON DELETE CASCADE,
  voucher_code VARCHAR(50) NOT NULL,
  
  -- User Information  
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user_email VARCHAR(255) NOT NULL,
  user_name VARCHAR(100),
  
  -- Club Information
  club_id UUID NOT NULL,
  requested_to_club_name VARCHAR(100),
  
  -- Business Logic
  spa_value INTEGER NOT NULL CHECK (spa_value > 0),
  voucher_type VARCHAR(50) NOT NULL DEFAULT 'spa_redemption',
  
  -- Workflow Status
  status VARCHAR(20) NOT NULL DEFAULT 'pending' 
    CHECK (status IN ('pending', 'approved', 'rejected', 'expired', 'cancelled')),
  
  -- Timestamps
  requested_at TIMESTAMP DEFAULT NOW(),
  processed_at TIMESTAMP,
  expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '7 days'),
  
  -- Processing Information
  processed_by UUID, -- Club manager who processed
  rejection_reason TEXT,
  approval_notes TEXT,
  
  -- Audit Trail
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(voucher_id, club_id) -- Prevent duplicate requests
);

-- ===============================================================
-- 2. CLUB VOUCHER CONFIGURATIONS - Business rules per club
-- ===============================================================  
CREATE TABLE IF NOT EXISTS club_voucher_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id UUID NOT NULL UNIQUE,
  
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
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ===============================================================
-- 3. VOUCHER REQUEST AUDIT LOG - Complete audit trail
-- ===============================================================
CREATE TABLE IF NOT EXISTS voucher_request_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES club_voucher_requests(id) ON DELETE CASCADE,
  
  -- Change tracking
  old_status VARCHAR(20),
  new_status VARCHAR(20) NOT NULL,
  changed_by UUID,
  change_reason TEXT,
  
  -- Metadata
  ip_address INET,
  user_agent TEXT,
  
  -- Timestamp
  created_at TIMESTAMP DEFAULT NOW()
);

-- ===============================================================
-- 4. PERFORMANCE INDEXES
-- ===============================================================
CREATE INDEX IF NOT EXISTS idx_club_voucher_requests_club_id ON club_voucher_requests(club_id);
CREATE INDEX IF NOT EXISTS idx_club_voucher_requests_user_id ON club_voucher_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_club_voucher_requests_status ON club_voucher_requests(status);
CREATE INDEX IF NOT EXISTS idx_club_voucher_requests_requested_at ON club_voucher_requests(requested_at);
CREATE INDEX IF NOT EXISTS idx_club_voucher_requests_expires_at ON club_voucher_requests(expires_at);
CREATE INDEX IF NOT EXISTS idx_voucher_request_audit_request_id ON voucher_request_audit(request_id);
CREATE INDEX IF NOT EXISTS idx_club_voucher_requests_voucher_id ON club_voucher_requests(voucher_id);

-- ===============================================================
-- 5. BUSINESS LOGIC FUNCTIONS
-- ===============================================================

-- Auto-expire old requests
CREATE OR REPLACE FUNCTION auto_expire_voucher_requests()
RETURNS INTEGER AS $$
DECLARE
  expired_count INTEGER;
BEGIN
  UPDATE club_voucher_requests 
  SET status = 'expired', 
      updated_at = NOW()
  WHERE status = 'pending' 
    AND expires_at < NOW();
    
  GET DIAGNOSTICS expired_count = ROW_COUNT;
  RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- Analytics function for clubs
CREATE OR REPLACE FUNCTION get_voucher_analytics(
  club_id_param UUID,
  from_date TIMESTAMP DEFAULT (NOW() - INTERVAL '30 days'),
  to_date TIMESTAMP DEFAULT NOW()
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_requests', (
      SELECT COUNT(*) FROM club_voucher_requests 
      WHERE club_id = club_id_param 
        AND requested_at BETWEEN from_date AND to_date
    ),
    'approved_requests', (
      SELECT COUNT(*) FROM club_voucher_requests 
      WHERE club_id = club_id_param 
        AND status = 'approved'
        AND requested_at BETWEEN from_date AND to_date
    ),
    'rejected_requests', (
      SELECT COUNT(*) FROM club_voucher_requests 
      WHERE club_id = club_id_param 
        AND status = 'rejected'
        AND requested_at BETWEEN from_date AND to_date
    ),
    'pending_requests', (
      SELECT COUNT(*) FROM club_voucher_requests 
      WHERE club_id = club_id_param 
        AND status = 'pending'
    ),
    'total_spa_value', (
      SELECT COALESCE(SUM(spa_value), 0) FROM club_voucher_requests 
      WHERE club_id = club_id_param 
        AND status = 'approved'
        AND requested_at BETWEEN from_date AND to_date
    ),
    'avg_processing_time', (
      SELECT EXTRACT(EPOCH FROM AVG(processed_at - requested_at))/3600
      FROM club_voucher_requests 
      WHERE club_id = club_id_param 
        AND status IN ('approved', 'rejected')
        AND requested_at BETWEEN from_date AND to_date
        AND processed_at IS NOT NULL
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ===============================================================
-- 6. TRIGGERS FOR AUDIT TRAIL
-- ===============================================================
CREATE OR REPLACE FUNCTION audit_voucher_request_changes()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    INSERT INTO voucher_request_audit (
      request_id, old_status, new_status, changed_by, created_at
    ) VALUES (
      NEW.id, OLD.status, NEW.status, NEW.processed_by, NOW()
    );
  END IF;
  
  -- Update timestamp
  NEW.updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER IF NOT EXISTS trigger_audit_voucher_requests
  BEFORE UPDATE ON club_voucher_requests
  FOR EACH ROW EXECUTE FUNCTION audit_voucher_request_changes();

-- ===============================================================
-- 7. CLEANUP AND MAINTENANCE
-- ===============================================================

-- Archive old requests (run daily via cron)
CREATE OR REPLACE FUNCTION cleanup_old_voucher_requests()
RETURNS INTEGER AS $$
DECLARE
  archived_count INTEGER;
BEGIN
  -- Move old completed requests to archive table (if needed)
  -- For now, just delete old audit logs to keep table lean
  DELETE FROM voucher_request_audit 
  WHERE created_at < NOW() - INTERVAL '90 days';
  
  GET DIAGNOSTICS archived_count = ROW_COUNT;
  RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- ===============================================================
-- 8. SAMPLE DATA FOR TESTING (Optional)
-- ===============================================================

-- Insert sample club config
-- INSERT INTO club_voucher_configs (club_id, auto_approve_enabled, auto_approve_max_value) 
-- VALUES ('sample-club-uuid', true, 500);

-- ===============================================================
-- MIGRATION NOTES:
-- ===============================================================
-- 1. Run this schema in your Supabase SQL editor
-- 2. Update your Flutter service to use ClubVoucherManagementService
-- 3. Migrate existing notification-based voucher requests (if any)
-- 4. Set up RLS policies for security
-- 5. Create cron job for auto_expire_voucher_requests()
-- 6. Add monitoring for voucher request volume and processing times