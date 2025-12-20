import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/post_background_theme.dart';

/// Card hiển thị post không có ảnh với background đẹp
class PostBackgroundCard extends StatelessWidget {
  final String content;
  final PostBackgroundTheme? theme;
  final double height;
  final VoidCallback? onTap;

  const PostBackgroundCard({
    super.key,
    required this.content,
    this.theme,
    this.height = 300,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTheme = theme ?? PostBackgroundThemes.defaultTheme;

    // 🎯 AUTO-FIT FONT SIZE dựa trên độ dài content
    final fontSize =
        _calculateFontSize(content, selectedTheme.textStyle.fontSize ?? 16);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background layer
              _buildBackground(selectedTheme),

              // Overlay layer để tăng độ nổi bật cho chữ
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      selectedTheme.overlayColor.withValues(
                        alpha: selectedTheme.overlayOpacity * 0.3,
                      ),
                      selectedTheme.overlayColor.withValues(
                        alpha: selectedTheme.overlayOpacity * 0.6,
                      ),
                      selectedTheme.overlayColor.withValues(
                        alpha: selectedTheme.overlayOpacity * 0.8,
                      ),
                    ],
                  ),
                ),
              ),

              // Content layer
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon billiard (optional)
                      if (selectedTheme.id == 'billiard_green') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.sports_baseball,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Content text với auto-fit font size
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width - 80,
                              ),
                              child: Text(
                                content,
                                style: selectedTheme.textStyle.copyWith(
                                  fontFamily: _getSystemFont(),
                                  fontSize: fontSize,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 20, // Cho phép nhiều dòng
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Decorative line
                      Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Shine effect (subtle)
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(PostBackgroundTheme theme) {
    switch (theme.type) {
      case BackgroundType.gradient:
      case BackgroundType.billiard:
        return Container(decoration: BoxDecoration(gradient: theme.gradient));

      case BackgroundType.solid:
        return Container(color: theme.colors.first);

      case BackgroundType.image:
        if (theme.imageUrl != null) {
          return Image.network(
            theme.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to gradient
              return Container(
                decoration: BoxDecoration(gradient: theme.gradient),
              );
            },
          );
        }
        return Container(decoration: BoxDecoration(gradient: theme.gradient));
    }
  }

  /// Tính toán font size dựa trên độ dài content để tránh tràn
  double _calculateFontSize(String content, double baseFontSize) {
    final contentLength = content.length;

    // Quy tắc:
    // - Nội dung ngắn (< 100 ký tự): font size gốc
    // - Nội dung trung bình (100-200): giảm 10%
    // - Nội dung dài (200-300): giảm 20%
    // - Nội dung rất dài (> 300): giảm 30%

    if (contentLength < 100) {
      return baseFontSize;
    } else if (contentLength < 200) {
      return baseFontSize * 0.9;
    } else if (contentLength < 300) {
      return baseFontSize * 0.8;
    } else {
      return baseFontSize * 0.7;
    }
  }

  String _getSystemFont() {
    try {
      if (kIsWeb) return 'Roboto';
      if (Platform.isIOS) {
        return '.SF Pro Display';
      } else {
        return 'Roboto';
      }
    } catch (e) {
      return 'Roboto';
    }
  }
}

/// Compact version cho grid view
class PostBackgroundCardCompact extends StatelessWidget {
  final String content;
  final PostBackgroundTheme? theme;
  final VoidCallback? onTap;

  const PostBackgroundCardCompact({
    super.key,
    required this.content,
    this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTheme = theme ?? PostBackgroundThemes.defaultTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background
              Container(
                decoration: BoxDecoration(gradient: selectedTheme.gradient),
              ),

              // Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Text(
                    content,
                    style: TextStyle(
                      fontFamily: _getSystemFont(),
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSystemFont() {
    try {
      if (kIsWeb) return 'Roboto';
      if (Platform.isIOS) {
        return '.SF Pro Display';
      } else {
        return 'Roboto';
      }
    } catch (e) {
      return 'Roboto';
    }
  }
}
