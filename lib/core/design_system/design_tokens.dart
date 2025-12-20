/// Design Tokens - Single Source of Truth
///
/// Core design constants following Instagram/Facebook standards:
/// - 8px grid system for spacing
/// - Consistent border radius scale
/// - Animation timing and curves
/// - Opacity levels for overlays
/// - Z-index hierarchy for layering
///
/// Based on Material Design 3 and iOS Human Interface Guidelines

import 'package:flutter/material.dart';

/// Core design tokens for the SABO ARENA app
///
/// All spacing, sizing, timing values should reference these tokens
/// to ensure consistency across the entire application
class DesignTokens {
  DesignTokens._(); // Private constructor to prevent instantiation

  // ============================================================================
  // SPACING SCALE (8px Grid System)
  // ============================================================================

  /// No spacing
  static const double space0 = 0.0;

  /// Extra small spacing (4px) - tight padding
  static const double space4 = 4.0;

  /// Small spacing (8px) - base unit, between related items
  static const double space8 = 8.0;

  /// Medium-small spacing (12px) - card padding, list item spacing
  static const double space12 = 12.0;

  /// Medium spacing (16px) - screen padding, section spacing
  static const double space16 = 16.0;

  /// Medium-small spacing (10px) - small gaps
  static const double space10 = 10.0;

  /// Medium-large spacing (20px) - larger section spacing
  static const double space20 = 20.0;

  /// Large spacing (24px) - between major sections
  static const double space24 = 24.0;

  /// Extra large spacing (32px) - large section dividers
  static const double space32 = 32.0;

  /// XXL spacing (40px) - hero section spacing
  static const double space40 = 40.0;

  /// XXXL spacing (48px) - major layout spacing
  static const double space48 = 48.0;

  /// Huge spacing (64px) - massive gaps
  static const double space64 = 64.0;

  // ============================================================================
  // BORDER RADIUS SCALE
  // ============================================================================

  /// Extra small radius (4px) - badges, tags
  static const double radiusXS = 4.0;

  /// Small radius (8px) - buttons, small cards
  static const double radiusSM = 8.0;

  /// Medium-small radius (10px) - small elements
  static const double radius10 = 10.0;

  /// Medium radius (12px) - standard cards, inputs
  static const double radiusMD = 12.0;

  /// Large radius (16px) - large cards, modals
  static const double radiusLG = 16.0;

  /// Extra large radius (20px) - bottom sheets
  static const double radiusXL = 20.0;

  /// XXL radius (24px) - special cards
  static const double radiusXXL = 24.0;

  /// XXXL radius (32px) - hero elements
  static const double radiusXXXL = 32.0;

  /// Full circle radius (9999px)
  static const double radiusFull = 9999.0;

  // ============================================================================
  // ANIMATION DURATIONS (Instagram/Facebook Standard)
  // ============================================================================

  /// Extra fast (100ms) - instant feedback, checkbox toggle
  static const Duration durationXFast = Duration(milliseconds: 100);

  /// Fast (150ms) - button press, quick transitions
  static const Duration durationFast = Duration(milliseconds: 150);

  /// Normal (250ms) - standard transitions, modal open/close
  static const Duration durationNormal = Duration(milliseconds: 250);

  /// Medium (350ms) - page transitions, complex animations
  static const Duration durationMedium = Duration(milliseconds: 350);

  /// Slow (500ms) - emphasized transitions, drawer slide
  static const Duration durationSlow = Duration(milliseconds: 500);

  /// Extra slow (700ms) - special effects
  static const Duration durationXSlow = Duration(milliseconds: 700);

  // ============================================================================
  // ANIMATION CURVES (Natural Motion)
  // ============================================================================

  /// Standard easing - most common, balanced
  static const Curve curveStandard = Curves.easeInOut;

  /// Emphasized easing - attention-grabbing, smooth deceleration
  static const Curve curveEmphasized = Curves.easeOutCubic;

  /// Decelerate - elements entering screen
  static const Curve curveDecelerate = Curves.easeOut;

  /// Accelerate - elements leaving screen
  static const Curve curveAccelerate = Curves.easeIn;

  /// Sharp - quick, mechanical (avoid for most cases)
  static const Curve curveSharp = Curves.linear;

  /// Bounce - playful, for success states
  static const Curve curveBounce = Curves.bounceOut;

  /// Elastic - springy, for interactive elements
  static const Curve curveElastic = Curves.elasticOut;

  // ============================================================================
  // OPACITY SCALE (Overlays, Disabled States)
  // ============================================================================

  /// 5% opacity - subtle hover effects
  static const double opacity5 = 0.05;

  /// 8% opacity - very subtle backgrounds
  static const double opacity8 = 0.08;

  /// 10% opacity - light overlays
  static const double opacity10 = 0.10;

  /// 12% opacity - hover states
  static const double opacity12 = 0.12;

  /// 20% opacity - disabled backgrounds
  static const double opacity20 = 0.20;

  /// 30% opacity - medium overlays
  static const double opacity30 = 0.30;

  /// 38% opacity - Material disabled text
  static const double opacity38 = 0.38;

  /// 50% opacity - half transparent
  static const double opacity50 = 0.50;

  /// 60% opacity - modal overlays
  static const double opacity60 = 0.60;

  /// 70% opacity - secondary text
  static const double opacity70 = 0.70;

  /// 80% opacity - medium emphasis text
  static const double opacity80 = 0.80;

  /// 90% opacity - high emphasis text
  static const double opacity90 = 0.90;

  // ============================================================================
  // Z-INDEX / LAYER HIERARCHY
  // ============================================================================

  /// Base layer (0) - default, normal content
  static const int zIndexBase = 0;

  /// Sticky elements (50) - sticky headers
  static const int zIndexSticky = 50;

  /// Dropdown (100) - select menus
  static const int zIndexDropdown = 100;

  /// Fixed elements (200) - fixed bottom bars
  static const int zIndexFixed = 200;

  /// App bar (300) - top navigation
  static const int zIndexAppBar = 300;

  /// Drawer (400) - side navigation
  static const int zIndexDrawer = 400;

  /// Modal (500) - dialogs, bottom sheets
  static const int zIndexModal = 500;

  /// Popover (600) - tooltips, popovers
  static const int zIndexPopover = 600;

  /// Snackbar (700) - toast notifications
  static const int zIndexSnackbar = 700;

  /// Tooltip (800) - highest UI element
  static const int zIndexTooltip = 800;

  // ============================================================================
  // ELEVATION / SHADOW DEPTHS
  // ============================================================================

  /// No elevation (0dp)
  static const double elevation0 = 0.0;

  /// Subtle elevation (1dp) - app bar on scroll
  static const double elevation1 = 1.0;

  /// Small elevation (2dp) - cards at rest
  static const double elevation2 = 2.0;

  /// Medium elevation (4dp) - raised cards, FAB at rest
  static const double elevation4 = 4.0;

  /// Large elevation (6dp) - FAB on press
  static const double elevation6 = 6.0;

  /// XL elevation (8dp) - bottom navigation, dialogs
  static const double elevation8 = 8.0;

  /// XXL elevation (12dp) - navigation drawer
  static const double elevation12 = 12.0;

  /// Huge elevation (16dp) - modals
  static const double elevation16 = 16.0;

  /// Maximum elevation (24dp) - special emphasis
  static const double elevation24 = 24.0;

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  /// Extra small icon (16px) - inline with text
  static const double iconXS = 16.0;

  /// Small icon (20px) - list items, compact UI
  static const double iconSM = 20.0;

  /// Medium icon (24px) - standard, most common
  static const double iconMD = 24.0;

  /// Large icon (32px) - emphasized actions
  static const double iconLG = 32.0;

  /// Extra large icon (40px) - hero icons
  static const double iconXL = 40.0;

  /// XXL icon (48px) - featured icons
  static const double iconXXL = 48.0;

  /// Huge icon (64px) - empty states
  static const double iconHuge = 64.0;

  // ============================================================================
  // BUTTON HEIGHTS
  // ============================================================================

  /// Small button (32px)
  static const double buttonHeightSM = 32.0;

  /// Medium button (40px) - default
  static const double buttonHeightMD = 40.0;

  /// Large button (48px) - primary actions
  static const double buttonHeightLG = 48.0;

  /// Extra large button (56px) - hero CTAs
  static const double buttonHeightXL = 56.0;

  // ============================================================================
  // TAP TARGET SIZES (Minimum 44x44 for accessibility)
  // ============================================================================

  /// Minimum tap target (44px) - iOS HIG, WCAG AAA
  static const double tapTargetMin = 44.0;

  /// Recommended tap target (48px) - Material Design
  static const double tapTargetRecommended = 48.0;

  /// Large tap target (56px) - primary actions
  static const double tapTargetLarge = 56.0;

  // ============================================================================
  // AVATAR SIZES
  // ============================================================================

  /// Extra small avatar (24px) - inline mentions
  static const double avatarXS = 24.0;

  /// Small avatar (32px) - compact lists
  static const double avatarSM = 32.0;

  /// Medium avatar (40px) - standard list items
  static const double avatarMD = 40.0;

  /// Large avatar (48px) - emphasized profiles
  static const double avatarLG = 48.0;

  /// Extra large avatar (64px) - profile headers
  static const double avatarXL = 64.0;

  /// XXL avatar (80px) - large profile displays
  static const double avatarXXL = 80.0;

  /// Huge avatar (96px) - profile cards
  static const double avatarHuge = 96.0;

  /// Massive avatar (128px) - full profile view
  static const double avatarMassive = 128.0;

  // ============================================================================
  // CONTENT WIDTH CONSTRAINTS
  // ============================================================================

  /// Maximum content width for mobile (480px)
  static const double maxWidthMobile = 480.0;

  /// Maximum content width for tablet (768px)
  static const double maxWidthTablet = 768.0;

  /// Maximum content width for desktop (1200px)
  static const double maxWidthDesktop = 1200.0;

  // ============================================================================
  // LINE HEIGHTS (Typography)
  // ============================================================================

  /// Tight line height (1.2) - headings
  static const double lineHeightTight = 1.2;

  /// Normal line height (1.4) - short text
  static const double lineHeightNormal = 1.4;

  /// Relaxed line height (1.5) - body text
  static const double lineHeightRelaxed = 1.5;

  /// Loose line height (1.6) - long-form content
  static const double lineHeightLoose = 1.6;

  // ============================================================================
  // LETTER SPACING
  // ============================================================================

  /// Tight letter spacing (-0.5px) - headings
  static const double letterSpacingTight = -0.5;

  /// Normal letter spacing (0px) - default
  static const double letterSpacingNormal = 0.0;

  /// Relaxed letter spacing (0.3px) - body text
  static const double letterSpacingRelaxed = 0.3;

  /// Wide letter spacing (1.2px) - buttons, labels
  static const double letterSpacingWide = 1.2;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Create EdgeInsets with uniform spacing
  static EdgeInsets all(double value) => EdgeInsets.all(value);

  /// Create horizontal EdgeInsets
  static EdgeInsets horizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);

  /// Create vertical EdgeInsets
  static EdgeInsets vertical(double value) =>
      EdgeInsets.symmetric(vertical: value);

  /// Create EdgeInsets with specific values
  static EdgeInsets only({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) =>
      EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);

  /// Create BorderRadius with all corners
  static BorderRadius radius(double value) => BorderRadius.circular(value);

  /// Create BorderRadius with only top corners
  static BorderRadius radiusTop(double value) =>
      BorderRadius.vertical(top: Radius.circular(value));

  /// Create BorderRadius with only bottom corners
  static BorderRadius radiusBottom(double value) =>
      BorderRadius.vertical(bottom: Radius.circular(value));

  /// Create Duration from milliseconds
  static Duration duration(int milliseconds) =>
      Duration(milliseconds: milliseconds);
}
