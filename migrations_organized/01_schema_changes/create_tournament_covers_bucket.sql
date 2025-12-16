-- ==========================================
-- CREATE TOURNAMENT COVERS STORAGE BUCKET
-- ==========================================
-- Date: October 26, 2025
-- Purpose: Tạo storage bucket cho tournament cover images
-- Run in: Supabase SQL Editor

-- ==========================================
-- STEP 1: CREATE BUCKET
-- ==========================================

-- Insert bucket vào storage.buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'tournament-covers',
  'tournament-covers',
  true,  -- Public bucket
  5242880,  -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;


-- ==========================================
-- STEP 2: SET UP RLS POLICIES
-- ==========================================

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Anyone can view tournament covers (public read)
CREATE POLICY "Anyone can view tournament covers"
ON storage.objects FOR SELECT
USING (bucket_id = 'tournament-covers');

-- Policy 2: Club owners and admins can upload tournament covers
CREATE POLICY "Club owners/admins can upload tournament covers"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'tournament-covers' AND
  auth.uid() IN (
    SELECT user_id FROM club_members cm
    WHERE cm.role IN ('owner', 'admin')
  )
);

-- Policy 3: Club owners and admins can update their tournament covers
CREATE POLICY "Club owners/admins can update tournament covers"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'tournament-covers' AND
  auth.uid() IN (
    SELECT user_id FROM club_members cm
    WHERE cm.role IN ('owner', 'admin')
  )
);

-- Policy 4: Club owners and admins can delete their tournament covers
CREATE POLICY "Club owners/admins can delete tournament covers"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'tournament-covers' AND
  auth.uid() IN (
    SELECT user_id FROM club_members cm
    WHERE cm.role IN ('owner', 'admin')
  )
);


-- ==========================================
-- STEP 3: VERIFY SETUP
-- ==========================================

-- Check if bucket exists
SELECT * FROM storage.buckets WHERE id = 'tournament-covers';

-- Check policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'objects' AND policyname LIKE '%tournament covers%';


-- ==========================================
-- NOTES
-- ==========================================

/*
1. Bucket tournament-covers được tạo với:
   - Public: true (ai cũng xem được)
   - File size limit: 5MB
   - Allowed types: JPG, PNG, WebP

2. RLS Policies:
   - SELECT: Public (mọi người xem được)
   - INSERT/UPDATE/DELETE: Chỉ club owners và admins

3. Naming convention:
   - tournament_cover_{tournamentId}_{timestamp}.{extension}
   - Example: tournament_cover_123abc_1730000000000.jpg

4. Usage trong Flutter:
   - Upload: TournamentService.uploadAndUpdateTournamentCover()
   - URL format: https://{project}.supabase.co/storage/v1/object/public/tournament-covers/{filename}

5. Testing:
   - Sau khi run script này, test upload trong app
   - Check URL image có public access không
   - Verify RLS policies hoạt động đúng
*/
