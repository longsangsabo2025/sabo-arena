import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sabo_arena/utils/production_logger.dart';
import 'match_card_widget.dart';
import '../../../services/match_service.dart';
import '../../../services/share_service.dart';
// ELON_MODE_AUTO_FIX

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


      // Fetch matches from Supabase
      final matches = await _matchService.getUserMatches(
        widget.userId,
        limit: 50,
      );


      // Log chi tiết các matches
      for (final _ in matches) {
      }

      if (mounted) {
        setState(() {
          _allMatches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
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
                matchObj: match,
                onTap: () {
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
          Expanded(child: _buildStatusTab(label: 'Sắp diễn ra', index: 0)),
          Expanded(
            child: _buildStatusTab(label: 'Đang diễn ra', index: 1, showRedDot: true),
          ),
          Expanded(child: _buildStatusTab(label: 'Hoàn thành', index: 2)),
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

  List<Match> _getFilteredMatches() {
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
    return _allMatches.where((match) {
      if (status == 'pending') {
        return match.status == 'pending' || match.status == 'scheduled';
      }
      return match.status == status;
    }).toList();
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

  Future<void> _shareMatch(dynamic matchData) async {
    try {
      String player1Name;
      String player2Name;
      String score1;
      String score2;
      String date;
      String? matchId;

      if (matchData is Match) {
        player1Name = matchData.player1Name ?? 'Player 1';
        player2Name = matchData.player2Name ?? 'Player 2';
        score1 = matchData.player1Score.toString();
        score2 = matchData.player2Score.toString();
        date = matchData.scheduledTime != null 
            ? DateFormat('dd/MM').format(matchData.scheduledTime!) 
            : '';
        matchId = matchData.id;
      } else {
        final match = matchData as Map<String, dynamic>;
        player1Name = match['player1Name'] as String? ?? 'Player 1';
        player2Name = match['player2Name'] as String? ?? 'Player 2';
        score1 = match['score1'] as String? ?? '?';
        score2 = match['score2'] as String? ?? '?';
        date = match['date'] as String? ?? '';
        matchId = match['id'] as String?;
      }

      final score = '$score1 - $score2';
      final winner = score1 != '?' && score2 != '?' 
        ? (int.tryParse(score1) ?? 0) > (int.tryParse(score2) ?? 0) 
          ? player1Name 
          : player2Name
        : 'TBD';
      
      await ShareService.shareMatchResult(
        player1Name: player1Name,
        player2Name: player2Name,
        score: score,
        winner: winner,
        matchDate: date,
        matchId: matchId,
      );
    } catch (e) {
      ProductionLogger.error('Share match result failed', error: e, tag: 'MatchesSectionWidget');
    }
  }
}

