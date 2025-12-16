/// Design System - Barrel Export
///
/// Single import point for the entire design system:
/// ```dart
/// import 'package:sabo_arena/core/design_system/design_system.dart';
/// ```
///
/// This exports:
/// - **DesignTokens**: Spacing, radius, durations, curves, opacity, z-index
/// - **AppColors**: Complete color palette with light/dark support
/// - **AppTypography**: Text styles (display, heading, body, label, caption)
/// - **AppIcons**: Centralized icon references
/// - **Breakpoints**: Responsive breakpoints and utilities
/// - **AppTheme**: Complete theme configuration (light/dark)
/// - **AppAnimations**: Pre-built transitions and micro-interactions
/// - **All Components**: DS buttons, cards, text fields, avatars, etc.
///
/// Usage:
/// ```dart
/// // Use design tokens
/// Container(
///   padding: DesignTokens.all(DesignTokens.space16),
///   decoration: BoxDecoration(
///     color: AppColors.surface,
///     borderRadius: DesignTokens.radius(DesignTokens.radiusMD),
///   ),
///   child: Column(
///     children: [
///       // Use typography
///       Text('Title', style: AppTypography.headingLarge),
///       // Use components
///       DSButton.primary(
///         text: 'Click Me',
///         onPressed: () {},
///       ),
///     ],
///   ),
/// )
///
/// // Use responsive breakpoints
/// if (context.isMobile) {
///   // Mobile layout
/// } else {
///   // Desktop layout
/// }
/// ```

library design_system;

// Export design tokens
export 'design_tokens.dart';

// Export colors
export 'app_colors.dart';

// Export typography
export 'typography.dart';

// Export icons
export 'app_icons.dart';

// Export breakpoints
export 'breakpoints.dart';

// Export theme
export 'app_theme.dart';

// Export animations
export 'animations.dart';

// Export all components
export 'components/components.dart';
