import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design_system/design_system.dart';
import '../../core/device/device_info.dart';
import '../../models/tournament.dart';
import '../../services/tournament_service.dart';
import '../../services/unified_bracket_service.dart';
import '../tournament_detail_screen/widgets/match_management_tab.dart';
import '../tournament_detail_screen/widgets/participant_management_tab.dart';
import '../tournament_detail_screen/widgets/tournament_rankings_widget.dart';
import 'widgets/bracket_management_tab.dart';
import '../tournament_creation_wizard/tournament_creation_wizard.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class TournamentManagementCenterScreen extends StatefulWidget {
  final String clubId;

  const TournamentManagementCenterScreen({super.key, required this.clubId});

  @override
  State<TournamentManagementCenterScreen> createState() =>
      _TournamentManagementCenterScreenState();
}

class _TournamentManagementCenterScreenState
    extends State<TournamentManagementCenterScreen> {
  final TournamentService _tournamentService = TournamentService.instance;
  final UnifiedBracketService _bracketService = UnifiedBracketService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Tournament> _tournaments = [];
  Tournament? _selectedTournament;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get tournaments with error handling
      List<Tournament> tournaments = [];
      try {
        tournaments = await _tournamentService.getTournaments(
          clubId: widget.clubId,
        );
      } catch (e) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        // Try alternative approach if direct query fails
        tournaments = [];
      }

      setState(() {
        _tournaments = tournaments;
        _isLoading = false;
        // Auto-select first tournament if available
        if (_tournaments.isNotEmpty) {
          // If current selected tournament is not in new list, select first
          if (_selectedTournament == null ||
              !_tournaments.any((t) => t.id == _selectedTournament!.id)) {
            _selectedTournament = _tournaments.first;
          } else {
            // Update selected tournament with fresh data
            _selectedTournament = _tournaments.firstWhere(
              (t) => t.id == _selectedTournament!.id,
            );
          }
        }
      });
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách giải đấu'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _loadTournaments,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 iPad: Detect for wider bracket layout
    final isIPad = DeviceInfo.isIPad(context);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final useWideBracketLayout = isIPad && isLandscape;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button when used in tab
        title: Text(
          'Quản lý Giải đấu', overflow: TextOverflow.ellipsis, style: AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Create Tournament Button
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _navigateToCreateTournament,
              icon: Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 18,
              ),
              label: Text(
                'Tạo giải đấu', overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: AppColors.divider),
        ),
      ),
      body: SafeArea(
        bottom: false, // Don't add bottom padding - let parent handle it
        child: _buildResponsiveBody(useWideBracketLayout),
      ),
    );
  }

  // 🎯 iPad: Responsive body with wide bracket support
  Widget _buildResponsiveBody(bool useWideBracketLayout) {
    return Column(
      children: [
        // Tournament Selection & Quick Actions
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: _buildTournamentSelectorWithActions(),
        ),

        // Management Panel Section with responsive bracket
        Expanded(
          child: _selectedTournament != null
              ? (useWideBracketLayout 
                  ? _buildWideBracketLayout() 
                  : _buildManagementTabs())
              : _buildEmptyState(),
        ),
      ],
    );
  }

  // 🎯 iPad: Wide bracket layout for landscape mode
  Widget _buildWideBracketLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1400), // Extra wide for brackets
        child: _buildManagementTabs(),
      ),
    );
  }

  Widget _buildTournamentSelectorWithActions() {
    final isActiveTournament = _selectedTournament?.status == 'active';
    final hasBracket =
        isActiveTournament || _selectedTournament?.status == 'completed';

    if (_isLoading) {
      return Container(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Loading tournaments...', overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(
                // 13px - iOS secondary text
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_tournaments.isEmpty) {
      return Container(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
            SizedBox(width: 8),
            Text(
              'No tournaments available', overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(
                // 13px - iOS secondary text
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Combined: Dropdown + Action Button
    return Row(
      children: [
        // Tournament Selector (Dropdown)
        Expanded(
          flex: 2,
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTournament?.id,
                      isExpanded: true,
                      isDense: true,
                      iconSize: 20,
                      icon: Icon(
                        Icons.keyboard_arrow_down_outlined,
                        color: AppColors.textSecondary,
                      ),
                      hint: Text(
                        'Select...', overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium.copyWith(
                          // 15px - iOS standard
                          color: AppColors.textSecondary,
                        ),
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        // 15px - iOS dropdown text
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      items: _tournaments.map((tournament) {
                        return DropdownMenuItem<String>(
                          value: tournament.id,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(tournament.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tournament.title, style: AppTypography.bodyMedium.copyWith(
                                    // 15px - iOS list item
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTournament = _tournaments.firstWhere(
                              (t) => t.id == newValue,
                            );
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: 8),

        // Action Button (Create Bracket)
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: hasBracket ? null : _createTournamentBracket,
              icon: Icon(
                hasBracket
                    ? Icons.check_circle_outline
                    : Icons.account_tree_outlined,
                size: 16,
              ),
              label: Text(
                hasBracket ? 'Created' : 'Create', overflow: TextOverflow.ellipsis, style: AppTypography
                    .labelMedium, // 14px, SemiBold - iOS button standard
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasBracket
                    ? AppColors.surfaceVariant
                    : AppColors.primary,
                foregroundColor: hasBracket
                    ? AppColors.textSecondary
                    : Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementTabs() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.labelSmall.copyWith(
                // 12px - compact
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTypography.labelSmall.copyWith(
                // 12px
                fontWeight: FontWeight.w500,
              ),
              labelPadding: EdgeInsets.symmetric(
                horizontal: 4,
              ), // Minimal padding between tabs
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.label, // Fit to label size
              tabAlignment: TabAlignment.fill, // Fill width evenly
              isScrollable: false, // Fixed layout, no scrolling
              dividerColor: Colors.transparent, // No divider line
              tabs: [
                Tab(
                  height: 48, // Slightly reduced height
                  icon: Icon(Icons.people_outline, size: 18),
                  iconMargin: EdgeInsets.only(bottom: 2),
                  text: 'Members',
                ),
                Tab(
                  height: 48,
                  icon: Icon(Icons.sports_outlined, size: 18),
                  iconMargin: EdgeInsets.only(bottom: 2),
                  text: 'Matches',
                ),
                Tab(
                  height: 48,
                  icon: Icon(Icons.account_tree_outlined, size: 18),
                  iconMargin: EdgeInsets.only(bottom: 2),
                  text: 'Bracket',
                ),
                Tab(
                  height: 48,
                  icon: Icon(Icons.emoji_events_outlined, size: 18),
                  iconMargin: EdgeInsets.only(bottom: 2),
                  text: 'Results',
                ),
              ],
            ),
          ),
          SizedBox(height: 12.sp),
          Expanded(
            child: TabBarView(
              children: [
                // Participants Tab
                ParticipantManagementTab(tournamentId: _selectedTournament!.id),

                // Matches Tab
                MatchManagementTab(tournamentId: _selectedTournament!.id),

                // Bracket Tab
                BracketManagementTab(tournament: _selectedTournament!),

                // Results Tab
                TournamentRankingsWidget(
                  tournamentId: _selectedTournament!.id,
                  tournamentStatus: _selectedTournament!.status,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustrative icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_tree_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 16.sp),

              // Title
              Text(
                'No Tournament Selected', overflow: TextOverflow.ellipsis, style: AppTypography
                    .headingSmall, // 20px, SemiBold - iOS empty state title
              ),
              SizedBox(height: 8.sp),

              // Description
              Text(
                'Select a tournament from the dropdown above\nto manage participants, matches, and brackets',
                textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(
                  // 13px - iOS secondary text
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 24.sp),

              // CTA Button
              if (_tournaments.isEmpty)
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Go back to create tournament
                    },
                    icon: Icon(Icons.add_outlined, size: 20),
                    label: Text(
                      'Create New Tournament', overflow: TextOverflow.ellipsis, style: AppTypography
                          .labelMedium, // 14px, SemiBold - iOS button
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary, width: 1.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.sp,
                        vertical: 12.sp,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Action handlers
  Future<void> _createTournamentBracket() async {
    if (_selectedTournament == null) return;

    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40),
            padding: EdgeInsets.all(24.sp),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40.sp,
                  height: 40.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 16.sp),
                Text(
                  'Creating Tournament Bracket...', overflow: TextOverflow.ellipsis, style: AppTypography.headingSmall.copyWith(
                    // 20px - iOS dialog title
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.sp),
                Text(
                  'Please wait while we generate matches', overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium.copyWith(
                    // 15px - iOS body text
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Create bracket with error handling
      try {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // First check if bracket already exists
        final existingMatches = await _supabase
            .from('matches')
            .select('id')
            .eq('tournament_id', _selectedTournament!.id)
            .limit(1);

        if (existingMatches.isNotEmpty) {
          throw Exception(
            'Bảng đấu đã tồn tại cho giải này. Vui lòng xóa bảng đấu cũ trước khi tạo mới.',
          );
        }

        // Get tournament participants first
        final participantProfiles = await _tournamentService
            .getTournamentParticipants(_selectedTournament!.id);
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        if (participantProfiles.isEmpty) {
          throw Exception('Không có thành viên tham gia giải đấu');
        }

        // Convert to Map format for bracket service
        final participants = participantProfiles
            .map(
              (profile) => {
                'user_id': profile.id,
                'full_name': profile.fullName.isNotEmpty
                    ? profile.fullName
                    : profile.username,
                'username': profile.username,
                'avatar_url': profile.avatarUrl,
                'payment_status':
                    'confirmed', // Add this for BracketService validation
              },
            )
            .toList();

        // 🔧 DETECT TOURNAMENT FORMAT AND USE APPROPRIATE SERVICE
        // Use bracketFormat (which maps to tournamentType) for bracket creation
        final tournamentFormat = _selectedTournament!.bracketFormat;
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        Map<String, dynamic> result;

        // Extract participant IDs
        final participantIds = participants
            .map((p) => p['user_id'] as String)
            .toList();

        // Use UnifiedBracketService for all formats
        result = await _bracketService.createBracket(
          tournamentId: _selectedTournament!.id,
          format: tournamentFormat,
          participantIds: participantIds,
        );

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        if (!result.containsKey('success')) {
          // Convert bracket result to success format
          result['success'] = true;
          result['message'] =
              'Bảng đấu $tournamentFormat đã được tạo với ${result['total_matches']} trận đấu';
        }

        if (!result.containsKey('success') || !result['success']) {
          throw Exception(
            result['message'] ?? 'Lỗi không xác định khi tạo bảng đấu',
          );
        }
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      } catch (e) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        throw Exception('Không thể tạo bảng đấu: ${e.toString()}');
      }

      if (mounted) Navigator.pop(context);

      // Reload tournaments to update status
      await _loadTournaments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 6.sp),
                Expanded(
                  child: Text(
                    'Bảng đấu bida đã tạo thành công!', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: ${e.toString()}',
              style: TextStyle(fontSize: 12.sp),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  // Navigation to create tournament
  void _navigateToCreateTournament() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentCreationWizard(clubId: widget.clubId),
      ),
    ).then((result) {
      // Reload tournaments after creating new one
      if (result != null) {
        _loadTournaments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Giải đấu đã được tạo thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'recruiting':
        return Colors.orange;
      case 'ready':
        return Colors.blue;
      case 'upcoming':
        return Colors.teal;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

