import 'package:flutter/material.dart';
import 'package:sabo_arena/services/basic_handicap_service.dart';

/// Example: How to use BasicHandicapService in UI widgets
///
/// Use case 1: Display handicap in match card
/// Use case 2: Show handicap when creating match
/// Use case 3: Tournament bracket display

class HandicapUIExample extends StatelessWidget {
  const HandicapUIExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Handicap UI Examples')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Example 1: Simple match card
          _buildMatchCardExample('K', 'I'),
          SizedBox(height: 16),

          // Example 2: Tournament match
          _buildMatchCardExample('K', 'H'),
          SizedBox(height: 16),

          // Example 3: Same rank (no handicap)
          _buildMatchCardExample('H', 'H'),
          SizedBox(height: 16),

          // Example 4: Large difference
          _buildMatchCardExample('K', 'G'),
        ],
      ),
    );
  }

  Widget _buildMatchCardExample(String rank1, String rank2) {
    // ✅ METHOD 1: Get formatted display text (simplest)
    final handicapText =
        BasicHandicapService.getHandicapDisplayText(rank1, rank2);

    // ✅ METHOD 2: Get full info (for detailed display)
    final handicapInfo = BasicHandicapService.getHandicapInfo(rank1, rank2);
    final description = handicapInfo['description'] as String;

    // Calculate starting scores
    final matchInfo = BasicHandicapService.applyHandicapToRaceTo7(
      player1Rank: rank1,
      player2Rank: rank2,
      player1Id: 'player1',
      player2Id: 'player2',
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match title
            Text(
              'Rank $rank1 vs Rank $rank2',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            // Handicap info - METHOD 1 (simple)
            Row(
              children: [
                Icon(Icons.balance, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Text(handicapText), // "Handicap 2 ván" or "Không chấp"
              ],
            ),
            SizedBox(height: 4),

            // Race to
            Row(
              children: [
                Icon(Icons.flag, size: 16, color: Colors.blue),
                SizedBox(width: 4),
                Text('Race to 7'),
              ],
            ),
            SizedBox(height: 8),

            // Starting scores
            Text(
              'Starting: ${matchInfo['player1_starting_score']}-${matchInfo['player2_starting_score']}',
              style: TextStyle(color: Colors.grey[600]),
            ),

            // Detailed description
            Text(
              description, // "K chấp I 1 ván"
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example: Integration with existing MatchCard widget
class MatchCardIntegrationExample {
  /// Use this in match_card_widget.dart
  static String getHandicapForMatch({
    required String player1Rank,
    required String player2Rank,
  }) {
    // Simple one-liner to get handicap text for UI
    return BasicHandicapService.getHandicapDisplayText(
        player1Rank, player2Rank);
  }

  /// Use this when preparing match data
  static Map<String, dynamic> prepareMatchDisplay({
    required String player1Rank,
    required String player2Rank,
    required String player1Id,
    required String player2Id,
  }) {
    final handicapInfo = BasicHandicapService.applyHandicapToRaceTo7(
      player1Rank: player1Rank,
      player2Rank: player2Rank,
      player1Id: player1Id,
      player2Id: player2Id,
    );

    return {
      'handicap': handicapInfo['ui_display'] ?? 'Không chấp',
      'raceInfo': 'Race to 7',
      'score1': handicapInfo['player1_starting_score'].toString(),
      'score2': handicapInfo['player2_starting_score'].toString(),
      'description': handicapInfo['description'],
    };
  }
}

/// Example: How to update match_card_widget.dart
///
/// BEFORE:
/// ```dart
/// handicap = m['handicap'] as String? ?? 'Handicap 0.5 ván';
/// ```
///
/// AFTER:
/// ```dart
/// // Get player ranks from match data
/// final player1Rank = m['player1_rank'] as String? ?? 'K';
/// final player2Rank = m['player2_rank'] as String? ?? 'K';
///
/// // Calculate handicap using BasicHandicapService
/// handicap = BasicHandicapService.getHandicapDisplayText(player1Rank, player2Rank);
/// ```
///
/// That's it! Simple and clean.
