-- Create club_photos table
CREATE TABLE IF NOT EXISTS public.club_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_club_photos_club_id ON public.club_photos(club_id);

CREATE INDEX IF NOT EXISTS idx_club_photos_created_at ON public.club_photos(created_at DESC);

-- Enable RLS
ALTER TABLE public.club_photos ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view club photos
CREATE POLICY "Anyone can view club photos"
ON public.club_photos
FOR SELECT
USING (true);

-- Policy: Club owners can insert photos
CREATE POLICY "Club owners can insert photos"
ON public.club_photos
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.clubs
        WHERE clubs.id = club_photos.club_id
        AND clubs.owner_id = auth.uid()
    )
);

-- Policy: Club owners can delete their club's photos
CREATE POLICY "Club owners can delete photos"
ON public.club_photos
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.clubs
        WHERE clubs.id = club_photos.club_id
        AND clubs.owner_id = auth.uid()
    )
);

-- Create storage bucket for club photos if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('club-photos', 'club-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policy: Anyone can view club photos
CREATE POLICY "Anyone can view club photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'club-photos');

-- Storage policy: Club owners can upload photos
CREATE POLICY "Club owners can upload photos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'club-photos'
    AND auth.role() = 'authenticated'
);

-- Storage policy: Club owners can delete their photos
CREATE POLICY "Club owners can delete photos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'club-photos'
    AND auth.role() = 'authenticated'
);
