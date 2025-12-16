-- Add SPA points and prize pool to users table
-- Date: 2025-09-17

-- Add spa_points column to track reward points
ALTER TABLE public.users 
ADD COLUMN spa_points INTEGER DEFAULT 0 NOT NULL;

-- Add total_prize_pool column to track total prize money won
ALTER TABLE public.users 
ADD COLUMN total_prize_pool DECIMAL(10,2) DEFAULT 0.00 NOT NULL;

-- Add indexes for better performance on these commonly queried fields
CREATE INDEX idx_users_spa_points ON public.users(spa_points DESC);
CREATE INDEX idx_users_total_prize_pool ON public.users(total_prize_pool DESC);

-- Add constraints to ensure values are non-negative
ALTER TABLE public.users 
ADD CONSTRAINT check_spa_points_non_negative 
CHECK (spa_points >= 0);

ALTER TABLE public.users 
ADD CONSTRAINT check_prize_pool_non_negative 
CHECK (total_prize_pool >= 0);

-- Update trigger to set updated_at when these fields change
CREATE OR REPLACE FUNCTION public.update_user_spa_prize_timestamp()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update the updated_at field when spa_points or total_prize_pool changes
    IF OLD.spa_points != NEW.spa_points OR OLD.total_prize_pool != NEW.total_prize_pool THEN
        NEW.updated_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for automatic timestamp update
CREATE TRIGGER on_user_spa_prize_update
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.update_user_spa_prize_timestamp();

-- Comments for documentation
COMMENT ON COLUMN public.users.spa_points IS 'SPA reward points earned by user through tournaments and activities';
COMMENT ON COLUMN public.users.total_prize_pool IS 'Total prize money (in USD) won by user from tournaments';