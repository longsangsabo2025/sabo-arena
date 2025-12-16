-- Create club_follows table for club follow functionality
CREATE TABLE IF NOT EXISTS public.club_follows (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure a user can only follow a club once
    UNIQUE(user_id, club_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_club_follows_user_id ON public.club_follows(user_id);
CREATE INDEX IF NOT EXISTS idx_club_follows_club_id ON public.club_follows(club_id);
CREATE INDEX IF NOT EXISTS idx_club_follows_created_at ON public.club_follows(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE public.club_follows ENABLE ROW LEVEL SECURITY;

-- RLS Policies for club_follows table

-- Policy: Users can view all follow relationships (for counting followers)
CREATE POLICY "Users can view club follows" ON public.club_follows
    FOR SELECT
    USING (true);

-- Policy: Users can only create their own follow relationships
CREATE POLICY "Users can create their own follows" ON public.club_follows
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only delete their own follow relationships
CREATE POLICY "Users can delete their own follows" ON public.club_follows
    FOR DELETE
    USING (auth.uid() = user_id);

-- Add updated_at trigger
CREATE TRIGGER set_updated_at_club_follows
    BEFORE UPDATE ON public.club_follows
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- Grant permissions
GRANT SELECT, INSERT, DELETE ON public.club_follows TO authenticated;

-- Comments for documentation
COMMENT ON TABLE public.club_follows IS 'Stores club follow relationships between users and clubs';
COMMENT ON COLUMN public.club_follows.user_id IS 'ID of the user who is following';
COMMENT ON COLUMN public.club_follows.club_id IS 'ID of the club being followed';
COMMENT ON COLUMN public.club_follows.created_at IS 'When the follow relationship was created';