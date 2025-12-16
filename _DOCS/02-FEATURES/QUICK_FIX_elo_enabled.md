# ⚡ CÁCH NHANH NHẤT - THÊM CỘT elo_enabled (30 GIÂY)

## 🎯 3 BƯỚC ĐƠN GIẢN

### 1️⃣ MỞ LINK NÀY (Ctrl+Click để mở):
```
https://mogjjvscxjwvhtpkrlqr.supabase.co/project/mogjjvscxjwvhtpkrlqr/sql/new
```

### 2️⃣ PASTE SQL NÀY:
```sql
ALTER TABLE tournaments
ADD COLUMN elo_enabled BOOLEAN DEFAULT true NOT NULL;
```

### 3️⃣ CLICK "RUN" (hoặc nhấn Ctrl+Enter)

---

## ✅ XONG! 

Bây giờ thử **Complete Tournament** lại xem!

---

## 🔍 KIỂM TRA (Optional)

Nếu muốn chắc chắn cột đã được thêm, chạy query này:

```sql
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'tournaments' AND column_name = 'elo_enabled';
```

Kết quả mong đợi:
```
column_name  | data_type | column_default
elo_enabled  | boolean   | true
```

---

## 💡 Ý NGHĨA

- **`elo_enabled = true`**: Giải đấu có tính ELO (mặc định)
- **`elo_enabled = false`**: Giải đấu KHÔNG tính ELO (giải giao hữu)

Tất cả giải đấu hiện tại sẽ có `elo_enabled = true` (mặc định).
