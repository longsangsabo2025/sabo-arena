# 🔧 FIX: SPA RACE CONDITION - ATOMIC INCREMENT

## 🚨 VẤN ĐỀ:

Khi nhiều users cùng nhận SPA reward trong 1 tournament, xảy ra **RACE CONDITION**:

```dart
// Transaction A
spa_points = GET users.spa_points  // → 0
UPDATE users SET spa_points = 0 + 550  // → 550

// Transaction B (cùng lúc)
spa_points = GET users.spa_points  // → 0 (chưa kịp update!)
UPDATE users SET spa_points = 0 + 550  // → 550 (GHI ĐÈ!)

// Kết quả: User chỉ có 550 thay vì 1100!
```

## ✅ GIẢI PHÁP:

Sử dụng **PostgreSQL Function** với atomic UPDATE để tránh race condition.

## 📝 BƯỚC 1: Deploy Function

Copy nội dung file `supabase/migrations/20251107_create_atomic_spa_function.sql` và execute trong **Supabase SQL Editor**.

Function tạo ra: `atomic_increment_spa()`

## 📝 BƯỚC 2: Update Dart Code

### File: `lib/services/tournament/reward_execution_service.dart`

**TRƯỚC** (line 126-150):
```dart
// Get current balance
final userResponse = await _supabase
    .from('users')
    .select('spa_points')
    .eq('id', userId)
    .single();

final currentBalance = userResponse['spa_points'] as int? ?? 0;
final newBalance = currentBalance + spaReward;

// Update user spa_points FIRST
await _supabase
    .from('users')
    .update({'spa_points': newBalance})
    .eq('id', userId);

// Create transaction record
await _supabase.from('spa_transactions').insert({
  'user_id': userId,
  'transaction_type': 'tournament_reward',
  'amount': spaReward,
  'balance_before': currentBalance,
  'balance_after': newBalance,
  ...
});
```

**SAU** (replace toàn bộ đoạn trên):
```dart
// ✅ Use atomic function to prevent race condition
final result = await _supabase.rpc('atomic_increment_spa', params: {
  'p_user_id': userId,
  'p_amount': spaReward,
  'p_transaction_type': 'tournament_reward',
  'p_description': 'Tournament reward for position $position',
  'p_reference_type': 'reward',
  'p_reference_id': tournamentId,
}).execute();

if (result.data != null && result.data.isNotEmpty) {
  final oldBalance = result.data[0]['old_balance'] as int;
  final newBalance = result.data[0]['new_balance'] as int;
  debugPrint('      ✅ [SPA] Atomic increment: +$spaReward SPA ($oldBalance → $newBalance)');
} else {
  throw Exception('Failed to execute atomic_increment_spa');
}
```

### File: `lib/services/tournament_completion_service.dart`

Tương tự, replace 2 chỗ:

**Line ~767** và **Line ~1541**:
```dart
// OLD CODE
final currentSpa = currentSpaPoints['spa_points'] ?? 0;
final newSpaPoints = currentSpa + positionBonusSPA;
await _supabase.from('users').update({'spa_points': newSpaPoints}).eq('id', standing['participant_id']);
await _supabase.from('spa_transactions').insert({...});

// NEW CODE
await _supabase.rpc('atomic_increment_spa', params: {
  'p_user_id': standing['participant_id'],
  'p_amount': positionBonusSPA,
  'p_transaction_type': 'spa_bonus',
  'p_description': 'SPA Bonus - Position $position: +$positionBonusSPA SPA',
  'p_reference_type': 'tournament',
  'p_reference_id': tournamentId,
}).execute();
```

## 📝 BƯỚC 3: Recalculate Existing Data

Chạy script để fix data cũ:

```bash
python recalculate_all_spa_balances.py
```

Script này sẽ:
1. Tính lại balance_before/after cho TẤT CẢ transactions
2. Cập nhật spa_points cho tất cả users

## 🎯 KẾT QUẢ:

- ✅ Không còn race condition
- ✅ SPA được tính đúng khi nhiều users cùng nhận reward
- ✅ balance_before/after luôn chính xác
- ✅ Audit trail đầy đủ trong spa_transactions

## 📊 TESTING:

1. Tạo 1 tournament với nhiều users
2. Complete tournament
3. Kiểm tra spa_transactions: Tất cả phải có balance_before ≠ 0 và tích lũy đúng
4. Kiểm tra users.spa_points: Phải = tổng tất cả amount trong transactions
