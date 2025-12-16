import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/bracket/formats/sabo_de24_format.dart';
import '../../../core/design_system/design_system.dart';
import 'demo_bracket/formats/sabo_de16_bracket.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// 📊 DE24 Group Stage Display Widget
/// Shows 8 groups with standings and match results
class DE24GroupStageWidget extends StatefulWidget {
  final String tournamentId;

  const DE24GroupStageWidget({
    Key? key,
    required this.tournamentId,
  }) : super(key: key);

  @override
  State<DE24GroupStageWidget> createState() => _DE24GroupStageWidgetState();
}

class _DE24GroupStageWidgetState extends State<DE24GroupStageWidget>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isAdvancing = false;
  Map<String, List<Map<String, dynamic>>> _groupStandings = {};
  Map<String, List<Map<String, dynamic>>> _groupMatches = {};
  List<Map<String, dynamic>> _de16Matches = []; // DE16 main stage matches
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _areAllGroupsCompleted() {
    // Check if all 8 groups have all 3 matches completed
    if (_groupMatches.length != 8) return false;
    
    for (final matches in _groupMatches.values) {
      if (matches.length != 3) return false;
      if (matches.any((m) => m['status'] != 'completed')) return false;
    }
    return true;
  }

  Future<void> _advanceToDE16() async {
    if (!_areAllGroupsCompleted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Tất cả trận vòng bảng phải hoàn thành trước!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isAdvancing = true);

    try {
      final service = HardcodedSaboDE24Service(_supabase);
      await service.advanceGroupWinnersToMainStage(widget.tournamentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Đã chuyển 16 người vào vòng chính DE16!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Reload to show updated data
        await _loadGroupData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdvancing = false);
      }
    }
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);

    try {
      // Load all matches for this tournament
      final allMatches = await _supabase
          .from('matches')
          .select('*, player1:users!player1_id(*), player2:users!player2_id(*)')
          .eq('tournament_id', widget.tournamentId)
          .order('display_order');

      // Separate group stage and DE16 matches
      final groupMatches = <Map<String, dynamic>>[];
      final de16Matches = <Map<String, dynamic>>[];

      ProductionLogger.info('🔍 Total matches loaded: ${allMatches.length}', tag: 'de24_group_stage_widget');
      for (final match in allMatches) {
        final bracketType = match['bracket_type'] as String?;
        ProductionLogger.info('  Match ${match['match_number']}: bracket_type=$bracketType, round=${match['round']}', tag: 'de24_group_stage_widget');
        if (bracketType == 'groups') {
          groupMatches.add(match);
        } else {
          // WB, LB-A, LB-B, SABO
          de16Matches.add(match);
        }
      }
      ProductionLogger.info('📊 Group matches: ${groupMatches.length}, DE16 matches: ${de16Matches.length}', tag: 'de24_group_stage_widget');

      // Organize group matches by group
      final groupedMatches = <String, List<Map<String, dynamic>>>{};
      for (final match in groupMatches) {
        final round = (match['round'] ?? '') as String;
        final group = round.replaceAll('Group ', '').trim();
        if (group.isNotEmpty) {
          groupedMatches.putIfAbsent(group, () => []).add(match);
        }
      }

      // Calculate standings for each group
      final standings = <String, List<Map<String, dynamic>>>{};
      for (final entry in groupedMatches.entries) {
        standings[entry.key] = _calculateGroupStandings(entry.value);
      }

      setState(() {
        _groupMatches = groupedMatches;
        _groupStandings = standings;
        _de16Matches = de16Matches;
        _isLoading = false;
      });
    } catch (e) {
      ProductionLogger.info('Error loading group data: $e', tag: 'de24_group_stage_widget');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _calculateGroupStandings(List<Map<String, dynamic>> matches) {
    final playerStats = <String, Map<String, dynamic>>{};

    for (final match in matches) {
      if (match['status'] != 'completed') continue;

      final player1Id = match['player1_id'] as String;
      final player2Id = match['player2_id'] as String;
      final winnerId = match['winner_id'] as String?;
      final player1Score = (match['player1_score'] ?? 0) as int;
      final player2Score = (match['player2_score'] ?? 0) as int;

      // Initialize stats with score tracking
      for (final playerId in [player1Id, player2Id]) {
        playerStats.putIfAbsent(playerId, () => {
          'player_id': playerId,
          'player': match['player1_id'] == playerId ? match['player1'] : match['player2'],
          'wins': 0,
          'losses': 0,
          'points': 0,
          'score_for': 0,
          'score_against': 0,
          'score_diff': 0,
        });
      }

      // Update scores
      playerStats[player1Id]!['score_for'] += player1Score;
      playerStats[player1Id]!['score_against'] += player2Score;
      playerStats[player2Id]!['score_for'] += player2Score;
      playerStats[player2Id]!['score_against'] += player1Score;

      // Update wins/losses
      if (winnerId == player1Id) {
        playerStats[player1Id]!['wins'] += 1;
        playerStats[player1Id]!['points'] += 3;
        playerStats[player2Id]!['losses'] += 1;
      } else if (winnerId == player2Id) {
        playerStats[player2Id]!['wins'] += 1;
        playerStats[player2Id]!['points'] += 3;
        playerStats[player1Id]!['losses'] += 1;
      }
    }

    // Calculate score difference
    for (final stats in playerStats.values) {
      stats['score_diff'] = stats['score_for'] - stats['score_against'];
    }

    // Sort by: 1) points, 2) score difference, 3) score_for
    final sorted = playerStats.values.toList()
      ..sort((a, b) {
        // Primary: Points
        final pointsDiff = (b['points'] as int).compareTo(a['points'] as int);
        if (pointsDiff != 0) return pointsDiff;
        
        // Secondary: Score difference (hiệu số)
        final scoreDiff = (b['score_diff'] as int).compareTo(a['score_diff'] as int);
        if (scoreDiff != 0) return scoreDiff;
        
        // Tertiary: Total score for
        return (b['score_for'] as int).compareTo(a['score_for'] as int);
      });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final groups = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    return Column(
      children: [
        // Tab Bar
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(
              icon: Icon(Icons.groups),
              text: 'Vòng Bảng (${_groupMatches.length}/8)',
            ),
            Tab(
              icon: Icon(Icons.emoji_events),
              text: 'DE16 (${_de16Matches.where((m) => m['player1_id'] != null).length}/${_de16Matches.length})',
            ),
          ],
        ),
        
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Group Stage
              _buildGroupStageTab(groups),
              
              // Tab 2: DE16 Main Stage
              _buildDE16Tab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupStageTab(List<String> groups) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '📊 Group Stage - Vòng Loại',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '8 bảng × 3 người • Top 2 mỗi bảng vào vòng trong',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Groups Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _buildGroupCard(group);
            },
          ),

          const SizedBox(height: 24),

          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildDE16Tab() {
    return Column(
      children: [
        // Main Stage Header
        Container(
          margin: const EdgeInsets.all(16),
          child: _buildMainStageHeader(),
        ),

        // DE16 Bracket Visualization or button
        if (_de16Matches.isNotEmpty) ...[
          Expanded(
            child: SaboDE16Bracket(
              matches: _de16Matches,
              onMatchTap: null,
            ),
          ),
        ] else if (_areAllGroupsCompleted()) ...[
          // Show message if groups done but DE16 not started
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '👆 Vui lòng chuyển sang tab "Vòng Bảng" và click nút "Chuyển 16 người vào DE16"',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ] else ...[
          // Groups not completed yet
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 64,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vòng chính chưa bắt đầu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hoàn thành tất cả 24 trận vòng bảng trước',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainStageHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning700, AppColors.warning],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.textOnPrimary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏆 Main Stage - Vòng Chính (DE16)',
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '16 người từ vòng bảng • Thi đấu loại trực tiếp kép',
                      style: TextStyle(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Show button if all groups completed, otherwise show info message
          _areAllGroupsCompleted()
              ? ElevatedButton.icon(
                  onPressed: _isAdvancing ? null : _advanceToDE16,
                  icon: _isAdvancing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(
                    _isAdvancing ? 'Đang chuyển...' : 'Chuyển 16 người vào DE16',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.textOnPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hoàn thành tất cả trận vòng bảng để chuyển vào DE16',
                          style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(String group) {
    final standings = _groupStandings[group] ?? [];
    final matches = _groupMatches[group] ?? [];

    // Extract players from matches (even if not completed)
    final playersInGroup = <String, Map<String, dynamic>>{};
    for (final match in matches) {
      final player1 = match['player1'];
      final player2 = match['player2'];
      if (player1 != null) {
        playersInGroup[match['player1_id']] = player1;
      }
      if (player2 != null) {
        playersInGroup[match['player2_id']] = player2;
      }
    }

    // Use standings if available, otherwise show players from matches
    final hasData = standings.isNotEmpty || playersInGroup.isNotEmpty;
    final displayList = standings.isNotEmpty 
        ? standings 
        : playersInGroup.values.map((p) => {'player': p, 'points': 0, 'wins': 0, 'losses': 0}).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Group $group',
                    style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_completedMatchCount(matches)}/3',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Standings
            Expanded(
              child: !hasData
                  ? Center(
                      child: Text(
                        'Chưa có dữ liệu',
                        style: TextStyle(color: AppColors.gray400, fontSize: 11),
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final player = displayList[index];
                        final isQualified = standings.isNotEmpty && index < 2;
                        final isEliminated = standings.isNotEmpty && index == 2;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isQualified
                                ? AppColors.success50
                                : isEliminated
                                    ? AppColors.error50
                                    : AppColors.gray50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isQualified
                                  ? AppColors.success
                                  : isEliminated
                                      ? AppColors.error
                                      : AppColors.gray300,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Position
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isQualified ? AppColors.success : AppColors.gray400,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: AppColors.textOnPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Player name
                              Expanded(
                                child: Text(
                                  player['player']?['display_name'] ?? 
                                  player['player']?['full_name'] ?? 
                                  'Unknown',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Record
                              Text(
                                '${player['wins']}-${player['losses']}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(width: 4),

                              // Points
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.info100,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '${player['points']}pt',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.info700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Qualification badge for Top 2
                              if (isQualified) ...[
                                SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success700,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        color: AppColors.textOnPrimary,
                                        size: 10,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'DE16',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: AppColors.textOnPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem(AppColors.success, 'Vào vòng trong', '✅'),
            _buildLegendItem(AppColors.error, 'Bị loại', '❌'),
            _buildLegendItem(AppColors.gray400, 'Chờ kết quả', '⏳'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String icon) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          icon,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  int _completedMatchCount(List<Map<String, dynamic>> matches) {
    return matches.where((m) => m['status'] == 'completed').length;
  }
}
