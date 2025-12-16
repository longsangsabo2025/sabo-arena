import 'package:flutter/material.dart';

/// 🎯 **AppButton** - Unified Button Component
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
    final isDisabled = onPressed == null && !isLoading;
    final effectiveOnPressed = isLoading ? null : onPressed;

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

  // 🎨 Primary Button (ElevatedButton)
  Widget _buildPrimaryButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: customColor ?? const Color(0xFF0866FF),
        foregroundColor: customTextColor ?? Colors.white,
        padding: _getPadding(),
        minimumSize: Size(_getMinWidth(), _getHeight()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[600],
      ),
      child: _buildLabel(context),
    );
  }

  // 🎨 Secondary Button (Gray ElevatedButton)
  Widget _buildSecondaryButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: customColor ?? Colors.grey[300],
        foregroundColor: customTextColor ?? Colors.black87,
        padding: _getPadding(),
        minimumSize: Size(_getMinWidth(), _getHeight()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 1,
        disabledBackgroundColor: Colors.grey[200],
        disabledForegroundColor: Colors.grey[500],
      ),
      child: _buildLabel(context),
    );
  }

  // 🎨 Outline Button (OutlinedButton)
  Widget _buildOutlineButton(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: customColor ?? const Color(0xFF0866FF),
        padding: _getPadding(),
        minimumSize: Size(_getMinWidth(), _getHeight()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color: customColor ?? const Color(0xFF0866FF),
          width: 1.5,
        ),
        disabledForegroundColor: Colors.grey[400],
      ),
      child: _buildLabel(context),
    );
  }

  // 🎨 Text Button (TextButton)
  Widget _buildTextButton(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: customColor ?? const Color(0xFF0866FF),
        padding: _getPadding(),
        minimumSize: Size(_getMinWidth(), _getHeight()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
                    : customColor ?? const Color(0xFF0866FF),
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
    final baseStyle = Theme.of(context).textTheme.labelLarge ?? TextStyle();

    double fontSize;
    FontWeight fontWeight;

    switch (size) {
      case AppButtonSize.small:
        fontSize = 12;
        fontWeight = FontWeight.w500;
        break;
      case AppButtonSize.medium:
        fontSize = 14;
        fontWeight = FontWeight.w600;
        break;
      case AppButtonSize.large:
        fontSize = 16;
        fontWeight = FontWeight.w600;
        break;
    }

    return baseStyle.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
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
