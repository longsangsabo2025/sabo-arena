-- =====================================================
-- 🎯 COMPLETE FIX FOR "DATABASE ERROR FINDING USER"
-- =====================================================
-- Chạy script này trong Supabase Dashboard → SQL Editor
-- =====================================================

-- 1️⃣ DROP existing trigger và function để tạo mới hoàn toàn
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- 2️⃣ TẠO FUNCTION MỚI với error handling chi tiết
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Log bắt đầu
  RAISE LOG 'handle_new_user triggered for user: %', NEW.id;
  
  -- Insert vào public.users
  INSERT INTO public.users (
    id,
    email,
    full_name,
    role,
    skill_level,
    is_active,
    is_online,
    spa_points,
    favorite_game,
    is_available_for_challenges,
    preferred_match_type,
    max_challenge_distance,
    created_at,
    updated_at,
    last_seen
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'player'),
    'beginner',
    true,
    true,
    0,
    '8-Ball',
    true,
    'both',
    10,
    NOW(),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, public.users.full_name),
    updated_at = NOW();
  
  -- Log thành công
  RAISE LOG 'User % created successfully in public.users', NEW.id;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log lỗi CHI TIẾT
    RAISE WARNING 'Error in handle_new_user for user %: % (SQLSTATE: %)', 
      NEW.id, SQLERRM, SQLSTATE;
    -- VẪN return NEW để không block signup
    RETURN NEW;
END;
$$;

-- 3️⃣ GRANT PERMISSIONS cho function
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;

-- 4️⃣ TẠO TRIGGER trên auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 5️⃣ VERIFY trigger được tạo
SELECT 
    tgname as trigger_name,
    tgenabled as status,
    pg_get_triggerdef(oid) as definition
FROM pg_trigger
WHERE tgrelid = 'auth.users'::regclass
  AND NOT tgisinternal;

-- 6️⃣ TEST với user giả
DO $$
DECLARE
  test_email TEXT := 'sql_test_' || extract(epoch from now())::text || '@test.com';
  test_id UUID := gen_random_uuid();
BEGIN
  -- Insert vào auth.users (sẽ trigger function)
  INSERT INTO auth.users (
    id, 
    instance_id,
    email, 
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_user_meta_data,
    aud,
    role
  ) VALUES (
    test_id,
    '00000000-0000-0000-0000-000000000000',
    test_email,
    crypt('Test123!', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    jsonb_build_object('full_name', 'SQL Test User'),
    'authenticated',
    'authenticated'
  );
  
  -- Check xem user có trong public.users không
  IF EXISTS (SELECT 1 FROM public.users WHERE id = test_id) THEN
    RAISE NOTICE '✅ TEST PASSED! User % exists in public.users', test_id;
  ELSE
    RAISE WARNING '❌ TEST FAILED! User % NOT found in public.users', test_id;
  END IF;
END $$;

-- 7️⃣ CHECK RLS policies trên public.users
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'users'
ORDER BY policyname;

-- =====================================================
-- ✅ DONE! Trigger đã được tạo và test
-- =====================================================
-- Bây giờ thử đăng ký trong Flutter app!
-- =====================================================
