-- Fix get_leaderboard function to include avatar_url
-- Run this in Supabase SQL Editor

CREATE OR REPLACE FUNCTION get_leaderboard(
  board_type TEXT DEFAULT 'elo',
  rank_filter TEXT DEFAULT NULL,
  limit_count INTEGER DEFAULT 20
)
RETURNS TABLE(
  rank INTEGER,
  player_id UUID,
  username TEXT,
  display_name TEXT,
  player_rank TEXT,
  elo_rating INTEGER,
  total_wins INTEGER,
  tournament_wins INTEGER,
  spa_points INTEGER,
  win_rate DECIMAL(5,2),
  recent_activity TEXT,
  avatar_url TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH ranked_players AS (
    SELECT 
      u.id,
      u.username,
      u.display_name,
      u.rank,
      u.elo_rating,
      u.wins,
      u.tournament_wins,
      COALESCE(u.spa_points, 1000) as spa_points,
      CASE WHEN u.total_matches > 0 
        THEN ROUND((u.wins::DECIMAL / u.total_matches::DECIMAL) * 100, 2)
        ELSE 0.00 END as win_rate,
      CASE 
        WHEN u.last_seen >= NOW() - INTERVAL '7 days' THEN 'Very Active'
        WHEN u.last_seen >= NOW() - INTERVAL '30 days' THEN 'Active'
        WHEN u.last_seen >= NOW() - INTERVAL '90 days' THEN 'Somewhat Active'
        ELSE 'Inactive'
      END as activity,
      u.avatar_url,
      ROW_NUMBER() OVER (
        ORDER BY 
          CASE 
            WHEN board_type = 'elo' THEN u.elo_rating
            WHEN board_type = 'wins' THEN u.wins
            WHEN board_type = 'tournaments' THEN u.tournament_wins
            WHEN board_type = 'spa_points' THEN COALESCE(u.spa_points, 1000)
            ELSE u.elo_rating
          END DESC
      ) as player_rank
    FROM users u
    WHERE (rank_filter IS NULL OR u.rank = rank_filter)
      AND u.total_matches > 0
  )
  SELECT 
    rp.player_rank::INTEGER,
    rp.id,
    rp.username,
    rp.display_name,
    rp.rank,
    rp.elo_rating,
    rp.wins,
    rp.tournament_wins,
    rp.spa_points,
    rp.win_rate,
    rp.activity,
    rp.avatar_url
  FROM ranked_players rp
  WHERE rp.player_rank <= limit_count
  ORDER BY rp.player_rank;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_leaderboard(TEXT, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_leaderboard(TEXT, TEXT, INTEGER) TO anon;
