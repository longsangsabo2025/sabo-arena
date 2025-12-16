// 🎯 SABO ARENA - Bracket Visualization Service
// Renders real tournament brackets with live participant data and match results
// Converts bracket data into UI-ready components with real-time updates

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../presentation/tournament_detail_screen/widgets/demo_bracket/components/bracket_components.dart';
import '../presentation/tournament_detail_screen/widgets/demo_bracket/formats/sabo_de16_bracket.dart';
import '../presentation/tournament_detail_screen/widgets/demo_bracket/formats/sabo_de32_bracket.dart';
import '../presentation/tournament_detail_screen/widgets/demo_bracket/formats/sabo_de64_bracket.dart';
import '../presentation/tournament_detail_screen/widgets/de24_group_stage_widget.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX
import 'dart:math' as math;

/// Service for rendering tournament brackets with real participant data
class BracketVisualizationService {
  static BracketVisualizationService? _instance;
  static BracketVisualizationService get instance =>
      _instance ??= BracketVisualizationService._();
  BracketVisualizationService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== MAIN VISUALIZATION METHODS ====================

  /// Build complete bracket widget from tournament data
  Future<Widget> buildTournamentBracket({
    required String tournamentId,
    required Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
    bool showLiveUpdates = true,
  }) async {
    try {
      final format = bracketData['format'] ?? 'single_elimination';

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      switch (format.toLowerCase()) {
        case 'single_elimination':
          return await _buildSingleEliminationBracket(
            tournamentId,
            bracketData,
            onMatchTap,
            showLiveUpdates,
          );
        case 'double_elimination':
          return await _buildDoubleEliminationBracket(
            tournamentId,
            bracketData,
            onMatchTap,
            showLiveUpdates,
          );
        case 'sabo_de16':
          // Use dedicated SABO DE16 bracket widget
          return _buildSaboDE16Bracket(bracketData, onMatchTap);
        case 'sabo_de24':
          // Use dedicated SABO DE24 bracket widget (8 groups + DE16)
          return _buildSaboDE24Bracket(bracketData, onMatchTap);
        case 'sabo_de32':
          // Use dedicated SABO DE32 bracket widget (2 groups: A + B)
          return _buildSaboDE32Bracket(bracketData, onMatchTap);
        case 'sabo_de64':
          // Use dedicated SABO DE64 bracket widget (4 groups structure)
          return _buildSaboDE64Bracket(bracketData, onMatchTap);
        case 'round_robin':
          return await _buildRoundRobinBracket(
            tournamentId,
            bracketData,
            onMatchTap,
            showLiveUpdates,
          );
        case 'swiss_system':
        case 'swiss':
          // Swiss System uses similar display to Round Robin (pairings + standings)
          return await _buildSwissSystemBracket(
            tournamentId,
            bracketData,
            onMatchTap,
            showLiveUpdates,
          );
        default:
          return _buildUnsupportedFormatWidget(format);
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return _buildErrorWidget(e.toString());
    }
  }

  // ==================== SINGLE ELIMINATION BRACKET ====================

  Future<Widget> _buildSingleEliminationBracket(
    String tournamentId,
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
    bool showLiveUpdates,
  ) async {
    final matches = bracketData['matches'] as List<dynamic>? ?? [];

    if (matches.isEmpty) {
      return _buildNoMatchesWidget();
    }

    // Convert matches to rounds format like demo bracket
    final rounds = _convertMatchesToRounds(matches);

    if (rounds.isEmpty) {
      return _buildNoMatchesWidget();
    }

    return Container(
      padding: const EdgeInsets.all(4), // Giảm padding tối đa
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bỏ luôn Compact Bracket Header để tiết kiệm không gian
          // _buildCompactBracketHeader(bracketData),
          // const SizedBox(height: 4),

          // Maximized Tournament Bracket Tree (Fill toàn bộ không gian)
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  // Ensure minimum height for proper bracket display
                  constraints: BoxConstraints(
                    minHeight: 300, // Minimum height for bracket visibility
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: EdgeInsets.only(
                      bottom: kBottomNavigationBarHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildRoundsWithConnectors(rounds),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SABO DE16 BRACKET ====================

  Widget _buildSaboDE16Bracket(
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
  ) {
    final matches = bracketData['matches'] as List<dynamic>? ?? [];

    if (matches.isEmpty) {
      return _buildNoMatchesWidget();
    }

    // Convert dynamic list to List<Map<String, dynamic>>
    final matchList = matches.map((m) => m as Map<String, dynamic>).toList();

    return SaboDE16Bracket(matches: matchList, onMatchTap: onMatchTap);
  }

  // ==================== SABO DE24 BRACKET ====================

  Widget _buildSaboDE24Bracket(
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
  ) {
    final tournamentId = bracketData['tournament_id'] as String? ?? '';

    if (tournamentId.isEmpty) {
      return _buildNoMatchesWidget();
    }

    // Use the DE24 group stage widget we created
    return DE24GroupStageWidget(
      tournamentId: tournamentId,
    );
  }

  Widget _buildSaboDE32Bracket(
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
  ) {
    final matches = bracketData['matches'] as List<dynamic>? ?? [];

    if (matches.isEmpty) {
      return _buildNoMatchesWidget();
    }

    // Convert dynamic list to List<Map<String, dynamic>>
    final matchList = matches.map((m) => m as Map<String, dynamic>).toList();

    // Debug: Check if matches have required fields
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    if (matchList.isNotEmpty) {
      final firstMatch = matchList.first;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }

    return SaboDE32Bracket(matches: matchList, onMatchTap: onMatchTap);
  }

  Widget _buildSaboDE64Bracket(
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
  ) {
    final matches = bracketData['matches'] as List<dynamic>? ?? [];

    if (matches.isEmpty) {
      return _buildNoMatchesWidget();
    }

    // Convert dynamic list to List<Map<String, dynamic>>
    final matchList = matches.map((m) => m as Map<String, dynamic>).toList();

    // Debug: Check if matches have required fields
    ProductionLogger.info('🔍 SABO DE64 Bracket Data Check:', tag: 'bracket_visualization_service');
    ProductionLogger.info('   Total matches: ${matchList.length}', tag: 'bracket_visualization_service');
    if (matchList.isNotEmpty) {
      final firstMatch = matchList.first;
      ProductionLogger.info('   Sample match fields: ${firstMatch.keys.toList()}', tag: 'bracket_visualization_service');
      ProductionLogger.info('   bracket_group: ${firstMatch['bracket_group']}', tag: 'bracket_visualization_service');
      ProductionLogger.info('   bracket_type: ${firstMatch['bracket_type']}', tag: 'bracket_visualization_service');
      ProductionLogger.info('   round_number: ${firstMatch['round_number']}', tag: 'bracket_visualization_service');
    }

    return SaboDE64Bracket(matches: matchList, onMatchTap: onMatchTap);
  }

  // ==================== BRACKET HEADER ====================

  /// Compact header for maximum bracket space (1 line only)
  Widget _buildCompactBracketHeader(Map<String, dynamic> bracketData) {
    // Safely parse participant count
    final participantCountData = bracketData['participantCount'];
    int participantCount = 0;

    if (participantCountData is int) {
      participantCount = participantCountData;
    } else if (participantCountData is String) {
      participantCount = int.tryParse(participantCountData) ?? 0;
    } else if (participantCountData != null) {
      participantCount = int.tryParse(participantCountData.toString()) ?? 0;
    }

    final format = bracketData['format'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ), // Compact padding
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E86AB), Color(0xFF1B5E7D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8), // Smaller radius
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_tree,
            color: Colors.white,
            size: 20, // Smaller icon
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_formatTournamentType(format)} • $participantCount players',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14, // Smaller font
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketHeader(Map<String, dynamic> bracketData) {
    // Safely parse participant count (could be String or int from database)
    final participantCountData = bracketData['participantCount'];
    int participantCount = 0;

    if (participantCountData is int) {
      participantCount = participantCountData;
    } else if (participantCountData is String) {
      participantCount = int.tryParse(participantCountData) ?? 0;
    } else if (participantCountData != null) {
      participantCount = int.tryParse(participantCountData.toString()) ?? 0;
    }

    final format = bracketData['format'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E86AB), Color(0xFF1B5E7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_tree,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTournamentType(format),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$participantCount người tham gia',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DOUBLE ELIMINATION BRACKET ====================

  Future<Widget> _buildDoubleEliminationBracket(
    String tournamentId,
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
    bool showLiveUpdates,
  ) async {
    final matches = bracketData['matches'] as List<dynamic>? ?? [];

    if (matches.isEmpty) {
      return _buildNoMatchesWidget();
    }

    // Group matches by bracket type
    final wbMatches = matches.where((m) => m['bracket_type'] == 'WB').toList();
    final lbMatches = matches.where((m) {
      final type = m['bracket_type'] as String?;
      return type == 'LB' || type == 'LB-A' || type == 'LB-B';
    }).toList();
    final finalMatches = matches.where((m) {
      final type = m['bracket_type'] as String?;
      return type == 'FINAL' || type == 'GRAND_FINAL' || type == 'SABO';
    }).toList();

    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Build bracket tree directly without section headers (tab handles filtering)
    final allMatches = [...wbMatches, ...lbMatches, ...finalMatches];
    final rounds = _convertMatchesToRounds(allMatches);

    if (rounds.isEmpty) {
      return _buildNoMatchesWidget();
    }

    return Container(
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildRoundsWithConnectors(rounds),
          ),
        ),
      ),
    );
  }

  /// Build a bracket section (WB/LB/Final) with title and matches
  Widget _buildBracketSection(
    String title,
    List<dynamic> matches,
    Color color,
    IconData icon,
  ) {
    final rounds = _convertMatchesToRounds(matches);

    if (rounds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header - Hidden for cleaner UI (filter row in tab handles this)
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //       colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        //       begin: Alignment.centerLeft,
        //       end: Alignment.centerRight,
        //     ),
        //     borderRadius: BorderRadius.circular(12),
        //     border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        //   ),
        //   child: Row(
        //     children: [
        //       Container(
        //         padding: const EdgeInsets.all(8),
        //         decoration: BoxDecoration(
        //           color: color.withValues(alpha: 0.2),
        //           borderRadius: BorderRadius.circular(8),
        //         ),
        //         child: Icon(icon, color: color, size: 20),
        //       ),
        //       const SizedBox(width: 12),
        //       Expanded(
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Text(
        //               title,
        //               style: TextStyle(
        //                 fontSize: 18,
        //                 fontWeight: FontWeight.bold,
        //                 color: color,
        //               ),
        //             ),
        //             Text(
        //               '${matches.length} trận đấu • ${rounds.length} vòng',
        //               style: TextStyle(
        //                 fontSize: 12,
        //                 color: Colors.grey[600],
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // const SizedBox(height: 12),

        // Bracket tree
        Container(
          constraints: const BoxConstraints(minHeight: 200),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildRoundsWithConnectors(rounds),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SWISS SYSTEM BRACKET ====================

  Future<Widget> _buildSwissSystemBracket(
    String tournamentId,
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
    bool showLiveUpdates,
  ) async {
    // Swiss System is similar to Round Robin but with pairings per round
    // Reuse Round Robin display logic
    return _buildRoundRobinBracket(
      tournamentId,
      bracketData,
      onMatchTap,
      showLiveUpdates,
    );
  }

  // ==================== ROUND ROBIN BRACKET ====================

  Future<Widget> _buildRoundRobinBracket(
    String tournamentId,
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
    bool showLiveUpdates,
  ) async {
    final matches = bracketData['matches'] as List<dynamic>? ?? [];

    if (matches.isEmpty) {
      return _buildNoMatchesWidget();
    }

    // Calculate standings from matches
    final standings = _calculateRoundRobinStandings(matches);

    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildBracketHeader(bracketData),
            const SizedBox(height: 20),

            // Standings Table
            _buildRoundRobinStandings(standings),
            const SizedBox(height: 24),

            // Match Results
            _buildRoundRobinMatches(matches),
          ],
        ),
      ),
    );
  }

  /// Calculate standings from matches
  List<Map<String, dynamic>> _calculateRoundRobinStandings(
    List<dynamic> matches,
  ) {
    final Map<String, Map<String, dynamic>> playerStats = {};

    for (final match in matches) {
      final player1Data = match['player1'] as Map<String, dynamic>?;
      final player2Data = match['player2'] as Map<String, dynamic>?;
      final status = match['status'] as String?;

      if (player1Data == null || player2Data == null) continue;

      final player1Id = match['player1_id'] as String?;
      final player2Id = match['player2_id'] as String?;
      final player1Name =
          player1Data['display_name'] ?? player1Data['full_name'] ?? player1Data['username'] ?? 'Player 1';
      final player2Name =
          player2Data['display_name'] ?? player2Data['full_name'] ?? player2Data['username'] ?? 'Player 2';

      // Initialize stats if needed
      playerStats[player1Id!] ??= {
        'name': player1Name,
        'played': 0,
        'won': 0,
        'lost': 0,
        'drawn': 0,
        'goalsFor': 0,
        'goalsAgainst': 0,
        'points': 0,
      };
      playerStats[player2Id!] ??= {
        'name': player2Name,
        'played': 0,
        'won': 0,
        'lost': 0,
        'drawn': 0,
        'goalsFor': 0,
        'goalsAgainst': 0,
        'points': 0,
      };

      if (status == 'completed') {
        final score1 = match['player1_score'] as int? ?? 0;
        final score2 = match['player2_score'] as int? ?? 0;
        final winnerId = match['winner_id'] as String?;

        playerStats[player1Id]!['played']++;
        playerStats[player2Id]!['played']++;
        playerStats[player1Id]!['goalsFor'] += score1;
        playerStats[player1Id]!['goalsAgainst'] += score2;
        playerStats[player2Id]!['goalsFor'] += score2;
        playerStats[player2Id]!['goalsAgainst'] += score1;

        if (winnerId == player1Id) {
          playerStats[player1Id]!['won']++;
          playerStats[player1Id]!['points'] += 3;
          playerStats[player2Id]!['lost']++;
        } else if (winnerId == player2Id) {
          playerStats[player2Id]!['won']++;
          playerStats[player2Id]!['points'] += 3;
          playerStats[player1Id]!['lost']++;
        } else if (score1 == score2) {
          // Draw
          playerStats[player1Id]!['drawn']++;
          playerStats[player1Id]!['points'] += 1;
          playerStats[player2Id]!['drawn']++;
          playerStats[player2Id]!['points'] += 1;
        }
      }
    }

    // Convert to list and sort by points
    final standingsList = playerStats.values.toList();
    standingsList.sort((a, b) {
      final pointsDiff = (b['points'] as int) - (a['points'] as int);
      if (pointsDiff != 0) return pointsDiff;

      // If points equal, sort by goal difference
      final gdA = (a['goalsFor'] as int) - (a['goalsAgainst'] as int);
      final gdB = (b['goalsFor'] as int) - (b['goalsAgainst'] as int);
      return gdB - gdA;
    });

    return standingsList;
  }

  /// Build standings table
  Widget _buildRoundRobinStandings(List<Map<String, dynamic>> standings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.2),
                Colors.blue.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.leaderboard, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Text(
                'Bảng Xếp Hạng (Standings)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Table(
            border: TableBorder.symmetric(
              inside: BorderSide(color: Colors.grey.shade300),
            ),
            columnWidths: const {
              0: FixedColumnWidth(50),
              1: FlexColumnWidth(2),
              2: FixedColumnWidth(40),
              3: FixedColumnWidth(40),
              4: FixedColumnWidth(40),
              5: FixedColumnWidth(40),
              6: FixedColumnWidth(60),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  _tableCell('Pos', isHeader: true),
                  _tableCell('Player', isHeader: true),
                  _tableCell('P', isHeader: true),
                  _tableCell('W', isHeader: true),
                  _tableCell('D', isHeader: true),
                  _tableCell('L', isHeader: true),
                  _tableCell('Pts', isHeader: true),
                ],
              ),
              // Rows
              ...standings.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;
                final isTop3 = index < 3;

                return TableRow(
                  decoration: BoxDecoration(
                    color: isTop3 ? Colors.green.withValues(alpha: 0.05) : null,
                  ),
                  children: [
                    _tableCell('${index + 1}', isBold: isTop3),
                    _tableCell(player['name'], isBold: isTop3),
                    _tableCell('${player['played']}'),
                    _tableCell('${player['won']}'),
                    _tableCell('${player['drawn']}'),
                    _tableCell('${player['lost']}'),
                    _tableCell('${player['points']}', isBold: true),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// Build match results list
  Widget _buildRoundRobinMatches(List<dynamic> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.2),
                Colors.purple.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.sports, color: Colors.purple[700], size: 20),
              const SizedBox(width: 12),
              Text(
                'Kết Quả Trận Đấu (Match Results)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: matches.map((match) {
            final player1Data = match['player1'] as Map<String, dynamic>?;
            final player2Data = match['player2'] as Map<String, dynamic>?;
            final player1Name =
                player1Data?['display_name'] ?? player1Data?['full_name'] ?? player1Data?['username'] ?? 'TBD';
            final player2Name =
                player2Data?['display_name'] ?? player2Data?['full_name'] ?? player2Data?['username'] ?? 'TBD';
            final status = match['status'] as String?;
            final score1 = match['player1_score'] as int? ?? 0;
            final score2 = match['player2_score'] as int? ?? 0;
            final winnerId = match['winner_id'] as String?;
            final player1Id = match['player1_id'] as String?;

            final isCompleted = status == 'completed';
            final player1Won = winnerId == player1Id;

            return Container(
              width: 280,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCompleted
                      ? Colors.grey.shade300
                      : Colors.orange.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player1Name,
                          style: TextStyle(
                            fontWeight: player1Won && isCompleted
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: player1Won && isCompleted
                                ? Colors.green[700]
                                : Colors.black,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Text(
                          '$score1',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player2Name,
                          style: TextStyle(
                            fontWeight: !player1Won && isCompleted
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: !player1Won && isCompleted
                                ? Colors.green[700]
                                : Colors.black,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Text(
                          '$score2',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCompleted ? 'Completed' : 'Scheduled',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Helper to build table cell
  Widget _tableCell(String text, {bool isHeader = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ==================== UTILITY METHODS ====================

  String _formatTournamentType(String format) {
    switch (format.toLowerCase()) {
      case 'single_elimination':
        return 'Single Elimination';
      case 'double_elimination':
        return 'Double Elimination';
      case 'sabo_de16':
        return 'SABO DE16';
      case 'sabo_de32':
        return 'SABO DE32';
      case 'round_robin':
        return 'Round Robin';
      case 'swiss_system':
        return 'Swiss System';
      default:
        return format.toUpperCase();
    }
  }

  Widget _buildNoMatchesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Chưa có trận đấu nào',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedFormatWidget(String format) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          Text(
            'Format "$format" chưa được hỗ trợ',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Lỗi tải bracket: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ==================== REAL-TIME UPDATES ====================

  /// Stream for real-time bracket updates
  Stream<Map<String, dynamic>> getBracketUpdateStream(String tournamentId) {
    return _supabase
        .from('tournaments')
        .stream(primaryKey: ['id'])
        .eq('id', tournamentId)
        .map((data) => data.isNotEmpty ? data.first : {});
  }

  /// Stream for real-time match updates
  Stream<List<Map<String, dynamic>>> getMatchUpdateStream(String tournamentId) {
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .eq('tournament_id', tournamentId)
        .order('round')
        .order('created_at');
  }

  // ==================== BRACKET TREE METHODS ====================

  /// Convert database matches to rounds format (like demo bracket)
  List<Map<String, dynamic>> _convertMatchesToRounds(List<dynamic> matches) {
    // Group matches by round
    Map<int, List<dynamic>> roundMatches = {};
    int maxRound = 0;

    for (final match in matches) {
      final roundData =
          match['round_number']; // Use round_number instead of round
      int round = 1;

      if (roundData is int) {
        round = roundData;
      } else if (roundData is String) {
        round = int.tryParse(roundData) ?? 1;
      } else if (roundData != null) {
        round = int.tryParse(roundData.toString()) ?? 1;
      }

      maxRound = math.max(maxRound, round);
      roundMatches[round] ??= [];
      roundMatches[round]!.add(match);
    }

    // Convert to rounds format with match cards
    final List<Map<String, dynamic>> rounds = [];
    final sortedRounds = roundMatches.keys.toList()..sort();

    // Calculate expected total rounds based on first round matches
    int totalExpectedRounds = 1;
    if (roundMatches.containsKey(1)) {
      final firstRoundMatches = roundMatches[1]!.length;
      totalExpectedRounds = _calculateTotalRounds(firstRoundMatches);
    }

    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    for (int round in sortedRounds) {
      final roundData = roundMatches[round]!;

      // Create match cards for this round
      final List<Map<String, String>> matchCards = [];
      for (final match in roundData) {
        final player1Data = match['player1'] as Map<String, dynamic>?;
        final player2Data = match['player2'] as Map<String, dynamic>?;

        // Handle progressive creation - show TBD for future matches
        String player1Name = 'TBD';
        String player2Name = 'TBD';

        if (player1Data != null) {
          player1Name =
              player1Data['display_name'] ?? player1Data['full_name'] ?? player1Data['username'] ?? 'TBD';
        }
        if (player2Data != null) {
          player2Name =
              player2Data['display_name'] ?? player2Data['full_name'] ?? player2Data['username'] ?? 'TBD';
        }

        // For Round 1 matches without players (shouldn't happen in new system)
        if (round == 1 && (player1Data == null || player2Data == null)) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }

        matchCards.add({
          'player1': player1Name,
          'player2': player2Name,
          'player1_avatar': player1Data?['avatar_url']?.toString() ?? 
                           player1Data?['avatar']?.toString() ?? '', // TRY BOTH avatar_url AND avatar
          'player2_avatar': player2Data?['avatar_url']?.toString() ?? 
                           player2Data?['avatar']?.toString() ?? '', // TRY BOTH avatar_url AND avatar
          'score': match['status'] == 'completed'
              ? '${match['player1_score'] ?? 0}-${match['player2_score'] ?? 0}'
              : '0-0',
          'status': match['status']?.toString() ?? 'scheduled',
          'winner_id': match['winner_id']?.toString() ?? '',
          'player1_id': match['player1_id']?.toString() ?? '',
          'player2_id': match['player2_id']?.toString() ?? '',
        });
      } // Generate round title based on total expected rounds
      String title = _generateRoundTitle(round, totalExpectedRounds);

      rounds.add({'title': title, 'matches': matchCards});
    }

    return rounds;
  }

  /// Build rounds with connectors (like demo bracket)
  List<Widget> _buildRoundsWithConnectors(List<Map<String, dynamic>> rounds) {
    List<Widget> widgets = [];

    for (int i = 0; i < rounds.length; i++) {
      final round = rounds[i];
      final isLastRound = i == rounds.length - 1;

      // Add round column
      widgets.add(
        RoundColumn(
          title: round['title'],
          matches: round['matches'].cast<Map<String, String>>(),
          roundIndex: i,
          totalRounds: rounds.length,
        ),
      );

      // Add connector if not the last round
      if (!isLastRound) {
        final nextRound = rounds[i + 1];
        widgets.add(
          BracketConnector(
            fromMatchCount: (round['matches'] as List).length,
            toMatchCount: (nextRound['matches'] as List).length,
            isLastRound: isLastRound,
          ),
        );
      }
    }

    return widgets;
  }

  // ==================== HELPER METHODS ====================

  /// Calculate total rounds needed based on first round match count
  int _calculateTotalRounds(int firstRoundMatches) {
    if (firstRoundMatches <= 0) return 1;

    // Each round reduces matches by half, so total rounds = log2(firstRoundMatches) + 1
    return (math.log(firstRoundMatches) / math.log(2)).round() + 1;
  }

  /// Generate round title based on round number and total expected rounds
  String _generateRoundTitle(int round, int totalRounds) {
    // Calculate matches in this round (working backwards from final)
    final matchesInRound = math.pow(2, totalRounds - round).toInt();

    if (matchesInRound == 1) {
      return 'Chung kết';
    } else if (matchesInRound == 2) {
      return 'Bán kết';
    } else if (matchesInRound == 4) {
      return 'Tứ kết';
    } else if (matchesInRound == 8) {
      return 'Vòng 1/8';
    } else if (matchesInRound == 16) {
      return 'Vòng 1/16';
    } else if (matchesInRound == 32) {
      return 'Vòng 1/32';
    } else {
      return 'Vòng $round';
    }
  }
}

