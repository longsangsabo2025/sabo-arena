-- Add 'used' status to spa_reward_redemptions constraint
-- Current: ('pending', 'approved', 'claimed', 'expired', 'cancelled')
-- New: ('pending', 'approved', 'claimed', 'used', 'expired', 'cancelled')

-- Step 1: Drop existing constraint
ALTER TABLE spa_reward_redemptions 
DROP CONSTRAINT IF EXISTS spa_reward_redemptions_status_check;

-- Step 2: Add new constraint with 'used' status
ALTER TABLE spa_reward_redemptions 
ADD CONSTRAINT spa_reward_redemptions_status_check 
CHECK (status IN ('pending', 'approved', 'claimed', 'used', 'expired', 'cancelled'));

-- Verify
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'spa_reward_redemptions'::regclass 
AND contype = 'c';
