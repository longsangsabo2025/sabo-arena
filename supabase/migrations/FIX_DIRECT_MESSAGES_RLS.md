# Fix Direct Messages RLS Error

## Problem
When clicking "Nhắn tin" button, getting error:
```
PostgresException(message: new row violates row-level security policy for table "chat_rooms", code: 42501)
```

## Root Cause
The RLS policy for `chat_rooms` table only allows INSERT for club members. Direct messages (type='direct') have `club_id = NULL`, so they are blocked.

## Solution
Run the migration file: `20250114000001_fix_direct_messages_rls.sql`

### Option 1: Run in Supabase Dashboard (Recommended)

1. Go to https://supabase.com/dashboard
2. Select your project: **mogjjvscxjwvhtpkrlqr**
3. Click **SQL Editor** in left sidebar
4. Click **New Query**
5. Copy and paste the entire content of `supabase/migrations/20250114000001_fix_direct_messages_rls.sql`
6. Click **Run** (or press F5)
7. Verify success message

### Option 2: Using Supabase CLI

If you have Supabase CLI installed:

```bash
cd d:\0.APP\1310\saboarenav4
supabase db push
```

## What the Migration Does

1. **Makes `club_id` nullable** - Allows direct messages without club
2. **Updates INSERT policy** - Allows users to create direct messages (type='direct')
3. **Updates SELECT policy** - Allows users to view their direct messages
4. **Updates chat_room_members policy** - Allows adding members to direct messages
5. **Adds index on `type`** - Improves query performance

## After Migration

Test the feature:
1. Hot restart the app (press `R` in Flutter terminal)
2. Go to another user's profile
3. Click "Nhắn tin"
4. Should open chat screen directly ✅

## Files Modified
- Created: `supabase/migrations/20250114000001_fix_direct_messages_rls.sql`
- No Dart code changes needed

## Verification Query

After running migration, verify with this SQL:

```sql
-- Check if club_id is nullable
SELECT 
  column_name, 
  is_nullable, 
  data_type 
FROM information_schema.columns 
WHERE table_name = 'chat_rooms' 
  AND column_name = 'club_id';

-- Check RLS policies
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  cmd 
FROM pg_policies 
WHERE tablename = 'chat_rooms';
```

Expected: `club_id` should show `is_nullable = YES`
