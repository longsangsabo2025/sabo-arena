/// Typography System - Text Styles
///
/// Complete typography scale following Instagram/Facebook standards:
/// - Display styles (hero text, titles)
/// - Heading styles (section titles)
/// - Body styles (paragraphs, content)
/// - Label styles (buttons, chips)
/// - Caption styles (metadata, timestamps)
///
/// All text styles use Inter font family (or SF Pro for iOS feel)
/// with proper weights, line heights, and letter spacing

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system for SABO ARENA
///
/// All text across the app should use these predefined styles
/// to ensure visual consistency and readability
class AppTypography {
  AppTypography._(); // Private constructor

  // ============================================================================
  // FONT FAMILY
  // ============================================================================

  /// Primary font family - Inter (clean, modern, highly readable)
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  /// Fallback fonts for different platforms
  static const List<String> fontFallbacks = [
    'SF Pro Display',
    'SF Pro Text',
    'Roboto',
    'Helvetica Neue',
    'Arial',
  ];

  // ============================================================================
  // FONT WEIGHTS
  // ============================================================================

  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // ============================================================================
  // DISPLAY STYLES (Hero Text, Large Titles)
  // ============================================================================

  /// Display Large - 48px, Bold
  /// Usage: Hero sections, splash screens
  static final TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: bold,
    height: 1.2, // 57.6px line height
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// Display Medium - 40px, Bold
  /// Usage: Large page titles
  static final TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: bold,
    height: 1.2, // 48px line height
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  /// Display Small - 32px, Bold
  /// Usage: Section headers, modal titles
  static final TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: bold,
    height: 1.25, // 40px line height
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  // ============================================================================
  // HEADING STYLES (Section Titles)
  // ============================================================================

  /// Heading Large - 28px, Bold
  /// Usage: Page titles, card headers
  static final TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: bold,
    height: 1.3, // 36.4px line height
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// Heading Medium - 24px, SemiBold
  /// Usage: Section titles, dialog titles
  static final TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.3, // 31.2px line height
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// Heading Small - 20px, SemiBold
  /// Usage: Card titles, list section headers
  static final TextStyle headingSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.4, // 28px line height
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  /// Heading XSmall - 18px, SemiBold
  /// Usage: Small section headers, emphasized text
  static final TextStyle headingXSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.4, // 25.2px line height
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  // ============================================================================
  // BODY STYLES (Content, Paragraphs)
  // ============================================================================

  /// Body Large - 17px, Regular
  /// Usage: Large body text, important content
  static final TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: regular,
    height: 1.5, // 25.5px line height
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Body Large Medium - 17px, Medium
  /// Usage: Emphasized body text
  static final TextStyle bodyLargeMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: medium,
    height: 1.5, // 25.5px line height
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Body Medium - 15px, Regular (DEFAULT)
  /// Usage: Standard body text, paragraphs, descriptions
  static final TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: regular,
    height: 1.5, // 22.5px line height
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Body Medium Medium - 15px, Medium
  /// Usage: Emphasized paragraphs, usernames
  static final TextStyle bodyMediumMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: medium,
    height: 1.5, // 22.5px line height
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Body Small - 13px, Regular
  /// Usage: Secondary text, descriptions
  static final TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: regular,
    height: 1.5, // 19.5px line height
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  /// Body Small Medium - 13px, Medium
  /// Usage: Emphasized small text
  static final TextStyle bodySmallMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: medium,
    height: 1.5, // 19.5px line height
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  // ============================================================================
  // LABEL STYLES (Buttons, Chips, Tags)
  // ============================================================================

  /// Label Large - 16px, SemiBold
  /// Usage: Large buttons, tabs
  static final TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.25, // 20px line height
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  /// Label Medium - 14px, SemiBold (DEFAULT for buttons)
  /// Usage: Standard buttons, chips
  static final TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: semiBold,
    height: 1.3, // 18.2px line height
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  /// Label Small - 12px, SemiBold
  /// Usage: Small buttons, badges
  static final TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: semiBold,
    height: 1.3, // 15.6px line height
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  /// Label XSmall - 11px, SemiBold
  /// Usage: Tiny badges, indicators
  static final TextStyle labelXSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: semiBold,
    height: 1.3, // 14.3px line height
    letterSpacing: 0.3,
    color: AppColors.textPrimary,
  );

  // ============================================================================
  // CAPTION STYLES (Metadata, Timestamps)
  // ============================================================================

  /// Caption Large - 13px, Regular
  /// Usage: Large captions, metadata
  static final TextStyle captionLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: regular,
    height: 1.4, // 18.2px line height
    letterSpacing: 0,
    color: AppColors.textTertiary,
  );

  /// Caption Medium - 12px, Regular (DEFAULT for metadata)
  /// Usage: Timestamps, post metadata, hints
  static final TextStyle captionMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: regular,
    height: 1.4, // 16.8px line height
    letterSpacing: 0,
    color: AppColors.textTertiary,
  );

  /// Caption Small - 11px, Regular
  /// Usage: Fine print, legal text
  static final TextStyle captionSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: regular,
    height: 1.4, // 15.4px line height
    letterSpacing: 0,
    color: AppColors.textTertiary,
  );

  /// Caption XSmall - 10px, Regular
  /// Usage: Extra small metadata
  static final TextStyle captionXSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: regular,
    height: 1.4, // 14px line height
    letterSpacing: 0.1,
    color: AppColors.textTertiary,
  );

  // ============================================================================
  // UTILITY STYLES
  // ============================================================================

  /// Link style - inherits from body but with primary color and underline
  static final TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );

  /// Link small style
  static final TextStyle linkSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );

  /// Code style - monospace font
  static const TextStyle code = TextStyle(
    fontFamily: 'Courier New',
    fontSize: 14,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    backgroundColor: AppColors.gray100,
  );

  /// Overline style - all caps, small, spaced out
  static final TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Apply size to any text style
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Apply primary color
  static TextStyle primary(TextStyle style) {
    return style.copyWith(color: AppColors.primary);
  }

  /// Apply secondary color
  static TextStyle secondary(TextStyle style) {
    return style.copyWith(color: AppColors.textSecondary);
  }

  /// Apply tertiary color
  static TextStyle tertiary(TextStyle style) {
    return style.copyWith(color: AppColors.textTertiary);
  }

  /// Apply error color
  static TextStyle error(TextStyle style) {
    return style.copyWith(color: AppColors.error);
  }

  /// Apply success color
  static TextStyle success(TextStyle style) {
    return style.copyWith(color: AppColors.success);
  }

  /// Apply warning color
  static TextStyle warning(TextStyle style) {
    return style.copyWith(color: AppColors.warning);
  }

  /// Apply white color
  static TextStyle white(TextStyle style) {
    return style.copyWith(color: AppColors.surface);
  }
}
