-- ===================================================================
-- 🔧 FIX CRITICAL: Add RLS Policies for elo_history and spa_transactions
-- ===================================================================
-- Problem: Users cannot insert into elo_history and spa_transactions
-- Reason: RLS is enabled but no INSERT policies exist
-- Impact: Tournament rewards audit trail is LOST
-- ===================================================================

-- ============================================
-- 1. ELO_HISTORY POLICIES
-- ============================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "elo_history_insert_policy" ON elo_history;
DROP POLICY IF EXISTS "elo_history_select_policy" ON elo_history;

-- Allow users to view their own ELO history
CREATE POLICY "elo_history_select_policy"
ON elo_history
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
);

-- Allow authenticated users to insert ELO history records
-- This is needed for tournament completion service
CREATE POLICY "elo_history_insert_policy"
ON elo_history
FOR INSERT
TO authenticated
WITH CHECK (true);  -- Allow all authenticated users to insert

-- Note: We use 'WITH CHECK (true)' because the service needs to insert
-- ELO history for ALL tournament participants, not just the current user

-- ============================================
-- 2. SPA_TRANSACTIONS POLICIES
-- ============================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "spa_transactions_insert_policy" ON spa_transactions;
DROP POLICY IF EXISTS "spa_transactions_select_policy" ON spa_transactions;

-- Allow users to view their own SPA transactions
CREATE POLICY "spa_transactions_select_policy"
ON spa_transactions
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
);

-- Allow authenticated users to insert SPA transaction records
-- This is needed for tournament completion service
CREATE POLICY "spa_transactions_insert_policy"
ON spa_transactions
FOR INSERT
TO authenticated
WITH CHECK (true);  -- Allow all authenticated users to insert

-- Note: We use 'WITH CHECK (true)' because the service needs to insert
-- SPA transactions for ALL tournament participants, not just the current user

-- ============================================
-- 3. VERIFICATION
-- ============================================

-- Verify policies are created
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
WHERE tablename IN ('elo_history', 'spa_transactions')
ORDER BY tablename, policyname;

-- ============================================
-- 4. TEST INSERT (should work after applying this)
-- ============================================

-- Test will be done from Python script

COMMENT ON POLICY "elo_history_insert_policy" ON elo_history IS 
'Allow authenticated users to insert ELO history records for tournament completion';

COMMENT ON POLICY "elo_history_select_policy" ON elo_history IS 
'Allow users to view their own ELO history';

COMMENT ON POLICY "spa_transactions_insert_policy" ON spa_transactions IS 
'Allow authenticated users to insert SPA transaction records for tournament completion';

COMMENT ON POLICY "spa_transactions_select_policy" ON spa_transactions IS 
'Allow users to view their own SPA transactions';
