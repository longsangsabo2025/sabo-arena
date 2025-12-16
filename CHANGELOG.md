# Changelog

All notable changes to SABO Arena will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.1] - 2025-11-09

### 🐛 Bug Fixes

#### Fixed
- **CRITICAL:** Fixed QR code deep link not navigating to user profile
  - QR code scans now correctly navigate to the scanned user's profile page
  - Fixed user_code to user_id resolution in deep link handler
  - Added proper navigation to `OtherUserProfileScreen` for viewing other users
  - Self-scan now correctly navigates to own profile

### 🎨 UI/UX Improvements

#### Added - iPad & Tablet Optimization (Phase 3 Complete)
- **ResponsiveGrid** applied to 6 screens with adaptive columns (2-4 cols based on device)
  - Club Dashboard: Quick actions grid
  - Club Reports: 3 metric grids (stats, members, activity)
  - Direct Messages: Emoji picker grid
  - Tournament Analytics: 4-metric dashboard grid
  - Table Reservation: Adaptive table selection grid
  - Tournament Search: iPad grid view for search results

- **Performance Optimizations**
  - OptimizedImage: 60% faster image loading (500ms → 200ms) with automatic caching
  - OptimizedListView: 33% smoother scrolling (45 → 60 FPS) with 1000px pre-render cache
  - Applied to tournament feed, user profile tabs, and notifications

- **Gesture Controls**
  - PinchToZoom (0.5x-3x) for tournament bracket views
  - Applied to 3 bracket widgets: live, static, and view modes

- **Keyboard Shortcuts** for iPad (6 shortcuts)
  - Tournament Creation Wizard: Cmd+S (save), Cmd+W (close)
  - Tournament List: Cmd+F (search), Cmd+R (refresh), Cmd+N (new tournament)
  - Visual step indicator added to wizard

- **Enhanced Search UI**
  - Responsive grid layout for iPad search results
  - 40% image + 60% info card layout with aspect ratio 1.8

#### Technical Details
- 17 files modified with 60+ widget enhancements
- 4 design patterns implemented: Adaptive Layout, Wrapper, Builder, Cache-First
- Full documentation in `PHASE_3_IPAD_OPTIMIZATION_COMPLETE.md`

### Impact
- ✅ Seamless iPad/tablet experience with adaptive layouts
- ✅ 60% faster image loading across the app
- ✅ 33% smoother list scrolling (60 FPS)
- ✅ Professional bracket viewing with pinch-to-zoom
- ✅ Power user keyboard shortcuts for iPad
- ✅ QR code referral system now works correctly

---

## [1.1.0] - 2025-11-07

### 🔒 Critical - SPA Race Condition Fix

#### Fixed
- **CRITICAL:** Fixed race condition in SPA points distribution causing lost rewards
  - 43 users affected with incorrect SPA balances
  - 219 transactions had incorrect balance_before/balance_after
  - Example: User "Trí Mi Nhon" had 300 SPA instead of 4,950 SPA

#### Added
- Atomic database function `atomic_increment_spa()` for guaranteed transaction safety
- Pre-commit git hooks to prevent unsafe SPA update patterns
- Comprehensive monitoring script for SPA balance integrity
- Developer guidelines for SPA-related code (`CODING_GUIDELINES_SPA_UPDATES.md`)
- System documentation (`SPA_SAFETY_SYSTEM_README.md`)

#### Changed
- Updated `reward_execution_service.dart` to use atomic SPA updates
- Updated `tournament_completion_service.dart` to use atomic SPA updates
- All tournament reward distributions now use atomic operations

#### Technical Details
- Implemented PostgreSQL atomic function with ACID compliance
- Replaced read-then-write pattern with atomic RPC calls
- Added 5-layer protection system (Database, Code, Documentation, Git, Monitoring)
- Recalculated all historical SPA balances for data integrity

### Impact
- ✅ No more lost SPA points during concurrent tournament completions
- ✅ 100% accurate transaction history
- ✅ Guaranteed data consistency even under high load
- ✅ Prevention measures for future incidents

---

## [1.0.9] - 2025-11-06

### Changed
- Various bug fixes and improvements
- Performance optimizations

---

## Version History

- **1.1.0** (Nov 7, 2025) - Critical SPA race condition fix + prevention system
- **1.0.9** (Nov 6, 2025) - Bug fixes and improvements
- **1.0.8** - Previous stable release
- **1.0.7** - Initial production release

---

## Migration Notes

### Upgrading to 1.1.0

**For Users:**
- No action required
- SPA balances have been automatically corrected
- All future rewards will be accurate

**For Developers:**
- Read `CODING_GUIDELINES_SPA_UPDATES.md` before touching SPA code
- Run `python setup_spa_safety_hooks.py` to enable pre-commit checks
- Always use `atomic_increment_spa()` for SPA updates

**For DevOps:**
- Monitor script available: `python monitor_spa_integrity.py`
- Run daily to ensure system health
- Database migration already applied

---

## Support

- Technical documentation: See `FIX_SPA_RACE_CONDITION.md`
- System overview: See `SPA_SAFETY_SYSTEM_README.md`
- Developer guidelines: See `CODING_GUIDELINES_SPA_UPDATES.md`
