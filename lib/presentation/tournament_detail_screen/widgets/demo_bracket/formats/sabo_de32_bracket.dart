import 'package:flutter/material.dart';
// ELON_MODE_AUTO_FIX

// 🎯 SABO DE32 Tournament Bracket - 2 Groups (A + B) + Cross Finals
class SaboDE32Bracket extends StatefulWidget {
  final List<Map<String, dynamic>> matches;
  final VoidCallback? onMatchTap;

  const SaboDE32Bracket({super.key, required this.matches, this.onMatchTap});

  @override
  State<SaboDE32Bracket> createState() => _SaboDE32BracketState();
}

class _SaboDE32BracketState extends State<SaboDE32Bracket>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  
  // 🔒 Cache grouped matches to prevent re-computation on every build
  List<Map<String, dynamic>>? _cachedGroupAMatches;
  List<Map<String, dynamic>>? _cachedGroupBMatches;
  List<Map<String, dynamic>>? _cachedCrossMatches;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
    
    // Initialize cached matches
    _updateCachedMatches();
  }
  
  @override
  void didUpdateWidget(SaboDE32Bracket oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only recompute if matches actually changed
    if (oldWidget.matches != widget.matches) {
      _updateCachedMatches();
    }
  }
  
  void _updateCachedMatches() {
    _cachedGroupAMatches = _getMatchesByGroup('A');
    _cachedGroupBMatches = _getMatchesByGroup('B');
    _cachedCrossMatches = _getMatchesByGroup('CROSS');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Group matches by bracket group
  List<Map<String, dynamic>> _getMatchesByGroup(String group) {
    final filtered = widget.matches.where((m) {
      final bracketGroup = m['bracket_group'] as String?;
      if (group == 'CROSS') {
        // Cross finals: Includes CROSS (6 matches) + GF (1 match) = 7 total
        final bracketType = m['bracket_type'] as String?;
        return bracketType != null &&
            (bracketType == 'CROSS' || 
             bracketType == 'GF' || 
             bracketType == 'FINAL' || 
             bracketType == 'SABO');
      }
      return bracketGroup == group;
    }).toList();

    if (filtered.isEmpty && widget.matches.isNotEmpty) {
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Safe access to matches with error boundary
    if (widget.matches.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Chưa có trận đấu',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // 🔒 Use cached matches - DO NOT recompute on every build!
    final groupAMatches = _cachedGroupAMatches ?? [];
    final groupBMatches = _cachedGroupBMatches ?? [];
    final crossMatches = _cachedCrossMatches ?? [];

    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            onTap: (index) {
              // User tapped tab -> animate to page
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_1, size: 12),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Bảng A (${groupAMatches.length})',
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
                    const Icon(Icons.filter_2, size: 12),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Bảng B (${groupBMatches.length})',
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
                    const Icon(Icons.emoji_events, size: 12),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Chung kết (${crossMatches.length})',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Content
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(), // 🔒 Prevent overscroll rebuild
            onPageChanged: (index) {
              // Simple sync without flag - tabs don't trigger page changes
              _tabController.index = index;
            },
            children: [
              _buildGroupBracket('A', groupAMatches),
              _buildGroupBracket('B', groupBMatches),
              _buildCrossFinals(crossMatches),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupBracket(String group, List<Map<String, dynamic>> matches) {
    if (matches.isEmpty) {
      return Center(
        key: ValueKey('empty_$group'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có trận đấu cho Bảng $group',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // 🎯 LEARN FROM DE64: Use nested DefaultTabController for WB/LB-A/LB-B
    final wbMatches = matches.where((m) => m['bracket_type'] == 'WB').toList();
    final lbAMatches = matches.where((m) => m['bracket_type'] == 'LB-A').toList();
    final lbBMatches = matches.where((m) => m['bracket_type'] == 'LB-B').toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Sub-tabs for bracket types
          TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: [
              Tab(text: '🏆 WB (${wbMatches.length})'),
              Tab(text: '⚔️ LB-A (${lbAMatches.length})'),
              Tab(text: '🔥 LB-B (${lbBMatches.length})'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                _buildBracketTreeView(wbMatches, Colors.green),
                _buildBracketTreeView(lbAMatches, Colors.orange),
                _buildBracketTreeView(lbBMatches, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 🎯 LEARN FROM DE64: Nested SingleChildScrollView pattern
  Widget _buildBracketTreeView(List<Map<String, dynamic>> matches, Color color) {
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
        child: _buildBracketTree(matches, color),
      ),
    );
  }
  
  // 🎯 Build bracket tree (horizontal rounds)
  Widget _buildBracketTree(List<Map<String, dynamic>> matches, Color color) {
    // Group by round_number (as int, like DE64)
    final rounds = <int, List<Map<String, dynamic>>>{};
    for (final match in matches) {
      final roundNumber = match['round_number'] as int? ?? match['stage_round'] as int? ?? 1;
      rounds.putIfAbsent(roundNumber, () => []).add(match);
    }

    // Sort rounds by key (ascending order)
    final sortedEntries = rounds.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: sortedEntries.map((entry) {
        final roundName = 'R${entry.key}';
        return _buildRoundColumn(roundName, entry.value, color);
      }).toList(),
    );
  }
  
  // Build single round column
  Widget _buildRoundColumn(String roundName, List<Map<String, dynamic>> matches, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Round header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              roundName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Matches
          ...matches.map((match) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MatchCard(match: match),
              )),
        ],
      ),
    );
  }
  
  Widget _buildCrossFinals(List<Map<String, dynamic>> matches) {
    if (matches.isEmpty) {
      return Center(
        key: const ValueKey('empty_cross'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có trận chung kết liên bảng',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // 🎯 LEARN FROM DE64: Direct tree view without extra tabs
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
                '🏆 Chung Kết Liên Bảng',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${matches.length} trận đấu',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Bracket tree
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _buildBracketTree(matches, Colors.purple),
            ),
          ),
        ),
      ],
    );
  }
}

// 🔒 MATCH CARD WIDGET
class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  
  const _MatchCard({required this.match});
  
  @override
  Widget build(BuildContext context) {
    final player1 = match['player1'] as Map<String, dynamic>?;
    final player2 = match['player2'] as Map<String, dynamic>?;
    final status = match['status'] as String? ?? 'pending';
    final winner = match['winner_id'] as String?;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status == 'completed' ? Colors.green : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPlayerRow(player1, winner == player1?['id']),
          const Divider(height: 8),
          _buildPlayerRow(player2, winner == player2?['id']),
        ],
      ),
    );
  }
  
  Widget _buildPlayerRow(Map<String, dynamic>? player, bool isWinner) {
    final name = player?['name'] as String? ?? player?['username'] as String? ?? 'TBD';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isWinner ? Colors.green[50] : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          if (isWinner) ...[
            const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

