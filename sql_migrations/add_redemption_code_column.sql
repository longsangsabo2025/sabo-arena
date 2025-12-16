-- Add redemption_code column to spa_reward_redemptions table
-- This column stores the unique code for each redemption (for vouchers, discount codes, etc.)

ALTER TABLE spa_reward_redemptions 
ADD COLUMN IF NOT EXISTS redemption_code TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_spa_reward_redemptions_redemption_code 
ON spa_reward_redemptions(redemption_code);

-- Add comment
COMMENT ON COLUMN spa_reward_redemptions.redemption_code IS 'Unique code for this redemption (voucher code, discount code, etc.)';
