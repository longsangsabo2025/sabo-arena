-- Fix RLS policies for spa_reward_redemptions table
-- This allows authenticated users to INSERT and SELECT their own redemptions

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can insert their own redemptions" ON spa_reward_redemptions;
DROP POLICY IF EXISTS "Users can view their own redemptions" ON spa_reward_redemptions;

-- Enable RLS
ALTER TABLE spa_reward_redemptions ENABLE ROW LEVEL SECURITY;

-- Allow users to insert their own redemptions
CREATE POLICY "Users can insert their own redemptions"
ON spa_reward_redemptions FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Allow users to view their own redemptions
CREATE POLICY "Users can view their own redemptions"
ON spa_reward_redemptions FOR SELECT TO authenticated
USING (auth.uid() = user_id);
