-- ============================================
-- RANK SYSTEM MIGRATION 2025
-- Remove K+ and I+, shift ELO ranges down
-- ============================================

-- Step 1: DELETE old ranks K+ and I+
DELETE FROM rank_system WHERE rank_code IN ('K+', 'I+');

-- Step 2: UPDATE all remaining ranks with new ELO ranges and stability descriptions
-- K: 1000-1099 (unchanged)
UPDATE rank_system 
SET 
  elo_min = 1000,
  elo_max = 1099,
  display_name = 'K - Khởi đầu',
  stability_description = 'Không ổn định, chỉ biết các kỹ thuật như cule, trỏ',
  updated_at = NOW()
WHERE rank_code = 'K';

-- I: 1100-1199 (was 1200-1299)
UPDATE rank_system 
SET 
  elo_min = 1100,
  elo_max = 1199,
  display_name = 'I - Khởi đầu+',
  stability_description = 'Không ổn định, chỉ biết đơn và biết các kỹ thuật như cule, trỏ',
  updated_at = NOW()
WHERE rank_code = 'I';

-- H: 1200-1299 (was 1400-1499)
UPDATE rank_system 
SET 
  elo_min = 1200,
  elo_max = 1299,
  display_name = 'H - Phát triển',
  stability_description = 'Chưa ổn định, không có khả năng đi chấm, biết 1 ít ắp phẻ',
  updated_at = NOW()
WHERE rank_code = 'H';

-- H+: 1300-1399 (was 1500-1599)
UPDATE rank_system 
SET 
  elo_min = 1300,
  elo_max = 1399,
  display_name = 'H+ - Phát triển tốt',
  stability_description = 'Ổn định, không có khả năng đi chấm, Don 1-2 hình trên 1 race 7',
  updated_at = NOW()
WHERE rank_code = 'H+';

-- G: 1400-1499 (was 1600-1699)
UPDATE rank_system 
SET 
  elo_min = 1400,
  elo_max = 1499,
  display_name = 'G - Trung bình',
  stability_description = 'Chưa ổn định, đi được 1 chấm / race chấm 7, Don 3 hình trên 1 race 7',
  updated_at = NOW()
WHERE rank_code = 'G';

-- G+: 1500-1599 (was 1700-1799)
UPDATE rank_system 
SET 
  elo_min = 1500,
  elo_max = 1599,
  display_name = 'G+ - Trung bình khá',
  stability_description = 'Ổn định, đi được 1 chấm / race chấm 7, Don 4 hình trên 1 race 7',
  updated_at = NOW()
WHERE rank_code = 'G+';

-- F: 1600-1699 (was 1800-1899)
UPDATE rank_system 
SET 
  elo_min = 1600,
  elo_max = 1699,
  display_name = 'F - Khá',
  stability_description = 'Rất ổn định, đi được 2 chấm / race chấm 7, Đi hình, don bàn khá tốt',
  updated_at = NOW()
WHERE rank_code = 'F';

-- F+: 1700-1799 (was 1900-1999) - Add if not exists
INSERT INTO rank_system (rank_code, elo_min, elo_max, display_name, stability_description, created_at, updated_at)
VALUES ('F+', 1700, 1799, 'F+ - Khá giỏi', 'Cực kỳ ổn định, khả năng đi 2 chấm thông', NOW(), NOW())
ON CONFLICT (rank_code) DO UPDATE SET
  elo_min = 1700,
  elo_max = 1799,
  display_name = 'F+ - Khá giỏi',
  stability_description = 'Cực kỳ ổn định, khả năng đi 2 chấm thông',
  updated_at = NOW();

-- E: 1800-1899 (was 2000-2099)
UPDATE rank_system 
SET 
  elo_min = 1800,
  elo_max = 1899,
  display_name = 'E - Chuyên gia',
  stability_description = 'Chuyên gia, khả năng đi 3 chấm thông',
  updated_at = NOW()
WHERE rank_code = 'E';

-- D: 1900-1999 (was 2100-2199)
UPDATE rank_system 
SET 
  elo_min = 1900,
  elo_max = 1999,
  display_name = 'D - Huyền thoại',
  stability_description = 'Huyền thoại, khả năng đi 4 chấm thông',
  updated_at = NOW()
WHERE rank_code = 'D';

-- C: 2000+ (was 2200+)
UPDATE rank_system 
SET 
  elo_min = 2000,
  elo_max = NULL,  -- NULL means unlimited
  display_name = 'C - Vô địch',
  stability_description = 'Vô địch, khả năng đi 5 chấm thông',
  updated_at = NOW()
WHERE rank_code = 'C';

-- Step 3: Verify final state
SELECT 
  rank_code,
  elo_min,
  elo_max,
  display_name,
  stability_description
FROM rank_system
ORDER BY elo_min;

-- Expected result: 10 ranks (K, I, H, H+, G, G+, F, F+, E, D, C)
