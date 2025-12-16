-- Fix RLS policies for tournament prize vouchers
-- Allow club owners to create voucher configs when creating tournament

-- 1. Drop existing policies
DROP POLICY IF EXISTS "tournament_prize_vouchers_select" ON tournament_prize_vouchers;
DROP POLICY IF EXISTS "tournament_prize_vouchers_insert" ON tournament_prize_vouchers;
DROP POLICY IF EXISTS "tournament_prize_vouchers_update" ON tournament_prize_vouchers;
DROP POLICY IF EXISTS "tournament_prize_vouchers_delete" ON tournament_prize_vouchers;

-- 2. Enable RLS
ALTER TABLE tournament_prize_vouchers ENABLE ROW LEVEL SECURITY;

-- 3. Select policy - Anyone can view
CREATE POLICY "tournament_prize_vouchers_select"
ON tournament_prize_vouchers
FOR SELECT
TO authenticated, anon
USING (true);

-- 4. Insert policy - Club owners can create voucher configs for their tournaments
CREATE POLICY "tournament_prize_vouchers_insert"
ON tournament_prize_vouchers
FOR INSERT
TO authenticated, anon
WITH CHECK (
  -- Allow if user is club owner
  EXISTS (
    SELECT 1 FROM tournaments t
    INNER JOIN clubs c ON c.id = t.club_id
    WHERE t.id = tournament_id
    AND c.owner_id = auth.uid()
  )
  OR
  -- Allow service role
  auth.jwt()->>'role' = 'service_role'
);

-- 5. Update policy - Club owners and service role can update
CREATE POLICY "tournament_prize_vouchers_update"
ON tournament_prize_vouchers
FOR UPDATE
TO authenticated, anon
USING (
  EXISTS (
    SELECT 1 FROM tournaments t
    INNER JOIN clubs c ON c.id = t.club_id
    WHERE t.id = tournament_id
    AND c.owner_id = auth.uid()
  )
  OR
  auth.jwt()->>'role' = 'service_role'
);

-- 6. Delete policy - Only club owners
CREATE POLICY "tournament_prize_vouchers_delete"
ON tournament_prize_vouchers
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM tournaments t
    INNER JOIN clubs c ON c.id = t.club_id
    WHERE t.id = tournament_id
    AND c.owner_id = auth.uid()
  )
);

COMMENT ON POLICY "tournament_prize_vouchers_insert" ON tournament_prize_vouchers IS 
'Allow club owners to create voucher configs for their tournaments';
