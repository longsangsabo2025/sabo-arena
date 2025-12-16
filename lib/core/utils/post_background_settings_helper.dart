import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/post_background_theme.dart';

/// Helper class để load và apply background settings cho posts
/// Use this when creating posts without images
class PostBackgroundSettingsHelper {
  // Keys for SharedPreferences
  static const String _keyThemeId = 'post_bg_theme_id';
  static const String _keyAutoRotate = 'post_bg_auto_rotate';
  static const String _keyCustomImage = 'post_bg_custom_image';
  static const String _keyBrightness = 'post_bg_brightness';
  static const String _keyOverlayColor = 'post_bg_overlay_color';
  static const String _keyOverlayOpacity = 'post_bg_overlay_opacity';

  /// Get current theme ID
  static Future<String> getThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeId) ?? PostBackgroundThemes.defaultTheme.id;
  }

  /// Get auto-rotate setting
  static Future<bool> getAutoRotate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoRotate) ?? false;
  }

  /// Get custom background image (if any)
  static Future<File?> getCustomImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_keyCustomImage);

    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return file;
      }
    }
    return null;
  }

  /// Get brightness value (-1.0 to 1.0)
  static Future<double> getBrightness() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyBrightness) ?? 0.0;
  }

  /// Get overlay color
  static Future<Color> getOverlayColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_keyOverlayColor);
    return colorValue != null ? Color(colorValue) : Colors.black;
  }

  /// Get overlay opacity (0.0 to 1.0)
  static Future<double> getOverlayOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyOverlayOpacity) ?? 0.3;
  }

  /// Get complete background settings
  static Future<PostBackgroundSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return PostBackgroundSettings(
      themeId:
          prefs.getString(_keyThemeId) ?? PostBackgroundThemes.defaultTheme.id,
      autoRotate: prefs.getBool(_keyAutoRotate) ?? false,
      customImagePath: prefs.getString(_keyCustomImage),
      brightness: prefs.getDouble(_keyBrightness) ?? 0.0,
      overlayColor: prefs.getInt(_keyOverlayColor) != null
          ? Color(prefs.getInt(_keyOverlayColor)!)
          : Colors.black,
      overlayOpacity: prefs.getDouble(_keyOverlayOpacity) ?? 0.3,
    );
  }

  /// Build background decoration from settings
  static Future<BoxDecoration> buildBackgroundDecoration({
    PostBackgroundSettings? settings,
    File? customImage,
  }) async {
    settings ??= await getSettings();

    // If has custom image
    if (customImage != null || settings.customImagePath != null) {
      final imageFile =
          customImage ??
          (settings.customImagePath != null
              ? File(settings.customImagePath!)
              : null);

      if (imageFile != null && imageFile.existsSync()) {
        return BoxDecoration(
          image: DecorationImage(
            image: FileImage(imageFile),
            fit: BoxFit.cover,
            colorFilter: _buildColorFilter(
              settings.brightness,
              settings.overlayColor,
              settings.overlayOpacity,
            ),
          ),
        );
      }
    }

    // Use preset theme
    final theme =
        PostBackgroundThemes.getThemeById(settings.themeId) ??
        PostBackgroundThemes.defaultTheme;

    return BoxDecoration(gradient: theme.gradient);
  }

  /// Build color filter for brightness and overlay
  static ColorFilter? _buildColorFilter(
    double brightness,
    Color overlayColor,
    double overlayOpacity,
  ) {
    if (brightness == 0.0 && overlayOpacity == 0.0) {
      return null;
    }

    // Combine brightness and overlay
    // This is a simplified version, you may need more complex matrix
    return ColorFilter.mode(
      brightness > 0
          ? Colors.white.withValues(alpha: brightness.abs() * 0.5)
          : Colors.black.withValues(alpha: brightness.abs() * 0.5),
      BlendMode.overlay,
    );
  }

  /// Get random theme (for auto-rotate)
  static PostBackgroundTheme getRandomTheme() {
    return PostBackgroundThemes.getRandomTheme();
  }
}

/// Data class for post background settings
class PostBackgroundSettings {
  final String themeId;
  final bool autoRotate;
  final String? customImagePath;
  final double brightness;
  final Color overlayColor;
  final double overlayOpacity;

  PostBackgroundSettings({
    required this.themeId,
    required this.autoRotate,
    this.customImagePath,
    required this.brightness,
    required this.overlayColor,
    required this.overlayOpacity,
  });

  /// Check if using custom image
  bool get hasCustomImage =>
      customImagePath != null && customImagePath!.isNotEmpty;

  /// Get custom image file
  File? get customImageFile {
    if (customImagePath == null) return null;
    final file = File(customImagePath!);
    return file.existsSync() ? file : null;
  }

  /// Get theme
  PostBackgroundTheme get theme {
    return PostBackgroundThemes.getThemeById(themeId) ??
        PostBackgroundThemes.defaultTheme;
  }

  @override
  String toString() {
    return 'PostBackgroundSettings('
        'themeId: $themeId, '
        'autoRotate: $autoRotate, '
        'hasCustomImage: $hasCustomImage, '
        'brightness: $brightness, '
        'overlayOpacity: $overlayOpacity'
        ')';
  }
}
