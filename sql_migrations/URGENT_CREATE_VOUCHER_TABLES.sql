-- 🚨 URGENT: PROFESSIONAL VOUCHER SYSTEM IMPLEMENTATION
-- Run this in Supabase SQL Editor to create proper voucher tables

-- 1. Create club_voucher_requests table
CREATE TABLE club_voucher_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Voucher Information
  voucher_id UUID NOT NULL REFERENCES user_vouchers(id) ON DELETE CASCADE,
  voucher_code VARCHAR(50) NOT NULL,
  
  -- User Information  
  user_id UUID NOT NULL,
  user_email VARCHAR(255) NOT NULL,
  user_name VARCHAR(100),
  
  -- Club Information
  club_id UUID NOT NULL,
  
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
  processed_by UUID,
  rejection_reason TEXT,
  approval_notes TEXT,
  
  -- Audit Trail
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(voucher_id, club_id)
);

-- 2. Create club_voucher_configs table
CREATE TABLE club_voucher_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id UUID NOT NULL UNIQUE,
  
  -- Auto-approval settings
  auto_approve_enabled BOOLEAN DEFAULT false,
  auto_approve_max_value INTEGER DEFAULT 1000,
  
  -- Request limits
  max_requests_per_day INTEGER DEFAULT 50,
  max_requests_per_user_per_day INTEGER DEFAULT 3,
  
  -- Notifications
  email_notifications BOOLEAN DEFAULT true,
  push_notifications BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. Create voucher_request_audit table
CREATE TABLE voucher_request_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES club_voucher_requests(id) ON DELETE CASCADE,
  
  old_status VARCHAR(20),
  new_status VARCHAR(20) NOT NULL,
  changed_by UUID,
  change_reason TEXT,
  
  created_at TIMESTAMP DEFAULT NOW()
);

-- 4. Create indexes for performance
CREATE INDEX idx_club_voucher_requests_club_id ON club_voucher_requests(club_id);
CREATE INDEX idx_club_voucher_requests_user_id ON club_voucher_requests(user_id);
CREATE INDEX idx_club_voucher_requests_status ON club_voucher_requests(status);
CREATE INDEX idx_club_voucher_requests_requested_at ON club_voucher_requests(requested_at);

-- 5. Create audit trigger
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
  
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_audit_voucher_requests
  BEFORE UPDATE ON club_voucher_requests
  FOR EACH ROW EXECUTE FUNCTION audit_voucher_request_changes();

-- 6. Insert sample config for existing club
INSERT INTO club_voucher_configs (club_id, auto_approve_enabled, auto_approve_max_value) 
VALUES ('dde4b08a-bece-4304-ad2b-fd5dec658b3f', false, 500)
ON CONFLICT (club_id) DO NOTHING;

-- SUCCESS: Professional voucher tables created!
SELECT 'VOUCHER TABLES CREATED SUCCESSFULLY!' as status;