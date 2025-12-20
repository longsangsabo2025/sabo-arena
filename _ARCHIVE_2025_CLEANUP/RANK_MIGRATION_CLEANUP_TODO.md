# 🧹 RANK MIGRATION - CLEANUP & TODO CHECKLIST

**Date:** December 20, 2025  
**Migration:** Remove K+ and I+ ranks, shift ELO ranges

---

## ✅ COMPLETED TASKS

### Code Updates
- [x] `lib/core/utils/sabo_rank_system.dart` - Updated to 10 ranks ✅
- [x] `lib/core/constants/ranking_constants.dart` - Updated to 10 ranks ✅
- [x] `lib/services/opponent_matching_service.dart` - Updated rank array ✅
- [x] `lib/services/tournament_elo_service.dart` - Fixed rank progression ✅
- [x] `lib/presentation/user_profile_screen/widgets/modern_profile_header_widget.dart` - Updated UI ✅
- [x] `lib/services/challenge_rules_service.dart` - Updated challenge logic ✅

### Documentation Created
- [x] `RANK_MIGRATION_PLAN.md` - Complete migration plan ✅
- [x] `RANK_MIGRATION_AUDIT_REPORT.md` - Full audit report ✅
- [x] `RANK_MIGRATION_CLEANUP_TODO.md` - This checklist ✅

### Scripts Created
- [x] `scripts/test_rank_migration.py` - Test suite ✅
- [x] `scripts/check_rank_tables.py` - Database verification ✅
- [x] `scripts/apply_rank_migration.py` - Migration helper ✅

---

## 🔴 CRITICAL TODO - DATABASE MIGRATION

### 1️⃣ Supabase rank_system Table ❌ **URGENT**
**Status:** Has 12 old ranks with K+ and I+  
**Action Required:**
```bash
# Run in Supabase SQL Editor:
sql_migrations/rank_system_migration_2025_remove_kplus_iplus.sql
```

**Expected Changes:**
- DELETE K+ (1100-1199) and I+ (1300-1399)
- UPDATE remaining 10 ranks with new ELO ranges
- ADD detailed stability descriptions

**Verification:**
```bash
python scripts/check_rank_tables.py
# Should show 10 ranks: K, I, H, H+, G, G+, F, F+, E, D, C
```

---

### 2️⃣ Supabase handicap_rules Table ❌ **URGENT**
**Status:** Empty - needs population  
**Action Required:**
```bash
# Run in Supabase SQL Editor:
sql_migrations/populate_handicap_rules.sql
```

**Expected Changes:**
- INSERT 24 handicap rules (4 rank diffs × 6 bet amounts)
- Based on `ChallengeRulesService.handicapMatrix`

**Verification:**
```bash
python scripts/check_rank_tables.py
# Should show 24 handicap rules
```

---

## 📋 MEDIUM PRIORITY - DOCUMENTATION CLEANUP

### Old Documentation Files
- [ ] **REVIEW:** `_CORE_DOCS_OPTIMIZED/` folder
  - Check for K+/I+ references
  - Update if needed
  - Location: `_CORE_DOCS_OPTIMIZED/*.md`

- [ ] **REVIEW:** `_DOCS/` folder
  - Check for outdated rank information
  - Update tournament/challenge docs
  - Location: `_DOCS/**/*.md`

- [ ] **ARCHIVE:** Old test scripts
  - `scripts/verify_test1_rewards.py` (tournament-specific, keep)
  - Any other rank-related test scripts?

---

## 🧪 LOW PRIORITY - OLD SCRIPTS CLEANUP

### Test Scripts to Review
```bash
# Check for old rank references in scripts
grep -r "K+" scripts/ --include="*.py"
grep -r "I+" scripts/ --include="*.py"
```

**Files Found:**
1. `scripts/test_rank_migration.py` - Keep (intentionally tests old ranks) ✅
2. Other scripts? - Need review

### SQL Migration Files
**Location:** `sql_migrations/`, `migrations_organized/`, `supabase/migrations/`

**Actions:**
- [ ] Move old migration files to archive
- [ ] Keep only:
  - `rank_system_migration_2025_remove_kplus_iplus.sql` ✅
  - `populate_handicap_rules.sql` ✅
  - Active migrations (check dates)

---

## 🗑️ ARCHIVE CANDIDATES

### Already Archived
- ✅ `_ARCHIVE_2025_CLEANUP/lib/` - Old code (not in use)

### To Consider for Archive
- [ ] Old rank-related markdown files
- [ ] Deprecated test scripts
- [ ] Old SQL migrations (pre-2025)

---

## 🎯 POST-MIGRATION VERIFICATION

### Manual Testing Checklist
After database migration is applied:

1. **Profile Screen**
   - [ ] Open user profile
   - [ ] Verify rank table shows 10 ranks
   - [ ] Check modal says "10 hạng" not "12 hạng"
   - [ ] Verify ELO max is 2099 not 2199

2. **Challenge System**
   - [ ] Create a challenge as K rank user
   - [ ] Verify can challenge I only (not H)
   - [ ] Check handicap calculation works
   - [ ] Verify SPA betting limits

3. **Tournament System**
   - [ ] Complete a tournament
   - [ ] Verify ELO changes apply correctly
   - [ ] Check rank change notifications
   - [ ] Verify users see correct new ranks

4. **Database Queries**
   ```bash
   # Run verification
   python scripts/check_rank_tables.py
   
   # Should show:
   # - 10 ranks in rank_system
   # - 24 rules in handicap_rules
   # - No K+ or I+ references
   ```

---

## 📊 IMPACT SUMMARY

### User Experience
- Users with 1100-1199 ELO: K+ → I (rank increase ⬆️)
- Users with 1300-1399 ELO: I+ → H (rank increase ⬆️)
- All users from I onwards: Move up one visual rank ⬆️

### System Changes
- **rank_system table:** 12 → 10 ranks
- **Flutter code:** 6 files updated
- **Challenge logic:** ±2 sub-ranks → ±1 rank
- **Database:** Migration required ❌

---

## 🚨 BLOCKING ISSUES

### Critical Blockers
1. ❌ **Database migration NOT applied** - rank_system still has 12 ranks
2. ❌ **handicap_rules table empty** - challenge system may fail

### Resolution Required
**Before deployment:**
1. Run `rank_system_migration_2025_remove_kplus_iplus.sql` in Supabase
2. Run `populate_handicap_rules.sql` in Supabase
3. Verify with `scripts/check_rank_tables.py`
4. Perform manual UI testing

---

## ✅ SUCCESS CRITERIA

Migration is complete when:
- [x] All 6 Flutter files updated with 10-rank system
- [x] Detailed stability descriptions added
- [x] Challenge rules updated for new logic
- [x] Audit report created
- [ ] **rank_system table has 10 ranks** ❌
- [ ] **handicap_rules table populated** ❌
- [ ] Manual UI testing passed
- [ ] No K+/I+ references in active code
- [ ] Documentation updated

---

## 📞 SUPPORT

**SQL Files Location:**
- `sql_migrations/rank_system_migration_2025_remove_kplus_iplus.sql`
- `sql_migrations/populate_handicap_rules.sql`

**Verification Scripts:**
- `scripts/check_rank_tables.py` - Check database state
- `scripts/apply_rank_migration.py` - Migration helper

**Documentation:**
- `RANK_MIGRATION_AUDIT_REPORT.md` - Full audit
- `RANK_MIGRATION_PLAN.md` - Original plan

---

**Created:** December 20, 2025  
**Last Updated:** December 20, 2025  
**Status:** ⚠️ Database migration pending
