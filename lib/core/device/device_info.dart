import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// iPad-specific device classification
enum IPadModel {
  none, // Not an iPad
  mini, // iPad Mini (744x1133)
  air, // iPad Air (820x1180)
  pro11, // iPad Pro 11" (834x1194)
  pro12, // iPad Pro 12.9" (1024x1366)
}

/// Device information and iPad detection utilities
class DeviceInfo {
  DeviceInfo._(); // Private constructor - static class only

  // ============================================================================
  // IPAD DETECTION
  // ============================================================================

  /// Detect if current device is an iPad
  ///
  /// Uses screen dimensions to identify iPad devices:
  /// - iPad Mini: 744x1133 (portrait)
  /// - iPad Air: 820x1180 (portrait)
  /// - iPad Pro 11": 834x1194 (portrait)
  /// - iPad Pro 12.9": 1024x1366 (portrait)
  static bool isIPad(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final minDimension = size.shortestSide;
    final maxDimension = size.longestSide;

    // iPad detection by screen size (works on Web too!)
    // shortest side >= 744px AND longest side >= 1024px
    // This filters out all iPhones including Pro Max (428x926)
    if (minDimension >= 744 && maxDimension >= 1024) {
      return true;
    }

    // On native iOS, also check Platform
    if (!kIsWeb && Platform.isIOS) {
      return minDimension >= 744 && maxDimension >= 1024;
    }

    return false;
  }

  /// Get specific iPad model based on screen dimensions
  static IPadModel getIPadModel(BuildContext context) {
    if (!isIPad(context)) return IPadModel.none;

    final size = MediaQuery.of(context).size;
    final minDimension = size.shortestSide;

    // Detect by shortest side (works in both portrait and landscape)
    if (minDimension >= 1024) {
      return IPadModel.pro12; // iPad Pro 12.9"
    } else if (minDimension >= 834) {
      return IPadModel.pro11; // iPad Pro 11"
    } else if (minDimension >= 820) {
      return IPadModel.air; // iPad Air
    } else if (minDimension >= 744) {
      return IPadModel.mini; // iPad Mini
    }

    return IPadModel.none;
  }

  /// Check if device supports Split View
  /// (All iPads support Split View since iOS 9+)
  static bool supportsSplitView(BuildContext context) {
    return isIPad(context);
  }

  /// Check if device supports Slide Over
  /// (All iPads support Slide Over since iOS 9+)
  static bool supportsSlideOver(BuildContext context) {
    return isIPad(context);
  }

  /// Check if device supports Stage Manager
  /// (iPad Air 3rd gen+, iPad Pro 2018+, iPad Mini 6th gen+)
  static bool supportsStageManager(BuildContext context) {
    if (!isIPad(context)) return false;

    final model = getIPadModel(context);
    // Stage Manager available on modern iPads
    // For simplicity, assume all detected iPads support it
    return model != IPadModel.none;
  }

  // ============================================================================
  // OPTIMAL LAYOUT DIMENSIONS
  // ============================================================================

  /// Get ideal content width for readability
  ///
  /// Returns maximum width for content to prevent text lines from being too long
  /// on large screens, following readability best practices (50-75 characters per line)
  static double getMaxContentWidth(BuildContext context) {
    if (!isIPad(context)) {
      return double.infinity; // Mobile: use full width
    }

    final model = getIPadModel(context);
    switch (model) {
      case IPadModel.pro12:
        return 980.0; // Wider for 12.9" screen
      case IPadModel.pro11:
      case IPadModel.air:
        return 840.0; // Comfortable reading width
      case IPadModel.mini:
        return 680.0; // Smaller but still readable
      default:
        return 680.0;
    }
  }

  /// Get optimal column count for grid layouts
  static int getOptimalColumnCount(BuildContext context) {
    if (!isIPad(context)) return 1; // Mobile: single column

    final model = getIPadModel(context);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    switch (model) {
      case IPadModel.pro12:
        return isLandscape ? 4 : 3; // 12.9" has most space
      case IPadModel.pro11:
      case IPadModel.air:
        return isLandscape ? 3 : 2; // Standard iPads
      case IPadModel.mini:
        return isLandscape ? 3 : 2; // Mini needs careful spacing
      default:
        return 1;
    }
  }

  /// Get optimal sidebar width for master-detail layouts
  static double getSidebarWidth(BuildContext context) {
    if (!isIPad(context)) return 0;

    final model = getIPadModel(context);
    switch (model) {
      case IPadModel.pro12:
        return 420.0; // Wider sidebar for large screen
      case IPadModel.pro11:
      case IPadModel.air:
        return 375.0; // Standard sidebar width
      case IPadModel.mini:
        return 320.0; // Narrower for smaller screen
      default:
        return 375.0;
    }
  }

  // ============================================================================
  // SCREEN METRICS
  // ============================================================================

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if app is likely in Split View mode
  ///
  /// Detects if the app is running in Split View by checking if the width
  /// is significantly smaller than expected for the device
  static bool isInSplitView(BuildContext context) {
    if (!isIPad(context)) return false;

    final width = getScreenWidth(context);
    final model = getIPadModel(context);

    // Check if width is reduced (indicating split view)
    switch (model) {
      case IPadModel.pro12:
        // Pro 12.9" in portrait should be 1024, if less than 600, likely split
        return width < 600;
      case IPadModel.pro11:
      case IPadModel.air:
        // Pro 11"/Air should be 834/820, if less than 500, likely split
        return width < 500;
      case IPadModel.mini:
        // Mini should be 744, if less than 450, likely split
        return width < 450;
      default:
        return false;
    }
  }

  /// Get split view ratio estimate
  /// Returns approximate split ratio (0.33 = 1/3, 0.5 = 1/2, 1.0 = full)
  static double getSplitViewRatio(BuildContext context) {
    if (!isInSplitView(context)) return 1.0;

    final width = getScreenWidth(context);

    // Estimate based on width
    if (width < 400) return 0.33; // 1/3 split
    if (width < 600) return 0.5; // 1/2 split
    return 0.67; // 2/3 split
  }

  // ============================================================================
  // HUMAN-READABLE NAMES
  // ============================================================================

  /// Get human-readable device name
  static String getDeviceName(BuildContext context) {
    if (!isIPad(context)) return 'iPhone';

    final model = getIPadModel(context);
    switch (model) {
      case IPadModel.mini:
        return 'iPad Mini';
      case IPadModel.air:
        return 'iPad Air';
      case IPadModel.pro11:
        return 'iPad Pro 11"';
      case IPadModel.pro12:
        return 'iPad Pro 12.9"';
      default:
        return 'iPad';
    }
  }

  /// Get device info string for debugging
  static String getDebugInfo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final model = getIPadModel(context);
    final isIPadDevice = isIPad(context);
    final inSplitView = isInSplitView(context);

    return '''
Device: ${getDeviceName(context)}
Model: ${model.name}
Is iPad: $isIPadDevice
Size: ${size.width.toInt()}x${size.height.toInt()}
Orientation: ${orientation.name}
Split View: $inSplitView
Split Ratio: ${getSplitViewRatio(context).toStringAsFixed(2)}
Max Content Width: ${getMaxContentWidth(context).toInt()}
Optimal Columns: ${getOptimalColumnCount(context)}
Sidebar Width: ${getSidebarWidth(context).toInt()}
''';
  }
}

// ============================================================================
// EXTENSION METHODS FOR EASY ACCESS
// ============================================================================

/// Extension methods on BuildContext for convenient device detection
extension DeviceInfoExtension on BuildContext {
  // iPad Detection
  bool get isIPad => DeviceInfo.isIPad(this);
  IPadModel get iPadModel => DeviceInfo.getIPadModel(this);
  bool get isIPadMini => DeviceInfo.getIPadModel(this) == IPadModel.mini;
  bool get isIPadAir => DeviceInfo.getIPadModel(this) == IPadModel.air;
  bool get isIPadPro11 => DeviceInfo.getIPadModel(this) == IPadModel.pro11;
  bool get isIPadPro12 => DeviceInfo.getIPadModel(this) == IPadModel.pro12;

  // Capabilities
  bool get supportsSplitView => DeviceInfo.supportsSplitView(this);
  bool get supportsSlideOver => DeviceInfo.supportsSlideOver(this);
  bool get supportsStageManager => DeviceInfo.supportsStageManager(this);

  // Layout Dimensions
  double get maxContentWidth => DeviceInfo.getMaxContentWidth(this);
  int get optimalColumnCount => DeviceInfo.getOptimalColumnCount(this);
  double get sidebarWidth => DeviceInfo.getSidebarWidth(this);

  // Screen Metrics
  bool get isLandscape => DeviceInfo.isLandscape(this);
  bool get isPortrait => DeviceInfo.isPortrait(this);
  double get screenWidth => DeviceInfo.getScreenWidth(this);
  double get screenHeight => DeviceInfo.getScreenHeight(this);

  // Split View
  bool get isInSplitView => DeviceInfo.isInSplitView(this);
  double get splitViewRatio => DeviceInfo.getSplitViewRatio(this);

  // Human-readable
  String get deviceName => DeviceInfo.getDeviceName(this);
  String get deviceDebugInfo => DeviceInfo.getDebugInfo(this);
}
