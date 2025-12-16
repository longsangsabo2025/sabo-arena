# ✅ ENHANCED ELO HISTORY CARD - Chi tiết thông tin thay đổi ELO

## 📊 DATA SOURCE

**Bảng chính**: `elo_history`
```sql
SELECT 
  user_id,
  tournament_id,
  old_elo,
  new_elo,
  elo_change,
  reason,              -- 'Tournament completion (position 1)'
  change_reason,       -- Legacy field
  created_at
FROM elo_history
WHERE user_id = {current_user_id}
ORDER BY created_at DESC;
```

**Bảng bổ sung** (để lấy chi tiết):
- `tournaments` - Tên giải, format (DE8, DE16, Round Robin...)
- `tournament_participants` - Vị trí cuối, wins/losses

---

## 🎨 CẢI TIẾN GIAO DIỆN

### TRƯỚC (Old Version):
```
📊 initial rating
ELO cũ: 1000 → 0 → ELO mới: 1000
```

### SAU (New Version):
```
📊 Giải Anh Long Magic
    🏆 Vô địch • Loại trực tiếp 16 • 4-0
    
ELO cũ: 1000 → +75 → ELO mới: 1075
```

---

## 🔧 THAY ĐỔI CODE

### File: `lib/presentation/user_profile_screen/elo_history_screen.dart`

### 1️⃣ Enhanced Tournament Query (Line 520-590)

**BEFORE**:
```dart
final tournamentResponse = await _supabase
    .from('tournaments')
    .select('name, id')  // Chỉ lấy tên
    .eq('id', tournamentId)
    .single();
```

**AFTER**:
```dart
final tournamentResponse = await _supabase
    .from('tournaments')
    .select('name, id, format')  // ✅ Thêm format
    .eq('id', tournamentId)
    .single();
```

### 2️⃣ Detailed Reason Text (Line 535-580)

**NEW FEATURES**:

#### A. Position Display với Emoji
```dart
if (position == 1) {
  positionText = '🏆 Vô địch';
} else if (position == 2) {
  positionText = '🥈 Á quân';
} else if (position == 3 || position == 4) {
  positionText = '🥉 Hạng $position';
} else if (position <= 8) {
  positionText = 'Top $position';
} else {
  positionText = 'Hạng $position';
}
```

#### B. Tournament Format Display
```dart
final formatMap = {
  'de8': 'Loại trực tiếp 8',
  'de16': 'Loại trực tiếp 16',
  'de32': 'Loại trực tiếp 32',
  'de64': 'Loại trực tiếp 64',
  'round_robin': 'Vòng tròn',
  'swiss': 'Swiss',
  'song_to': 'Song Tô',
};
formatText = formatMap[tournamentFormat] ?? tournamentFormat.toUpperCase();
```

#### C. Combined Display
```dart
List<String> parts = [];
if (positionText.isNotEmpty) parts.add(positionText);
if (formatText.isNotEmpty) parts.add(formatText);
parts.add('$wins-$losses');

return '$tournamentName\n${parts.join(' • ')}';
```

**Result Example**:
```
Giải Anh Long Magic
🏆 Vô địch • Loại trực tiếp 16 • 4-0
```

---

## 📱 UI EXAMPLES

### Example 1: Champion (Position 1)
```
┌────────────────────────────────────┐
│ 🔼 +75 điểm     📅 06/11 06:52   │
├────────────────────────────────────┤
│ 🏆 Giải Anh Long Magic             │
│    🏆 Vô địch • DE16 • 4-0         │
│                                    │
│ ELO cũ     →  +75  →   ELO mới   │
│  1000                    1075      │
│                                    │
│ 🏆 Từ giải đấu                     │
└────────────────────────────────────┘
```

### Example 2: Runner-up (Position 2)
```
┌────────────────────────────────────┐
│ 🔼 +50 điểm     📅 07/11 19:53   │
├────────────────────────────────────┤
│ 🥈 Giải Tri Mi Nhon                │
│    🥈 Á quân • DE32 • 3-1          │
│                                    │
│ ELO cũ     →  +50  →   ELO mới   │
│  1075                   1125       │
└────────────────────────────────────┘
```

### Example 3: Top 4 (Position 3-4)
```
┌────────────────────────────────────┐
│ 🔼 +25 điểm     📅 08/11 10:30   │
├────────────────────────────────────┤
│ 🥉 Giải SABO Arena Cup             │
│    🥉 Hạng 3 • Vòng tròn • 2-2    │
│                                    │
│ ELO cũ     →  +25  →   ELO mới   │
│  1125                   1150       │
└────────────────────────────────────┘
```

### Example 4: Participation (Lower rank)
```
┌────────────────────────────────────┐
│ 🔻 -10 điểm     📅 08/11 14:20   │
├────────────────────────────────────┤
│ 📊 Giải Weekend Tournament         │
│    Hạng 12 • Swiss • 1-3           │
│                                    │
│ ELO cũ     →  -10  →   ELO mới   │
│  1150                   1140       │
└────────────────────────────────────┘
```

### Example 5: Initial Rating (No tournament)
```
┌────────────────────────────────────┐
│ 📊 0 điểm       📅 06/11 06:52   │
├────────────────────────────────────┤
│ 📊 initial rating                  │
│                                    │
│ ELO cũ     →   0   →   ELO mới   │
│  1000                   1000       │
└────────────────────────────────────┘
```

---

## 🎯 THÔNG TIN HIỂN THỊ

### Card Header:
- ✅ **Change Amount**: `+75 điểm` / `-10 điểm`
- ✅ **Icon**: 🔼 (positive) / 🔻 (negative)
- ✅ **Time**: `06/11 06:52`

### Reason Section:
- ✅ **Emoji**: 🏆🥈🥉📊✅❌⬆️⬇️🔧
- ✅ **Tournament Name**: `Giải Anh Long Magic`
- ✅ **Position**: `🏆 Vô địch` / `🥈 Á quân` / `Top 8` / `Hạng 12`
- ✅ **Format**: `Loại trực tiếp 16` / `Vòng tròn` / `Swiss`
- ✅ **Win-Loss**: `4-0` / `3-1` / `2-2`

### ELO Change:
- ✅ **Old ELO**: Gray box with border
- ✅ **Arrow + Change**: Colored arrow with `+75` or `-10`
- ✅ **New ELO**: Colored box matching change type

### Footer (if tournament):
- ✅ **Badge**: 🏆 Từ giải đấu

---

## 🗄️ DATABASE SCHEMA

### elo_history Table:
```sql
CREATE TABLE elo_history (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  tournament_id UUID REFERENCES tournaments(id),  -- ✅ Link to tournament
  old_elo INTEGER NOT NULL,
  new_elo INTEGER NOT NULL,
  elo_change INTEGER NOT NULL,
  reason TEXT NOT NULL,                           -- ✅ Detailed reason
  change_reason TEXT,                             -- Legacy
  created_at TIMESTAMP DEFAULT NOW()
);
```

### tournaments Table:
```sql
CREATE TABLE tournaments (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  format TEXT NOT NULL,  -- ✅ 'de8', 'de16', 'de32', 'round_robin', 'swiss', 'song_to'
  status TEXT,
  ...
);
```

### tournament_participants Table:
```sql
CREATE TABLE tournament_participants (
  tournament_id UUID REFERENCES tournaments(id),
  user_id UUID REFERENCES users(id),
  final_position INTEGER,  -- ✅ 1, 2, 3, 4, 5...
  wins INTEGER DEFAULT 0,  -- ✅ Wins count
  losses INTEGER DEFAULT 0,  -- ✅ Losses count
  ...
);
```

---

## 🔍 QUERY FLOW

```
1. Load elo_history records
   ↓
2. For each record with tournament_id:
   ├─ Query tournaments → Get name + format
   └─ Query tournament_participants → Get position + wins/losses
   ↓
3. Build detailed text:
   - Position emoji (🏆🥈🥉)
   - Format name (DE16, Vòng tròn...)
   - Win-Loss record (4-0, 3-1...)
   ↓
4. Display in card:
   "Giải Anh Long Magic
    🏆 Vô địch • Loại trực tiếp 16 • 4-0"
```

---

## 📊 REASON MAPPING

| reason (DB) | Emoji | Display Text | Source |
|-------------|-------|--------------|--------|
| `initial_rating` | 📊 | initial rating | System |
| `Tournament completion (position 1)` | 🏆 | {Name} • Vô địch • {Format} • {W-L} | Tournament |
| `Tournament completion (position 2)` | 🥈 | {Name} • Á quân • {Format} • {W-L} | Tournament |
| `Tournament completion (position 3)` | 🥉 | {Name} • Hạng 3 • {Format} • {W-L} | Tournament |
| `tournament_participation` | 🎮 | Tham gia giải đấu | Tournament |
| `match_win` | ✅ | Thắng trận đấu | Match |
| `match_loss` | ❌ | Thua trận đấu | Match |
| `rank_promotion` | ⬆️ | Thăng hạng | Rank System |
| `rank_demotion` | ⬇️ | Giáng hạng | Rank System |
| `manual_adjustment` | 🔧 | Điều chỉnh thủ công | Admin |

---

## ✅ BENEFITS

### User Experience:
- ✅ **Chi tiết hơn**: Biết được vô địch hay á quân
- ✅ **Rõ ràng hơn**: Hiển thị format giải (DE16, Round Robin...)
- ✅ **Thông tin đầy đủ**: Win-loss record (4-0, 3-1...)
- ✅ **Visual cues**: Emoji giúp nhận diện nhanh
- ✅ **Context**: Link trực tiếp đến tournament

### Technical:
- ✅ **Efficient**: Chỉ query khi có tournament_id
- ✅ **Cached**: FutureBuilder cache results
- ✅ **Fallback**: Graceful degradation nếu query fail
- ✅ **Scalable**: Dễ thêm reason types mới

---

## 🚀 FUTURE ENHANCEMENTS

### Có thể thêm:

1. **Prize Money Display**:
   ```
   🏆 Vô địch • DE16 • 4-0
   💰 +500,000 VND
   ```

2. **Opponent Info**:
   ```
   ✅ Thắng @player123 (2-0)
   ```

3. **ELO Rank Display**:
   ```
   🏆 Vô địch • DE16 • 4-0
   📊 Rank: #24 → #18 (+6)
   ```

4. **Click to view tournament**:
   ```dart
   onTap: () => Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => TournamentDetailScreen(
         tournamentId: tournamentId,
       ),
     ),
   ),
   ```

---

## 📝 SUMMARY

**Card hiện tại hiển thị**:
- ✅ Tournament name
- ✅ Position with emoji (🏆🥈🥉)
- ✅ Tournament format (DE16, Round Robin...)
- ✅ Win-Loss record (4-0, 3-1...)
- ✅ ELO change (+75, -10...)
- ✅ Old/New ELO values
- ✅ Timestamp

**Data source**: `elo_history` + `tournaments` + `tournament_participants`

**User benefit**: Biết chính xác ELO thay đổi do hoạt động cụ thể nào, vị trí nào, format gì, và thành tích ra sao! 🎉
