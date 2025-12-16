# 🎨 DESIGN SYSTEM QUICK REFERENCE

Tài liệu tham khảo nhanh cho tất cả components và patterns trong Design System.

---

## 📦 Import Statement

```dart
// ✅ Single import cho tất cả
import 'package:sabo_arena/core/design_system/design_system.dart';

// Bây giờ bạn có thể dùng:
// - AppColors.*
// - AppTypography.*
// - AppIcons.*
// - DesignTokens.*
// - AppAnimations.*
// - Breakpoints.*
// - DSButton.*
// - DSCard.*
// - DSTextField.*
// - DSAvatar.*
// - DSBadge.*
// - DSChip.*
// - DSTabs.*
// - DSSwitch.*
// - DSCheckbox.*
// - DSRadio.*
// - DSSnackbar.*
// - DSEmptyState.*
// - v.v.
```

---

## 🎨 Colors

```dart
// Primary Colors
AppColors.primary          // Main brand color
AppColors.primaryDark      // Darker shade
AppColors.primaryLight     // Lighter shade

// Secondary Colors
AppColors.secondary
AppColors.secondaryDark
AppColors.secondaryLight

// Semantic Colors
AppColors.success          // Green - success states
AppColors.error            // Red - error states
AppColors.warning          // Orange/Yellow - warning states
AppColors.info             // Blue - info states

// Text Colors
AppColors.textPrimary      // Main text (black/dark)
AppColors.textSecondary    // Secondary text (gray)
AppColors.textTertiary     // Tertiary text (light gray)
AppColors.textDisabled     // Disabled text

// Background Colors
AppColors.backgroundGray   // Light gray background
AppColors.white            // White
AppColors.black            // Black

// Gray Scale
AppColors.gray50
AppColors.gray100
AppColors.gray200
AppColors.gray300
AppColors.gray400
AppColors.gray500
AppColors.gray600
AppColors.gray700
AppColors.gray800
AppColors.gray900

// UI Colors
AppColors.divider          // Divider lines
AppColors.border           // Border lines
AppColors.overlay          // Semi-transparent overlays
```

---

## 📝 Typography

```dart
// Display Styles (48px - 32px) - Largest text
AppTypography.displayLarge      // 48px, bold
AppTypography.displayMedium     // 40px, bold
AppTypography.displaySmall      // 32px, bold

// Heading Styles (28px - 18px) - Section headers
AppTypography.headingXL         // 28px, semibold
AppTypography.headingLarge      // 24px, semibold
AppTypography.headingMedium     // 20px, semibold
AppTypography.headingSmall      // 18px, semibold

// Body Styles (17px - 13px) - Main content
AppTypography.bodyLarge         // 17px, regular
AppTypography.bodyLargeBold     // 17px, bold
AppTypography.bodyMedium        // 15px, regular
AppTypography.bodyMediumBold    // 15px, bold
AppTypography.bodySmall         // 13px, regular
AppTypography.bodySmallBold     // 13px, bold

// Label Styles (16px - 11px) - Form labels, buttons
AppTypography.labelLarge        // 16px, medium
AppTypography.labelMedium       // 14px, medium
AppTypography.labelSmall        // 12px, medium
AppTypography.labelTiny         // 11px, medium

// Caption Styles (13px - 10px) - Small text, metadata
AppTypography.captionLarge      // 13px, regular
AppTypography.captionMedium     // 12px, regular
AppTypography.captionSmall      // 11px, regular
AppTypography.captionTiny       // 10px, regular

// Helper Methods
AppTypography.bodyMedium.withColor(AppColors.primary)
AppTypography.bodyMedium.withWeight(FontWeight.w600)
AppTypography.bodyMedium.primary()      // Primary color
AppTypography.bodyMedium.secondary()    // Secondary color
```

---

## 🔲 Icons

### Size Constants
```dart
AppIcons.sizeXS        // 12px
AppIcons.sizeSM        // 16px
AppIcons.sizeMD        // 20px
AppIcons.sizeLG        // 24px (default)
AppIcons.sizeXL        // 32px
AppIcons.sizeXXL       // 40px
AppIcons.sizeHuge      // 48px
AppIcons.sizeMassive   // 64px
```

### Common Icons
```dart
// Navigation
AppIcons.home, AppIcons.homeOutlined
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
AppIcons.share, AppIcons.send
AppIcons.download, AppIcons.upload
AppIcons.refresh
AppIcons.filter, AppIcons.sort

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

// Status
AppIcons.success, AppIcons.check
AppIcons.error, AppIcons.errorOutlined
AppIcons.warning, AppIcons.warningOutlined
AppIcons.info, AppIcons.infoOutlined
AppIcons.help

// Content
AppIcons.camera, AppIcons.photo
AppIcons.video
AppIcons.play, AppIcons.pause, AppIcons.stop

// Billiards
AppIcons.ball
AppIcons.cue
AppIcons.billiardTable
```

---

## 📏 Design Tokens

### Spacing
```dart
DesignTokens.space4        // 4px
DesignTokens.space8        // 8px
DesignTokens.space12       // 12px
DesignTokens.space16       // 16px
DesignTokens.space20       // 20px
DesignTokens.space24       // 24px
DesignTokens.space32       // 32px
DesignTokens.space48       // 48px
DesignTokens.space64       // 64px
```

### Border Radius
```dart
DesignTokens.radiusXS      // 2px
DesignTokens.radiusSM      // 4px
DesignTokens.radiusMD      // 8px
DesignTokens.radiusLG      // 12px
DesignTokens.radiusXL      // 16px
DesignTokens.radiusXXL     // 24px
DesignTokens.radiusFull    // 9999px (circular)
```

### Opacity
```dart
DesignTokens.opacityDisabled   // 0.38
DesignTokens.opacityLight      // 0.12
DesignTokens.opacityMedium     // 0.24
DesignTokens.opacityHeavy      // 0.48
```

---

## ⏱️ Animations

### Duration
```dart
AppAnimations.durationFast     // 150ms
AppAnimations.durationNormal   // 300ms
AppAnimations.durationSlow     // 500ms
```

### Curves
```dart
AppAnimations.emphasized       // Emphasized ease curve
AppAnimations.standard         // Standard ease curve
```

### Transitions
```dart
AppAnimations.fadeIn(child: Widget)
AppAnimations.fadeOut(child: Widget)
AppAnimations.scaleIn(child: Widget)
AppAnimations.slideInFromBottom(child: Widget)
AppAnimations.slideInFromRight(child: Widget)
```

---

## 📱 Responsive

### Breakpoints
```dart
Breakpoints.mobile      // 600px
Breakpoints.tablet      // 840px
Breakpoints.desktop     // 1200px
Breakpoints.wide        // 1440px
Breakpoints.extraWide   // 1920px
```

### Context Extensions
```dart
context.isMobile        // < 600px
context.isTablet        // 600px - 840px
context.isDesktop       // >= 840px
context.isWide          // >= 1200px

context.screenWidth
context.screenHeight

// Responsive values
context.value<T>(
  mobile: value1,
  tablet: value2,
  desktop: value3,
)

// Responsive padding
context.responsiveScreenPadding  // Auto horizontal padding
context.getHorizontalPadding()   // Get padding value
```

---

## 🧩 Components

### DSButton

```dart
// 4 variants
DSButton.primary(
  text: 'Save',
  onPressed: () {},
  icon: AppIcons.save,               // Optional
  size: DSButtonSize.medium,         // small, medium, large
  isFullWidth: false,
  isLoading: false,
  isDisabled: false,
)

DSButton.secondary(text: 'Cancel', onPressed: () {})
DSButton.outlined(text: 'More', onPressed: () {})
DSButton.text(text: 'Skip', onPressed: () {})
```

### DSCard

```dart
// 3 variants
DSCard.elevated(
  child: Widget,
  padding: EdgeInsets.all(DesignTokens.space16),
  onTap: () {},  // Optional - makes card tappable
)

DSCard.outlined(
  child: Widget,
  padding: EdgeInsets.all(DesignTokens.space16),
)

DSCard.filled(
  child: Widget,
  fillColor: AppColors.primary.withOpacity(0.1),
)
```

### DSTextField

```dart
DSTextField(
  label: 'Email',
  hintText: 'Enter your email',
  controller: _controller,
  prefixIcon: AppIcons.email,
  suffixIcon: AppIcons.close,
  keyboardType: TextInputType.emailAddress,
  obscureText: false,
  maxLines: 1,
  enabled: true,
  onChanged: (value) {},
  validator: (value) {
    if (value?.isEmpty ?? true) {
      return 'Email is required';
    }
    return null;
  },
)
```

### DSAvatar

```dart
DSAvatar(
  size: DSAvatarSize.md,  // xs, sm, md, lg, xl, xxl
  imageUrl: user.photoUrl,
  name: user.name,         // For initials fallback
  borderColor: AppColors.white,
)
```

### DSBadge

```dart
// 3 variants
DSBadge.dot(
  color: DSBadgeColor.error,  // primary, error, success, warning, info, neutral
  child: Icon(AppIcons.notifications),
  position: DSBadgePosition.topRight,  // topRight, topLeft, bottomRight, bottomLeft
)

DSBadge.count(
  count: 5,
  color: DSBadgeColor.error,
  child: Icon(AppIcons.message),
)

DSBadge.text(
  text: 'New',
  color: DSBadgeColor.success,
  child: Widget,
)
```

### DSChip

```dart
// 3 base variants
DSChip.filled(
  label: 'Active',
  size: DSChipSize.medium,  // small, medium, large
  icon: AppIcons.check,
  onTap: () {},
)

DSChip.outlined(
  label: 'Tag',
  onTap: () {},
  onDeleted: () {},  // Shows delete icon
)

DSChip.tonal(
  label: 'Category',
)

// Factory methods
DSChip.filter(label: 'All', onTap: () {})
DSChip.choice(label: 'Option', onTap: () {})
DSChip.input(label: 'New', onDeleted: () {})
```

### DSTabs

```dart
final tabs = [
  DSTabItem(label: 'Home', icon: AppIcons.home),
  DSTabItem(label: 'Search', icon: AppIcons.search, badgeCount: 5),
  DSTabItem(label: 'Profile', icon: AppIcons.profile),
];

DSTabs(
  tabs: tabs.map((t) => t.label).toList(),
  icons: tabs.map((t) => t.icon).toList(),
  currentIndex: _currentIndex,
  onTabChanged: (index) {
    setState(() => _currentIndex = index);
  },
  isScrollable: false,
)
```

### DSSwitch

```dart
DSSwitch(
  value: _isEnabled,
  onChanged: (value) {
    setState(() => _isEnabled = value);
  },
)

// With label
DSSwitchTile(
  title: 'Enable notifications',
  subtitle: 'Receive push notifications',
  value: _isEnabled,
  onChanged: (value) {},
)
```

### DSCheckbox

```dart
DSCheckbox(
  value: _isChecked,
  onChanged: (value) {
    setState(() => _isChecked = value ?? false);
  },
  tristate: false,  // Allow null state
)

// With label
DSCheckboxTile(
  title: 'Accept terms',
  subtitle: 'I agree to the terms and conditions',
  value: _isChecked,
  onChanged: (value) {},
)

// Group
DSCheckboxGroup(
  options: ['Option 1', 'Option 2', 'Option 3'],
  selectedValues: _selectedOptions,
  onChanged: (selected) {
    setState(() => _selectedOptions = selected);
  },
)
```

### DSRadio

```dart
DSRadio<String>(
  value: 'option1',
  groupValue: _selectedOption,
  onChanged: (value) {
    setState(() => _selectedOption = value);
  },
)

// With label
DSRadioTile<String>(
  value: 'option1',
  groupValue: _selectedOption,
  title: 'Option 1',
  subtitle: 'Description',
  onChanged: (value) {},
)

// Group
DSRadioGroup<String>(
  options: [
    DSRadioOption(value: 'a', label: 'Option A'),
    DSRadioOption(value: 'b', label: 'Option B'),
  ],
  groupValue: _selectedOption,
  onChanged: (value) {
    setState(() => _selectedOption = value);
  },
)
```

### DSSnackbar

```dart
// 4 types - static methods
DSSnackbar.success(
  context: context,
  message: 'Operation successful!',
  actionLabel: 'Undo',
  onAction: () {},
)

DSSnackbar.error(
  context: context,
  message: 'An error occurred',
)

DSSnackbar.info(
  context: context,
  message: 'Information message',
)

DSSnackbar.warning(
  context: context,
  message: 'Warning message',
)
```

### DSEmptyState

```dart
DSEmptyState(
  icon: AppIcons.inbox,
  title: 'No data yet',
  subtitle: 'Start by adding your first item',
  action: DSButton.primary(
    text: 'Add Item',
    onPressed: () {},
  ),
)
```

---

## 🎯 Common Patterns

### Card with Stats
```dart
DSCard.elevated(
  padding: EdgeInsets.all(DesignTokens.space16),
  child: Column(
    children: [
      Icon(AppIcons.trophy, size: AppIcons.sizeLG, color: AppColors.warning),
      SizedBox(height: DesignTokens.space8),
      Text('42', style: AppTypography.headingLarge),
      SizedBox(height: DesignTokens.space4),
      Text('Tournaments', style: AppTypography.labelSmall.withColor(AppColors.textSecondary)),
    ],
  ),
)
```

### Action Button with Badge
```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    IconButton(
      icon: Icon(AppIcons.notifications),
      onPressed: () {},
    ),
    Positioned(
      right: 4,
      top: 4,
      child: DSBadge.count(
        count: 5,
        color: DSBadgeColor.error,
      ),
    ),
  ],
)
```

### List Item with Avatar
```dart
DSCard.outlined(
  padding: EdgeInsets.all(DesignTokens.space12),
  onTap: () {},
  child: Row(
    children: [
      DSAvatar(
        size: DSAvatarSize.md,
        imageUrl: user.photoUrl,
        name: user.name,
      ),
      SizedBox(width: DesignTokens.space12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: AppTypography.bodyMedium),
            SizedBox(height: DesignTokens.space4),
            Text(user.role, style: AppTypography.bodySmall.withColor(AppColors.textSecondary)),
          ],
        ),
      ),
      Icon(AppIcons.forward, size: AppIcons.sizeSM, color: AppColors.textTertiary),
    ],
  ),
)
```

### Filter Bar
```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      DSChip.outlined(label: 'All', onTap: () {}),
      SizedBox(width: DesignTokens.space8),
      DSChip.outlined(label: 'Active', onTap: () {}),
      SizedBox(width: DesignTokens.space8),
      DSChip.outlined(label: 'Completed', onTap: () {}),
    ],
  ),
)
```

### Form Section
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Account Information', style: AppTypography.headingSmall),
    SizedBox(height: DesignTokens.space16),
    DSTextField(
      label: 'Email',
      controller: _emailController,
      prefixIcon: AppIcons.email,
    ),
    SizedBox(height: DesignTokens.space12),
    DSTextField(
      label: 'Password',
      controller: _passwordController,
      prefixIcon: AppIcons.lock,
      obscureText: true,
    ),
    SizedBox(height: DesignTokens.space16),
    DSButton.primary(
      text: 'Save',
      isFullWidth: true,
      onPressed: () {},
    ),
  ],
)
```

### Responsive Grid
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: context.isMobile ? 2 : context.isTablet ? 3 : 4,
    crossAxisSpacing: DesignTokens.space12,
    mainAxisSpacing: DesignTokens.space12,
  ),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return DSCard.outlined(
      onTap: () {},
      child: Center(child: Text(items[index])),
    );
  },
)
```

---

## 📚 Resources

- **Full Documentation:** `lib/core/design_system/README.md`
- **Foundation Guide:** `lib/core/design_system/FOUNDATION_COMPLETE.md`
- **Components Guide:** `lib/core/design_system/MISSING_COMPONENTS_COMPLETE.md`
- **Live Examples:** `lib/core/design_system/examples/design_system_example_page.dart`
- **Changelog:** `lib/core/design_system/CHANGELOG.md`

---

**Quick Tip:** Always import from `design_system.dart` for single import convenience!

```dart
import 'package:sabo_arena/core/design_system/design_system.dart';
```

**Last Updated:** October 14, 2025  
**Version:** 2.0.0
