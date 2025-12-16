-- Fix RLS policy for club_members to allow public read access
-- This allows anyone to see club member lists (for public clubs)

-- Drop existing restrictive policy
DROP POLICY IF EXISTS "users_manage_own_club_memberships" ON public.club_members;

-- Create separate policies for different operations

-- 1. Anyone can view club members (SELECT)
CREATE POLICY "public_can_view_club_members"
ON public.club_members
FOR SELECT
TO authenticated
USING (true);

-- 2. Users can only insert/update/delete their own memberships
CREATE POLICY "users_manage_own_memberships"
ON public.club_members
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_update_own_memberships"
ON public.club_members
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_delete_own_memberships"
ON public.club_members
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Verify policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'club_members'
ORDER BY policyname;
