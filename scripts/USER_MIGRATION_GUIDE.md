# 🔄 USER MIGRATION GUIDE - SUPABASE CŨ → MỚI

## 📋 MỤC ĐÍCH:

Migrate tất cả users từ **Supabase cũ** (web platform) sang **Supabase mới** (mobile app) để users không phải tạo lại tài khoản.

---

## 🔐 THÔNG TIN:

### **Supabase Cũ (Web):**
- URL: `https://exlqvlbawytbglioqfbc.supabase.co`
- Service Key: `sb_secret_nNmO6wZEx0bv9YD323kErg__VmmUYEc`

### **Supabase Mới (App):**
- URL: Lấy từ `.env` → `SUPABASE_URL`
- Service Key: Lấy từ `.env` → `SUPABASE_SERVICE_ROLE_KEY`

---

## ⚠️ QUAN TRỌNG:

### **Trước khi chạy:**
1. ✅ **Backup database** Supabase mới
2. ✅ Đảm bảo có **Service Role Key** (không phải anon key)
3. ✅ Test với **1-2 users** trước
4. ✅ Chạy trong **môi trường an toàn**
5. ✅ Chỉ chạy **1 LẦN** để tránh duplicate

### **Script sẽ:**
- ✅ Fetch tất cả users từ Supabase cũ
- ✅ Check duplicate trước khi tạo
- ✅ Preserve email verification status
- ✅ Preserve user metadata
- ✅ Giữ nguyên password hash (nếu có)
- ✅ Skip users đã tồn tại

---

## 🚀 CÁCH CHẠY:

### **Bước 1: Cài đặt dependencies**

```bash
# Thêm vào pubspec.yaml nếu chưa có
dependencies:
  http: ^1.1.0

# Install
flutter pub get
```

### **Bước 2: Kiểm tra .env**

Đảm bảo file `.env` có:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key  # ← QUAN TRỌNG!
```

### **Bước 3: Chạy script**

```bash
# Từ root project
dart run scripts/migrate_users.dart
```

---

## 📊 OUTPUT MẪU:

```
🚀 Starting User Migration...

✅ Loaded new Supabase credentials from .env

📥 Fetching users from old Supabase...
✅ Found 150 users in old Supabase

[0/150] Migrating: user1@example.com
  ✅ Success

[1/150] Migrating: user2@example.com
  ⚠️  User already exists, skipping...

[2/150] Migrating: user3@example.com
  ✅ Success

...

==================================================
🎉 Migration Complete!
==================================================
✅ Success: 148
❌ Failed: 2
📊 Total: 150
==================================================
```

---

## 🔍 TROUBLESHOOTING:

### **Error: "Missing Supabase credentials in .env"**
**Fix:** Thêm `SUPABASE_SERVICE_ROLE_KEY` vào `.env`

### **Error: "Failed to fetch users: 401"**
**Fix:** Check Service Role Key của Supabase cũ

### **Error: "Failed to create user: 422"**
**Nguyên nhân:** User đã tồn tại hoặc email invalid
**Fix:** Script tự động skip, không cần fix

### **Error: "Rate limit exceeded"**
**Fix:** Script có delay 500ms giữa các requests. Nếu vẫn lỗi, tăng delay:
```dart
await Future.delayed(Duration(seconds: 1)); // Tăng từ 500ms → 1s
```

---

## 🔐 BẢO MẬT:

### **Service Role Key:**
- ⚠️ **KHÔNG commit** vào Git
- ⚠️ **KHÔNG share** công khai
- ✅ Chỉ dùng trong môi trường an toàn
- ✅ Revoke sau khi migration xong (nếu cần)

### **Password Migration:**
- ✅ Script giữ nguyên **password hash**
- ✅ Users có thể login với **password cũ**
- ✅ Không cần reset password

---

## 📝 WHAT GETS MIGRATED:

### **✅ Migrated:**
- Email
- Password hash (encrypted)
- Email verification status
- User metadata (name, avatar, etc.)
- App metadata
- User ID (nếu có thể)

### **❌ NOT Migrated:**
- Login history
- Sessions
- Refresh tokens
- MFA settings (cần setup lại)

---

## 🧪 TEST MIGRATION:

### **Test với 1 user trước:**

Sửa script tạm thời:
```dart
// Trong _fetchOldUsers(), thêm:
final users = List<Map<String, dynamic>>.from(data['users']);
return users.take(1).toList(); // ← Chỉ lấy 1 user để test
```

Sau khi test OK, remove `.take(1)` và chạy full migration.

---

## 🔄 RE-RUN MIGRATION:

Nếu cần chạy lại:

1. **Script tự động skip** users đã tồn tại
2. Chỉ migrate users mới
3. An toàn để chạy nhiều lần

---

## 📊 POST-MIGRATION:

### **Verify:**

```sql
-- Check số lượng users trong Supabase mới
SELECT COUNT(*) FROM auth.users;

-- Check users cụ thể
SELECT email, created_at, email_confirmed_at 
FROM auth.users 
ORDER BY created_at DESC;
```

### **Test Login:**
1. Thử login với 1 vài accounts cũ
2. Verify password works
3. Check user metadata

---

## 🎯 ADVANCED OPTIONS:

### **Custom Mapping:**

Nếu cần map thêm data, sửa trong `_migrateUser()`:

```dart
final userData = {
  'email': email,
  'email_confirm': oldUser['email_confirmed_at'] != null,
  'user_metadata': {
    ...oldUser['user_metadata'] ?? {},
    'migrated_from': 'old_web_platform', // ← Custom field
    'migration_date': DateTime.now().toIso8601String(),
  },
};
```

### **Batch Processing:**

Nếu có nhiều users (>1000), xử lý theo batch:

```dart
const batchSize = 100;
for (var i = 0; i < oldUsers.length; i += batchSize) {
  final batch = oldUsers.skip(i).take(batchSize).toList();
  await Future.wait(batch.map((user) => _migrateUser(user)));
  print('Processed batch ${i ~/ batchSize + 1}');
}
```

---

## ✅ CHECKLIST:

- [ ] Backup Supabase mới
- [ ] Có Service Role Key
- [ ] Test với 1-2 users
- [ ] Check .env file
- [ ] Run full migration
- [ ] Verify users migrated
- [ ] Test login
- [ ] Document results

---

## 🎉 SUCCESS!

Sau khi migration xong:
- ✅ Users có thể login với account cũ
- ✅ Không cần tạo lại tài khoản
- ✅ Giữ nguyên password
- ✅ Preserve user data
- ✅ Seamless experience!

---

## 📞 SUPPORT:

Nếu gặp vấn đề:
1. Check logs trong console
2. Verify Service Role Keys
3. Check Supabase dashboard
4. Review error messages

**READY TO MIGRATE! 🚀**
