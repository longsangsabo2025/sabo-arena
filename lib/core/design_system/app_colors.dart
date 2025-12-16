/// App Colors - Single Source of Truth
///
/// Consolidated color system following Instagram/Facebook standards:
/// - Neutral gray scale (50-900)
/// - Single primary color with variations
/// - Semantic colors for status indicators
/// - Dark mode support
///
/// Based on Material Design 3 color system

import 'package:flutter/material.dart';

/// Complete color palette for SABO ARENA
///
/// All colors across the app should reference these constants
/// to ensure visual consistency and easy theme switching
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  /// White
  static const Color white = Colors.white;

  /// Black
  static const Color black = Colors.black;

  // ============================================================================
  // NEUTRAL GRAY SCALE (Instagram/Facebook Style)
  // ============================================================================

  /// Gray 50 - lightest gray, subtle backgrounds
  static const Color gray50 = Color(0xFFFAFAFA);

  /// Gray 100 - very light gray, card backgrounds
  static const Color gray100 = Color(0xFFF5F5F5);

  /// Gray 200 - light gray, dividers, borders
  static const Color gray200 = Color(0xFFEEEEEE);

  /// Gray 300 - medium light gray, disabled backgrounds
  static const Color gray300 = Color(0xFFE0E0E0);

  /// Gray 400 - medium gray, placeholder text
  static const Color gray400 = Color(0xFFBDBDBD);

  /// Gray 500 - neutral gray, icons
  static const Color gray500 = Color(0xFF9E9E9E);

  /// Gray 600 - medium dark gray, secondary text
  static const Color gray600 = Color(0xFF757575);

  /// Gray 700 - dark gray, body text
  static const Color gray700 = Color(0xFF616161);

  /// Gray 800 - very dark gray, headings
  static const Color gray800 = Color(0xFF424242);

  /// Gray 900 - darkest gray, primary text
  static const Color gray900 = Color(0xFF212121);

  // ============================================================================
  // PRIMARY COLORS (Teal Green - Billiards Theme)
  // ============================================================================

  /// Primary 50 - lightest teal, hover backgrounds
  static const Color primary50 = Color(0xFFE0F2F1);

  /// Primary 100 - very light teal, selected backgrounds
  static const Color primary100 = Color(0xFFB2DFDB);

  /// Primary 200 - light teal, subtle accents
  static const Color primary200 = Color(0xFF80CBC4);

  /// Primary 300 - medium light teal
  static const Color primary300 = Color(0xFF4DB6AC);

  /// Primary 400 - medium teal
  static const Color primary400 = Color(0xFF26A69A);

  /// Primary 500 - main primary color (default)
  static const Color primary500 = Color(0xFF00695C);

  /// Primary 600 - dark teal, hover states
  static const Color primary600 = Color(0xFF00897B);

  /// Primary 700 - darker teal, pressed states
  static const Color primary700 = Color(0xFF004D40);

  /// Primary 800 - very dark teal
  static const Color primary800 = Color(0xFF00352B);

  /// Primary 900 - darkest teal
  static const Color primary900 = Color(0xFF00251A);

  /// Primary - default primary color (alias for primary500)
  static const Color primary = primary500;

  // ============================================================================
  // SECONDARY COLORS (Vibrant Accent)
  // ============================================================================

  /// Secondary 50 - lightest secondary
  static const Color secondary50 = Color(0xFFE0F2F1);

  /// Secondary 100 - very light secondary
  static const Color secondary100 = Color(0xFFB2DFDB);

  /// Secondary 200 - light secondary
  static const Color secondary200 = Color(0xFF80CBC4);

  /// Secondary 300 - medium light secondary
  static const Color secondary300 = Color(0xFF4DB6AC);

  /// Secondary 400 - medium secondary (default)
  static const Color secondary400 = Color(0xFF26A69A);

  /// Secondary 500 - main secondary color
  static const Color secondary500 = Color(0xFF009688);

  /// Secondary 600 - dark secondary
  static const Color secondary600 = Color(0xFF00897B);

  /// Secondary 700 - darker secondary
  static const Color secondary700 = Color(0xFF00796B);

  /// Secondary 800 - very dark secondary
  static const Color secondary800 = Color(0xFF00695C);

  /// Secondary 900 - darkest secondary
  static const Color secondary900 = Color(0xFF004D40);

  /// Secondary - default secondary color (alias for secondary400)
  static const Color secondary = secondary400;

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  // SUCCESS (Green)
  /// Success 50 - lightest success background
  static const Color success50 = Color(0xFFE8F5E9);

  /// Success 100 - light success background
  static const Color success100 = Color(0xFFC8E6C9);

  /// Success 200 - light green
  static const Color success200 = Color(0xFFA5D6A7);

  /// Success 500 - main success color
  static const Color success500 = Color(0xFF4CAF50);

  /// Success 600 - dark success (default)
  static const Color success600 = Color(0xFF43A047);

  /// Success 700 - darker success
  static const Color success700 = Color(0xFF388E3C);

  /// Success 800 - forest green
  static const Color success800 = Color(0xFF2E7D32);

  /// Success 900 - dark forest green
  static const Color success900 = Color(0xFF1B5E20);

  /// Success - default success color (alias)
  static const Color success = success600;

  // WARNING (Amber/Orange)
  /// Warning 50 - lightest warning background
  static const Color warning50 = Color(0xFFFFF3E0);

  /// Warning 100 - light warning background
  static const Color warning100 = Color(0xFFFFE0B2);

  /// Warning 200 - light orange
  static const Color warning200 = Color(0xFFFFCC80);

  /// Warning 500 - main warning color
  static const Color warning500 = Color(0xFFFF9800);

  /// Warning 600 - dark warning (default)
  static const Color warning600 = Color(0xFFFB8C00);

  /// Warning 700 - darker warning
  static const Color warning700 = Color(0xFFF57C00);

  /// Warning 900 - dark orange
  static const Color warning900 = Color(0xFFE65100);

  /// Warning - default warning color (alias)
  static const Color warning = warning600;

  // ERROR (Red)
  /// Error 50 - lightest error background
  static const Color error50 = Color(0xFFFFEBEE);

  /// Error 100 - light error background
  static const Color error100 = Color(0xFFFFCDD2);

  /// Error 400 - medium error
  static const Color error400 = Color(0xFFEF5350);

  /// Error 500 - main error color
  static const Color error500 = Color(0xFFF44336);

  /// Error 600 - dark error (default)
  static const Color error600 = Color(0xFFE53935);

  /// Error 700 - darker error
  static const Color error700 = Color(0xFFD32F2F);

  /// Error 800 - very dark error
  static const Color error800 = Color(0xFFC62828);

  /// Error 900 - darkest error
  static const Color error900 = Color(0xFFB71C1C);

  /// Error - default error color (alias)
  static const Color error = error600;

  // INFO (Blue)
  /// Info 50 - lightest info background
  static const Color info50 = Color(0xFFE3F2FD);

  /// Info 100 - light info background
  static const Color info100 = Color(0xFFBBDEFB);

  /// Info 500 - main info color
  static const Color info500 = Color(0xFF2196F3);

  /// Info 600 - dark info (default)
  static const Color info600 = Color(0xFF1E88E5);

  /// Info 700 - darker info
  static const Color info700 = Color(0xFF1976D2);

  /// Info - default info color (alias)
  static const Color info = info600;

  // ============================================================================
  // SPECIAL COLORS
  // ============================================================================

  // ACCENT (Orange - for highlights)
  /// Accent 50 - lightest accent
  static const Color accent50 = Color(0xFFFFF3E0);

  /// Accent 100 - very light accent
  static const Color accent100 = Color(0xFFFFE0B2);

  /// Accent 400 - medium accent
  static const Color accent400 = Color(0xFFFFB74D);

  /// Accent 500 - main accent
  static const Color accent500 = Color(0xFFFF8A50);

  /// Accent 600 - dark accent (default)
  static const Color accent600 = Color(0xFFFF8F00);

  /// Accent 700 - darker accent
  static const Color accent700 = Color(0xFFF57C00);

  /// Accent - default accent color (alias)
  static const Color accent = accent500;

  // PREMIUM/VERIFIED (Purple)
  /// Premium 50 - lightest premium
  static const Color premium50 = Color(0xFFF3E5F5);

  /// Premium 100 - light premium
  static const Color premium100 = Color(0xFFE1BEE7);

  /// Premium 500 - main premium
  static const Color premium500 = Color(0xFF9C27B0);

  /// Premium 600 - dark premium (default)
  static const Color premium600 = Color(0xFF8E24AA);

  /// Premium - default premium color (alias)
  static const Color premium = premium600;

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================

  // Light mode backgrounds
  /// Background - main background color (light mode)
  static const Color background = Color(0xFFFAFAFA);

  /// Surface - card/paper background (light mode)
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface variant - secondary surface (light mode)
  static const Color surfaceVariant = gray100;

  // Dark mode backgrounds
  /// Background dark - main background (dark mode)
  static const Color backgroundDark = Color(0xFF121212);

  /// Surface dark - card/paper background (dark mode)
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Surface variant dark - secondary surface (dark mode)
  static const Color surfaceVariantDark = Color(0xFF2D2D2D);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  // Light mode text
  /// Text primary - highest emphasis (light mode)
  static const Color textPrimary = gray900;

  /// Text secondary - medium emphasis (light mode)
  static const Color textSecondary = gray600;

  /// Text tertiary - low emphasis (light mode)
  static const Color textTertiary = gray500;

  /// Text disabled - disabled state (light mode)
  static const Color textDisabled = gray400;

  /// Text on primary - text on primary color backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Text on secondary - text on secondary color backgrounds
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // Dark mode text
  /// Text primary dark - highest emphasis (dark mode)
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  /// Text secondary dark - medium emphasis (dark mode)
  static const Color textSecondaryDark = Color(0xB3FFFFFF); // 70% opacity

  /// Text tertiary dark - low emphasis (dark mode)
  static const Color textTertiaryDark = Color(0x99FFFFFF); // 60% opacity

  /// Text disabled dark - disabled state (dark mode)
  static const Color textDisabledDark = Color(0x61FFFFFF); // 38% opacity

  // ============================================================================
  // BORDER & DIVIDER COLORS
  // ============================================================================

  /// Border - standard border color (light mode)
  static const Color border = gray300;

  /// Divider - divider line color (light mode)
  static const Color divider = gray200;

  /// Border dark - standard border (dark mode)
  static const Color borderDark = Color(0x1FFFFFFF); // 12% white

  /// Divider dark - divider line (dark mode)
  static const Color dividerDark = Color(0x1FFFFFFF); // 12% white

  // ============================================================================
  // OVERLAY & SHADOW COLORS
  // ============================================================================

  /// Shadow - standard shadow (light mode)
  static const Color shadow = Color(0x1A000000); // 10% black

  /// Shadow dark - standard shadow (dark mode)
  static const Color shadowDark = Color(0x1AFFFFFF); // 10% white

  /// Scrim - full-screen overlay
  static const Color scrim = Color(0x99000000); // 60% black

  // ============================================================================
  // SPECIAL STATES
  // ============================================================================

  /// Focus ring color
  static const Color focus = info500;

  /// Hover overlay (light mode)
  static const Color hoverOverlay = Color(0x0A000000); // 4% black

  /// Press overlay (light mode)
  static const Color pressOverlay = Color(0x1F000000); // 12% black

  /// Drag overlay (light mode)
  static const Color dragOverlay = Color(0x14000000); // 8% black

  /// Selected overlay (light mode)
  static const Color selectedOverlay = Color(0x14000000); // 8% black

  // ============================================================================
  // SOCIAL MEDIA BRAND COLORS (For sharing buttons)
  // ============================================================================

  /// Facebook brand color
  static const Color facebook = Color(0xFF1877F2);

  /// Instagram gradient start
  static const Color instagramStart = Color(0xFFF58529);

  /// Instagram gradient end
  static const Color instagramEnd = Color(0xFFDD2A7B);

  /// Twitter/X brand color
  static const Color twitter = Color(0xFF1DA1F2);

  /// WhatsApp brand color
  static const Color whatsapp = Color(0xFF25D366);

  /// Telegram brand color
  static const Color telegram = Color(0xFF0088CC);

  /// Zalo brand color (Vietnam)
  static const Color zalo = Color(0xFF0068FF);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Create color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Create black overlay with opacity
  static Color blackOverlay(double opacity) {
    return Colors.black.withValues(alpha: opacity);
  }

  /// Create white overlay with opacity
  static Color whiteOverlay(double opacity) {
    return Colors.white.withValues(alpha: opacity);
  }

  /// Get text color based on background brightness
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();

    // Return white text for dark backgrounds, black for light
    return luminance > 0.5 ? textPrimary : textPrimaryDark;
  }

  /// Get appropriate primary color for current theme
  static Color getPrimary(Brightness brightness) {
    return brightness == Brightness.light ? primary : primary400;
  }

  /// Get appropriate background for current theme
  static Color getBackground(Brightness brightness) {
    return brightness == Brightness.light ? background : backgroundDark;
  }

  /// Get appropriate surface for current theme
  static Color getSurface(Brightness brightness) {
    return brightness == Brightness.light ? surface : surfaceDark;
  }

  /// Get appropriate text primary for current theme
  static Color getTextPrimary(Brightness brightness) {
    return brightness == Brightness.light ? textPrimary : textPrimaryDark;
  }

  /// Get appropriate text secondary for current theme
  static Color getTextSecondary(Brightness brightness) {
    return brightness == Brightness.light ? textSecondary : textSecondaryDark;
  }
}

/// Color scheme builder for easy theme creation
class AppColorScheme {
  /// Create light color scheme
  static ColorScheme light() {
    return ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primary100,
      onPrimaryContainer: AppColors.primary700,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnSecondary,
      secondaryContainer: AppColors.secondary100,
      onSecondaryContainer: AppColors.secondary700,
      tertiary: AppColors.accent,
      onTertiary: AppColors.textOnPrimary,
      tertiaryContainer: AppColors.accent50,
      onTertiaryContainer: AppColors.accent600,
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      errorContainer: AppColors.error50,
      onErrorContainer: AppColors.error700,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      shadow: AppColors.shadow,
      scrim: AppColors.scrim,
      inverseSurface: AppColors.surfaceDark,
      onInverseSurface: AppColors.textPrimaryDark,
      inversePrimary: AppColors.primary200,
    );
  }

  /// Create dark color scheme
  static ColorScheme dark() {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary400,
      onPrimary: AppColors.primary900,
      primaryContainer: AppColors.primary700,
      onPrimaryContainer: AppColors.primary100,
      secondary: AppColors.secondary400,
      onSecondary: AppColors.secondary900,
      secondaryContainer: AppColors.secondary700,
      onSecondaryContainer: AppColors.secondary100,
      tertiary: AppColors.accent400,
      onTertiary: AppColors.accent50,
      tertiaryContainer: AppColors.accent700,
      onTertiaryContainer: AppColors.accent100,
      error: AppColors.error400,
      onError: AppColors.error900,
      errorContainer: AppColors.error700,
      onErrorContainer: AppColors.error100,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.dividerDark,
      shadow: AppColors.shadowDark,
      scrim: AppColors.scrim,
      inverseSurface: AppColors.surface,
      onInverseSurface: AppColors.textPrimary,
      inversePrimary: AppColors.primary700,
    );
  }
}
