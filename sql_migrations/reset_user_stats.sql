-- Reset all user stats to default values
-- Run this in Supabase SQL Editor

-- Update all profiles
UPDATE profiles
SET 
  -- Reset match stats
  wins = 0,
  losses = 0,
  draws = 0,
  total_matches = 0,
  
  -- Reset tournament stats
  tournaments_played = 0,
  tournaments_won = 0,
  
  -- Reset ELO to starting point of current rank
  elo_rating = CASE
    WHEN elo_rating < 1400 THEN 1200   -- Rank I
    WHEN elo_rating < 1600 THEN 1400   -- Rank II
    WHEN elo_rating < 1800 THEN 1600   -- Rank III
    WHEN elo_rating < 2000 THEN 1800   -- Rank IV
    WHEN elo_rating < 2200 THEN 2000   -- Rank V
    WHEN elo_rating < 2400 THEN 2200   -- Rank VI
    WHEN elo_rating < 2600 THEN 2400   -- Rank VII
    WHEN elo_rating < 2800 THEN 2600   -- Rank VIII
    WHEN elo_rating < 3000 THEN 2800   -- Rank IX
    ELSE 3000                           -- Rank X
  END,
  
  -- Reset highest/lowest ELO
  highest_elo = CASE
    WHEN elo_rating < 1400 THEN 1200
    WHEN elo_rating < 1600 THEN 1400
    WHEN elo_rating < 1800 THEN 1600
    WHEN elo_rating < 2000 THEN 1800
    WHEN elo_rating < 2200 THEN 2000
    WHEN elo_rating < 2400 THEN 2200
    WHEN elo_rating < 2600 THEN 2400
    WHEN elo_rating < 2800 THEN 2600
    WHEN elo_rating < 3000 THEN 2800
    ELSE 3000
  END,
  
  lowest_elo = CASE
    WHEN elo_rating < 1400 THEN 1200
    WHEN elo_rating < 1600 THEN 1400
    WHEN elo_rating < 1800 THEN 1600
    WHEN elo_rating < 2000 THEN 1800
    WHEN elo_rating < 2200 THEN 2000
    WHEN elo_rating < 2400 THEN 2200
    WHEN elo_rating < 2600 THEN 2400
    WHEN elo_rating < 2800 THEN 2600
    WHEN elo_rating < 3000 THEN 2800
    ELSE 3000
  END,
  
  updated_at = NOW()
WHERE TRUE;

-- Show results
SELECT 
  display_name,
  email,
  elo_rating AS "New ELO",
  CASE
    WHEN elo_rating < 1400 THEN 'I'
    WHEN elo_rating < 1600 THEN 'II'
    WHEN elo_rating < 1800 THEN 'III'
    WHEN elo_rating < 2000 THEN 'IV'
    WHEN elo_rating < 2200 THEN 'V'
    WHEN elo_rating < 2400 THEN 'VI'
    WHEN elo_rating < 2600 THEN 'VII'
    WHEN elo_rating < 2800 THEN 'VIII'
    WHEN elo_rating < 3000 THEN 'IX'
    ELSE 'X'
  END AS "Rank",
  wins,
  losses,
  draws,
  total_matches,
  tournaments_played,
  tournaments_won
FROM profiles
ORDER BY elo_rating DESC;
