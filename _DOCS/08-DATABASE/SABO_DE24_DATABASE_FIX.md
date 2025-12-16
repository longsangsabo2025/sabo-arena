# 🔧 SABO DE24 Database Fix

## ❌ Problem

When trying to create a SABO DE24 tournament, you get this error:

```
Exception: Failed to create tournament: PostgrestException(
  message: new row for relation "tournaments" violates check constraint "check_bracket_format", 
  code: 23514
)
```

## 🎯 Root Cause

The `tournaments` table has a constraint called `check_bracket_format` that validates the `bracket_format` column. Currently, it only allows these values:

- `single_elimination`
- `double_elimination`
- `round_robin`
- `sabo_de8`
- `sabo_de16`
- `sabo_de32`
- `sabo_de64`

**Missing:** `sabo_de24` ❌

## ✅ Solution

Add `sabo_de24` to the constraint in the database.

### Steps:

1. **Go to Supabase Dashboard:**
   - URL: https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr
   - Or: https://supabase.com → Select your project

2. **Open SQL Editor:**
   - Click "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Copy and paste this SQL:**

```sql
-- Drop existing constraint
ALTER TABLE tournaments 
DROP CONSTRAINT IF EXISTS check_bracket_format;

-- Add new constraint with sabo_de24 included
ALTER TABLE tournaments 
ADD CONSTRAINT check_bracket_format 
CHECK (bracket_format IN (
    'single_elimination',
    'double_elimination', 
    'round_robin',
    'sabo_de8',
    'sabo_de16',
    'sabo_de24',
    'sabo_de32',
    'sabo_de64'
));
```

4. **Click "Run" (or press Ctrl+Enter)**

5. **Verify:**
   - You should see: "Success. No rows returned"
   - The constraint is now updated

## 🎉 After Fix

Once the SQL runs successfully:

✅ You can create SABO DE24 tournaments
✅ All 8 bracket formats are now allowed
✅ No more constraint violation errors

## 📝 Technical Details

**What is a CHECK constraint?**
- A database rule that validates data before insertion
- Ensures only allowed values are stored
- Prevents invalid bracket formats

**Why was sabo_de24 missing?**
- The constraint was created before DE24 was implemented
- Each new format needs to be added to the constraint
- This is a one-time database migration

**Files involved:**
- `lib/services/hardcoded_sabo_de24_service.dart` - DE24 service implementation
- `lib/presentation/tournament_wizard/enhanced_basic_info_step.dart` - UI with DE24 option
- Database: `tournaments` table constraint

## 🔍 Verification Query

After running the fix, you can verify with:

```sql
SELECT conname, pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'tournaments'::regclass
AND conname = 'check_bracket_format';
```

Expected result should include: `'sabo_de24'` in the list.

## 🚨 Common Issues

**Issue:** "Permission denied"
- **Solution:** Make sure you're logged in as the project owner or have admin access

**Issue:** "Relation tournaments does not exist"
- **Solution:** Check that you're connected to the correct database/project

**Issue:** SQL runs but still getting error
- **Solution:** Try refreshing the app or restarting the Flutter app (hot reload may not be enough)

## 📚 Related

- **DE24 Implementation:** `SABO_DE24_FORMAT.md`
- **Quick Start:** `QUICK_START_DE24.md`
- **Integration:** `SABO_DE24_INTEGRATION_COMPLETE.md`
- **Similar fixes:** See `FINAL_STATUS_DE64.txt` for DE64 constraint fix example
