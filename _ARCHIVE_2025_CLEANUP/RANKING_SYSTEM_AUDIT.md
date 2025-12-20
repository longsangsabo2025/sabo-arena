## 🔍 KIỂM TRA HỆ THỐNG PHÂN HẠNG & ELO - SABO ARENA

### 📊 1. LOGIC TÍNH ELO (Position-Based)

**File:** `tournament_rankings_widget.dart` (lines 936-953)
```dart
int _calculateEloBonus(int position, int totalParticipants) {
  if (position == 1) return 75;      // 🥇 Champion
  if (position == 2) return 50;      // 🥈 Runner-up  
  if (position == 3 || position == 4) return 35;  // 🥉 Semi-finalists
  if (position <= totalParticipants * 0.25) return 25;  // Top 25%
  if (position <= totalParticipants * 0.5) return 15;   // Top 50%
  if (position <= totalParticipants * 0.75) return 10;  // Top 75%
  return -5;  // Bottom 25%
}
```

**✅ ĐÚNG:** Dùng `position` (1, 2, 3, 4, 5...) thay vì `rank` (có thể có ties)

---

### 🏆 2. LOGIC TÍNH SPA (Position-Based)

**File:** `tournament_rankings_widget.dart` (lines 959-977)
```dart
int _calculateSpaBonus(int position, int totalParticipants) {
  final top25 = (totalParticipants * 0.25).ceil();
  final top50 = (totalParticipants * 0.5).ceil();
  final top75 = (totalParticipants * 0.75).ceil();
  
  if (position == 1) return 1000;    // 🥇 Winner
  if (position == 2) return 800;     // 🥈 Runner-up
  if (position == 3 || position == 4) return 550;  // 🥉 Semi-finalists
  if (position <= top25) return 400;  // Top 25%
  if (position <= top50) return 300;  // Top 50%
  if (position <= top75) return 200;  // Top 75%
  return 100;  // Participation
}
```

**✅ ĐÚNG:** Cũng dùng `position`, đúng với spec

---

### 🎯 3. LOGIC PHÂN HẠNG (Bracket-Based)

**File:** `tournament_rankings_widget.dart` (lines 864-925)

#### Method: `_assignBracketPositions()`

**Cách hoạt động:**
1. Query tất cả matches, sắp xếp theo `round_number` DESC (Finals trước)
2. Phân loại theo `round_name`:
   - Finals → champion (rank 1), runner-up (rank 2)
   - Semi-finals losers → rank 3 (tie)
   - Quarter-finals losers → rank 5 (tie)
   - Round of 16 losers → rank 9 (tie)
   - Round of 32 losers → rank 17 (tie)
3. Gán `bracket_rank` cho từng player
4. Players chưa eliminated → `bracket_rank = 999`

**Ví dụ với 6 người:**
- ĐAT KING (Finals winner) → bracket_rank = 1
- Minh Anh (Finals loser) → bracket_rank = 2  
- Danh HVT (Semi loser) → bracket_rank = 3
- An Phát (Semi loser) → bracket_rank = 3
- Cu Tèo (Semi loser) → bracket_rank = 3
- User (chưa thua) → bracket_rank = 999

**✅ ĐÚNG:** Logic bracket position chính xác

---

### 🔄 4. SORTING LOGIC (Live Rankings)

**File:** `tournament_rankings_widget.dart` (lines 314-328)

```dart
rankings.sort((a, b) {
  // Primary: bracket_rank (1 < 2 < 3 < 5...)
  final rankA = a['bracket_rank'] as int? ?? 999;
  final rankB = b['bracket_rank'] as int? ?? 999;
  if (rankA != rankB) return rankA.compareTo(rankB);
  
  // Tie-break: wins (higher wins = better)
  final winsA = a['wins'] as int? ?? 0;
  final winsB = b['wins'] as int? ?? 0;
  if (winsA != winsB) return winsB.compareTo(winsA);
  
  // Final tie-break: win rate
  return (b['win_rate'] as num).toDouble().compareTo(
    (a['win_rate'] as num).toDouble(),
  );
});
```

**✅ ĐÚNG:** Sắp xếp theo bracket_rank trước, sau đó mới đến wins

---

### 💰 5. REWARD EXECUTION SERVICE

**File:** `reward_execution_service.dart`

#### Workflow:
1. Đọc từ `tournament_results` (SOURCE OF TRUTH)
2. Execute 3 actions:
   - `_executeSpaReward()` → Insert vào `spa_transactions` + Update `users.spa_balance` (atomic)
   - `_executeEloChange()` → Insert vào `elo_history` + Update `users.elo_rating`
   - `_updateUserStats()` → Update aggregated stats

#### ✅ Features:
- **IDEMPOTENT:** Check existing records trước khi insert
- **ATOMIC:** Dùng PostgreSQL function `atomic_increment_spa` để tránh race condition
- **ERROR HANDLING:** Try-catch cho từng player, không fail toàn bộ

---

### 🎨 6. UI DISPLAY LOGIC

**File:** `tournament_rankings_widget.dart` (lines 606-610)

```dart
Widget _buildRankingItem(Map<String, dynamic> ranking, int position) {
  final rank = ranking['rank'] as int? ?? position;
  final isTopFour = position <= 4;  // 🚀 CHỈ 4 NGƯỜI ĐẦU có màu/icon
  final bgColor = isTopFour ? _getTopThreeColor(rank) : Colors.white;
  // ...
}
```

**✅ FIXED:** Chỉ `position <= 4` có màu, rank 5+ màu trắng

---

### 📋 7. TOURNAMENT COMPLETION FLOW

**File:** `tournament_completion_orchestrator.dart`

```dart
Future<Map<String, dynamic>> completeTournament({
  bool executeRewards = true,  // 🚀 DEFAULT = TRUE
}) async {
  // 1. Capture UI data (rankings, bracket positions)
  final uiData = await UIDataCapture.captureUIRankings(...);
  
  // 2. Save to tournament_results (SOURCE OF TRUTH)
  await _saveTournamentResults(...);
  
  // 3. Execute rewards (if enabled)
  if (executeRewards) {
    await _executionService.executeRewardsFromResults(...);
  }
  
  // 4. Send notifications
  await _notificationService.sendTournamentCompletionNotifications(...);
  
  // 5. Update tournament status to 'completed'
  // ...
}
```

**✅ COMPLETE:** Full workflow từ capture → save → execute → notify

---

## ⚠️ POTENTIAL ISSUES

### 1. Round Name Matching
**Line 870:** `round.contains('final') && !round.contains('semi')`
- ❓ Case sensitive? "Final" vs "final"?
- ❓ Localization? "chung kết" vs "final"?

**Khuyến nghị:** Convert to lowercase trước khi check:
```dart
final round = (match['round_name'] as String?)?.toLowerCase() ?? '';
```

### 2. Position vs Rank Consistency
**tournament_rankings_widget.dart lines 394-400:**
```dart
rankings[i]['elo_bonus'] = _calculateEloBonus(
  position,  // ✅ FIXED: Dùng position thay vì currentRank
  totalParticipants,
);
```

**✅ ĐÃ FIX:** Trước đây dùng `currentRank` (sai), giờ dùng `position` (đúng)

### 3. Idempotency Risks
**reward_execution_service.dart:**
- ✅ Check existing `spa_transactions`
- ✅ Check existing `elo_history`
- ⚠️ Nếu 1 trong 2 fail, user có thể nhận 1 nửa rewards
- **Khuyến nghị:** Wrap trong transaction hoặc thêm `rewards_executed` flag

---

## 🧪 TEST SCENARIOS

### Test Case 1: 6 Players Tournament
**Input:**
- Finals: ĐAT KING (W) vs Minh Anh (L)
- Semi 1: ĐAT KING (W) vs Danh HVT (L)
- Semi 2: Minh Anh (W) vs An Phát (L)
- Quarter: Cu Tèo loses to someone

**Expected Ranking:**
1. ĐAT KING (bracket_rank=1) → +75 ELO, +1000 SPA
2. Minh Anh (bracket_rank=2) → +50 ELO, +800 SPA
3. Danh HVT (bracket_rank=3) → +35 ELO, +550 SPA
4. An Phát (bracket_rank=3) → +35 ELO, +550 SPA
5. Cu Tèo (bracket_rank=3) → +35 ELO ❌ **SHOULD BE +25!**

**⚠️ BUG FOUND:** Nếu có 3 người đồng hạng 3, Cu Tèo ở position 5 vẫn được +35 ELO!

**Root Cause:** Logic `position == 3 || position == 4` không cover trường hợp có nhiều hơn 2 người đồng hạng 3.

---

## 🎯 KẾT LUẬN

### ✅ ĐÚNG:
1. Bracket-based ranking logic
2. Position-based ELO/SPA calculation
3. Atomic SPA transactions
4. Idempotent reward execution
5. UI display (chỉ top 4 có màu)

### ⚠️ CẦN FIX:
1. **ELO bonus cho position 5+:** Hiện tại `position == 3 || position == 4` cứng, không linh hoạt với ties
2. Round name matching: Nên lowercase
3. Transaction safety: Wrap rewards execution trong transaction

### 📊 CURRENT STATUS:
- Code đã sửa: ✅ Position-based ELO (lines 394)
- Database: ⚠️ Tournament "test1" đã reset về `ongoing`, chưa execute rewards
- UI: ✅ Top 4 có màu, rank 5+ trắng
