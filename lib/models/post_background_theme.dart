import 'package:flutter/material.dart';

/// Theme cho background của post không có ảnh
class PostBackgroundTheme {
  final String id;
  final String name;
  final BackgroundType type;
  final List<Color> colors; // Gradient colors hoặc solid color
  final String? imageUrl; // URL cho image background
  final double overlayOpacity; // Độ mờ của overlay (0.0 - 1.0)
  final Color overlayColor; // Màu overlay
  final TextStyle textStyle; // Style cho text trên background

  const PostBackgroundTheme({
    required this.id,
    required this.name,
    required this.type,
    required this.colors,
    this.imageUrl,
    this.overlayOpacity = 0.6,
    this.overlayColor = Colors.black,
    required this.textStyle,
  });

  /// Tạo gradient từ colors
  LinearGradient get gradient => LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

enum BackgroundType {
  gradient, // Gradient màu
  solid, // Màu đơn
  image, // Hình ảnh
  billiard, // Hình billiard đặc biệt
}

/// Predefined themes cho posts
class PostBackgroundThemes {
  // Billiard theme - Xanh lá chủ đạo
  static const billiardGreen = PostBackgroundTheme(
    id: 'billiard_green',
    name: 'Billiard Green',
    type: BackgroundType.gradient,
    colors: [
      Color(0xFF004D40), // Teal 900
      Color(0xFF00695C), // Teal 700
      Color(0xFF00897B), // Teal 600
    ],
    overlayOpacity: 0.5,
    overlayColor: Colors.black,
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      shadows: [
        Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 8),
      ],
    ),
  );

  // Gradient xanh dương - Chuyên nghiệp
  static const oceanBlue = PostBackgroundTheme(
    id: 'ocean_blue',
    name: 'Ocean Blue',
    type: BackgroundType.gradient,
    colors: [
      Color(0xFF0D47A1), // Blue 900
      Color(0xFF1976D2), // Blue 700
      Color(0xFF42A5F5), // Blue 400
    ],
    overlayOpacity: 0.5,
    overlayColor: Colors.black,
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      shadows: [
        Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 8),
      ],
    ),
  );

  // Gradient tím - Sáng tạo
  static const purpleDream = PostBackgroundTheme(
    id: 'purple_dream',
    name: 'Purple Dream',
    type: BackgroundType.gradient,
    colors: [
      Color(0xFF4A148C), // Purple 900
      Color(0xFF7B1FA2), // Purple 700
      Color(0xFFAB47BC), // Purple 400
    ],
    overlayOpacity: 0.5,
    overlayColor: Colors.black,
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      shadows: [
        Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 8),
      ],
    ),
  );

  // Gradient cam đỏ - Năng động
  static const sunsetOrange = PostBackgroundTheme(
    id: 'sunset_orange',
    name: 'Sunset Orange',
    type: BackgroundType.gradient,
    colors: [
      Color(0xFFE65100), // Orange 900
      Color(0xFFFF6F00), // Orange 800
      Color(0xFFFF9800), // Orange 500
    ],
    overlayOpacity: 0.5,
    overlayColor: Colors.black,
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      shadows: [
        Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 8),
      ],
    ),
  );

  // Gradient hồng - Năng lượng
  static const pinkEnergy = PostBackgroundTheme(
    id: 'pink_energy',
    name: 'Pink Energy',
    type: BackgroundType.gradient,
    colors: [
      Color(0xFFAD1457), // Pink 800
      Color(0xFFD81B60), // Pink 600
      Color(0xFFEC407A), // Pink 400
    ],
    overlayOpacity: 0.5,
    overlayColor: Colors.black,
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      shadows: [
        Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 8),
      ],
    ),
  );

  // Gradient xanh lam - Bình yên
  static const calmCyan = PostBackgroundTheme(
    id: 'calm_cyan',
    name: 'Calm Cyan',
    type: BackgroundType.gradient,
    colors: [
      Color(0xFF006064), // Cyan 900
      Color(0xFF00838F), // Cyan 700
      Color(0xFF00ACC1), // Cyan 600
    ],
    overlayOpacity: 0.5,
    overlayColor: Colors.black,
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      shadows: [
        Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 8),
      ],
    ),
  );

  // Dark mode - Tối giản
  static const darkMinimal = PostBackgroundTheme(
    id: 'dark_minimal',
    name: 'Dark Minimal',
    type: BackgroundType.gradient,
    colors: [
      Color(0xFF212121), // Grey 900
      Color(0xFF424242), // Grey 800
      Color(0xFF616161), // Grey 700
    ],
    overlayOpacity: 0.4,
    overlayColor: Colors.black,
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      shadows: [
        Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 8),
      ],
    ),
  );

  // Light mode - Sáng sủa
  static const lightBright = PostBackgroundTheme(
    id: 'light_bright',
    name: 'Light Bright',
    type: BackgroundType.gradient,
    colors: [
      Color(0xFFE3F2FD), // Blue 50
      Color(0xFFBBDEFB), // Blue 100
      Color(0xFF90CAF9), // Blue 200
    ],
    overlayOpacity: 0.3,
    overlayColor: Colors.white,
    textStyle: TextStyle(
      color: Color(0xFF1565C0), // Blue 800
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.5,
      shadows: [
        Shadow(color: Colors.white70, offset: Offset(0, 1), blurRadius: 4),
      ],
    ),
  );

  /// Danh sách tất cả themes
  static List<PostBackgroundTheme> get allThemes => [
    billiardGreen, // Default
    oceanBlue,
    purpleDream,
    sunsetOrange,
    pinkEnergy,
    calmCyan,
    darkMinimal,
    lightBright,
  ];

  /// Lấy theme theo ID
  static PostBackgroundTheme? getThemeById(String id) {
    try {
      return allThemes.firstWhere((theme) => theme.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Lấy theme random
  static PostBackgroundTheme getRandomTheme() {
    final index = DateTime.now().millisecondsSinceEpoch % allThemes.length;
    return allThemes[index];
  }

  /// Lấy theme mặc định
  static PostBackgroundTheme get defaultTheme => billiardGreen;
}
