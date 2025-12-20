import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// 🎯 **AppButton** - Unified Button Component
///
/// **iOS Support**: Automatically applies iOS-style (flat buttons, 12px radius) on iOS devices
/// **Brand Color**: Uses brand teal green #1E8A6F for primary actions
///
/// **Purpose**: Replace 100+ inconsistent button implementations with a single,
/// consistent, and accessible button component across the entire app.
///
/// **Features**:
/// - 4 button types: primary, secondary, outline, text
/// - 3 sizes: small, medium, large
/// - Loading state with spinner
/// - Icon support (leading/trailing)
/// - Full width option
/// - Disabled state
/// - Consistent styling and animations
///
/// **Usage**:
/// ```dart
/// // Primary button
/// AppButton(
///   label: 'Xác nhận',
///   onPressed: () => handleSubmit(),
/// )
///
/// // Secondary button with icon
/// AppButton(
///   label: 'Hủy',
///   type: AppButtonType.secondary,
///   icon: Icons.close,
///   onPressed: () => Navigator.pop(context),
/// )
///
/// // Outline button (loading state)
/// AppButton(
///   label: 'Đang tải...',
///   type: AppButtonType.outline,
///   isLoading: true,
/// )
///
/// // Text button (small size)
/// AppButton(
///   label: 'Xem thêm',
///   type: AppButtonType.text,
///   size: AppButtonSize.small,
///   onPressed: () => navigateToDetail(),
/// )
/// ```

enum AppButtonType {
  primary, // ElevatedButton style - main actions
  secondary, // ElevatedButton with gray color - cancel actions
  outline, // OutlinedButton style - secondary actions
  text, // TextButton style - tertiary actions
}

enum AppButtonSize {
  small, // Compact buttons for lists
  medium, // Default size for most actions
  large, // Prominent actions like submit forms
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? icon;
  final bool iconTrailing;
  final bool isLoading;
  final bool fullWidth;
  final Color? customColor;
  final Color? customTextColor;

  const AppButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconTrailing = false,
    this.isLoading = false,
    this.fullWidth = false,
    this.customColor,
    this.customTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = _buildButtonContent(context);

    if (fullWidth) {
      buttonChild = SizedBox(
        width: double.infinity,
        child: buttonChild,
      );
    }

    return buttonChild;
  }

  Widget _buildButtonContent(BuildContext context) {
    switch (type) {
      case AppButtonType.primary:
        return _buildPrimaryButton(context);
      case AppButtonType.secondary:
        return _buildSecondaryButton(context);
      case AppButtonType.outline:
        return _buildOutlineButton(context);
      case AppButtonType.text:
        return _buildTextButton(context);
    }
  }

  // 🎨 Primary Button (iOS-style flat on iOS, Material elevated on Android)
  Widget _buildPrimaryButton(BuildContext context) {
    final isIOS = !kIsWeb && Platform.isIOS;
    final brandColor =
        customColor ?? const Color(0xFF1E8A6F); // Brand teal green
    final borderRadius = isIOS ? 12.0 : 8.0; // iOS: 12px, Android: 8px
    final elevation = isIOS ? 0.0 : 2.0; // iOS: flat, Android: elevated

    if (isIOS) {
      // iOS-style flat button với brand color
      return Container(
        height: _getHeight(),
        decoration: BoxDecoration(
          color: isLoading ? Colors.grey[300] : brandColor,
          borderRadius: BorderRadius.circular(borderRadius),
          // No elevation - iOS flat style
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: isLoading ? null : onPressed,
            child: Padding(
              padding: _getPadding(),
              child: Center(
                child: _buildLabel(context),
              ),
            ),
          ),
        ),
      );
    }

    // Android Material style
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: brandColor,
        foregroundColor: customTextColor ?? Colors.white,
        padding: _getPadding(),
        minimumSize: Size(_getMinWidth(), _getHeight()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: elevation,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[600],
      ),
      child: _buildLabel(context),
    );
  }

  // 🎨 Secondary Button (iOS-style flat on iOS, Material elevated on Android)
  Widget _buildSecondaryButton(BuildContext context) {
    final isIOS = !kIsWeb && Platform.isIOS;
    final bgColor = customColor ?? Colors.grey[300];
    final borderRadius = isIOS ? 12.0 : 8.0;
    final elevation = isIOS ? 0.0 : 1.0;

    if (isIOS) {
      // iOS-style flat secondary button
      return Container(
        height: _getHeight(),
        decoration: BoxDecoration(
          color: isLoading ? Colors.grey[200] : bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: isLoading ? null : onPressed,
            child: Padding(
              padding: _getPadding(),
              child: Center(
                child: _buildLabel(context),
              ),
            ),
          ),
        ),
      );
    }

    // Android Material style
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: customTextColor ?? Colors.black87,
        padding: _getPadding(),
        minimumSize: Size(_getMinWidth(), _getHeight()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: elevation,
        disabledBackgroundColor: Colors.grey[200],
        disabledForegroundColor: Colors.grey[500],
      ),
      child: _buildLabel(context),
    );
  }

  // 🎨 Outline Button (iOS-style với brand color)
  Widget _buildOutlineButton(BuildContext context) {
    final isIOS = !kIsWeb && Platform.isIOS;
    final brandColor =
        customColor ?? const Color(0xFF1E8A6F); // Brand teal green
    final borderRadius = isIOS ? 12.0 : 8.0;

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: brandColor,
        padding: _getPadding(),
        minimumSize: Size(_getMinWidth(), _getHeight()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        side: BorderSide(
          color: brandColor,
          width: isIOS ? 1.0 : 1.5, // iOS: thinner border
        ),
        disabledForegroundColor: Colors.grey[400],
      ),
      child: _buildLabel(context),
    );
  }

  // 🎨 Text Button (iOS-style với brand color hoặc iOS blue cho links)
  Widget _buildTextButton(BuildContext context) {
    final isIOS = !kIsWeb && Platform.isIOS;
    // Text buttons: dùng brand color cho primary, iOS blue cho secondary links
    final textColor = customColor ??
        (type == AppButtonType.text
            ? const Color(0xFF007AFF) // iOS blue cho links
            : const Color(0xFF1E8A6F)); // Brand color cho primary text buttons
    final borderRadius = isIOS ? 12.0 : 8.0;

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        padding: _getPadding(),
        minimumSize: Size(_getMinWidth(), _getHeight()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        disabledForegroundColor: Colors.grey[400],
      ),
      child: _buildLabel(context),
    );
  }

  // 📝 Build Label with Icon and Loading State
  Widget _buildLabel(BuildContext context) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: _getLoadingSize(),
            height: _getLoadingSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == AppButtonType.primary
                    ? Colors.white
                    : customColor ?? const Color(0xFF1E8A6F), // Brand color
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: _getTextStyle(context),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: iconTrailing
            ? [
                Text(label, style: _getTextStyle(context)),
                SizedBox(width: 6),
                Icon(icon, size: _getIconSize()),
              ]
            : [
                Icon(icon, size: _getIconSize()),
                SizedBox(width: 6),
                Text(label, style: _getTextStyle(context)),
              ],
      );
    }

    return Text(
      label,
      style: _getTextStyle(context),
      textAlign: TextAlign.center,
    );
  }

  // 📏 Size Configurations
  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case AppButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    }
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 32;
      case AppButtonSize.medium:
        return 40;
      case AppButtonSize.large:
        return 48;
    }
  }

  double _getMinWidth() {
    if (fullWidth) return double.infinity;
    switch (size) {
      case AppButtonSize.small:
        return 60;
      case AppButtonSize.medium:
        return 80;
      case AppButtonSize.large:
        return 100;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 16;
      case AppButtonSize.large:
        return 18;
    }
  }

  double _getLoadingSize() {
    switch (size) {
      case AppButtonSize.small:
        return 12;
      case AppButtonSize.medium:
        return 14;
      case AppButtonSize.large:
        return 16;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    final isIOS = !kIsWeb && Platform.isIOS;
    final baseStyle = Theme.of(context).textTheme.labelLarge ?? TextStyle();

    double fontSize;
    FontWeight fontWeight;
    double letterSpacing;

    switch (size) {
      case AppButtonSize.small:
        fontSize = isIOS ? 13 : 12;
        fontWeight = FontWeight.w500;
        letterSpacing = isIOS ? -0.2 : 0.1;
        break;
      case AppButtonSize.medium:
        fontSize = isIOS ? 15 : 14;
        fontWeight = FontWeight.w600;
        letterSpacing = isIOS ? -0.3 : 0.1;
        break;
      case AppButtonSize.large:
        fontSize = isIOS ? 17 : 16; // iOS standard button text size
        fontWeight = FontWeight.w600;
        letterSpacing = isIOS ? -0.3 : 0.1;
        break;
    }

    return baseStyle.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }
}

/// 🎯 **AppIconButton** - Unified Icon Button Component
///
/// **Purpose**: Consistent icon-only buttons (like IconButton but with better defaults)
///
/// **Usage**:
/// ```dart
/// AppIconButton(
///   icon: Icons.close,
///   onPressed: () => Navigator.pop(context),
/// )
///
/// AppIconButton(
///   icon: Icons.refresh,
///   onPressed: _reload,
///   size: AppIconButtonSize.large,
///   tooltip: 'Tải lại',
/// )
/// ```
enum AppIconButtonSize {
  small,
  medium,
  large,
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonSize size;
  final Color? color;
  final String? tooltip;
  final bool isLoading;

  const AppIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.size = AppIconButtonSize.medium,
    this.color,
    this.tooltip,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget button = IconButton(
      icon: isLoading
          ? SizedBox(
              width: _getIconSize(),
              height: _getIconSize(),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Theme.of(context).iconTheme.color ?? Colors.black,
                ),
              ),
            )
          : Icon(icon, size: _getIconSize()),
      onPressed: isLoading ? null : onPressed,
      color: color,
      iconSize: _getIconSize(),
      constraints: BoxConstraints(
        minWidth: _getButtonSize(),
        minHeight: _getButtonSize(),
      ),
      padding: EdgeInsets.all(_getPadding()),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }

  double _getIconSize() {
    switch (size) {
      case AppIconButtonSize.small:
        return 18;
      case AppIconButtonSize.medium:
        return 24;
      case AppIconButtonSize.large:
        return 28;
    }
  }

  double _getButtonSize() {
    switch (size) {
      case AppIconButtonSize.small:
        return 32;
      case AppIconButtonSize.medium:
        return 40;
      case AppIconButtonSize.large:
        return 48;
    }
  }

  double _getPadding() {
    switch (size) {
      case AppIconButtonSize.small:
        return 6;
      case AppIconButtonSize.medium:
        return 8;
      case AppIconButtonSize.large:
        return 10;
    }
  }
}
