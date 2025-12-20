import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
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
  final MatchService _matchService = MatchService.instance;

  // 3 PagingControllers for 3 tabs
  late final PagingController<int, Match> _readyController;
  late final PagingController<int, Match> _liveController;
  late final PagingController<int, Match> _doneController;

  @override
  void initState() {
    super.initState();
    _readyController = PagingController(firstPageKey: 0);
    _liveController = PagingController(firstPageKey: 0);
    _doneController = PagingController(firstPageKey: 0);

    _readyController.addPageRequestListener(_fetchReadyMatches);
    _liveController.addPageRequestListener(_fetchLiveMatches);
    _doneController.addPageRequestListener(_fetchDoneMatches);
  }

  @override
  void dispose() {
    _readyController.dispose();
    _liveController.dispose();
    _doneController.dispose();
    super.dispose();
  }

  Future<void> _fetchReadyMatches(int pageKey) async {
    await _fetchMatchesPage(pageKey, 'ready', _readyController);
  }

  Future<void> _fetchLiveMatches(int pageKey) async {
    await _fetchMatchesPage(pageKey, 'live', _liveController);
  }

  Future<void> _fetchDoneMatches(int pageKey) async {
    await _fetchMatchesPage(pageKey, 'done', _doneController);
  }

  Future<void> _fetchMatchesPage(
    int pageKey,
    String status,
    PagingController<int, Match> controller,
  ) async {
    try {
      final matches = await _matchService.getUserMatches(
        widget.userId,
        limit: 20,
        offset: pageKey,
      );

      // Filter by status
      final filteredMatches = matches.where((match) {
        if (status == 'ready')
          return match.status == 'scheduled' || match.status == 'ready';
        if (status == 'live')
          return match.status == 'in_progress' || match.status == 'live';
        return match.status == 'completed' || match.status == 'done';
      }).toList();

      final isLastPage = matches.length < 20;
      if (isLastPage) {
        controller.appendLastPage(filteredMatches);
      } else {
        final nextPageKey = pageKey + matches.length;
        controller.appendPage(filteredMatches, nextPageKey);
      }
    } catch (e) {
      controller.error = e;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current controller based on selected tab
    final currentController = _selectedStatusIndex == 0
        ? _readyController
        : _selectedStatusIndex == 1
            ? _liveController
            : _doneController;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Tabs (Ready/Live/Done)
        _buildStatusTabs(),

        // Matches List with PagedListView
        PagedListView<int, Match>(
          pagingController: currentController,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          builderDelegate: PagedChildBuilderDelegate<Match>(
            itemBuilder: (context, match, index) {
              return MatchCardWidget(
                matchObj: match,
                onTap: () {},
                onShareTap: () => _shareMatch(match),
              );
            },
            firstPageProgressIndicatorBuilder: (context) => const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            ),
            newPageProgressIndicatorBuilder: (context) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            firstPageErrorIndicatorBuilder: (context) => _buildEmptyState(),
            noItemsFoundIndicatorBuilder: (context) => _buildEmptyState(),
          ),
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
            child: _buildStatusTab(
                label: 'Đang diễn ra', index: 1, showRedDot: true),
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
        icon = Icons.sports_baseball;
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
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFBDBDBD),
                overflow: TextOverflow.ellipsis),
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
      ProductionLogger.error('Share match result failed',
          error: e, tag: 'MatchesSectionWidget');
    }
  }
}
