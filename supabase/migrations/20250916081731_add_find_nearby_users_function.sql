-- supabase/migrations/20250916081731_add_find_nearby_users_function.sql

-- First, ensure the earthdistance extension is enabled, which depends on cube
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

-- Drop the function if it already exists to ensure a clean update
DROP FUNCTION IF EXISTS find_nearby_users;

-- Create the function to find nearby users
CREATE OR REPLACE FUNCTION find_nearby_users(
  current_user_id UUID,
  user_lat DECIMAL(10, 8),
  user_lon DECIMAL(11, 8),
  radius_km REAL
)
RETURNS SETOF users AS $$
DECLARE
  radius_meters REAL;
BEGIN
  -- Convert radius from kilometers to meters
  radius_meters := radius_km * 1000;

  RETURN QUERY
  SELECT *
  FROM users
  WHERE 
    id != current_user_id AND
    latitude IS NOT NULL AND
    longitude IS NOT NULL AND
    earth_distance(
      ll_to_earth(user_lat, user_lon),
      ll_to_earth(latitude, longitude)
    ) <= radius_meters
  ORDER BY
    earth_distance(
      ll_to_earth(user_lat, user_lon),
      ll_to_earth(latitude, longitude)
    );
END;
$$ LANGUAGE plpgsql;
