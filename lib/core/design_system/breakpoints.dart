/// Breakpoints System - Responsive Design
///
/// Responsive breakpoints and utilities for adaptive layouts:
/// - Mobile, tablet, desktop, wide breakpoints
/// - Helper methods to check device type
/// - Responsive padding, spacing utilities
/// - Adaptive column counts for grids
///
/// Based on Material Design 3 breakpoints with adjustments

import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Responsive breakpoints for SABO ARENA
///
/// Use these breakpoints to create adaptive layouts that work
/// seamlessly across mobile, tablet, and desktop
class Breakpoints {
  Breakpoints._(); // Private constructor

  // ============================================================================
  // BREAKPOINT VALUES (width in logical pixels)
  // ============================================================================

  /// Mobile breakpoint (0-599px)
  /// Phones in portrait and landscape
  static const double mobile = 600;

  // ============================================================================
  // IPAD-SPECIFIC BREAKPOINTS
  // ============================================================================

  /// iPad Mini portrait (744px)
  static const double iPadMini = 744;

  /// iPad Air portrait (820px)
  static const double iPadAir = 820;

  /// iPad Pro 11" portrait (834px)
  static const double iPadPro11 = 834;

  /// iPad Pro 12.9" portrait (1024px)
  static const double iPadPro12 = 1024;

  /// iPad Mini landscape (1133px)
  static const double iPadMiniLandscape = 1133;

  /// iPad Air landscape (1180px)
  static const double iPadAirLandscape = 1180;

  /// iPad Pro 11" landscape (1194px)
  static const double iPadPro11Landscape = 1194;

  /// iPad Pro 12.9" landscape (1366px)
  static const double iPadPro12Landscape = 1366;

  /// Tablet breakpoint (600-839px)
  /// Tablets in portrait, large phones in landscape
  static const double tablet = 840;

  /// Desktop breakpoint (840-1199px)
  /// Tablets in landscape, small laptops
  static const double desktop = 1200;

  /// Wide desktop breakpoint (1200px+)
  /// Large screens, wide monitors
  static const double wide = 1440;

  /// Extra wide breakpoint (1440px+)
  /// Ultra-wide monitors, 4K displays
  static const double extraWide = 1920;

  // ============================================================================
  // DEVICE TYPE CHECKS
  // ============================================================================

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= desktop && width < extraWide;
  }

  /// Check if current device is wide desktop
  static bool isWide(BuildContext context) {
    return MediaQuery.of(context).size.width >= wide;
  }

  /// Check if current device is extra wide
  static bool isExtraWide(BuildContext context) {
    return MediaQuery.of(context).size.width >= extraWide;
  }

  /// Check if device is tablet or larger
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobile;
  }

  /// Check if device is desktop or larger
  static bool isDesktopOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Get device type as enum
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= extraWide) return DeviceType.extraWide;
    if (width >= wide) return DeviceType.wide;
    if (width >= desktop) return DeviceType.desktop;
    if (width >= mobile) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  // ============================================================================
  // RESPONSIVE VALUES
  // ============================================================================

  /// Get responsive value based on device type
  ///
  /// Usage:
  /// ```dart
  /// Breakpoints.value(
  ///   context: context,
  ///   mobile: 12,
  ///   tablet: 16,
  ///   desktop: 20,
  /// )
  /// ```
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? wide,
    T? extraWide,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= Breakpoints.extraWide && extraWide != null) return extraWide;
    if (width >= Breakpoints.wide && wide != null) return wide;
    if (width >= Breakpoints.desktop && desktop != null) return desktop;
    if (width >= Breakpoints.mobile && tablet != null) return tablet;
    return mobile;
  }

  // ============================================================================
  // RESPONSIVE SPACING
  // ============================================================================

  /// Get responsive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    return value(
      context: context,
      mobile: DesignTokens.space16,
      tablet: DesignTokens.space24,
      desktop: DesignTokens.space32,
      wide: DesignTokens.space40,
    );
  }

  /// Get responsive vertical padding
  static double getVerticalPadding(BuildContext context) {
    return value(
      context: context,
      mobile: DesignTokens.space16,
      tablet: DesignTokens.space20,
      desktop: DesignTokens.space24,
    );
  }

  /// Get responsive screen padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    final horizontal = getHorizontalPadding(context);
    final vertical = getVerticalPadding(context);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  /// Get responsive card padding
  static EdgeInsets getCardPadding(BuildContext context) {
    return EdgeInsets.all(
      value(
        context: context,
        mobile: DesignTokens.space16,
        tablet: DesignTokens.space20,
        desktop: DesignTokens.space24,
      ),
    );
  }

  // ============================================================================
  // RESPONSIVE GRID
  // ============================================================================

  /// Get responsive column count for grid
  static int getColumnCount(
    BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? desktop,
    int? wide,
  }) {
    return value(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 2,
      desktop: desktop ?? tablet ?? mobile * 3,
      wide: wide ?? desktop ?? mobile * 4,
    );
  }

  /// Get responsive grid spacing
  static double getGridSpacing(BuildContext context) {
    return value(
      context: context,
      mobile: DesignTokens.space12,
      tablet: DesignTokens.space16,
      desktop: DesignTokens.space20,
    );
  }

  // ============================================================================
  // RESPONSIVE SIZING
  // ============================================================================

  /// Get responsive max width for content
  /// Prevents content from stretching too wide on large screens
  static double getMaxContentWidth(BuildContext context) {
    return value(
      context: context,
      mobile: double.infinity,
      tablet: 720,
      desktop: 960,
      wide: 1200,
      extraWide: 1440,
    );
  }

  /// Get responsive dialog width
  static double getDialogWidth(BuildContext context) {
    return value(
      context: context,
      mobile: MediaQuery.of(context).size.width * 0.9,
      tablet: 480,
      desktop: 560,
      wide: 640,
    );
  }

  /// Get responsive bottom sheet max height
  static double getBottomSheetMaxHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return value(
      context: context,
      mobile: screenHeight * 0.9,
      tablet: screenHeight * 0.85,
      desktop: screenHeight * 0.8,
    );
  }

  // ============================================================================
  // RESPONSIVE TYPOGRAPHY
  // ============================================================================

  /// Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    return value(
      context: context,
      mobile: 1.0,
      tablet: 1.05,
      desktop: 1.1,
      wide: 1.15,
    );
  }

  // ============================================================================
  // ORIENTATION CHECKS
  // ============================================================================

  /// Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // ============================================================================
  // SAFE AREA UTILITIES
  // ============================================================================

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Check if device has notch/dynamic island
  static bool hasNotch(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.top > 20; // Typical status bar height
  }

  // ============================================================================
  // PLATFORM UTILITIES
  // ============================================================================

  /// Get platform-specific value
  static T platformValue<T>({
    required T mobile,
    T? ios,
    T? android,
    T? web,
    T? desktop,
  }) {
    // This would need platform detection logic
    // For now, returning mobile as default
    return mobile;
  }

  // ============================================================================
  // IPAD-SPECIFIC HELPERS
  // ============================================================================

  /// Get responsive value with iPad-specific options
  ///
  /// This provides finer control for iPad sizes compared to the generic
  /// value() method. Use this when you need different values for each iPad model.
  ///
  /// Usage:
  /// ```dart
  /// final padding = Breakpoints.valueIPad(
  ///   context: context,
  ///   mobile: 16,
  ///   iPadMini: 20,
  ///   iPadAir: 24,
  ///   iPadPro: 28,
  /// );
  /// ```
  static T valueIPad<T>({
    required BuildContext context,
    required T mobile,
    T? iPadMini,
    T? iPadAir,
    T? iPadPro,
  }) {
    final width = MediaQuery.of(context).size.width;

    // Use specific iPad values if provided
    if (width >= Breakpoints.iPadPro12 && iPadPro != null) return iPadPro;
    if (width >= Breakpoints.iPadPro11 && iPadPro != null) return iPadPro;
    if (width >= Breakpoints.iPadAir && iPadAir != null) return iPadAir;
    if (width >= Breakpoints.iPadMini && iPadMini != null) return iPadMini;

    return mobile;
  }

  /// Get iPad-optimized horizontal padding
  static double getIPadHorizontalPadding(BuildContext context) {
    return valueIPad(
      context: context,
      mobile: 16,
      iPadMini: 24,
      iPadAir: 32,
      iPadPro: 40,
    );
  }

  /// Get iPad-optimized vertical padding
  static double getIPadVerticalPadding(BuildContext context) {
    return valueIPad(
      context: context,
      mobile: 16,
      iPadMini: 20,
      iPadAir: 24,
      iPadPro: 28,
    );
  }

  /// Get iPad-optimized card padding
  static EdgeInsets getIPadCardPadding(BuildContext context) {
    final horizontal = getIPadHorizontalPadding(context);
    final vertical = getIPadVerticalPadding(context);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  /// Get optimal column count for iPad grid views
  static int getIPadColumnCount(
    BuildContext context, {
    int iPhone = 1,
    int? iPadMini,
    int? iPadAir,
    int? iPadPro,
  }) {
    return valueIPad(
      context: context,
      mobile: iPhone,
      iPadMini: iPadMini ?? iPhone * 2,
      iPadAir: iPadAir ?? iPhone * 2,
      iPadPro: iPadPro ?? iPhone * 3,
    );
  }
}

/// Device type enum
enum DeviceType { mobile, tablet, desktop, wide, extraWide }

/// Extension methods for BuildContext
extension BreakpointExtensions on BuildContext {
  /// Check if mobile
  bool get isMobile => Breakpoints.isMobile(this);

  /// Check if tablet
  bool get isTablet => Breakpoints.isTablet(this);

  /// Check if desktop
  bool get isDesktop => Breakpoints.isDesktop(this);

  /// Check if wide
  bool get isWide => Breakpoints.isWide(this);

  /// Check if tablet or larger
  bool get isTabletOrLarger => Breakpoints.isTabletOrLarger(this);

  /// Check if desktop or larger
  bool get isDesktopOrLarger => Breakpoints.isDesktopOrLarger(this);

  /// Get device type
  DeviceType get deviceType => Breakpoints.getDeviceType(this);

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get responsive horizontal padding
  double get responsiveHorizontalPadding =>
      Breakpoints.getHorizontalPadding(this);

  /// Get responsive vertical padding
  double get responsiveVerticalPadding => Breakpoints.getVerticalPadding(this);

  /// Get responsive screen padding
  EdgeInsets get responsiveScreenPadding => Breakpoints.getScreenPadding(this);

  // ============================================================================
  // IPAD-SPECIFIC EXTENSIONS
  // ============================================================================

  /// Get iPad-optimized horizontal padding
  double get iPadHorizontalPadding =>
      Breakpoints.getIPadHorizontalPadding(this);

  /// Get iPad-optimized vertical padding
  double get iPadVerticalPadding => Breakpoints.getIPadVerticalPadding(this);

  /// Get iPad-optimized card padding
  EdgeInsets get iPadCardPadding => Breakpoints.getIPadCardPadding(this);
}
