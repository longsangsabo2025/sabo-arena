import 'package:flutter/material.dart';

/// Dark Mode Helper - Centralized color management
/// 
/// Use this instead of hardcoded colors for automatic dark mode support
class DarkModeHelper {
  /// Get theme-aware primary color
  static Color primary(BuildContext context) => 
      Theme.of(context).colorScheme.primary;

  /// Get theme-aware surface color (replaces Colors.white)
  static Color surface(BuildContext context) => 
      Theme.of(context).colorScheme.surface;

  /// Get theme-aware on-surface color (replaces Colors.black for text)
  static Color onSurface(BuildContext context) => 
      Theme.of(context).colorScheme.onSurface;

  /// Get theme-aware gray colors (replaces Colors.grey[X])
  static Color gray(BuildContext context, {int shade = 500}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      // Invert shades for dark mode
      return _getDarkGray(1000 - shade);
    }
    return _getLightGray(shade);
  }

  static Color _getLightGray(int shade) {
    switch (shade) {
      case 100: return const Color(0xFFF5F5F5);
      case 200: return const Color(0xFFEEEEEE);
      case 300: return const Color(0xFFE0E0E0);
      case 400: return const Color(0xFFBDBDBD);
      case 500: return const Color(0xFF9E9E9E);
      case 600: return const Color(0xFF757575);
      case 700: return const Color(0xFF616161);
      case 800: return const Color(0xFF424242);
      case 900: return const Color(0xFF212121);
      default: return const Color(0xFF9E9E9E);
    }
  }

  static Color _getDarkGray(int shade) {
    switch (shade) {
      case 100: return const Color(0xFF2C2C2C);
      case 200: return const Color(0xFF383838);
      case 300: return const Color(0xFF4A4A4A);
      case 400: return const Color(0xFF5C5C5C);
      case 500: return const Color(0xFF707070);
      case 600: return const Color(0xFF8A8A8A);
      case 700: return const Color(0xFFA0A0A0);
      case 800: return const Color(0xFFB8B8B8);
      case 900: return const Color(0xFFD0D0D0);
      default: return const Color(0xFF707070);
    }
  }

  /// Get theme-aware border color
  static Color border(BuildContext context) => 
      Theme.of(context).colorScheme.outline;

  /// Get theme-aware divider color
  static Color divider(BuildContext context) => 
      Theme.of(context).colorScheme.outlineVariant;

  /// Get theme-aware shadow color
  static Color shadow(BuildContext context) => 
      Theme.of(context).colorScheme.shadow;

  /// Get theme-aware error color
  static Color error(BuildContext context) => 
      Theme.of(context).colorScheme.error;

  /// Get theme-aware success color (green)
  static Color success(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
  }

  /// Get theme-aware warning color (orange)
  static Color warning(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFF9800) : const Color(0xFFE65100);
  }

  /// Get theme-aware info color (blue)
  static Color info(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
  }

  /// Check if current theme is dark
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Get adaptive color with alpha
  static Color withAlpha(Color color, double alpha) =>
      color.withValues(alpha: alpha);
}
