import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'match_card_widget.dart';
import '../../../services/match_service.dart';
import '../../../services/share_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Matches Section Widget - Hiển thị danh sách trận đấu
/// Design: Tabs Ready/Live/Done + Match cards list
class MatchesSectionWidget extends StatefulWidget {
  final String userId;

  const MatchesSectionWidget({super.key, required this.userId});

  @override
  State<MatchesSectionWidget> createState() => _MatchesSectionWidgetState();
}

class _MatchesSectionWidgetState extends State<MatchesSectionWidget> {
  int _selectedStatusIndex = 0; // 0: Ready, 1: Live, 2: Done
  bool _isLoading = true;
  List<Match> _allMatches = [];
  final MatchService _matchService = MatchService.instance;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      setState(() {
        _isLoading = true;
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Fetch matches from Supabase
      final matches = await _matchService.getUserMatches(
        widget.userId,
        limit: 50,
      );

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Log chi tiết các matches
      for (var match in matches) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      if (mounted) {
        setState(() {
          _allMatches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredMatches = _getFilteredMatches();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Tabs (Ready/Live/Done)
        _buildStatusTabs(),

        // Matches List (shrinkWrap for nested scroll)
        if (filteredMatches.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // Prevent nested scroll
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredMatches.length,
            itemBuilder: (context, index) {
              final match = filteredMatches[index];
              return MatchCardWidget(
                match: match,
                onTap: () {
                  ProductionLogger.debug('Debug log', tag: 'AutoFix');
                },
                onShareTap: () => _shareMatch(match),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatusTab(label: 'Ready', index: 0)),
          Expanded(
            child: _buildStatusTab(label: 'Live', index: 1, showRedDot: true),
          ),
          Expanded(child: _buildStatusTab(label: 'Done', index: 2)),
        ],
      ),
    );
  }

  Widget _buildStatusTab({
    required String label,
    required int index,
    bool showRedDot = false,
  }) {
    final isActive = _selectedStatusIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.black : const Color(0xFF9E9E9E),
              ),
            ),
            if (showRedDot && isActive) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredMatches() {
    String status;
    switch (_selectedStatusIndex) {
      case 0:
        status = 'pending'; // Ready = pending/scheduled
        break;
      case 1:
        status = 'in_progress'; // Live = in_progress
        break;
      case 2:
        status = 'completed'; // Done = completed
        break;
      default:
        status = 'pending';
    }

    // Filter real matches from Supabase
    final filtered = _allMatches
        .where((match) => match.status == status)
        .toList();

    // Convert Match objects to Map format for MatchCardWidget
    return filtered.map((match) => _convertMatchToCardData(match)).toList();
  }

  Map<String, dynamic> _convertMatchToCardData(Match match) {
    // Determine if current user is player1 or player2
    final isPlayer1 = match.player1Id == widget.userId;

    // Get player data based on position
    final currentUserName = isPlayer1 ? match.player1Name : match.player2Name;
    final currentUserRank = isPlayer1 ? match.player1Rank : match.player2Rank;
    final currentUserAvatar = isPlayer1
        ? match.player1Avatar
        : match.player2Avatar;

    final opponentName = isPlayer1 ? match.player2Name : match.player1Name;
    final opponentRank = isPlayer1 ? match.player2Rank : match.player1Rank;
    final opponentAvatar = isPlayer1
        ? match.player2Avatar
        : match.player1Avatar;

    // Get scores
    final currentUserScore = isPlayer1
        ? match.player1Score
        : match.player2Score;
    final opponentScore = isPlayer1 ? match.player2Score : match.player1Score;

    // Format date and time
    String dateStr = '';
    String timeStr = '';
    if (match.scheduledTime != null) {
      final date = match.scheduledTime!;
      final formatter = DateFormat('EEE - dd/MM');
      dateStr = formatter.format(date);
      timeStr = DateFormat('HH:mm').format(date);
    }

    // Determine status for card
    String cardStatus;
    if (match.status == 'pending' || match.status == 'scheduled') {
      cardStatus = 'ready';
    } else if (match.status == 'in_progress') {
      cardStatus = 'live';
    } else if (match.status == 'completed') {
      cardStatus = 'done';
    } else {
      cardStatus = 'ready';
    }

    return {
      'id': match.id,
      // Opponent data (shown on left)
      'player1Name': opponentName ?? 'Unknown',
      'player1Rank': opponentRank ?? 'H',
      'player1Avatar': opponentAvatar,
      'player1Online': false, // TODO: Fetch real online status from presence
      // Current user data (shown on right)
      'player2Name': currentUserName ?? 'You',
      'player2Rank': currentUserRank ?? 'H',
      'player2Avatar': currentUserAvatar,
      'player2Online': true, // Assume current user is online
      'status': cardStatus,
      'date': dateStr,
      'time': timeStr,
      'score1': opponentScore.toString(),
      'score2': currentUserScore.toString(),
      'handicap': match.notes ?? '',
      'prize': '', // TODO: Fetch from tournament if needed
      'raceInfo': match.tournamentTitle ?? 'Match ${match.matchNumber}',
      'currentTable': 'Round ${match.roundNumber}',
    };
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedStatusIndex) {
      case 0:
        message = 'Chưa có trận đấu sắp diễn ra';
        icon = Icons.schedule;
        break;
      case 1:
        message = 'Không có trận đấu đang diễn ra';
        icon = Icons.sports_esports;
        break;
      case 2:
        message = 'Chưa có lịch sử trận đấu';
        icon = Icons.history;
        break;
      default:
        message = 'Không có dữ liệu';
        icon = Icons.info_outline;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFBDBDBD)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tham gia tournament để bắt đầu!',
            style: const TextStyle(fontSize: 13, color: Color(0xFFBDBDBD), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Future<void> _shareMatch(Map<String, dynamic> match) async {
    try {
      final player1Name = match['player1Name'] as String? ?? 'Player 1';
      final player2Name = match['player2Name'] as String? ?? 'Player 2';
      final score1 = match['score1'] as String? ?? '?';
      final score2 = match['score2'] as String? ?? '?';
      final score = '$score1 - $score2';
      final winner = score1 != '?' && score2 != '?' 
        ? (int.tryParse(score1) ?? 0) > (int.tryParse(score2) ?? 0) 
          ? player1Name 
          : player2Name
        : 'TBD';
      final date = match['date'] as String? ?? '';
      final matchId = match['id'] as String?;
      
      await ShareService.shareMatchResult(
        player1Name: player1Name,
        player2Name: player2Name,
        score: score,
        winner: winner,
        matchDate: date,
        matchId: matchId,
      );
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }
}

