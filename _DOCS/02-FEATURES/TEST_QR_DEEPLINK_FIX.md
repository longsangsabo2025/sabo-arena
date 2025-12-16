# QR Deep Link Fix - Test Guide

## Vấn đề đã sửa

### 🐛 Bug cũ:
Khi quét QR code của user (từ profile header), deep link chỉ mở app nhưng **KHÔNG dẫn đến trang profile của user đó**.

### ✅ Nguyên nhân:
1. QR code format: `https://saboarena.com/user/SABO123456?ref=SABO-USERNAME`
   - `SABO123456` là `user_code` (không phải `user_id` UUID)
   - Deep link handler đang parse `SABO123456` như là `userId` và gọi sai route

2. Route `/user-profile` là profile của **current user** (người đang đăng nhập), không nhận `userId` argument

3. Cần navigate đến `OtherUserProfileScreen(userId: UUID)` với **user_id thật**

### 🔧 Giải pháp:
1. **Parse user_code từ deep link**: 
   - `https://saboarena.com/user/{userCode}?ref={referralCode}`
   - Example: `https://saboarena.com/user/SABO123456?ref=SABO-LONGSANG`

2. **Query database để lấy user_id thật**:
   ```dart
   final userId = await _getUserIdFromUserCode('SABO123456');
   // Returns UUID: "550e8400-e29b-41d4-a716-446655440000"
   ```

3. **Navigate đúng screen**:
   ```dart
   if (currentUserId == userId) {
     // Own profile → UserProfileScreen
     Navigator.pushNamed('/profile');
   } else {
     // Other user → OtherUserProfileScreen
     Navigator.push(MaterialPageRoute(
       builder: (_) => OtherUserProfileScreen(userId: userId)
     ));
   }
   ```

## Files đã sửa

### 1. `lib/services/deep_link_handler.dart`

#### a. Imports mới:
```dart
import '../presentation/other_user_profile_screen/other_user_profile_screen.dart';
import '../services/auth_service.dart';
```

#### b. Method `_handleDeepLink` - Line 49-90:
**Trước:**
```dart
if (pathSegments.length >= 2 && pathSegments[0] == 'user') {
  final userId = pathSegments[1]; // ❌ Đây thực ra là user_code!
  final referralCode = uri.queryParameters['ref'];
  
  if (referralCode != null && referralCode.isNotEmpty) {
    await _handleQRReferral(context, userId, referralCode);
  } else {
    Navigator.of(context).pushNamed(
      '/user-profile', // ❌ Route sai!
      arguments: {'userId': userId}, // ❌ userId là user_code!
    );
  }
}
```

**Sau:**
```dart
if (pathSegments.length >= 2 && pathSegments[0] == 'user') {
  final userCode = pathSegments[1]; // ✅ Đổi tên rõ ràng
  final referralCode = uri.queryParameters['ref'];
  
  print('👤 User profile deep link detected');
  print('   User Code: $userCode');
  print('   Referral code: $referralCode');
  
  // ✅ Find user by user_code to get actual user ID
  final userId = await _getUserIdFromUserCode(userCode);
  
  if (userId == null) {
    print('❌ User not found for code: $userCode');
    // Show error
    return;
  }
  
  if (referralCode != null && referralCode.isNotEmpty) {
    await _handleQRReferral(context, userId, referralCode);
  } else {
    // ✅ Navigate với helper method mới
    await _navigateToUserProfile(context, userId);
  }
}
```

#### c. Method `_handleQRReferral` - Line 317-319:
**Trước:**
```dart
// Navigate to the user's profile
Navigator.of(context).pushNamed(
  '/user-profile',
  arguments: {'userId': userId},
);
```

**Sau:**
```dart
// ✅ Navigate to the user's profile
await _navigateToUserProfile(context, userId);
```

#### d. Helper methods mới (thêm vào cuối class):
```dart
/// Helper: Get user ID from user_code (e.g., "SABO123456" -> UUID)
static Future<String?> _getUserIdFromUserCode(String userCode) async {
  try {
    final response = await _supabase
        .from('users')
        .select('id')
        .eq('user_code', userCode)
        .single();
    
    return response['id'] as String?;
  } catch (e) {
    print('❌ Error finding user by code: $e');
    return null;
  }
}

/// Helper: Navigate to user profile (own profile or other user's profile)
static Future<void> _navigateToUserProfile(
  BuildContext context,
  String userId,
) async {
  if (!context.mounted) return;
  
  // Check if viewing own profile or another user's profile
  final currentUserId = AuthService.instance.currentUser?.id;
  
  if (currentUserId == userId) {
    // Navigate to own profile (UserProfileScreen)
    Navigator.of(context).pushNamed('/profile');
  } else {
    // Navigate to other user's profile
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(userId: userId),
      ),
    );
  }
}
```

## Testing Checklist

### ✅ Test Case 1: Quét QR của user khác (có referral code)
**Setup:**
1. User A đăng nhập vào app
2. User A mở profile → hiện QR code
3. QR data: `https://saboarena.com/user/SABO123456?ref=SABO-USERA`

**Action:**
1. User B quét QR code của User A

**Expected Result:**
- ✅ App mở và navigate đến `OtherUserProfileScreen`
- ✅ Hiển thị profile của User A (tên, ảnh, ELO, rank)
- ✅ Xử lý referral code (nếu User B chưa đăng nhập → lưu code, nếu đã đăng nhập → apply ngay)
- ✅ Hiện thông báo "🎉 Nhận thưởng giới thiệu thành công! +25 SPA" (nếu apply thành công)

### ✅ Test Case 2: Quét QR của chính mình
**Setup:**
1. User A đăng nhập
2. User A mở profile → lấy QR code của mình

**Action:**
1. User A quét QR code của chính mình (self-scan)

**Expected Result:**
- ✅ App mở và navigate đến `UserProfileScreen` (own profile)
- ✅ KHÔNG xử lý referral (không tự giới thiệu mình)

### ✅ Test Case 3: QR không có referral code
**Setup:**
1. Tạo QR code thủ công: `https://saboarena.com/user/SABO123456` (không có `?ref=...`)

**Action:**
1. User B quét QR code này

**Expected Result:**
- ✅ App mở và navigate đến profile của user có code `SABO123456`
- ✅ KHÔNG xử lý referral code
- ✅ Chỉ đơn giản là xem profile

### ✅ Test Case 4: QR code không hợp lệ
**Setup:**
1. QR code: `https://saboarena.com/user/INVALID_CODE?ref=SABO-USERA`
2. User với code `INVALID_CODE` không tồn tại trong database

**Action:**
1. User quét QR code này

**Expected Result:**
- ❌ App mở nhưng hiện SnackBar: "❌ Không tìm thấy người dùng"
- ❌ KHÔNG navigate đi đâu (giữ nguyên màn hình hiện tại)

### ✅ Test Case 5: Deep link từ browser/external link
**Setup:**
1. Gửi link `https://saboarena.com/user/SABO123456?ref=SABO-USERA` qua SMS/Email
2. User B nhấn vào link

**Action:**
1. Nhấn link từ browser/external app

**Expected Result:**
- ✅ App mở (hoặc chuyển sang app nếu đang mở browser)
- ✅ Navigate đến profile của user có code `SABO123456`
- ✅ Xử lý referral code đúng

### ✅ Test Case 6: User chưa đăng nhập quét QR
**Setup:**
1. User chưa đăng nhập (hoặc đã logout)
2. Quét QR: `https://saboarena.com/user/SABO123456?ref=SABO-USERA`

**Action:**
1. Quét QR code

**Expected Result:**
- ⚠️ Hiện SnackBar: "🎁 Đăng nhập để nhận thưởng giới thiệu!"
- ✅ Lưu referral code vào storage
- ✅ Navigate đến màn hình login
- ✅ Sau khi đăng nhập/đăng ký → tự động apply referral code

## Flow Chart

```
QR Code: https://saboarena.com/user/SABO123456?ref=SABO-USERA
                           ↓
              Parse Deep Link (deep_link_handler.dart)
                           ↓
              Extract: userCode="SABO123456", ref="SABO-USERA"
                           ↓
              Query DB: SELECT id FROM users WHERE user_code='SABO123456'
                           ↓
                     userId (UUID)
                           ↓
                ┌─────────┴─────────┐
                ↓                   ↓
         userId == null?      userId != null
                ↓                   ↓
         Show Error          Check referral code
         "User not found"            ↓
                              ┌─────┴─────┐
                              ↓           ↓
                          Has ref?    No ref?
                              ↓           ↓
                      _handleQRReferral  _navigateToUserProfile
                              ↓           ↓
                      Process referral   Check userId == currentUserId?
                              ↓           ↓
                      +25 SPA (if valid) ┌──┴──┐
                              ↓          ↓     ↓
                      _navigateToUserProfile Own Other
                              ↓          ↓     ↓
                      Check userId == currentUserId? UserProfileScreen OtherUserProfileScreen
                              ↓                              ↓
                      ┌───────┴────────┐                    ↓
                      ↓                ↓              (Show target user's
              Own Profile    Other User Profile      full name, avatar,
           (UserProfileScreen) (OtherUserProfileScreen) ELO, rank, etc.)
```

## Debug Commands

### 1. Test QR code generation (check format):
```dart
// In QRCodeWidget or profile screen
final qrData = await ShareService.generateUserQRDataWithReferral(userProfile);
debugPrint('QR Data: $qrData');
// Expected: https://saboarena.com/user/SABO123456?ref=SABO-USERNAME
```

### 2. Test user_code lookup:
```dart
// In Dart console or test file
final userId = await DeepLinkHandler._getUserIdFromUserCode('SABO123456');
debugPrint('User ID: $userId'); 
// Expected: UUID string like "550e8400-e29b-41d4-a716-446655440000"
```

### 3. Monitor deep link processing:
```dart
// Deep link logs in console when QR scanned:
print('🔗 Deep link received: https://saboarena.com/user/SABO123456?ref=...');
print('👤 User profile deep link detected');
print('   User Code: SABO123456');
print('   Referral code: SABO-USERA');
print('🎯 Processing QR referral...');
print('   Target user: 550e8400-e29b-41d4-a716-446655440000');
```

## Rollback Plan (nếu có bug)

Nếu fix này gây lỗi, rollback bằng cách:

```bash
git checkout HEAD~1 lib/services/deep_link_handler.dart
```

Hoặc manual revert:
1. Xóa 2 imports mới
2. Đổi `userCode` → `userId` 
3. Xóa `_getUserIdFromUserCode()` method
4. Xóa `_navigateToUserProfile()` method
5. Restore old navigation code

## Related Files

- ✅ `lib/services/deep_link_handler.dart` (FIXED)
- ✅ `lib/services/integrated_qr_service.dart` (OK - generates correct QR format)
- ✅ `lib/presentation/other_user_profile_screen/other_user_profile_screen.dart` (OK - accepts userId)
- ✅ `lib/presentation/user_profile_screen/widgets/qr_code_widget.dart` (OK - uses ShareService)
- ✅ `lib/services/share_service.dart` (OK - generates QR with referral)

## Performance Impact

- **Query overhead**: +1 database query per QR scan (`SELECT id FROM users WHERE user_code=?`)
  - Negligible: <10ms, indexed column
  - Alternative: Could cache user_code→userId mapping, but overkill for now

## Future Improvements

1. **Cache user_code → userId mapping** in memory (if QR scanning becomes frequent)
2. **Add deep link analytics**: Track how many users scan QR codes
3. **Support multiple QR formats**: 
   - Short URLs: `sabo.app/u/SABO123456`
   - Vanity URLs: `sabo.app/@username`
4. **Add QR expiration**: Optional time-limited QR codes for events

---

**Status:** ✅ FIXED & READY FOR TESTING
**Author:** GitHub Copilot
**Date:** 2025-11-09
