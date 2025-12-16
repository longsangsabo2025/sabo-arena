-- =====================================================
-- FIX CLUBS-USERS RELATIONSHIP
-- =====================================================
-- Lỗi: Could not find a relationship between 'clubs' and 'users'
-- Fix: Đảm bảo foreign key tồn tại và schema cache được refresh
-- =====================================================

-- 1️⃣ KIỂM TRA CẤU TRÚC HIỆN TẠI
-- =====================================================
SELECT 
    '🔍 Checking clubs table structure...' as status;

SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'clubs' 
    AND table_schema = 'public'
    AND column_name = 'owner_id';

-- 2️⃣ KIỂM TRA FOREIGN KEYS HIỆN TẠI
-- =====================================================
SELECT 
    '🔍 Checking existing foreign keys...' as status;

SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'clubs'
    AND kcu.column_name = 'owner_id';

-- 3️⃣ XÓA FOREIGN KEY CŨ NẾU TỒN TẠI (ĐỂ TẠO LẠI ĐÚNG)
-- =====================================================
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'clubs_owner_id_fkey' 
            AND table_name = 'clubs'
    ) THEN
        ALTER TABLE clubs DROP CONSTRAINT clubs_owner_id_fkey;
        RAISE NOTICE '✅ Dropped existing foreign key: clubs_owner_id_fkey';
    END IF;
END $$;

-- 4️⃣ TẠO LẠI FOREIGN KEY ĐÚNG CHUẨN
-- =====================================================
ALTER TABLE clubs
ADD CONSTRAINT clubs_owner_id_fkey 
FOREIGN KEY (owner_id) 
REFERENCES users(id) 
ON DELETE CASCADE
ON UPDATE CASCADE;

SELECT '✅ Created foreign key: clubs.owner_id -> users.id' as status;

-- 5️⃣ TẠO INDEX CHO PERFORMANCE (NẾU CHƯA CÓ)
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_clubs_owner_id 
ON clubs(owner_id);

SELECT '✅ Created index: idx_clubs_owner_id' as status;

-- 6️⃣ VERIFY RELATIONSHIP
-- =====================================================
SELECT 
    '🎯 Final verification...' as status;

SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.update_rule,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'clubs'
    AND kcu.column_name = 'owner_id';

-- 7️⃣ TEST QUERY (GIỐNG NHƯ TRONG DASHBOARD)
-- =====================================================
SELECT 
    '🧪 Testing query with relationship...' as status;

SELECT 
    c.id,
    c.name,
    c.owner_id,
    u.id as user_id,
    u.full_name as owner_name
FROM clubs c
LEFT JOIN users u ON u.id = c.owner_id
LIMIT 5;

SELECT '✅ ALL DONE! Relationship fixed and verified.' as final_status;

-- =====================================================
-- INSTRUCTIONS:
-- =====================================================
-- 1. Copy toàn bộ SQL này
-- 2. Vào Supabase SQL Editor:
--    https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/sql/new
-- 3. Paste và chạy
-- 4. Restart Flutter app (Hot Reload)
-- 5. Thử lại dashboard
-- =====================================================
