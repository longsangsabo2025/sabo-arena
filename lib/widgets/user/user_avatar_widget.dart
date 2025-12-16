import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/sabo_rank_system.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🎨 UserAvatarWidget - Unified Avatar Display Component
///
/// **Single source of truth** cho việc hiển thị avatar user trong toàn bộ app.
///
/// ## Features:
/// - ✅ Automatic caching với CachedNetworkImage
/// - ✅ Shimmer loading effect
/// - ✅ Graceful error handling với default avatar
/// - ✅ Optional rank border với gradient color
/// - ✅ Consistent sizing và styling
///
/// ## Usage:
/// ```dart
/// // Basic avatar
/// UserAvatarWidget(
///   avatarUrl: user.avatarUrl,
///   size: 50,
/// )
///
/// // Avatar with rank border
/// UserAvatarWidget(
///   avatarUrl: user.avatarUrl,
///   rankCode: 'G',
///   size: 80,
///   showRankBorder: true,
/// )
/// ```
class UserAvatarWidget extends StatelessWidget {
  /// URL của avatar (có thể null)
  final String? avatarUrl;

  /// Kích thước avatar (width = height)
  final double size;

  /// Tên user để hiển thị initials nếu không có avatar
  final String? userName;

  /// Rank code của user (K, I, H, G, E, D, C)
  final String? rankCode;

  /// Hiển thị border gradient theo màu rank
  final bool showRankBorder;

  /// Border width khi có rank border
  final double borderWidth;

  /// Custom placeholder widget (nếu không muốn dùng default)
  final Widget? customPlaceholder;

  /// Custom error widget (nếu không muốn dùng default)
  final Widget? customErrorWidget;

  /// Hiển thị shimmer effect khi loading
  final bool showShimmer;

  const UserAvatarWidget({
    super.key,
    this.avatarUrl,
    this.size = 50,
    this.userName,
    this.rankCode,
    this.showRankBorder = false,
    this.borderWidth = 3,
    this.customPlaceholder,
    this.customErrorWidget,
    this.showShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    // Nếu có rank border, wrap với gradient container
    if (showRankBorder && rankCode != null && rankCode!.isNotEmpty) {
      return _buildWithRankBorder();
    }

    // Avatar thường không có border
    return _buildAvatar();
  }

  /// Avatar với rank border gradient
  Widget _buildWithRankBorder() {
    final rankColor = SaboRankSystem.getRankColor(rankCode!);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            rankColor,
            rankColor.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: _buildAvatar(),
          ),
        ),
      ),
    );
  }

  /// Core avatar widget với caching
  Widget _buildAvatar() {
    final url = avatarUrl?.trim();

    // Validate URL
    if (url == null || url.isEmpty || url == 'null' || url == 'undefined') {
      return _buildDefaultAvatar();
    }

    // Handle SVG avatars (e.g. DiceBear)
    if (url.toLowerCase().contains('.svg') || url.toLowerCase().contains('/svg')) {
      return ClipOval(
        child: FutureBuilder<String>(
          future: _fetchSvg(url),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SvgPicture.string(
                snapshot.data!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholderBuilder: (context) =>
                    customPlaceholder ?? _buildPlaceholder(),
              );
            }
            if (snapshot.hasError) {
              return customErrorWidget ?? _buildDefaultAvatar();
            }
            return customPlaceholder ?? _buildPlaceholder();
          },
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) =>
            customPlaceholder ?? _buildPlaceholder(),
        errorWidget: (context, url, error) {
          ProductionLogger.error('❌ Avatar load error: $url - $error', error: error);
          return customErrorWidget ?? _buildDefaultAvatar();
        },
      ),
    );
  }

  /// Placeholder khi đang loading
  Widget _buildPlaceholder() {
    if (showShimmer) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: size,
          height: size,
          color: Colors.white,
        ),
      );
    }

    // Simple loading indicator
    return Container(
      width: size,
      height: size,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
        ),
      ),
    );
  }

  /// Default avatar khi không có ảnh hoặc lỗi
  Widget _buildDefaultAvatar() {
    if (userName != null && userName!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade300,
              Colors.grey.shade400,
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            userName![0].toUpperCase(),
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }

  static final Map<String, String> _svgCache = {};

  Future<String> _fetchSvg(String url) async {
    if (_svgCache.containsKey(url)) {
      return _svgCache[url]!;
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Clean SVG string to remove unsupported elements
        String svgContent = response.body;

        // Remove <filter>...</filter> blocks
        svgContent = svgContent.replaceAll(
            RegExp(r'<filter[\s\S]*?<\/filter>', caseSensitive: false), '');

        // Remove self-closing <filter/> tags
        svgContent = svgContent.replaceAll(
            RegExp(r'<filter[^>]*\/>', caseSensitive: false), '');

        // Remove filter="..." attributes
        svgContent = svgContent.replaceAll(
            RegExp(r'filter="[^"]*"', caseSensitive: false), '');

        // Remove <metadata>...</metadata> blocks
        svgContent = svgContent.replaceAll(
            RegExp(r'<metadata[\s\S]*?<\/metadata>', caseSensitive: false), '');

        _svgCache[url] = svgContent;
        return svgContent;
      }
      throw Exception('Failed to load SVG');
    } catch (e) {
      ProductionLogger.error('Error loading SVG avatar',
          error: e, tag: 'UserAvatar');
      rethrow;
    }
  }
}

/// 🎨 UserAvatarWithBadge - Avatar with status badge
///
/// Hiển thị avatar với badge nhỏ (online, verified, notification, etc.)
class UserAvatarWithBadge extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final String? rankCode;
  final bool showRankBorder;

  /// Badge widget (e.g., online indicator, verified icon)
  final Widget? badge;

  /// Badge position (topRight, topLeft, bottomRight, bottomLeft)
  final BadgePosition badgePosition;

  const UserAvatarWithBadge({
    super.key,
    this.avatarUrl,
    this.size = 50,
    this.rankCode,
    this.showRankBorder = false,
    this.badge,
    this.badgePosition = BadgePosition.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatarWidget(
          avatarUrl: avatarUrl,
          size: size,
          rankCode: rankCode,
          showRankBorder: showRankBorder,
        ),
        if (badge != null) _positionBadge(badge!),
      ],
    );
  }

  Widget _positionBadge(Widget badge) {
    final offset = size * 0.15;

    switch (badgePosition) {
      case BadgePosition.topRight:
        return Positioned(top: -offset, right: -offset, child: badge);
      case BadgePosition.topLeft:
        return Positioned(top: -offset, left: -offset, child: badge);
      case BadgePosition.bottomLeft:
        return Positioned(bottom: -offset, left: -offset, child: badge);
      case BadgePosition.bottomRight:
        return Positioned(bottom: -offset, right: -offset, child: badge);
    }
  }
}

enum BadgePosition {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
}

/// 🟢 Online Status Badge
class OnlineStatusBadge extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OnlineStatusBadge({
    super.key,
    required this.isOnline,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// ✓ Verified Badge
class VerifiedBadge extends StatelessWidget {
  final double size;
  final Color color;

  const VerifiedBadge({
    super.key,
    this.size = 16,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.check,
        size: size * 0.7,
        color: Colors.white,
      ),
    );
  }
}
