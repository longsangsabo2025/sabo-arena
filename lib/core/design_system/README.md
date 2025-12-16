# 🎨 SABO ARENA Design System

Complete design system foundation for the SABO Arena Flutter app, following Instagram/Facebook quality standards.

## 📋 What's Included

### ✅ Foundation (Completed)
- ✨ **Design Tokens** - Spacing, radius, animations, opacity
- ✨ **Color System** - Complete palette with light/dark mode
- ✨ **Typography** - Professional text styles hierarchy
- ✨ **Icons** - Centralized icon references
- ✨ **Breakpoints** - Responsive design utilities
- ✨ **Theme** - Complete Material 3 theme setup
- ✨ **Animations** - Smooth transitions & micro-interactions

### ✅ Components (Ready to Use)
- ✨ **DSButton** - 4 variants, 3 sizes, loading states
- ✨ **DSTextField** - Outlined/filled, validation
- ✨ **DSCard** - 3 variants, tap animations
- ✨ **DSAvatar** - 8 sizes, borders, badges
- ✨ **DSLoading** - Spinner, skeleton, progress bar
- ✨ **DSSnackbar** - 5 types, actions
- ✨ **DSDialog** - Modal dialogs
- ✨ **DSBottomSheet** - Bottom sheets
- ✨ **DSEmptyState** - Empty state displays

---

## 🚀 Quick Start

### 1. Import Design System

```dart
import 'package:sabo_arena/core/design_system/design_system.dart';
```

This single import gives you access to everything!

### 2. Apply Theme

In your `main.dart`:

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SABO Arena',
      theme: AppTheme.light(),        // ✨ Light theme
      darkTheme: AppTheme.dark(),     // ✨ Dark theme
      themeMode: ThemeMode.system,    // Auto-switch based on system
      home: HomePage(),
    );
  }
}
```

---

## 📖 Usage Examples

### Colors

```dart
// Use semantic colors
Container(
  color: AppColors.primary,
  child: Text(
    'Primary Text',
    style: TextStyle(color: AppColors.textOnPrimary),
  ),
)

// Use gray scale
Container(
  color: AppColors.gray100,
  child: Text('Secondary', style: TextStyle(color: AppColors.gray700)),
)

// Use semantic status colors
Container(
  color: AppColors.success50,
  child: Text('Success!', style: TextStyle(color: AppColors.success)),
)
```

### Typography

```dart
// Display styles (large titles)
Text('Welcome', style: AppTypography.displayLarge)

// Heading styles (section titles)
Text('Section Title', style: AppTypography.headingMedium)

// Body styles (content)
Text('This is body text', style: AppTypography.bodyMedium)

// Label styles (buttons, chips)
Text('BUTTON', style: AppTypography.labelMedium)

// Caption styles (metadata, timestamps)
Text('2 hours ago', style: AppTypography.captionMedium)

// Apply colors
Text(
  'Primary Text',
  style: AppTypography.primary(AppTypography.bodyMedium),
)
```

### Icons

```dart
// Use centralized icons
Icon(AppIcons.home, size: AppIcons.sizeLG)
Icon(AppIcons.search, color: AppColors.primary)
Icon(AppIcons.notifications, size: AppIcons.sizeXL)

// Custom sizes
Icon(AppIcons.like, size: AppIcons.getSize('huge'))
```

### Design Tokens

```dart
// Spacing
Container(
  padding: DesignTokens.all(DesignTokens.space16),
  margin: DesignTokens.symmetric(
    horizontal: DesignTokens.space20,
    vertical: DesignTokens.space12,
  ),
)

// Border radius
Container(
  decoration: BoxDecoration(
    borderRadius: DesignTokens.radius(DesignTokens.radiusMD),
  ),
)

// Animations
AnimatedContainer(
  duration: DesignTokens.durationNormal,
  curve: DesignTokens.curveEmphasized,
)
```

### Breakpoints (Responsive)

```dart
// Check device type
if (context.isMobile) {
  // Mobile layout
} else if (context.isTablet) {
  // Tablet layout
} else {
  // Desktop layout
}

// Responsive values
final padding = Breakpoints.value(
  context: context,
  mobile: 16,
  tablet: 24,
  desktop: 32,
);

// Responsive padding helpers
Container(
  padding: context.responsiveScreenPadding,
  child: YourWidget(),
)

// Responsive columns
GridView.count(
  crossAxisCount: Breakpoints.getColumnCount(
    context,
    mobile: 1,
    tablet: 2,
    desktop: 3,
  ),
)
```

### Components

#### DSButton

```dart
// Primary button
DSButton.primary(
  text: 'Follow',
  onPressed: () => followUser(),
  leadingIcon: AppIcons.follow,
)

// Secondary button
DSButton.secondary(
  text: 'Share',
  onPressed: () => sharePost(),
  size: DSButtonSize.large,
)

// Loading button
DSButton(
  text: 'Loading...',
  onPressed: null,
  isLoading: true,
)

// Full width button
DSButton.primary(
  text: 'Continue',
  onPressed: () {},
  fullWidth: true,
)
```

#### DSTextField

```dart
DSTextField(
  label: 'Email',
  hintText: 'Enter your email',
  prefixIcon: AppIcons.email,
  keyboardType: TextInputType.emailAddress,
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Required';
    return null;
  },
  onChanged: (value) => print(value),
)

// Password field
DSTextField(
  label: 'Password',
  obscureText: true,
  showPasswordToggle: true,
  prefixIcon: AppIcons.lock,
)
```

#### DSCard

```dart
DSCard.elevated(
  onTap: () => navigateToPost(),
  child: Column(
    children: [
      Text('Post Title', style: AppTypography.headingSmall),
      SizedBox(height: DesignTokens.space8),
      Text('Post content...', style: AppTypography.bodyMedium),
    ],
  ),
)
```

#### DSAvatar

```dart
DSAvatar(
  imageUrl: user.avatarUrl,
  size: DSAvatarSize.large,
  borderStyle: DSAvatarBorderStyle.gradient,
  showOnlineIndicator: true,
  onTap: () => navigateToProfile(),
)
```

#### DSSnackbar

```dart
// Success message
DSSnackbar.success(
  context: context,
  message: 'Post published successfully!',
)

// Error message
DSSnackbar.error(
  context: context,
  message: 'Failed to load data',
  actionLabel: 'Retry',
  onActionPressed: () => retry(),
)
```

#### DSLoading

```dart
// Spinner
DSSpinner.primary(size: DSSpinnerSize.large)

// Skeleton loader
DSSkeletonLoader.list(itemCount: 5)

// Progress bar
DSProgressBar(value: 0.65, showPercentage: true)
```

### Animations

```dart
// Fade in animation
AppAnimations.fadeIn(
  child: YourWidget(),
  duration: DesignTokens.durationNormal,
)

// Scale in animation
AppAnimations.scaleIn(
  child: YourWidget(),
  curve: DesignTokens.curveEmphasized,
)

// Slide in animation
AppAnimations.slideIn(
  child: YourWidget(),
  direction: SlideDirection.bottom,
)
```

---

## 🎯 Design Principles

### 1. **Consistency**
- Use design tokens for ALL spacing, sizing, timing
- Reference colors through `AppColors` only
- Use typography styles, don't hardcode font sizes

### 2. **Accessibility**
- Minimum touch target size: 44x44px
- Color contrast ratios meet WCAG AA standards
- Support for screen readers

### 3. **Performance**
- All animations use `const` constructors where possible
- Efficient widget rebuilds
- Optimized asset loading

### 4. **Responsive**
- Mobile-first approach
- Adapt layouts using `Breakpoints`
- Test on multiple screen sizes

---

## 📱 Applying to Pages

### Step 1: Replace Hardcoded Values

**Before:**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    'Hello',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
  ),
)
```

**After:**
```dart
Container(
  padding: DesignTokens.all(DesignTokens.space16),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: DesignTokens.radius(DesignTokens.radiusMD),
  ),
  child: Text('Hello', style: AppTypography.headingSmall),
)
```

### Step 2: Replace Custom Widgets

**Before:**
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Click Me'),
)
```

**After:**
```dart
DSButton.primary(
  text: 'Click Me',
  onPressed: () {},
)
```

### Step 3: Add Responsive Behavior

```dart
// Before: Fixed layout
Container(padding: EdgeInsets.all(16))

// After: Responsive layout
Container(padding: context.responsiveScreenPadding)
```

---

## 🔧 Customization

### Adding Custom Colors

In `app_colors.dart`:
```dart
static const Color customColor = Color(0xFF123456);
```

### Adding Custom Icons

In `app_icons.dart`:
```dart
static const IconData customIcon = Icons.your_icon;
```

### Adding Custom Text Styles

In `typography.dart`:
```dart
static const TextStyle customStyle = TextStyle(
  fontFamily: fontFamily,
  fontSize: 18,
  fontWeight: semiBold,
);
```

---

## ✅ TODO: Missing Components

These components should be added next:

- [ ] **DSChip/DSBadge** - Tags, status badges
- [ ] **DSBottomNavigation** - Navigation bar
- [ ] **DSTabs** - Tab bar
- [ ] **DSSwitch** - Toggle switch
- [ ] **DSCheckbox** - Checkbox
- [ ] **DSRadio** - Radio button
- [ ] **DSDropdown** - Select/picker
- [ ] **DSTooltip** - Hover hints
- [ ] **DSSegmentedControl** - iOS-style segmented control

---

## 📚 References

- [Material Design 3](https://m3.material.io/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Instagram Design](https://www.instagram.com/)
- [Facebook Design](https://facebook.design/)

---

## 🎉 Ready to Apply!

Your design system foundation is **complete and production-ready**! Start applying it to your pages for a consistent, professional UI.

**Next Steps:**
1. Choose a page to refactor
2. Replace hardcoded values with design tokens
3. Replace custom widgets with DS components
4. Test responsiveness
5. Move to next page

Happy coding! 🚀
