# 🚀 BATCH FIX STRATEGY - 300 FILES

**Date**: 2025-01-12  
**Status**: 🔄 **IN PROGRESS**

---

## 📊 STATISTICS

- **Total Files**: 302 files
- **Total Matches**: 5,848 hardcoded colors
- **Files Fixed**: 7 files (critical)
- **Remaining**: ~295 files

---

## 🎯 PRIORITY ORDER

### Batch 1: High Priority (Top 20 files with most matches)
1. ✅ user_profile_screen.dart - 74 matches
2. ✅ account_settings_screen.dart - 47 matches  
3. ✅ club_main_screen.dart - 65 matches (6 files)
4. ✅ tournament_detail_screen.dart - 1148 matches (48 files)
5. ✅ home_feed_screen.dart - 25 matches
6. ✅ tournament_list_screen.dart - 4 matches
7. ⏳ user_voucher_screen.dart - 18 matches
8. ⏳ tournament_registration_screen.dart - 77 matches
9. ⏳ spa_management - 95 matches
10. ⏳ loyalty_program - 22+ matches

### Batch 2: Medium Priority (Next 50 files)
- Widgets và components
- Settings screens
- Staff screens

### Batch 3: Low Priority (Remaining files)
- Demo brackets
- Legacy code
- Less frequently used screens

---

## 🔧 FIX PATTERNS

### Common Replacements:
- `Colors.white` → `AppColors.surface`
- `Colors.black` → `AppColors.textPrimary`
- `Colors.grey` → `AppColors.textSecondary`
- `Colors.grey.shadeX` → `AppColors.grayX`
- `Colors.red` → `AppColors.error`
- `Colors.green` → `AppColors.success`
- `Colors.blue` → `AppColors.info` or `AppColors.primary`
- `Colors.orange` → `AppColors.warning`
- `Colors.yellow` → `AppColors.warning`
- `Colors.purple` → `AppColors.premium`
- `Colors.amber` → `AppColors.accent`

### Spacing Replacements:
- `SizedBox(height: X)` → `SizedBox(height: DesignTokens.spaceX)`
- `SizedBox(width: X)` → `SizedBox(width: DesignTokens.spaceX)`
- `EdgeInsets.all(X)` → `EdgeInsets.all(DesignTokens.spaceX)`
- `padding: EdgeInsets.all(X)` → `padding: EdgeInsets.all(DesignTokens.spaceX)`
- `margin: EdgeInsets.all(X)` → `margin: EdgeInsets.all(DesignTokens.spaceX)`

### Border Radius Replacements:
- `BorderRadius.circular(X)` → `BorderRadius.circular(DesignTokens.radiusX)`
- `Radius.circular(X)` → `Radius.circular(DesignTokens.radiusX)`

---

## ✅ PROGRESS TRACKING

### Completed Files (7):
1. ✅ voucher_management_main_screen.dart
2. ✅ tournament_template_selection_widget.dart
3. ✅ my_reservations_screen.dart
4. ✅ leaderboard_screen.dart
5. ✅ table_reservation_screen.dart
6. ✅ payment_history_screen.dart
7. ✅ admin_voucher_campaign_approval_screen.dart

### In Progress:
- ⏳ user_profile_screen.dart

### Next:
- ⏳ account_settings_screen.dart
- ⏳ club_main_screen.dart
- ⏳ tournament_detail_screen.dart (48 files)

---

## 🎯 GOAL

Fix all 302 files to use design system consistently.

**Estimated Time**: 
- Batch 1: ~2-3 hours
- Batch 2: ~4-5 hours  
- Batch 3: ~6-8 hours
- **Total**: ~12-16 hours

---

**Status**: 🔄 **BATCH 1 IN PROGRESS**

