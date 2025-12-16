# 👤 User Widgets - Unified User Display Components

## 📋 Overview

Bộ components chuẩn hóa để hiển thị thông tin user (avatar, tên, rank) trong toàn bộ ứng dụng Sabo Arena.

### ❌ Vấn đề trước đây:
- 100+ nơi dùng logic inline khác nhau để hiển thị avatar
- Không có caching hoặc error handling nhất quán
- Display name priority logic lộn xộn (display_name vs displayName vs full_name)
- Rank hiển thị không đồng bộ (có chỗ code, có chỗ tên)

### ✅ Giải pháp:
Single source of truth cho tất cả user display components.

---

## 🎨 Components

### 1. **UserAvatarWidget**
Avatar với automatic caching, shimmer loading, rank border gradient.

```dart
// Basic avatar
UserAvatarWidget(
  avatarUrl: user.avatarUrl,
  size: 50,
)

// Avatar với rank border
UserAvatarWidget(
  avatarUrl: user.avatarUrl,
  rankCode: 'G',
  size: 80,
  showRankBorder: true,
)

// Avatar with badge
UserAvatarWithBadge(
  avatarUrl: user.avatarUrl,
  badge: OnlineStatusBadge(isOnline: true),
  badgePosition: BadgePosition.bottomRight,
)
```

**Features:**
- ✅ Auto caching với CachedNetworkImage
- ✅ Shimmer loading effect
- ✅ Graceful error handling
- ✅ Optional rank border gradient
- ✅ Badge support (online, verified, notification)

---

### 2. **UserDisplayNameText**
Tên user với priority logic chuẩn: `display_name` > `displayName` > `full_name` > `fullName`.

```dart
// Basic name
UserDisplayNameText(
  userData: {'display_name': 'John Doe'},
)

// With verified badge
UserDisplayNameText(
  userData: userMap,
  showVerifiedBadge: true,
  maxLength: 20,
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
)

// Name + username (profile screen)
UserNameWithUsername(
  userData: userMap,
  showVerifiedBadge: true,
)
```

**Helper Functions:**
```dart
// Get name as String
final name = UserDisplayNameHelper.getDisplayName(userData);

// Get short name
final short = UserDisplayNameHelper.getShortDisplayName(userData, maxLength: 15);

// Get initials ("John Doe" -> "JD")
final initials = UserDisplayNameHelper.getInitials(userData);

// Get username with @
final username = UserDisplayNameHelper.getUsername(userData); // "@johndoe"
```

---

### 3. **UserRankBadgeWidget**
Rank badge với 3 styles: compact, standard, detailed.

```dart
// Compact (cho lists)
UserRankBadgeWidget(
  rankCode: 'G',
  style: RankBadgeStyle.compact,
)

// Standard (default)
UserRankBadgeWidget(
  rankCode: 'G',
  showFullName: true,
  eloRating: 1650,
)

// Detailed (cho profile)
UserRankBadgeWidget(
  rankCode: 'G',
  style: RankBadgeStyle.detailed,
  onTap: () => showRankInfo(),
)

// Unranked user
UserRankBadgeWidget(
  rankCode: null, // Hiển thị "Chưa xác minh hạng"
  onTap: () => showRankRegistration(),
)
```

**Additional Widgets:**
```dart
// Simple rank icon
UserRankIcon(rankCode: 'G', size: 24)

// Rank comparison (for match-ups)
RankComparisonWidget(
  player1Rank: 'G',
  player2Rank: 'E',
  player1Name: 'John',
  player2Name: 'Jane',
)
```

---

### 4. **UserProfileCard**
Reusable card component cho lists, grids, leaderboards.

```dart
// List variant (default)
UserProfileCard(
  userData: userMap,
  variant: UserCardVariant.list,
  showRank: true,
  showStats: true,
  onTap: () => navigateToProfile(),
  trailing: IconButton(
    icon: Icon(Icons.more_vert),
    onPressed: () => showMenu(),
  ),
)

// Compact variant
UserProfileCard(
  userData: userMap,
  variant: UserCardVariant.compact,
  showRank: true,
)

// Grid variant
UserProfileCard(
  userData: userMap,
  variant: UserCardVariant.grid,
  showRank: true,
  showStats: true,
)

// Simple ListTile wrapper
UserProfileListTile(
  userData: userMap,
  showRank: true,
  onTap: () => navigateToProfile(),
  trailing: Icon(Icons.arrow_forward_ios),
)

// Chip style (for tags, mentions)
UserProfileChip(
  userData: userMap,
  showAvatar: true,
  onDeleted: () => removeUser(),
)
```

---

## 📦 Import

```dart
// Import tất cả components
import 'package:sabo_arena/widgets/user/user_widgets.dart';

// Hoặc import riêng lẻ
import 'package:sabo_arena/widgets/user/user_avatar_widget.dart';
import 'package:sabo_arena/widgets/user/user_display_name_text.dart';
import 'package:sabo_arena/widgets/user/user_rank_badge_widget.dart';
import 'package:sabo_arena/widgets/user/user_profile_card.dart';
```

---

## 🔧 Migration Guide

### Before (Old way):
```dart
// ❌ Inline logic, không nhất quán
CircleAvatar(
  backgroundImage: user['avatar_url'] != null 
    ? NetworkImage(user['avatar_url']) 
    : null,
  child: user['avatar_url'] == null ? Icon(Icons.person) : null,
)

Text(
  user['display_name'] ?? user['full_name'] ?? 'Unknown',
  style: TextStyle(fontSize: 16),
)

Container(
  padding: EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: SaboRankSystem.getRankColor(rank).withOpacity(0.2),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text('Rank $rank'),
)
```

### After (New way):
```dart
// ✅ Sử dụng unified components
UserAvatarWidget(
  avatarUrl: user['avatar_url'],
  rankCode: user['rank'],
  size: 50,
  showRankBorder: true,
)

UserDisplayNameText(
  userData: user,
  style: TextStyle(fontSize: 16),
  showVerifiedBadge: true,
)

UserRankBadgeWidget(
  rankCode: user['rank'],
  style: RankBadgeStyle.compact,
)
```

---

## 🎯 Best Practices

### ✅ DO:
```dart
// Use unified components
UserAvatarWidget(avatarUrl: url, size: 50)

// Use helper for String operations
final name = UserDisplayNameHelper.getDisplayName(userData);

// Show rank with badge widget
UserRankBadgeWidget(rankCode: 'G')
```

### ❌ DON'T:
```dart
// Don't inline avatar logic
CircleAvatar(backgroundImage: NetworkImage(url))

// Don't inline name priority logic
userData['display_name'] ?? userData['full_name'] ?? 'Unknown'

// Don't manually build rank badges
Container(child: Text('Rank G'))
```

---

## 📊 Component Comparison

| Component | Old Way | New Way | Benefits |
|-----------|---------|---------|----------|
| **Avatar** | `CircleAvatar` + manual error handling | `UserAvatarWidget` | Auto caching, shimmer, rank border |
| **Name** | Inline logic: `userData['display_name'] ?? userData['full_name']` | `UserDisplayNameText` | Nhất quán, null-safe, verified badge |
| **Rank** | Manual `Container` + `SaboRankSystem.getRankColor()` | `UserRankBadgeWidget` | 3 styles, unranked handling, clickable |
| **Card** | Custom build mỗi screen | `UserProfileCard` | 3 variants, stats, trailing widget |

---

## 🚀 Performance

### Caching:
- `UserAvatarWidget` dùng `CachedNetworkImage` → **auto cache images**
- `UserDisplayNameHelper` là static functions → **không rebuild**

### Memory:
- Avatar shimmer chỉ render khi loading → **save memory**
- Rank color computed once → **cached in SaboRankSystem**

---

## 🧪 Testing

```dart
testWidgets('UserAvatarWidget shows default avatar on error', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: UserAvatarWidget(
        avatarUrl: 'invalid-url',
        size: 50,
      ),
    ),
  );
  
  // Should show default avatar icon
  expect(find.byIcon(Icons.person), findsOneWidget);
});

test('UserDisplayNameHelper returns display_name first', () {
  final userData = {
    'display_name': 'John Doe',
    'full_name': 'Johnathan Doe',
  };
  
  final name = UserDisplayNameHelper.getDisplayName(userData);
  expect(name, 'John Doe');
});
```

---

## 📝 Changelog

### v1.0.0 (2025-01-XX)
- ✅ Initial release
- ✅ 4 core components: Avatar, DisplayName, RankBadge, ProfileCard
- ✅ Migration từ 100+ inline implementations
- ✅ Full documentation

---

## 🔗 Related Files

- `lib/core/utils/sabo_rank_system.dart` - Rank color & name logic
- `lib/models/user_profile.dart` - UserProfile model
- `lib/widgets/custom_image_widget.dart` - Old avatar widget (deprecated)

---

**Author:** Sabo Arena Team  
**Last Updated:** January 2025
