# 🎯 ELO UPDATE FLOW - Luồng cập nhật ELO trong tương lai

## 📊 OVERVIEW

Sau khi fix bug, ELO sẽ được cập nhật **CHÍNH XÁC** qua flow sau:

```
USER ACTION (UI)
      ↓
Tournament Settings Tab
      ↓
"Hoàn thành giải đấu" Button
      ↓
TournamentCompletionOrchestrator
      ↓
RewardExecutionService ✅ (FIXED)
      ↓
Database Update (users + elo_history)
```

---

## 🔄 DETAILED FLOW

### 1️⃣ USER ACTION (Club Owner/Admin)

**File**: `lib/presentation/tournament_detail_screen/widgets/tournament_settings_tab.dart`

**UI Button**: "Hoàn thành giải đấu" (Line 550)
```dart
ElevatedButton.icon(
  onPressed: _isCompleting ? null : _completeTournament,
  label: Text('Hoàn thành giải đấu'),
)
```

**Điều kiện**: 
- Tournament status = 'in_progress'
- Tất cả matches đã completed
- User là club owner hoặc admin

---

### 2️⃣ ORCHESTRATOR COORDINATION

**File**: `lib/services/tournament/tournament_completion_orchestrator.dart`

**Method**: `completeTournament()` (Line 50)

```dart
final result = await _completionService.completeTournament(
  tournamentId: widget.tournamentId,
  sendNotifications: true,
  updateElo: true,              // ✅ Enable ELO update
  distributePrizes: true,
  issueVouchers: true,
  executeRewards: false,        // ⚠️ FALSE by default!
);
```

**⚠️ QUAN TRỌNG**: 
- `executeRewards: false` → Rewards KHÔNG tự động execute
- Admin phải dùng **"Gửi Quà" Button** để distribute rewards

---

### 3️⃣ MANUAL REWARD DISTRIBUTION

**File**: `lib/presentation/widgets/reward_distribution_button.dart`

**Button**: "Gửi Quà" / "Reward Distribution" (Line 70-80)

```dart
final rewardService = RewardExecutionService();
final success = await rewardService.executeRewardsFromResults(
  tournamentId: widget.tournamentId,
);
```

**Flow từ button này**:
1. User clicks "Gửi Quà" button
2. RewardDistributionButton calls RewardExecutionService
3. RewardExecutionService reads from `tournament_results` table
4. For each participant:
   - ✅ UPDATE `users.elo_rating`
   - ✅ INSERT to `elo_history`
   - ✅ UPDATE `spa_transactions`
   - ✅ UPDATE user stats (wins, losses, tournaments)

---

### 4️⃣ REWARD EXECUTION SERVICE ✅ (FIXED)

**File**: `lib/services/tournament/reward_execution_service.dart`

**Method**: `executeRewardsFromResults()` → `_executeEloChange()` (Line 175-210)

```dart
Future<void> _executeEloChange({
  required String tournamentId,
  required String userId,
  required int eloChange,
  required int position,
}) async {
  try {
    // 1. Get current ELO
    final userResponse = await _supabase
        .from('users')
        .select('elo_rating')
        .eq('id', userId)
        .single();

    final oldElo = userResponse['elo_rating'] as int? ?? 1500;
    final newElo = oldElo + eloChange;

    // ✅ 2. UPDATE users.elo_rating FIRST (CRITICAL FIX)
    await _supabase.from('users').update({
      'elo_rating': newElo,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    // ✅ 3. CREATE history record
    await _supabase.from('elo_history').insert({
      'user_id': userId,
      'tournament_id': tournamentId,
      'old_elo': oldElo,
      'new_elo': newElo,
      'elo_change': eloChange,
      'reason': 'Tournament completion (position $position)',
      'created_at': DateTime.now().toIso8601String(),
    });

    debugPrint('✅ [ELO] Updated user ELO: $oldElo → $newElo');
    debugPrint('✅ [ELO] Created history: ${eloChange >= 0 ? '+' : ''}$eloChange ELO');
  } catch (e) {
    debugPrint('❌ [ELO] Error updating ELO: $e');
    rethrow;
  }
}
```

---

### 5️⃣ DATABASE UPDATES

**Table 1: `users`** (Profile ELO)
```sql
UPDATE users 
SET 
  elo_rating = {newElo},
  updated_at = NOW()
WHERE id = {userId};
```

**Table 2: `elo_history`** (Audit Trail)
```sql
INSERT INTO elo_history (
  user_id,
  tournament_id,
  old_elo,
  new_elo,
  elo_change,
  reason,
  created_at
) VALUES (
  {userId},
  {tournamentId},
  {oldElo},
  {newElo},
  {eloChange},
  'Tournament completion (position {position})',
  NOW()
);
```

---

## 🎭 FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────────┐
│                    TOURNAMENT COMPLETE                      │
│                  (Admin clicks button)                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│          TournamentCompletionOrchestrator                   │
│  • Save results to tournament_results (source of truth)     │
│  • Mark tournament as completed                             │
│  • Send notifications                                       │
│  • Issue vouchers                                           │
│  • executeRewards = FALSE (default)                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│               REWARDS NOT EXECUTED YET                      │
│          (Waiting for manual distribution)                  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ↓
        ┌─────────────────────────────┐
        │  Admin clicks "Gửi Quà"     │
        │  (Reward Distribution)      │
        └─────────────┬───────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│              RewardExecutionService                         │
│  1. Read tournament_results                                 │
│  2. For each participant:                                   │
│     ├─ Execute SPA reward                                   │
│     ├─ Execute ELO change ✅                                │
│     └─ Update user stats                                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                  _executeEloChange()                        │
│  ✅ Step 1: UPDATE users.elo_rating                         │
│  ✅ Step 2: INSERT to elo_history                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                DATABASE UPDATED                             │
│  ✅ users.elo_rating = newElo                               │
│  ✅ elo_history record created                              │
│  ✅ Profile shows correct ELO                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 IMPORTANT NOTES

### ✅ Bug đã được FIX:

**Before (BUG)**:
```dart
// ❌ Only inserted to elo_history
await _supabase.from('elo_history').insert({...});
// Missing: UPDATE users.elo_rating
```

**After (FIXED)**:
```dart
// ✅ UPDATE users.elo_rating FIRST
await _supabase.from('users').update({'elo_rating': newElo}).eq('id', userId);

// ✅ Then create history
await _supabase.from('elo_history').insert({...});
```

### 🎯 Điểm cần lưu ý:

1. **executeRewards = false by default**
   - Orchestrator KHÔNG tự động execute rewards
   - Admin phải click "Gửi Quà" button manually
   - Lý do: Tránh bug duplicate rewards (đã có từ trước)

2. **2-Step Process**:
   - Step 1: Complete Tournament → Save results
   - Step 2: Distribute Rewards → Update ELO/SPA/Stats

3. **Idempotent Design**:
   - RewardExecutionService check existing transactions
   - Không duplicate rewards nếu chạy nhiều lần

4. **Audit Trail**:
   - `elo_history` lưu tất cả thay đổi
   - Có thể trace back mọi tournament

---

## 🚀 TESTING

### Test Flow (Sau khi fix):

1. **Complete Tournament**:
   ```dart
   // UI: Click "Hoàn thành giải đấu"
   // Result: Tournament status = completed
   // Check: users.elo_rating = unchanged (executeRewards=false)
   ```

2. **Distribute Rewards**:
   ```dart
   // UI: Click "Gửi Quà" button
   // Result: RewardExecutionService executes
   // Check: users.elo_rating = updated ✅
   // Check: elo_history has new record ✅
   ```

3. **Verify**:
   ```sql
   -- Check user ELO matches history
   SELECT 
     u.email,
     u.elo_rating AS current_elo,
     eh.new_elo AS history_elo
   FROM users u
   JOIN elo_history eh ON u.id = eh.user_id
   WHERE eh.created_at = (
     SELECT MAX(created_at) 
     FROM elo_history 
     WHERE user_id = u.id
   );
   ```

---

## 🎉 CONCLUSION

**Tương lai, ELO sẽ được cập nhật qua flow**:

1. ✅ Admin complete tournament (orchestrator)
2. ✅ Admin click "Gửi Quà" button (manual distribution)
3. ✅ RewardExecutionService executes (**đã fix**)
4. ✅ Database updates cả `users.elo_rating` và `elo_history`
5. ✅ Profile hiển thị ELO chính xác

**100% users sẽ có ELO đúng từ giờ trở đi!** 🚀
