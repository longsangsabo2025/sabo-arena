import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'package:sabo_arena/core/design_system/responsive_grid.dart';
import 'package:sabo_arena/core/performance/performance_widgets.dart';
import 'package:sabo_arena/core/device/device_info.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/widgets/common/shimmer_loading.dart';
// import 'package:sabo_arena/widgets/charts/member_growth_chart.dart'; // Chart hidden - not needed
import 'package:sabo_arena/services/dashboard_cache_service.dart';
import 'package:sabo_arena/theme/app_theme.dart' as OldTheme;
import 'package:sabo_arena/models/club.dart';
import 'package:sabo_arena/services/club_service.dart';
import 'package:sabo_arena/services/auth_service.dart';
import 'package:sabo_arena/routes/app_routes.dart';
// import 'package:sabo_arena/services/club_dashboard_service.dart';
import '../member_management_screen/member_management_screen.dart';
import './club_owner_rank_approval_screen.dart';
import '../tournament_creation_wizard/tournament_creation_wizard.dart';
import '../../services/admin_rank_approval_service.dart';
import '../club_notification_screen/club_notification_screen_simple.dart';
import '../club_settings_screen/club_settings_screen.dart';
import '../club_reports_screen/club_reports_screen.dart';
import '../activity_history_screen/activity_history_screen.dart';
import '../../services/club_permission_service.dart';
import '../../models/club_role.dart';
import '../club_profile_edit_screen/club_profile_edit_screen_simple.dart';
import 'package:image_picker/image_picker.dart';
import '../reservation_management_screen/reservation_management_screen.dart';
import '../spa_management/club_spa_management_screen.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

// Temporary mock classes
class ClubDashboardStats {
  final int totalMembers;
  final int activeMembers;
  final double monthlyRevenue;
  final int totalTournaments;
  final int tournaments;
  final int ranking;

  ClubDashboardStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.monthlyRevenue,
    required this.totalTournaments,
    required this.tournaments,
    required this.ranking,
  });
}

class ClubActivity {
  final String title;
  final String subtitle;
  final String type;
  final DateTime timestamp;

  ClubActivity({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
  });
}

// Quick Action data class - Facebook/Instagram style
class _QuickAction {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String? badge;

  _QuickAction({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.badge,
  });
}

class ClubDashboardScreenSimple extends StatefulWidget {
  final String clubId;

  const ClubDashboardScreenSimple({super.key, required this.clubId});

  @override
  State<ClubDashboardScreenSimple> createState() =>
      _ClubDashboardScreenSimpleState();
}

class _ClubDashboardScreenSimpleState extends State<ClubDashboardScreenSimple> {
  bool _isLoading = true;
  Club? _club;
  bool _isOwner = false;
  ClubRole? _userRole; // User's role in this club

  // Dashboard data
  ClubDashboardStats? _dashboardStats;
  List<ClubActivity> _recentActivities = [];
  int _pendingRankRequests = 0;

  // Services
  final ClubPermissionService _permissionService = ClubPermissionService();
  final AdminRankApprovalService _rankApprovalService =
      AdminRankApprovalService();

  // Phase 3: Animation & Filter States
  bool _showStatsAnimation = false;
  String _selectedActivityFilter = 'all'; // all, tournament, training, social
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  Future<int> _loadPendingRankRequestsCount() async {
    try {
      final requests = await _rankApprovalService.getPendingRankRequests();
      return requests.length;
    } catch (e) {
      return 0;
    }
  }

  Future<ClubDashboardStats> _loadRealClubStats(String clubId) async {
    try {
      // Get real member count
      final memberCount = await Supabase.instance.client
          .from('club_members')
          .select('id')
          .eq('club_id', clubId)
          .eq('status', 'active')
          .count();

      // Get tournament count (if tournaments table exists)
      int tournamentCount = 0;
      try {
        final tournamentResult = await Supabase.instance.client
            .from('tournaments')
            .select('id')
            .eq('club_id', clubId)
            .count();
        tournamentCount = tournamentResult.count;
      } catch (e) {
        // Tournaments table might not exist, use 0
        tournamentCount = 0;
      }

      return ClubDashboardStats(
        totalMembers: memberCount.count,
        activeMembers: memberCount.count,
        monthlyRevenue: 0.0, // Can be calculated later if needed
        totalTournaments: tournamentCount,
        tournaments: tournamentCount,
        ranking: 0, // Can be calculated later if needed
      );
    } catch (e) {
      // Fallback to zero values if error
      return ClubDashboardStats(
        totalMembers: 0,
        activeMembers: 0,
        monthlyRevenue: 0.0,
        totalTournaments: 0,
        tournaments: 0,
        ranking: 0,
      );
    }
  }

  Future<List<ClubActivity>> _loadRecentActivities(String clubId) async {
    try {
      final activities = <ClubActivity>[];

      // Get recent member joins
      final recentJoins = await Supabase.instance.client
          .from('club_members')
          .select('''
            joined_at,
            users!inner(display_name)
          ''')
          .eq('club_id', clubId)
          .order('joined_at', ascending: false)
          .limit(5);

      for (final join in recentJoins) {
        final userName = join['users']['display_name'] ?? 'Thành viên mới';
        activities.add(
          ClubActivity(
            title: 'Thành viên mới tham gia',
            subtitle: '$userName đã tham gia club',
            type: 'member_join',
            timestamp: DateTime.parse(join['joined_at']),
          ),
        );
      }

      return activities;
    } catch (e) {
      // Return empty list if error
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUserId = AuthService.instance.currentUser?.id;

      // If clubId is empty, try to get user's owned club
      String clubId = widget.clubId;
      if (clubId.isEmpty && currentUserId != null) {
        final supabase = Supabase.instance.client;
        final clubData = await supabase
            .from('clubs')
            .select()
            .eq('owner_id', currentUserId)
            .maybeSingle();

        if (clubData != null) {
          clubId = clubData['id'];
        } else {
          // No club found for this user
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }
      }

      final club = await ClubService.instance.getClubById(clubId);
      final isOwner = club.ownerId == currentUserId;

      // Get user's role in this club from club_members
      ClubRole? userRole;
      if (currentUserId != null) {
        try {
          final memberData = await Supabase.instance.client
              .from('club_members')
              .select('role')
              .eq('club_id', clubId)
              .eq('user_id', currentUserId)
              .eq('status', 'active')
              .maybeSingle();

          if (memberData != null) {
            userRole = ClubRole.fromString(memberData['role'] as String? ?? 'member');
          }
        } catch (e) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }

      // If user is club owner, ensure they have a membership record
      if (isOwner && currentUserId != null) {
        await _ensureOwnerMembership(clubId, currentUserId);
      }

      setState(() {
        _club = club;
        _isOwner = isOwner;
        _userRole = userRole;
        // Store user role for future use if needed
      });

      // Allow owner, admin, and moderator to see dashboard
      final canAccessDashboard = isOwner || 
                                  userRole == ClubRole.admin || 
                                  userRole == ClubRole.moderator;

      if (canAccessDashboard) {
        // Load dashboard data with caching
        final cache = DashboardCacheService.instance;

        final stats = await cache.getOrFetch<ClubDashboardStats>(
          key: CacheKeys.clubStats(clubId),
          fetchFunction: () => _loadRealClubStats(clubId),
          ttl: CacheTTL.dashboardStats,
        );

        final activities = await cache.getOrFetch<List<ClubActivity>>(
          key: CacheKeys.clubActivities(clubId),
          fetchFunction: () => _loadRecentActivities(clubId),
          ttl: CacheTTL.medium,
        );

        // Load pending rank requests count
        final pendingRequests = await _loadPendingRankRequestsCount();

        setState(() {
          _dashboardStats = stats;
          _recentActivities = activities;
          _pendingRankRequests = pendingRequests;
          _isLoading = false;
        });

        // Trigger stats animation after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _showStatsAnimation = true;
            });
          }
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        DSSnackbar.error(context: context, message: 'Lỗi tải dữ liệu: $e');
      }
    }
  }

  /// Ensure club owner has membership record
  Future<void> _ensureOwnerMembership(String clubId, String userId) async {
    try {
      final supabase = Supabase.instance.client;

      // Check if owner already has membership record
      final existing = await supabase
          .from('club_members')
          .select('id')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        // Add owner to club_members
        await supabase.from('club_members').insert({
          'club_id': clubId,
          'user_id': userId,
          'role': 'owner',
          'status': 'active',
          'joined_at': DateTime.now().toIso8601String(),
        });

        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // Clear permission cache to force refresh
        _permissionService.clearCache(clubId: clubId, userId: userId);
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: CustomAppBar(title: 'Club Dashboard'),
        body: const DashboardSkeleton(),
      );
    }

    // Allow owner, admin, and moderator to access
    final canAccess = _isOwner || 
                      _userRole == ClubRole.admin || 
                      _userRole == ClubRole.moderator;

    if (!canAccess) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Club Dashboard'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Bạn không có quyền truy cập dashboard này.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Chỉ Chủ club, Quản trị viên và Người điều hành mới có thể xem.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildModernAppBar(),
      body: _buildResponsiveBody(),
    );
  }

  // 🎯 iPad: Responsive body with max-width constraint
  Widget _buildResponsiveBody() {
    final isIPad = DeviceInfo.isIPad(context);
    final maxWidth = isIPad ? 1000.0 : double.infinity;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with club info
              _buildClubHeader(),

              // Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats section - compact
                    _buildCompactStats(),
                    const SizedBox(height: 24),

                    // Quick actions - modern grid
                    _buildSectionHeader('Quản lý nhanh', Icons.speed),
                    const SizedBox(height: 16),
                    _buildModernQuickActions(),
                    const SizedBox(height: 24),

                    // Recent activities - improved with filters
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
                          onPressed: _showExportDialog,
                          tooltip: 'Xuất báo cáo',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildActivityFilterBar(),
                    const SizedBox(height: 16),
                    _buildImprovedActivities(),
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

  // Modern AppBar
  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Club Dashboard',
        style: TextStyle(
          color: Colors.grey[800],
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
          onPressed: _navigateToNotifications,
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: Colors.grey[600]),
          onPressed: _showSettings,
        ),
      ],
    );
  }

  // Enhanced Club Header - Facebook Profile Standard Layout
  Widget _buildClubHeader() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover photo with edit button
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover photo section - 200px height
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(color: AppColors.border),
                child: _club?.coverImageUrl != null
                    ? OptimizedImage(
                        imageUrl: _club!.coverImageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
              ),
              // Edit cover button
              Positioned(
                bottom: DesignTokens.space12,
                right: DesignTokens.space16,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                  elevation: 1,
                  child: InkWell(
                    onTap: _editClubProfile,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.space12,
                        vertical: DesignTokens.space8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.camera,
                            size: AppIcons.sizeSM,
                            color: AppColors.textPrimary,
                          ),
                          SizedBox(width: DesignTokens.space8),
                          Text(
                            'Chỉnh sửa',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Avatar overlapping cover
              Positioned(
                left: DesignTokens.space16,
                bottom: -50, // Overlap down 50px
                child: Stack(
                  clipBehavior: Clip.none, // Allow children to overflow
                  children: [
                    // Avatar with white border
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _club?.profileImageUrl != null
                            ? OptimizedImage(
                                imageUrl: _club!.profileImageUrl!,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                alignment: Alignment.center,
                                child: Text(
                                  (_club?.name != null &&
                                          _club!.name.isNotEmpty)
                                      ? _club!.name
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : 'C',
                                  style: AppTypography.displayLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    // Camera icon badge - positioned at bottom right
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _editClubProfileImage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Space for avatar overlap + info section
          SizedBox(
            height: 60,
          ), // Space for avatar overlap (50px + 10px padding)
          // Club info section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _club?.name ?? 'Loading...',
                        style: AppTypography.headingLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_club?.isVerified == true) ...[
                      SizedBox(width: DesignTokens.space8),
                      Icon(Icons.verified, color: AppColors.info, size: 20),
                    ],
                  ],
                ),
                SizedBox(height: DesignTokens.space4),
                Text(
                  'Dashboard quản lý',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: DesignTokens.space16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Stats Cards with Design System - Responsive layout
  Widget _buildCompactStats() {
    // Check if mobile/tablet for responsive layout
    final isMobile = context.isMobile;

    if (isMobile) {
      // 2x2 grid for mobile
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Members',
                  value: '${_dashboardStats?.activeMembers ?? 0}',
                  icon: AppIcons.following,
                  color: AppColors.info,
                  index: 0,
                ),
              ),
              SizedBox(width: DesignTokens.space12),
              Expanded(
                child: _buildStatCard(
                  label: 'Tournaments',
                  value: '${_dashboardStats?.totalTournaments ?? 0}',
                  icon: AppIcons.trophy,
                  color: AppColors.warning,
                  index: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Revenue',
                  value: _formatRevenue(_dashboardStats?.monthlyRevenue ?? 0.0),
                  icon: Icons.attach_money,
                  color: AppColors.success,
                  index: 2,
                ),
              ),
              SizedBox(width: DesignTokens.space12),
              Expanded(
                child: _buildStatCard(
                  label: 'Activities',
                  value: '${_recentActivities.length}',
                  icon: AppIcons.event,
                  color: AppColors.primary,
                  index: 3,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // 1x4 row for tablet/desktop
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Members',
            value: '${_dashboardStats?.activeMembers ?? 0}',
            icon: AppIcons.following,
            color: AppColors.info,
            index: 0,
          ),
        ),
        SizedBox(width: DesignTokens.space12),
        Expanded(
          child: _buildStatCard(
            label: 'Tournaments',
            value: '${_dashboardStats?.totalTournaments ?? 0}',
            icon: AppIcons.trophy,
            color: AppColors.warning,
            index: 1,
          ),
        ),
        SizedBox(width: DesignTokens.space12),
        Expanded(
          child: _buildStatCard(
            label: 'Revenue',
            value: _formatRevenue(_dashboardStats?.monthlyRevenue ?? 0.0),
            icon: Icons.attach_money,
            color: AppColors.success,
            index: 2,
          ),
        ),
        SizedBox(width: DesignTokens.space12),
        Expanded(
          child: _buildStatCard(
            label: 'Activities',
            value: '${_recentActivities.length}',
            icon: AppIcons.event,
            color: AppColors.primary,
            index: 3,
          ),
        ),
      ],
    );
  }

  // Stat Card using DSCard with animation - Facebook/Instagram horizontal style
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: DesignTokens.curveEmphasized,
      tween: Tween(begin: 0.0, end: _showStatsAnimation ? 1.0 : 0.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: DSCard.elevated(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space12,
                  vertical: DesignTokens.space12,
                ),
                child: Row(
                  children: [
                    // Icon circle - Facebook style
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSM,
                        ),
                      ),
                      child: Icon(icon, color: color, size: AppIcons.sizeMD),
                    ),
                    SizedBox(width: DesignTokens.space12),
                    // Value + Label - Vertical stack
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Value (số lớn)
                          Text(
                            value,
                            style: AppTypography.headingMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: DesignTokens.space4),
                          // Label (text nhỏ)
                          Text(
                            label,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Section header with icon
  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    VoidCallback? onViewAll,
  }) {
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

  // Quick Actions - Facebook/Instagram style (2 column grid)
  Widget _buildModernQuickActions() {
    final actions = [
      _QuickAction(
        label: 'Thành viên',
        icon: AppIcons.following,
        iconColor: AppColors.info,
        onTap: _navigateToMemberManagement,
      ),
      _QuickAction(
        label: 'Duyệt hạng',
        icon: Icons.verified_user,
        iconColor: AppColors.success,
        badge: _pendingRankRequests > 0
            ? _pendingRankRequests.toString()
            : null,
        onTap: _navigateToRankApproval,
      ),
      _QuickAction(
        label: 'Quản lý SPA',
        icon: Icons.wallet,
        iconColor: Colors.deepPurple,
        onTap: _navigateToSpaManagement,
      ),
      _QuickAction(
        label: 'Giải đấu',
        icon: AppIcons.trophy,
        iconColor: AppColors.warning,
        onTap: _navigateToTournamentCreate,
      ),
      _QuickAction(
        label: 'Welcome Campaign',
        icon: Icons.celebration,
        iconColor: Colors.purple,
        onTap: _navigateToWelcomeCampaign,
      ),
      _QuickAction(
        label: 'Quản lý đặt bàn',
        icon: Icons.event_seat,
        iconColor: AppColors.success,
        onTap: _navigateToReservationManagement,
      ),
      _QuickAction(
        label: 'Báo cáo',
        icon: Icons.bar_chart_rounded,
        iconColor: AppColors.primary,
        onTap: _showReports,
      ),
      _QuickAction(
        label: 'Thông báo',
        icon: AppIcons.notificationsOutlined,
        iconColor: AppColors.warning,
        badge: '5',
        onTap: _navigateToNotifications,
      ),
      _QuickAction(
        label: 'Cài đặt',
        icon: AppIcons.settings,
        iconColor: AppColors.textSecondary,
        onTap: _showSettings,
      ),
    ];

    return ResponsiveGrid(
      items: actions,
      itemBuilder: (context, action, index) {
        return _buildQuickActionItem(action);
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      spacing: DesignTokens.space12,
      runSpacing: DesignTokens.space12,
      padding: EdgeInsets.zero,
    );
  }

  // Quick Action Item - Facebook/Instagram style
  Widget _buildQuickActionItem(_QuickAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space12,
            vertical: DesignTokens.space12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        action.icon,
                        color: action.iconColor,
                        size: AppIcons.sizeMD,
                      ),
                    ),
                    if (action.badge != null)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: EdgeInsets.all(DesignTokens.space4 - 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            action.badge!,
                            style: AppTypography.captionSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: DesignTokens.space12),
              // Label
              Expanded(
                child: Text(
                  action.label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: AppIcons.sizeMD,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Improved activities section with filters - Phase 3
  Widget _buildImprovedActivities() {
    final filteredActivities = _getFilteredActivities();

    if (filteredActivities.isEmpty) {
      return DSEmptyState(
        icon: AppIcons.event,
        title: _recentActivities.isEmpty
            ? 'Chưa có hoạt động'
            : 'Không tìm thấy hoạt động',
        description: 'Các hoạt động của club sẽ hiển thị ở đây',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredActivities.length > 5 ? 5 : filteredActivities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final activity = filteredActivities[index];
        return _buildImprovedActivityItem(activity, index);
      },
    );
  }

  // Activity item with DSCard and design tokens - Facebook/Instagram style
  Widget _buildImprovedActivityItem(ClubActivity activity, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: DesignTokens.curveStandard,
      tween: Tween(begin: 0.0, end: _showStatsAnimation ? 1.0 : 0.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue,
            child: DSCard.outlined(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space12,
                  vertical: DesignTokens.space12,
                ),
                child: Row(
                  children: [
                    // Avatar circle with icon badge - Facebook style
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Main avatar circle (green background with + icon)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.add,
                            color: AppColors.success,
                            size: AppIcons.sizeMD,
                          ),
                        ),
                        // Small badge icon at bottom right
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getActivityColor(activity.type),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              _getActivityIcon(activity.type),
                              color: Colors.white,
                              size: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: DesignTokens.space12),
                    // Content - Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title - Bold like Facebook
                          Text(
                            activity.title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: DesignTokens.space4),
                          // Subtitle - Muted text
                          Text(
                            activity.subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: DesignTokens.space8),
                    // Time badge - Compact display
                    Text(
                      _formatTimeAgo(activity.timestamp),
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'member_join':
        return AppColors.success;
      case 'tournament_end':
        return AppColors.info;
      case 'tournament_start':
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'member_join':
        return AppIcons.add;
      case 'tournament_end':
        return AppIcons.trophy;
      case 'tournament_start':
        return Icons.play_arrow;
      default:
        return AppIcons.info;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}p';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  void _navigateToMemberManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberManagementScreen(clubId: widget.clubId),
      ),
    );
  }

  void _navigateToWelcomeCampaign() {
    Navigator.pushNamed(
      context,
      AppRoutes.clubWelcomeCampaignScreen,
      arguments: {'clubId': widget.clubId, 'clubName': _club?.name ?? 'Club'},
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
    // Refresh pending requests count when returning
    _refreshPendingRankRequests();
  }

  Future<void> _refreshPendingRankRequests() async {
    try {
      final pendingRequests = await _loadPendingRankRequestsCount();
      if (mounted) {
        setState(() {
          _pendingRankRequests = pendingRequests;
        });
      }
    } catch (e) {
      // Ignore errors for this refresh
    }
  }

  void _navigateToSpaManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubSpaManagementScreen(
          clubId: widget.clubId,
          clubName: _club?.name ?? 'CLB',
        ),
      ),
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

  void _navigateToTournamentCreate() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Get current user ID
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(context); // Close loading dialog
        DSSnackbar.error(
          context: context,
          message: 'Vui lòng đăng nhập để tiếp tục',
        );
        return;
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Debug membership first (commented out - not currently used)
      // final membershipDebug = await _permissionService.debugMembership(
      //   widget.clubId,
      //   currentUser.id,
      // );
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Force refresh user role to get latest data from database
      final userRole = await _permissionService.refreshUserRole(widget.clubId);
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      Navigator.pop(context); // Close loading dialog

      // Check if user has permission to create tournaments
      bool hasPermission = false;
      String errorMessage = '';

      if (userRole == null) {
        hasPermission = false;
        errorMessage = 'Bạn không phải là thành viên của club này';
      } else {
        switch (userRole) {
          case ClubRole.owner:
          case ClubRole.admin:
            hasPermission = true;
            break;
          case ClubRole.moderator:
          case ClubRole.member:
            // Members can create tournaments too based on permissions
            hasPermission = await _permissionService.canManageTournaments(
              widget.clubId,
              currentUser.id,
            );
            errorMessage = 'Thành viên thường không có quyền tạo giải đấu';
            break;
          case ClubRole.guest:
            hasPermission = false;
            errorMessage = 'Khách không có quyền tạo giải đấu';
            break;
        }
      }

      if (!hasPermission) {
        DSSnackbar.error(
          context: context,
          message: '$errorMessage. Role hiện tại: $userRole',
          duration: Duration(seconds: 4),
        );
        return;
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      Navigator.pop(context); // Close loading dialog first
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TournamentCreationWizard(clubId: widget.clubId),
        ),
      ).then((result) {
        if (mounted && result != null && result is Map<String, dynamic>) {
          // Refresh dashboard if tournament was created successfully
          _loadData();
          DSSnackbar.success(
            context: context,
            message: 'Giải đấu đã được tạo thành công!',
          );
        }
      });
      return; // Exit function after navigation
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        DSSnackbar.error(
          context: context,
          message: 'Lỗi kiểm tra quyền: ${e.toString()}',
        );
      }
    }
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ClubNotificationScreenSimple(clubId: widget.clubId),
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

  void _navigateToClubSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubSettingsScreen(clubId: widget.clubId),
      ),
    );
  }

  void _showSettings() {
    _navigateToClubSettings();
  }

  void _editClubProfile() async {
    if (_club == null) return;

    // Show options: Change cover photo or edit full profile
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
            Text('Chỉnh sửa', style: AppTypography.headingMedium),
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
              title: Text('Chụp ảnh bìa'),
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
              title: Text('Chọn ảnh bìa từ thư viện'),
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
              title: Text('Chỉnh sửa thông tin club'),
              onTap: () => Navigator.pop(context, 'edit_profile'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (action == null) return;

    // Handle edit full profile
    if (action == 'edit_profile') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClubProfileEditScreenSimple(clubId: _club!.id),
        ),
      );

      // Reload club data if profile was updated
      if (result == true) {
        _loadData();
      }
      return;
    }

    // Handle cover photo change
    final source = action == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;

    try {
      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920, // Cover photo can be larger
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: OldTheme.AppTheme.primaryLight,
                ),
                const SizedBox(height: 16),
                Text('Đang tải ảnh bìa...'),
              ],
            ),
          ),
        ),
      );

      // Read image bytes
      final imageBytes = await image.readAsBytes();

      // Use ClubService to upload and update cover image
      final updatedClub = await ClubService.instance.uploadAndUpdateClubCover(
        _club!.id,
        imageBytes,
        image.name,
      );

      // Update local club data
      setState(() {
        _club = updatedClub;
      });

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        DSSnackbar.success(
          context: context,
          message: 'Cập nhật ảnh bìa thành công!',
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        DSSnackbar.error(context: context, message: 'Lỗi cập nhật ảnh bìa: $e');
      }
    }
  }

  void _editClubProfileImage() async {
    if (_club == null) return;

    // Show options: Camera or Gallery
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
            Text('Chọn ảnh đại diện', style: AppTypography.headingMedium),
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
              title: Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
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
              title: Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: OldTheme.AppTheme.primaryLight,
                ),
                const SizedBox(height: 16),
                Text('Đang tải ảnh lên...'),
              ],
            ),
          ),
        ),
      );

      // Read image bytes
      final imageBytes = await image.readAsBytes();

      // Use ClubService to upload and update profile image
      final updatedClub = await ClubService.instance
          .uploadAndUpdateProfileImage(_club!.id, imageBytes, image.name);

      // Update local club data
      setState(() {
        _club = updatedClub;
      });

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        DSSnackbar.success(
          context: context,
          message: 'Cập nhật ảnh đại diện thành công!',
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        DSSnackbar.error(context: context, message: 'Lỗi: ${e.toString()}');
      }
    }
  }

  void _navigateToActivityHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityHistoryScreen(clubId: widget.clubId),
      ),
    );
  }

  // Phase 3: Activity Filter Bar
  Widget _buildActivityFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Tất cả', 'all', AppIcons.menu),
          SizedBox(width: DesignTokens.space8),
          _buildFilterChip('Giải đấu', 'tournament', AppIcons.trophy),
          SizedBox(width: DesignTokens.space8),
          _buildFilterChip('Training', 'training', Icons.fitness_center),
          SizedBox(width: DesignTokens.space8),
          _buildFilterChip('Giao lưu', 'social', AppIcons.following),
          SizedBox(width: DesignTokens.space8),
          _buildDateRangeFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedActivityFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppIcons.sizeSM,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          SizedBox(width: DesignTokens.space4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedActivityFilter = value;
        });
      },
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: AppTypography.labelMedium.copyWith(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space8,
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    final hasDateFilter = _filterStartDate != null && _filterEndDate != null;
    return GestureDetector(
      onTap: _showDateRangePicker,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space8,
        ),
        decoration: BoxDecoration(
          color: hasDateFilter ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          border: Border.all(
            color: hasDateFilter ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.calendar,
              size: AppIcons.sizeSM,
              color: hasDateFilter ? Colors.white : AppColors.primary,
            ),
            SizedBox(width: DesignTokens.space4),
            Text(
              hasDateFilter ? 'Lọc theo ngày' : 'Chọn ngày',
              style: AppTypography.labelMedium.copyWith(
                color: hasDateFilter ? Colors.white : AppColors.textSecondary,
                fontWeight: hasDateFilter ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (hasDateFilter) ...[
              SizedBox(width: DesignTokens.space4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _filterStartDate = null;
                    _filterEndDate = null;
                  });
                },
                child: Icon(
                  AppIcons.close,
                  size: AppIcons.sizeSM,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _filterStartDate != null && _filterEndDate != null
          ? DateTimeRange(start: _filterStartDate!, end: _filterEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: OldTheme.AppTheme.primaryLight,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterStartDate = picked.start;
        _filterEndDate = picked.end;
      });
    }
  }

  // Phase 3: Export Dialog
  void _showExportDialog() {
    showModalBottomSheet(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: OldTheme.AppTheme.primaryLight.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.file_download,
                    color: OldTheme.AppTheme.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Xuất báo cáo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildExportOption(
              'Xuất PDF',
              'Tạo file PDF chi tiết với biểu đồ',
              Icons.picture_as_pdf,
              Colors.red,
              () => _exportReport('pdf'),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              'Xuất Excel',
              'Tạo bảng tính Excel để phân tích',
              Icons.table_chart,
              Colors.green,
              () => _exportReport('excel'),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              'Xuất CSV',
              'Tạo file CSV để import vào hệ thống khác',
              Icons.grid_on,
              Colors.orange,
              () => _exportReport('csv'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Hủy'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _exportReport(String format) {
    Navigator.pop(context);
    DSSnackbar.info(
      context: context,
      message: 'Đang xuất báo cáo dạng ${format.toUpperCase()}...',
      duration: const Duration(seconds: 2),
    );
    // TODO: Implement actual export logic
  }

  // Filter activities based on selected filters
  List<ClubActivity> _getFilteredActivities() {
    var filtered = _recentActivities;

    // Filter by type
    if (_selectedActivityFilter != 'all') {
      filtered = filtered.where((activity) {
        return activity.type.toLowerCase() == _selectedActivityFilter;
      }).toList();
    }

    // Filter by date range
    if (_filterStartDate != null && _filterEndDate != null) {
      filtered = filtered.where((activity) {
        return activity.timestamp.isAfter(_filterStartDate!) &&
            activity.timestamp.isBefore(
              _filterEndDate!.add(const Duration(days: 1)),
            );
      }).toList();
    }

    return filtered;
  }

  // Build Member Growth Chart Widget - REMOVED (not needed)
  // Widget _buildMemberGrowthChart() { ... }

  String _formatRevenue(double revenue) {
    if (revenue >= 1000000) {
      return '${(revenue / 1000000).toStringAsFixed(1)}M';
    } else if (revenue >= 1000) {
      return '${(revenue / 1000).toStringAsFixed(1)}K';
    } else {
      return revenue.toStringAsFixed(0);
    }
  }
}

