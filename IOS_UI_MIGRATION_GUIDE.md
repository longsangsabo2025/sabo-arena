# 🍎 iOS UI Migration Guide
## Quick Start Implementation Guide

---

## 🎯 QUICK WINS (Có thể làm ngay trong 1-2 giờ)

### 1. Keep Brand Color (✅ Đã đúng)

**File:** `lib/theme/app_theme.dart`

```dart
// ✅ GIỮ NGUYÊN brand color
static const Color primaryLight = Color(0xFF1E8A6F); // Teal green - Brand color

// ✅ Chỉ cần đảm bảo iOS-style usage patterns
// - Flat buttons với brand color
// - Subtle shadows
// - iOS typography & spacing
```

**Impact:** ✅ Giữ brand identity, nhưng với iOS-style UI patterns

---

### 2. Platform-Specific Font (10 phút)

**File:** `lib/theme/app_theme.dart`

```dart
// Helper method
static String _getFontFamily() {
  if (kIsWeb) return 'Roboto';
  if (Platform.isIOS) {
    return '.SF Pro Display'; // iOS system font
  }
  return 'Roboto'; // Android
}

// Update text theme
static TextTheme _buildTextTheme({required bool isLight}) {
  final fontFamily = _getFontFamily();
  
  return TextTheme(
    bodyLarge: TextStyle(
      fontFamily: fontFamily,  // ✅ Platform-specific
      fontSize: Platform.isIOS ? 17 : 16,  // ✅ iOS standard
      fontWeight: FontWeight.w400,
      letterSpacing: Platform.isIOS ? -0.3 : 0.15,  // ✅ iOS negative spacing
      height: Platform.isIOS ? 1.2 : 1.5,  // ✅ Tighter line height
    ),
    // ... other styles
  );
}
```

**Impact:** ✅ Typography sẽ native trên iOS

---

### 3. Update Button Border Radius (5 phút)

**File:** `lib/widgets/common/app_button.dart`

```dart
// BEFORE
shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(8),  // ❌ Android
),

// AFTER
shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(
    Platform.isIOS ? 12 : 8  // ✅ iOS: 12px, Android: 8px
  ),
),
```

**Impact:** ✅ Buttons sẽ có iOS-style rounded corners

---

### 4. Remove Button Elevation (10 phút)

**File:** `lib/widgets/common/app_button.dart`

```dart
// BEFORE
Widget _buildPrimaryButton(BuildContext context) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      elevation: 2,  // ❌ Material elevation
      // ...
    ),
  );
}

// AFTER
Widget _buildPrimaryButton(BuildContext context) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      elevation: Platform.isIOS ? 0 : 2,  // ✅ iOS: flat, Android: elevated
      // ...
    ),
  );
}
```

**Impact:** ✅ Buttons sẽ flat trên iOS (iOS-style)

---

## 🏗️ COMPONENT MIGRATION PATTERNS

### Pattern 1: iOS Button Widget

**File:** `lib/widgets/common/ios_button.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../core/design_system/design_system.dart';

class IOSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  
  const IOSButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      // Fallback to Material button on Android
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: Text(label),
      );
    }

    // iOS-style flat button với brand color
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF1E8A6F), // ✅ Brand teal green
        borderRadius: BorderRadius.circular(12),
        // ✅ No elevation, flat button (iOS style)
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,  // ✅ iOS letter spacing
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
```

**Usage:**
```dart
// Replace this:
ElevatedButton(
  onPressed: () {},
  child: Text('Submit'),
)

// With this:
IOSButton(
  label: 'Submit',
  onPressed: () {},
)
```

---

### Pattern 2: iOS Card Widget

**File:** `lib/widgets/common/ios_card.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../core/design_system/design_system.dart';

class IOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;

  const IOSCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      // Fallback to Material Card on Android
      return Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
    }

    // iOS-style card with subtle shadow
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),  // ✅ iOS: 16px
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),  // ✅ Subtle shadow
            blurRadius: 8,
            offset: const Offset(0, 2),
            // ✅ No spread radius (iOS style)
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

**Usage:**
```dart
// Replace this:
Card(
  child: Text('Content'),
)

// With this:
IOSCard(
  child: Text('Content'),
)
```

---

### Pattern 3: iOS Text Field

**File:** `lib/widgets/common/ios_text_field.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class IOSTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const IOSTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      // Fallback to Material TextField
      return TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    // iOS-style rounded text field
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),  // ✅ iOS gray background
        borderRadius: BorderRadius.circular(12),  // ✅ iOS: 12px
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 17,  // ✅ iOS standard
          fontWeight: FontWeight.w400,
          color: Color(0xFF1C1C1E),  // ✅ iOS text color
          letterSpacing: -0.3,  // ✅ iOS letter spacing
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF8E8E93),  // ✅ iOS placeholder color
            fontSize: 17,
          ),
          border: InputBorder.none,  // ✅ No border
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
```

**Usage:**
```dart
// Replace this:
TextFormField(
  decoration: InputDecoration(hintText: 'Email'),
)

// With this:
IOSTextField(
  hintText: 'Email',
  controller: emailController,
)
```

---

## 🔄 MIGRATION STRATEGY

### Step 1: Create iOS Components (Day 1)
1. Create `ios_button.dart`
2. Create `ios_card.dart`
3. Create `ios_text_field.dart`
4. Test trên iOS simulator

### Step 2: Replace Gradually (Day 2-5)
1. Start với screens quan trọng nhất:
   - Login screen ✅ (đã có)
   - Home feed
   - Profile screen
   - Settings screen

2. Replace từng component:
   ```dart
   // Find & Replace pattern:
   // Find: ElevatedButton
   // Replace: IOSButton (với Platform check)
   ```

### Step 3: Update Theme (Day 3)
1. Update `app_theme.dart` với iOS colors
2. Update typography với SF Pro
3. Update border radius values

### Step 4: Test & Refine (Day 4-5)
1. Test trên iOS devices (iPhone 12+, iPad)
2. Fix any visual bugs
3. Get user feedback

---

## 📝 CHECKLIST PER SCREEN

Khi migrate một screen, check:

- [ ] **Colors**
  - [x] ✅ Primary color: #1E8A6F (Brand teal green - GIỮ NGUYÊN)
  - [ ] Background: #FFFFFF hoặc #F2F2F7 (iOS gray)
  - [ ] Text: #1C1C1E (iOS black)
  - [ ] Secondary actions: #007AFF (iOS blue - cho links, secondary buttons)

- [ ] **Typography**
  - [ ] Font: SF Pro Display (iOS)
  - [ ] Font size: 17px (standard)
  - [ ] Letter spacing: -0.3
  - [ ] Line height: 1.2

- [ ] **Components**
  - [ ] Buttons: Flat (elevation: 0), 12px radius
  - [ ] Cards: 16px radius, subtle shadow
  - [ ] Inputs: 12px radius, no border
  - [ ] Icons: Outlined variants, 20px size

- [ ] **Spacing**
  - [ ] Padding: 16px standard
  - [ ] Margins: 8px, 16px, 24px
  - [ ] Section spacing: 24px

---

## 🎨 COLOR REFERENCE

### Brand & iOS Colors
```dart
// ✅ Brand Primary (GIỮ NGUYÊN)
static const Color brandPrimary = Color(0xFF1E8A6F); // Teal green - Brand color

// iOS System Colors (cho secondary actions)
static const Color iosBlue = Color(0xFF007AFF);      // Links, secondary actions
static const Color iosGreen = Color(0xFF34C759);     // Success states
static const Color iosRed = Color(0xFFFF3B30);       // Error states
static const Color iosOrange = Color(0xFFFF9500);    // Warning states

// iOS Grays (cho text & backgrounds)
static const Color iosGray1 = Color(0xFF1C1C1E);   // Text primary
static const Color iosGray2 = Color(0xFF8E8E93);     // Text secondary
static const Color iosGray3 = Color(0xFFF2F2F7);     // Background
static const Color iosGray4 = Color(0xFFE5E5EA);     // Border
```

### Usage in Theme
```dart
// ✅ GIỮ NGUYÊN brand color cho cả iOS và Android
static const Color primaryLight = Color(0xFF1E8A6F); // Brand teal green

// iOS-style: Dùng brand color với iOS UI patterns
// - Flat buttons với brand color
// - iOS typography & spacing
// - Subtle shadows
```

---

## 🚀 QUICK START COMMANDS

### 1. Create iOS Components
```bash
# Create new files
touch lib/widgets/common/ios_button.dart
touch lib/widgets/common/ios_card.dart
touch lib/widgets/common/ios_text_field.dart
```

### 2. Update Theme
```bash
# Edit theme file
code lib/theme/app_theme.dart
```

### 3. Test on iOS
```bash
# Run on iOS simulator
flutter run -d iPhone
```

---

## 📚 REFERENCES

- **iOS Human Interface Guidelines:** https://developer.apple.com/design/human-interface-guidelines/
- **Flutter Cupertino:** https://api.flutter.dev/flutter/cupertino/cupertino-library.html
- **Existing iOS Login:** `lib/presentation/login_screen/login_screen_ios.dart`

---

**Next Steps:**
1. ✅ Review this guide
2. ✅ Create iOS components
3. ✅ Start with 1 screen (Home Feed)
4. ✅ Test & iterate

**Estimated Time:** 2-3 weeks for full migration

