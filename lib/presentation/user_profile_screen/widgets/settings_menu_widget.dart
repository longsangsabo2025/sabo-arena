import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class SettingsMenuWidget extends StatelessWidget {
  final VoidCallback? onAccountSettings;
  final VoidCallback? onPrivacySettings;
  final VoidCallback? onNotificationSettings;
  final VoidCallback? onLanguageSettings;
  final VoidCallback? onPaymentHistory;
  final VoidCallback? onHelpSupport;
  final VoidCallback? onAbout;
  final VoidCallback? onLogout;
  final VoidCallback? onClubManagement;
  final VoidCallback? onSwitchToPlayerView;
  final bool isClubOwner;
  final bool isInAdminMode;

  const SettingsMenuWidget({
    super.key,
    this.onAccountSettings,
    this.onPrivacySettings,
    this.onNotificationSettings,
    this.onLanguageSettings,
    this.onPaymentHistory,
    this.onHelpSupport,
    this.onAbout,
    this.onLogout,
    this.onClubManagement,
    this.onSwitchToPlayerView,
    this.isClubOwner = false,
    this.isInAdminMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tùy chọn',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Menu Items
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                if (isClubOwner)
                  _buildMenuItem(
                    context,
                    icon: Icons.business_outlined,
                    iconColor: Theme.of(context).colorScheme.primary,
                    iconBackground: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    title: 'Quản lý CLB',
                    subtitle: 'Giao diện quản lý câu lạc bộ',
                    onTap: onClubManagement,
                  ),

                if (isInAdminMode)
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    iconColor: Colors.green,
                    iconBackground: Colors.green.withValues(alpha: 0.1),
                    title: 'Chế độ người chơi',
                    subtitle: 'Chuyển về giao diện người chơi',
                    onTap: onSwitchToPlayerView,
                  ),

                _buildMenuItem(
                  context,
                  icon: Icons.share_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  iconBackground: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  title: 'Chia sẻ hồ sơ',
                  subtitle: 'Chia sẻ hồ sơ của bạn với bạn bè',
                  onTap: () {},
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.content_copy_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  iconBackground: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  title: 'Sao chép liên kết',
                  subtitle: 'Sao chép đường dẫn đến hồ sơ',
                  onTap: () {},
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.person_outline,
                  iconColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  iconBackground: Theme.of(context).colorScheme.surfaceContainerHighest,
                  title: 'Tài khoản',
                  subtitle: 'Thông tin cá nhân, bảo mật',
                  onTap: onAccountSettings,
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  iconColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  iconBackground: Theme.of(context).colorScheme.surfaceContainerHighest,
                  title: 'Thông báo',
                  subtitle: 'Cài đặt thông báo push',
                  onTap: onNotificationSettings,
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.language,
                  iconColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  iconBackground: Theme.of(context).colorScheme.surfaceContainerHighest,
                  title: 'Ngôn ngữ',
                  subtitle: 'Tiếng Việt, English',
                  onTap: onLanguageSettings,
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.help_outline,
                  iconColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  iconBackground: Theme.of(context).colorScheme.surfaceContainerHighest,
                  title: 'Trợ giúp & Hỗ trợ',
                  subtitle: 'FAQ, liên hệ',
                  onTap: onHelpSupport,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 10),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                        letterSpacing: -0.1,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool showDivider = true,
    bool highlight = false,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          leading: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: highlight
                  ? Colors.orange.withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: highlight
                  ? Colors.orange
                  : AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: CustomIconWidget(
            iconName: 'chevron_right',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.lightTheme.colorScheme.outline.withValues(
              alpha: 0.1,
            ),
            indent: 4.w,
            endIndent: 4.w,
          ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CustomIconWidget(iconName: 'logout', color: Colors.red, size: 24),
            SizedBox(width: 3.w),
            Text(
              'Đăng xuất',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onLogout != null) {
                onLogout!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerViewItem(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onSwitchToPlayerView,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          leading: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'sports_esports',
              color: Colors.green,
              size: 20,
            ),
          ),
          title: Text(
            'Quay về giao diện Player',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Chuyển sang chế độ người chơi',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: CustomIconWidget(
            iconName: 'chevron_right',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: AppTheme.lightTheme.colorScheme.outlineVariant,
          indent: 4.w,
          endIndent: 4.w,
        ),
      ],
    );
  }
}
