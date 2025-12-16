import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_background_theme.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service quản lý background settings cho posts
class PostBackgroundService {
  static const String _keySelectedTheme = 'post_background_theme';
  static const String _keyAutoRotate = 'post_background_auto_rotate';
  static const String _keyCustomBackgrounds = 'post_background_custom_list';

  static PostBackgroundService? _instance;
  static PostBackgroundService get instance {
    _instance ??= PostBackgroundService._();
    return _instance!;
  }

  PostBackgroundService._();

  /// Lấy theme đã chọn
  Future<PostBackgroundTheme> getSelectedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeId = prefs.getString(_keySelectedTheme);

      if (themeId != null) {
        final theme = PostBackgroundThemes.getThemeById(themeId);
        if (theme != null) {
          return theme;
        }
      }

      return PostBackgroundThemes.defaultTheme;
    } catch (e) {
      return PostBackgroundThemes.defaultTheme;
    }
  }

  /// Lưu theme đã chọn
  Future<void> saveSelectedTheme(String themeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedTheme, themeId);
    } catch (e) {
      ProductionLogger.info('Error saving theme: $e', tag: 'post_background_service');
    }
  }

  /// Kiểm tra auto rotate có bật không
  Future<bool> isAutoRotateEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAutoRotate) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Bật/tắt auto rotate
  Future<void> setAutoRotate(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutoRotate, enabled);
    } catch (e) {
      ProductionLogger.info('Error saving auto rotate: $e', tag: 'post_background_service');
    }
  }

  /// Lấy theme cho post (auto rotate hoặc theme đã chọn)
  Future<PostBackgroundTheme> getThemeForPost({String? postId}) async {
    final autoRotate = await isAutoRotateEnabled();

    if (autoRotate) {
      // Nếu auto rotate, dùng postId để chọn theme nhất quán
      if (postId != null) {
        final index =
            postId.hashCode.abs() % PostBackgroundThemes.allThemes.length;
        return PostBackgroundThemes.allThemes[index];
      }
      // Nếu không có postId, random
      return PostBackgroundThemes.getRandomTheme();
    }

    // Nếu không auto rotate, dùng theme đã chọn
    return await getSelectedTheme();
  }

  /// Lấy danh sách custom backgrounds (future feature)
  Future<List<String>> getCustomBackgrounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keyCustomBackgrounds) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Thêm custom background (future feature)
  Future<void> addCustomBackground(String imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getCustomBackgrounds();
      current.add(imageUrl);
      await prefs.setStringList(_keyCustomBackgrounds, current);
    } catch (e) {
      ProductionLogger.info('Error adding custom background: $e', tag: 'post_background_service');
    }
  }

  /// Xóa custom background (future feature)
  Future<void> removeCustomBackground(String imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getCustomBackgrounds();
      current.remove(imageUrl);
      await prefs.setStringList(_keyCustomBackgrounds, current);
    } catch (e) {
      ProductionLogger.info('Error removing custom background: $e', tag: 'post_background_service');
    }
  }

  /// Reset về mặc định
  Future<void> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySelectedTheme);
      await prefs.remove(_keyAutoRotate);
      await prefs.remove(_keyCustomBackgrounds);
    } catch (e) {
      ProductionLogger.info('Error resetting: $e', tag: 'post_background_service');
    }
  }
}
