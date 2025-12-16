import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../core/gestures/gesture_widgets.dart';
import '../../../core/utils/rank_migration_helper.dart';
import '../../../services/cached_tournament_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class LiveTournamentBracketWidget extends StatefulWidget {
  final String tournamentId;

  const LiveTournamentBracketWidget({super.key, required this.tournamentId});

  @override
  State<LiveTournamentBracketWidget> createState() =>
      _LiveTournamentBracketWidgetState();
}

class _LiveTournamentBracketWidgetState
    extends State<LiveTournamentBracketWidget> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _matches = [];
  int _totalParticipants = 0;
  String _tournamentStatus = '';

  String _selectedBracket = 'WB';
  final Map<String, String> _bracketNames = {
    'WB': 'Nhánh Thắng',
    'LB_A': 'Nhánh Thua A',
    'LB_B': 'Nhánh Thua B',
    'FINALS': 'Chung Kết',
  };

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);

    try {
      ProductionLogger.info('🔄 LiveTournamentBracketWidget: Loading matches with cache...', tag: 'live_tournament_bracket_widget');

      // Load tournament info
      final tournament = await CachedTournamentService.loadTournament(
        widget.tournamentId,
      );

      // Load matches with cache
      List<Map<String, dynamic>> matches;
      try {
        matches = await CachedTournamentService.loadMatches(
          widget.tournamentId,
        );
        ProductionLogger.info('📋 Loaded ${matches.length} matches from cache/service', tag: 'live_tournament_bracket_widget');
      } catch (e) {
        ProductionLogger.info('⚠️ Cache failed, using direct service: $e', tag: 'live_tournament_bracket_widget');
        // Fallback to direct database query
        matches = await supabase
            .from('matches')
            .select('''
              id,
              bracket_type,
              round_number,
              match_number,
              player1_id,
              player2_id,
              winner_id,
              player1_score,
              player2_score,
              status,
              scheduled_at,
              player1:player1_id(id, full_name, avatar_url, rank, elo_rating),
              player2:player2_id(id, full_name, avatar_url, rank, elo_rating)
            ''')
            .eq('tournament_id', widget.tournamentId)
            .order('round_number', ascending: true)
            .order('match_number', ascending: true);
      }

      setState(() {
        _matches = matches.map<Map<String, dynamic>>((match) {
          // Debug log để kiểm tra score values
          if (match['player1_score'] != null ||
              match['player2_score'] != null) {
            ProductionLogger.info('🔍 Match ${match['match_number']} scores: P1=${match['player1_score']}, P2=${match['player2_score']}',  tag: 'live_tournament_bracket_widget');
          }

          return {
            ...match,
            'player1_name': match['player1']?['full_name'] ?? 'TBD',
            'player2_name': match['player2']?['full_name'] ?? 'TBD',
            'player1_avatar': match['player1']?['avatar_url'],
            'player2_avatar': match['player2']?['avatar_url'],
            'player1_rank': match['player1']?['rank'] ?? '',
            'player2_rank': match['player2']?['rank'] ?? '',
            'player1_elo': match['player1']?['elo_rating'] ?? 0,
            'player2_elo': match['player2']?['elo_rating'] ?? 0,
            // Explicitly preserve score fields
            'player1_score': match['player1_score'] ?? 0,
            'player2_score': match['player2_score'] ?? 0,
          };
        }).toList();

        _totalParticipants = tournament?['participant_count'] ?? 0;
        _tournamentStatus = tournament?['status'] ?? '';
        _isLoading = false;
      });

      ProductionLogger.info('✅ LiveTournamentBracketWidget: Loaded ${_matches.length} matches', tag: 'live_tournament_bracket_widget');
    } catch (e) {
      ProductionLogger.info('❌ Error loading tournament bracket: $e', tag: 'live_tournament_bracket_widget');
      setState(() => _isLoading = false);
    }
  }

  Future<void> refreshData() async {
    ProductionLogger.info('🔄 LiveTournamentBracketWidget: Force refreshing data...', tag: 'live_tournament_bracket_widget');

    // Force refresh bypassing cache to get latest data
    try {
      final matches = await supabase
          .from('matches')
          .select('''
            id,
            bracket_type,
            round_number,
            match_number,
            player1_id,
            player2_id,
            winner_id,
            player1_score,
            player2_score,
            status,
            scheduled_at,
            player1:player1_id(id, full_name, avatar_url, rank, elo_rating),
            player2:player2_id(id, full_name, avatar_url, rank, elo_rating)
          ''')
          .eq('tournament_id', widget.tournamentId)
          .order('round_number', ascending: true)
          .order('match_number', ascending: true);

      ProductionLogger.info('🔄 Force refresh: Fetched ${matches.length} matches directly from database',  tag: 'live_tournament_bracket_widget');

      setState(() {
        _matches = matches.map<Map<String, dynamic>>((match) {
          // Debug log scores during refresh
          if (match['player1_score'] != null ||
              match['player2_score'] != null) {
            ProductionLogger.info('🔍 REFRESH Match ${match['match_number']} scores: P1=${match['player1_score']}, P2=${match['player2_score']}',  tag: 'live_tournament_bracket_widget');
          }

          return {
            ...match,
            'player1_name': match['player1']?['full_name'] ?? 'TBD',
            'player2_name': match['player2']?['full_name'] ?? 'TBD',
            'player1_avatar': match['player1']?['avatar_url'],
            'player2_avatar': match['player2']?['avatar_url'],
            'player1_rank': match['player1']?['rank'] ?? '',
            'player2_rank': match['player2']?['rank'] ?? '',
            'player1_elo': match['player1']?['elo_rating'] ?? 0,
            'player2_elo': match['player2']?['elo_rating'] ?? 0,
            // Explicitly preserve score fields
            'player1_score': match['player1_score'] ?? 0,
            'player2_score': match['player2_score'] ?? 0,
          };
        }).toList();
      });

      ProductionLogger.info('✅ Force refresh completed with ${_matches.length} matches', tag: 'live_tournament_bracket_widget');
    } catch (e) {
      ProductionLogger.info('❌ Force refresh failed: $e', tag: 'live_tournament_bracket_widget');
      // Fallback to normal load
      await _loadMatches();
    }
  }

  String _getRoundDisplayName(int roundNumber) {
    if (_selectedBracket == 'FINALS') {
      return 'CHUNG KẾT';
    }
    
    if (_selectedBracket.startsWith('LB')) {
      return 'Vòng $roundNumber';
    }

    if (_totalParticipants <= 0) return 'Vòng $roundNumber';

    // Calculate players after this round
    int playersAfterRound = _totalParticipants ~/ (1 << roundNumber);

    switch (playersAfterRound) {
      case 1:
        return 'CHUNG KẾT';
      case 2:
        return 'BÁN KẾT';
      case 4:
        return 'TỨ KẾT';
      case 8:
        return 'VÒNG 1/8';
      case 16:
        return 'VÒNG 1/16';
      default:
        return 'VÒNG $roundNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshData,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.sp),
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.sp),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 16.sp),
            if (_isLoading)
              _buildLoadingState()
            else if (_matches.isEmpty)
              _buildEmptyState()
            else
              _buildBracketContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_tree, color: AppTheme.primaryLight, size: 24.sp),
            SizedBox(width: 8.sp),
            Text(
              'Bảng đấu',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            const Spacer(),
            if (_matches.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
                decoration: BoxDecoration(
                  color: _getStatusColor(_tournamentStatus).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.sp),
                ),
                child: Text(
                  _getStatusText(_tournamentStatus),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(_tournamentStatus),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12.sp),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _bracketNames.entries.map((entry) {
              final isSelected = _selectedBracket == entry.key;
              // Only show brackets that have matches
              final hasMatches = _matches.any((m) => m['bracket_type'] == entry.key);
              if (!hasMatches && entry.key != 'WB') return const SizedBox.shrink();

              return Padding(
                padding: EdgeInsets.only(right: 8.sp),
                child: InkWell(
                  onTap: () => setState(() => _selectedBracket = entry.key),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryLight : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20.sp),
                    ),
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 300.sp,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 300.sp,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree, size: 48.sp, color: Colors.grey[400]),
          SizedBox(height: 16.sp),
          Text(
            'Chưa có bảng đấu',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            'Bảng đấu sẽ được tạo khi giải đấu bắt đầu',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBracketContent() {
    // Filter matches by selected bracket
    final filteredMatches = _matches.where((m) => 
      (m['bracket_type'] ?? 'WB') == _selectedBracket
    ).toList();

    if (filteredMatches.isEmpty) {
      return SizedBox(
        height: 200.sp,
        child: Center(
          child: Text(
            'Chưa có trận đấu nào ở nhánh này',
            style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
          ),
        ),
      );
    }

    // Group matches by round
    Map<int, List<Map<String, dynamic>>> matchesByRound = {};
    for (var match in filteredMatches) {
      int round = match['round_number'];
      if (!matchesByRound.containsKey(round)) {
        matchesByRound[round] = [];
      }
      matchesByRound[round]!.add(match);
    }

    // Sort rounds
    var sortedRounds = matchesByRound.keys.toList()..sort();

    return PinchToZoomWidget(
      minScale: 0.5,
      maxScale: 3.0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedRounds.map((round) {
            return _buildRoundColumn(round, matchesByRound[round]!);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoundColumn(
    int roundNumber,
    List<Map<String, dynamic>> matches,
  ) {
    return Container(
      width: 250.sp,
      margin: EdgeInsets.only(right: 16.sp),
      child: Column(
        children: [
          // Round header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.primaryLight.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: Text(
              _getRoundDisplayName(roundNumber),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 12.sp),

          // Matches in this round
          ...matches.map((match) => _buildMatchCard(match)),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    String status = match['status'] ?? 'pending';
    String player1Name = match['player1_name'] ?? 'TBD';
    String player2Name = match['player2_name'] ?? 'TBD';
    int player1Score = match['player1_score'] ?? 0;
    int player2Score = match['player2_score'] ?? 0;
    String? winnerId = match['winner_id'];

    bool player1Won = winnerId == match['player1_id'];
    bool player2Won = winnerId == match['player2_id'];

    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: _getMatchStatusBorderColor(status), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Player 1
          Container(
            padding: EdgeInsets.all(12.sp),
            decoration: BoxDecoration(
              color: player1Won
                  ? AppTheme.primaryLight.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(6.sp)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 32.sp,
                  height: 32.sp,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.sp),
                    border: Border.all(
                      color: player1Won
                          ? AppTheme.primaryLight
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.sp),
                    child: match['player1_avatar'] != null
                        ? Image.network(
                            match['player1_avatar'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.person, size: 16.sp),
                          )
                        : Icon(
                            Icons.person,
                            size: 16.sp,
                            color: Colors.grey[500],
                          ),
                  ),
                ),
                SizedBox(width: 8.sp),

                // Name and rank
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player1Name,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: player1Won
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: player1Won
                              ? AppTheme.primaryLight
                              : AppTheme.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (match['player1_rank'] != null &&
                          match['player1_rank'].toString().isNotEmpty)
                        Text(
                          RankMigrationHelper.getNewDisplayName(
                            match['player1_rank'],
                          ),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // Score
                if (status == 'completed' || status == 'live')
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.sp,
                      vertical: 2.sp,
                    ),
                    decoration: BoxDecoration(
                      color: player1Won
                          ? AppTheme.primaryLight
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4.sp),
                    ),
                    child: Text(
                      '$player1Score',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: player1Won ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),

                if (player1Won)
                  Container(
                    margin: EdgeInsets.only(left: 4.sp),
                    child: Icon(
                      Icons.emoji_events,
                      color: AppTheme.primaryLight,
                      size: 16.sp,
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: Colors.grey[200]),

          // Player 2
          Container(
            padding: EdgeInsets.all(12.sp),
            decoration: BoxDecoration(
              color: player2Won
                  ? AppTheme.primaryLight.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(6.sp),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 32.sp,
                  height: 32.sp,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.sp),
                    border: Border.all(
                      color: player2Won
                          ? AppTheme.primaryLight
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.sp),
                    child: match['player2_avatar'] != null
                        ? Image.network(
                            match['player2_avatar'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.person, size: 16.sp),
                          )
                        : Icon(
                            Icons.person,
                            size: 16.sp,
                            color: Colors.grey[500],
                          ),
                  ),
                ),
                SizedBox(width: 8.sp),

                // Name and rank
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player2Name,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: player2Won
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: player2Won
                              ? AppTheme.primaryLight
                              : AppTheme.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (match['player2_rank'] != null &&
                          match['player2_rank'].toString().isNotEmpty)
                        Text(
                          RankMigrationHelper.getNewDisplayName(
                            match['player2_rank'],
                          ),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // Score
                if (status == 'completed' || status == 'live')
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.sp,
                      vertical: 2.sp,
                    ),
                    decoration: BoxDecoration(
                      color: player2Won
                          ? AppTheme.primaryLight
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4.sp),
                    ),
                    child: Text(
                      '$player2Score',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: player2Won ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),

                if (player2Won)
                  Container(
                    margin: EdgeInsets.only(left: 4.sp),
                    child: Icon(
                      Icons.emoji_events,
                      color: AppTheme.primaryLight,
                      size: 16.sp,
                    ),
                  ),
              ],
            ),
          ),

          // Status indicator for live matches
          if (status == 'live')
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 6.sp),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(6.sp),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8.sp,
                    height: 8.sp,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4.sp),
                    ),
                  ),
                  SizedBox(width: 6.sp),
                  Text(
                    'ĐANG DIỄN RA',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'ongoing':
        return 'ĐANG DIỄN RA';
      case 'completed':
        return 'ĐÃ KẾT THÚC';
      case 'cancelled':
        return 'ĐÃ HỦY';
      default:
        return 'CHUẨN BỊ';
    }
  }

  Color _getMatchStatusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return Colors.red;
      case 'completed':
        return AppTheme.primaryLight;
      case 'pending':
        return Colors.grey[300]!;
      default:
        return Colors.grey[300]!;
    }
  }
}
