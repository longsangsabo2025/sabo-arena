import 'package:flutter/material.dart';
import '../device/device_info.dart';

/// iPad-optimized typography system with automatic scaling
///
/// Provides text styles that automatically scale based on iPad model:
/// - iPad Mini: 1.12x scaling
/// - iPad Air/Pro 11": 1.18x scaling
/// - iPad Pro 12.9": 1.25x scaling
/// - iPhone: 1.0x (base size)
///
/// Usage:
/// ```dart
/// Text(
///   'Hello World',
///   style: TypographyIPad.title(context),
/// )
///
/// // Or use extension
/// Text('Body text').responsive(context)
/// ```
class TypographyIPad {
  TypographyIPad._(); // Private constructor - static class only

  // ============================================================================
  // SCALING FACTORS
  // ============================================================================

  /// Get scale factor based on iPad model
  ///
  /// - iPad Pro 12.9": 1.25x (largest screen needs largest text)
  /// - iPad Air/Pro 11": 1.18x (medium iPads)
  /// - iPad Mini: 1.12x (smaller but still larger than iPhone)
  /// - iPhone: 1.0x (base)
  static double getScaleFactor(BuildContext context) {
    if (!context.isIPad) return 1.0;

    final model = context.iPadModel;
    switch (model) {
      case IPadModel.pro12:
        return 1.25; // +25% for large Pro
      case IPadModel.pro11:
      case IPadModel.air:
        return 1.18; // +18% for standard iPads
      case IPadModel.mini:
        return 1.12; // +12% for Mini
      default:
        return 1.0;
    }
  }

  /// Get scaled font size
  static double scaledSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }

  /// Make any TextStyle responsive
  static TextStyle responsive(
    BuildContext context,
    TextStyle baseStyle,
  ) {
    final scaleFactor = getScaleFactor(context);
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * scaleFactor,
      height: baseStyle.height, // Keep line height ratio
    );
  }

  // ============================================================================
  // DISPLAY TEXT STYLES (Hero text, page titles)
  // ============================================================================

  /// Display - Largest text (hero sections, splash screens)
  /// Base: 34px | iPad Mini: 38px | iPad Air: 40px | iPad Pro: 42px
  static TextStyle display(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 34),
      fontWeight: FontWeight.bold,
      height: 1.2,
      letterSpacing: -0.5,
      color: color,
    );
  }

  /// Display Medium - Large hero text
  /// Base: 28px | iPad Mini: 31px | iPad Air: 33px | iPad Pro: 35px
  static TextStyle displayMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 28),
      fontWeight: FontWeight.bold,
      height: 1.25,
      letterSpacing: -0.4,
      color: color,
    );
  }

  // ============================================================================
  // HEADLINE TEXT STYLES (Page headers, section titles)
  // ============================================================================

  /// Headline - Page titles, screen headers
  /// Base: 22px | iPad Mini: 25px | iPad Air: 26px | iPad Pro: 28px
  static TextStyle headline(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 22),
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.3,
      color: color,
    );
  }

  /// Headline Small - Sub-headers
  /// Base: 20px | iPad Mini: 22px | iPad Air: 24px | iPad Pro: 25px
  static TextStyle headlineSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 20),
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.2,
      color: color,
    );
  }

  // ============================================================================
  // TITLE TEXT STYLES (Card titles, section labels)
  // ============================================================================

  /// Title Large - Card headers, list section headers
  /// Base: 18px | iPad Mini: 20px | iPad Air: 21px | iPad Pro: 22px
  static TextStyle titleLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 18),
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: -0.1,
      color: color,
    );
  }

  /// Title - Standard titles
  /// Base: 16px | iPad Mini: 18px | iPad Air: 19px | iPad Pro: 20px
  static TextStyle title(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 16),
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: color,
    );
  }

  /// Title Small - Small card titles
  /// Base: 14px | iPad Mini: 16px | iPad Air: 17px | iPad Pro: 18px
  static TextStyle titleSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 14),
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: color,
    );
  }

  // ============================================================================
  // BODY TEXT STYLES (Main content, paragraphs)
  // ============================================================================

  /// Body Large - Important body text, callouts
  /// Base: 17px | iPad Mini: 19px | iPad Air: 20px | iPad Pro: 21px
  static TextStyle bodyLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 17),
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: -0.1,
      color: color,
    );
  }

  /// Body - Standard body text, most common
  /// Base: 15px | iPad Mini: 17px | iPad Air: 18px | iPad Pro: 19px
  static TextStyle body(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 15),
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: color,
    );
  }

  /// Body Medium - Slightly emphasized body
  /// Base: 15px | iPad Mini: 17px | iPad Air: 18px | iPad Pro: 19px
  static TextStyle bodyMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 15),
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: color,
    );
  }

  /// Body Small - Secondary body text
  /// Base: 13px | iPad Mini: 15px | iPad Air: 15px | iPad Pro: 16px
  static TextStyle bodySmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 13),
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: color ?? Colors.grey[600],
    );
  }

  // ============================================================================
  // LABEL TEXT STYLES (Form labels, metadata)
  // ============================================================================

  /// Label - Form labels, input labels
  /// Base: 14px | iPad Mini: 16px | iPad Air: 17px | iPad Pro: 18px
  static TextStyle label(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 14),
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: color,
    );
  }

  /// Label Small - Small labels, metadata
  /// Base: 12px | iPad Mini: 13px | iPad Air: 14px | iPad Pro: 15px
  static TextStyle labelSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 12),
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: color ?? Colors.grey[600],
    );
  }

  // ============================================================================
  // CAPTION TEXT STYLES (Hints, footnotes, timestamps)
  // ============================================================================

  /// Caption - Hints, help text, timestamps
  /// Base: 13px | iPad Mini: 15px | iPad Air: 15px | iPad Pro: 16px
  static TextStyle caption(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 13),
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: color ?? Colors.grey[600],
    );
  }

  /// Caption Small - Fine print, very small text
  /// Base: 11px | iPad Mini: 12px | iPad Air: 13px | iPad Pro: 14px
  static TextStyle captionSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 11),
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: color ?? Colors.grey[500],
    );
  }

  // ============================================================================
  // BUTTON TEXT STYLES
  // ============================================================================

  /// Button Large - Large action buttons
  /// Base: 17px | iPad Mini: 19px | iPad Air: 20px | iPad Pro: 21px
  static TextStyle buttonLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 17),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: color,
    );
  }

  /// Button - Standard button text
  /// Base: 15px | iPad Mini: 17px | iPad Air: 18px | iPad Pro: 19px
  static TextStyle button(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 15),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: color,
    );
  }

  /// Button Small - Small buttons, tertiary actions
  /// Base: 13px | iPad Mini: 15px | iPad Air: 15px | iPad Pro: 16px
  static TextStyle buttonSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 13),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: color,
    );
  }

  // ============================================================================
  // SPECIAL TEXT STYLES
  // ============================================================================

  /// Overline - All caps labels, categories
  /// Base: 11px | iPad Mini: 12px | iPad Air: 13px | iPad Pro: 14px
  static TextStyle overline(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 11),
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      color: color ?? Colors.grey[700],
    );
  }

  /// Code/Monospace - Code blocks, terminal output
  /// Base: 13px | iPad Mini: 15px | iPad Air: 15px | iPad Pro: 16px
  static TextStyle code(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: scaledSize(context, 13),
      fontWeight: FontWeight.w400,
      fontFamily: 'Courier',
      height: 1.5,
      color: color,
    );
  }
}

// ============================================================================
// EXTENSION METHODS
// ============================================================================

/// Extension on Text widget for easy responsive styling
extension TextIPadExtension on Text {
  /// Make text responsive to iPad screen sizes
  ///
  /// Usage:
  /// ```dart
  /// Text('Hello').responsive(context)
  /// ```
  Text responsiveIPad(BuildContext context) {
    return Text(
      data ?? '',
      key: key,
      style: style != null
          ? TypographyIPad.responsive(context, style!)
          : TypographyIPad.body(context),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      softWrap: softWrap,
      textDirection: textDirection,
      textScaler: textScaler,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

/// Extension on BuildContext for quick typography access
extension TypographyContextExtension on BuildContext {
  /// Get scale factor for current device
  double get textScaleFactor => TypographyIPad.getScaleFactor(this);

  /// Scale a font size for current device
  double scaleFont(double baseSize) =>
      TypographyIPad.scaledSize(this, baseSize);
}
