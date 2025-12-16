-- =====================================================
-- FIX: Foreign Key Relationship clubs.owner_id → users.id
-- =====================================================
-- Issue: Dashboard error "Could not find a relationship 
--        between 'clubs' and 'users' in the schema cache"
-- Solution: Add proper foreign key constraint
-- =====================================================

-- Step 1: Check and drop existing foreign key if exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'clubs_owner_id_fkey' 
        AND conrelid = 'public.clubs'::regclass
    ) THEN
        ALTER TABLE public.clubs DROP CONSTRAINT clubs_owner_id_fkey;
        RAISE NOTICE '✅ Dropped existing foreign key';
    END IF;
END $$;

-- Step 2: Add the foreign key constraint
ALTER TABLE public.clubs
ADD CONSTRAINT clubs_owner_id_users_fkey
FOREIGN KEY (owner_id) 
REFERENCES public.users(id)
ON DELETE CASCADE;

-- Step 3: Verify the foreign key was created
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
    AND tc.table_name = 'clubs'
    AND kcu.column_name = 'owner_id';

-- =====================================================
-- INSTRUCTIONS:
-- 1. Go to Supabase SQL Editor:
--    https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/sql
-- 2. Copy this entire SQL file
-- 3. Paste into SQL Editor
-- 4. Click "Run" button (or press Ctrl+Enter)
-- 5. Verify output shows "✅ Foreign key created successfully!"
-- 6. Test admin dashboard again - it should work!
-- =====================================================
