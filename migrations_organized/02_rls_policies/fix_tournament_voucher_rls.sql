-- ============================================================================
-- FIX TOURNAMENT PRIZE VOUCHER SYSTEM
-- ============================================================================
-- Issue: Tournament winner không nhận được prize voucher
-- Root Cause: RLS policy chặn INSERT vào tournament_prize_vouchers table
-- Solution: Add proper RLS policies + manually create missing voucher configs
-- ============================================================================

-- Step 1: Drop existing policies (if any)
DROP POLICY IF EXISTS "Club owners can create prize vouchers" ON tournament_prize_vouchers;
DROP POLICY IF EXISTS "Anyone can view prize vouchers" ON tournament_prize_vouchers;
DROP POLICY IF EXISTS "System can issue vouchers" ON tournament_prize_vouchers;

-- Step 2: Create comprehensive RLS policies

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

-- Allow system (service_role) to UPDATE when issuing vouchers
CREATE POLICY "System can issue vouchers"
ON tournament_prize_vouchers
FOR UPDATE
USING (true)
WITH CHECK (true);

-- Step 3: Enable RLS on tournament_prize_vouchers (if not enabled)
ALTER TABLE tournament_prize_vouchers ENABLE ROW LEVEL SECURITY;

-- Step 4: Insert missing voucher configs for tournament sabo16
-- Tournament ID: db321d1a-1017-443e-bc17-18d5ad61ba16
-- Prize Pool: 1,800,000 VNĐ distributed as 700K/500K/300K/300K

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
  )
ON CONFLICT (tournament_id, position) DO NOTHING;

-- Step 5: Verify voucher configs created
SELECT 
  position,
  position_label,
  voucher_value,
  is_issued,
  created_at
FROM tournament_prize_vouchers
WHERE tournament_id = 'db321d1a-1017-443e-bc17-18d5ad61ba16'
ORDER BY position;

-- ============================================================================
-- EXPECTED OUTPUT:
-- ============================================================================
--  position | position_label | voucher_value | is_issued |       created_at        
-- ----------+----------------+---------------+-----------+-------------------------
--         1 | Nhất           |        700000 | f         | 2025-11-06 ...
--         2 | Nhì            |        500000 | f         | 2025-11-06 ...
--         3 | Ba             |        300000 | f         | 2025-11-06 ...
--         4 | Top 4          |        300000 | f         | 2025-11-06 ...
-- ============================================================================

-- Step 6: Now RPC function can issue vouchers to winners
-- This will be called automatically by calling issue_champion_voucher.py
-- Or manually: SELECT issue_tournament_prize_vouchers(
--   'db321d1a-1017-443e-bc17-18d5ad61ba16',
--   '0a0220d4-51ec-428e-b185-1914093db584',
--   1
-- );
