/// DSAvatar - Design System Avatar Component
///
/// Instagram/Facebook quality avatar with:
/// - Multiple sizes (XS to Massive)
/// - Border support (for stories, active states)
/// - Badge/indicator support (online, verified, count)
/// - Tap callback
/// - Placeholder fallback
/// - Loading state
/// - Accessibility support
///
/// Usage:
/// ```dart
/// DSAvatar(
///   imageUrl: user.avatarUrl,
///   size: DSAvatarSize.medium,
///   onTap: () => navigateToProfile(),
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../design_tokens.dart';
import '../app_colors.dart';

/// Avatar sizes following design tokens
enum DSAvatarSize {
  /// 24px - inline mentions, small lists
  extraSmall,

  /// 32px - compact lists, comments
  small,

  /// 40px - standard list items (default)
  medium,

  /// 48px - emphasized items
  large,

  /// 64px - profile headers
  extraLarge,

  /// 80px - large profile displays
  xxLarge,

  /// 96px - profile cards
  huge,

  /// 128px - full profile view
  massive,
}

/// Avatar border style
enum DSAvatarBorderStyle {
  /// No border
  none,

  /// Thin border (1px)
  thin,

  /// Medium border (2px)
  medium,

  /// Thick border (3px) - for stories
  thick,

  /// Gradient border - Instagram stories style
  gradient,
}

/// Badge position on avatar
enum DSAvatarBadgePosition { topRight, topLeft, bottomRight, bottomLeft }

/// Design System Avatar Component
class DSAvatar extends StatelessWidget {
  /// Image URL to display
  final String? imageUrl;

  /// Fallback text (usually initials)
  final String? fallbackText;

  /// Avatar size
  final DSAvatarSize size;

  /// Border style
  final DSAvatarBorderStyle borderStyle;

  /// Border color (if not using gradient)
  final Color? borderColor;

  /// Gradient colors for border (Instagram style)
  final List<Color>? gradientColors;

  /// Show online indicator
  final bool showOnlineIndicator;

  /// Online status
  final bool isOnline;

  /// Show badge
  final bool showBadge;

  /// Badge widget (custom badge)
  final Widget? badge;

  /// Badge position
  final DSAvatarBadgePosition badgePosition;

  /// Tap callback
  final VoidCallback? onTap;

  /// Long press callback
  final VoidCallback? onLongPress;

  /// Background color for fallback
  final Color? backgroundColor;

  /// Text color for fallback
  final Color? textColor;

  /// Show loading state
  final bool isLoading;

  /// Custom placeholder widget
  final Widget? placeholder;

  /// Hero tag for hero animations
  final String? heroTag;

  const DSAvatar({
    super.key,
    this.imageUrl,
    this.fallbackText,
    this.size = DSAvatarSize.medium,
    this.borderStyle = DSAvatarBorderStyle.none,
    this.borderColor,
    this.gradientColors,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.showBadge = false,
    this.badge,
    this.badgePosition = DSAvatarBadgePosition.bottomRight,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.placeholder,
    this.heroTag,
  });

  /// Get size in pixels based on DSAvatarSize enum
  double get _sizeInPixels {
    switch (size) {
      case DSAvatarSize.extraSmall:
        return DesignTokens.avatarXS;
      case DSAvatarSize.small:
        return DesignTokens.avatarSM;
      case DSAvatarSize.medium:
        return DesignTokens.avatarMD;
      case DSAvatarSize.large:
        return DesignTokens.avatarLG;
      case DSAvatarSize.extraLarge:
        return DesignTokens.avatarXL;
      case DSAvatarSize.xxLarge:
        return DesignTokens.avatarXXL;
      case DSAvatarSize.huge:
        return DesignTokens.avatarHuge;
      case DSAvatarSize.massive:
        return DesignTokens.avatarMassive;
    }
  }

  /// Get border width based on style
  double get _borderWidth {
    switch (borderStyle) {
      case DSAvatarBorderStyle.none:
        return 0;
      case DSAvatarBorderStyle.thin:
        return 1;
      case DSAvatarBorderStyle.medium:
        return 2;
      case DSAvatarBorderStyle.thick:
        return 3;
      case DSAvatarBorderStyle.gradient:
        return 3;
    }
  }

  /// Get online indicator size (scales with avatar size)
  double get _onlineIndicatorSize {
    if (_sizeInPixels <= 32) return 8;
    if (_sizeInPixels <= 48) return 10;
    if (_sizeInPixels <= 64) return 12;
    return 14;
  }

  /// Get font size for fallback text
  double get _fallbackFontSize {
    if (_sizeInPixels <= 32) return 12;
    if (_sizeInPixels <= 48) return 16;
    if (_sizeInPixels <= 64) return 20;
    if (_sizeInPixels <= 96) return 28;
    return 36;
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = _buildAvatar(context);

    // Wrap with hero if heroTag provided
    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    // Wrap with GestureDetector if onTap or onLongPress provided
    if (onTap != null || onLongPress != null) {
      avatar = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main avatar with border
        Container(
          width: _sizeInPixels,
          height: _sizeInPixels,
          decoration: _buildBorderDecoration(),
          child: Padding(
            padding: EdgeInsets.all(_borderWidth),
            child: _buildAvatarContent(context),
          ),
        ),

        // Online indicator
        if (showOnlineIndicator)
          Positioned(right: 0, bottom: 0, child: _buildOnlineIndicator()),

        // Badge
        if (showBadge && badge != null) _positionBadge(badge!),
      ],
    );
  }

  /// Build border decoration
  BoxDecoration _buildBorderDecoration() {
    if (borderStyle == DSAvatarBorderStyle.none) {
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      );
    }

    if (borderStyle == DSAvatarBorderStyle.gradient) {
      return BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors ??
              [AppColors.accent500, AppColors.error500, AppColors.premium500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }

    return BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: borderColor ?? AppColors.border,
        width: _borderWidth,
      ),
    );
  }

  /// Build avatar content (image or fallback)
  Widget _buildAvatarContent(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _buildImageAvatar();
    }

    if (placeholder != null) {
      return ClipOval(child: placeholder!);
    }

    return _buildFallbackAvatar();
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gray200,
      ),
      child: Center(
        child: SizedBox(
          width: _sizeInPixels * 0.4,
          height: _sizeInPixels * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }

  /// Build image avatar
  Widget _buildImageAvatar() {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: _sizeInPixels,
        height: _sizeInPixels,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.gray200,
          child: Center(
            child: SizedBox(
              width: _sizeInPixels * 0.4,
              height: _sizeInPixels * 0.4,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackAvatar(),
      ),
    );
  }

  /// Build fallback avatar (initials or icon)
  Widget _buildFallbackAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.primary100,
      ),
      child: Center(
        child: fallbackText != null && fallbackText!.isNotEmpty
            ? Text(
                _getInitials(fallbackText!),
                style: TextStyle(
                  fontSize: _fallbackFontSize,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? AppColors.primary,
                ),
              )
            : Icon(
                Icons.person,
                size: _sizeInPixels * 0.5,
                color: textColor ?? AppColors.primary,
              ),
      ),
    );
  }

  /// Build online indicator
  Widget _buildOnlineIndicator() {
    return Container(
      width: _onlineIndicatorSize,
      height: _onlineIndicatorSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? AppColors.success : AppColors.gray400,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
    );
  }

  /// Extract initials from text (max 2 characters)
  String _getInitials(String text) {
    final words = text.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return text.substring(0, text.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Position badge based on badgePosition
  Widget _positionBadge(Widget badge) {
    switch (badgePosition) {
      case DSAvatarBadgePosition.topRight:
        return Positioned(top: -4, right: -4, child: badge);
      case DSAvatarBadgePosition.topLeft:
        return Positioned(top: -4, left: -4, child: badge);
      case DSAvatarBadgePosition.bottomLeft:
        return Positioned(bottom: -4, left: -4, child: badge);
      case DSAvatarBadgePosition.bottomRight:
        return Positioned(bottom: -4, right: -4, child: badge);
    }
  }
}

/// Avatar badge for verified, count, etc.
class DSAvatarBadge extends StatelessWidget {
  /// Badge icon
  final IconData? icon;

  /// Badge text (for count)
  final String? text;

  /// Badge color
  final Color? color;

  /// Badge size
  final double size;

  const DSAvatarBadge({
    super.key,
    this.icon,
    this.text,
    this.color,
    this.size = 20,
  });

  /// Verified badge (blue checkmark)
  factory DSAvatarBadge.verified({double size = 20}) {
    return DSAvatarBadge(
      icon: Icons.verified,
      color: AppColors.info,
      size: size,
    );
  }

  /// Premium badge (gold star)
  factory DSAvatarBadge.premium({double size = 20}) {
    return DSAvatarBadge(
      icon: Icons.stars,
      color: AppColors.premium,
      size: size,
    );
  }

  /// Count badge (notification count)
  factory DSAvatarBadge.count({required int count, double size = 20}) {
    return DSAvatarBadge(
      text: count > 99 ? '99+' : count.toString(),
      color: AppColors.error,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? AppColors.primary,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: size * 0.6, color: AppColors.surface)
            : Text(
                text ?? '',
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surface,
                ),
              ),
      ),
    );
  }
}

/// Avatar group - show multiple avatars overlapped
class DSAvatarGroup extends StatelessWidget {
  /// List of image URLs
  final List<String> imageUrls;

  /// Avatar size
  final DSAvatarSize size;

  /// Max avatars to show (remaining shown as +N)
  final int maxAvatars;

  /// Overlap amount (0-1, where 1 = full overlap)
  final double overlap;

  /// Tap callback with index
  final void Function(int index)? onTap;

  const DSAvatarGroup({
    super.key,
    required this.imageUrls,
    this.size = DSAvatarSize.small,
    this.maxAvatars = 3,
    this.overlap = 0.3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount =
        imageUrls.length > maxAvatars ? maxAvatars : imageUrls.length;
    final remaining = imageUrls.length - maxAvatars;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: List.generate(displayCount, (index) {
            final avatarSize = _getAvatarSize();
            return Positioned(
              left: index * avatarSize * (1 - overlap),
              child: DSAvatar(
                imageUrl: imageUrls[index],
                size: size,
                borderStyle: DSAvatarBorderStyle.medium,
                borderColor: AppColors.surface,
                onTap: onTap != null ? () => onTap!(index) : null,
              ),
            );
          }),
        ),
        if (remaining > 0)
          Padding(
            padding: EdgeInsets.only(
              left: _getAvatarSize() * (1 - overlap) * displayCount,
            ),
            child: DSAvatar(
              size: size,
              fallbackText: '+$remaining',
              backgroundColor: AppColors.gray300,
              textColor: AppColors.gray700,
              borderStyle: DSAvatarBorderStyle.medium,
              borderColor: AppColors.surface,
            ),
          ),
      ],
    );
  }

  double _getAvatarSize() {
    switch (size) {
      case DSAvatarSize.extraSmall:
        return DesignTokens.avatarXS;
      case DSAvatarSize.small:
        return DesignTokens.avatarSM;
      case DSAvatarSize.medium:
        return DesignTokens.avatarMD;
      case DSAvatarSize.large:
        return DesignTokens.avatarLG;
      case DSAvatarSize.extraLarge:
        return DesignTokens.avatarXL;
      case DSAvatarSize.xxLarge:
        return DesignTokens.avatarXXL;
      case DSAvatarSize.huge:
        return DesignTokens.avatarHuge;
      case DSAvatarSize.massive:
        return DesignTokens.avatarMassive;
    }
  }
}
