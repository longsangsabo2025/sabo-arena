# 🚀 Quick Start: SABO DE24

## 📋 Tóm tắt nhanh
- **24 players** → **51 matches** → **3-4 giờ**
- Vòng loại: 8 bảng × 3 người
- Vòng trong: DE16 (16 người vào)

## 🎯 Cách sử dụng

### 1. Tạo tournament DE24

```dart
import 'package:saboarenav4/services/hardcoded_sabo_de24_service.dart';

final service = HardcodedSaboDE24Service(supabase);

// Cần đúng 24 player IDs
final playerIds = [...]; // 24 IDs

await service.createDE24Tournament(
  tournamentId: tournamentId,
  participantIds: playerIds,
);
```

### 2. Hiển thị Group Stage

```dart
import 'package:saboarenav4/presentation/tournament_detail_screen/widgets/de24_group_stage_widget.dart';

DE24GroupStageWidget(tournamentId: tournamentId)
```

### 3. Hoàn thành Group Stage

Sau khi tất cả 24 matches vòng bảng đã xong:

```dart
await service.advanceGroupWinnersToMainStage(tournamentId);
```

### 4. Tiếp tục với DE16

Main stage (matches 25-51) chạy như SABO DE16 bình thường.

## 📊 Match Structure

```
Matches 1-24: Group Stage (8 groups × 3 matches)
  Group A: 1-3
  Group B: 4-6
  Group C: 7-9
  Group D: 10-12
  Group E: 13-15
  Group F: 16-18
  Group G: 19-21
  Group H: 22-24

Matches 25-51: Main Stage (DE16)
  WB R1: 25-32
  WB R2: 33-36
  WB Semi: 37-38
  LB-A: 39-45
  LB-B: 46-48
  Finals: 49-51
```

## ✅ Advantages

1. **Công bằng**: Mọi người đá ít nhất 2 trận
2. **Nhanh**: Vòng bảng round-robin = 3 trận/bảng
3. **Hấp dẫn**: 3 người/bảng = đánh xoay vòng thú vị
4. **Cơ hội thứ 2**: DE16 cho loser bracket

## 🎮 Ví dụ thực tế

```
Group A:
  Sabo vs Long: 11-7 → Sabo wins (3 pts)
  Sabo vs Minh: 11-9 → Sabo wins (3 pts)
  Long vs Minh: 11-8 → Long wins (3 pts)

Standings:
  1. Sabo: 2-0 = 6pts ✅ Advance
  2. Long: 1-1 = 3pts ✅ Advance
  3. Minh: 0-2 = 0pts ❌ Eliminated
```

## 🔧 Code Integration

Đã tạo:
- ✅ `hardcoded_sabo_de24_service.dart` - Tournament structure
- ✅ `de24_group_stage_widget.dart` - UI hiển thị
- ✅ `SABO_DE24_FORMAT.md` - Documentation đầy đủ
- ✅ `test_de24_format.py` - Validation script

## 📱 UI Flow

1. **Create Tournament** → Chọn DE24 format
2. **Group Stage Tab** → 8 bảng hiển thị standings
3. **Complete Groups** → Tự động advance top 2
4. **Main Stage Tab** → DE16 bracket như bình thường

Done! 🎉
