-- =====================================================
-- FIX RLS POLICY FOR spa_reward_redemptions
-- Run this SQL in Supabase SQL Editor
-- =====================================================

-- 1. Drop existing policies
DROP POLICY IF EXISTS "Users can insert their own redemptions" ON spa_reward_redemptions;
DROP POLICY IF EXISTS "Users can view their own redemptions" ON spa_reward_redemptions;
DROP POLICY IF EXISTS "Club owners can view club redemptions" ON spa_reward_redemptions;

-- 2. Enable RLS
ALTER TABLE spa_reward_redemptions ENABLE ROW LEVEL SECURITY;

-- 3. Policy for INSERT: Users can insert their own redemptions
CREATE POLICY "Users can insert their own redemptions"
ON spa_reward_redemptions
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 4. Policy for SELECT: Users can view their own redemptions
CREATE POLICY "Users can view their own redemptions"
ON spa_reward_redemptions
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- 5. Policy for SELECT: Club owners can view all club redemptions
CREATE POLICY "Club owners can view club redemptions"
ON spa_reward_redemptions
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM clubs
        WHERE clubs.id = spa_reward_redemptions.club_id
        AND clubs.owner_id = auth.uid()
    )
);

-- 6. Verify policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'spa_reward_redemptions'
ORDER BY policyname;
