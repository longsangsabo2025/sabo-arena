-- ============================================================================
-- FIX USER_VOUCHERS SCHEMA + CREATE TOURNAMENT PRIZE VOUCHERS
-- ============================================================================
-- Run this SQL script on Supabase Dashboard → SQL Editor
-- ============================================================================

-- PART 1: Fix schema - Make campaign_id nullable
-- (Tournament vouchers don't belong to marketing campaigns)
ALTER TABLE user_vouchers 
ALTER COLUMN campaign_id DROP NOT NULL;

-- Verify the change
SELECT 
    column_name, 
    is_nullable,
    data_type
FROM information_schema.columns 
WHERE table_name = 'user_vouchers' 
AND column_name = 'campaign_id';
-- Expected: is_nullable = 'YES'

-- ============================================================================
-- PART 2: Create RLS policies for tournament_prize_vouchers
-- ============================================================================

-- Drop existing policies (if any)
DROP POLICY IF EXISTS "Club owners can create prize vouchers" ON tournament_prize_vouchers;
DROP POLICY IF EXISTS "Anyone can view prize vouchers" ON tournament_prize_vouchers;
DROP POLICY IF EXISTS "System can update vouchers" ON tournament_prize_vouchers;

-- Allow club owners/admins to INSERT prize voucher configs
CREATE POLICY "Club owners can create prize vouchers"
ON tournament_prize_vouchers
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM tournaments t
    JOIN clubs c ON c.id = t.club_id
    WHERE t.id = tournament_prize_vouchers.tournament_id
    AND (
      c.owner_id = auth.uid() 
      OR EXISTS (
        SELECT 1 FROM club_admins ca 
        WHERE ca.club_id = c.id 
        AND ca.user_id = auth.uid()
      )
    )
  )
);

-- Allow anyone to SELECT/view prize vouchers
CREATE POLICY "Anyone can view prize vouchers"
ON tournament_prize_vouchers
FOR SELECT
USING (true);

-- Allow system to UPDATE when issuing vouchers
CREATE POLICY "System can update vouchers"
ON tournament_prize_vouchers
FOR UPDATE
USING (true)
WITH CHECK (true);

-- Enable RLS
ALTER TABLE tournament_prize_vouchers ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PART 3: Delete old voucher configs if exist (clean slate)
-- ============================================================================
DELETE FROM tournament_prize_vouchers 
WHERE tournament_id = 'db321d1a-1017-443e-bc17-18d5ad61ba16';

-- ============================================================================
-- PART 4: Create 4 prize voucher configs for tournament sabo16
-- ============================================================================
INSERT INTO tournament_prize_vouchers (
  tournament_id,
  position,
  position_label,
  voucher_value,
  voucher_code_prefix,
  voucher_description,
  valid_days,
  is_issued,
  created_at
) VALUES
  (
    'db321d1a-1017-443e-bc17-18d5ad61ba16',
    1,
    'Nhất',
    700000,
    'PRIZE1',
    'Prize voucher Nhất - 700K VNĐ',
    30,
    false,
    NOW()
  ),
  (
    'db321d1a-1017-443e-bc17-18d5ad61ba16',
    2,
    'Nhì',
    500000,
    'PRIZE2',
    'Prize voucher Nhì - 500K VNĐ',
    30,
    false,
    NOW()
  ),
  (
    'db321d1a-1017-443e-bc17-18d5ad61ba16',
    3,
    'Ba',
    300000,
    'PRIZE3',
    'Prize voucher Ba - 300K VNĐ',
    30,
    false,
    NOW()
  ),
  (
    'db321d1a-1017-443e-bc17-18d5ad61ba16',
    4,
    'Top 4',
    300000,
    'PRIZE4',
    'Prize voucher Top 4 - 300K VNĐ',
    30,
    false,
    NOW()
  );

-- ============================================================================
-- PART 5: Verify voucher configs created
-- ============================================================================
SELECT 
  position,
  position_label,
  voucher_value,
  is_issued,
  created_at
FROM tournament_prize_vouchers
WHERE tournament_id = 'db321d1a-1017-443e-bc17-18d5ad61ba16'
ORDER BY position;

-- Expected output: 4 rows showing positions 1-4

-- ============================================================================
-- DONE! Now run Python script to issue voucher to champion:
-- python auto_fix_voucher_complete.py
-- ============================================================================
