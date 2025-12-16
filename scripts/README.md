# 📜 SCRIPTS DIRECTORY

## 🔄 User Migration Script

### **migrate_users.dart**
Script để migrate users từ Supabase cũ (web) sang Supabase mới (app).

**Usage:**
```bash
dart run scripts/migrate_users.dart
```

**Xem hướng dẫn chi tiết:** `USER_MIGRATION_GUIDE.md`

---

## 📋 Requirements:

```yaml
dependencies:
  http: ^1.1.0
```

---

## ⚠️ Important:

- Chỉ chạy trong môi trường an toàn
- Backup database trước khi chạy
- Cần Service Role Key
- Chỉ chạy 1 lần

---

## 📚 Documentation:

- `USER_MIGRATION_GUIDE.md` - Chi tiết về user migration
- `migrate_users.dart` - Migration script

---

**READY TO USE! 🚀**
