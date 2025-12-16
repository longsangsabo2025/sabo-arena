-- Add storage buckets for club images and fix schema inconsistencies
-- Date: 2025-01-20

-- 1. ADD STORAGE BUCKETS FOR CLUB CONTENT

-- Bucket for club logos (public access for branding)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'club-logos',
    'club-logos',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'image/svg+xml']
) ON CONFLICT (id) DO NOTHING;

-- Bucket for club profile and cover images (public access for display)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'club-images',
    'club-images',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
) ON CONFLICT (id) DO NOTHING;

-- 2. STORAGE POLICIES FOR CLUB BUCKETS

-- Policies for club-logos bucket
CREATE POLICY "club_owners_manage_club_logos"
ON storage.objects
FOR ALL
TO authenticated
USING (
    bucket_id = 'club-logos'
    AND owner IN (
        SELECT owner_id FROM public.clubs WHERE id::text = (storage.foldername(name))[2]
    )
)
WITH CHECK (
    bucket_id = 'club-logos'
    AND owner IN (
        SELECT owner_id FROM public.clubs WHERE id::text = (storage.foldername(name))[2]
    )
);

CREATE POLICY "public_can_view_club_logos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'club-logos');

-- Policies for club-images bucket
CREATE POLICY "club_owners_manage_club_images"
ON storage.objects
FOR ALL
TO authenticated
USING (
    bucket_id = 'club-images'
    AND owner IN (
        SELECT owner_id FROM public.clubs WHERE id::text = (storage.foldername(name))[2]
    )
)
WITH CHECK (
    bucket_id = 'club-images'
    AND owner IN (
        SELECT owner_id FROM public.clubs WHERE id::text = (storage.foldername(name))[2]
    )
);

CREATE POLICY "public_can_view_club_images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'club-images');

-- 3. FIX DATABASE SCHEMA INCONSISTENCIES

-- Add logo_url column if it doesn't exist (for backward compatibility)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clubs' AND column_name = 'logo_url') THEN
        ALTER TABLE public.clubs ADD COLUMN logo_url TEXT;
        -- Copy existing profile_image_url to logo_url for existing clubs
        UPDATE public.clubs SET logo_url = profile_image_url WHERE profile_image_url IS NOT NULL;
    END IF;
END $$;

-- 4. ADD INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_clubs_logo_url ON public.clubs(logo_url) WHERE logo_url IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_clubs_profile_image_url ON public.clubs(profile_image_url) WHERE profile_image_url IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_clubs_cover_image_url ON public.clubs(cover_image_url) WHERE cover_image_url IS NOT NULL;
