# 🔒 CODING GUIDELINES: SPA Points Updates

## ⚠️ CRITICAL RULE: Always Use Atomic Function

### ❌ NEVER DO THIS (Race Condition):
```dart
// ❌ BAD: Read-then-write pattern
final user = await supabase
    .from('users')
    .select('spa_points')
    .eq('id', userId)
    .single();

final currentSpa = user['spa_points'] as int;
final newSpa = currentSpa + 100;

await supabase
    .from('users')
    .update({'spa_points': newSpa})
    .eq('id', userId);

await supabase.from('spa_transactions').insert({...});
```

**WHY?** When multiple rewards are distributed simultaneously:
```
Time T1: Transaction A reads spa_points = 1000
Time T2: Transaction B reads spa_points = 1000 (before A updates!)
Time T3: Transaction A writes spa_points = 1100
Time T4: Transaction B writes spa_points = 1100 (overwrites A's update!)
Result: User has 1100 instead of 1200 ❌
```

---

## ✅ ALWAYS DO THIS (Atomic):

```dart
// ✅ GOOD: Use atomic_increment_spa function
final result = await supabase.rpc('atomic_increment_spa', params: {
  'p_user_id': userId,
  'p_amount': 100,
  'p_transaction_type': 'tournament_reward',
  'p_description': 'Tournament completion bonus',
  'p_reference_type': 'tournament',
  'p_reference_id': tournamentId,
}) as List<dynamic>;

if (result.isNotEmpty) {
  final data = result.first as Map<String, dynamic>;
  final oldBalance = data['old_balance'] as int;
  final newBalance = data['new_balance'] as int;
  debugPrint('✅ SPA updated: $oldBalance → $newBalance');
}
```

**WHY?** Database locks the row and updates atomically:
```
Transaction A calls atomic_increment_spa(+100)
Transaction B calls atomic_increment_spa(+100)
→ Database ensures both execute sequentially
→ User gets 1200 correctly ✅
```

---

## 📋 WHEN TO USE atomic_increment_spa:

### ✅ MUST USE for:
1. **Tournament rewards** (multiple users rewarded simultaneously)
2. **Match completion bonuses** (concurrent matches finishing)
3. **Daily login rewards** (many users claiming at same time)
4. **Referral bonuses** (multiple referrals activating)
5. **Event rewards** (bulk reward distribution)
6. **Admin grants** (staff granting SPA to multiple users)

### ⚠️ OPTIONAL for (low concurrency risk):
1. **SPA redemption** (spending/deducting SPA) - users rarely redeem same instant
2. **Refunds** (reversing transactions)
3. **Manual adjustments** (admin corrections)

**But still recommended** for consistency!

---

## 🔍 CODE REVIEW CHECKLIST:

Before merging any PR that touches SPA points:

- [ ] Does it use `atomic_increment_spa()` RPC call?
- [ ] Does it avoid `select spa_points` + `update spa_points`?
- [ ] Does it avoid manual `spa_transactions` insert?
- [ ] Is the transaction_type descriptive?
- [ ] Is the reference_id and reference_type set?

---

## 📚 EXAMPLES BY USE CASE:

### Tournament Completion:
```dart
await supabase.rpc('atomic_increment_spa', params: {
  'p_user_id': userId,
  'p_amount': 800,
  'p_transaction_type': 'tournament_reward',
  'p_description': 'Champion - Tournament "$tournamentName"',
  'p_reference_type': 'tournament',
  'p_reference_id': tournamentId,
});
```

### Match Win Bonus:
```dart
await supabase.rpc('atomic_increment_spa', params: {
  'p_user_id': winnerId,
  'p_amount': 50,
  'p_transaction_type': 'match_bonus',
  'p_description': 'Match victory bonus',
  'p_reference_type': 'match',
  'p_reference_id': matchId,
});
```

### Daily Login:
```dart
await supabase.rpc('atomic_increment_spa', params: {
  'p_user_id': userId,
  'p_amount': 10,
  'p_transaction_type': 'daily_login',
  'p_description': 'Daily login bonus - Day $dayCount',
  'p_reference_type': 'daily_login',
  'p_reference_id': userId, // or streak_id
});
```

### Referral Bonus:
```dart
await supabase.rpc('atomic_increment_spa', params: {
  'p_user_id': referrerId,
  'p_amount': 100,
  'p_transaction_type': 'referral_bonus',
  'p_description': 'Referral bonus - $referredUserName joined',
  'p_reference_type': 'referral',
  'p_reference_id': referredUserId,
});
```

---

## 🚨 INCIDENT RESPONSE:

If SPA balances are incorrect:

1. **Check for race condition:**
   ```python
   python check_concurrent_spa_transactions.py
   ```

2. **Verify function exists:**
   ```sql
   SELECT routine_name FROM information_schema.routines
   WHERE routine_name = 'atomic_increment_spa';
   ```

3. **Recalculate balances:**
   ```bash
   python recalculate_all_spa_balances.py
   ```

4. **Review recent code changes** for manual spa_points updates

---

## 📖 DATABASE FUNCTION REFERENCE:

**Function:** `atomic_increment_spa()`

**Parameters:**
- `p_user_id` (UUID) - User ID
- `p_amount` (INTEGER) - Amount to add (can be negative for deductions)
- `p_transaction_type` (VARCHAR) - Type: 'tournament_reward', 'match_bonus', etc.
- `p_description` (TEXT) - Human-readable description
- `p_reference_type` (VARCHAR) - 'tournament', 'match', 'referral', etc.
- `p_reference_id` (UUID) - ID of referenced entity

**Returns:**
```typescript
{
  old_balance: number,
  new_balance: number,
  transaction_id: string
}
```

**Guarantees:**
- ✅ Atomic update (no race conditions)
- ✅ Transaction record created
- ✅ Balance consistency (balance_after = balance_before + amount)
- ✅ ACID compliance

---

## 🎓 TRAINING:

New developers must:
1. Read this document
2. Review `FIX_SPA_RACE_CONDITION.md`
3. Understand why race conditions happen
4. Practice using `atomic_increment_spa()` in code reviews

---

## 📞 QUESTIONS?

Contact: Technical Lead or Database Administrator

**Last Updated:** November 7, 2025
**Version:** 1.0
**Status:** ✅ Active Guideline
