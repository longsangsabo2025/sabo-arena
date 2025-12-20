-- ============================================
-- HANDICAP RULES POPULATION
-- Populate handicap_rules table based on ChallengeRulesService
-- ============================================

-- Clear existing data (if any)
TRUNCATE TABLE handicap_rules CASCADE;

-- Insert handicap rules based on rank difference and bet amount
-- Format: rank_difference (in rank values), bet_amount, handicap_value, description

-- 1 sub-rank difference (e.g., K→I, H→H+)
INSERT INTO handicap_rules (rank_difference, bet_amount, handicap_value, handicap_type, description, created_at, updated_at) VALUES
(1, 100, 0.5, '1_sub', 'K→I hoặc H→H+ với cược 100 SPA', NOW(), NOW()),
(1, 200, 1.0, '1_sub', 'K→I hoặc H→H+ với cược 200 SPA', NOW(), NOW()),
(1, 300, 1.5, '1_sub', 'K→I hoặc H→H+ với cược 300 SPA', NOW(), NOW()),
(1, 400, 1.5, '1_sub', 'K→I hoặc H→H+ với cược 400 SPA', NOW(), NOW()),
(1, 500, 2.0, '1_sub', 'K→I hoặc H→H+ với cược 500 SPA', NOW(), NOW()),
(1, 600, 2.5, '1_sub', 'K→I hoặc H→H+ với cược 600 SPA', NOW(), NOW());

-- 1 main rank difference (e.g., K→H, I→G)
INSERT INTO handicap_rules (rank_difference, bet_amount, handicap_value, handicap_type, description, created_at, updated_at) VALUES
(2, 100, 1.0, '1_main', 'K→H hoặc I→G với cược 100 SPA', NOW(), NOW()),
(2, 200, 1.5, '1_main', 'K→H hoặc I→G với cược 200 SPA', NOW(), NOW()),
(2, 300, 2.0, '1_main', 'K→H hoặc I→G với cược 300 SPA', NOW(), NOW()),
(2, 400, 2.5, '1_main', 'K→H hoặc I→G với cược 400 SPA', NOW(), NOW()),
(2, 500, 3.0, '1_main', 'K→H hoặc I→G với cược 500 SPA', NOW(), NOW()),
(2, 600, 3.5, '1_main', 'K→H hoặc I→G với cược 600 SPA', NOW(), NOW());

-- 1.5 main rank difference (e.g., K→H+, I→G+)
INSERT INTO handicap_rules (rank_difference, bet_amount, handicap_value, handicap_type, description, created_at, updated_at) VALUES
(3, 100, 1.5, '1.5_main', 'K→H+ hoặc I→G+ với cược 100 SPA', NOW(), NOW()),
(3, 200, 2.5, '1.5_main', 'K→H+ hoặc I→G+ với cược 200 SPA', NOW(), NOW()),
(3, 300, 3.5, '1.5_main', 'K→H+ hoặc I→G+ với cược 300 SPA', NOW(), NOW()),
(3, 400, 4.0, '1.5_main', 'K→H+ hoặc I→G+ với cược 400 SPA', NOW(), NOW()),
(3, 500, 5.0, '1.5_main', 'K→H+ hoặc I→G+ với cược 500 SPA', NOW(), NOW()),
(3, 600, 6.0, '1.5_main', 'K→H+ hoặc I→G+ với cược 600 SPA', NOW(), NOW());

-- 2 main rank difference (e.g., K→G, I→F)
INSERT INTO handicap_rules (rank_difference, bet_amount, handicap_value, handicap_type, description, created_at, updated_at) VALUES
(4, 100, 2.0, '2_main', 'K→G hoặc I→F với cược 100 SPA', NOW(), NOW()),
(4, 200, 3.0, '2_main', 'K→G hoặc I→F với cược 200 SPA', NOW(), NOW()),
(4, 300, 4.0, '2_main', 'K→G hoặc I→F với cược 300 SPA', NOW(), NOW()),
(4, 400, 5.0, '2_main', 'K→G hoặc I→F với cược 400 SPA', NOW(), NOW()),
(4, 500, 6.0, '2_main', 'K→G hoặc I→F với cược 500 SPA', NOW(), NOW()),
(4, 600, 7.0, '2_main', 'K→G hoặc I→F với cược 600 SPA', NOW(), NOW());

-- Verify insertion
SELECT 
  rank_difference,
  bet_amount,
  handicap_value,
  handicap_type,
  description
FROM handicap_rules
ORDER BY rank_difference, bet_amount;

-- Expected: 24 rules (4 rank differences × 6 bet amounts)
