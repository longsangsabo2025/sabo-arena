import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'device_info.dart';

/// Manages device orientation preferences based on device type
///
/// iPad devices support all orientations (portrait and landscape)
/// iPhone devices are restricted to portrait by default
///
/// Usage:
/// ```dart
/// // At app start
/// await OrientationManager.setDeviceOrientations(context);
///
/// // For specific screens
/// OrientationScope(
///   child: MyScreen(),
/// )
/// ```
class OrientationManager {
  OrientationManager._(); // Private constructor - static class only

  // ============================================================================
  // ORIENTATION PREFERENCES
  // ============================================================================

  /// Get allowed orientations based on device type
  ///
  /// Returns:
  /// - iPad: All orientations (portrait + landscape)
  /// - iPhone: Portrait only (can be customized)
  static List<DeviceOrientation> getAllowedOrientations(BuildContext context) {
    // Web: Support all orientations
    if (kIsWeb) {
      return [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    }

    // iPad: Support all orientations for optimal multitasking
    if (Platform.isIOS && context.isIPad) {
      return [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    }

    // iPhone: Portrait only by default
    // Can be changed to support landscape if needed
    return [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ];
  }

  /// Apply device-appropriate orientation constraints
  ///
  /// Call this at app start or when device context changes
  static Future<void> setDeviceOrientations(BuildContext context) async {
    await SystemChrome.setPreferredOrientations(
      getAllowedOrientations(context),
    );
  }

  /// Reset to all orientations (default Flutter behavior)
  static Future<void> resetOrientations() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // ============================================================================
  // SCREEN-SPECIFIC LOCKS
  // ============================================================================

  /// Lock device to portrait orientation only
  ///
  /// Useful for:
  /// - Forms and registration screens
  /// - Camera/photo capture
  /// - Onboarding flows
  static Future<void> lockPortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Lock device to landscape orientation only
  ///
  /// Useful for:
  /// - Video players
  /// - Game screens
  /// - Image galleries in landscape
  static Future<void> lockLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Lock to portrait up only (no upside down)
  ///
  /// Useful for sensitive screens where upside-down would be confusing
  static Future<void> lockPortraitUp() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  // ============================================================================
  // IPAD-SPECIFIC ORIENTATION HELPERS
  // ============================================================================

  /// Check if device should support landscape
  ///
  /// iPad: Always true (Apple HIG requirement)
  /// iPhone: Can be configured per app
  static bool shouldSupportLandscape(BuildContext context) {
    if (Platform.isIOS && context.isIPad) {
      return true; // iPad must support landscape
    }
    return false; // iPhone default: portrait only
  }

  /// Get recommended orientations for video playback
  ///
  /// iPad: Landscape preferred but allow portrait
  /// iPhone: Landscape only for immersive experience
  static List<DeviceOrientation> getVideoOrientations(BuildContext context) {
    if (context.isIPad) {
      // iPad: Allow all for flexibility
      return [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    }

    // iPhone: Landscape for video
    return [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ];
  }

  // ============================================================================
  // ORIENTATION CHANGE HANDLING
  // ============================================================================

  /// Check if orientation change should be animated
  ///
  /// iPad: Usually seamless transitions
  /// iPhone: May want to disable for portrait-only apps
  static bool shouldAnimateOrientationChange(BuildContext context) {
    return context.isIPad;
  }

  /// Get recommended animation duration for orientation change
  static Duration getOrientationAnimationDuration() {
    return const Duration(milliseconds: 300);
  }
}

// ============================================================================
// ORIENTATION SCOPE WIDGET
// ============================================================================

/// Widget to manage orientation for a specific screen
///
/// Automatically sets orientations on init and resets on dispose.
///
/// Usage:
/// ```dart
/// // Auto-detect based on device
/// OrientationScope(
///   child: MyScreen(),
/// )
///
/// // Force portrait
/// OrientationScope(
///   allowedOrientations: [
///     DeviceOrientation.portraitUp,
///     DeviceOrientation.portraitDown,
///   ],
///   child: MyScreen(),
/// )
///
/// // Force landscape (e.g., video player)
/// OrientationScope(
///   allowedOrientations: [
///     DeviceOrientation.landscapeLeft,
///     DeviceOrientation.landscapeRight,
///   ],
///   child: VideoPlayer(),
/// )
/// ```
class OrientationScope extends StatefulWidget {
  /// The child widget
  final Widget child;

  /// Allowed orientations for this screen
  /// If null, uses device-appropriate defaults
  final List<DeviceOrientation>? allowedOrientations;

  /// Whether to restore previous orientations on dispose
  final bool restoreOnDispose;

  const OrientationScope({
    super.key,
    required this.child,
    this.allowedOrientations,
    this.restoreOnDispose = true,
  });

  @override
  State<OrientationScope> createState() => _OrientationScopeState();
}

class _OrientationScopeState extends State<OrientationScope> {
  @override
  void initState() {
    super.initState();
    _setOrientations();
  }

  @override
  void dispose() {
    if (widget.restoreOnDispose) {
      OrientationManager.resetOrientations();
    }
    super.dispose();
  }

  void _setOrientations() {
    if (widget.allowedOrientations != null) {
      // Use explicitly provided orientations
      SystemChrome.setPreferredOrientations(widget.allowedOrientations!);
    } else {
      // Use device-appropriate defaults
      OrientationManager.setDeviceOrientations(context);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ============================================================================
// PORTRAIT-ONLY WIDGET
// ============================================================================

/// Convenience widget that forces portrait orientation
///
/// Usage:
/// ```dart
/// PortraitOnly(
///   child: RegistrationForm(),
/// )
/// ```
class PortraitOnly extends StatelessWidget {
  final Widget child;

  const PortraitOnly({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationScope(
      allowedOrientations: const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      child: child,
    );
  }
}

// ============================================================================
// LANDSCAPE-ONLY WIDGET
// ============================================================================

/// Convenience widget that forces landscape orientation
///
/// Usage:
/// ```dart
/// LandscapeOnly(
///   child: VideoPlayer(),
/// )
/// ```
class LandscapeOnly extends StatelessWidget {
  final Widget child;

  const LandscapeOnly({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationScope(
      allowedOrientations: const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      child: child,
    );
  }
}

// ============================================================================
// EXTENSION METHODS
// ============================================================================

/// Extension on BuildContext for easy orientation queries
extension OrientationExtension on BuildContext {
  /// Check if device is in landscape orientation
  bool get isLandscapeOrientation =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  /// Check if device is in portrait orientation
  bool get isPortraitOrientation =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  /// Get current orientation
  Orientation get currentOrientation => MediaQuery.of(this).orientation;

  /// Check if device should support landscape based on device type
  bool get shouldSupportLandscape =>
      OrientationManager.shouldSupportLandscape(this);
}
