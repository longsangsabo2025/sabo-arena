-- Fix RLS policy for challenges to allow viewing public challenges
-- This allows users to see public challenges (challenged_id = null) on the opponents tab

-- Drop only the restrictive SELECT policy
DROP POLICY IF EXISTS "Users can view their own challenges" ON public.challenges;

-- Create new SELECT policy that allows:
-- 1. Viewing public challenges (challenged_id = null)
-- 2. Viewing challenges you created (challenger_id = auth.uid())
-- 3. Viewing challenges sent to you (challenged_id = auth.uid())
CREATE POLICY "users_can_view_all_relevant_challenges"
ON public.challenges
FOR SELECT
TO authenticated
USING (
  challenged_id IS NULL OR
  challenger_id = auth.uid() OR
  challenged_id = auth.uid()
);

-- Verify policies
SELECT policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE tablename = 'challenges'
ORDER BY policyname;
