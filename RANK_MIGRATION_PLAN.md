# 🎯 RANK SYSTEM MIGRATION PLAN

## 📊 SO SÁNH HỆ THỐNG CŨ VS MỚI

### ❌ RANKS BỊ XÓA:
- **K+** (1100-1199) → LOẠI BỎ
- **I+** (1300-1399) → LOẠI BỎ

---

## 🗺️ BẢNG MAPPING MỚI (DỰA TRÊN ẢNH)

| RANK | ELO RANGE CŨ | ELO RANGE MỚI | BI | ĐỘ ỔN ĐỊNH (từ ảnh) |
|------|--------------|---------------|-----|---------------------|
| **K** | 1000-1099 | **1000-1099** | **1-2 Bi** | Không ổn định, chỉ biết các kỹ thuật như cule, trỏ |
| ~~K+~~ | ~~1100-1199~~ | ❌ **LOẠI BỎ** | - | - |
| **I** | 1200-1299 | **1100-1199** ⬇️ | **1-3 Bi** | Không ổn định, chỉ biết đơn và biết các kỹ thuật như cule, trỏ |
| ~~I+~~ | ~~1300-1399~~ | ❌ **LOẠI BỎ** | - | - |
| **H** | 1400-1499 | **1200-1299** ⬇️ | **3-5 Bi** | Chưa ổn định, không có khả năng đi chấm, biết 1 ít ắp phẻ |
| **H+** | 1500-1599 | **1300-1399** ⬇️ | **3-5 Bi** | Ổn định, không có khả năng đi chấm, Don 1-2 hinh tren 1 race 7 |
| **G** | 1600-1699 | **1400-1499** ⬇️ | **5-6 Bi** | Chưa ổn định, đi được 1 chấm / race cham 7, Don 3 hình trên 1 race 7 |
| **G+** | 1700-1799 | **1500-1599** ⬇️ | **5-6 Bi** | Ổn định, đi được 1 chấm / race cham 7, Don 4 hình trên 1 race 7 |
| **F** | 1800-1899 | **1600-1699** ⬇️ | **6-8 Bi** | Rất ổn định, đi được 2 chấm / race cham 7, Đi hình, don bàn khá tốt |

---

## ⚠️ VẤN ĐỀ CẦN XÁC NHẬN:

### 🔍 Ảnh chỉ hiển thị từ K → F (7 ranks)
### ❓ Còn các rank cao hơn F thì sao?

**Hệ thống hiện tại có:**
- F+ (1700-1799 cũ)
- E (1800-1899 cũ) 
- D (1900-1999 cũ)
- C (2000-2099 cũ)

**Đề xuất cho ranks cao (F+ → C):**

| RANK | ELO MỚI | BI | ĐỘ ỔN ĐỊNH |
|------|---------|-----|-----------|
| **F+** | **1700-1799** ⬇️ | **2 Cham** | Cực kỳ ổn định, kha nang di 2 cham thong |
| **E** | **1800-1899** ⬇️ | **3 Cham** | Chuyên gia, kha nang di 3 cham thong |
| **D** | **1900-1999** ⬇️ | **4 Cham** | Huyền thoại, kha nang di 4 cham thong |
| **C** | **2000-2099** ⬇️ | **5 cham** | Vô địch, kha nang di 5 cham thong |

---

## 🎯 IMPACT ANALYSIS

### 📈 USER ELO MIGRATION:

**Ví dụ:**
- User có ELO **1150** (cũ: K+ rank) → Sau migration: **I rank**
- User có ELO **1350** (cũ: I+ rank) → Sau migration: **H+ rank**
- User có ELO **1450** (cũ: H rank) → Sau migration: **G rank**

### ⚠️ BREAKING CHANGES:

1. **Tất cả users sẽ TĂNG RANK** (do ELO range shift xuống):
   - ELO 1150: K+ → I (tăng 1 bậc)
   - ELO 1250: I → H (tăng 1 bậc)
   - ELO 1350: I+ → H+ (tăng 1 bậc)

2. **Matching Algorithm**: Opponent matching cần update vì rank order thay đổi

3. **Rank History**: Cần migrate rank_change_logs để phản ánh đúng

---

## ✅ XÁC NHẬN CỦA BẠN:

1. ✅ Bảng mapping K → F đã đúng chưa?
2. ❓ F+ → C có giữ không? Nếu có, định nghĩa thế nào?
3. ❓ Có cần thông báo cho users về việc rank tăng tự động?
4. ❓ Có cần backup hoặc migration script cho existing users?

**VUI LÒNG XÁC NHẬN ĐỂ TÔI TIẾP TỤC!**
