# 🔧 MINIMAL VOUCHER REQUEST FIX

## ❌ PROBLEM: Column Not Found
```
Could not find the 'notes' column of 'club_voucher_requests' in the schema cache
PostgrestException code: PGRST204
```

## ✅ SOLUTION: Minimal Fields Strategy

### 🎯 Reduced INSERT to Essential Fields Only
```dart
// BEFORE: Too many fields, some don't exist
{
  'voucher_code': voucherCode,
  'user_id': userId, 
  'user_email': userEmail,
  'user_name': userName,
  'club_id': clubId,
  'spa_value': spaValue,
  'voucher_type': voucherType,
  'expires_at': DateTime.now()...,
  'status': 'pending',
  'notes': '...' // ← This column doesn't exist!
}

// AFTER: Only essential fields
{
  'voucher_code': voucherCode,
  'user_id': userId,
  'club_id': clubId, 
  'status': 'pending'
}
```

## 🧪 TEST NOW
1. **Click voucher button**
2. **Should see**: "🔧 DEBUG: Creating voucher request with minimal fields"
3. **Expected**: SUCCESS instead of 400 Bad Request

## 🎯 STRATEGY
- Start with **minimal working INSERT**
- Add fields **one by one** after confirming success
- **Identify actual table schema** through testing

**This should finally work!** 🚀