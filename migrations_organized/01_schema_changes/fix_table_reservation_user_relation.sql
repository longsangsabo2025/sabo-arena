-- =====================================================
-- FIX: table_reservations <-> users relationship
-- Issue: PostgREST cannot join auth.users directly
-- Solution: Create public.users view or remove join
-- =====================================================

-- Option 1: Create a public.users view (RECOMMENDED if not exists)
-- This allows joining user data in queries
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'users'
  ) THEN
    -- Check if it's a view
    IF NOT EXISTS (
      SELECT FROM pg_views
      WHERE schemaname = 'public'
      AND viewname = 'users'
    ) THEN
      CREATE OR REPLACE VIEW public.users AS
      SELECT 
        id,
        email,
        raw_user_meta_data->>'full_name' as full_name,
        raw_user_meta_data->>'display_name' as display_name,
        raw_user_meta_data->>'avatar_url' as avatar_url,
        created_at,
        updated_at
      FROM auth.users;
      
      RAISE NOTICE '✅ Created public.users view';
    ELSE
      RAISE NOTICE '✅ public.users view already exists';
    END IF;
  ELSE
    RAISE NOTICE '✅ public.users table already exists';
  END IF;
END $$;

-- Grant permissions on the view
GRANT SELECT ON public.users TO authenticated;
GRANT SELECT ON public.users TO anon;

-- =====================================================
-- Alternative: Check if public.users table exists
-- =====================================================
DO $$
BEGIN
  -- If public.users table exists with proper columns
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'users'
  ) THEN
    -- Add foreign key if not exists (from table_reservations to public.users)
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'table_reservations_user_id_fkey'
      AND table_name = 'table_reservations'
    ) THEN
      -- Note: This might fail if referencing auth.users already
      -- ALTER TABLE table_reservations 
      -- ADD CONSTRAINT table_reservations_user_id_fkey 
      -- FOREIGN KEY (user_id) REFERENCES public.users(id);
      
      RAISE NOTICE '⚠️ Check existing foreign key constraint';
    END IF;
  END IF;
END $$;

-- =====================================================
-- Verify the setup
-- =====================================================
DO $$
DECLARE
  v_has_public_users BOOLEAN;
  v_has_auth_fk BOOLEAN;
BEGIN
  -- Check if public.users exists (table or view)
  SELECT EXISTS (
    SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users'
  ) OR EXISTS (
    SELECT FROM pg_views WHERE schemaname = 'public' AND viewname = 'users'
  ) INTO v_has_public_users;
  
  -- Check current foreign key
  SELECT EXISTS (
    SELECT 1 FROM information_schema.key_column_usage kcu
    JOIN information_schema.referential_constraints rc 
      ON kcu.constraint_name = rc.constraint_name
    WHERE kcu.table_name = 'table_reservations'
    AND kcu.column_name = 'user_id'
  ) INTO v_has_auth_fk;
  
  RAISE NOTICE '=====================================';
  RAISE NOTICE 'VERIFICATION RESULTS:';
  RAISE NOTICE '=====================================';
  RAISE NOTICE 'public.users exists: %', v_has_public_users;
  RAISE NOTICE 'table_reservations.user_id has FK: %', v_has_auth_fk;
  RAISE NOTICE '=====================================';
  
  IF v_has_public_users THEN
    RAISE NOTICE '✅ You can now use: user:users(*) in queries';
  ELSE
    RAISE NOTICE '⚠️ Need to create public.users table/view first';
  END IF;
END $$;
