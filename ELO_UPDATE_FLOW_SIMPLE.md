# 🎯 FLOW CẬP NHẬT ELO TRONG TƯƠNG LAI

## 📱 USER JOURNEY (Từ UI đến Database)

### BƯỚC 1: Admin hoàn thành giải đấu

```
🏆 Tournament Detail Screen
    ↓
📋 Settings Tab
    ↓
🔘 Button: "Hoàn thành giải đấu"
    ↓
⚙️  TournamentCompletionOrchestrator
    ├─ Lưu kết quả vào tournament_results ✅
    ├─ Đổi status → completed ✅
    ├─ Issue vouchers ✅
    └─ executeRewards = FALSE ⚠️
    
⚠️  ELO CHƯA ĐƯỢC CẬP NHẬT!
```

### BƯỚC 2: Admin phân phối thưởng (QUAN TRỌNG!)

```
🎁 Button: "Gửi Quà" / "Reward Distribution"
    ↓
⚙️  RewardExecutionService.executeRewardsFromResults()
    ↓
Đọc từ tournament_results
    ↓
For each participant:
    ├─ _executeSpaReward()
    │   └─ UPDATE spa_transactions ✅
    │
    ├─ _executeEloChange() ✅ (ĐÃ FIX)
    │   ├─ GET users.elo_rating (current)
    │   ├─ CALCULATE newElo = oldElo + eloChange
    │   ├─ UPDATE users.elo_rating = newElo ✅
    │   └─ INSERT elo_history ✅
    │
    └─ _updateUserStats()
        └─ UPDATE user aggregated stats ✅
```

---

## 🔧 CODE EXECUTION PATH

### Path 1: Tournament Completion (Không update ELO)

```dart
// File: tournament_settings_tab.dart (Line 676)
await _completionService.completeTournament(
  tournamentId: widget.tournamentId,
  executeRewards: false,  // ← ⚠️ FALSE = Không execute rewards
);

// Result:
// ✅ Tournament status = completed
// ✅ tournament_results saved
// ❌ users.elo_rating = unchanged
```

### Path 2: Reward Distribution (CẬP NHẬT ELO)

```dart
// File: reward_distribution_button.dart (Line 78)
final rewardService = RewardExecutionService();
await rewardService.executeRewardsFromResults(
  tournamentId: widget.tournamentId,
);

// ↓

// File: reward_execution_service.dart (Line 65)
await _executeEloChange(
  tournamentId: tournamentId,
  userId: userId,
  eloChange: eloChange,
  position: position,
);

// ↓

// File: reward_execution_service.dart (Line 175-210)
// ✅ FIXED CODE:
await _supabase.from('users').update({
  'elo_rating': newElo,  // ← CẬP NHẬT USERS TABLE
  'updated_at': DateTime.now().toIso8601String(),
}).eq('id', userId);

await _supabase.from('elo_history').insert({
  'user_id': userId,
  'tournament_id': tournamentId,
  'old_elo': oldElo,
  'new_elo': newElo,
  'elo_change': eloChange,
  'reason': 'Tournament completion (position $position)',
});
```

---

## 🗄️ DATABASE FLOW

```
BEFORE FIX (BUG):
┌─────────────────┐
│ RewardExecution │
│    Service      │
└────────┬────────┘
         │
         ↓
    INSERT only
         │
         ↓
┌─────────────────┐
│  elo_history    │  ✅ Có data
└─────────────────┘

┌─────────────────┐
│ users.elo_rating│  ❌ KHÔNG update (BUG!)
└─────────────────┘


AFTER FIX (CORRECT):
┌─────────────────┐
│ RewardExecution │
│    Service      │
└────────┬────────┘
         │
         ├─────────────┐
         │             │
         ↓             ↓
     UPDATE        INSERT
         │             │
         ↓             ↓
┌─────────────────┐ ┌─────────────────┐
│ users.elo_rating│ │  elo_history    │
│  ✅ UPDATED!    │ │  ✅ Created!    │
└─────────────────┘ └─────────────────┘
         │
         ↓
┌─────────────────┐
│  Profile Screen │
│  ✅ Shows       │
│  correct ELO    │
└─────────────────┘
```

---

## 🎬 DEMO SCENARIO

### Scenario: User "Nguyễn Văn A" tham gia tournament

**Starting Point:**
- User A: ELO = 1000
- Tournament: 8 players, Single Elimination

**Match Results:**
- Round 1: User A wins → Advance
- Semi-final: User A wins → Advance
- Final: User A wins → Champion 🏆

**Tournament Complete:**
```
Admin clicks "Hoàn thành giải đấu"
→ Status: completed
→ User A ELO: 1000 (unchanged)
```

**Reward Distribution:**
```
Admin clicks "Gửi Quà"
→ RewardExecutionService runs:
   1. Calculate ELO change: +75 (champion)
   2. UPDATE users SET elo_rating = 1075 WHERE id = user_a_id ✅
   3. INSERT elo_history (1000 → 1075, +75) ✅
   
→ User A ELO: 1075 ✅
```

**Profile Screen:**
```
User A opens profile
→ Fetch users.elo_rating
→ Display: 1075 ELO ✅
```

---

## ⚡ QUICK REFERENCE

### Khi nào ELO được cập nhật?

| Action | ELO Updated? |
|--------|-------------|
| Tournament started | ❌ No |
| Match completed | ❌ No |
| Tournament completed (button clicked) | ❌ No |
| **"Gửi Quà" button clicked** | **✅ YES** |

### Files liên quan:

| File | Purpose |
|------|---------|
| `tournament_settings_tab.dart` | UI button "Hoàn thành giải đấu" |
| `reward_distribution_button.dart` | UI button "Gửi Quà" |
| `tournament_completion_orchestrator.dart` | Orchestrate completion flow |
| `reward_execution_service.dart` | **Execute ELO update** ✅ |
| `users` table | Store current ELO |
| `elo_history` table | Store ELO changes audit trail |

### Debug Commands:

```sql
-- Check user current ELO
SELECT email, elo_rating FROM users WHERE email = 'user@example.com';

-- Check user ELO history
SELECT * FROM elo_history 
WHERE user_id = (SELECT id FROM users WHERE email = 'user@example.com')
ORDER BY created_at DESC;

-- Verify consistency
SELECT 
  u.email,
  u.elo_rating as current_elo,
  eh.new_elo as history_elo,
  CASE WHEN u.elo_rating = eh.new_elo THEN '✅ OK' ELSE '❌ MISMATCH' END as status
FROM users u
LEFT JOIN LATERAL (
  SELECT new_elo 
  FROM elo_history 
  WHERE user_id = u.id 
  ORDER BY created_at DESC 
  LIMIT 1
) eh ON true;
```

---

## 🚨 TROUBLESHOOTING

### Problem: User ELO không update sau tournament

**Check 1**: Admin đã click "Gửi Quà" chưa?
```
→ Không → Click "Gửi Quà" button
→ Có → Check logs
```

**Check 2**: Có error trong RewardExecutionService?
```dart
// Check debug logs
debugPrint('✅ [ELO] Updated user ELO: $oldElo → $newElo');
debugPrint('✅ [ELO] Created history: ...');
```

**Check 3**: RLS Policy có chặn UPDATE không?
```sql
-- Test with SERVICE_ROLE key
UPDATE users SET elo_rating = 1100 WHERE id = 'user_id';
```

### Problem: ELO history có nhưng users.elo_rating = 1000

**Root Cause**: Code cũ (bug) đang chạy

**Solution**:
1. Verify code đã fix (line 185-188 trong reward_execution_service.dart)
2. Hot reload app
3. Sync data bằng script: `python sync_all_elo_service_role.py`

---

## ✅ SUCCESS CRITERIA

Sau khi tournament complete và distribute rewards:

- ✅ `users.elo_rating` = latest `elo_history.new_elo`
- ✅ Profile screen hiển thị ELO đúng
- ✅ Leaderboard xếp hạng đúng
- ✅ No mismatches giữa users và elo_history

---

**📌 TÓM TẮT**: 

Tương lai, ELO được cập nhật qua **2 bước**:
1. Admin click **"Hoàn thành giải đấu"** (save results)
2. Admin click **"Gửi Quà"** (execute rewards + update ELO) ✅

**Bug đã fix, 100% users sẽ có ELO chính xác!** 🎉
