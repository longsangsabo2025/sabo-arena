-- ========================================
-- ADD INITIALIZATION TRACKING COLUMNS
-- ========================================
-- Run this in Supabase Dashboard > SQL Editor

-- Add columns to track post-registration initialization
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS initialization_status TEXT DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS initialization_completed_at TIMESTAMPTZ;

-- Add index for faster queries on initialization_status
CREATE INDEX IF NOT EXISTS idx_users_initialization_status 
ON public.users(initialization_status);

-- Add column comments for documentation
COMMENT ON COLUMN public.users.initialization_status IS 
'Tracks post-registration initialization status: pending, in_progress, completed, failed';

COMMENT ON COLUMN public.users.initialization_completed_at IS 
'Timestamp when user initialization (welcome notif, referral code, etc.) was completed';

-- ========================================
-- MIGRATION FOR EXISTING USERS
-- ========================================
-- Set all existing users to 'completed' status
-- (assume they're already initialized through old flow)

UPDATE public.users
SET 
  initialization_status = 'completed',
  initialization_completed_at = COALESCE(initialization_completed_at, created_at)
WHERE initialization_status IS NULL 
   OR initialization_status = 'pending';

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- Check if columns were added successfully
SELECT 
  column_name, 
  data_type, 
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'users' 
  AND column_name IN ('initialization_status', 'initialization_completed_at')
ORDER BY ordinal_position;

-- Check initialization status distribution
SELECT 
  initialization_status,
  COUNT(*) as user_count
FROM public.users
GROUP BY initialization_status
ORDER BY user_count DESC;

-- View users needing initialization (should be only NEW registrations after this fix)
SELECT 
  id,
  email,
  full_name,
  initialization_status,
  initialization_completed_at,
  created_at
FROM public.users
WHERE initialization_status != 'completed'
ORDER BY created_at DESC
LIMIT 20;

-- ========================================
-- SUCCESS MESSAGE
-- ========================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '✅ Initialization tracking columns added successfully!';
  RAISE NOTICE '';
  RAISE NOTICE '📊 Next steps:';
  RAISE NOTICE '  1. Restart Flutter app';
  RAISE NOTICE '  2. Test new user registration';
  RAISE NOTICE '  3. Check logs for: 🎯 User needs initialization';
  RAISE NOTICE '  4. Verify welcome notification appears';
  RAISE NOTICE '';
END $$;
