// 🎯 SABO ARENA - DE16 Demo Wrapper
// Wraps SaboDE16Bracket with sample data for demo purposes

import 'package:flutter/material.dart';
import './sabo_de16_bracket.dart';
// ELON_MODE_AUTO_FIX

class DE16DemoWrapper extends StatelessWidget {
  const DE16DemoWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate sample matches for DE16 (27 matches total)
    final sampleMatches = _generateSampleDE16Matches();

    return SaboDE16Bracket(
      matches: sampleMatches,
      onMatchTap: () {
        // Optional: Show match details in demo
      },
    );
  }

  /// Generate 27 sample matches for SABO DE16
  /// Structure: WB(14) + LB-A(7) + LB-B(3) + Finals(3)
  List<Map<String, dynamic>> _generateSampleDE16Matches() {
    final matches = <Map<String, dynamic>>[];
    final playerNames = _generatePlayerNames(16);

    // ========== WINNER BRACKET: 14 matches ==========

    // WB Round 1: 8 matches (1101-1108)
    for (int i = 0; i < 8; i++) {
      matches.add({
        'id': 'WB_R1_M${i + 1}',
        'round_number': 1,
        'match_number': i + 1,
        'bracket_type': 'WB',
        'stage_round': 1,
        'display_order': 1101 + i,
        'player1_id': 'p${i * 2 + 1}',
        'player2_id': 'p${i * 2 + 2}',
        'player1_name': playerNames[i * 2],
        'player2_name': playerNames[i * 2 + 1],
        'player1_score': _randomScore(),
        'player2_score': _randomScore(),
        'winner_id': i % 2 == 0 ? 'p${i * 2 + 1}' : 'p${i * 2 + 2}',
        'status': 'completed',
      });
    }

    // WB Round 2: 4 matches (1201-1204)
    for (int i = 0; i < 4; i++) {
      final p1Index = i * 2;
      final p2Index = i * 2 + 1;
      matches.add({
        'id': 'WB_R2_M${i + 1}',
        'round_number': 2,
        'match_number': 9 + i,
        'bracket_type': 'WB',
        'stage_round': 2,
        'display_order': 1201 + i,
        'player1_id': 'p${p1Index + 1}',
        'player2_id': 'p${p2Index + 1}',
        'player1_name': playerNames[p1Index],
        'player2_name': playerNames[p2Index],
        'player1_score': _randomScore(),
        'player2_score': _randomScore(),
        'winner_id': i % 2 == 0 ? 'p${p1Index + 1}' : 'p${p2Index + 1}',
        'status': 'completed',
      });
    }

    // WB Round 3: 2 matches (1301-1302) - NO LOSER ADVANCE!
    for (int i = 0; i < 2; i++) {
      matches.add({
        'id': 'WB_R3_M${i + 1}',
        'round_number': 3,
        'match_number': 13 + i,
        'bracket_type': 'WB',
        'stage_round': 3,
        'display_order': 1301 + i,
        'player1_id': 'p${i * 2 + 1}',
        'player2_id': 'p${i * 2 + 3}',
        'player1_name': playerNames[i * 2],
        'player2_name': playerNames[i * 2 + 2],
        'player1_score': _randomScore(),
        'player2_score': _randomScore(),
        'winner_id': 'p${i * 2 + 1}',
        'status': 'completed',
      });
    }

    // ========== LOSER BRANCH A: 7 matches ==========

    // LB-A Round 1: 4 matches (2101-2104)
    for (int i = 0; i < 4; i++) {
      matches.add({
        'id': 'LBA_R1_M${i + 1}',
        'round_number': 101,
        'match_number': 15 + i,
        'bracket_type': 'LB-A',
        'stage_round': 1,
        'display_order': 2101 + i,
        'player1_id': 'p${i * 2 + 2}',
        'player2_id': 'p${i * 2 + 4}',
        'player1_name': playerNames[i * 2 + 1],
        'player2_name': playerNames[i * 2 + 3],
        'player1_score': _randomScore(),
        'player2_score': _randomScore(),
        'winner_id': 'p${i * 2 + 2}',
        'status': 'completed',
      });
    }

    // LB-A Round 2: 2 matches (2201-2202)
    for (int i = 0; i < 2; i++) {
      matches.add({
        'id': 'LBA_R2_M${i + 1}',
        'round_number': 102,
        'match_number': 19 + i,
        'bracket_type': 'LB-A',
        'stage_round': 2,
        'display_order': 2201 + i,
        'player1_id': 'p${i * 2 + 2}',
        'player2_id': 'p${i * 2 + 4}',
        'player1_name': playerNames[i * 2 + 1],
        'player2_name': playerNames[i * 2 + 3],
        'player1_score': _randomScore(),
        'player2_score': _randomScore(),
        'winner_id': 'p${i * 2 + 2}',
        'status': 'completed',
      });
    }

    // LB-A Round 3 / Final: 1 match (2301)
    matches.add({
      'id': 'LBA_R3_M1',
      'round_number': 103,
      'match_number': 21,
      'bracket_type': 'LB-A',
      'stage_round': 3,
      'display_order': 2301,
      'player1_id': 'p2',
      'player2_id': 'p4',
      'player1_name': playerNames[1],
      'player2_name': playerNames[3],
      'player1_score': _randomScore(),
      'player2_score': _randomScore(),
      'winner_id': 'p2',
      'status': 'completed',
    });

    // ========== LOSER BRANCH B: 3 matches ==========

    // LB-B Round 1: 2 matches (3101-3102)
    for (int i = 0; i < 2; i++) {
      matches.add({
        'id': 'LBB_R1_M${i + 1}',
        'round_number': 201,
        'match_number': 22 + i,
        'bracket_type': 'LB-B',
        'stage_round': 1,
        'display_order': 3101 + i,
        'player1_id': 'p${i + 5}',
        'player2_id': 'p${i + 7}',
        'player1_name': playerNames[i + 4],
        'player2_name': playerNames[i + 6],
        'player1_score': _randomScore(),
        'player2_score': _randomScore(),
        'winner_id': 'p${i + 5}',
        'status': 'completed',
      });
    }

    // LB-B Round 2 / Final: 1 match (3201)
    matches.add({
      'id': 'LBB_R2_M1',
      'round_number': 202,
      'match_number': 24,
      'bracket_type': 'LB-B',
      'stage_round': 2,
      'display_order': 3201,
      'player1_id': 'p5',
      'player2_id': 'p6',
      'player1_name': playerNames[4],
      'player2_name': playerNames[5],
      'player1_score': _randomScore(),
      'player2_score': _randomScore(),
      'winner_id': 'p5',
      'status': 'completed',
    });

    // ========== SABO FINALS: 3 matches ==========

    // Semifinal 1: (4101) WB R3 M13 winner vs LB-A champion
    matches.add({
      'id': 'FINAL_SF1',
      'round_number': 250,
      'match_number': 25,
      'bracket_type': 'SABO',
      'stage_round': 1,
      'display_order': 4101,
      'player1_id': 'p1',
      'player2_id': 'p2',
      'player1_name': '${playerNames[0]} (WB)',
      'player2_name': '${playerNames[1]} (LB-A)',
      'player1_score': _randomScore(),
      'player2_score': _randomScore(),
      'winner_id': 'p1',
      'status': 'completed',
    });

    // Semifinal 2: (4102) WB R3 M14 winner vs LB-B champion
    matches.add({
      'id': 'FINAL_SF2',
      'round_number': 251,
      'match_number': 26,
      'bracket_type': 'SABO',
      'stage_round': 1,
      'display_order': 4102,
      'player1_id': 'p3',
      'player2_id': 'p5',
      'player1_name': '${playerNames[2]} (WB)',
      'player2_name': '${playerNames[4]} (LB-B)',
      'player1_score': _randomScore(),
      'player2_score': _randomScore(),
      'winner_id': 'p3',
      'status': 'completed',
    });

    // SABO Finals: (4201)
    matches.add({
      'id': 'FINAL',
      'round_number': 300,
      'match_number': 27,
      'bracket_type': 'SABO',
      'stage_round': 2,
      'display_order': 4201,
      'player1_id': 'p1',
      'player2_id': 'p3',
      'player1_name': playerNames[0],
      'player2_name': playerNames[2],
      'player1_score': 11,
      'player2_score': 9,
      'winner_id': 'p1',
      'status': 'completed',
    });

    return matches;
  }

  /// Generate realistic player names
  List<String> _generatePlayerNames(int count) {
    final names = [
      'Nguyễn Văn A',
      'Trần Thị B',
      'Lê Văn C',
      'Phạm Thị D',
      'Hoàng Văn E',
      'Vũ Thị F',
      'Đặng Văn G',
      'Bùi Thị H',
      'Đỗ Văn I',
      'Ngô Thị J',
      'Dương Văn K',
      'Lý Thị L',
      'Võ Văn M',
      'Phan Thị N',
      'Trương Văn O',
      'Đinh Thị P',
    ];
    return names.take(count).toList();
  }

  /// Generate random score (7-11 for race to 11)
  int _randomScore() {
    return 7 + (DateTime.now().millisecondsSinceEpoch % 5);
  }
}

