import 'package:flutter/material.dart';
// ELON_MODE_AUTO_FIX

/// Pinch-to-zoom widget for bracket visualization and images
///
/// Usage:
/// ```dart
/// PinchToZoomWidget(
///   child: BracketTreeWidget(),
///   minScale: 0.5,
///   maxScale: 3.0,
/// )
/// ```
class PinchToZoomWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final double initialScale;

  const PinchToZoomWidget({
    Key? key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.initialScale = 1.0,
  }) : super(key: key);

  @override
  State<PinchToZoomWidget> createState() => _PinchToZoomWidgetState();
}

class _PinchToZoomWidgetState extends State<PinchToZoomWidget> {
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      constrained: false,
      child: widget.child,
    );
  }
}

/// Long-press context menu for iPad
///
/// Usage:
/// ```dart
/// LongPressContextMenu(
///   menuItems: [
///     ContextMenuItem(icon: Icons.edit, label: 'Edit', onTap: () {}),
///     ContextMenuItem(icon: Icons.delete, label: 'Delete', onTap: () {}),
///   ],
///   child: MyWidget(),
/// )
/// ```
class LongPressContextMenu extends StatelessWidget {
  final Widget child;
  final List<ContextMenuItem> menuItems;
  final Offset? menuPosition;

  const LongPressContextMenu({
    Key? key,
    required this.child,
    required this.menuItems,
    this.menuPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: menuItems.map((item) {
        return PopupMenuItem(
          onTap: item.onTap,
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: item.color),
              const SizedBox(width: 12),
              Text(item.label),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Context menu item model
class ContextMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

/// Swipeable page navigation widget
///
/// Usage:
/// ```dart
/// SwipeablePages(
///   pages: [Page1(), Page2(), Page3()],
///   onPageChanged: (index) => print('Page $index'),
/// )
/// ```
class SwipeablePages extends StatefulWidget {
  final List<Widget> pages;
  final Function(int)? onPageChanged;
  final PageController? controller;
  final ScrollPhysics? physics;

  const SwipeablePages({
    Key? key,
    required this.pages,
    this.onPageChanged,
    this.controller,
    this.physics,
  }) : super(key: key);

  @override
  State<SwipeablePages> createState() => _SwipeablePagesState();
}

class _SwipeablePagesState extends State<SwipeablePages> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = widget.controller ?? PageController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: widget.onPageChanged,
      physics: widget.physics ?? const BouncingScrollPhysics(),
      children: widget.pages,
    );
  }
}

/// Double-tap to zoom widget
///
/// Usage:
/// ```dart
/// DoubleTapToZoom(
///   child: Image.network(url),
///   zoomedScale: 2.0,
/// )
/// ```
class DoubleTapToZoom extends StatefulWidget {
  final Widget child;
  final double zoomedScale;
  final Duration animationDuration;

  const DoubleTapToZoom({
    Key? key,
    required this.child,
    this.zoomedScale = 2.0,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<DoubleTapToZoom> createState() => _DoubleTapToZoomState();
}

class _DoubleTapToZoomState extends State<DoubleTapToZoom>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.zoomedScale)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    setState(() {
      _isZoomed = !_isZoomed;
      if (_isZoomed) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
