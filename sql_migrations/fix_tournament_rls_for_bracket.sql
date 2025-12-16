-- Fix RLS policy for tournament bracket generation
-- Allow club owners to update tournament status when generating bracket

-- Drop existing restrictive policies if any
DROP POLICY IF EXISTS "Club owners can update their tournaments" ON tournaments;

-- Create comprehensive update policy for club owners
CREATE POLICY "Club owners can update their tournaments"
ON tournaments
FOR UPDATE
TO authenticated
USING (
  -- User is the club owner
  club_id IN (
    SELECT id FROM clubs WHERE owner_id = auth.uid()
  )
)
WITH CHECK (
  -- User is the club owner
  club_id IN (
    SELECT id FROM clubs WHERE owner_id = auth.uid()
  )
);

-- Also ensure club owners can read their tournaments
DROP POLICY IF EXISTS "Club owners can read their tournaments" ON tournaments;

CREATE POLICY "Club owners can read their tournaments"
ON tournaments
FOR SELECT
TO authenticated
USING (
  club_id IN (
    SELECT id FROM clubs WHERE owner_id = auth.uid()
  )
  OR
  -- Anyone can view public tournaments
  status IN ('upcoming', 'ongoing', 'completed')
);

-- Grant necessary permissions
GRANT UPDATE ON tournaments TO authenticated;
GRANT SELECT ON tournaments TO authenticated;

-- Verify policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'tournaments'
ORDER BY policyname;
