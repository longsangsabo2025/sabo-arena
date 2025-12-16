/// DSBottomSheet - Design System Bottom Sheet Component
///
/// Instagram/Facebook quality bottom sheet with:
/// - Drag handle
/// - Custom heights (auto, half, full)
/// - Scroll support
/// - Dismissible options
/// - Smooth animations
///
/// Usage:
/// ```dart
/// DSBottomSheet.show(
///   context: context,
///   builder: (context) => YourContent(),
/// )
/// ```

import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../app_colors.dart';

/// Bottom sheet height presets
enum DSBottomSheetHeight {
  /// Auto height based on content
  auto,

  /// Half screen height
  half,

  /// Full screen height
  full,

  /// Custom height (use customHeight parameter)
  custom,
}

/// Design System Bottom Sheet
class DSBottomSheet {
  /// Show bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    DSBottomSheetHeight height = DSBottomSheetHeight.auto,
    double? customHeight,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showDragHandle = true,
    Color? backgroundColor,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      builder: (context) => _DSBottomSheetContent(
        height: height,
        customHeight: customHeight,
        showDragHandle: showDragHandle,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        padding: padding,
        child: builder(context),
      ),
    );
  }

  /// Show scrollable bottom sheet
  static Future<T?> showScrollable<T>({
    required BuildContext context,
    required Widget Function(BuildContext, ScrollController) builder,
    DSBottomSheetHeight height = DSBottomSheetHeight.half,
    double? customHeight,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showDragHandle = true,
    Color? backgroundColor,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: height == DSBottomSheetHeight.half ? 0.5 : 0.9,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _DSBottomSheetContent(
          height: height,
          customHeight: customHeight,
          showDragHandle: showDragHandle,
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
          padding: padding,
          child: builder(context, scrollController),
        ),
      ),
    );
  }
}

class _DSBottomSheetContent extends StatelessWidget {
  final Widget child;
  final DSBottomSheetHeight height;
  final double? customHeight;
  final bool showDragHandle;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const _DSBottomSheetContent({
    required this.child,
    required this.height,
    this.customHeight,
    required this.showDragHandle,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  });

  double? _getHeight(BuildContext context) {
    switch (height) {
      case DSBottomSheetHeight.auto:
        return null;
      case DSBottomSheetHeight.half:
        return MediaQuery.of(context).size.height * 0.5;
      case DSBottomSheetHeight.full:
        return MediaQuery.of(context).size.height * 0.95;
      case DSBottomSheetHeight.custom:
        return customHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _getHeight(context),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius ?? DesignTokens.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle) ...[
            SizedBox(height: DesignTokens.space12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: DesignTokens.radius(DesignTokens.radiusFull),
              ),
            ),
            SizedBox(height: DesignTokens.space12),
          ],
          Flexible(
            child: Padding(
              padding: padding ?? DesignTokens.all(DesignTokens.space16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
