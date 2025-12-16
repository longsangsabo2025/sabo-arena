# 🔧 CÁCH THÊM CỘT elo_enabled VÀO BẢNG tournaments

## ❌ VẤN ĐỀ
Khi hoàn thành giải đấu, code bị lỗi:
```
PostgrestException(message: column tournaments.elo_enabled does not exist, code: 42703)
```

## ✅ GIẢI PHÁP
Thêm cột `elo_enabled` vào bảng `tournaments` trong Supabase.

## 📋 HƯỚNG DẪN (3 BƯỚC)

### BƯỚC 1: Mở Supabase SQL Editor
1. Vào: https://mogjjvscxjwvhtpkrlqr.supabase.co/project/mogjjvscxjwvhtpkrlqr/editor
2. Click vào tab **SQL Editor** (bên trái màn hình)
3. Click nút **New Query** hoặc **+ New query**

### BƯỚC 2: Paste SQL
Copy & paste đoạn SQL này vào editor:

```sql
-- Add elo_enabled column with default true
ALTER TABLE tournaments 
ADD COLUMN elo_enabled BOOLEAN DEFAULT true NOT NULL;

-- Add comment
COMMENT ON COLUMN tournaments.elo_enabled IS 'Whether ELO rating is enabled for this tournament';
```

### BƯỚC 3: Run SQL
1. Click nút **Run** (hoặc nhấn Ctrl+Enter)
2. Chờ thông báo "Success"

## 🧪 KIỂM TRA
Sau khi thêm cột, chạy lệnh này để kiểm tra:

```powershell
$env:SUPABASE_URL="https://mogjjvscxjwvhtpkrlqr.supabase.co"; $env:SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"; python add_elo_enabled_column.py
```

Nếu thấy:
```
✅ elo_enabled column already exists!
```
→ **XONG!** ✅

## 📊 Ý NGHĨA CỘT `elo_enabled`

Cột này quyết định:
- **`true`**: Giải đấu này sẽ tính ELO cho người chơi
- **`false`**: Giải đấu này KHÔNG tính ELO (ví dụ: giải giao hữu)

### Trong code:
```dart
// File: ranking_service.dart line 25
final eloEnabled = tournament['elo_enabled'] as bool? ?? false;

// Nếu eloEnabled = true → Tính ELO change
// Nếu eloEnabled = false → elo_change = 0
final eloChange = eloEnabled ? _calculateEloChange(position, participantCount) : 0;
```

## 🏆 NÚT "COMPLETE TOURNAMENT" LÀM GÌ?

Khi bạn click **Complete Tournament**, `TournamentCompletionOrchestrator` sẽ:

1. ✅ **Validate**: Kiểm tra tất cả trận đấu đã xong chưa
2. 📊 **Calculate Standings**: Tính xếp hạng cuối cùng (position 1, 2, 3...)
3. 💰 **Calculate Rewards**: Tính **TẤT CẢ** phần thưởng:
   - **SPA points** (dựa vào position)
   - **ELO change** (dựa vào position + `elo_enabled`)
   - **Prize money** (từ `prize_distribution` template)
4. 💾 **Save to tournament_results**: Lưu kết quả vào bảng `tournament_results` (source of truth)
5. ⚡ **Execute Rewards**: Phân phối rewards:
   - Cộng SPA vào `users.spa_points` + tạo `spa_transactions`
   - Cộng ELO vào `users.elo_rating` + tạo `elo_history`
   - Cập nhật user stats (tournaments_won, total_earnings...)
6. 🎟️ **Issue Vouchers**: Tạo voucher cho Top 4 (nếu `issueVouchers=true`)
7. 📢 **Send Notifications**: Gửi thông báo cho người chơi
8. 📱 **Post to Social**: Đăng kết quả lên feed (nếu `sendNotifications=true`)
9. 💬 **Chat Notification**: Thông báo trong group chat
10. ✅ **Mark Complete**: Đổi status tournament thành `completed`

### Ví dụ với 1 người chơi:
```
Position 1 (Champion):
- SPA: +200
- ELO: +75 (nếu elo_enabled=true)
- Prize money: 50% prize_pool
- Voucher: "Champion Discount 30%"
```

## 🎯 TẠI SAO CẦN CỘT NÀY?

Ban đầu bạn hỏi: "Có cần thiết cột đấy không?"

**CÓ!** Vì:
1. Không phải giải nào cũng muốn tính ELO (ví dụ: giải giao hữu)
2. Code cần biết có tính ELO hay không khi calculate rewards
3. Đây là phần của **reward calculation logic** - không thể bỏ

## ⚠️ LƯU Ý
- Tất cả tournaments hiện tại sẽ có `elo_enabled = true` (default)
- Nếu muốn tắt ELO cho giải nào, sửa thủ công trong database
