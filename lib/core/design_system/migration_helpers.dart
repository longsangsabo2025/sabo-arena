/// Migration Helpers for Font System Migration
///
/// Utilities to help migrate from old design system to new iOS Facebook design
///
/// Usage:
/// 1. Use TypographyMigration.mapOldStyle() to convert old styles
/// 2. Use ColorMigration.mapOldColor() to convert old colors
/// 3. Replace .sp with fixed sizes using SizerMigration

import 'package:flutter/material.dart';
import 'typography.dart';
import 'app_colors.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Helper class for migrating typography styles
class TypographyMigration {
  TypographyMigration._();

  /// Map old CustomTextStyles to new AppTypography
  ///
  /// Example:
  /// ```dart
  /// // Old: CustomTextStyles.bodyMedium
  /// // New: TypographyMigration.bodyMedium
  /// ```
  static TextStyle get bodyMedium => AppTypography.bodyMedium;
  static TextStyle get titleMedium => AppTypography.headingXSmall;
  static TextStyle get titleLarge => AppTypography.headingSmall;
  static TextStyle get headlineSmall => AppTypography.headingMedium;

  /// Map Sizer font sizes to AppTypography styles
  static TextStyle fromSizerSize(double sp) {
    if (sp <= 10) return AppTypography.captionXSmall;
    if (sp <= 11) return AppTypography.captionSmall;
    if (sp <= 12) return AppTypography.captionMedium;
    if (sp <= 13) return AppTypography.bodySmall;
    if (sp <= 14) return AppTypography.labelMedium;
    if (sp <= 15) return AppTypography.bodyMedium;
    if (sp <= 16) return AppTypography.labelLarge;
    if (sp <= 17) return AppTypography.bodyLarge;
    if (sp <= 18) return AppTypography.headingXSmall;
    if (sp <= 20) return AppTypography.headingSmall;
    if (sp <= 24) return AppTypography.headingMedium;
    if (sp <= 28) return AppTypography.headingLarge;
    if (sp <= 32) return AppTypography.displaySmall;
    if (sp <= 40) return AppTypography.displayMedium;
    return AppTypography.displayLarge;
  }

  /// Quick reference map for common migrations
  static const Map<String, String> migrationMap = {
    'CustomTextStyles.bodyMedium': 'AppTypography.bodyMedium',
    'CustomTextStyles.titleMedium': 'AppTypography.headingXSmall',
    'CustomTextStyles.titleLarge': 'AppTypography.headingSmall',
    'CustomTextStyles.headlineSmall': 'AppTypography.headingMedium',
  };
}

/// Helper class for migrating colors
class ColorMigration {
  ColorMigration._();

  /// Map old AppTheme colors to new AppColors
  static Color get primaryLight => AppColors.primary;
  static Color get secondaryLight => AppColors.secondary;
  static Color get backgroundLight => AppColors.background;
  static Color get surfaceLight => AppColors.surface;
  static Color get errorLight => AppColors.error;
  static Color get successLight => AppColors.success;
  static Color get warningLight => AppColors.warning;
  static Color get onBackgroundLight => AppColors.textPrimary;
  static Color get onSurfaceLight => AppColors.textPrimary;

  /// Quick reference map for color migrations
  static const Map<String, String> migrationMap = {
    'AppTheme.primaryLight': 'AppColors.primary',
    'AppTheme.secondaryLight': 'AppColors.secondary',
    'AppTheme.backgroundLight': 'AppColors.background',
    'AppTheme.surfaceLight': 'AppColors.surface',
    'AppTheme.errorLight': 'AppColors.error',
    'AppTheme.successLight': 'AppColors.success',
    'AppTheme.warningLight': 'AppColors.warning',
    'AppTheme.onBackgroundLight': 'AppColors.textPrimary',
    'AppTheme.onSurfaceLight': 'AppColors.textPrimary',
  };
}

/// Helper for converting Sizer (.sp) to fixed sizes
class SizerMigration {
  SizerMigration._();

  /// Convert .sp to fixed pixel size
  ///
  /// Note: Sizer uses responsive sizing, but new design system uses fixed sizes
  /// This is a 1:1 conversion assuming base size
  static double toFixed(double sp) => sp;

  /// Recommended AppTypography style for given .sp size
  static String recommendedStyle(double sp) {
    if (sp <= 10) return 'AppTypography.captionXSmall';
    if (sp <= 11) return 'AppTypography.captionSmall';
    if (sp <= 12) return 'AppTypography.captionMedium';
    if (sp <= 13) return 'AppTypography.bodySmall';
    if (sp <= 14) return 'AppTypography.labelMedium';
    if (sp <= 15) return 'AppTypography.bodyMedium';
    if (sp <= 16) return 'AppTypography.labelLarge';
    if (sp <= 17) return 'AppTypography.bodyLarge';
    if (sp <= 18) return 'AppTypography.headingXSmall';
    if (sp <= 20) return 'AppTypography.headingSmall';
    if (sp <= 24) return 'AppTypography.headingMedium';
    if (sp <= 28) return 'AppTypography.headingLarge';
    if (sp <= 32) return 'AppTypography.displaySmall';
    if (sp <= 40) return 'AppTypography.displayMedium';
    return 'AppTypography.displayLarge';
  }
}

/// Extension methods for easy migration
extension TextStyleMigrationExtension on TextStyle {
  /// Convert to new design system with color
  TextStyle withNewColor(Color color) {
    return copyWith(color: color, fontFamily: AppTypography.fontFamily);
  }

  /// Ensure using Inter font family
  TextStyle withInterFont() {
    return copyWith(fontFamily: AppTypography.fontFamily);
  }
}

/// Migration checklist for developers
class MigrationChecklist {
  static const List<String> steps = [
    '1. Replace imports: Remove sizer, app_colors_styles',
    '2. Add imports: typography.dart, app_colors.dart',
    '3. Replace CustomTextStyles with AppTypography',
    '4. Replace .sp with fixed sizes or AppTypography styles',
    '5. Replace AppTheme colors with AppColors',
    '6. Test visual consistency',
    '7. Verify on different screen sizes',
  ];

  static void printChecklist() {
    ProductionLogger.info('=== MIGRATION CHECKLIST ===', tag: 'migration_helpers');
    for (final step in steps) {
      ProductionLogger.info(step, tag: 'migration_helpers');
    }
    ProductionLogger.info('===========================', tag: 'migration_helpers');
  }
}
