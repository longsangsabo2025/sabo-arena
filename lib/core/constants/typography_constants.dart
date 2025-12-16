import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../design_system/design_tokens.dart';

/// Typography system constants using Inter font family
/// Consistent with modern design standards (SF Pro equivalent)
///
/// Now uses DesignTokens for letter spacing and line heights
class AppTypography {
  // ============================================================================
  // HEADINGS
  // ============================================================================

  /// Main page titles, hero text
  /// Size: 28, Weight: Bold (w700)
  static TextStyle heading1({
    Color color = Colors.white,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: DesignTokens.letterSpacingWide,
      height: DesignTokens.lineHeightTight,
      shadows: shadows ?? _defaultShadow,
    );
  }

  /// Section titles, card headers
  /// Size: 24, Weight: Bold (w700)
  static TextStyle heading2({
    Color color = Colors.white,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: DesignTokens.letterSpacingWide,
      height: DesignTokens.lineHeightTight,
      shadows: shadows ?? _defaultShadow,
    );
  }

  /// Subsection titles
  /// Size: 20, Weight: SemiBold (w600)
  static TextStyle heading3({
    Color color = Colors.white,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: DesignTokens.letterSpacingRelaxed,
      height: DesignTokens.lineHeightNormal,
      shadows: shadows,
    );
  }

  // ============================================================================
  // BODY TEXT
  // ============================================================================

  /// Primary body text, descriptions
  /// Size: 16, Weight: Regular (w400)
  static TextStyle bodyLarge({Color? color, List<Shadow>? shadows}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color ?? Colors.white.withValues(alpha: DesignTokens.opacity90),
      letterSpacing: DesignTokens.letterSpacingRelaxed,
      height: DesignTokens.lineHeightRelaxed,
      shadows: shadows,
    );
  }

  /// Secondary body text
  /// Size: 15, Weight: Regular (w400) - Increased for better readability
  static TextStyle bodyMedium({Color? color, List<Shadow>? shadows}) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: color ?? Colors.white.withValues(alpha: DesignTokens.opacity80),
      letterSpacing: DesignTokens.letterSpacingRelaxed,
      height: DesignTokens.lineHeightRelaxed,
      shadows: shadows,
    );
  }

  /// Small text, captions
  /// Size: 14, Weight: Regular (w400) - Increased from 12
  static TextStyle bodySmall({Color? color, List<Shadow>? shadows}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color ?? Colors.white.withValues(alpha: DesignTokens.opacity70),
      letterSpacing: DesignTokens.letterSpacingRelaxed,
      height: DesignTokens.lineHeightNormal,
      shadows: shadows,
    );
  }

  // ============================================================================
  // BUTTONS & CTAs
  // ============================================================================

  /// Primary button text
  /// Size: 18, Weight: SemiBold (w600)
  static TextStyle button({Color color = Colors.white, List<Shadow>? shadows}) {
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: DesignTokens.letterSpacingRelaxed,
      height: DesignTokens.lineHeightTight,
      shadows: shadows ?? _buttonShadow,
    );
  }

  /// Secondary/smaller button text
  /// Size: 16, Weight: SemiBold (w600)
  static TextStyle buttonSmall({
    Color color = Colors.white,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: DesignTokens.letterSpacingRelaxed,
      height: DesignTokens.lineHeightTight,
      shadows: shadows,
    );
  }

  // ============================================================================
  // FORM INPUTS
  // ============================================================================

  /// Input field text
  /// Size: 16, Weight: Regular (w400)
  static TextStyle input({Color color = Colors.black87}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color,
      letterSpacing: DesignTokens.letterSpacingRelaxed,
      height: DesignTokens.lineHeightRelaxed,
    );
  }

  /// Input field labels
  /// Size: 15, Weight: Medium (w500) - Increased for better visibility
  static TextStyle inputLabel({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: color ?? Colors.grey[700],
      letterSpacing: DesignTokens.letterSpacingRelaxed,
    );
  }

  /// Input field hints/placeholders
  /// Size: 15, Weight: Regular (w400) - Increased for better readability
  static TextStyle inputHint({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: color ?? Colors.grey[400],
      letterSpacing: DesignTokens.letterSpacingRelaxed,
    );
  }

  /// Input field helper/error text
  /// Size: 13sp, Weight: Regular (w400) - Increased from 12sp
  static TextStyle inputHelper({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 13.sp,
      fontWeight: FontWeight.w400,
      color: color ?? Colors.grey[600],
      letterSpacing: 0.2,
    );
  }

  // ============================================================================
  // SPECIAL TEXT
  // ============================================================================

  /// Subtitle text (under titles)
  /// Size: 16, Weight: Regular (w400)
  static TextStyle subtitle({Color? color, List<Shadow>? shadows}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color ?? Colors.white.withValues(alpha: DesignTokens.opacity80),
      letterSpacing: DesignTokens.letterSpacingRelaxed,
      height: DesignTokens.lineHeightNormal,
      shadows: shadows ?? _subtleShadow,
    );
  }

  /// Link text
  /// Size: 15, Weight: Medium (w500) - Increased for better tap target
  static TextStyle link({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: color ?? Colors.blue[600],
      letterSpacing: DesignTokens.letterSpacingRelaxed,
      decoration: TextDecoration.underline,
    );
  }

  /// Badge/chip text
  /// Size: 13, Weight: SemiBold (w600) - Increased from 12
  static TextStyle badge({Color color = Colors.white}) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: DesignTokens.letterSpacingRelaxed,
    );
  }

  /// Numbers, stats
  /// Size: 24, Weight: Bold (w700)
  static TextStyle number({Color color = Colors.white, List<Shadow>? shadows}) {
    return GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: DesignTokens.letterSpacingRelaxed,
      height: DesignTokens.lineHeightTight,
      shadows: shadows,
    );
  }

  // ============================================================================
  // DEFAULT SHADOWS (Using DesignTokens opacity)
  // ============================================================================

  static final List<Shadow> _defaultShadow = [
    Shadow(
      offset: const Offset(0, 2),
      blurRadius: 4,
      color: Colors.black.withValues(alpha: DesignTokens.opacity10),
    ),
  ];

  static final List<Shadow> _subtleShadow = [
    Shadow(
      offset: const Offset(0, 1),
      blurRadius: 2,
      color: Colors.black.withValues(alpha: DesignTokens.opacity8),
    ),
  ];

  static final List<Shadow> _buttonShadow = [
    Shadow(
      offset: const Offset(0, 1),
      blurRadius: 2,
      color: Colors.black.withValues(alpha: DesignTokens.opacity12),
    ),
  ];
}
