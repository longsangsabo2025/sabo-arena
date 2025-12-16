# 🎯 END-TO-END: USER NHẬN GÌ SAU KHI COMPLETE GIẢI ĐẤU?

## 📊 TỔNG QUAN HỆ THỐNG

Khi 1 giải đấu được **Complete** (admin bấm nút "Complete Tournament"), hệ thống tự động:

---

## 1️⃣ REWARDS USER NHẬN ĐƯỢC

### 🏆 A. ELO RATING (Tất cả 16 user)
- **Nguồn tính**: Dựa trên kết quả matches + thuật toán ELO
- **Ghi vào**:
  - `users.elo_rating` ← ELO mới (cập nhật trực tiếp)
  - `elo_history` ← Lưu lịch sử thay đổi (old → new)
  - `tournament_results.old_elo`, `new_elo`, `elo_change`
- **Hiển thị ở**:
  - Profile Screen → Badge ELO (real-time từ `users` table)
  - Tournament Results → Detail stats
  - Leaderboard → Ranking theo ELO

### 💎 B. SPA POINTS (Tất cả 16 user - theo position)
- **Công thức phân bổ**:
  ```
  Position 1 (Champion):        1000 SPA
  Position 2 (Runner-up):       800 SPA
  Position 3-4 (Semi-final):    550 SPA
  Top 25%:                      400 SPA
  Top 50%:                      300 SPA
  Top 75%:                      200 SPA
  Bottom 25%:                   100 SPA (participation)
  ```
- **Ghi vào**:
  - `users.spa_points` ← Cộng thêm SPA (cumulative)
  - `transactions` ← Log transaction (type: 'tournament_reward')
  - `tournament_results.spa_reward` ← SPA cho giải này
- **Hiển thị ở**:
  - Profile Screen → SPA Points badge (real-time)
  - SPA Rewards Screen → Có thể đổi quà
  - Tournament Results → Chi tiết SPA nhận được

### 💰 C. PRIZE MONEY (Top 3 only)
- **Phân bổ**:
  ```
  🥇 Position 1:    500,000 VND
  🥈 Position 2:    300,000 VND
  🥉 Position 3:    100,000 VND
  Position 4-16:    0 VND
  ```
- **Ghi vào**:
  - `tournament_results.prize_money_vnd`
- **Lưu ý**: 
  - Tiền thưởng chỉ GHI NHẬN (record keeping)
  - User nhận tiền OFFLINE tại quán
  - Không tự động chuyển vào ví

### 🎁 D. VOUCHER (Top 4 only)
- **Phân bổ**:
  ```
  🥇 Position 1:    WINNER_50 (Giảm 50%)
  🥈 Position 2:    RUNNER_30 (Giảm 30%)
  🥉 Position 3:    THIRD_20 (Giảm 20%)
  🏅 Position 4:    FOURTH_10 (Giảm 10%)
  Position 5-16:    Không có voucher
  ```
- **Ghi vào**:
  - `user_vouchers` ← Voucher record (user_id, voucher_code, status, expires_at)
  - `tournament_results.voucher_code`, `voucher_discount_percent`
- **Hiển thị ở**:
  - User Voucher Screen → Danh sách voucher active
  - Notification → "Bạn nhận được voucher..."
  - Tournament Results → Voucher code

### 📈 E. TOURNAMENT STATS (Tất cả 16 user)
- **Ghi vào**:
  - `users.total_tournaments` ← +1
  - `tournament_results` ← Full record (1 row/user):
    * Tournament ID, User ID
    * Position (1-16)
    * Matches won/lost
    * Win percentage
    * Points/Games statistics
- **Hiển thị ở**:
  - Profile → "X giải đấu đã tham gia"
  - Tournament History Tab → List all tournaments
  - Tournament Detail → Bảng xếp hạng cuối cùng

---

## 2️⃣ DATABASE TABLES - GHI NHẬN Ở ĐÂU?

### 📊 Bảng tổng hợp kết quả

| Table | Purpose | User xem ở đâu |
|-------|---------|----------------|
| **users** | Profile stats (ELO, SPA, total_tournaments) | Profile Screen (real-time) |
| **elo_history** | Lịch sử thay đổi ELO | ELO History Screen |
| **transactions** | Lịch sử SPA transactions | SPA Rewards → History Tab |
| **user_vouchers** | Voucher đã nhận | User Voucher Screen |
| **tournament_results** | Chi tiết kết quả giải (1 row/user) | Tournament Detail Results |
| **tournament_result_history** | Snapshot toàn giải (JSONB audit) | Admin Dashboard |
| **notifications** | Thông báo "Chúc mừng bạn..." | Notification Bell |

### 🔍 Chi tiết từng bảng

#### A. `users` table
```sql
elo_rating          INTEGER      -- ELO hiện tại (updated)
spa_points          INTEGER      -- SPA Points tích lũy (updated)
total_tournaments   INTEGER      -- Số giải đã tham gia (+1)
total_wins          INTEGER      -- Tổng matches thắng
total_losses        INTEGER      -- Tổng matches thua
```
**👁️ User xem**: Profile Screen → Header stats

---

#### B. `elo_history` table
```sql
user_id            UUID
old_elo            INTEGER      -- ELO trước tournament
new_elo            INTEGER      -- ELO sau tournament
elo_change         INTEGER      -- Thay đổi (+/-)
reason             TEXT         -- "tournament_completion"
tournament_id      UUID
created_at         TIMESTAMP
```
**👁️ User xem**: ELO History Screen (nếu có)

---

#### C. `transactions` table
```sql
user_id            UUID
transaction_type   TEXT         -- "tournament_reward"
spa_amount         INTEGER      -- SPA nhận được
balance_before     INTEGER      -- SPA trước
balance_after      INTEGER      -- SPA sau
tournament_id      UUID
description        TEXT         -- "Tournament completion reward"
created_at         TIMESTAMP
```
**👁️ User xem**: SPA Rewards Screen → History Tab

---

#### D. `user_vouchers` table
```sql
id                 UUID
user_id            UUID
voucher_code       TEXT         -- "WINNER_50", "RUNNER_30"...
voucher_type       TEXT         -- "tournament_prize"
voucher_value      INTEGER      -- Giá trị VND (nếu là prize)
discount_percent   INTEGER      -- % giảm giá
status             TEXT         -- "active", "used", "expired"
tournament_id      UUID
expires_at         TIMESTAMP    -- 30 ngày sau khi phát
created_at         TIMESTAMP
```
**👁️ User xem**: User Voucher Screen → Tab "Active Vouchers"

---

#### E. `tournament_results` table (⭐ QUAN TRỌNG NHẤT)
```sql
-- Mỗi user = 1 ROW
tournament_id          UUID
participant_id         UUID
participant_name       TEXT
position               INTEGER      -- 1-16
matches_played         INTEGER
matches_won            INTEGER
matches_lost           INTEGER
games_won              INTEGER
games_lost             INTEGER
win_percentage         DECIMAL
points                 INTEGER

-- 🎁 REWARDS COLUMNS (MỚI)
old_elo                INTEGER      -- ELO trước giải
new_elo                INTEGER      -- ELO sau giải
elo_change             INTEGER      -- +/- ELO
spa_reward             INTEGER      -- SPA Points nhận được
prize_money_vnd        DECIMAL      -- Tiền thưởng (VND)
voucher_code           TEXT         -- Mã voucher (nếu có)
voucher_discount_percent INTEGER    -- % giảm giá

created_at             TIMESTAMP
updated_at             TIMESTAMP
```
**👁️ User xem**: 
- Tournament Detail Screen → Results Tab
- Profile → Tournament History Tab

---

#### F. `tournament_result_history` table (Audit/Admin only)
```sql
tournament_id          UUID
tournament_name        TEXT
tournament_format      TEXT
completed_at           TIMESTAMP

-- JSONB Arrays (snapshot toàn giải)
standings              JSONB[]      -- All 16 participants
elo_updates            JSONB[]      -- All ELO changes
spa_distribution       JSONB[]      -- All SPA distributions
prize_distribution     JSONB[]      -- Top 3 prizes
vouchers_issued        JSONB[]      -- Top 4 vouchers
```
**👁️ User xem**: KHÔNG - Chỉ admin/audit

---

#### G. `notifications` table
```sql
user_id                UUID
title                  TEXT         -- "🎉 Chúc mừng! Bạn đạt vị trí X"
message                TEXT         -- Chi tiết rewards
type                   TEXT         -- "tournament_completion"
data                   JSONB        -- {elo, spa, prize, voucher...}
is_read                BOOLEAN
created_at             TIMESTAMP
```
**👁️ User xem**: Notification Bell → List notifications

---

## 3️⃣ USER INTERFACE - XEM Ở ĐÂU?

### 📱 A. Profile Screen (Real-time Stats)
**File**: `lib/presentation/user_profile_screen/user_profile_screen.dart`

```dart
displayUserData['eloRating'] = _userProfile!.eloRating;     // FROM users.elo_rating
displayUserData['spaPoints'] = _userProfile!.spaPoints;     // FROM users.spa_points
displayUserData['totalTournaments'] = _userProfile!.totalTournaments; // FROM users.total_tournaments
```

**Hiển thị**:
- ⭐ ELO Badge: "1500 ELO"
- 💎 SPA Badge: "2500 SPA"
- 🏆 Tournaments: "12 giải"

---

### 🏆 B. Tournament Detail Screen → Results Tab
**Query**: `tournament_results WHERE tournament_id = ?`

**Hiển thị**:
- Bảng xếp hạng 16 user
- Mỗi user: Position, Name, W/L, ELO Change, SPA, Prize, Voucher
- Filter/Sort by position

---

### 🎁 C. User Voucher Screen
**File**: `lib/presentation/user_voucher_screen/user_voucher_screen.dart`
**Query**: `user_vouchers WHERE user_id = ? AND status = 'active'`

**Hiển thị**:
- Tab "Active Vouchers"
- Card: Voucher code, Discount %, Expires date
- Button "Use Now" → QR Code

---

### 💎 D. SPA Rewards Screen → History Tab
**File**: `lib/presentation/spa_management/spa_reward_screen.dart`
**Query**: `transactions WHERE user_id = ? ORDER BY created_at DESC`

**Hiển thị**:
- Lịch sử nhận SPA
- "Tournament completion: +500 SPA"
- Balance before → after

---

### 🔔 E. Notifications Screen
**Query**: `notifications WHERE user_id = ? ORDER BY created_at DESC`

**Hiển thị**:
- "🎉 Chúc mừng! Bạn đạt vị trí 1 trong SABO DE16"
- "💰 Bạn nhận: +50 ELO, +1000 SPA, 500k VND, Voucher WINNER_50"
- Tap → Navigate to Tournament Detail

---

## 4️⃣ WORKFLOW END-TO-END

```
┌─────────────────────────────────────────────────────────────┐
│  ADMIN COMPLETE TOURNAMENT                                  │
│  (Bấm nút "Complete Tournament" trong Settings Tab)         │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│  TOURNAMENT COMPLETION ORCHESTRATOR                         │
│  File: tournament_completion_orchestrator.dart              │
└─────────────────────────────────────────────────────────────┘
                        ↓
        ┌───────────────┴───────────────┐
        ↓                               ↓
┌──────────────────┐          ┌──────────────────┐
│  ELO UPDATE      │          │  PRIZE DISTRIBUTION │
│  Service         │          │  Service         │
└──────────────────┘          └──────────────────┘
        ↓                               ↓
┌──────────────────┐          ┌──────────────────┐
│  UPDATE:         │          │  UPDATE:         │
│  users.elo_rating│          │  users.spa_points│
│  elo_history     │          │  transactions    │
└──────────────────┘          └──────────────────┘
                        ↓
        ┌───────────────┴───────────────┐
        ↓                               ↓
┌──────────────────┐          ┌──────────────────┐
│  VOUCHER SERVICE │          │  RESULT SERVICE  │
│  (Top 4 only)    │          │  (All 16 users)  │
└──────────────────┘          └──────────────────┘
        ↓                               ↓
┌──────────────────┐          ┌──────────────────┐
│  INSERT:         │          │  INSERT/UPDATE:  │
│  user_vouchers   │          │  tournament_     │
│  (1 row/user)    │          │  results         │
│                  │          │  (1 row/user)    │
└──────────────────┘          └──────────────────┘
                        ↓
        ┌───────────────┴───────────────┐
        ↓                               ↓
┌──────────────────┐          ┌──────────────────┐
│  NOTIFICATION    │          │  SOCIAL POST     │
│  Service         │          │  Service         │
└──────────────────┘          └──────────────────┘
        ↓                               ↓
┌──────────────────┐          ┌──────────────────┐
│  INSERT:         │          │  CREATE:         │
│  notifications   │          │  posts (feed)    │
│  (16 users)      │          │  chat_messages   │
└──────────────────┘          └──────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│  ✅ TOURNAMENT COMPLETED                                    │
│                                                             │
│  16 users mỗi người nhận:                                   │
│  ✅ ELO updated → Profile badge real-time                   │
│  ✅ SPA updated → Có thể đổi quà ngay                       │
│  ✅ Voucher (Top 4) → User Voucher Screen                   │
│  ✅ Prize money recorded (Top 3) → Tournament Results       │
│  ✅ Tournament stats → Tournament History Tab               │
│  ✅ Notification → "Chúc mừng bạn..."                       │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│  USER MỞ APP                                                │
│                                                             │
│  1. Profile → Thấy ELO & SPA tăng ngay lập tức              │
│  2. Notification → Thông báo chi tiết rewards               │
│  3. Tournament History → Xem kết quả chi tiết               │
│  4. Voucher Screen → Voucher mới (nếu Top 4)                │
│  5. SPA Rewards → Có thể đổi quà với SPA mới nhận           │
└─────────────────────────────────────────────────────────────┘
```

---

## 5️⃣ SAMPLE DATA - VÍ DỤ THỰC TẾ

### User Position 1 (Champion) nhận được:

```yaml
Profile Stats:
  ELO: 1000 → 1050 (+50)
  SPA: 500 → 1500 (+1000)
  Total Tournaments: 5 → 6

Tournament Results Record:
  tournament_id: "sabo166..."
  participant_name: "hello hu a yao"
  position: 1
  matches: 5W/0L (100%)
  old_elo: 1000
  new_elo: 1050
  elo_change: +50
  spa_reward: 1000
  prize_money_vnd: 500000
  voucher_code: "WINNER_50"
  voucher_discount_percent: 50

Voucher Record:
  voucher_code: "WINNER_50"
  discount_percent: 50%
  status: "active"
  expires_at: "2025-12-07" (30 ngày)
  
Notification:
  "🎉 Chúc mừng! Bạn vô địch SABO DE16"
  "💰 Phần thưởng: +50 ELO, +1000 SPA, 500k VND, Voucher giảm 50%"
```

### User Position 5 nhận được:

```yaml
Profile Stats:
  ELO: 1200 → 1195 (-5)
  SPA: 300 → 700 (+400) ← Top 25%
  Total Tournaments: 3 → 4

Tournament Results Record:
  position: 5
  matches: 3W/2L (60%)
  old_elo: 1200
  new_elo: 1195
  elo_change: -5
  spa_reward: 400
  prize_money_vnd: 0 ← Không có prize
  voucher_code: NULL ← Không có voucher
  
Notification:
  "🏆 Bạn đạt vị trí thứ 5 trong SABO DE16"
  "💰 Phần thưởng: -5 ELO, +400 SPA"
```

---

## 6️⃣ CHECKLIST KIỂM TRA

### ✅ Sau khi Complete Tournament, check:

- [ ] `users` table: ELO & SPA đã update cho 16 users?
- [ ] `elo_history`: 16 records mới với reason="tournament_completion"?
- [ ] `transactions`: 16 SPA transaction records?
- [ ] `tournament_results`: 16 rows (1/user) với đầy đủ rewards?
- [ ] `user_vouchers`: 4 vouchers cho Top 4?
- [ ] `notifications`: 16 thông báo gửi đến 16 users?
- [ ] Profile Screen: ELO & SPA hiển thị real-time?
- [ ] Tournament Results: Bảng xếp hạng đầy đủ?
- [ ] Voucher Screen: Top 4 thấy voucher mới?

---

## 📝 TÓM TẮT

| Reward | Ghi vào table | User xem ở đâu | Ai nhận? |
|--------|---------------|----------------|----------|
| **ELO** | `users.elo_rating`<br>`elo_history`<br>`tournament_results` | Profile Badge<br>Tournament Results | All 16 |
| **SPA** | `users.spa_points`<br>`transactions`<br>`tournament_results` | Profile Badge<br>SPA Rewards Screen<br>Tournament Results | All 16 |
| **Prize Money** | `tournament_results.prize_money_vnd` | Tournament Results<br>Notification | Top 3 |
| **Voucher** | `user_vouchers`<br>`tournament_results.voucher_code` | User Voucher Screen<br>Notification | Top 4 |
| **Tournament Stats** | `tournament_results`<br>`users.total_tournaments` | Profile<br>Tournament History Tab | All 16 |
| **Notification** | `notifications` | Notification Bell | All 16 |

---

**✅ STATUS**: HOÀN CHỈNH 100%  
**📅 Date**: November 7, 2025  
**🔗 Related**: `FINAL_VERIFICATION_REPORT.md`
