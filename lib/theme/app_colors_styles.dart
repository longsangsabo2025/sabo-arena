import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'app_theme.dart';

// AppColors class for color constants
class AppColors {
  static const Color primaryColor = AppTheme.primaryLight;
  static const Color secondaryColor = AppTheme.secondaryLight;
  static const Color backgroundColor = AppTheme.backgroundLight;
  static const Color surfaceColor = AppTheme.surfaceLight;
  static const Color errorColor = AppTheme.errorLight;
  static const Color successColor = AppTheme.successLight;
  static const Color warningColor = AppTheme.warningLight;

  // Additional colors for widgets
  static const Color green = Color(0xFF2E7D32);
  static const Color red = Color(0xFFD32F2F);
  static const Color blue = Color(0xFF1976D2);
  static const Color purple = Color(0xFF9C27B0);
  static const Color orange = Color(0xFFFF6F00);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);

  // Primary color alias
  static const Color primary = primaryColor;
}

// AppTheme helper for modern color palette
class appTheme {
  static const Color blue50 = Color(0xFFE3F2FD);
  static const Color blue200 = Color(0xFF90CAF9);
  static const Color blue600 = Color(0xFF1976D2);
  static const Color blue700 = Color(0xFF1565C0);
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray900 = Color(0xFF212121);
  static const Color black900 = Color(0xFF000000);
  static const Color red600 = Color(0xFFD32F2F);
  static const Color green50 = Color(0xFFE8F5E9);
  static const Color green600 = Color(0xFF2E7D32);
  static const Color orange600 = Color(0xFFFF6F00);
  static const Color purple600 = Color(0xFF9C27B0);
  static const Color teal600 = Color(0xFF00897B);
  static const Color indigo600 = Color(0xFF3F51B5);
  static const Color pink600 = Color(0xFFE91E63);
}

// AppDecoration for container decorations
class AppDecoration {
  static BoxDecoration get fillWhite => BoxDecoration(color: Colors.white);
}

// BorderRadiusStyle for consistent border radius
class BorderRadiusStyle {
  static BorderRadius get roundedBorder16 => BorderRadius.circular(16);
  static BorderRadius get roundedBorder8 => BorderRadius.circular(8);
  static BorderRadius get roundedBorder12 => BorderRadius.circular(12);
  static BorderRadius get roundedBorder24 => BorderRadius.circular(24);
}

// CustomTextStyles class for text styling
// ⚠️ DEPRECATED: Use AppTypography from core/design_system/typography.dart
//
// Migration guide:
// - CustomTextStyles.bodyMedium → AppTypography.bodyMedium
// - CustomTextStyles.titleMedium → AppTypography.headingXSmall
// - CustomTextStyles.titleLarge → AppTypography.headingSmall
// - CustomTextStyles.headlineSmall → AppTypography.headingMedium
@Deprecated('Use AppTypography from core/design_system/typography.dart')
class CustomTextStyles {
  @Deprecated('Use AppTypography.bodyMedium')
  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppTheme.onBackgroundLight,
  );

  @Deprecated('Use AppTypography.headingXSmall')
  static TextStyle get titleMedium => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: AppTheme.onBackgroundLight,
  );

  @Deprecated('Use AppTypography.headingSmall')
  static TextStyle get titleLarge => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: AppTheme.onBackgroundLight,
  );

  @Deprecated('Use AppTypography.headingMedium')
  static TextStyle get headlineSmall => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    color: AppTheme.onBackgroundLight,
  );
}
