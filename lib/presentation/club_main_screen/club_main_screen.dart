import 'package:flutter/material.dart';
import '../../theme/app_bar_theme.dart' as app_theme;

import '../../models/club.dart';
import '../../services/club_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/loading_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../core/design_system/design_system.dart';
import 'widgets/horizontal_club_list.dart';
import 'widgets/club_detail_section.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class ClubMainScreen extends StatefulWidget {
  const ClubMainScreen({super.key});

  @override
  State<ClubMainScreen> createState() => _ClubMainScreenState();
}

class _ClubMainScreenState extends State<ClubMainScreen> {
  Club? _selectedClub;
  List<Club> _clubs = [];
  List<Club> _filteredClubs = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search and filter state
  String _searchQuery = '';
  String _locationQuery = '';
  Set<int> _selectedRatings = {};
  String? _selectedDistance;
  Set<String> _selectedFacilities = {};

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  void _loadClubs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load clubs from Supabase
      final clubs = await ClubService.instance.getClubs(limit: 50);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      setState(() {
        _clubs = clubs;
        _filteredClubs = clubs;
        _selectedClub = clubs.isNotEmpty ? clubs.first : null;
        _isLoading = false;
      });
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _onClubSelected(Club club) {
    setState(() {
      _selectedClub = club;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredClubs = _clubs.where((club) {
        // Search by name
        if (_searchQuery.isNotEmpty &&
            !club.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }

        // Search by location
        if (_locationQuery.isNotEmpty &&
            club.address != null &&
            !club.address!.toLowerCase().contains(
              _locationQuery.toLowerCase(),
            )) {
          return false;
        }

        // Filter by rating
        if (_selectedRatings.isNotEmpty) {
          final clubRating = (club.rating).ceil();
          if (!_selectedRatings.contains(clubRating)) {
            return false;
          }
        }

        // Note: Distance and facilities filtering would require additional data
        // For now, we implement name and location filtering which are most important

        return true;
      }).toList();

      // Update selected club if current is not in filtered list
      if (_selectedClub != null && !_filteredClubs.contains(_selectedClub)) {
        _selectedClub = _filteredClubs.isNotEmpty ? _filteredClubs.first : null;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _locationQuery = '';
      _selectedRatings.clear();
      _selectedDistance = null;
      _selectedFacilities.clear();
      _filteredClubs = _clubs;
      _selectedClub = _clubs.isNotEmpty ? _clubs.first : null;
    });
  }

  void _handleBottomNavTap(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  void _showRegisterClubDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text('Xác thực quyền sở hữu', overflow: TextOverflow.ellipsis, style: AppTypography.headingSmall),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chỉ chủ sở hữu hoặc quản lý câu lạc bộ mới có thể đăng ký', overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Để đảm bảo tính xác thực, bạn cần cung cấp:', overflow: TextOverflow.ellipsis, style: AppTypography.headingSmall,
              ),
              const SizedBox(height: 12),
              _buildVerificationRequirement(
                '📋',
                'Giấy phép kinh doanh',
                'Giấy phép kinh doanh có tên bạn hoặc câu lạc bộ',
              ),
              _buildVerificationRequirement(
                '🏢',
                'Địa chỉ cụ thể',
                'Địa chỉ thực tế của câu lạc bộ (có thể xác minh)',
              ),
              _buildVerificationRequirement(
                '📞',
                'Số điện thoại liên hệ',
                'SĐT chính thức của câu lạc bộ để xác minh',
              ),
              _buildVerificationRequirement(
                '🆔',
                'CCCD/CMND',
                'Chứng minh nhân dân của người đại diện',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Quy trình xác thực:', overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProcessStep('1', 'Gửi thông tin và tài liệu'),
                    _buildProcessStep('2', 'Admin sẽ xác minh trong 1-2 ngày'),
                    _buildProcessStep('3', 'Thông báo kết quả qua email/SMS'),
                    _buildProcessStep('4', 'Kích hoạt câu lạc bộ nếu hợp lệ'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Lợi ích sau khi xác thực:', overflow: TextOverflow.ellipsis, style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBenefitItem('⭐', 'Huy hiệu "Đã xác thực" tin cậy'),
                    _buildBenefitItem('�', 'Ưu tiên hiển thị trong tìm kiếm'),
                    _buildBenefitItem('�', 'Công cụ quản lý chuyên nghiệp'),
                    _buildBenefitItem('💰', 'Tăng khả năng thu hút khách hàng'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          DSButton(
            text: 'Hủy',
            onPressed: () => Navigator.of(context).pop(),
            variant: DSButtonVariant.ghost,
          ),
          DSButton(
            text: 'Tôi hiểu và đồng ý',
            onPressed: () {
              Navigator.of(context).pop();
              _showVerificationAgreement();
            },
            variant: DSButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _navigateToRegisterClubForm() {
    Navigator.pushNamed(context, '/club_registration_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        automaticallyImplyLeading: false,
        title: app_theme.AppBarTheme.buildGradientTitle('Câu lạc bộ'),
        centerTitle: false,
        actions: [
          // Filter button
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              onPressed: _showFilterDialog,
              icon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F2F5), // Facebook background
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Color(0xFF1877F2), // Facebook blue
                  size: 20,
                ),
              ),
              tooltip: 'Lọc câu lạc bộ',
            ),
          ),
          // Search button
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Stack(
              children: [
                IconButton(
                  onPressed: _showSearchDialog,
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F2F5), // Facebook background
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Color(0xFF1877F2), // Facebook blue
                      size: 20,
                    ),
                  ),
                  tooltip: 'Tìm kiếm câu lạc bộ',
                ),
                // Filter active indicator
                if (_searchQuery.isNotEmpty ||
                    _locationQuery.isNotEmpty ||
                    _selectedRatings.isNotEmpty ||
                    _selectedDistance != null ||
                    _selectedFacilities.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: _clearFilters,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Rank management button
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.rankManagementScreen);
              },
              icon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F2F5), // Facebook background
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: Color(0xFF1877F2), // Facebook blue
                  size: 20,
                ),
              ),
              tooltip: 'Quản lý hạng',
            ),
          ),
          // Register club button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: _showRegisterClubDialog,
              icon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F2F5), // Facebook background
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_business_outlined,
                  color: Color(0xFF1877F2), // Facebook blue
                  size: 20,
                ),
              ),
              tooltip: 'Đăng ký câu lạc bộ',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.5,
            color: const Color(0xFFE4E6EB), // Facebook divider
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingStateWidget(
              message: 'Đang tải danh sách câu lạc bộ...',
            )
          : _errorMessage != null
          ? RefreshableErrorStateWidget(
              errorMessage: _errorMessage,
              onRefresh: () async => _loadClubs(),
              title: 'Không thể tải danh sách câu lạc bộ',
              description: 'Đã xảy ra lỗi khi tải thông tin câu lạc bộ',
              showErrorDetails: true,
            )
          : _clubs.isEmpty
          ? RefreshableEmptyStateWidget(
              message: 'Chưa có câu lạc bộ nào',
              subtitle: 'Hãy là người đầu tiên đăng ký câu lạc bộ của bạn',
              icon: Icons.business,
              onRefresh: () async => _loadClubs(),
              actionLabel: 'Đăng ký câu lạc bộ',
              onAction: _showRegisterClubDialog,
            )
          : Column(
              children: [
                // Top section: Horizontal Club List (1/3 screen)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: HorizontalClubList(
                    clubs: _filteredClubs,
                    selectedClub: _selectedClub,
                    onClubSelected: _onClubSelected,
                  ),
                ),

                // Divider
                Container(
                  height: 1,
                  color: AppColors.gray200,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),

                // Bottom section: Club Detail (2/3 screen)
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0.1, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                              child: child,
                            ),
                          );
                        },
                    child: _selectedClub != null
                        ? ClubDetailSection(
                            key: ValueKey(_selectedClub!.id),
                            club: _selectedClub!,
                            onNeedRefresh:
                                _loadClubs, // Reload clubs when rating changes
                          )
                        : Center(
                            key: const ValueKey('empty'),
                            child: Text(
                              'Chọn một câu lạc bộ để xem chi tiết', overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
      // 🎯 PHASE 1: Bottom navigation moved to PersistentTabScaffold
      // No bottomNavigationBar here to prevent duplicate navigation bars
    );
  }

  // Helper methods for verification dialog
  Widget _buildVerificationRequirement(
    String icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description, style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number, style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description, style: const TextStyle(fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationAgreement() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.assignment_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text('Cam kết xác thực', overflow: TextOverflow.ellipsis, style: AppTypography.headingSmall),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tôi cam kết rằng:', overflow: TextOverflow.ellipsis, style: AppTypography.headingSmall),
              const SizedBox(height: 12),
              _buildCommitmentItem(
                '✓',
                'Tôi là chủ sở hữu hoặc người được ủy quyền đại diện cho câu lạc bộ này',
              ),
              _buildCommitmentItem(
                '✓',
                'Tất cả thông tin tôi cung cấp là chính xác và có thể xác minh',
              ),
              _buildCommitmentItem(
                '✓',
                'Tôi có đủ tài liệu chứng minh quyền sở hữu/quản lý câu lạc bộ',
              ),
              _buildCommitmentItem(
                '✓',
                'Tôi đồng ý với quy trình xác minh của Sabo Arena',
              ),
              _buildCommitmentItem(
                '✓',
                'Tôi hiểu rằng thông tin sai lệch sẽ dẫn đến từ chối đăng ký',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gavel, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lưu ý: Việc cung cấp thông tin sai lệch hoặc giả mạo có thể dẫn đến khóa tài khoản vĩnh viễn.', overflow: TextOverflow.ellipsis, style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          DSButton(
            text: 'Quay lại',
            onPressed: () => Navigator.of(context).pop(),
            variant: DSButtonVariant.ghost,
          ),
          DSButton(
            text: 'Tôi cam kết và tiếp tục',
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToRegisterClubForm();
            },
            variant: DSButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentItem(String checkmark, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            checkmark, style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text, style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    // Local state for dialog
    String tempSearchQuery = _searchQuery;
    String tempLocationQuery = _locationQuery;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Tìm kiếm câu lạc bộ', overflow: TextOverflow.ellipsis, style: AppTypography.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: tempSearchQuery),
                decoration: InputDecoration(
                  hintText: 'Nhập tên câu lạc bộ...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    tempSearchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: TextEditingController(text: tempLocationQuery),
                decoration: InputDecoration(
                  hintText: 'Nhập địa chỉ...',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    tempLocationQuery = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                // Apply search
                setState(() {
                  _searchQuery = tempSearchQuery;
                  _locationQuery = tempLocationQuery;
                });
                _applyFilters();
                Navigator.of(context).pop();
              },
              child: const Text('Tìm kiếm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    // Local state for dialog
    Set<int> tempSelectedRatings = Set.from(_selectedRatings);
    String? tempSelectedDistance = _selectedDistance;
    Set<String> tempSelectedFacilities = Set.from(_selectedFacilities);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Lọc câu lạc bộ', overflow: TextOverflow.ellipsis, style: AppTypography.headingSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating filter
                Text(
                  'Đánh giá', overflow: TextOverflow.ellipsis, style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 5; i >= 1; i--)
                      FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text('$i+'),
                          ],
                        ),
                        selected: tempSelectedRatings.contains(i),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              tempSelectedRatings.add(i);
                            } else {
                              tempSelectedRatings.remove(i);
                            }
                          });
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Distance filter
                Text(
                  'Khoảng cách', overflow: TextOverflow.ellipsis, style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  hint: const Text('Chọn khoảng cách'),
                  items: ['1 km', '5 km', '10 km', '20 km', 'Tất cả']
                      .map(
                        (distance) => DropdownMenuItem(
                          value: distance,
                          child: Text(distance),
                        ),
                      )
                      .toList(),
                  initialValue: tempSelectedDistance,
                  onChanged: (value) {
                    setDialogState(() {
                      tempSelectedDistance = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Facilities filter
                Text(
                  'Tiện ích', overflow: TextOverflow.ellipsis, style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      ['WiFi', 'Bãi đỗ xe', 'Quầy bar', 'Phòng VIP', 'Điều hòa']
                          .map(
                            (facility) => FilterChip(
                              label: Text(facility),
                              selected: tempSelectedFacilities.contains(
                                facility,
                              ),
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    tempSelectedFacilities.add(facility);
                                  } else {
                                    tempSelectedFacilities.remove(facility);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                // Reset filters
                setDialogState(() {
                  tempSelectedRatings.clear();
                  tempSelectedDistance = null;
                  tempSelectedFacilities.clear();
                });
              },
              child: const Text('Đặt lại'),
            ),
            ElevatedButton(
              onPressed: () {
                // Apply filters
                setState(() {
                  _selectedRatings = tempSelectedRatings;
                  _selectedDistance = tempSelectedDistance;
                  _selectedFacilities = tempSelectedFacilities;
                });
                _applyFilters();
                Navigator.of(context).pop();
              },
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }

  // Mock data for testing
}

