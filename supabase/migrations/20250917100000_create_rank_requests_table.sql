-- Create rank requests table for managing user rank registration requests
-- Date: 2025-09-17

-- Create enum for request status
CREATE TYPE public.request_status AS ENUM ('pending', 'approved', 'rejected');

-- Create rank_requests table
CREATE TABLE public.rank_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    status public.request_status NOT NULL DEFAULT 'pending',
    requested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES public.users(id), -- admin or club owner
    rejection_reason TEXT,
    notes TEXT, -- Additional notes from user when requesting

    UNIQUE(user_id, club_id) -- A user can only have one request per club
);

-- Enable Row Level Security
ALTER TABLE public.rank_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies:
-- 1. Users can read their own rank requests
CREATE POLICY "users_can_read_own_rank_requests"
ON public.rank_requests
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- 2. Users can create rank requests for themselves
CREATE POLICY "users_can_create_own_rank_requests"
ON public.rank_requests
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- 3. Club owners can read all requests sent to their clubs
CREATE POLICY "club_owners_can_read_club_rank_requests"
ON public.rank_requests
FOR SELECT
TO authenticated
USING (
    club_id IN (
        SELECT id FROM public.clubs WHERE owner_id = auth.uid()
    )
);

-- 4. Club owners can update (approve/reject) requests for their clubs
CREATE POLICY "club_owners_can_update_club_rank_requests"
ON public.rank_requests
FOR UPDATE
TO authenticated
USING (
    club_id IN (
        SELECT id FROM public.clubs WHERE owner_id = auth.uid()
    )
)
WITH CHECK (
    club_id IN (
        SELECT id FROM public.clubs WHERE owner_id = auth.uid()
    )
);

-- 5. Admins can read and manage all rank requests
CREATE POLICY "admins_can_manage_all_rank_requests"
ON public.rank_requests
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() AND role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Add indexes for better performance
CREATE INDEX idx_rank_requests_user_id ON public.rank_requests(user_id);
CREATE INDEX idx_rank_requests_club_id ON public.rank_requests(club_id);
CREATE INDEX idx_rank_requests_status ON public.rank_requests(status);
CREATE INDEX idx_rank_requests_requested_at ON public.rank_requests(requested_at DESC);

-- Function to automatically update user rank when request is approved
CREATE OR REPLACE FUNCTION public.update_user_rank_on_approval()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only execute when status changes from pending to approved
    IF OLD.status = 'pending' AND NEW.status = 'approved' THEN
        -- Update user's rank to 'E' (beginner rank) if they don't have one
        UPDATE public.users 
        SET 
            rank = COALESCE(rank, 'E'),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.user_id AND (rank IS NULL OR rank = 'unranked');
        
        -- Set reviewed_at timestamp
        NEW.reviewed_at = CURRENT_TIMESTAMP;
        NEW.reviewed_by = auth.uid();
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for automatic rank update
CREATE TRIGGER on_rank_request_approved
    BEFORE UPDATE ON public.rank_requests
    FOR EACH ROW EXECUTE FUNCTION public.update_user_rank_on_approval();