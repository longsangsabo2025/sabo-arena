-- Fix 404 Error: Create missing get_user_ranking function
CREATE OR REPLACE FUNCTION get_user_ranking(user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER -- Run as owner to ensure access to users table
AS $$
DECLARE
    user_rank INTEGER;
BEGIN
    -- Calculate rank based on ELO rating for active users
    SELECT rank_position INTO user_rank
    FROM (
        SELECT 
            id,
            RANK() OVER (ORDER BY elo_rating DESC) as rank_position
        FROM users
        WHERE is_active = true
    ) as ranked_users
    WHERE id = user_id;
    
    -- Return 0 if user not found or not active (unranked)
    RETURN COALESCE(user_rank, 0);
END;
$$;

-- Fix 400 Error: Ensure Foreign Key relationship between tournaments and clubs exists
-- This enables the query: select=*,clubs(...)
DO $$
BEGIN
    -- Check if the constraint exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'tournaments_club_id_fkey' 
        AND table_name = 'tournaments'
    ) THEN
        -- Add the foreign key if missing
        ALTER TABLE tournaments 
        ADD CONSTRAINT tournaments_club_id_fkey 
        FOREIGN KEY (club_id) 
        REFERENCES clubs(id) 
        ON DELETE CASCADE;
    END IF;
END $$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_ranking(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_ranking(UUID) TO service_role;

-- Refresh schema cache (this is automatic in Supabase but good to note)
NOTIFY pgrst, 'reload config';
