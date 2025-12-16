# 📘 CLUB DASHBOARD DESIGN SYSTEM REFACTOR GUIDE

## 🎯 Mục Tiêu

Hướng dẫn chi tiết cách áp dụng Design System vào Club Dashboard Screen, từng bước một với code examples đầy đủ.

---

## 📋 Tổng Quan Dashboard

**File hiện tại:** `club_dashboard_screen_simple.dart` (1743 lines)

**Cấu trúc chính:**
1. **Stats Cards** - 4 cards hiển thị số liệu (Members, Tournaments, Revenue, Activities)
2. **Quick Actions** - 6 buttons actions nhanh (Thành viên, Giải đấu, Lịch sử, Báo cáo, Thông báo, Cài đặt)
3. **Activities Timeline** - List các hoạt động gần đây
4. **Club Header** - Club logo, cover photo, edit buttons
5. **Filters** - Chips để filter activities
6. **Bottom Navigation** - Navigation bar

---

## 🔄 Icon Mapping Reference

### Icons hiện tại → Design System

```dart
// ❌ KHÔNG CÓ trong AppIcons
AppIcons.speed        // undefined
AppIcons.timeline     // undefined
AppIcons.people       // undefined
AppIcons.money        // undefined
AppIcons.sports       // undefined
AppIcons.allInclusive // undefined
AppIcons.fitness      // undefined
AppIcons.groups       // undefined
AppIcons.personAdd    // undefined
AppIcons.playArrow    // undefined
AppIcons.chart        // undefined

// ✅ SỬ DỤNG THAY THẾ
AppIcons.dashboard       // cho speed/dashboard
AppIcons.event           // cho timeline
AppIcons.following       // cho people
Icons.attach_money       // hoặc dùng trực tiếp cho money
AppIcons.trophy          // cho sports (billiards)
Icons.all_inclusive      // dùng trực tiếp
Icons.fitness_center     // dùng trực tiếp
AppIcons.group           // cho groups
AppIcons.follow          // cho personAdd
AppIcons.play            // cho playArrow
Icons.bar_chart          // dùng trực tiếp cho chart
AppIcons.calendar        // cho date/calendar
AppIcons.history         // undefined, dùng Icons.history
```

### Icons có sẵn trong AppIcons

```dart
// Navigation
AppIcons.home
AppIcons.search
AppIcons.notifications, AppIcons.notificationsOutlined
AppIcons.profile, AppIcons.profileOutlined
AppIcons.menu
AppIcons.back, AppIcons.forward
AppIcons.close
AppIcons.settings, AppIcons.settingsOutlined

// Actions
AppIcons.add, AppIcons.addCircle
AppIcons.edit, AppIcons.editOutlined
AppIcons.delete, AppIcons.deleteOutlined
AppIcons.save
AppIcons.share
AppIcons.send
AppIcons.download
AppIcons.upload
AppIcons.refresh
AppIcons.filter
AppIcons.sort

// Social
AppIcons.like, AppIcons.likeOutlined
AppIcons.comment, AppIcons.commentOutlined
AppIcons.message, AppIcons.messageOutlined
AppIcons.follow, AppIcons.followOutlined
AppIcons.following, AppIcons.followingOutlined
AppIcons.group, AppIcons.groupOutlined
AppIcons.event, AppIcons.eventOutlined
AppIcons.trophy, AppIcons.trophyOutlined
AppIcons.star, AppIcons.starOutlined
AppIcons.verified
AppIcons.bookmark

// Content
AppIcons.camera, AppIcons.cameraOutlined
AppIcons.photo, AppIcons.photoOutlined
AppIcons.video
AppIcons.play, AppIcons.playCircle
AppIcons.pause
AppIcons.stop

// Status
AppIcons.success, AppIcons.check
AppIcons.error, AppIcons.errorOutlined
AppIcons.warning, AppIcons.warningOutlined
AppIcons.info, AppIcons.infoOutlined
AppIcons.help
AppIcons.online, AppIcons.offline

// Location
AppIcons.location, AppIcons.locationOutlined
AppIcons.map
AppIcons.directions
AppIcons.pin

// Billiards specific
AppIcons.ball, AppIcons.cue, AppIcons.billiardTable
```

---

## 🎨 DesignTokens Mapping

### Spacing

```dart
// ❌ KHÔNG CÓ
DesignTokens.space2   // undefined
DesignTokens.space6   // undefined
DesignTokens.space10  // undefined
DesignTokens.space100 // undefined

// ✅ CÓ SẴN
DesignTokens.space4
DesignTokens.space8
DesignTokens.space12
DesignTokens.space16
DesignTokens.space20
DesignTokens.space24
DesignTokens.space32
DesignTokens.space48
DesignTokens.space64

// ✅ DÙNG THAY THẾ
DesignTokens.space4   // thay cho space2, space6
DesignTokens.space8   // thay cho space10
DesignTokens.space64  // thay cho space100
```

### Border Radius

```dart
// ❌ KHÔNG CÓ
DesignTokens.radius10 // undefined
DesignTokens.radius12 // undefined

// ✅ CÓ SẴN
DesignTokens.radiusXS  // 2px
DesignTokens.radiusSM  // 4px
DesignTokens.radiusMD  // 8px
DesignTokens.radiusLG  // 12px
DesignTokens.radiusXL  // 16px
DesignTokens.radiusXXL // 24px
DesignTokens.radiusFull // 9999px (circular)

// ✅ DÙNG THAY THẾ
DesignTokens.radiusMD  // thay cho radius10
DesignTokens.radiusLG  // thay cho radius12
```

### Animation Curves

```dart
// ❌ SAI TÊN CLASS
AppCurves.emphasized  // Undefined class 'AppCurves'

// ✅ ĐÚNG TÊN
AppAnimations.emphasized  // from design_system
Curves.easeOutCubic       // or use Flutter's built-in
```

---

## 🧩 Components API Reference

### 1. DSCard

```dart
// ✅ ĐÚNG - Có sẵn 3 variants
DSCard.elevated(
  child: Widget,
  padding: EdgeInsets.all(DesignTokens.space16),
  onTap: () {},
)

DSCard.outlined(
  child: Widget,
  padding: EdgeInsets.all(DesignTokens.space16),
  onTap: () {},
)

DSCard.filled(
  child: Widget,
  padding: EdgeInsets.all(DesignTokens.space16),
)
```

### 2. DSButton

```dart
// ✅ ĐÚNG - Có 4 variants
DSButton.primary(
  text: 'Click',
  onPressed: () {},
  icon: AppIcons.add,
  size: DSButtonSize.small, // small, medium, large
  isFullWidth: false,
  isLoading: false,
)

DSButton.secondary(...)
DSButton.outlined(...)

// ❌ SAI - Không có variant này
DSButton.tonal(...)  // Undefined method

// ✅ DÙNG THAY THẾ
DSButton.outlined(...)  // hoặc DSButton.secondary(...)
```

### 3. DSAvatar

```dart
// ✅ ĐÚNG
DSAvatar(
  size: DSAvatarSize.xl,  // xs, sm, md, lg, xl, xxl (NO xxl!)
  imageUrl: club.logoUrl,
  borderColor: AppColors.white,
  // NO borderWidth parameter!
  // NO fallbackIcon parameter!
)

// ❌ SAI - Parameters không tồn tại
DSAvatar(
  size: DSAvatarSize.xxl,     // No 'xxl' constant
  borderWidth: 3,             // No 'borderWidth' parameter
  fallbackIcon: AppIcons.xxx, // No 'fallbackIcon' parameter
)

// ✅ DÙNG THAY THẾ - Wrap trong Container
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: AppColors.white,
      width: 3,
    ),
  ),
  child: DSAvatar(
    size: DSAvatarSize.xxl,  // or use xl
    imageUrl: club.logoUrl,
  ),
)
```

### 4. DSBadge

```dart
// ✅ ĐÚNG - 3 variants
DSBadge.dot(
  color: DSBadgeColor.error,  // primary, error, success, warning, info, neutral
  // NO pulsate parameter!
)

DSBadge.count(
  count: 5,
  color: DSBadgeColor.error,
)

DSBadge.text(
  text: 'New',
  color: DSBadgeColor.success,
)

// ❌ SAI
DSBadge.dot(
  pulsate: true,  // No 'pulsate' parameter
)

// ✅ ALTERNATIVE - Nếu cần animation
// Tự tạo pulsating animation wrapper
```

### 5. DSChip

```dart
// ✅ ĐÚNG - 3 variants + factories
DSChip.filled(
  label: 'Tag',
  onTap: () {},
)

DSChip.outlined(
  label: 'Tag',
  onTap: () {},
  onDeleted: () {},  // Shows delete icon
)

DSChip.tonal(
  label: 'Tag',
)

// Factory methods
DSChip.filter(
  label: 'All',
  onTap: () {},
  // NO icon parameter!
  // NO selected parameter!
  // NO onDeleted parameter for filter!
)

DSChip.choice(...)
DSChip.input(...)

// ❌ SAI - Parameters không tồn tại trong filter
DSChip.filter(
  icon: AppIcons.xxx,      // No 'icon' parameter
  selected: true,          // No 'selected' parameter
)

// ✅ DÙNG THAY THẾ - Dùng outlined/filled
DSChip.outlined(
  label: 'All',
  onTap: () {},
  // Can show selected state via conditional rendering
)
```

### 6. DSEmptyState

```dart
// ✅ ĐÚNG
DSEmptyState(
  icon: AppIcons.inbox,
  title: 'No Data',
  // NO message parameter!
  action: DSButton.primary(
    text: 'Add',
    onPressed: () {},
  ),
)

// ❌ SAI
DSEmptyState(
  message: 'Description',  // No 'message' parameter
)

// ✅ DÙNG THAY THẾ - Use subtitle
DSEmptyState(
  icon: AppIcons.inbox,
  title: 'No Data',
  subtitle: 'Description text here',  // Use this instead
)
```

### 7. DSSnackbar

```dart
// ✅ ĐÚNG - Static methods
DSSnackbar.success(
  context: context,
  message: 'Success!',
  actionLabel: 'Undo',
  onAction: () {},
)

DSSnackbar.error(
  context: context,
  message: 'Error occurred',
)

DSSnackbar.info(...)
DSSnackbar.warning(...)

// ❌ SAI - Dùng ScaffoldMessenger
ScaffoldMessenger.of(context).showSnackBar(...)

// ✅ LUÔN DÙNG DSSnackbar
```

### 8. DSLoading

```dart
// ❌ TÊN CLASS SAI
DSLoading.spinner(...)   // Undefined name 'DSLoading'
DSLoading.skeleton()     // Undefined

// ✅ TÊN ĐÚNG - Kiểm tra trong design_system
// Có thể là:
- DSLoadingSpinner(...)
- DSLoadingSkeleton(...)
// Hoặc components khác, cần check lại

// ✅ FALLBACK - Dùng built-in widgets
CircularProgressIndicator(
  color: AppColors.primary,
)

// For skeleton
ShimmerLoading.rectangle(...)  // Nếu có từ common_widgets
```

---

## 🎯 Refactor Plan - Step by Step

### Step 1: Fix Imports & Constants

```dart
// ❌ TRƯỚC
import 'package:sabo_arena/core/design_system.dart' as ds;

// Icon sai
icon: ds.AppIcons.speed
spacing: ds.DesignTokens.space6
curve: AppCurves.emphasized

// ✅ SAU
import 'package:sabo_arena/core/design_system/design_system.dart';

// Icons đúng
icon: AppIcons.dashboard
icon: Icons.speed  // hoặc dùng trực tiếp Flutter icon
spacing: DesignTokens.space8
curve: AppAnimations.emphasized  // hoặc Curves.easeOutCubic
```

### Step 2: Stats Cards với DSCard

**❌ Code hiện tại:**
```dart
Widget _buildEnhancedStatCard({
  required String label,
  required String value,
  required IconData icon,
  required Color color,
  required int index,
}) {
  return Column(
    children: [
      Icon(icon, color: color, size: 28),
      SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 24, ...)),
      Text(label, style: TextStyle(fontSize: 12, ...)),
    ],
  );
}
```

**✅ Refactor với Design System:**
```dart
Widget _buildStatCard({
  required String label,
  required String value,
  required IconData icon,
  required Color color,
  required int index,
}) {
  return TweenAnimationBuilder<double>(
    duration: Duration(milliseconds: 300 + (index * 80)),
    curve: AppAnimations.emphasized,  // ✅ Đúng class name
    tween: Tween(begin: 0.0, end: _showStatsAnimation ? 1.0 : 0.0),
    builder: (context, animValue, child) {
      return Transform.translate(
        offset: Offset(0, 15 * (1 - animValue)),
        child: Opacity(
          opacity: animValue,
          child: DSCard.elevated(
            padding: EdgeInsets.all(DesignTokens.space16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: AppIcons.sizeLG,  // ✅ Dùng size constants
                ),
                SizedBox(height: DesignTokens.space8),
                Text(
                  value,
                  style: AppTypography.headingLarge.withColor(
                    AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DesignTokens.space4),
                Text(
                  label,
                  style: AppTypography.labelSmall.withColor(
                    AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Usage
_buildStatCard(
  label: 'Members',
  value: '${_dashboardStats?.activeMembers ?? 0}',
  icon: AppIcons.following,  // ✅ Thay people
  color: AppColors.info,
  index: 0,
)
```

### Step 3: Quick Actions với DSCard

**❌ Code hiện tại:**
```dart
QuickActionButton(
  label: 'Thành viên',
  icon: Icons.people_outline,
  color: ds.AppColors.categoryManagement,
  onTap: _navigateToMemberManagement,
)
```

**✅ Refactor:**
```dart
Widget _buildQuickActionCard(_QuickAction action) {
  return DSCard.outlined(
    onTap: action.onTap,
    child: Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action.icon,
                color: action.color,
                size: AppIcons.sizeLG,
              ),
              SizedBox(height: DesignTokens.space8),
              Text(
                action.label,
                style: AppTypography.labelMedium.withColor(
                  AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (action.badge != null)
          Positioned(
            top: DesignTokens.space8,
            right: DesignTokens.space8,
            child: DSBadge.count(
              count: int.tryParse(action.badge!) ?? 0,
              color: DSBadgeColor.error,
            ),
          ),
      ],
    ),
  );
}

// Data class
class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });
}

// Usage
final actions = [
  _QuickAction(
    label: 'Thành viên',
    icon: AppIcons.following,  // ✅ Thay people
    color: AppColors.info,
    onTap: _navigateToMemberManagement,
  ),
  _QuickAction(
    label: 'Giải đấu',
    icon: AppIcons.trophy,
    color: AppColors.warning,
    onTap: _navigateToTournamentCreate,
  ),
  // ... more actions
];
```

### Step 4: Club Header với DSAvatar

**❌ Code hiện tại:**
```dart
CircleAvatar(
  radius: 35,
  backgroundImage: _club?.logoUrl != null 
      ? NetworkImage(_club!.logoUrl!) 
      : null,
  child: _club?.logoUrl == null 
      ? Icon(Icons.sports_tennis, size: 35)
      : null,
)
```

**✅ Refactor:**
```dart
// Wrap để có border
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: AppColors.white,
      width: 3,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withOpacity(0.3),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: DSAvatar(
    size: DSAvatarSize.xl,  // ✅ Không có xxl
    imageUrl: _club?.logoUrl,
    // No fallbackIcon parameter - avatar tự show initials/placeholder
  ),
)
```

### Step 5: Activity Items với DSCard

**❌ Code hiện tại:**
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [...],
  ),
  child: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(...),
        child: Icon(...),
      ),
      // ... content
    ],
  ),
)
```

**✅ Refactor:**
```dart
DSCard.outlined(
  padding: EdgeInsets.all(DesignTokens.space16),
  child: Row(
    children: [
      Container(
        padding: EdgeInsets.all(DesignTokens.space8),
        decoration: BoxDecoration(
          color: _getActivityColor(activity.type).withOpacity(0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        child: Icon(
          _getActivityIcon(activity.type),
          color: _getActivityColor(activity.type),
          size: AppIcons.sizeMD,
        ),
      ),
      SizedBox(width: DesignTokens.space12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity.title,
              style: AppTypography.bodyMedium.withWeight(
                FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: DesignTokens.space4),
            Text(
              activity.subtitle,
              style: AppTypography.bodySmall.withColor(
                AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
      SizedBox(width: DesignTokens.space8),
      Text(
        _formatTimeAgo(activity.timestamp),
        style: AppTypography.captionMedium.withColor(
          AppColors.textTertiary,
        ),
      ),
    ],
  ),
)
```

### Step 6: Activity Filters với DSChip

**❌ Code hiện tại:**
```dart
FilterChip(
  label: Row(
    children: [
      Icon(icon, size: 16, ...),
      Text(label),
    ],
  ),
  selected: isSelected,
  onSelected: (selected) {...},
)
```

**✅ Refactor:**
```dart
// Option 1: Dùng outlined và handle selected state
Widget _buildFilterChip(String label, String value, IconData icon) {
  final isSelected = _selectedActivityFilter == value;
  
  return GestureDetector(
    onTap: () => setState(() => _selectedActivityFilter = value),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppIcons.sizeSM,
            color: isSelected ? AppColors.white : AppColors.primary,
          ),
          SizedBox(width: DesignTokens.space4),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? AppColors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// Option 2: Dùng DSChip.outlined (simpler)
Row(
  children: [
    DSChip.outlined(
      label: 'Tất cả',
      onTap: () => setState(() => _selectedActivityFilter = 'all'),
    ),
    SizedBox(width: DesignTokens.space8),
    DSChip.outlined(
      label: 'Giải đấu',
      onTap: () => setState(() => _selectedActivityFilter = 'tournament'),
    ),
    // ... more chips
  ],
)
```

### Step 7: Snackbars với DSSnackbar

**❌ Code hiện tại:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error occurred'),
    backgroundColor: Colors.red,
  ),
);
```

**✅ Refactor:**
```dart
// Success
DSSnackbar.success(
  context: context,
  message: 'Cập nhật logo thành công!',
);

// Error
DSSnackbar.error(
  context: context,
  message: 'Lỗi: ${e.toString()}',
  actionLabel: 'Thử lại',
  onAction: _editClubLogo,
);

// Info
DSSnackbar.info(
  context: context,
  message: 'Đang xuất báo cáo...',
);

// Warning
DSSnackbar.warning(
  context: context,
  message: 'Thành viên thường không có quyền tạo giải đấu',
);
```

### Step 8: Empty State với DSEmptyState

**❌ Code hiện tại:**
```dart
Container(
  padding: const EdgeInsets.all(32),
  child: Column(
    children: [
      Icon(Icons.timeline_outlined, size: 48, ...),
      SizedBox(height: 12),
      Text('Chưa có hoạt động', ...),
      Text('Các hoạt động của club sẽ hiển thị ở đây', ...),
    ],
  ),
)
```

**✅ Refactor:**
```dart
DSEmptyState(
  icon: AppIcons.event,  // ✅ Thay timeline
  title: _recentActivities.isEmpty 
      ? 'Chưa có hoạt động' 
      : 'Không tìm thấy hoạt động',
  subtitle: 'Các hoạt động của club sẽ hiển thị ở đây',
)
```

### Step 9: Loading States

**❌ Code hiện tại:**
```dart
body: const DashboardSkeleton(),

// Or
showDialog(
  context: context,
  builder: (context) => Center(
    child: CircularProgressIndicator(),
  ),
);
```

**✅ Refactor:**
```dart
// Check tên class chính xác trong design_system
// Có thể là một trong các tên sau:

// Option 1
body: DSLoadingSkeleton(),  // Nếu có component này

// Option 2 - Dùng common widget hiện có
body: ShimmerLoading.dashboardSkeleton(),

// Option 3 - Custom với DSCard
body: Padding(
  padding: context.responsiveScreenPadding,
  child: Column(
    children: [
      // Skeleton stats
      Row(
        children: List.generate(4, (index) =>
          Expanded(
            child: DSCard.elevated(
              padding: EdgeInsets.all(DesignTokens.space16),
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMD,
                      ),
                    ),
                  ),
                  SizedBox(height: DesignTokens.space8),
                  Container(
                    width: 40,
                    height: 24,
                    color: AppColors.gray300,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // ... more skeleton items
    ],
  ),
);

// For dialog loading
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => Center(
    child: DSCard.elevated(
      padding: EdgeInsets.all(DesignTokens.space20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
          ),
          SizedBox(height: DesignTokens.space16),
          Text(
            'Đang tải ảnh lên...',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    ),
  ),
);
```

### Step 10: Responsive Layout với Breakpoints

**❌ Code hiện tại:**
```dart
// Không có responsive
Widget _buildStats() {
  return Row(
    children: [
      // Always 4 columns
    ],
  );
}
```

**✅ Refactor:**
```dart
Widget _buildStatsSection() {
  if (context.isMobile) {
    return _buildMobileStats();
  } else {
    return _buildDesktopStats();
  }
}

Widget _buildMobileStats() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(child: _buildStatCard(..., index: 0)),
          SizedBox(width: DesignTokens.space12),
          Expanded(child: _buildStatCard(..., index: 1)),
        ],
      ),
      SizedBox(height: DesignTokens.space12),
      Row(
        children: [
          Expanded(child: _buildStatCard(..., index: 2)),
          SizedBox(width: DesignTokens.space12),
          Expanded(child: _buildStatCard(..., index: 3)),
        ],
      ),
    ],
  );
}

Widget _buildDesktopStats() {
  return Row(
    children: [
      Expanded(child: _buildStatCard(..., index: 0)),
      SizedBox(width: DesignTokens.space12),
      Expanded(child: _buildStatCard(..., index: 1)),
      SizedBox(width: DesignTokens.space12),
      Expanded(child: _buildStatCard(..., index: 2)),
      SizedBox(width: DesignTokens.space12),
      Expanded(child: _buildStatCard(..., index: 3)),
    ],
  );
}

// Use responsive padding
Padding(
  padding: context.responsiveScreenPadding,  // Auto adapts to screen size
  child: Column(...),
)

// Adjust header height
Container(
  height: context.isMobile ? 180 : 220,
  child: Stack(...),
)
```

---

## 📊 Expected Results

### Before Refactor
- **Lines of code:** 1743 lines
- **Hardcoded values:** ~50+ hardcoded colors, spacings, sizes
- **Custom widgets:** AnimatedStatsCard, QuickActionCard, custom containers
- **Consistency:** Low (different styles in different parts)
- **Maintenance:** Hard (need to update multiple places)

### After Refactor
- **Lines of code:** ~1200 lines (30% reduction)
- **Hardcoded values:** 0 (all using design tokens)
- **Custom widgets:** Replaced with DS components
- **Consistency:** High (same components everywhere)
- **Maintenance:** Easy (update design system, all screens update)

### Benefits
✅ Consistent UI/UX across entire app  
✅ Easier to maintain and update  
✅ Less code duplication  
✅ Better performance (optimized components)  
✅ Type-safe with proper APIs  
✅ Responsive out of the box  
✅ Dark mode ready  
✅ Accessibility support  

---

## 🚀 Next Steps

1. **Start small** - Refactor one section at a time
2. **Test frequently** - Test after each section refactor
3. **Compare visually** - Ensure UI looks the same or better
4. **Check performance** - Ensure animations are smooth
5. **Test responsive** - Check on different screen sizes
6. **Document changes** - Note any issues or improvements

---

## 💡 Tips

1. **Use hot reload** - Flutter hot reload to see changes instantly
2. **Keep backup** - Keep original file as reference
3. **Console logs** - Use debugPrint to debug issues
4. **Error messages** - Read error messages carefully
5. **Design system docs** - Refer to design system README

---

**Created:** October 14, 2025  
**Version:** 1.0  
**Status:** Ready for implementation

Chúc bạn refactor thành công! 🎉
