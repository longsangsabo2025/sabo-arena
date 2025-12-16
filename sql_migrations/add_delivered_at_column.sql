-- Add delivered_at column to spa_reward_redemptions table
-- Để track khi nào thưởng được giao cho khách hàng

-- Add delivered_at timestamp column
ALTER TABLE spa_reward_redemptions 
ADD COLUMN delivered_at TIMESTAMP WITH TIME ZONE;

-- Create index for faster queries on delivered_at
CREATE INDEX idx_spa_reward_redemptions_delivered_at 
ON spa_reward_redemptions(delivered_at);

-- Create index for status + club queries
CREATE INDEX idx_spa_reward_redemptions_status_club 
ON spa_reward_redemptions(status) 
INCLUDE (spa_reward_id);

-- Update existing delivered records with estimated delivered_at
-- (Optional - set delivered_at to redeemed_at for existing delivered records)
UPDATE spa_reward_redemptions 
SET delivered_at = redeemed_at 
WHERE status = 'delivered' AND delivered_at IS NULL;

-- Add comment to column
COMMENT ON COLUMN spa_reward_redemptions.delivered_at IS 'Timestamp when the reward was physically delivered to customer';