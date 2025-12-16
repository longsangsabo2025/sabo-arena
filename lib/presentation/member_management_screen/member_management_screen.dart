import 'package:flutter/material.dart';
// import '../../core/app_export.dart'; // Conflicts with design system
import '../../core/design_system/design_system.dart';
// import '../../widgets/custom_app_bar.dart'; // Not using anymore
// import '../../models/member_analytics.dart'; // Not needed anymore
import '../../models/member_data.dart';
import '../../models/rank_request.dart';
import '../../services/member_management_service.dart';
import '../../services/rank_verification_service.dart';
import '../../services/club_permission_service.dart';
import '../../widgets/user/user_widgets.dart';
import '../tournament_management_center/tournament_management_center_screen.dart';
import '../club_settings_screen/club_settings_screen.dart';
import '../../widgets/common/common_widgets.dart'; // Phase 4 - AppButton/AppSnackbar
// import 'widgets/member_search_bar.dart'; // Using DSTextField instead
// import 'widgets/member_filter_section.dart'; // Using simple pills instead
import 'widgets/member_list_view.dart';
// import 'widgets/member_analytics_card_simple.dart'; // Analytics hidden
import 'widgets/bulk_action_bar.dart';
import 'widgets/add_member_dialog.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class MemberManagementScreen extends StatefulWidget {
  final String clubId;

  const MemberManagementScreen({super.key, required this.clubId});

  @override
  _MemberManagementScreenState createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  // Removed: late TabController _filterTabController; (no longer needed)

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  // Removed: bool _showAdvancedFilters (no longer needed)
  bool _isSearchMode = false; // iOS style search toggle
  final List<String> _selectedMembers = [];

  // Real data from API
  List<MemberData> _allMembers = [];
  List<MemberData> _filteredMembers = [];
  bool _isLoading = true;
  // MemberAnalytics _analytics = const MemberAnalytics(
  //   totalMembers: 0,
  //   activeMembers: 0,
  //   newThisMonth: 0,
  //   growthRate: 0.0,
  // );

  // Rank verification state
  List<RankRequest> _rankRequests = [];
  int _pendingRequestsCount = 0;
  bool _isLoadingRankRequests = false;

  @override
  void initState() {
    super.initState();
    // Removed: _filterTabController = TabController(length: 5, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadMemberData();
    _loadRankRequests();
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Removed: _filterTabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMemberData() async {
    try {
      ProductionLogger.info('🚀 Loading member data for club: ${widget.clubId}', tag: 'member_management_screen');
      // Fetch real member data from the service - get all members first
      final membersData = await MemberManagementService.getClubMembers(
        clubId: widget.clubId,
        // Don't filter by status initially, get all members
      );

      ProductionLogger.info('✅ Got ${membersData.length} members from service', tag: 'member_management_screen');

      // Calculate real analytics - COMMENTED OUT (analytics hidden)
      // final totalMembers = membersData.length;
      // final activeMembers = membersData.where((m) => m['status'] == 'active').length;

      // Calculate new members this month
      // final now = DateTime.now();
      // final thisMonth = DateTime(now.year, now.month, 1);
      // final newThisMonth = membersData.where((m) {
      //   if (m['joined_at'] != null) {
      //     final joinDate = DateTime.parse(m['joined_at']);
      //     return joinDate.isAfter(thisMonth);
      //   }
      //   return false;
      // }).length;

      final convertedMembers = _convertToMemberData(membersData);
      ProductionLogger.info('✅ Converted ${convertedMembers.length} members to MemberData objects',  tag: 'member_management_screen');

      setState(() {
        _allMembers = convertedMembers;
        _filteredMembers = _allMembers;
        // _analytics = MemberAnalytics(
        //   totalMembers: totalMembers,
        //   activeMembers: activeMembers,
        //   newThisMonth: newThisMonth,
        //   growthRate: totalMembers > 0 ? (newThisMonth / totalMembers * 100) : 0.0,
        // );
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      ProductionLogger.info('Error loading member data: $e', tag: 'member_management_screen');
      setState(() {
        _isLoading = false;
        // Fallback to empty list or show error
        _allMembers = [];
        _filteredMembers = [];
        // _analytics = const MemberAnalytics(
        //   totalMembers: 0,
        //   activeMembers: 0,
        //   newThisMonth: 0,
        //   growthRate: 0.0,
        // );
      });

      if (mounted) {
        AppSnackbar.error(
          context: context,
          message: 'Lỗi tải dữ liệu thành viên: $e',
        );
      }
    }
  }

  Future<void> _loadRankRequests() async {
    try {
      setState(() => _isLoadingRankRequests = true);

      // Load pending rank requests count for badge
      final count = await RankVerificationService.instance
          .getPendingRequestsCount(widget.clubId);
      final requests = await RankVerificationService.instance
          .getPendingRankRequests(widget.clubId);

      setState(() {
        _pendingRequestsCount = count;
        _rankRequests = requests;
        _isLoadingRankRequests = false;
      });
    } catch (e) {
      ProductionLogger.info('Error loading rank requests: $e', tag: 'member_management_screen');
      setState(() => _isLoadingRankRequests = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
      bottomNavigationBar: _buildClubBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // iOS style AppBar with selection mode support
    final bool isInSelectionMode = _selectedMembers.isNotEmpty;

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: isInSelectionMode
          ? null // Hide back button in selection mode
          : IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: AppColors.primary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
      title: isInSelectionMode
          ? Text(
              '${_selectedMembers.length} đã chọn', overflow: TextOverflow.ellipsis, style: AppTypography.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            )
          : _isSearchMode
          ? _buildInlineSearchBar()
          : Text(
              'Thành viên', overflow: TextOverflow.ellipsis, style: AppTypography.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
      centerTitle: !_isSearchMode,
      actions: isInSelectionMode
          ? [
              // Cancel selection button
              AppButton(
                label: 'Hủy',
                type: AppButtonType.text,
                onPressed: () {
                  setState(() {
                    _selectedMembers.clear();
                  });
                },
              ),
            ]
          : _isSearchMode
          ? [
              // Cancel button when in search mode
              AppButton(
                label: 'Hủy',
                type: AppButtonType.text,
                onPressed: () {
                  setState(() {
                    _isSearchMode = false;
                    _searchController.clear();
                    _searchQuery = '';
                    _filterMembers();
                  });
                },
              ),
            ]
          : [
              // Search icon
              IconButton(
                icon: Icon(Icons.search, color: AppColors.textPrimary),
                onPressed: () {
                  setState(() {
                    _isSearchMode = true;
                  });
                  // Auto focus search field
                  Future.delayed(Duration(milliseconds: 100), () {
                    _searchFocusNode.requestFocus();
                  });
                },
                tooltip: 'Tìm kiếm',
              ),

              // Add member icon with badge for rank verification requests
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.person_add, color: AppColors.textPrimary),
                    onPressed: _showAddMemberDialog,
                    tooltip: 'Thêm thành viên',
                  ),
                  if (_pendingRequestsCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _pendingRequestsCount > 99
                              ? '99+'
                              : _pendingRequestsCount.toString(),
                          style: TextStyle(
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

              // More menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.textPrimary),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_download,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Xuất danh sách', overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_upload,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Nhập thành viên', overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Cài đặt', overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: _handleMenuAction,
              ),
            ],
    );
  }

  // iOS style inline search bar
  Widget _buildInlineSearchBar() {
    return DSTextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: 'Tìm kiếm...',
      variant: DSTextFieldVariant.filled,
      prefixIcon: Icons.search,
      suffixIcon: _searchController.text.isNotEmpty ? Icons.clear : null,
      onSuffixIconTap: () {
        _searchController.clear();
        _handleSearchChanged('');
      },
      onChanged: _handleSearchChanged,
      borderRadius: 10,
    );
  }

  // Simple filter pills - Facebook/Instagram style
  Widget _buildSimpleFilterPills() {
    final filters = [
      {'key': 'all', 'label': 'Tất cả', 'icon': Icons.people},
      {
        'key': 'active',
        'label': 'Hoạt động',
        'icon': Icons.check_circle_outline,
      },
      {'key': 'new', 'label': 'Mới', 'icon': Icons.fiber_new},
      {
        'key': 'inactive',
        'label': 'Không hoạt động',
        'icon': Icons.pause_circle_outline,
      },
      {'key': 'pending', 'label': 'Chờ duyệt', 'icon': Icons.schedule},
      {
        'key': 'rank_verification',
        'label': 'Xác minh hạng',
        'icon': Icons.verified_user,
      },
    ];

    final counts = _getFilterCounts();

    return Container(
      height: 44,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: filters.length,
        separatorBuilder: (context, index) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final key = filter['key'] as String;
          final label = filter['label'] as String;
          final icon = filter['icon'] as IconData;
          final count = counts[key] ?? 0;
          final isSelected = _selectedFilter == key;

          return DSChip(
            label: key == 'rank_verification'
                ? 'Xác minh hạng · ${_pendingRequestsCount > 0 ? _pendingRequestsCount : 0}'
                : '$label · $count',
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedFilter = key;
                _filterMembers();
                if (key == 'rank_verification') {
                  _showRankVerificationDialog();
                }
              });
            },
            variant: isSelected ? DSChipVariant.tonal : DSChipVariant.outlined,
            size: DSChipSize.medium,
            leadingIcon: icon,
          );
        },
      ),
    );
  }

  Map<String, int> _getFilterCounts() {
    return {
      'all': _allMembers.length,
      'active': _allMembers
          .where((m) => m.membershipInfo.status == MemberStatus.active)
          .length,
      'new': _allMembers.where((m) => _isNewMember(m)).length,
      'inactive': _allMembers
          .where((m) => m.membershipInfo.status == MemberStatus.inactive)
          .length,
      'pending': _allMembers
          .where((m) => m.membershipInfo.status == MemberStatus.pending)
          .length,
    };
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            'Đang tải danh sách thành viên...', overflow: TextOverflow.ellipsis, style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Analytics section - HIDDEN
              // Container(
              //   padding: const EdgeInsets.all(20),
              //   color: AppTheme.surfaceLight,
              //   child: MemberAnalyticsCardSimple(analytics: _analytics),
              // ),

              // Search and filter section
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.divider, width: 0.5),
                  ),
                ),
                child: _buildSimpleFilterPills(),
              ),

              // Bulk actions bar
              if (_selectedMembers.isNotEmpty)
                BulkActionBar(
                  selectedCount: _selectedMembers.length,
                  onAction: _handleBulkAction,
                  onClear: () => setState(() => _selectedMembers.clear()),
                ),

              // Member list
              Expanded(
                child: MemberListView(
                  members: _filteredMembers,
                  selectedMembers: _selectedMembers,
                  onMemberSelected: _handleMemberSelection,
                  onMemberAction: _handleMemberAction,
                  onRefresh: _handleRefresh,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    // Hide FAB - using AppBar add button instead (iOS style)
    return SizedBox.shrink();
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterMembers();
    });
  }

  // Removed unused handlers: _handleFilterChanged, _toggleAdvancedFilters, _handleAdvancedFiltersChanged

  void _handleMemberSelection(String memberId, bool selected) {
    setState(() {
      if (selected) {
        _selectedMembers.add(memberId);
      } else {
        _selectedMembers.remove(memberId);
      }
    });
  }

  void _handleMemberAction(String action, String memberId) {
    switch (action) {
      case 'view-profile':
        _navigateToMemberDetail(memberId);
        break;
      case 'message':
        _showMessageDialog(memberId);
        break;
      case 'view-stats':
        _showMemberStats(memberId);
        break;
      case 'more':
        _showMemberMoreActions(memberId);
        break;
    }
  }

  void _handleBulkAction(String action) {
    switch (action) {
      case 'message':
        _showBulkMessageDialog();
        break;
      case 'promote':
        _showBulkPromoteDialog();
        break;
      case 'export':
        _exportSelectedMembers();
        break;
      case 'remove':
        _showBulkRemoveDialog();
        break;
    }
  }

  Future<void> _handleRefresh() async {
    await _loadMemberData();
    await _loadRankRequests();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportAllMembers();
        break;
      case 'import':
        _showImportDialog();
        break;
      case 'settings':
        _navigateToMemberSettings();
        break;
    }
  }

  void _filterMembers() {
    setState(() {
      _filteredMembers = _allMembers.where((member) {
        // Text search
        final matchesSearch =
            _searchQuery.isEmpty ||
            member.user.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            member.user.username.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        // Status filter
        final matchesStatus =
            _selectedFilter == 'all' ||
            (_selectedFilter == 'active' &&
                member.membershipInfo.status == MemberStatus.active) ||
            (_selectedFilter == 'new' && _isNewMember(member)) ||
            (_selectedFilter == 'inactive' &&
                member.membershipInfo.status == MemberStatus.inactive) ||
            (_selectedFilter == 'pending' &&
                member.membershipInfo.status == MemberStatus.pending);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  // Duplicate removed - _getFilterCounts is already defined above in _buildSimpleFilterPills

  bool _isNewMember(MemberData member) {
    final now = DateTime.now();
    final joinDate = member.membershipInfo.joinDate;
    return now.difference(joinDate).inDays <= 30;
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(
        clubId: widget.clubId,
        onMemberAdded: (member) {
          setState(() {
            _allMembers.insert(0, member);
            _filterMembers();
          });
          _loadMemberData(); // Refresh the member list from API
        },
      ),
    );
  }

  void _navigateToMemberDetail(String memberId) {
    Navigator.pushNamed(
      context,
      '/member-detail',
      arguments: {'clubId': widget.clubId, 'memberId': memberId},
    );
  }

  void _showMessageDialog(String memberId) {
    // Implementation for single member message
  }

  void _showMemberStats(String memberId) {
    // Implementation for member statistics
  }

  void _showMemberMoreActions(String memberId) {
    // Implementation for more member actions
  }

  void _showBulkMessageDialog() {
    // Implementation for bulk messaging
  }

  void _showBulkPromoteDialog() {
    // Implementation for bulk promotion
  }

  void _exportSelectedMembers() {
    // Implementation for exporting selected members
  }

  void _showBulkRemoveDialog() {
    // Implementation for bulk removal
  }

  void _exportAllMembers() {
    // Implementation for exporting all members
  }

  void _showImportDialog() {
    // Implementation for member import
  }

  void _navigateToMemberSettings() {
    Navigator.pushNamed(context, '/member-settings');
  }

  Widget _buildClubBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Thành viên'),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events),
          label: 'Giải đấu',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
      ],
      currentIndex: 1, // Current tab is "Thành viên"
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pop(context); // Go back to dashboard
            break;
          case 1:
            // Already on member management
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TournamentManagementCenterScreen(clubId: widget.clubId),
              ),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ClubSettingsScreen(clubId: widget.clubId),
              ),
            );
            break;
        }
      },
    );
  }

  List<MemberData> _convertToMemberData(List<Map<String, dynamic>> apiData) {
    return apiData.map((data) {
      return MemberData.fromSupabaseData(data);
    }).toList();
  }

  void _showRankVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified_user, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Xác minh hạng'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _isLoadingRankRequests
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('Đang tải yêu cầu...'),
                    ],
                  ),
                )
              : _rankRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Không có yêu cầu xác minh hạng nào', overflow: TextOverflow.ellipsis, style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _rankRequests.length,
                  itemBuilder: (context, index) {
                    final request = _rankRequests[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: UserAvatarWidget(
                          avatarUrl: request.user?.avatarUrl,
                          size: 40,
                        ),
                        title: UserDisplayNameText(
                          userData: {
                            'display_name': request.user?.displayName,
                          },
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yêu cầu: ${request.requestedAt.toString().split(' ')[0]}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (request.notes != null &&
                                request.notes!.isNotEmpty)
                              Text(
                                'Ghi chú: ${request.notes}', overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveRankRequest(request.id),
                              tooltip: 'Duyệt',
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectRankRequest(request.id),
                              tooltip: 'Từ chối',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          AppButton(
            label: 'Đóng',
            type: AppButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRankRequest(String requestId) async {
    try {
      // 🔐 PERMISSION CHECK: Verify user can verify rank
      final canVerify = await ClubPermissionService().canPerformAction(
        clubId: widget.clubId,
        permissionKey: 'verify_rank',
      );
      
      if (!canVerify) {
        if (mounted) {
          AppSnackbar.error(
            context: context,
            message: 'Bạn không có quyền xác thực hạng',
          );
        }
        return;
      }

      await RankVerificationService.instance.approveRankRequest(requestId);
      await _loadRankRequests(); // Refresh the list
      Navigator.pop(context); // Close dialog
      AppSnackbar.success(
        context: context,
        message: 'Đã duyệt yêu cầu xác minh hạng',
      );
    } catch (e) {
      AppSnackbar.error(
        context: context,
        message: 'Lỗi khi duyệt yêu cầu: $e',
      );
    }
  }

  Future<void> _rejectRankRequest(String requestId) async {
    // Show dialog to enter rejection reason
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Từ chối yêu cầu'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText: 'Nhập lý do từ chối...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          AppButton(
            label: 'Hủy',
            type: AppButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            label: 'Từ chối',
            customColor: Colors.red,
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                AppSnackbar.warning(
                  context: context,
                  message: 'Vui lòng nhập lý do từ chối',
                );
                return;
              }

              try {
                await RankVerificationService.instance.rejectRankRequest(
                  requestId,
                  reasonController.text.trim(),
                );
                Navigator.pop(context); // Close reason dialog
                await _loadRankRequests(); // Refresh the list
                Navigator.pop(context); // Close main dialog
                AppSnackbar.success(
                  context: context,
                  message: 'Đã từ chối yêu cầu xác minh hạng',
                );
              } catch (e) {
                AppSnackbar.error(
                  context: context,
                  message: 'Lỗi khi từ chối yêu cầu: $e',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
