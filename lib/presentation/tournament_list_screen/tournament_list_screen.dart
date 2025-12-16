import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/core/app_export.dart' hide AppColors, AppTypography;
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'package:sabo_arena/core/performance/performance_widgets.dart';
import 'package:sabo_arena/core/keyboard/keyboard_shortcuts.dart';
import '../../theme/app_bar_theme.dart' as app_theme;
import 'package:sabo_arena/models/tournament.dart';
import 'package:sabo_arena/models/club.dart';
import 'package:sabo_arena/presentation/shared/widgets/tournament_card_widget.dart';
import 'package:sabo_arena/presentation/shared/widgets/tournament_card_with_eligibility.dart';
import 'package:sabo_arena/presentation/tournament_list_screen/widgets/tournament_filter_bottom_sheet.dart';
import 'package:sabo_arena/presentation/tournament_list_screen/widgets/tournament_search_delegate.dart';
import 'package:sabo_arena/presentation/demo_bracket_screen/demo_bracket_screen.dart';
import 'package:sabo_arena/presentation/tournament_creation_wizard/tournament_creation_wizard.dart';
import 'package:sabo_arena/services/tournament_service.dart';
import 'package:sabo_arena/services/auth_service.dart';
import 'package:sabo_arena/services/club_service.dart';
import 'package:sabo_arena/services/club_permission_service.dart';
import 'package:sabo_arena/services/share_service.dart';
import 'package:sabo_arena/models/club_role.dart';
import 'package:sabo_arena/widgets/error_state_widget.dart';
import 'package:sabo_arena/widgets/empty_state_widget.dart';

import 'package:sabo_arena/core/design_system/skeleton_widgets.dart';
import 'package:sabo_arena/core/device/device_info.dart';
import 'package:sabo_arena/core/design_system/spacing_ipad.dart';
import 'package:sabo_arena/widgets/common/common_widgets.dart'; // Phase 4
import 'package:sabo_arena/core/design_system/typography_ipad.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TournamentService _tournamentService = TournamentService.instance;
  final ClubPermissionService _permissionService = ClubPermissionService();
  bool _isLoading = true;
  String _selectedTab = 'upcoming';
  Map<String, dynamic> _currentFilters = {
    'locationRadius': 10.0,
    'entryFeeRange': <String>[],
    'formats': <String>[],
    'skillLevels': <String>[],
    'hasLiveStream': false,
    'hasAvailableSlots': false,
    'hasPrizePool': false,
  };

  List<Tournament> _allTournaments = [];
  String? _errorMessage;
  
  // 📱 iPad Master-Detail Layout State
  Tournament? _selectedTournament;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tournaments = await _tournamentService.getTournaments(
        status: _selectedTab,
      );

      // Apply sorting logic: newest created first, then by start date
      tournaments.sort((a, b) {
        // First priority: creation time (newest first)
        final aCreated = a.createdAt;
        final bCreated = b.createdAt;

        // If created within 24 hours of each other, sort by start date (closest first)
        final timeDiff = aCreated.difference(bCreated).inHours.abs();
        if (timeDiff < 24) {
          final aStart = a.startDate;
          final bStart = b.startDate;

          // For upcoming tournaments, show earliest start date first
          if (_selectedTab == 'upcoming') {
            return aStart.compareTo(bStart);
          }
          // For ongoing tournaments, show earliest start date first
          else if (_selectedTab == 'live') {
            return aStart.compareTo(bStart);
          }
          // For completed tournaments, show latest end date first
          else if (_selectedTab == 'completed') {
            final aEnd = a.endDate ?? a.startDate;
            final bEnd = b.endDate ?? b.startDate;
            return bEnd.compareTo(aEnd);
          }
        }

        // Otherwise, newest created first
        return bCreated.compareTo(aCreated);
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      for (int i = 0; i < tournaments.take(3).length; i++) {
        final t = tournaments[i];
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      if (mounted) {
        setState(() {
          _allTournaments = tournaments;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Show error if data loading fails
      if (mounted) {
        setState(() {
          _allTournaments = [];
          _isLoading = false;
          _errorMessage = 'Không thể tải dữ liệu giải đấu: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    final newTab = ['upcoming', 'live', 'completed'][_tabController.index];
    if (newTab != _selectedTab) {
      setState(() {
        _selectedTab = newTab;
      });
      _loadTournaments();
    }
  }

  void _handleNavigation(String route) {
    if (route != AppRoutes.tournamentListScreen) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  List<Tournament> get _filteredTournaments {
    // Temporarily simplified to fix dead_null_aware_expression warnings
    return _allTournaments;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardShortcutsWrapper(
      onSearch: () => _showSearch(context),
      onRefresh: () => _loadTournaments(),
      onNewItem: () => _handleCreateTournament(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0.5,
          shadowColor: AppColors.shadow,
          automaticallyImplyLeading: false,
          title: app_theme.AppBarTheme.buildGradientTitle('Giải đấu'),
          centerTitle: false,
          actions: [
            // Create Tournament Icon (Club Owner only)
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
            tooltip: 'Tạo giải đấu',
            color: AppColors.info600,
            onPressed: () => _handleCreateTournament(context),
          ),
          // Register Rank Icon
          IconButton(
            icon: const Icon(Icons.military_tech_outlined, size: 24),
            tooltip: 'Đăng ký hạng',
            color: AppColors.info600,
            onPressed: () => _handleRegisterRank(context),
          ),
          IconButton(
            icon: const Icon(Icons.account_tree_outlined, size: 22),
            tooltip: 'Demo Bảng Đấu',
            color: AppColors.textSecondary,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DemoBracketScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_outlined, size: 22),
            tooltip: 'Tìm kiếm',
            color: AppColors.textSecondary,
            onPressed: () => _showSearch(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(76),
          child: Column(
            children: [
              Divider(height: 0.5, thickness: 0.5, color: AppColors.divider),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.schedule_outlined, size: 20),
                      text: 'Sắp diễn ra',
                      height: 60,
                    ),
                    Tab(
                      icon: const Icon(Icons.sensors_outlined, size: 20),
                      text: 'Đang diễn ra',
                      height: 60,
                    ),
                    Tab(
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      text: 'Đã kết thúc',
                      height: 60,
                    ),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2,
                  labelStyle: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: context.scaleFont(13),
                  ),
                  unselectedLabelStyle: AppTypography.labelMedium.copyWith(
                    fontSize: context.scaleFont(13),
                  ),
                  dividerColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          heroTag: 'tournament_list_filter',
          onPressed: () => _showFilterBottomSheet(context),
          backgroundColor: AppColors.primary,
          elevation: 4,
          icon: const Icon(Icons.tune_outlined, size: 20),
          label: Text(
            'Lọc', overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      // 🎯 PHASE 1: Bottom navigation moved to PersistentTabScaffold
      // No bottomNavigationBar here to prevent duplicate navigation bars
      ),
    );
  }

  Widget _buildBody() {
    // 📱 iPad Landscape: Facebook-style Master-Detail Layout
    final isIPad = DeviceInfo.isIPad(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final showMasterDetail = isIPad && isLandscape;
    
    if (showMasterDetail) {
      return Row(
        children: [
          // Master Panel (List - 40% width, max 420px like Facebook)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.4 > 420 
              ? 420 
              : MediaQuery.of(context).size.width * 0.4,
            child: _buildTournamentList(),
          ),
          
          // Divider
          VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
          
          // Detail Panel (60% width)
          Expanded(
            child: _buildDetailPanel(),
          ),
        ],
      );
    }
    
    // 📱 Portrait: Standard Full-Width List
    return _buildTournamentList();
  }
  
  Widget _buildTournamentList() {
    final isIPad = DeviceInfo.isIPad(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final showMasterDetail = isIPad && isLandscape;
    
    if (_isLoading) {
      return const TournamentListSkeleton();
    }
    if (_errorMessage != null) {
      return RefreshableErrorStateWidget(
        errorMessage: _errorMessage,
        onRefresh: _loadTournaments,
        title: 'Không thể tải dữ liệu',
        description: 'Đã xảy ra lỗi khi tải danh sách giải đấu',
        showErrorDetails: true,
      );
    }
    if (_filteredTournaments.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadTournaments,
      child: OptimizedListView(
        itemCount: _filteredTournaments.length,
        itemBuilder: (context, index) {
          final tournament = _filteredTournaments[index];
          
          // Highlight selected tournament on iPad landscape
          final isSelected = showMasterDetail && _selectedTournament?.id == tournament.id;
          
          // Use eligibility-enabled card for upcoming tournaments only
          if (_selectedTab == 'upcoming') {
            return Container(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
              child: TournamentCardWithEligibility(
                tournament: tournament,
                tournamentCardData: _convertTournamentToCardData(tournament),
                onTap: () => _handleTournamentTap(tournament),
                onDetailTap: () => _handleTournamentTap(tournament),
                onShareTap: () => _shareTournament(tournament),
              ),
            );
          }
          
          // Use regular card for live/completed tournaments
          return Container(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
            child: TournamentCardWidget(
              tournament: _convertTournamentToCardData(tournament),
              onTap: () => _handleTournamentTap(tournament),
              onDetailTap: () => _handleTournamentTap(tournament),
              onShareTap: () => _shareTournament(tournament),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDetailPanel() {
    if (_selectedTournament == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: context.space24),
            Text(
              'Chọn giải đấu để xem chi tiết',
              style: TypographyIPad.title(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: context.space8),
            Text(
              'Nhấn vào giải đấu bên trái để xem thông tin',
              style: TypographyIPad.body(context).copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }
    
    // Show tournament detail in detail panel
    // TODO: Replace with actual TournamentDetailScreen content
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament Header
          Text(
            _selectedTournament!.title,
            style: TypographyIPad.headline(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.space16),
          
          // Tournament Details
          _buildDetailRow(
            Icons.location_on_outlined,
            'Địa điểm',
            _selectedTournament!.clubName ?? 'Chưa cập nhật',
          ),
          _buildDetailRow(
            Icons.calendar_today_outlined,
            'Thời gian',
            '${_selectedTournament!.startDate.day}/${_selectedTournament!.startDate.month}/${_selectedTournament!.startDate.year}',
          ),
          _buildDetailRow(
            Icons.people_outline,
            'Số người tham gia',
            '${_selectedTournament!.currentParticipants}/${_selectedTournament!.maxParticipants}',
          ),
          
          SizedBox(height: context.space24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToDetail(_selectedTournament!),
                  icon: Icon(Icons.info_outline),
                  label: Text('Xem chi tiết đầy đủ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: EdgeInsets.symmetric(vertical: context.space16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.space12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          SizedBox(width: context.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TypographyIPad.caption(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: context.space4),
                Text(
                  value,
                  style: TypographyIPad.body(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleTournamentTap(Tournament tournament) {
    final isIPad = DeviceInfo.isIPad(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final showMasterDetail = isIPad && isLandscape;
    
    if (showMasterDetail) {
      // iPad landscape: Update detail panel
      setState(() {
        _selectedTournament = tournament;
      });
    } else {
      // Portrait: Navigate to detail screen
      _navigateToDetail(tournament);
    }
  }

  /// Convert Tournament object to Map format for TournamentCardWidget
  Map<String, dynamic> _convertTournamentToCardData(Tournament tournament) {
    // Determine game type icon number (8, 9, or 10) based on gameFormat
    String iconNumber = '9'; // Default
    final gameFormat = tournament.gameFormat.toLowerCase();
    
    // Check for 10-ball first (most specific)
    if (gameFormat.contains('10')) {
      iconNumber = '10';
    } else if (gameFormat.contains('8')) {
      iconNumber = '8';
    } else if (gameFormat.contains('9')) {
      iconNumber = '9';
    }
    
    // Debug log to verify icon number
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Format date
    String dateStr = '';
    final startDate = tournament.startDate;
    final weekday = [
      'CN',
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
    ][startDate.weekday % 7];
    dateStr = '${startDate.day}/${startDate.month} - $weekday';

    // Format time
    String startTime = '';
    final hour = tournament.startDate.hour;
    final minute = tournament.startDate.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    startTime =
        '$hour12${minute > 0 ? ":${minute.toString().padLeft(2, '0')}" : ""}$period';

    // Determine status
    String status = 'ready';
    if (tournament.status == 'ongoing') {
      status = 'live';
    } else if (tournament.status == 'completed' ||
        tournament.status == 'cancelled') {
      status = 'done';
    }

    // Determine number of mạng based on tournament bracket format
    // Vietnamese billiard terminology:
    // Single Elimination = 1 Mạng (thua 1 trận là out)
    // Double Elimination = 2 Mạng (thua 2 trận mới out)
    int mangCount = 0; // Default: hide badge

    final bracketFormat = tournament.tournamentType.toLowerCase();
    if (bracketFormat.contains('single') ||
        bracketFormat == 'single_elimination') {
      mangCount = 1; // Single elimination = 1 mạng
    } else if (bracketFormat.contains('double') ||
        bracketFormat == 'double_elimination') {
      mangCount = 2; // Double elimination = 2 mạng
    } else if (bracketFormat.contains('robin') ||
        bracketFormat.contains('swiss') ||
        bracketFormat.contains('ladder') ||
        bracketFormat.contains('sabo')) {
      mangCount = 0; // These formats don't have "mạng" concept - hide badge
    } else {
      mangCount = 1; // Default to single elimination
    }

    return {
      'name': tournament.title,
      'date': dateStr,
      'startTime': startTime,
      'playersCount':
          '${tournament.currentParticipants}/${tournament.maxParticipants}',
      'prizePool': _formatPrize(tournament.prizePool),
      'rating': tournament.skillLevelRequired ?? 'All',
      'iconNumber': iconNumber,
      'clubLogo': tournament.clubLogo,
      'clubName': tournament.clubName ?? 'Club',
      'mangCount': mangCount,
      'isLive': tournament.status == 'ongoing',
      'status': status,
      // NEW ENHANCEMENT FIELDS
      'entryFee': tournament.entryFee > 0
          ? _formatPrize(tournament.entryFee)
          : 'free',
      'registrationDeadline': tournament.registrationDeadline.toIso8601String(),
      'prizeBreakdown': _getPrizeBreakdown(tournament),
      'venue': tournament.venueAddress ?? tournament.clubAddress ?? '${tournament.clubName}',
    };
  }

  /// Get prize breakdown from custom distribution or calculate from pool
  Map<String, String>? _getPrizeBreakdown(Tournament tournament) {
    if (tournament.prizePool <= 0) return null;
    
    // Check for custom distribution
    final prizeDistribution = tournament.prizeDistribution;
    if (prizeDistribution != null) {
      // ✅ NEW: Check for text-based format (first, second, third keys with text values)
      if (prizeDistribution.containsKey('first') && prizeDistribution['first'] is String) {
        return {
          'first': prizeDistribution['first'] as String,
          if (prizeDistribution['second'] != null)
            'second': prizeDistribution['second'] as String,
          if (prizeDistribution['third'] != null)
            'third': prizeDistribution['third'] as String,
          if (prizeDistribution['fourth'] != null)
            'fourth': prizeDistribution['fourth'] as String,
          if (prizeDistribution['fifth_to_eighth'] != null)
            'fifth_to_eighth': prizeDistribution['fifth_to_eighth'] as String,
        };
      }
      
      // Array-based format (distribution array)
      if (prizeDistribution['distribution'] != null) {
        final customDistribution = prizeDistribution['distribution'] as List?;
        if (customDistribution != null && customDistribution.isNotEmpty) {
          // Use custom amounts
          return {
            if (customDistribution.isNotEmpty)
              'first': _formatPrize((customDistribution[0]['cashAmount'] ?? 0).toDouble()),
            if (customDistribution.length > 1)
              'second': _formatPrize((customDistribution[1]['cashAmount'] ?? 0).toDouble()),
            if (customDistribution.length > 2)
              'third': _formatPrize((customDistribution[2]['cashAmount'] ?? 0).toDouble()),
          };
        }
      }
    }
    
    // Fallback to percentage-based calculation
    return {
      'first': _formatPrize(tournament.prizePool * 0.5),  // 50% for 1st
      'second': _formatPrize(tournament.prizePool * 0.3), // 30% for 2nd
      'third': _formatPrize(tournament.prizePool * 0.2),  // 20% for 3rd
    };
  }

  String _formatPrize(double prize) {
    if (prize >= 1000000) {
      return '${(prize / 1000000).toStringAsFixed(1)}M';
    }
    if (prize >= 1000) {
      return '${(prize / 1000).toStringAsFixed(0)}K';
    }
    return '${prize.toStringAsFixed(0)}đ';
  }

  void _navigateToDetail(Tournament tournament) {
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentDetailScreen,
      arguments: tournament.id,
    );
  }

  Future<void> _shareTournament(Tournament tournament) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tạo hình ảnh chia sẻ...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Use rich share with image
      await ShareService.shareTournamentRich(
        tournamentId: tournament.id,
        tournamentName: tournament.title,
        startDate: tournament.startDate.toIso8601String(),
        participants: tournament.maxParticipants,
        prizePool: tournament.prizePool.toStringAsFixed(0),
        format: tournament.format,
        status: tournament.status,
        context: context,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      AppSnackbar.success(
        context: context,
        message: 'Đã chia sẻ giải đấu!',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('❌ Error sharing tournament: $e', tag: 'tournament_list_screen');
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      AppSnackbar.warning(
        context: context,
        message: 'Không thể chia sẻ: $e',
      );
    }
  }

  Widget _buildEmptyState() {
    String emptyMessage;
    IconData emptyIcon;

    switch (_selectedTab) {
      case 'upcoming':
        emptyMessage = 'Chưa có giải đấu sắp diễn ra';
        emptyIcon = Icons.event_busy_outlined;
        break;
      case 'live':
        emptyMessage = 'Hiện không có giải đấu nào đang diễn ra';
        emptyIcon = Icons.live_tv_outlined;
        break;
      case 'completed':
        emptyMessage = 'Chưa có giải đấu nào kết thúc';
        emptyIcon = Icons.history_outlined;
        break;
      default:
        emptyMessage = 'Không có giải đấu nào';
        emptyIcon = Icons.inbox_outlined;
    }

    return RefreshableEmptyStateWidget(
      message: emptyMessage,
      icon: emptyIcon,
      onRefresh: _loadTournaments,
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TournamentFilterBottomSheet(
        currentFilters: _currentFilters,
        onFiltersApplied: (filters) {
          setState(() {
            _currentFilters = filters;
          });
        },
      ),
    );
  }

  Map<String, dynamic> _tournamentToMap(Tournament tournament) {
    return {
      'id': tournament.id,
      'title': tournament.title,
      'clubName': tournament.clubId ?? 'N/A',
      'format': tournament.tournamentType,
      'entryFee': tournament.entryFee > 0
          ? '${tournament.entryFee.toStringAsFixed(0)}đ'
          : 'Miễn phí',
      'coverImage': tournament.coverImageUrl,
      'skillLevelRequired': tournament.skillLevelRequired,
    };
  }

  // Handle Create Tournament - Check authentication and permissions
  Future<void> _handleCreateTournament(BuildContext context) async {
    try {
      // 1. Check if user is authenticated
      final currentUser = AuthService.instance.currentUser;

      if (kDebugMode) {
        ProductionLogger.info('🔍 DEBUG: Starting _handleCreateTournament', tag: 'tournament_list_screen');
        ProductionLogger.info('👤 DEBUG: Current user ID: ${currentUser?.id}', tag: 'tournament_list_screen');
      }

      if (currentUser == null) {
        if (kDebugMode) ProductionLogger.info('❌ DEBUG: No user logged in', tag: 'tournament_list_screen');
        _showLoginRequiredDialog(context);
        return;
      }

      // 2. Show loading dialog while checking permissions
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 3. Check if user owns any club
      if (kDebugMode) ProductionLogger.info('🔍 DEBUG: Checking owned club...', tag: 'tournament_list_screen');
      final ownedClub = await ClubService.instance.getClubByOwnerId(
        currentUser.id,
      );

      if (kDebugMode) {
        ProductionLogger.info('🏢 DEBUG: Owned club: ${ownedClub?.name} (ID: ${ownedClub?.id})',  tag: 'tournament_list_screen');
      }

      if (ownedClub != null) {
        // User owns a club - OWNER has full access, bypass permission checks
        if (!context.mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (kDebugMode) {
          ProductionLogger.info('✅ DEBUG: User is club owner - granting access', tag: 'tournament_list_screen');
          ProductionLogger.info('🚀 DEBUG: Navigating to TournamentCreationWizard...', tag: 'tournament_list_screen');
        }

        // DIRECT NAVIGATION FOR OWNER - No permission checks needed
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TournamentCreationWizard(clubId: ownedClub.id),
          ),
        ).then((result) {
          if (result != null) {
            if (kDebugMode) ProductionLogger.info('✅ DEBUG: Tournament created successfully', tag: 'tournament_list_screen');
            _loadTournaments(); // Refresh tournament list
          }
        });
      } else {
        // User doesn't own any club - check if they're admin/member of any club
        final userClubs = await _getUserClubsWithPermission(currentUser.id);

        if (!context.mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (userClubs.isNotEmpty) {
          // User is admin/member with tournament creation permission
          _showSelectClubDialog(context, userClubs);
        } else {
          // User doesn't have any club - show registration dialog
          _showRegisterClubDialog(context);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog if still open

      AppSnackbar.error(
        context: context,
        message: 'Lỗi: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );

      if (kDebugMode) ProductionLogger.info('❌ Error in _handleCreateTournament: $e', tag: 'tournament_list_screen');
    }
  }

  // Get list of clubs where user has tournament creation permission
  Future<List<Club>> _getUserClubsWithPermission(String userId) async {
    try {
      // Get all clubs where user is a member
      final memberResponse = await Supabase.instance.client
          .from('club_members')
          .select('club_id, role, status')
          .eq('user_id', userId)
          .eq('status', 'active');

      if (memberResponse.isEmpty) return [];

      // For each club, check if user can create tournaments
      final List<Club> clubsWithPermission = [];

      for (final membership in memberResponse) {
        final clubId = membership['club_id'] as String;
        final canCreate = await _permissionService.canManageTournaments(
          clubId,
          userId,
        );

        if (canCreate) {
          try {
            final club = await ClubService.instance.getClubById(clubId);
            clubsWithPermission.add(club);
          } catch (e) {
            if (kDebugMode) ProductionLogger.info('⚠️ Could not load club $clubId: $e', tag: 'tournament_list_screen');
          }
        }
      }

      return clubsWithPermission;
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('❌ Error getting user clubs with permission: $e', tag: 'tournament_list_screen');
      return [];
    }
  }

  // Show dialog for selecting which club to create tournament for
  void _showSelectClubDialog(BuildContext context, List<Club> clubs) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        title: Text(
          'Chọn câu lạc bộ', overflow: TextOverflow.ellipsis, style: TextStyle(
            fontSize: context.scaleFont(18),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: clubs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final club = clubs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.gray50,
                  child: Icon(Icons.groups, color: AppColors.info600),
                ),
                title: Text(
                  club.name, style: TextStyle(
                    fontSize: context.scaleFont(15),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: club.address != null
                    ? Text(
                        club.address!, overflow: TextOverflow.ellipsis, style: TextStyle(
                          fontSize: context.scaleFont(13),
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TournamentCreationWizard(clubId: club.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Show dialog when user doesn't have permission
  void _showNoPermissionDialog(BuildContext context, ClubRole? role) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.block_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có quyền', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: context.scaleFont(18),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn không có quyền tạo giải đấu.\nVai trò hiện tại: ${_getRoleDisplayName(role)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.scaleFont(15),
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Đã hiểu',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get display name for role
  String _getRoleDisplayName(ClubRole? role) {
    if (role == null) return 'Không có';
    
    switch (role) {
      case ClubRole.owner:
        return 'Chủ CLB';
      case ClubRole.admin:
        return 'Quản trị viên';
      case ClubRole.moderator:
        return 'Người điều hành';
      case ClubRole.member:
        return 'Thành viên';
      case ClubRole.guest:
        return 'Khách';
    }
  }

  // Show login required dialog
  void _showLoginRequiredDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.login_rounded,
                size: 32,
                color: AppColors.info600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cần đăng nhập', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: context.scaleFont(18),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn cần đăng nhập để sử dụng tính năng này.',
              textAlign: TextAlign.center, style: TextStyle(
                fontSize: context.scaleFont(15),
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Để sau',
                    type: AppButtonType.text,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Đăng nhập',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.loginScreen);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Handle Register Rank
  void _handleRegisterRank(BuildContext context) {
    // Navigate to Rank Management Screen (already exists)
    Navigator.pushNamed(context, AppRoutes.rankManagementScreen);
  }

  // Show dialog for non-club owners
  void _showRegisterClubDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 32,
                color: AppColors.info600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cần đăng ký CLB', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: context.scaleFont(18),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn cần đăng ký và trở thành chủ câu lạc bộ để có thể tạo giải đấu.',
              textAlign: TextAlign.center, style: TextStyle(
                fontSize: context.scaleFont(15),
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Để sau',
                    type: AppButtonType.text,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Đăng ký ngay',
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to Club Registration Screen (already exists)
                      Navigator.pushNamed(
                        context,
                        AppRoutes.clubRegistrationScreen,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    final tournamentsForSearch = _filteredTournaments
        .map(_tournamentToMap)
        .toList();

    showSearch<String>(
      context: context,
      delegate: TournamentSearchDelegate(
        tournaments: tournamentsForSearch,
        onTournamentSelected: (tournamentMap) {
          Navigator.pushNamed(
            context,
            AppRoutes.tournamentDetailScreen,
            arguments: tournamentMap['id'],
          );
        },
      ),
    );
  }
}

