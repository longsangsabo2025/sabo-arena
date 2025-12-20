import 'package:flutter/material.dart';
import '../device/device_info.dart';

/// iPad-optimized spacing system with automatic scaling
///
/// Provides spacing values that automatically scale based on iPad model:
/// - iPad Mini: 1.15x scaling
/// - iPad Air/Pro 11": 1.25x scaling
/// - iPad Pro 12.9": 1.4x scaling
/// - iPhone: 1.0x (base size)
///
/// This creates more comfortable spacing on larger screens while maintaining
/// proportions and visual hierarchy.
///
/// Usage:
/// ```dart
/// Container(
///   padding: context.screenPadding,
///   margin: EdgeInsets.only(bottom: context.cardGap),
///   child: MyWidget(),
/// )
/// ```
class SpacingIPad {
  SpacingIPad._(); // Private constructor - static class only

  // ============================================================================
  // SCALING FACTORS
  // ============================================================================

  /// Get spacing scale factor based on iPad model
  ///
  /// Spacing scales more aggressively than typography to fill larger screens
  /// - iPad Pro 12.9": 1.4x (40% more space)
  /// - iPad Air/Pro 11": 1.25x (25% more space)
  /// - iPad Mini: 1.15x (15% more space)
  /// - iPhone: 1.0x (base)
  static double getSpacingFactor(BuildContext context) {
    if (!context.isIPad) return 1.0;

    final model = context.iPadModel;
    switch (model) {
      case IPadModel.pro12:
        return 1.4; // +40% for large Pro
      case IPadModel.pro11:
      case IPadModel.air:
        return 1.25; // +25% for standard iPads
      case IPadModel.mini:
        return 1.15; // +15% for Mini
      default:
        return 1.0;
    }
  }

  /// Get responsive spacing value
  static double space(BuildContext context, double baseValue) {
    return baseValue * getSpacingFactor(context);
  }

  // ============================================================================
  // STANDARD SPACING VALUES
  // ============================================================================

  /// Extra small spacing: 4px base
  /// iPhone: 4px | iPad Mini: 5px | iPad Air: 5px | iPad Pro: 6px
  static double space4(BuildContext context) => space(context, 4);

  /// Small spacing: 8px base
  /// iPhone: 8px | iPad Mini: 9px | iPad Air: 10px | iPad Pro: 11px
  static double space8(BuildContext context) => space(context, 8);

  /// Medium-small spacing: 12px base
  /// iPhone: 12px | iPad Mini: 14px | iPad Air: 15px | iPad Pro: 17px
  static double space12(BuildContext context) => space(context, 12);

  /// Base spacing: 16px base (most common)
  /// iPhone: 16px | iPad Mini: 18px | iPad Air: 20px | iPad Pro: 22px
  static double space16(BuildContext context) => space(context, 16);

  /// Medium spacing: 20px base
  /// iPhone: 20px | iPad Mini: 23px | iPad Air: 25px | iPad Pro: 28px
  static double space20(BuildContext context) => space(context, 20);

  /// Large spacing: 24px base
  /// iPhone: 24px | iPad Mini: 28px | iPad Air: 30px | iPad Pro: 34px
  static double space24(BuildContext context) => space(context, 24);

  /// Extra large spacing: 32px base
  /// iPhone: 32px | iPad Mini: 37px | iPad Air: 40px | iPad Pro: 45px
  static double space32(BuildContext context) => space(context, 32);

  /// Huge spacing: 40px base
  /// iPhone: 40px | iPad Mini: 46px | iPad Air: 50px | iPad Pro: 56px
  static double space40(BuildContext context) => space(context, 40);

  /// Massive spacing: 48px base
  /// iPhone: 48px | iPad Mini: 55px | iPad Air: 60px | iPad Pro: 67px
  static double space48(BuildContext context) => space(context, 48);

  /// Giant spacing: 64px base
  /// iPhone: 64px | iPad Mini: 74px | iPad Air: 80px | iPad Pro: 90px
  static double space64(BuildContext context) => space(context, 64);

  // ============================================================================
  // SEMANTIC SPACING (Named by purpose)
  // ============================================================================

  /// Spacing between items in a list
  /// Base: 12px (tight list items)
  static double listItemGap(BuildContext context) => space(context, 12);

  /// Spacing between sections on a page
  /// Base: 32px (clear visual separation)
  static double sectionGap(BuildContext context) => space(context, 32);

  /// Spacing between cards in a grid/list
  /// Base: 16px (comfortable card spacing)
  static double cardGap(BuildContext context) => space(context, 16);

  /// Spacing between form fields
  /// Base: 16px (standard form spacing)
  static double formFieldGap(BuildContext context) => space(context, 16);

  /// Spacing between buttons in a group
  /// Base: 12px (tight button groups)
  static double buttonGap(BuildContext context) => space(context, 12);

  /// Spacing between icon and text
  /// Base: 8px (comfortable icon-text spacing)
  static double iconTextGap(BuildContext context) => space(context, 8);

  /// Spacing for large headers/heroes
  /// Base: 48px (dramatic hero spacing)
  static double heroGap(BuildContext context) => space(context, 48);

  // ============================================================================
  // PADDING PRESETS
  // ============================================================================

  /// Screen edge padding (overall page padding)
  /// Base: 16px all around
  static EdgeInsets screenPadding(BuildContext context) {
    return EdgeInsets.all(space(context, 16));
  }

  /// Screen horizontal padding only
  /// Base: 16px left+right
  static EdgeInsets screenHorizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: space(context, 16));
  }

  /// Screen vertical padding only
  /// Base: 16px top+bottom
  static EdgeInsets screenVerticalPadding(BuildContext context) {
    return EdgeInsets.symmetric(vertical: space(context, 16));
  }

  /// Card padding (content inside cards)
  /// Base: 16px all around
  static EdgeInsets cardPadding(BuildContext context) {
    return EdgeInsets.all(space(context, 16));
  }

  /// Large card padding (more spacious cards)
  /// Base: 20px all around
  static EdgeInsets cardPaddingLarge(BuildContext context) {
    return EdgeInsets.all(space(context, 20));
  }

  /// List tile padding
  /// Base: 16px horizontal, 12px vertical
  static EdgeInsets listTilePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: space(context, 16),
      vertical: space(context, 12),
    );
  }

  /// Button padding (text button padding)
  /// Base: 16px horizontal, 12px vertical
  static EdgeInsets buttonPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: space(context, 16),
      vertical: space(context, 12),
    );
  }

  /// Large button padding
  /// Base: 24px horizontal, 16px vertical
  static EdgeInsets buttonPaddingLarge(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: space(context, 24),
      vertical: space(context, 16),
    );
  }

  /// Icon button padding (circular buttons)
  /// Base: 12px all around
  static EdgeInsets iconButtonPadding(BuildContext context) {
    return EdgeInsets.all(space(context, 12));
  }

  /// Dialog padding
  /// Base: 24px all around
  static EdgeInsets dialogPadding(BuildContext context) {
    return EdgeInsets.all(space(context, 24));
  }

  /// Bottom sheet padding
  /// Base: 16px all around
  static EdgeInsets bottomSheetPadding(BuildContext context) {
    return EdgeInsets.all(space(context, 16));
  }

  /// App bar padding
  /// Base: 16px horizontal
  static EdgeInsets appBarPadding(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: space(context, 16));
  }

  // ============================================================================
  // MARGIN PRESETS
  // ============================================================================

  /// Standard bottom margin (between elements)
  /// Base: 16px
  static EdgeInsets marginBottom(BuildContext context) {
    return EdgeInsets.only(bottom: space(context, 16));
  }

  /// Small bottom margin (tight spacing)
  /// Base: 8px
  static EdgeInsets marginBottomSmall(BuildContext context) {
    return EdgeInsets.only(bottom: space(context, 8));
  }

  /// Large bottom margin (more separation)
  /// Base: 24px
  static EdgeInsets marginBottomLarge(BuildContext context) {
    return EdgeInsets.only(bottom: space(context, 24));
  }

  /// Standard vertical margin
  /// Base: 16px top+bottom
  static EdgeInsets marginVertical(BuildContext context) {
    return EdgeInsets.symmetric(vertical: space(context, 16));
  }

  /// Standard horizontal margin
  /// Base: 16px left+right
  static EdgeInsets marginHorizontal(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: space(context, 16));
  }

  // ============================================================================
  // SAFE AREA HELPERS
  // ============================================================================

  /// Get bottom padding that accounts for safe area + spacing
  /// Useful for buttons at bottom of screen
  static double safeBottomPadding(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding.bottom;
    final additionalPadding = space(context, 16);
    return safeArea + additionalPadding;
  }

  /// Get top padding that accounts for safe area + spacing
  static double safeTopPadding(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding.top;
    final additionalPadding = space(context, 16);
    return safeArea + additionalPadding;
  }

  /// Get bottom padding as EdgeInsets
  static EdgeInsets safeBottomInsets(BuildContext context) {
    return EdgeInsets.only(bottom: safeBottomPadding(context));
  }

  /// Get top padding as EdgeInsets
  static EdgeInsets safeTopInsets(BuildContext context) {
    return EdgeInsets.only(top: safeTopPadding(context));
  }
}

// ============================================================================
// EXTENSION METHODS
// ============================================================================

/// Extension on BuildContext for easy spacing access
extension SpacingExtensions on BuildContext {
  // Standard spacing values
  double space(double baseValue) => SpacingIPad.space(this, baseValue);
  double get space4 => SpacingIPad.space4(this);
  double get space8 => SpacingIPad.space8(this);
  double get space12 => SpacingIPad.space12(this);
  double get space16 => SpacingIPad.space16(this);
  double get space20 => SpacingIPad.space20(this);
  double get space24 => SpacingIPad.space24(this);
  double get space32 => SpacingIPad.space32(this);
  double get space40 => SpacingIPad.space40(this);
  double get space48 => SpacingIPad.space48(this);
  double get space64 => SpacingIPad.space64(this);

  // Semantic spacing
  double get listItemGap => SpacingIPad.listItemGap(this);
  double get sectionGap => SpacingIPad.sectionGap(this);
  double get cardGap => SpacingIPad.cardGap(this);
  double get formFieldGap => SpacingIPad.formFieldGap(this);
  double get buttonGap => SpacingIPad.buttonGap(this);
  double get iconTextGap => SpacingIPad.iconTextGap(this);
  double get heroGap => SpacingIPad.heroGap(this);

  // Padding presets
  EdgeInsets get screenPadding => SpacingIPad.screenPadding(this);
  EdgeInsets get screenHorizontalPadding =>
      SpacingIPad.screenHorizontalPadding(this);
  EdgeInsets get screenVerticalPadding =>
      SpacingIPad.screenVerticalPadding(this);
  EdgeInsets get cardPadding => SpacingIPad.cardPadding(this);
  EdgeInsets get cardPaddingLarge => SpacingIPad.cardPaddingLarge(this);
  EdgeInsets get listTilePadding => SpacingIPad.listTilePadding(this);
  EdgeInsets get buttonPadding => SpacingIPad.buttonPadding(this);
  EdgeInsets get buttonPaddingLarge => SpacingIPad.buttonPaddingLarge(this);
  EdgeInsets get iconButtonPadding => SpacingIPad.iconButtonPadding(this);
  EdgeInsets get dialogPadding => SpacingIPad.dialogPadding(this);
  EdgeInsets get bottomSheetPadding => SpacingIPad.bottomSheetPadding(this);
  EdgeInsets get appBarPadding => SpacingIPad.appBarPadding(this);

  // Margin presets
  EdgeInsets get marginBottom => SpacingIPad.marginBottom(this);
  EdgeInsets get marginBottomSmall => SpacingIPad.marginBottomSmall(this);
  EdgeInsets get marginBottomLarge => SpacingIPad.marginBottomLarge(this);
  EdgeInsets get marginVertical => SpacingIPad.marginVertical(this);
  EdgeInsets get marginHorizontal => SpacingIPad.marginHorizontal(this);

  // Safe area helpers
  double get safeBottomPadding => SpacingIPad.safeBottomPadding(this);
  double get safeTopPadding => SpacingIPad.safeTopPadding(this);
  EdgeInsets get safeBottomInsets => SpacingIPad.safeBottomInsets(this);
  EdgeInsets get safeTopInsets => SpacingIPad.safeTopInsets(this);

  /// Get spacing scale factor
  double get spacingFactor => SpacingIPad.getSpacingFactor(this);
}

// ============================================================================
// SIZED BOX HELPERS
// ============================================================================

/// Convenience SizedBox widgets for common spacing
extension SizedBoxSpacing on BuildContext {
  /// Vertical gap of standard size (16px base)
  Widget get vGap => SizedBox(height: space16);

  /// Vertical gap small (8px base)
  Widget get vGapSmall => SizedBox(height: space8);

  /// Vertical gap large (24px base)
  Widget get vGapLarge => SizedBox(height: space24);

  /// Horizontal gap of standard size (16px base)
  Widget get hGap => SizedBox(width: space16);

  /// Horizontal gap small (8px base)
  Widget get hGapSmall => SizedBox(width: space8);

  /// Horizontal gap large (24px base)
  Widget get hGapLarge => SizedBox(width: space24);
}
