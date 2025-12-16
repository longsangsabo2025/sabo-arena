import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../core/design_system/design_system.dart';

/// Theme constants cho AppBar trong toàn bộ app
class AppBarTheme {
  // Màu xanh lá chủ đạo của app (sử dụng từ design system)
  static const Color primaryGreen = AppColors.primary;

  // Font cho tiêu đề AppBar - SF Pro (iOS) / Roboto (Android)
  // Sử dụng system font để tránh lỗi font trên iOS
  static TextStyle get titleStyle => TextStyle(
    fontFamily: _getFontFamily(),
    fontSize: 18,
    fontWeight: FontWeight.w700, // Bold
    color: primaryGreen,
    letterSpacing: -0.3, // Negative spacing cho iOS style
    height: 1.2,
  );

  // Lấy font family phù hợp với platform
  static String _getFontFamily() {
    try {
      if (Platform.isIOS) {
        return '.SF Pro Display'; // SF Pro Display - iOS system font
      } else {
        return 'Roboto'; // Roboto - Android system font
      }
    } catch (e) {
      return 'Roboto'; // Fallback
    }
  }

  /// Tạo title với gradient effect (xanh đậm -> xanh nhạt)
  static Widget buildGradientTitle(String title) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          AppColors.primary700, // Xanh đậm hơn
          AppColors.primary500, // Xanh chuẩn
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: _getFontFamily(),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white, // Required for ShaderMask
          letterSpacing: -0.3, // Negative spacing cho iOS style
          height: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Tạo AppBar chuẩn cho toàn app
  static AppBar buildAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      leading:
          leading ??
          IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryGreen),
            onPressed: () => Navigator.pop(context),
          ),
      title: buildGradientTitle(title),
      centerTitle: centerTitle,
      actions: actions,
      bottom: bottom,
    );
  }

  /// AppBar cho màn hình chính (không có back button)
  static AppBar buildMainAppBar({
    required String title,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      automaticallyImplyLeading: false,
      title: buildGradientTitle(title),
      centerTitle: false,
      actions: actions,
      bottom: bottom,
    );
  }
}
