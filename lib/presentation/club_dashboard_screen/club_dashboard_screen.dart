import 'package:flutter/material.dart';
// Temporarily removed: // Temporarily removed AppLocalizations import
import 'package:image_picker/image_picker.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'package:sabo_arena/core/device/device_info.dart';
import 'package:sabo_arena/services/auth_service.dart';
import 'package:sabo_arena/services/club_permission_service.dart';
import 'package:sabo_arena/services/club_service.dart';
import 'package:sabo_arena/theme/app_theme.dart' as OldTheme;

import '../../models/club_role.dart';
import '../../routes/app_routes.dart';
import '../activity_history_screen/activity_history_screen.dart';
import '../club_profile_edit_screen/club_profile_edit_screen_simple.dart';
import '../club_reports_screen/club_reports_screen.dart';
import '../club_settings_screen/club_settings_screen.dart';
import '../member_management_screen/member_management_screen.dart';
import '../reservation_management_screen/reservation_management_screen.dart';
import '../spa_management/club_spa_management_screen.dart';
import '../tournament_creation_wizard/tournament_creation_wizard.dart';
import 'club_owner_rank_approval_screen.dart';
import 'controllers/club_dashboard_controller.dart';
import 'widgets/activity_filter_bar.dart';
import 'widgets/club_header_widget.dart';
import 'widgets/dashboard_stats_widget.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/recent_activities_list.dart';
import '../../widgets/notification_badge.dart'; // Import NotificationBadge
import '../notification_list_screen.dart'; // Import NotificationListScreen

class ClubDashboardScreen extends StatefulWidget {
  final String clubId;

  const ClubDashboardScreen({super.key, required this.clubId});

  @override
  State<ClubDashboardScreen> createState() => _ClubDashboardScreenState();
}

class _ClubDashboardScreenState extends State<ClubDashboardScreen> {
  late ClubDashboardController _controller;
  String _selectedActivityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _controller = ClubDashboardController(clubId: widget.clubId);
    _controller.loadData();
  }

  Future<void> _loadData() async {
    await _controller.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildModernAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            if (_controller.isLoading && _controller.club == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.error != null && _controller.club == null) {
              // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi tải dữ liệu',
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _controller.error!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    DSButton(
                      text: 'Thử lại',
                      onPressed: _loadData,
                      variant: DSButtonVariant.primary,
                    ),
                  ],
                ),
              );
            }

            return _buildResponsiveBody();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Bảng điều khiển CLB',
        style: TextStyle(
          color: Colors.grey[800],
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        NotificationBadge(
          contextType: NotificationContext.club,
          child: IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
            onPressed: _navigateToNotifications,
          ),
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: Colors.grey[600]),
          onPressed: _navigateToClubSettings,
        ),
      ],
    );
  }

  Widget _buildResponsiveBody() {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    final isIPad = DeviceInfo.isIPad(context);
    final maxWidth = isIPad ? 1000.0 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              ClubHeaderWidget(
                club: _controller.club,
                onEditProfile: _editClubProfileImage,
                onEditCover: _editClubProfile,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardStatsWidget(
                      stats: _controller.stats,
                      activityCount: _controller.activities.length,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Thao tác nhanh', Icons.speed),
                    const SizedBox(height: 16),
                    QuickActionsGrid(actions: _getQuickActions()),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildSectionHeader(
                            'Hoạt động gần đây',
                            Icons.timeline,
                            onViewAll: _navigateToActivityHistory,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.file_download,
                            color: OldTheme.AppTheme.primaryLight,
                          ),
                          onPressed: () {}, // TODO: Implement export
                          tooltip: 'Xuất báo cáo',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ActivityFilterBar(
                      selectedFilter: _selectedActivityFilter,
                      onFilterSelected: (filter) {
                        setState(() {
                          _selectedActivityFilter = filter;
                        });
                      },
                      onDateRangeSelected: () {}, // TODO: Implement date range
                    ),
                    const SizedBox(height: 16),
                    RecentActivitiesList(activities: _controller.activities),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    VoidCallback? onViewAll,
  }) {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(icon, color: OldTheme.AppTheme.primaryLight, size: 24),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const Spacer(),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'Xem tất cả',
              style: TextStyle(
                color: OldTheme.AppTheme.primaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  List<QuickActionItem> _getQuickActions() {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    return [
      QuickActionItem(
        label: 'Thành viên',
        icon: AppIcons.following,
        iconColor: AppColors.info,
        onTap: _navigateToMemberManagement,
      ),
      QuickActionItem(
        label: 'Duyệt hạng',
        icon: Icons.verified_user,
        iconColor: AppColors.success,
        badge: _controller.pendingRankRequests > 0
            ? _controller.pendingRankRequests.toString()
            : null,
        onTap: _navigateToRankApproval,
      ),
      QuickActionItem(
        label: 'Ví SPA',
        icon: Icons.wallet,
        iconColor: Colors.deepPurple,
        onTap: _navigateToSpaManagement,
      ),
      QuickActionItem(
        label: 'Tạo giải đấu',
        icon: AppIcons.trophy,
        iconColor: AppColors.warning,
        onTap: _navigateToTournamentCreate,
      ),
      QuickActionItem(
        label: 'Chiến dịch chào mừng',
        icon: Icons.celebration,
        iconColor: Colors.purple,
        onTap: _navigateToWelcomeCampaign,
      ),
      QuickActionItem(
        label: 'Đặt bàn',
        icon: Icons.event_seat,
        iconColor: AppColors.success,
        onTap: _navigateToReservationManagement,
      ),
      QuickActionItem(
        label: 'Báo cáo',
        icon: Icons.bar_chart_rounded,
        iconColor: AppColors.primary,
        onTap: _showReports,
      ),
      QuickActionItem(
        label: 'Thông báo',
        icon: AppIcons.notificationsOutlined,
        iconColor: AppColors.warning,
        badge: '5', // TODO: Real notification count
        onTap: _navigateToNotifications,
      ),
      QuickActionItem(
        label: 'Cài đặt',
        icon: AppIcons.settings,
        iconColor: AppColors.textSecondary,
        onTap: _navigateToClubSettings,
      ),
    ];
  }

  // Navigation Methods
  void _navigateToMemberManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberManagementScreen(clubId: widget.clubId),
      ),
    );
  }

  void _navigateToRankApproval() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ClubOwnerRankApprovalScreen(clubId: widget.clubId),
      ),
    );
    _controller.loadData();
  }

  void _navigateToSpaManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubSpaManagementScreen(
          clubId: widget.clubId,
          clubName: _controller.club?.name ?? 'CLB',
        ),
      ),
    );
  }

  void _navigateToTournamentCreate() async {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(context);
        DSSnackbar.error(context: context, message: "Vui lòng đăng nhập");
        return;
      }

      final permissionService = ClubPermissionService();
      final userRole = await permissionService.refreshUserRole(widget.clubId);

      if (!mounted) return;
      Navigator.pop(context);

      bool hasPermission = false;
      String errorMessage = '';

      if (userRole == null) {
        hasPermission = false;
        errorMessage = "Lỗi xác thực quyền";
      } else {
        switch (userRole) {
          case ClubRole.owner:
          case ClubRole.admin:
            hasPermission = true;
            break;
          case ClubRole.moderator:
          case ClubRole.member:
            hasPermission = await permissionService.canManageTournaments(
              widget.clubId,
              currentUser.id,
            );
            if (!mounted) return;
            errorMessage = "Không có quyền quản lý giải đấu";
            break;
          case ClubRole.guest:
            hasPermission = false;
            errorMessage = "Khách không có quyền này";
            break;
        }
      }

      if (!hasPermission) {
        DSSnackbar.error(
          context: context,
          message: '$errorMessage. Role: $userRole',
          duration: Duration(seconds: 4),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TournamentCreationWizard(clubId: widget.clubId),
        ),
      ).then((result) {
        if (mounted && result != null && result is Map<String, dynamic>) {
          _controller.loadData();
          DSSnackbar.success(
              context: context, message: "Tạo giải đấu thành công");
        }
      });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        DSSnackbar.error(
          context: context,
          message: 'Lỗi quyền truy cập: ${e.toString()}',
        );
      }
    }
  }

  void _navigateToWelcomeCampaign() {
    Navigator.pushNamed(
      context,
      AppRoutes.clubWelcomeCampaignScreen,
      arguments: {
        'clubId': widget.clubId,
        'clubName': _controller.club?.name ?? 'CLB'
      },
    );
  }

  void _navigateToReservationManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReservationManagementScreen(clubId: widget.clubId),
      ),
    );
  }

  void _showReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubReportsScreen(clubId: widget.clubId),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationListScreen(isClubContext: true),
      ),
    );
  }

  void _navigateToClubSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubSettingsScreen(clubId: widget.clubId),
      ),
    );
  }

  void _navigateToActivityHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityHistoryScreen(clubId: widget.clubId),
      ),
    );
  }

  void _editClubProfile() async {
    if (_controller.club == null) return;
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chỉnh sửa ảnh bìa",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: Text("Chụp ảnh mới"),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library, color: Colors.green),
              ),
              title: Text("Chọn từ thư viện"),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            const Divider(height: 32),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit, color: Colors.orange),
              ),
              title: Text("Chỉnh sửa thông tin CLB"),
              onTap: () => Navigator.pop(context, 'edit_profile'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (action == null) return;

    if (action == 'edit_profile') {
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ClubProfileEditScreenSimple(clubId: _controller.club!.id),
        ),
      );

      if (result == true) {
        _controller.loadData();
      }
      return;
    }

    final source =
        action == 'camera' ? ImageSource.camera : ImageSource.gallery;
    if (!mounted) return;
    _updateCoverImage(source);
  }

  void _editClubProfileImage() async {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chỉnh sửa ảnh đại diện",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.blue),
              title: Text("Chụp ảnh mới"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.green),
              title: Text("Chọn từ thư viện"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      if (!mounted) return;
      _updateProfileImage(source);
    }
  }

  Future<void> _updateCoverImage(ImageSource source) async {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final imageBytes = await image.readAsBytes();
      await ClubService.instance.uploadAndUpdateClubCover(
        _controller.club!.id,
        imageBytes,
        image.name,
      );

      // Reload data to update UI
      await _controller.loadData();

      if (!mounted) return;
      Navigator.pop(context);
      DSSnackbar.success(context: context, message: "Message");
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        DSSnackbar.error(context: context, message: 'Lỗi: $e');
      }
    }
  }

  Future<void> _updateProfileImage(ImageSource source) async {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final imageBytes = await image.readAsBytes();
      await ClubService.instance.uploadAndUpdateProfileImage(
        _controller.club!.id,
        imageBytes,
        image.name,
      );

      // Reload data to update UI
      await _controller.loadData();

      if (!mounted) return;
      Navigator.pop(context);
      DSSnackbar.success(context: context, message: "Message");
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        DSSnackbar.error(context: context, message: 'Lỗi: $e');
      }
    }
  }
}
