-- =====================================================
-- FIX: Foreign Key Relationship posts.club_id → clubs.id
-- =====================================================
-- Issue: "Could not find a relationship between 'posts' 
--        and 'clubs' in the schema cache"
-- Error code: PGRST200
-- =====================================================

-- Step 1: Check current foreign keys on posts table
DO $$ 
BEGIN
    RAISE NOTICE '🔍 Checking existing foreign keys on posts table...';
END $$;

SELECT 
    '📋 Current Foreign Keys:' AS status,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS references_table,
    ccu.column_name AS references_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'posts'
    AND tc.table_schema = 'public'
ORDER BY kcu.column_name;

-- Step 2: Drop existing constraint if it exists (to recreate it properly)
DO $$
BEGIN
    -- Drop posts_club_id_fkey if exists
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'posts_club_id_fkey' 
        AND conrelid = 'public.posts'::regclass
    ) THEN
        ALTER TABLE public.posts DROP CONSTRAINT posts_club_id_fkey;
        RAISE NOTICE '✅ Dropped existing posts_club_id_fkey';
    END IF;
    
    -- Also check for alternative names
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'fk_posts_club_id' 
        AND conrelid = 'public.posts'::regclass
    ) THEN
        ALTER TABLE public.posts DROP CONSTRAINT fk_posts_club_id;
        RAISE NOTICE '✅ Dropped existing fk_posts_club_id';
    END IF;
END $$;

-- Step 3: Verify data integrity before creating FK
DO $$
DECLARE
    orphan_count INTEGER;
BEGIN
    RAISE NOTICE '🔍 Checking for orphaned records...';
    
    -- Check for posts with club_id that don't exist in clubs
    SELECT COUNT(*) INTO orphan_count
    FROM posts 
    WHERE club_id IS NOT NULL 
    AND club_id NOT IN (SELECT id FROM clubs);
    
    IF orphan_count > 0 THEN
        RAISE NOTICE '⚠️ Found % posts with invalid club_id', orphan_count;
        RAISE NOTICE '🧹 Cleaning up orphaned records...';
        
        -- Option 1: Set to NULL (safer)
        UPDATE posts 
        SET club_id = NULL 
        WHERE club_id IS NOT NULL 
        AND club_id NOT IN (SELECT id FROM clubs);
        
        RAISE NOTICE '✅ Cleaned up % orphaned records', orphan_count;
    ELSE
        RAISE NOTICE '✅ No orphaned records found';
    END IF;
END $$;

-- Step 4: Create the foreign key constraint
ALTER TABLE public.posts
ADD CONSTRAINT posts_club_id_fkey
FOREIGN KEY (club_id) 
REFERENCES public.clubs(id)
ON DELETE SET NULL;  -- When a club is deleted, set club_id to NULL instead of deleting the post

-- Step 5: Create index for better performance
CREATE INDEX IF NOT EXISTS idx_posts_club_id ON public.posts(club_id);

-- Step 6: Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Step 7: Verify the foreign key was created
SELECT 
    '✅ Foreign key created successfully!' AS status,
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name,
    ccu.table_name AS references_table,
    ccu.column_name AS references_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'posts'
    AND kcu.column_name = 'club_id'
    AND tc.table_schema = 'public';

-- =====================================================
-- INSTRUCTIONS:
-- =====================================================
-- 1. Go to Supabase SQL Editor:
--    https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/sql
--
-- 2. Copy this entire SQL file
--
-- 3. Paste into SQL Editor
--
-- 4. Click "Run" button (or press Ctrl+Enter)
--
-- 5. Wait 5-10 seconds for schema cache to reload
--
-- 6. Hot reload your Flutter app (press 'r' in terminal)
--
-- 7. Test creating a post with club_id again
-- =====================================================

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '================================================';
    RAISE NOTICE '✅ FIX COMPLETE!';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Foreign key created: posts.club_id → clubs.id';
    RAISE NOTICE 'Schema cache reloaded';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Wait 5-10 seconds for cache refresh';
    RAISE NOTICE '2. Hot reload Flutter app (press "r")';
    RAISE NOTICE '3. Test creating posts with club association';
    RAISE NOTICE '================================================';
END $$;
