-- =====================================================
-- FIX: RLS Policy for elo_history table
-- Allow users to view their own ELO history
-- =====================================================

-- Drop existing policy if any
DROP POLICY IF EXISTS "Users can view own elo history" ON elo_history;

-- Create new policy: Users can view their own ELO history
CREATE POLICY "Users can view own elo history"
ON elo_history
FOR SELECT
USING (
  auth.uid() = user_id
  OR
  -- Admin users can see all
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
);

-- Also allow public read for leaderboard purposes (optional)
-- Comment out if you want strict privacy
DROP POLICY IF EXISTS "Public can view elo history for leaderboards" ON elo_history;

CREATE POLICY "Public can view elo history for leaderboards"
ON elo_history
FOR SELECT
USING (true);  -- Anyone can read (needed for leaderboards, stats)

-- Grant SELECT permission to authenticated and anon users
GRANT SELECT ON elo_history TO authenticated;
GRANT SELECT ON elo_history TO anon;

-- Verify RLS is enabled
ALTER TABLE elo_history ENABLE ROW LEVEL SECURITY;
