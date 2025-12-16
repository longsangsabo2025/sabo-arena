import 'package:flutter/material.dart';
import 'package:sabo_arena/core/device/device_info.dart';

/// Responsive grid widget that adapts column count based on iPad model
/// 
/// Usage:
/// ```dart
/// ResponsiveGrid(
///   items: myItems,
///   itemBuilder: (context, item, index) => MyWidget(item),
/// )
/// ```
class ResponsiveGrid extends StatelessWidget {
  final List items;
  final Widget Function(BuildContext context, dynamic item, int index) itemBuilder;
  final double spacing;
  final double runSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double childAspectRatio;

  const ResponsiveGrid({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.childAspectRatio = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columnCount = _getColumnCount(context);

    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(16.0),
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }

  int _getColumnCount(BuildContext context) {
    if (!DeviceInfo.isIPad(context)) {
      return 2; // Default for phones
    }

    final iPadModel = DeviceInfo.getIPadModel(context);
    
    switch (iPadModel) {
      case IPadModel.mini:
        return 2; // iPad Mini: 2 columns
      case IPadModel.air:
      case IPadModel.pro11:
        return 3; // iPad Air & Pro 11": 3 columns
      case IPadModel.pro12:
        return 4; // iPad Pro 12.9": 4 columns
      case IPadModel.none:
        return 2; // Fallback
    }
  }
}

/// Sliver version for use in CustomScrollView
class ResponsiveSliverGrid extends StatelessWidget {
  final List items;
  final Widget Function(BuildContext context, dynamic item, int index) itemBuilder;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  const ResponsiveSliverGrid({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.childAspectRatio = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columnCount = _getColumnCount(context);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return itemBuilder(context, items[index], index);
        },
        childCount: items.length,
      ),
    );
  }

  int _getColumnCount(BuildContext context) {
    if (!DeviceInfo.isIPad(context)) {
      return 2; // Default for phones
    }

    final iPadModel = DeviceInfo.getIPadModel(context);
    
    switch (iPadModel) {
      case IPadModel.mini:
        return 2; // iPad Mini: 2 columns
      case IPadModel.air:
      case IPadModel.pro11:
        return 3; // iPad Air & Pro 11": 3 columns
      case IPadModel.pro12:
        return 4; // iPad Pro 12.9": 4 columns
      case IPadModel.none:
        return 2; // Fallback
    }
  }
}

/// Helper extension for quick grid building
extension ResponsiveGridExtension on BuildContext {
  /// Get optimal column count for current device
  int getGridColumnCount() {
    if (!DeviceInfo.isIPad(this)) {
      return 2;
    }

    final iPadModel = DeviceInfo.getIPadModel(this);
    
    switch (iPadModel) {
      case IPadModel.mini:
        return 2;
      case IPadModel.air:
      case IPadModel.pro11:
        return 3;
      case IPadModel.pro12:
        return 4;
      case IPadModel.none:
        return 2;
    }
  }
}
