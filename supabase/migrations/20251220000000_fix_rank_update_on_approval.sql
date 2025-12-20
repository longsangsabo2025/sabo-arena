-- Migration: Fix rank update on approval
-- Date: 2025-12-20
-- Purpose: Fix bug where user rank is not updated to requested rank after approval
--          Currently only updates to 'E', not respecting user's requested rank

-- Step 1: Add requested_rank column to store the rank user is requesting
ALTER TABLE public.rank_requests 
ADD COLUMN IF NOT EXISTS requested_rank TEXT;

-- Add comment
COMMENT ON COLUMN public.rank_requests.requested_rank IS 'The rank level user is requesting (e.g., A, B, C, D, E, F, G, H, I, J, K)';

-- Step 2: Drop old trigger and function (CASCADE to remove dependencies)
DROP TRIGGER IF EXISTS on_rank_request_approved ON public.rank_requests CASCADE;
DROP TRIGGER IF EXISTS update_user_rank_trigger ON public.rank_requests CASCADE;
DROP FUNCTION IF EXISTS public.update_user_rank_on_approval() CASCADE;

-- Step 3: Create improved function that updates rank to requested rank
CREATE OR REPLACE FUNCTION public.update_user_rank_on_approval()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_rank TEXT;
BEGIN
    -- Only execute when status changes from pending to approved
    IF OLD.status = 'pending' AND NEW.status = 'approved' THEN
        -- Determine which rank to set:
        -- 1. If requested_rank is specified, use it
        -- 2. Otherwise, parse from notes (format: "Rank mong muốn: X")
        -- 3. Otherwise, default to 'K' (beginner rank)
        
        IF NEW.requested_rank IS NOT NULL AND NEW.requested_rank != '' THEN
            v_new_rank := NEW.requested_rank;
        ELSE
            -- Try to extract rank from notes
            v_new_rank := substring(NEW.notes FROM 'Rank mong muốn: ([A-K])');
            
            -- If nothing found, default to K
            IF v_new_rank IS NULL OR v_new_rank = '' THEN
                v_new_rank := 'K';
            END IF;
        END IF;
        
        -- Update user's rank
        UPDATE public.users 
        SET 
            rank = v_new_rank,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.user_id;
        
        -- Log the update
        RAISE NOTICE 'Updated user % rank to %', NEW.user_id, v_new_rank;
        
        -- Set reviewed_at timestamp if not already set
        IF NEW.reviewed_at IS NULL THEN
            NEW.reviewed_at = CURRENT_TIMESTAMP;
        END IF;
        
        -- Set reviewed_by if not already set
        IF NEW.reviewed_by IS NULL THEN
            NEW.reviewed_by = auth.uid();
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Step 4: Recreate trigger
CREATE TRIGGER on_rank_request_approved
    BEFORE UPDATE ON public.rank_requests
    FOR EACH ROW EXECUTE FUNCTION public.update_user_rank_on_approval();

-- Step 5: Update existing pending/approved requests to extract requested_rank from notes
UPDATE public.rank_requests
SET requested_rank = substring(notes FROM 'Rank mong muốn: ([A-K])')
WHERE requested_rank IS NULL 
  AND notes IS NOT NULL 
  AND notes LIKE '%Rank mong muốn:%';

-- Verify
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'rank_requests' 
        AND column_name = 'requested_rank'
    ) THEN
        RAISE NOTICE '✅ Column requested_rank added successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to add requested_rank column';
    END IF;
    
    IF EXISTS (
        SELECT 1 
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name = 'update_user_rank_on_approval'
    ) THEN
        RAISE NOTICE '✅ Function update_user_rank_on_approval created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create function';
    END IF;
    
    IF EXISTS (
        SELECT 1 
        FROM information_schema.triggers 
        WHERE trigger_schema = 'public' 
        AND trigger_name = 'on_rank_request_approved'
    ) THEN
        RAISE NOTICE '✅ Trigger on_rank_request_approved created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create trigger';
    END IF;
END $$;
