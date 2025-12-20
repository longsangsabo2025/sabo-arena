import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

// 🎯 SABO DE64 Tournament Bracket - 4 Groups + Cross Finals
class SaboDE64Bracket extends StatefulWidget {
  final List<Map<String, dynamic>> matches;
  final VoidCallback? onMatchTap;

  const SaboDE64Bracket({super.key, required this.matches, this.onMatchTap});

  @override
  State<SaboDE64Bracket> createState() => _SaboDE64BracketState();
}

class _SaboDE64BracketState extends State<SaboDE64Bracket>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 5 tabs: Group A, Group B, Group C, Group D, Cross Finals
    _tabController = TabController(length: 5, vsync: this);
    _pageController = PageController();

    // Debug: Check bracket_group distribution
    final groupCounts = <String, int>{};
    for (final match in widget.matches) {
      final group = match['bracket_group'] as String? ?? 'null';
      groupCounts[group] = (groupCounts[group] ?? 0) + 1;
    }
    ProductionLogger.info('📊 SABO DE64 bracket_group distribution:',
        tag: 'sabo_de64_bracket');
    groupCounts.forEach((group, count) {
      ProductionLogger.info('   $group: $count matches',
          tag: 'sabo_de64_bracket');
    });

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

  // Group matches by bracket_group
  List<Map<String, dynamic>> _getMatchesByGroup(String group) {
    final filtered = widget.matches.where((m) {
      final bracketGroup = m['bracket_group'] as String?;

      // Handle Cross Finals - match both 'Cross' and matches not in A,B,C,D
      if (group == 'Cross') {
        return bracketGroup?.toUpperCase() == 'CROSS' ||
            bracketGroup?.toLowerCase() == 'cross' ||
            (bracketGroup != 'A' &&
                bracketGroup != 'B' &&
                bracketGroup != 'C' &&
                bracketGroup != 'D');
      }

      return bracketGroup == group;
    }).toList();

    ProductionLogger.info(
        '🔍 SABO DE64: Filtering group=$group, found ${filtered.length} matches',
        tag: 'sabo_de64_bracket');

    return filtered;
  }

  // Get matches by bracket type within a group
  /* List<Map<String, dynamic>> _getMatchesByTypeInGroup(
    String group,
    String type,
  ) {
    final groupMatches = _getMatchesByGroup(group);
    final filtered = groupMatches.where((m) {
      final bracketType = m['bracket_type'] as String?;
      if (type == 'WB') {
        return bracketType == 'WB';
      } else if (type == 'LB') {
        return bracketType == 'LB';
      } else if (type == 'LB-B') {
        return bracketType == 'LB-B';
      }
      return false;
    }).toList();

    return filtered;
  } */

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Material(
          color: Colors.transparent,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Group A'),
              Tab(text: 'Group B'),
              Tab(text: 'Group C'),
              Tab(text: 'Group D'),
              Tab(text: 'Cross Finals'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Content
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              _tabController.animateTo(index);
            },
            children: [
              _buildGroupView('A'),
              _buildGroupView('B'),
              _buildGroupView('C'),
              _buildGroupView('D'),
              _buildCrossFinalsView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupView(String group) {
    final groupMatches = _getMatchesByGroup(group);

    // Separate by bracket type: WB, LB-A, LB-B
    final wbMatches =
        groupMatches.where((m) => m['bracket_type'] == 'WB').toList();
    final lbAMatches =
        groupMatches.where((m) => m['bracket_type'] == 'LB-A').toList();
    final lbBMatches =
        groupMatches.where((m) => m['bracket_type'] == 'LB-B').toList();

    return Column(
      children: [
        // Group header (minimal)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                'Group $group',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'WB: ${wbMatches.length} • LB-A: ${lbAMatches.length} • LB-B: ${lbBMatches.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Sub-tabs for WB, LB-A, LB-B
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.indigo,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.indigo,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events, size: 14),
                          const SizedBox(width: 4),
                          Text('Winner (${wbMatches.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.redo, size: 14),
                          const SizedBox(width: 4),
                          Text('LB-A (${lbAMatches.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.redo, size: 14),
                          const SizedBox(width: 4),
                          Text('LB-B (${lbBMatches.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildBracketTreeView(wbMatches, Colors.green, group),
                      _buildBracketTreeView(lbAMatches, Colors.orange, group),
                      _buildBracketTreeView(lbBMatches, Colors.red, group),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build bracket tree view with horizontal scroll
  Widget _buildBracketTreeView(
      List<Map<String, dynamic>> matches, Color color, String group) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có trận đấu',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: _buildBracketTree(matches, color, group),
      ),
    );
  }

  Widget _buildCrossFinalsView() {
    // Get all matches that are not in groups A, B, C, D
    final crossMatches = widget.matches.where((m) {
      final bracketGroup = m['bracket_group'] as String?;
      // Include matches with 'Cross' or any value not A,B,C,D
      return bracketGroup?.toUpperCase() == 'CROSS' ||
          bracketGroup?.toLowerCase() == 'cross' ||
          (bracketGroup != 'A' &&
              bracketGroup != 'B' &&
              bracketGroup != 'C' &&
              bracketGroup != 'D');
    }).toList();

    ProductionLogger.info(
        '🔍 Cross Finals: Found ${crossMatches.length} matches',
        tag: 'sabo_de64_bracket');
    if (crossMatches.isNotEmpty) {
      final sampleGroup = crossMatches.first['bracket_group'];
      ProductionLogger.info('   Sample bracket_group: $sampleGroup',
          tag: 'sabo_de64_bracket');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cross Finals',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${crossMatches.length} matches',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Bracket Tree - Horizontal scroll with Expanded
        if (crossMatches.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: _buildBracketTree(crossMatches, Colors.purple, 'Cross'),
              ),
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có trận đấu chung kết',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Build bracket tree structure (horizontal scroll with rounds)
  Widget _buildBracketTree(
      List<Map<String, dynamic>> matches, Color color, String group) {
    // Group matches by round_number
    final rounds = <int, List<Map<String, dynamic>>>{};
    for (var match in matches) {
      final round =
          match['round_number'] as int? ?? match['stage_round'] as int? ?? 1;
      rounds[round] = [...(rounds[round] ?? []), match];
    }

    // Sort rounds by key (ascending order)
    final sortedEntries = rounds.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sortedEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Chưa có trận đấu',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ),
      );
    }

    // Find the last round (final match of this bracket)
    final lastRound = sortedEntries.last.key;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: sortedEntries.map((entry) {
        final isLastRound = entry.key == lastRound;
        return _buildRoundColumn(
          'R${entry.key}',
          entry.value,
          color,
          isLastRound, // Highlight last round winner
        );
      }).toList(),
    );
  }

  // Build a single round column
  Widget _buildRoundColumn(
    String title,
    List<Map<String, dynamic>> matches,
    Color color,
    bool isLastRound, // Highlight winner in last round
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Round title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color is MaterialColor ? color.shade700 : color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Matches in this round
          ...matches.map((match) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCompactMatchCard(match, color, isLastRound),
              )),
        ],
      ),
    );
  }

  // Compact match card for bracket tree
  Widget _buildCompactMatchCard(
    Map<String, dynamic> match,
    Color color,
    bool highlightWinner, // Highlight winner if this is last round
  ) {
    final status = match['status'] as String? ?? 'pending';
    final player1 = match['player1'] as Map<String, dynamic>?;
    final player2 = match['player2'] as Map<String, dynamic>?;
    final player1Name =
        player1?['name'] as String? ?? player1?['username'] as String? ?? 'TBD';
    final player2Name =
        player2?['name'] as String? ?? player2?['username'] as String? ?? 'TBD';
    final player1Score = match['player1_score'] as int? ?? 0;
    final player2Score = match['player2_score'] as int? ?? 0;
    final winnerId = match['winner_id'] as String?;
    final player1Id = player1?['id'] as String?;
    final player2Id = player2?['id'] as String?;

    final isPlayer1Winner = winnerId != null && winnerId == player1Id;
    final isPlayer2Winner = winnerId != null && winnerId == player2Id;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlightWinner && status == 'completed'
              ? Colors.purple // Purple border for last round winner
              : status == 'completed'
                  ? color.withValues(alpha: 0.5)
                  : Colors.grey.shade300,
          width: highlightWinner && status == 'completed'
              ? 3
              : status == 'completed'
                  ? 2
                  : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: highlightWinner && status == 'completed'
                ? Colors.purple.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: highlightWinner && status == 'completed' ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Player 1
          _buildPlayerRow(
            player1Name,
            player1Score,
            isPlayer1Winner,
            color,
            highlightWinner &&
                isPlayer1Winner, // Extra highlight for Cross Finals qualifier
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          // Player 2
          _buildPlayerRow(
            player2Name,
            player2Score,
            isPlayer2Winner,
            color,
            highlightWinner &&
                isPlayer2Winner, // Extra highlight for Cross Finals qualifier
          ),
        ],
      ),
    );
  }

  // Build player row for compact match card
  Widget _buildPlayerRow(
    String name,
    int score,
    bool isWinner,
    Color color,
    bool extraHighlight, // Purple highlight for Cross Finals qualifier
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: extraHighlight
          ? Colors.purple
              .withValues(alpha: 0.2) // Purple background for qualifier
          : isWinner
              ? color.withValues(alpha: 0.1)
              : Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (extraHighlight) ...[
                  Icon(Icons.stars, size: 16, color: Colors.purple),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: extraHighlight || isWinner
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: extraHighlight
                          ? Colors.purple
                          : isWinner
                              ? color
                              : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: extraHighlight
                  ? Colors.purple
                  : isWinner
                      ? color
                      : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    extraHighlight || isWinner ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* Widget _buildBracketSection(
    String title,
    List<Map<String, dynamic>> matches,
    Color color,
  ) {
    // Group by round
    final Map<int, List<Map<String, dynamic>>> roundGroups = {};
    for (final match in matches) {
      final round = match['round_number'] as int? ?? 0;
      roundGroups.putIfAbsent(round, () => []);
      roundGroups[round]!.add(match);
    }

    final sortedRounds = roundGroups.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              '${matches.length} matches',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rounds
        ...sortedRounds.map((round) {
          final roundMatches = roundGroups[round]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round $round',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...roundMatches.map((match) => _buildMatchCard(match, color)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, Color color) {
    final status = match['status'] as String? ?? 'pending';
    final player1 = match['player1'] as Map<String, dynamic>?;
    final player2 = match['player2'] as Map<String, dynamic>?;
    final player1Name = player1?['display_name'] as String? ?? 
                        player1?['full_name'] as String? ?? 
                        player1?['username'] as String? ?? 'TBD';
    // ... (rest of the method)
    return Container(); // Placeholder for commented out code
  }
    final player2Name = player2?['display_name'] as String? ?? 
                        player2?['full_name'] as String? ?? 
                        player2?['username'] as String? ?? 'TBD';
    final player1Score = match['player1_score'] as int? ?? 0;
    final player2Score = match['player2_score'] as int? ?? 0;
    final matchNumber = match['match_number'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: widget.onMatchTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Match Number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#$matchNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Players
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(player1Name)),
                        Text(
                          '$player1Score',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: Text(player2Name)),
                        Text(
                          '$player2Score',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status
              const SizedBox(width: 12),
              _buildStatusBadge(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String badgeText;

    switch (status.toLowerCase()) {
      case 'completed':
        badgeColor = Colors.green;
        badgeText = 'Hoàn thành';
        break;
      case 'in_progress':
        badgeColor = Colors.blue;
        badgeText = 'Đang đấu';
        break;
      case 'pending':
      default:
        badgeColor = Colors.grey;
        badgeText = 'Chờ đấu';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  } */
}
