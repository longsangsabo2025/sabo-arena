-- Fix user_vouchers status enum to include pending_approval

-- Step 1: Drop the existing constraint
ALTER TABLE public.user_vouchers DROP CONSTRAINT IF EXISTS user_vouchers_status_check;

-- Step 2: Add new constraint with pending_approval
ALTER TABLE public.user_vouchers 
ADD CONSTRAINT user_vouchers_status_check 
CHECK (status IN ('active', 'used', 'expired', 'cancelled', 'pending_approval'));

-- Step 3: Update any existing spa_reward_redemptions with status to use the new enum
-- (if this table exists and has status column)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='spa_reward_redemptions') AND
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='spa_reward_redemptions' AND column_name='status') THEN
        
        -- Update any pending status to pending_approval
        UPDATE spa_reward_redemptions 
        SET status = 'pending_approval' 
        WHERE status = 'pending';
        
    END IF;
END $$;

-- Verify the changes
SELECT 'Status constraint updated successfully' as message;