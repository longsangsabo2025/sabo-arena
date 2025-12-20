import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/design_system/design_system.dart';
import '../admin_dashboard_screen/admin_voucher_campaign_approval_screen.dart';
import '../club_promotion_hub/club_promotion_hub_screen.dart';

/// Main entry point for voucher management system
/// Redirects to appropriate screens based on user role
class VoucherManagementMainScreen extends StatefulWidget {
  final String userId;
  final String? clubId; // null if user is admin
  final bool isAdmin;

  const VoucherManagementMainScreen({
    super.key,
    required this.userId,
    this.clubId,
    required this.isAdmin,
  });

  @override
  State<VoucherManagementMainScreen> createState() =>
      _VoucherManagementMainScreenState();
}

class _VoucherManagementMainScreenState
    extends State<VoucherManagementMainScreen> {
  @override
  void initState() {
    super.initState();
    // Redirect immediately based on user role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectToAppropriateScreen();
    });
  }

  void _redirectToAppropriateScreen() {
    if (!mounted) return;

    if (widget.isAdmin) {
      // Admin: Redirect to voucher campaign approval screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminVoucherCampaignApprovalScreen(),
        ),
      );
      return;
    }

    if (widget.clubId != null) {
      // Club owner: Redirect to promotion hub
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClubPromotionHubScreen(
            clubId: widget.clubId!,
            clubName: '', // Will be loaded by ClubPromotionHubScreen if needed
          ),
        ),
      );
    }
    // Note: Regular users should not reach this screen via routing
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while redirecting
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DSSpinner.primary(size: DSSpinnerSize.large),
            SizedBox(height: DesignTokens.space24),
            Text(
              'Đang chuyển hướng...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick access widget for voucher features in main app
class VoucherQuickAccess extends StatelessWidget {
  final String userId;
  final String? clubId;
  final bool isAdmin;
  final bool hasVoucherPermissions;

  const VoucherQuickAccess({
    super.key,
    required this.userId,
    this.clubId,
    required this.isAdmin,
    required this.hasVoucherPermissions,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasVoucherPermissions) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(DesignTokens.space16),
      padding: EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: DesignTokens.radius(DesignTokens.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VoucherManagementMainScreen(
                  userId: userId,
                  clubId: clubId,
                  isAdmin: isAdmin,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(2.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.space12),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.2),
                    borderRadius: DesignTokens.radius(DesignTokens.radiusMD),
                  ),
                  child: Icon(Icons.campaign,
                      color: AppColors.textOnPrimary, size: 24),
                ),
                SizedBox(width: DesignTokens.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAdmin
                            ? 'Quản lý Voucher Campaign'
                            : 'Đăng ký Voucher Campaign',
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnPrimary,
                                ),
                      ),
                      SizedBox(height: DesignTokens.space4),
                      Text(
                        isAdmin
                            ? 'Duyệt và quản lý các campaign voucher từ clubs'
                            : 'Tạo và đăng ký campaign voucher cho club của bạn',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textOnPrimary
                                  .withValues(alpha: 0.9),
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: DesignTokens.space8),
                Icon(Icons.arrow_forward_ios,
                    color: AppColors.textOnPrimary, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge showing pending requests count for admins
class AdminVoucherBadge extends StatelessWidget {
  final int pendingCount;

  const AdminVoucherBadge({super.key, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space8,
        vertical: DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: DesignTokens.radius(DesignTokens.radiusFull),
      ),
      child: Text(
        pendingCount > 99 ? '99+' : pendingCount.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// Quick stats widget showing voucher overview
class VoucherStatsPreview extends StatelessWidget {
  final int totalCampaigns;
  final int activeCampaigns;
  final int totalVouchersIssued;
  final bool isAdmin;

  const VoucherStatsPreview({
    super.key,
    required this.totalCampaigns,
    required this.activeCampaigns,
    required this.totalVouchersIssued,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      padding: EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: DesignTokens.radius(DesignTokens.radiusMD),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdmin ? 'Tổng quan Voucher' : 'Campaign của tôi',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: DesignTokens.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context,
                'Campaigns',
                totalCampaigns.toString(),
                Icons.campaign,
                AppColors.info,
              ),
              _buildStatItem(
                context,
                'Đang hoạt động',
                activeCampaigns.toString(),
                Icons.play_circle,
                AppColors.success,
              ),
              _buildStatItem(
                context,
                'Voucher đã phát',
                _formatNumber(totalVouchersIssued),
                Icons.card_giftcard,
                AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.space10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: DesignTokens.radius(DesignTokens.radiusSM),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: DesignTokens.space8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}
