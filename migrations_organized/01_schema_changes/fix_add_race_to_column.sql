-- ====================================================================
-- FIX: Add race_to column to challenges table
-- Error: column challenges.race_to does not exist (code: 42703)
-- ====================================================================

-- Step 1: Add race_to column if not exists
ALTER TABLE public.challenges 
ADD COLUMN IF NOT EXISTS race_to INTEGER DEFAULT 7 CHECK (race_to > 0);

-- Step 2: Add comment
COMMENT ON COLUMN public.challenges.race_to IS 
'Race to X wins - number of games needed to win the match (default: 7)';

-- Step 3: Update existing NULL values to default
UPDATE public.challenges 
SET race_to = 7 
WHERE race_to IS NULL;

-- Step 4: Verify column exists
SELECT 
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'challenges' 
  AND column_name = 'race_to';

-- Step 5: Check sample data
SELECT 
    id,
    challenger_id,
    challenged_id,
    race_to,
    status,
    created_at
FROM public.challenges
ORDER BY created_at DESC
LIMIT 5;

-- ====================================================================
-- ✅ After running this SQL:
--    1. The app should work when updating challenge scores
--    2. Default race_to is 7 for all challenges
--    3. Users can specify different race_to when creating challenges
-- ====================================================================
