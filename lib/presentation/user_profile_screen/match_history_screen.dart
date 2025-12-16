import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/match_management_service.dart';
import '../../widgets/user/user_widgets.dart';
import 'widgets/score_input_dialog.dart';

/// Screen hiển thị lịch sử tất cả trận đấu của user
class MatchHistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const MatchHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _matchManagementService = MatchManagementService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _matches = [];
  String? _errorMessage;
  late TabController _tabController;

  // Stats
  int _totalMatches = 0;
  int _wins = 0;
  int _losses = 0;
  int _draws = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all matches where user is player1 or player2
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            player1:player1_id(id, display_name, avatar_url),
            player2:player2_id(id, display_name, avatar_url)
          ''')
          .or('player1_id.eq.${widget.userId},player2_id.eq.${widget.userId}')
          .order('match_date', ascending: false);

      final allMatches = List<Map<String, dynamic>>.from(response);

      // Calculate stats
      _totalMatches = allMatches.length;
      _wins = 0;
      _losses = 0;
      _draws = 0;

      for (final match in allMatches) {
        final winnerId = match['winner_id'] as String?;
        if (winnerId == null) {
          _draws++;
        } else if (winnerId == widget.userId) {
          _wins++;
        } else {
          _losses++;
        }
      }

      setState(() {
        _matches = allMatches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải lịch sử trận đấu: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredMatches() {
    switch (_tabController.index) {
      case 0: // All
        return _matches;
      case 1: // Wins
        return _matches
            .where((m) => m['winner_id'] == widget.userId)
            .toList();
      case 2: // Losses
        return _matches
            .where((m) =>
                m['winner_id'] != null && m['winner_id'] != widget.userId)
            .toList();
      case 3: // Draws
        return _matches.where((m) => m['winner_id'] == null).toList();
      default:
        return _matches;
    }
  }

  /// Show score input dialog for club owner
  Future<void> _showScoreInputDialog(Map<String, dynamic> match) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScoreInputDialog(match: match),
    );

    if (result != null && mounted) {
      final player1Score = result['player1Score'] as int;
      final player2Score = result['player2Score'] as int;
      final winnerId = result['winnerId'] as String?;

      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Complete match with scores
        await _matchManagementService.completeMatch(
          matchId: match['id'],
          winnerId: winnerId ?? match['player1_id'], // Fallback to player1 if draw
          finalPlayer1Score: player1Score,
          finalPlayer2Score: player2Score,
        );

        // Close loading
        if (mounted) Navigator.pop(context);

        // Reload matches
        await _loadMatches();

        // Show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã cập nhật tỷ số: $player1Score-$player2Score'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Close loading
        if (mounted) Navigator.pop(context);

        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi cập nhật: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử trận đấu', overflow: TextOverflow.ellipsis, style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.userName, style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        bottom: _isLoading
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(120),
                child: Column(
                  children: [
                    // Stats summary
                    _buildStatsBar(),
                    // Tabs
                    TabBar(
                      controller: _tabController,
                      onTap: (index) => setState(() {}),
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(text: 'Tất cả ($_totalMatches)'),
                        Tab(text: 'Thắng ($_wins)'),
                        Tab(text: 'Thua ($_losses)'),
                        Tab(text: 'Hòa ($_draws)'),
                      ],
                    ),
                  ],
                ),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center, style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMatches,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _matches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_esports,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có trận đấu nào', overflow: TextOverflow.ellipsis, style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMatches,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _getFilteredMatches().length,
                        itemBuilder: (context, index) {
                          final match = _getFilteredMatches()[index];
                          return _buildMatchCard(match);
                        },
                      ),
                    ),
    );
  }

  Widget _buildStatsBar() {
    final winRate =
        _totalMatches > 0 ? ((_wins / _totalMatches) * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Tỉ lệ thắng',
            value: '$winRate%',
            color: Colors.greenAccent,
          ),
          Container(width: 1, height: 30, color: Colors.white30),
          _buildStatItem(
            label: 'Thắng',
            value: _wins.toString(),
            color: Colors.green,
          ),
          Container(width: 1, height: 30, color: Colors.white30),
          _buildStatItem(
            label: 'Thua',
            value: _losses.toString(),
            color: Colors.red,
          ),
          Container(width: 1, height: 30, color: Colors.white30),
          _buildStatItem(
            label: 'Hòa',
            value: _draws.toString(),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value, style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label, style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final player1 = match['player1'] as Map<String, dynamic>?;
    final player2 = match['player2'] as Map<String, dynamic>?;
    final winnerId = match['winner_id'] as String?;
    final matchDate = DateTime.parse(match['match_date'] as String);
    final tournamentId = match['tournament_id'] as String?;
    final player1Score = match['player1_score'] as int? ?? 0;
    final player2Score = match['player2_score'] as int? ?? 0;

    final isPlayer1 = player1?['id'] == widget.userId;
    final userWon = winnerId == widget.userId;
    final isDraw = winnerId == null;

    Color resultColor;
    String resultText;
    IconData resultIcon;

    if (isDraw) {
      resultColor = Colors.orange;
      resultText = 'HÒA';
      resultIcon = Icons.horizontal_rule;
    } else if (userWon) {
      resultColor = Colors.green;
      resultText = 'THẮNG';
      resultIcon = Icons.check_circle;
    } else {
      resultColor = Colors.red;
      resultText = 'THUA';
      resultIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: resultColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: resultColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Result badge + Date
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(resultIcon, color: resultColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  resultText, style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: resultColor,
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(matchDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Match details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Players and scores
                Row(
                  children: [
                    // Player 1
                    Expanded(
                      child: _buildPlayerInfo(
                        player1,
                        isPlayer1,
                        winnerId == player1?['id'],
                      ),
                    ),
                    // Score
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            '$player1Score - $player2Score', overflow: TextOverflow.ellipsis, style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const Text(
                            'VS', overflow: TextOverflow.ellipsis, style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Player 2
                    Expanded(
                      child: _buildPlayerInfo(
                        player2,
                        !isPlayer1,
                        winnerId == player2?['id'],
                      ),
                    ),
                  ],
                ),

                // Tournament info (if from tournament)
                if (tournamentId != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events,
                            size: 16, color: Color(0xFF00695C)),
                        const SizedBox(width: 8),
                        Text(
                          'Từ giải đấu', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(
    Map<String, dynamic>? playerData,
    bool isCurrentUser,
    bool isWinner,
  ) {
    return Column(
      children: [
        Stack(
          children: [
            UserAvatarWidget(
              avatarUrl: playerData?['avatar_url'],
              size: 60,
              showRankBorder: isCurrentUser,
            ),
            if (isWinner)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: UserDisplayNameText(
            userData: playerData,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
              color: isCurrentUser ? const Color(0xFF00695C) : Colors.black87,
            ),
            maxLines: 1,
          ),
        ),
        if (isCurrentUser)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00695C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Bạn', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00695C),
              ),
            ),
          ),
      ],
    );
  }
}
