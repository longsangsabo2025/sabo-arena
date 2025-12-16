-- =====================================================
-- FIX CLUB ROLES SYSTEM
-- Cập nhật constraint để cho phép: owner, admin, moderator, member, guest
-- =====================================================

-- Step 1: Drop old constraint
ALTER TABLE club_members 
DROP CONSTRAINT IF EXISTS club_members_role_check;

-- Step 2: Add new constraint
ALTER TABLE club_members 
ADD CONSTRAINT club_members_role_check 
CHECK (role IN ('owner', 'admin', 'moderator', 'member', 'guest'));

-- Step 3: Verify
SELECT 
    'Total members' as info,
    COUNT(*) as count
FROM club_members

UNION ALL

SELECT 
    'Role: ' || role as info,
    COUNT(*) as count
FROM club_members
GROUP BY role
ORDER BY info;

-- =====================================================
-- CHẠY SCRIPT NÀY TRÊN SUPABASE DASHBOARD:
-- 1. Vào https://supabase.com/dashboard
-- 2. Chọn project
-- 3. SQL Editor (bên trái)
-- 4. Copy paste script này vào
-- 5. Bấm Run hoặc Ctrl+Enter
-- =====================================================
