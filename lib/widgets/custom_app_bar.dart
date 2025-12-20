import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/design_system/design_system.dart';
import 'animated_sabo_logo.dart';
import 'notification_badge.dart';

// Helper để lấy font family phù hợp
String _getSystemFont() {
  try {
    if (kIsWeb) return 'Roboto';
    if (Platform.isIOS) {
      return '.SF Pro Display'; // SF Pro Display - iOS
    } else {
      return 'Roboto'; // Roboto - Android
    }
  } catch (e) {
    return 'Roboto'; // Fallback
  }
}

/// Custom app bar variants for different screens
enum CustomAppBarVariant {
  /// Standard app bar with title and back button
  standard,

  /// Home feed app bar with search and notifications
  homeFeed,

  /// Tournament app bar with actions
  tournament,

  /// Profile app bar with edit action
  profile,

  /// Search app bar with search field
  search,
}

/// A customizable app bar widget that provides consistent navigation
/// and branding across the Vietnamese billiards social networking app
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The variant of the app bar to display
  final CustomAppBarVariant variant;

  /// The title to display in the app bar
  final String? title;

  /// Whether to show the back button (auto-detected if null)
  final bool? showBackButton;

  /// Custom leading widget (overrides back button)
  final Widget? leading;

  /// List of action widgets to display
  final List<Widget>? actions;

  /// Callback for search text changes (search variant only)
  final ValueChanged<String>? onSearchChanged;

  /// Search hint text (search variant only)
  final String? searchHint;

  /// Whether the app bar is elevated
  final bool elevated;

  /// Custom background color (overrides theme)
  final Color? backgroundColor;

  /// Whether to center the title
  final bool centerTitle;

  /// Whether to show notification badge icon (added to actions)
  final bool showNotificationBadge;

  /// Callback when notification badge is tapped
  final VoidCallback? onNotificationTap;

  const CustomAppBar({
    super.key,
    this.variant = CustomAppBarVariant.standard,
    this.title,
    this.showBackButton,
    this.leading,
    this.actions,
    this.onSearchChanged,
    this.searchHint,
    this.elevated = true,
    this.backgroundColor,
    this.centerTitle = true,
    this.showNotificationBadge = true, // Mặc định hiển thị notification badge
    this.onNotificationTap,
  });

  /// Factory constructor for home feed app bar
  factory CustomAppBar.homeFeed({
    Key? key,
    VoidCallback? onNotificationTap,
    VoidCallback? onSearchTap,
  }) {
    return CustomAppBar(
      key: key,
      variant: CustomAppBarVariant.homeFeed,
      title: 'SABO ARENA',
      showBackButton: false,
      centerTitle: false,
      showNotificationBadge: false, // Đã có trong actions rồi, không thêm nữa
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchTap,
          tooltip: 'Tìm kiếm',
        ),
        NotificationBadge(
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onNotificationTap,
            tooltip: 'Thông báo',
          ),
        ),
      ],
    );
  }

  /// Factory constructor for tournament app bar
  factory CustomAppBar.tournament({
    Key? key,
    required String title,
    VoidCallback? onShareTap,
    VoidCallback? onFavoriteTap,
    bool isFavorite = false,
    bool showNotificationBadge = true,
    VoidCallback? onNotificationTap,
  }) {
    return CustomAppBar(
      key: key,
      variant: CustomAppBarVariant.tournament,
      title: title,
      showNotificationBadge: showNotificationBadge,
      onNotificationTap: onNotificationTap,
      actions: [
        IconButton(
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          onPressed: onFavoriteTap,
          tooltip: isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: onShareTap,
          tooltip: 'Chia sẻ',
        ),
      ],
    );
  }

  /// Factory constructor for profile app bar
  factory CustomAppBar.profile({
    Key? key,
    required String title,
    VoidCallback? onEditTap,
    VoidCallback? onSettingsTap,
    bool showNotificationBadge = true,
    VoidCallback? onNotificationTap,
  }) {
    return CustomAppBar(
      key: key,
      variant: CustomAppBarVariant.profile,
      title: title,
      showNotificationBadge: showNotificationBadge,
      onNotificationTap: onNotificationTap,
      actions: [
        if (onEditTap != null)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEditTap,
            tooltip: 'Chỉnh sửa',
          ),
        if (onSettingsTap != null)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: onSettingsTap,
            tooltip: 'Cài đặt',
          ),
      ],
    );
  }

  /// Factory constructor for search app bar
  factory CustomAppBar.search({
    Key? key,
    required ValueChanged<String> onSearchChanged,
    String searchHint = 'Tìm kiếm...',
    VoidCallback? onFilterTap,
    bool showNotificationBadge = true,
    VoidCallback? onNotificationTap,
  }) {
    return CustomAppBar(
      key: key,
      variant: CustomAppBarVariant.search,
      onSearchChanged: onSearchChanged,
      searchHint: searchHint,
      showNotificationBadge: showNotificationBadge,
      onNotificationTap: onNotificationTap,
      actions: onFilterTap != null
          ? [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: onFilterTap,
                tooltip: 'Bộ lọc',
              ),
            ]
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show back button
    final shouldShowBack = showBackButton ??
        (leading == null && ModalRoute.of(context)?.canPop == true);

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.surface,
      foregroundColor: AppColors.primary, // Màu xanh lá chủ đạo
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      surfaceTintColor: Colors.transparent,
      centerTitle: false, // Căn trái theo chuẩn
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      // iOS bottom border
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(color: AppColors.divider, height: 0.5),
      ),

      // Leading widget
      leading: leading ?? (shouldShowBack ? _buildBackButton(context) : null),
      automaticallyImplyLeading: false,

      // Title based on variant
      title: _buildTitle(context),

      // Actions (with optional notification badge)
      actions: _buildActions(context),

      // Title spacing
      titleSpacing: leading != null || shouldShowBack ? 0 : 16,
    );
  }

  /// Build actions list with optional notification badge
  List<Widget>? _buildActions(BuildContext context) {
    // If showNotificationBadge is true, add badge to actions
    if (showNotificationBadge) {
      final notificationWidget = NotificationBadge(
        child: IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Use provided callback or default navigation
            if (onNotificationTap != null) {
              onNotificationTap!();
            } else {
              // Default: navigate to notification list screen
              Navigator.pushNamed(context, '/notification_list');
            }
          },
          tooltip: 'Thông báo',
        ),
      );

      // Combine with existing actions
      if (actions != null && actions!.isNotEmpty) {
        return [...actions!, notificationWidget, const SizedBox(width: 8)];
      } else {
        return [notificationWidget, const SizedBox(width: 8)];
      }
    }

    return actions;
  }

  Widget? _buildTitle(BuildContext context) {
    switch (variant) {
      case CustomAppBarVariant.search:
        return _buildSearchField(context);

      case CustomAppBarVariant.homeFeed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo PNG load nhanh hơn SVG, không cần placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  // Không cần placeholder vì PNG load rất nhanh
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback nếu không load được
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sports_baseball,
                        color: AppColors.surface,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // SABO ARENA với hiệu ứng gradient và shadow chuyên nghiệp
            StaticSaboLogo(text: title ?? 'SABO ARENA', fontSize: 20),
          ],
        );

      default:
        return title != null
            ? ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppColors.primary700, // Xanh đậm hơn
                    AppColors.primary500, // Xanh chuẩn
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontFamily: _getSystemFont(),
                    fontSize: 18,
                    fontWeight: FontWeight.w700, // Bold
                    color: Colors.white, // Required for ShaderMask
                    letterSpacing: -0.3, // Negative spacing cho iOS style
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null;
    }
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.gray100, // iOS gray background
        borderRadius: BorderRadius.circular(10), // iOS corner radius
      ),
      child: TextField(
        onChanged: onSearchChanged,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: searchHint ?? 'Tìm kiếm...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.primary, // Màu xanh lá
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Quay lại',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
