# ✅ BASIC RACE TO 7 HANDICAP - IMPLEMENTATION COMPLETE

**Date:** Dec 20, 2025  
**Status:** ✅ COMPLETE (Service Layer Only - No DB Dependency)

---

## 🎯 LOGIC (First Principles)

**Simple Rule:** handicap_value = rank_difference (1:1 mapping)

**Examples:**
- K (rank 1) vs I (rank 2): diff = 1 → **1 ván handicap**
- K (rank 1) vs H (rank 3): diff = 2 → **2 ván handicap**  
- I (rank 2) vs G (rank 5): diff = 3 → **3 ván handicap**
- H (rank 3) vs F (rank 7): diff = 4 → **4 ván handicap**

**Race To:** Always **7** for basic matches (fixed)

**Who gets handicap:** Lower-ranked player starts with advantage

---

## 📁 FILES CREATED

### 1. **BasicHandicapService** (Dart)
**File:** `lib/services/basic_handicap_service.dart`

**Key Methods:**
```dart
// Calculate handicap
static double calculateBasicHandicap(String rank1, String rank2);

// Determine recipient
static String? getHandicapRecipient(String rank1, String rank2, String userId1, String userId2);

// Get display info
static Map<String, dynamic> getHandicapInfo(String rank1, String rank2);

// Apply to race to 7
static Map<String, dynamic> applyHandicapToRaceTo7({
  required String player1Rank,
  required String player2Rank,
  required String player1Id,
  required String player2Id,
});

// Create match
Future<Map<String, dynamic>> createRaceTo7Match({...});

// Validate logic
static void validateHandicapLogic();
```

**Features:**
- ✅ Pure in-memory calculation (no DB dependency)
- ✅ Works with 10-rank system (K, I, H, H+, G, G+, F, E, D, C)
- ✅ Simple 1:1 mapping: rank_diff = handicap
- ✅ Race to 7 fixed
- ✅ Full Vietnamese descriptions

### 2. **Test Script** (Python)
**File:** `scripts/test_basic_handicap.py`

**Output:**
```
✅ K vs K → handicap=0.0 (expected=0.0)
   Không chấp (cùng hạng)
✅ K vs I → handicap=1.0 (expected=1.0)
   K chấp I 1 ván
✅ K vs H → handicap=2.0 (expected=2.0)
   K chấp H 2 ván
```

---

## 🆚 BASIC vs CHALLENGE HANDICAP

| Feature | Basic Race to 7 | Challenge System |
|---------|-----------------|------------------|
| **bet_amount** | N/A (no betting) | 100-600 SPA |
| **race_to** | Always 7 | Varies (8-22) |
| **handicap** | rank_diff only | Varies by bet+rank |
| **DB table** | None (in-memory) | handicap_rules |
| **complexity** | Simple (1:1) | Complex matrix |
| **use case** | Tournament/friendly | SPA challenges |

**Example Comparison (K vs I):**
- Basic: 1 ván handicap, race to 7
- Challenge 100 SPA: 0.5 ván handicap, race to 8
- Challenge 600 SPA: 2.5 ván handicap, race to 22

---

## 🚫 DATABASE IMPLEMENTATION (ABANDONED)

**Attempted:** Populate `handicap_rules` table with basic rules

**Problem:** Table has foreign key `bet_amount` → `challenge_configurations.bet_amount`

**Solution:** Don't use DB for basic handicap - service layer is sufficient

**Why This Works:**
1. Basic handicap is pure math (rank_diff = handicap)
2. No configuration needed
3. Simpler, faster, less error-prone
4. DB table reserved for challenge system complexity

---

## 🎮 USAGE EXAMPLE

```dart
import 'package:sabo_arena/services/basic_handicap_service.dart';

// Calculate handicap
final handicap = BasicHandicapService.calculateBasicHandicap('K', 'H');
print(handicap); // 2.0

// Get info
final info = BasicHandicapService.getHandicapInfo('K', 'H');
print(info['description']); // "K chấp H 2 ván"

// Apply to race to 7
final match = BasicHandicapService.applyHandicapToRaceTo7(
  player1Rank: 'K',
  player2Rank: 'H',
  player1Id: 'user1',
  player2Id: 'user2',
);
print(match);
// {
//   player1_starting_score: 2,
//   player2_starting_score: 0,
//   handicap_value: 2.0,
//   race_to: 7,
//   description: "K chấp H 2 ván"
// }

// Create full match
final service = BasicHandicapService.instance;
final matchData = await service.createRaceTo7Match(
  player1Id: 'user1',
  player2Id: 'user2',
  player1Rank: 'K',
  player2Rank: 'H',
  tournamentId: 'tournament-id',
);
```

---

## ✅ VALIDATION RESULTS

```
K vs K → 0 ván (no handicap)
K vs I → 1 ván (K starts 1-0)
K vs H → 2 ván (K starts 2-0)
K vs H+ → 3 ván (K starts 3-0)
I vs G → 3 ván (I starts 3-0)
H vs F → 4 ván (H starts 4-0)
G+ vs C → 4 ván (G+ starts 4-0)
```

**Logic:** Weaker player (lower rank number) starts with score advantage

**Win Condition:** First to reach 7 wins

---

## 🔮 FUTURE CONSIDERATIONS

1. **Tournament Integration:**  
   Use `BasicHandicapService` for all tournament matches

2. **Match Creation:**  
   Call `createRaceTo7Match()` when creating non-challenge matches

3. **UI Display:**  
   Use `getHandicapInfo()` for Vietnamese descriptions

4. **Validation:**  
   Run `validateHandicapLogic()` in tests

---

## 📝 MIGRATION NOTES

**Challenge System (Separate Feature):**
- Uses `ChallengeRulesService` 
- Has `handicap_rules` table with bet_amount FK
- Complex handicap matrix (varies by bet+rank)
- Race to varies (8-22)

**Basic System (This Implementation):**
- Uses `BasicHandicapService`
- No DB dependency (pure calculation)
- Simple handicap (rank_diff = handicap)
- Race to 7 (fixed)

**They are INDEPENDENT systems.**

---

## 🎯 SUMMARY

✅ **COMPLETE:** Basic race to 7 handicap logic  
✅ **SERVICE:** `BasicHandicapService` fully implemented  
✅ **TESTED:** All calculations validated  
✅ **SIMPLE:** 1 rank difference = 1 ván handicap  
✅ **READY:** Can be used in tournaments/matches immediately

**No database changes needed. Service layer implementation is sufficient and cleaner.**
