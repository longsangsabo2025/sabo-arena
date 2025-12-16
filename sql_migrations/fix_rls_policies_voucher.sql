-- Fix RLS policies for spa_reward_redemptions and user_vouchers
-- This SQL needs to be run in Supabase SQL Editor

-- =====================================================
-- FIX RLS POLICY FOR spa_reward_redemptions
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can insert their own redemptions" ON spa_reward_redemptions;
DROP POLICY IF EXISTS "Users can view their own redemptions" ON spa_reward_redemptions;
DROP POLICY IF EXISTS "Club owners can view club redemptions" ON spa_reward_redemptions;

-- Enable RLS
ALTER TABLE spa_reward_redemptions ENABLE ROW LEVEL SECURITY;

-- Policy for INSERT: Users can insert their own redemptions
CREATE POLICY "Users can insert their own redemptions"
ON spa_reward_redemptions
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy for SELECT: Users can view their own redemptions
CREATE POLICY "Users can view their own redemptions"
ON spa_reward_redemptions
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy for UPDATE: Users can update their own redemptions
CREATE POLICY "Users can update their own redemptions"
ON spa_reward_redemptions
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy for club owners to view their club redemptions
CREATE POLICY "Club owners can view club redemptions"
ON spa_reward_redemptions
FOR SELECT
TO authenticated
USING (
  club_id IN (
    SELECT club_id FROM club_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  )
);

-- =====================================================
-- FIX RLS POLICY FOR user_vouchers
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own vouchers" ON user_vouchers;
DROP POLICY IF EXISTS "System can create vouchers" ON user_vouchers;
DROP POLICY IF EXISTS "Users can update their voucher status" ON user_vouchers;

-- Enable RLS
ALTER TABLE user_vouchers ENABLE ROW LEVEL SECURITY;

-- Policy for INSERT: System can create vouchers
CREATE POLICY "System can create vouchers"
ON user_vouchers
FOR INSERT
TO authenticated
WITH CHECK (true); -- Allow system to create vouchers

-- Policy for SELECT: Users can view their own vouchers
CREATE POLICY "Users can view their own vouchers"
ON user_vouchers
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy for UPDATE: Users can update their voucher status
CREATE POLICY "Users can update their voucher status"
ON user_vouchers
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy for club staff to view/manage vouchers for their club
CREATE POLICY "Club staff can manage club vouchers"
ON user_vouchers
FOR ALL
TO authenticated
USING (
  club_id IN (
    SELECT club_id FROM club_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'staff')
  )
);

-- =====================================================
-- ALLOW ANON ACCESS FOR TESTING (TEMPORARY)
-- =====================================================

-- Allow anonymous access for testing purposes
-- NOTE: Remove these in production for security

CREATE POLICY "Allow anon insert redemptions"
ON spa_reward_redemptions
FOR INSERT
TO anon
WITH CHECK (true);

CREATE POLICY "Allow anon select redemptions"
ON spa_reward_redemptions
FOR SELECT
TO anon
USING (true);

CREATE POLICY "Allow anon update redemptions"
ON spa_reward_redemptions
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow anon insert vouchers"
ON user_vouchers
FOR INSERT
TO anon
WITH CHECK (true);

CREATE POLICY "Allow anon select vouchers"
ON user_vouchers
FOR SELECT
TO anon
USING (true);

CREATE POLICY "Allow anon update vouchers"
ON user_vouchers
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- =====================================================
-- VERIFY POLICIES
-- =====================================================

SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename IN ('spa_reward_redemptions', 'user_vouchers')
ORDER BY tablename, policyname;