import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Optimized image widget with caching and loading states
/// 
/// Usage:
/// ```dart
/// OptimizedImage(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 200,
///   height: 200,
/// )
/// ```
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      placeholder: (context, url) => placeholder ?? 
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      errorWidget: (context, url, error) => errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade300,
          child: const Icon(Icons.error_outline, color: Colors.red),
        ),
    );
  }
}

/// Optimized list with lazy loading
/// 
/// Usage:
/// ```dart
/// OptimizedListView(
///   itemCount: items.length,
///   itemBuilder: (context, index) => ItemWidget(items[index]),
///   itemExtent: 80.0,
/// )
/// ```
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double? itemExtent;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final ScrollController? controller;

  const OptimizedListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent,
    this.physics,
    this.padding,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      itemExtent: itemExtent, // Performance boost for fixed-height items
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding,
      cacheExtent: 1000, // Pre-render items outside viewport
    );
  }
}

/// 120Hz animation support for ProMotion displays
/// 
/// Usage:
/// ```dart
/// ProMotionAnimation(
///   duration: Duration(milliseconds: 300),
///   child: MyAnimatedWidget(),
/// )
/// ```
class ProMotionAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const ProMotionAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  State<ProMotionAnimation> createState() => _ProMotionAnimationState();
}

class _ProMotionAnimationState extends State<ProMotionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
      child: widget.child,
    );
  }
}

/// Repaint boundary wrapper for complex widgets
/// 
/// Usage:
/// ```dart
/// PerformanceOptimizedWidget(
///   child: ComplexWidget(),
/// )
/// ```
class PerformanceOptimizedWidget extends StatelessWidget {
  final Widget child;

  const PerformanceOptimizedWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

/// Debounced search field
/// 
/// Usage:
/// ```dart
/// DebouncedSearchField(
///   onSearch: (query) => performSearch(query),
///   debounceTime: Duration(milliseconds: 500),
/// )
/// ```
class DebouncedSearchField extends StatefulWidget {
  final Function(String) onSearch;
  final Duration debounceTime;
  final String? hintText;
  final TextEditingController? controller;

  const DebouncedSearchField({
    Key? key,
    required this.onSearch,
    this.debounceTime = const Duration(milliseconds: 500),
    this.hintText,
    this.controller,
  }) : super(key: key);

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late TextEditingController _controller;
  DateTime? _lastChangeTime;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    _lastChangeTime = DateTime.now();
    
    Future.delayed(widget.debounceTime, () {
      if (_lastChangeTime != null &&
          DateTime.now().difference(_lastChangeTime!) >= widget.debounceTime) {
        widget.onSearch(_controller.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Search...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Performance monitoring utility
class PerformanceMonitor {
  static final List<PerformanceMetric> _metrics = [];

  static void logMetric(String name, Duration duration) {
    _metrics.add(PerformanceMetric(
      name: name,
      duration: duration,
      timestamp: DateTime.now(),
    ));

    // Keep only last 100 metrics
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }
  }

  static List<PerformanceMetric> getMetrics() => List.unmodifiable(_metrics);

  static void clearMetrics() => _metrics.clear();

  static String getSummary() {
    if (_metrics.isEmpty) return 'No metrics collected';

    final avgDuration = _metrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b) / _metrics.length;

    return 'Avg: ${avgDuration.toStringAsFixed(2)}ms | Total: ${_metrics.length} ops';
  }
}

class PerformanceMetric {
  final String name;
  final Duration duration;
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
  });
}
