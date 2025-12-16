/// DSTabs - Design System Tabs Component
///
/// Instagram/Facebook quality tabs with:
/// - Underline indicator style
/// - Scrollable support
/// - Icon support
/// - Badge support
/// - Smooth animation
///
/// Usage:
/// ```dart
/// DSTabs(
///   tabs: ['Home', 'Trending', 'Following'],
///   onTabChanged: (index) => setState(() => _currentTab = index),
/// )
/// ```

import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../app_colors.dart';
import '../typography.dart';

/// Tab item data
class DSTabItem {
  /// Tab label
  final String label;

  /// Tab icon (optional)
  final IconData? icon;

  /// Badge count (optional)
  final int? badgeCount;

  /// Show badge dot (optional)
  final bool showBadgeDot;

  const DSTabItem({
    required this.label,
    this.icon,
    this.badgeCount,
    this.showBadgeDot = false,
  });
}

/// Design System Tabs Component
class DSTabs extends StatefulWidget {
  /// List of tab labels
  final List<String>? tabs;

  /// List of tab items (alternative to tabs)
  final List<DSTabItem>? tabItems;

  /// Initial tab index
  final int initialIndex;

  /// Tab change callback
  final void Function(int index)? onTabChanged;

  /// Enable scrollable tabs
  final bool isScrollable;

  /// Tab controller (if managing externally)
  final TabController? controller;

  /// Indicator color
  final Color? indicatorColor;

  /// Selected tab color
  final Color? selectedColor;

  /// Unselected tab color
  final Color? unselectedColor;

  /// Indicator weight
  final double indicatorWeight;

  /// Tab padding
  final EdgeInsetsGeometry? labelPadding;

  const DSTabs({
    super.key,
    this.tabs,
    this.tabItems,
    this.initialIndex = 0,
    this.onTabChanged,
    this.isScrollable = false,
    this.controller,
    this.indicatorColor,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorWeight = 2.0,
    this.labelPadding,
  }) : assert(
         tabs != null || tabItems != null,
         'Either tabs or tabItems must be provided',
       );

  @override
  State<DSTabs> createState() => _DSTabsState();
}

class _DSTabsState extends State<DSTabs> with SingleTickerProviderStateMixin {
  late TabController _controller;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _isInternalController = true;
      final length = widget.tabs?.length ?? widget.tabItems?.length ?? 0;
      _controller = TabController(
        length: length,
        vsync: this,
        initialIndex: widget.initialIndex,
      );
    }

    _controller.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTabChange);
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleTabChange() {
    if (_controller.indexIsChanging) {
      widget.onTabChanged?.call(_controller.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: TabBar(
        controller: _controller,
        isScrollable: widget.isScrollable,
        labelColor: widget.selectedColor ?? AppColors.primary,
        unselectedLabelColor: widget.unselectedColor ?? AppColors.textSecondary,
        labelStyle: AppTypography.labelMedium,
        unselectedLabelStyle: AppTypography.labelMedium,
        labelPadding:
            widget.labelPadding ??
            EdgeInsets.symmetric(
              horizontal: widget.isScrollable
                  ? DesignTokens.space16
                  : DesignTokens.space12,
            ),
        indicatorColor: widget.indicatorColor ?? AppColors.primary,
        indicatorWeight: widget.indicatorWeight,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: _buildTabs(),
      ),
    );
  }

  List<Widget> _buildTabs() {
    if (widget.tabItems != null) {
      return widget.tabItems!.map((item) => _buildTabItem(item)).toList();
    }

    return widget.tabs!
        .map((label) => _buildTabItem(DSTabItem(label: label)))
        .toList();
  }

  Widget _buildTabItem(DSTabItem item) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          if (item.icon != null) ...[
            Icon(item.icon, size: 20),
            SizedBox(width: DesignTokens.space8),
          ],

          // Label
          Text(item.label),

          // Badge
          if (item.badgeCount != null && item.badgeCount! > 0) ...[
            SizedBox(width: DesignTokens.space4),
            _buildBadge(item.badgeCount!),
          ] else if (item.showBadgeDot) ...[
            SizedBox(width: DesignTokens.space4),
            _buildBadgeDot(),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: DesignTokens.radius(DesignTokens.radiusFull),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.surface,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Tab view with DSTabs
class DSTabView extends StatefulWidget {
  /// List of tab labels
  final List<String>? tabs;

  /// List of tab items (alternative to tabs)
  final List<DSTabItem>? tabItems;

  /// List of tab content widgets
  final List<Widget> children;

  /// Initial tab index
  final int initialIndex;

  /// Tab change callback
  final void Function(int index)? onTabChanged;

  /// Enable scrollable tabs
  final bool isScrollableTabs;

  /// Enable swipe gesture
  final bool enableSwipe;

  const DSTabView({
    super.key,
    this.tabs,
    this.tabItems,
    required this.children,
    this.initialIndex = 0,
    this.onTabChanged,
    this.isScrollableTabs = false,
    this.enableSwipe = true,
  }) : assert(
         tabs != null || tabItems != null,
         'Either tabs or tabItems must be provided',
       );

  @override
  State<DSTabView> createState() => _DSTabViewState();
}

class _DSTabViewState extends State<DSTabView>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();

    final length = widget.tabs?.length ?? widget.tabItems?.length ?? 0;
    _controller = TabController(
      length: length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );

    _controller.addListener(() {
      if (_controller.indexIsChanging) {
        widget.onTabChanged?.call(_controller.index);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DSTabs(
          tabs: widget.tabs,
          tabItems: widget.tabItems,
          controller: _controller,
          isScrollable: widget.isScrollableTabs,
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            physics: widget.enableSwipe
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            children: widget.children,
          ),
        ),
      ],
    );
  }
}

/// Segmented control style tabs (iOS style)
class DSSegmentedControl extends StatelessWidget {
  /// List of segment labels
  final List<String> segments;

  /// Selected segment index
  final int selectedIndex;

  /// Selection change callback
  final void Function(int index) onChanged;

  /// Background color
  final Color? backgroundColor;

  /// Selected color
  final Color? selectedColor;

  /// Text color
  final Color? textColor;

  /// Selected text color
  final Color? selectedTextColor;

  const DSSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.backgroundColor,
    this.selectedColor,
    this.textColor,
    this.selectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.gray100,
        borderRadius: DesignTokens.radius(DesignTokens.radiusSM),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: List.generate(segments.length, (index) {
          final isSelected = index == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: DesignTokens.durationFast,
                curve: DesignTokens.curveStandard,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (selectedColor ?? AppColors.surface)
                      : Colors.transparent,
                  borderRadius: DesignTokens.radius(DesignTokens.radiusSM - 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    segments[index],
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? (selectedTextColor ?? AppColors.textPrimary)
                          : (textColor ?? AppColors.textSecondary),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
