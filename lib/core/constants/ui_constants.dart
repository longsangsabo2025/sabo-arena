import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../design_system/design_tokens.dart';
import '../design_system/app_colors.dart' as ds_colors;

/// UI Constants for consistent sizing and spacing
/// Based on Sizer responsive units + DesignTokens
///
/// NOTE: Prefer using DesignTokens directly for fixed values
/// Use AppSizing for responsive values (Sizer-based)
class AppSizing {
  // ============================================================================
  // LOGO & IMAGES
  // ============================================================================

  /// Large logo (onboarding, splash)
  static double logoLarge = 30.w;

  /// Medium logo (login, register)
  static double logoMedium = 28.w;

  /// Small logo (headers, app bar)
  static double logoSmall = 20.w;

  /// Profile avatar size
  static double avatar = 20.w;

  // ============================================================================
  // SPACING (Vertical & Horizontal)
  // ============================================================================

  /// Extra small spacing (between related items)
  static double spaceXS = 0.5.h;

  /// Small spacing
  static double spaceSM = 1.h;

  /// Medium spacing (between sections)
  static double spaceMD = 2.h;

  /// Large spacing
  static double spaceLG = 3.h;

  /// Extra large spacing (between major sections)
  static double spaceXL = 4.h;

  /// Massive spacing (screen padding top/bottom)
  static double spaceXXL = 6.h;

  // ============================================================================
  // PADDING
  // ============================================================================

  /// Screen edge padding
  static double screenPadding = 4.w;

  /// Card padding
  static double cardPadding = 4.w;

  /// Button padding vertical
  static double buttonPaddingV = 2.h;

  /// Button padding horizontal
  static double buttonPaddingH = 6.w;

  // ============================================================================
  // BORDER RADIUS (Now using DesignTokens)
  // ============================================================================

  /// Small radius (badges, chips) - Use DesignTokens.radiusSM instead
  @Deprecated('Use DesignTokens.radiusSM instead')
  static double radiusXS = DesignTokens.radiusSM;

  /// Small radius (buttons, inputs) - Use DesignTokens.radiusSM instead
  @Deprecated('Use DesignTokens.radiusSM instead')
  static double radiusSM = DesignTokens.radiusSM;

  /// Medium radius (cards) - Use DesignTokens.radiusMD instead
  @Deprecated('Use DesignTokens.radiusMD instead')
  static double radiusMD = DesignTokens.radiusMD;

  /// Large radius (modals, dialogs) - Use DesignTokens.radiusLG instead
  @Deprecated('Use DesignTokens.radiusLG instead')
  static double radiusLG = DesignTokens.radiusLG;

  /// Extra large radius (special cards) - Use DesignTokens.radiusXL instead
  @Deprecated('Use DesignTokens.radiusXL instead')
  static double radiusXL = DesignTokens.radiusXL;

  /// Circle - Use DesignTokens.radiusFull instead
  @Deprecated('Use DesignTokens.radiusFull instead')
  static double radiusCircle = DesignTokens.radiusFull;

  // ============================================================================
  // ICON SIZES (Now using DesignTokens)
  // ============================================================================

  /// Small icon - Use DesignTokens.iconSM instead
  @Deprecated('Use DesignTokens.iconSM instead')
  static double iconSM = DesignTokens.iconSM;

  /// Medium icon - Use DesignTokens.iconMD instead
  @Deprecated('Use DesignTokens.iconMD instead')
  static double iconMD = DesignTokens.iconMD;

  /// Large icon - Use DesignTokens.iconLG instead
  @Deprecated('Use DesignTokens.iconLG instead')
  static double iconLG = DesignTokens.iconLG;

  /// Extra large icon - Use DesignTokens.iconXXL instead
  @Deprecated('Use DesignTokens.iconXXL instead')
  static double iconXL = DesignTokens.iconXXL;

  // ============================================================================
  // BUTTON HEIGHTS
  // ============================================================================

  /// Small button
  static double buttonHeightSM = 5.h;

  /// Medium button (default)
  static double buttonHeightMD = 6.h;

  /// Large button
  static double buttonHeightLG = 7.h;

  // ============================================================================
  // CONTAINER CONSTRAINTS
  // ============================================================================

  /// Maximum width for content (tablets/web)
  static double maxContentWidth = 600.0;

  /// Card minimum height
  static double cardMinHeight = 12.h;

  // ============================================================================
  // ELEVATION & SHADOWS (Now using DesignTokens)
  // ============================================================================

  /// Small elevation - Use DesignTokens.elevation2 instead
  @Deprecated('Use DesignTokens.elevation2 instead')
  static double elevationSM = DesignTokens.elevation2;

  /// Medium elevation - Use DesignTokens.elevation4 instead
  @Deprecated('Use DesignTokens.elevation4 instead')
  static double elevationMD = DesignTokens.elevation4;

  /// Large elevation - Use DesignTokens.elevation8 instead
  @Deprecated('Use DesignTokens.elevation8 instead')
  static double elevationLG = DesignTokens.elevation8;

  // ============================================================================
  // EDGE INSETS (Common Paddings)
  // ============================================================================

  static EdgeInsets get screenPaddingAll => EdgeInsets.all(screenPadding);

  static EdgeInsets get screenPaddingHorizontal =>
      EdgeInsets.symmetric(horizontal: screenPadding);

  static EdgeInsets get cardPaddingAll => EdgeInsets.all(cardPadding);

  static EdgeInsets get buttonPadding => EdgeInsets.symmetric(
        vertical: buttonPaddingV,
        horizontal: buttonPaddingH,
      );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Custom spacing (multiplier of base unit)
  static double space(double multiplier) => multiplier.h;

  /// Custom width spacing
  static double spaceW(double multiplier) => multiplier.w;
}

/// Color constants (DEPRECATED - Use design_system/app_colors.dart instead)
///
/// This class is kept for backward compatibility but should not be used in new code.
/// Migrate to: import 'package:sabo_arena/core/design_system/app_colors.dart';
@Deprecated('Use AppColors from design_system/app_colors.dart instead')
class AppColors {
  @Deprecated('Use AppColors.white from design_system/app_colors.dart')
  static const Color white = ds_colors.AppColors.white;

  @Deprecated('Use AppColors.black from design_system/app_colors.dart')
  static const Color black = ds_colors.AppColors.black;

  @Deprecated('Use AppColors.textOnPrimary from design_system/app_colors.dart')
  static const Color textOnPrimary = ds_colors.AppColors.textOnPrimary;

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  @Deprecated('Use AppColors.success from design_system/app_colors.dart')
  static const Color success = ds_colors.AppColors.success;

  @Deprecated('Use AppColors.warning from design_system/app_colors.dart')
  static const Color warning = ds_colors.AppColors.warning;

  @Deprecated('Use AppColors.error from design_system/app_colors.dart')
  static const Color error = ds_colors.AppColors.error;

  @Deprecated('Use AppColors.info from design_system/app_colors.dart')
  static const Color info = ds_colors.AppColors.info;

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  @Deprecated('Use AppColors.textPrimary from design_system/app_colors.dart')
  static const Color textPrimary = ds_colors.AppColors.textPrimary;

  @Deprecated('Use AppColors.textSecondary from design_system/app_colors.dart')
  static const Color textSecondary = ds_colors.AppColors.textSecondary;

  @Deprecated('Use AppColors.gray400 from design_system/app_colors.dart')
  static const Color textHint = ds_colors.AppColors.gray400;

  @Deprecated(
    'Use AppColors.textPrimaryDark from design_system/app_colors.dart',
  )
  static const Color textInverse = Colors.white;

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================

  @Deprecated('Use AppColors.background from design_system/app_colors.dart')
  static const Color backgroundLight = ds_colors.AppColors.background;

  @Deprecated('Use AppColors.backgroundDark from design_system/app_colors.dart')
  static const Color backgroundDark = ds_colors.AppColors.backgroundDark;

  @Deprecated('Use AppColors.surface from design_system/app_colors.dart')
  static const Color surface = ds_colors.AppColors.surface;

  @Deprecated('Use AppColors.surfaceDark from design_system/app_colors.dart')
  static const Color surfaceDark = ds_colors.AppColors.surfaceDark;

  // ============================================================================
  // OVERLAY & SHADOW COLORS
  // ============================================================================

  @Deprecated('Use AppColors.blackOverlay() from design_system/app_colors.dart')
  static Color overlay({double opacity = 0.5}) =>
      ds_colors.AppColors.blackOverlay(opacity);

  @Deprecated('Use AppColors.blackOverlay() from design_system/app_colors.dart')
  static Color shadowLight({double opacity = 0.1}) =>
      ds_colors.AppColors.blackOverlay(opacity);

  @Deprecated('Use AppColors.blackOverlay() from design_system/app_colors.dart')
  static Color shadowDark({double opacity = 0.3}) =>
      ds_colors.AppColors.blackOverlay(opacity);
}

/// Animation durations (DEPRECATED - Use DesignTokens instead)
@Deprecated('Use DesignTokens.durationFast, durationNormal, etc. instead')
class AppDurations {
  @Deprecated('Use DesignTokens.durationFast instead')
  static const Duration fast = DesignTokens.durationFast;

  @Deprecated('Use DesignTokens.durationNormal instead')
  static const Duration normal = DesignTokens.durationNormal;

  @Deprecated('Use DesignTokens.durationSlow instead')
  static const Duration slow = DesignTokens.durationSlow;

  @Deprecated('Use DesignTokens.durationMedium instead')
  static const Duration pageTransition = DesignTokens.durationMedium;
}
