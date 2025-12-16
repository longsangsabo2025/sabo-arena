-- Fix user_vouchers status constraint to support pending_approval
-- This script updates the check constraint to allow pending_approval status

-- First check current constraint
SELECT conname, consrc 
FROM pg_constraint 
WHERE conname = 'user_vouchers_status_check';

-- Update the constraint to include pending_approval
ALTER TABLE user_vouchers 
DROP CONSTRAINT IF EXISTS user_vouchers_status_check;

ALTER TABLE user_vouchers 
ADD CONSTRAINT user_vouchers_status_check 
CHECK (status IN ('active', 'used', 'expired', 'cancelled', 'pending_approval'));

-- Verify the update
SELECT conname, consrc 
FROM pg_constraint 
WHERE conname = 'user_vouchers_status_check';