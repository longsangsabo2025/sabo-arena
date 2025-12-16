import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'tournament_overview_tab.dart';
import 'participant_management_tab.dart';
import 'match_management_tab.dart';
import 'tournament_settings_tab.dart';
import '../../../services/bracket_visualization_service.dart';
import 'full_tournament_bracket_screen.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class TournamentManagementPanel extends StatefulWidget {
  final String tournamentId;
  final String tournamentStatus;
  final VoidCallback? onStatusChanged;

  const TournamentManagementPanel({
    super.key,
    required this.tournamentId,
    required this.tournamentStatus,
    this.onStatusChanged,
  });

  @override
  _TournamentManagementPanelState createState() =>
      _TournamentManagementPanelState();
}

class _TournamentManagementPanelState extends State<TournamentManagementPanel>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  int _selectedTab = 0;
  final List<String> _tabs = [
    'Tổng quan',
    'Người chơi',
    'Bảng đấu',
    'Trận đấu',
    'Cài đặt',
  ];

  // Callback to refresh bracket when match scores are updated
  void _onMatchScoreUpdated() {
    // Force rebuild to trigger bracket data refresh
    if (mounted) {
      setState(() {
        // This will trigger a rebuild which will refresh the bracket tab
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.sp),
                ),
              ),
              child: Column(
                children: [
                  _buildTabBar(),
                  Expanded(child: _buildTabContent()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.dividerLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý giải đấu',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: AppTheme.textSecondaryLight),
              ),
            ],
          ),
          SizedBox(height: 16.sp),
          // Tab buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isSelected = _selectedTab == index;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedTab = index);
                    _animationController.forward(from: 0);
                  },
                  borderRadius: BorderRadius.circular(20.sp),
                  child: Container(
                    margin: EdgeInsets.only(right: 8.sp),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.sp,
                      vertical: 8.sp,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryLight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.sp),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryLight
                            : AppTheme.dividerLight,
                      ),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return TournamentOverviewTab(
          tournamentId: widget.tournamentId,
          tournamentStatus: widget.tournamentStatus,
          onStatusChanged: widget.onStatusChanged,
        );
      case 1:
        return ParticipantManagementTab(tournamentId: widget.tournamentId);
      case 2:
        return _SimpleBracketTab(tournamentId: widget.tournamentId);
      case 3:
        return MatchManagementTab(
          tournamentId: widget.tournamentId,
          onMatchScoreUpdated: _onMatchScoreUpdated,
        );
      case 4:
        return TournamentSettingsTab(
          tournamentId: widget.tournamentId,
          onStatusChanged: widget.onStatusChanged,
        );
      default:
        return Container();
    }
  }
}

// Bracket Tab using BracketVisualizationService
class _SimpleBracketTab extends StatefulWidget {
  final String tournamentId;

  const _SimpleBracketTab({required this.tournamentId});

  @override
  State<_SimpleBracketTab> createState() => _SimpleBracketTabState();
}

class _SimpleBracketTabState extends State<_SimpleBracketTab> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _error;
  Widget? _bracketWidget;

  @override
  void initState() {
    super.initState();
    _loadBracket();
  }

  Future<void> _loadBracket() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Load tournament info
      final tournamentData = await _supabase
          .from('tournaments')
          .select('id, title, bracket_format')
          .eq('id', widget.tournamentId)
          .single();

      final bracketFormat = tournamentData['bracket_format'] as String?;
      ProductionLogger.info('🎯 Bracket format: $bracketFormat', tag: 'tournament_management_panel');

      // 2. Load matches with bracket_type explicitly
      final matchesData = await _supabase
          .from('matches')
          .select('''
            id,
            round_number,
            match_number,
            bracket_type,
            player1_id,
            player2_id,
            winner_id,
            status,
            player1_score,
            player2_score,
            bracket_position,
            scheduled_time,
            player1:profiles!matches_player1_id_fkey(id, full_name, avatar_url),
            player2:profiles!matches_player2_id_fkey(id, full_name, avatar_url)
          ''')
          .eq('tournament_id', widget.tournamentId)
          .order('round_number');

      ProductionLogger.info('📊 Loaded ${matchesData.length} matches', tag: 'tournament_management_panel');
      if (matchesData.isNotEmpty) {
        ProductionLogger.info('🔍 First match RAW DATA:', tag: 'tournament_management_panel');
        ProductionLogger.info('   bracket_type: ${matchesData[0]['bracket_type']}', tag: 'tournament_management_panel');
        ProductionLogger.info('   round_number: ${matchesData[0]['round_number']}', tag: 'tournament_management_panel');
        ProductionLogger.info('   match_number: ${matchesData[0]['match_number']}', tag: 'tournament_management_panel');
      }

      // 3. Transform matches to include player names
      final matches = matchesData.map<Map<String, dynamic>>((match) {
        return {
          ...match,
          'player1_name': match['player1']?['full_name'] ?? 'TBD',
          'player2_name': match['player2']?['full_name'] ?? 'TBD',
        };
      }).toList();

      // Debug: Check if bracket_type is preserved after transform
      if (matches.isNotEmpty) {
        ProductionLogger.info('🔍 After transform:', tag: 'tournament_management_panel');
        ProductionLogger.info('   bracket_type: ${matches[0]['bracket_type']}', tag: 'tournament_management_panel');
        ProductionLogger.info('   player1_name: ${matches[0]['player1_name']}', tag: 'tournament_management_panel');
      }

      // 4. Use BracketVisualizationService to build widget
      final bracketWidget = await BracketVisualizationService.instance
          .buildTournamentBracket(
            tournamentId: widget.tournamentId,
            bracketData: {
              'id': widget.tournamentId,
              'format': bracketFormat ?? 'sabo_de16',
              'matches': matches,
            },
            onMatchTap: () {
              // No action needed - just display
            },
          );

      setState(() {
        _bracketWidget = bracketWidget;
        _isLoading = false;
      });
    } catch (e) {
      ProductionLogger.info('❌ Error loading bracket: $e', tag: 'tournament_management_panel');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Lỗi: $_error'),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadBracket, child: Text('Thử lại')),
          ],
        ),
      );
    }

    return Stack(
      children: [
        _bracketWidget ?? const Center(child: Text('Không có dữ liệu')),
        
        // Full Tournament Button (Top Right)
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _openFullTournamentView,
            icon: const Icon(Icons.fullscreen),
            label: const Text('Full Tournament'),
            backgroundColor: AppTheme.primaryLight,
            elevation: 4,
          ),
        ),
      ],
    );
  }

  Future<void> _openFullTournamentView() async {
    try {
      if (!mounted) return;

      // Navigate to native Full Tournament Bracket Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullTournamentBracketScreen(
            tournamentId: widget.tournamentId,
            tournamentTitle: 'Full Tournament', // Can fetch from tournament data if needed
          ),
        ),
      );
    } catch (e) {
      ProductionLogger.info('❌ Error opening full tournament view: $e', tag: 'tournament_management_panel');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
