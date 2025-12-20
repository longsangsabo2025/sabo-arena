/// SABO Arena Design System
///
/// Comprehensive design system for consistent UI/UX across the application.
/// Includes colors, typography, spacing, and component specifications.
///
/// Created: October 13, 2025
/// Version: 1.0.0

import 'package:flutter/material.dart';

// ============================================================================
// COLORS
// ============================================================================

/// Application color palette with semantic meanings
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================================================
  // Primary Colors (Keep existing brand identity)
  // ============================================================================

  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);

  static const Color secondary = Color(0xFFFFA726);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFF57C00);

  // ============================================================================
  // Semantic Colors (Status & Feedback)
  // ============================================================================

  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);

  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // ============================================================================
  // Status Colors (For member/club/tournament states)
  // ============================================================================

  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusInactive = Color(0xFF9E9E9E);
  static const Color statusCompleted = Color(0xFF2196F3);
  static const Color statusCancelled = Color(0xFFF44336);
  static const Color statusDraft = Color(0xFFBDBDBD);

  // ============================================================================
  // Category Colors (For quick actions & sections)
  // ============================================================================

  static const Color categoryManagement = Color(0xFF2196F3);
  static const Color categoryAnalytics = Color(0xFF9C27B0);
  static const Color categorySettings = Color(0xFF607D8B);
  static const Color categoryFinance = Color(0xFF4CAF50);
  static const Color categorySocial = Color(0xFFFF5722);
  static const Color categoryTournament = Color(0xFFFFC107);

  // ============================================================================
  // Neutral Colors (Backgrounds, borders, text)
  // ============================================================================

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ============================================================================
  // Surface Colors
  // ============================================================================

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFFEEEEEE);

  // ============================================================================
  // Text Colors
  // ============================================================================

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF000000);

  // ============================================================================
  // Border & Divider Colors
  // ============================================================================

  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderDark = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFE0E0E0);

  // ============================================================================
  // Shadow Colors
  // ============================================================================

  static Color shadow = Colors.black.withValues(alpha: 0.12);
  static Color shadowLight = Colors.black.withValues(alpha: 0.05);
  static Color shadowDark = Colors.black.withValues(alpha: 0.20);

  // ============================================================================
  // Overlay Colors
  // ============================================================================

  static Color overlay = Colors.black.withValues(alpha: 0.5);
  static Color overlayLight = Colors.black.withValues(alpha: 0.3);
  static Color overlayDark = Colors.black.withValues(alpha: 0.7);

  // ============================================================================
  // Gradient Presets
  // ============================================================================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, warningLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ============================================================================
// TYPOGRAPHY
// ============================================================================

/// Typography system with consistent text styles
class AppTypography {
  AppTypography._(); // Private constructor

  // Font family
  static const String fontFamily = 'Inter';
  static const String fontFamilyFallback = 'Roboto';

  // ============================================================================
  // Display Styles (Extra large, hero text)
  // ============================================================================

  static TextStyle display1({Color? color}) => TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle display2({Color? color}) => TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  // ============================================================================
  // Heading Styles
  // ============================================================================

  static TextStyle h1({Color? color}) => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
        height: 1.25,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle h2({Color? color}) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
        height: 1.29,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle h3({Color? color}) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle h4({Color? color}) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.4,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle h5({Color? color}) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.44,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle h6({Color? color}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  // ============================================================================
  // Body Styles
  // ============================================================================

  static TextStyle bodyLarge({Color? color}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
        height: 1.5,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyMedium({Color? color}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
        height: 1.43,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodySmall({Color? color}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.4,
        height: 1.33,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  // ============================================================================
  // Label Styles (Buttons, chips, etc.)
  // ============================================================================

  static TextStyle labelLarge({Color? color}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle labelMedium({Color? color}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle labelSmall({Color? color}) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  // ============================================================================
  // Special Styles
  // ============================================================================

  /// For large statistic numbers
  static TextStyle statValue({Color? color}) => TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        height: 1.2,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  /// For stat labels/descriptions
  static TextStyle statLabel({Color? color}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        fontFamily: fontFamily,
        color: color ?? AppColors.textSecondary,
      );

  /// For card titles
  static TextStyle cardTitle({Color? color}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
        fontFamily: fontFamily,
        color: color ?? AppColors.textPrimary,
      );

  /// For button text
  static TextStyle button({Color? color}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.43,
        fontFamily: fontFamily,
        color: color ?? AppColors.textOnPrimary,
      );

  /// For caption text
  static TextStyle caption({Color? color}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.4,
        height: 1.33,
        fontFamily: fontFamily,
        color: color ?? AppColors.textSecondary,
      );

  /// For overline text (labels above content)
  static TextStyle overline({Color? color}) => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        height: 1.6,
        fontFamily: fontFamily,
        color: color ?? AppColors.textSecondary,
      );
}

// ============================================================================
// SPACING
// ============================================================================

/// Consistent spacing scale for layouts
class AppSpacing {
  AppSpacing._(); // Private constructor

  // Base unit: 4px
  static const double base = 4.0;

  // Spacing scale (multiples of base)
  static const double xs = 4.0; // 1x base
  static const double sm = 8.0; // 2x base
  static const double md = 16.0; // 4x base
  static const double lg = 24.0; // 6x base
  static const double xl = 32.0; // 8x base
  static const double xxl = 48.0; // 12x base
  static const double xxxl = 64.0; // 16x base

  // Semantic spacing
  static const double cardPadding = md;
  static const double screenPadding = md;
  static const double sectionSpacing = lg;
  static const double elementSpacing = sm;
  static const double iconTextSpacing = sm;

  // Component-specific spacing
  static const double buttonPaddingHorizontal = md;
  static const double buttonPaddingVertical = sm;
  static const double inputPadding = md;
  static const double chipPadding = sm;

  // List spacing
  static const double listItemSpacing = sm;
  static const double listSectionSpacing = lg;

  // Grid spacing
  static const double gridSpacing = md;
  static const double gridPadding = md;
}

// ============================================================================
// BORDER RADIUS
// ============================================================================

/// Consistent border radius values
class AppRadius {
  AppRadius._(); // Private constructor

  static const double none = 0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0; // For circular/pill shapes

  // Component-specific radius
  static const double button = md;
  static const double card = lg;
  static const double dialog = xl;
  static const double chip = full;
  static const double input = md;
}

// ============================================================================
// ELEVATION (Shadow Depths)
// ============================================================================

/// Shadow elevation levels
class AppElevation {
  AppElevation._(); // Private constructor

  static List<BoxShadow> none = [];

  static List<BoxShadow> level1 = [
    BoxShadow(
      color: AppColors.shadow,
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> level2 = [
    BoxShadow(
      color: AppColors.shadow,
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> level3 = [
    BoxShadow(
      color: AppColors.shadow,
      offset: const Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> level4 = [
    BoxShadow(
      color: AppColors.shadow,
      offset: const Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> level5 = [
    BoxShadow(
      color: AppColors.shadowDark,
      offset: const Offset(0, 12),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];
}

// ============================================================================
// ANIMATION DURATIONS
// ============================================================================

/// Consistent animation timing
class AppDuration {
  AppDuration._(); // Private constructor

  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Specific animations
  static const Duration fadeIn = Duration(milliseconds: 200);
  static const Duration fadeOut = Duration(milliseconds: 150);
  static const Duration slide = Duration(milliseconds: 300);
  static const Duration scale = Duration(milliseconds: 250);
  static const Duration shimmer = Duration(milliseconds: 1500);
}

// ============================================================================
// ANIMATION CURVES
// ============================================================================

/// Consistent animation curves
class AppCurves {
  AppCurves._(); // Private constructor

  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve decelerated = Curves.easeOut;
  static const Curve accelerated = Curves.easeIn;
}

// ============================================================================
// ICON SIZES
// ============================================================================

/// Consistent icon sizing
class AppIconSize {
  AppIconSize._(); // Private constructor

  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;

  // Component-specific
  static const double button = md;
  static const double appBar = md;
  static const double fab = md;
  static const double listTile = md;
  static const double avatar = xl;
}

// ============================================================================
// BREAKPOINTS (Responsive Design)
// ============================================================================

/// Screen size breakpoints
class AppBreakpoints {
  AppBreakpoints._(); // Private constructor

  static const double mobile = 375;
  static const double mobileLarge = 425;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;

  /// Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tablet;
  }

  /// Check if screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }

  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }
}

// ============================================================================
// TOUCH TARGET SIZES
// ============================================================================

/// Minimum touch target sizes for accessibility
class AppTouchTarget {
  AppTouchTarget._(); // Private constructor

  static const double minimum = 44.0; // iOS/Material Design minimum
  static const double comfortable = 48.0; // Material Design recommended
  static const double large = 56.0; // For primary actions
}
