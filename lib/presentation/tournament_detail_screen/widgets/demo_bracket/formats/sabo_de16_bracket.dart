import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

// 🎯 SABO DE16 Tournament Bracket - Optimized Visualization
class SaboDE16Bracket extends StatefulWidget {
  final List<Map<String, dynamic>> matches;
  final VoidCallback? onMatchTap;

  const SaboDE16Bracket({super.key, required this.matches, this.onMatchTap});

  @override
  State<SaboDE16Bracket> createState() => _SaboDE16BracketState();
}

class _SaboDE16BracketState extends State<SaboDE16Bracket>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();

    // Sync tab and page controller
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Group matches by bracket type
  List<Map<String, dynamic>> _getMatchesByType(String type) {
    final filtered = widget.matches.where((m) {
      final bracketType = m['bracket_type'] as String?;
      if (type == 'WB') {
        return bracketType == 'WB';
      } else if (type == 'LB') {
        // LB includes: LB, LB-A, LB-B, and any other LB variants
        return bracketType != null && bracketType.startsWith('LB');
      } else if (type == 'FINAL') {
        // Finals include: SABO, FINAL, GRAND_FINAL, Finals (for DE24)
        return bracketType == 'SABO' ||
            bracketType == 'FINAL' ||
            bracketType == 'GRAND_FINAL' ||
            bracketType == 'Finals';
      }
      return false;
    }).toList();

    // Debug log
    ProductionLogger.info(
        '🔍 SABO DE16: Filtering type=$type, found ${filtered.length} matches',
        tag: 'sabo_de16_bracket');
    if (filtered.isEmpty && widget.matches.isNotEmpty) {
      ProductionLogger.info(
          '⚠️ Available bracket types: ${widget.matches.map((m) => m['bracket_type']).toSet()}',
          tag: 'sabo_de16_bracket');
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final wbMatches = _getMatchesByType('WB');
    final lbMatches = _getMatchesByType('LB');
    final finalMatches = _getMatchesByType('FINAL');

    return Column(
      children: [
        // Header - Hidden for cleaner UI
        // Container(
        //   padding: const EdgeInsets.all(16),
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //       colors: [Colors.indigo.withValues(alpha: 0.1), Colors.purple.withValues(alpha: 0.1)],
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //     ),
        //     borderRadius: BorderRadius.circular(12),
        //   ),
        //   child: Row(
        //     children: [
        //       Icon(Icons.emoji_events, color: Colors.indigo[700], size: 24),
        //       const SizedBox(width: 12),
        //       Expanded(
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Text(
        //               'SABO Double Elimination 16',
        //               style: TextStyle(
        //                 fontSize: 18,
        //                 fontWeight: FontWeight.bold,
        //                 color: Colors.indigo[700],
        //               ),
        //             ),
        //             Text(
        //               '${widget.matches.length} trận đấu • WB(${wbMatches.length}) LB(${lbMatches.length}) Finals(${finalMatches.length})',
        //               style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),

        // const SizedBox(height: 16),

        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, size: 12),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        'W (${wbMatches.length})',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.redo, size: 12),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        'L (${lbMatches.length})',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 12),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        'F (${finalMatches.length})',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            indicator: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(25),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.indigo,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),

        const SizedBox(height: 16),

        // PageView with bracket content
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              _tabController.animateTo(index);
            },
            children: [
              _buildWinnerBracket(wbMatches),
              _buildLoserBracket(lbMatches),
              _buildFinals(finalMatches),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerBracket(List<Map<String, dynamic>> matches) {
    // Group by round (use round_number from database)
    final rounds = <int, List<Map<String, dynamic>>>{};
    for (var match in matches) {
      final round =
          match['round_number'] as int? ?? match['stage_round'] as int? ?? 1;
      rounds[round] = [...(rounds[round] ?? []), match];
    }

    // Sort rounds by key (ascending order: Round 1, 2, 3...)
    final sortedEntries = rounds.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sortedEntries.map((entry) {
              return _buildRoundColumn(
                'Round ${entry.key}',
                entry.value,
                Colors.green,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoserBracket(List<Map<String, dynamic>> matches) {
    // Group by bracket_type (LB-A, LB-B) then by round
    final lbA = matches.where((m) => m['bracket_type'] == 'LB-A').toList();
    final lbB = matches.where((m) => m['bracket_type'] == 'LB-B').toList();

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lbA.isNotEmpty) ...[
                _buildLoserBranchColumn('LB-A', lbA, Colors.orange),
                const SizedBox(width: 32),
              ],
              if (lbB.isNotEmpty) ...[
                _buildLoserBranchColumn('LB-B', lbB, Colors.red),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoserBranchColumn(
    String title,
    List<Map<String, dynamic>> matches,
    Color color,
  ) {
    // Group by round (use round_number from database)
    final rounds = <int, List<Map<String, dynamic>>>{};
    for (var match in matches) {
      final round =
          match['round_number'] as int? ?? match['stage_round'] as int? ?? 1;
      rounds[round] = [...(rounds[round] ?? []), match];
    }

    // Sort rounds by key (ascending order)
    final sortedEntries = rounds.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Branch Title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color is MaterialColor ? color.shade700 : color,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Rounds sorted
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedEntries.map((entry) {
            return _buildRoundColumn('R${entry.key}', entry.value, color);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFinals(List<Map<String, dynamic>> matches) {
    // Sort by round_number (250, 251, 300)
    final sortedMatches = [...matches]..sort((a, b) {
        final aRound = a['round_number'] as int? ?? 0;
        final bRound = b['round_number'] as int? ?? 0;
        return aRound.compareTo(bRound);
      });

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade700, Colors.orange.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🏆 SABO FINALS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Finals matches in column
                ...sortedMatches.map((match) {
                  final matchNum = match['match_number'] as int? ?? 0;
                  final roundNum = match['round_number'] as int? ?? 0;
                  String title = 'Match $matchNum';
                  if (roundNum == 250) title = 'SABO Semi 1';
                  if (roundNum == 251) title = 'SABO Semi 2';
                  if (roundNum == 300) title = 'GRAND FINAL';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildMatchCard(match, title, Colors.amber.shade700),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundColumn(
    String title,
    List<Map<String, dynamic>> matches,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color is MaterialColor ? color.shade800 : color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Matches
          ...matches.map((match) {
            final matchNum = match['match_number'] as int? ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMatchCard(match, 'M$matchNum', color),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMatchCard(
    Map<String, dynamic> match,
    String label,
    Color color,
  ) {
    final player1 = match['player1'] as Map<String, dynamic>?;
    final player2 = match['player2'] as Map<String, dynamic>?;
    final status = match['status'] as String? ?? 'pending';
    final winnerId = match['winner_id'] as String?;

    return GestureDetector(
      onTap: widget.onMatchTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status == 'completed'
                ? Colors.green.shade300
                : color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match label
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color is MaterialColor ? color.shade800 : color,
                    ),
                  ),
                ),
                const Spacer(),
                if (status == 'completed')
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            // Player 1
            _buildPlayerRow(
              player1?['display_name'] ??
                  player1?['name'] ??
                  player1?['full_name'] ??
                  'TBD',
              winnerId == player1?['id'],
              player1?['score'] as int? ?? match['player1_score'] as int? ?? 0,
            ),
            const Divider(height: 8),
            // Player 2
            _buildPlayerRow(
              player2?['display_name'] ??
                  player2?['name'] ??
                  player2?['full_name'] ??
                  'TBD',
              winnerId == player2?['id'],
              player2?['score'] as int? ?? match['player2_score'] as int? ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow(String name, bool isWinner, int score) {
    return Row(
      children: [
        if (isWinner) ...[
          const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              color: isWinner ? Colors.black : Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (score > 0)
          Text(
            score.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isWinner ? Colors.green : Colors.grey,
            ),
          ),
      ],
    );
  }
}
