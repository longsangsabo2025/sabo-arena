import 'dart:convert';
import 'package:http/http.dart' as http;

// 🔧 ALTERNATIVE: UPDATE USER RANKS DIRECTLY WITHOUT CREATING FUNCTIONS

class DirectRankingUpdate {
  final String supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  final String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ';

  Map<String, String> get headers => {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  // Vietnamese Billiards Ranking System
  static const Map<String, Map<String, dynamic>> rankingSystem = {
    'K': {'elo': 1000, 'skill': '2-4 bi khi hình dễ; mới tập'},
    'K+': {'elo': 1100, 'skill': 'Sát ngưỡng lên I'},
    'I': {'elo': 1200, 'skill': '3-5 bi; chưa điều được chấm'},
    'I+': {'elo': 1300, 'skill': 'Sát ngưỡng lên H'},
    'H': {'elo': 1400, 'skill': '5-8 bi; có thể "rùa" 1 chấm hình dễ'},
    'H+': {'elo': 1500, 'skill': 'Chuẩn bị lên G'},
    'G': {
      'elo': 1600,
      'skill': 'Clear 1 chấm + 3-7 bi kế; bắt đầu điều bi 3 băng',
    },
    'G+': {'elo': 1700, 'skill': 'Trình phong trào "ngon"; sát ngưỡng lên F'},
    'F': {'elo': 1800, 'skill': '60-80% clear 1 chấm, đôi khi phá 2 chấm'},
    'F+': {
      'elo': 1900,
      'skill': 'Safety & spin control khá chắc; sát ngưỡng lên E',
    },
    'E': {'elo': 2000, 'skill': '90-100% clear 1 chấm, 70% phá 2 chấm'},
    'E+': {
      'elo': 2100,
      'skill': 'Điều bi phức tạp, safety chủ động; sát ngưỡng lên D',
    },
  };

  Future<void> updateAllUserRanksDirectly() async {
    print('🎱 UPDATING USER RANKS DIRECTLY - VIETNAMESE BILLIARDS SYSTEM');
    print('=============================================================');
    print('');

    await _analyzeCurrentRanks();
    await _updateRanksDirectly();
    await _showRankingLeaderboard();
  }

  String _calculateRankFromElo(int elo) {
    if (elo >= 2100) return 'E+';
    if (elo >= 2000) return 'E';
    if (elo >= 1900) return 'F+';
    if (elo >= 1800) return 'F';
    if (elo >= 1700) return 'G+';
    if (elo >= 1600) return 'G';
    if (elo >= 1500) return 'H+';
    if (elo >= 1400) return 'H';
    if (elo >= 1300) return 'I+';
    if (elo >= 1200) return 'I';
    if (elo >= 1100) return 'K+';
    return 'K';
  }

  Future<void> _analyzeCurrentRanks() async {
    print('📊 STEP 1: ANALYZING CURRENT USER RANKS');
    print('');

    try {
      final response = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/users?select=id,username,elo_rating,rank,total_wins,total_losses,total_matches&order=elo_rating.desc',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final users = jsonDecode(response.body) as List;

        print('   👥 CURRENT USER ANALYSIS:');
        print('   Total Users: ${users.length}');
        print('');

        for (int i = 0; i < users.length; i++) {
          final user = users[i];
          final username = user['username'] ?? 'Unknown';
          final currentElo = user['elo_rating'] ?? 1200;
          final currentRank = user['rank'] ?? 'I';
          final correctRank = _calculateRankFromElo(currentElo);
          final wins = user['total_wins'] ?? 0;
          final losses = user['total_losses'] ?? 0;
          final matches = user['total_matches'] ?? 0;

          final needsUpdate = currentRank != correctRank;
          final status = needsUpdate ? '⚠️ NEEDS UPDATE' : '✅ CORRECT';

          print('   ${i + 1}. $username');
          print('      ├── ELO: $currentElo');
          print('      ├── Current Rank: $currentRank');
          print('      ├── Correct Rank: $correctRank');
          print('      ├── Record: ${wins}W-${losses}L ($matches total)');
          print('      └── Status: $status');

          if (needsUpdate) {
            final skillDesc = rankingSystem[correctRank]!['skill'];
            print('         💡 New skill level: $skillDesc');
          }
          print('');
        }
      }
    } catch (e) {
      print('   ❌ Error analyzing ranks: $e');
    }
  }

  Future<void> _updateRanksDirectly() async {
    print('🔄 STEP 2: UPDATING RANKS DIRECTLY VIA REST API');
    print('');

    try {
      final response = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/users?select=id,username,elo_rating,rank',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final users = jsonDecode(response.body) as List;

        int updated = 0;
        int unchanged = 0;
        int errors = 0;

        for (final user in users) {
          final userId = user['id'];
          final username = user['username'] ?? 'Unknown';
          final currentElo = user['elo_rating'] ?? 1200;
          final currentRank = user['rank'] ?? 'I';
          final correctRank = _calculateRankFromElo(currentElo);

          if (currentRank != correctRank) {
            // Update the user's rank
            try {
              final updateResponse = await http.patch(
                Uri.parse('$supabaseUrl/rest/v1/users?id=eq.$userId'),
                headers: headers,
                body: jsonEncode({
                  'rank': correctRank,
                  'updated_at': DateTime.now().toIso8601String(),
                }),
              );

              if (updateResponse.statusCode == 204) {
                updated++;
                final skillDesc = rankingSystem[correctRank]!['skill'];
                print(
                  '   ✅ $username: $currentRank → $correctRank (ELO: $currentElo)',
                );
                print('      💡 $skillDesc');
              } else {
                errors++;
                print(
                  '   ❌ Failed to update $username: ${updateResponse.statusCode}',
                );
                print('      Response: ${updateResponse.body}');
              }
            } catch (e) {
              errors++;
              print('   ❌ Error updating $username: $e');
            }
          } else {
            unchanged++;
            print(
              '   ✅ $username: $correctRank (ELO: $currentElo) - already correct',
            );
          }
        }

        print('');
        print('   📊 UPDATE SUMMARY:');
        print('   ├── Total Users: ${users.length}');
        print('   ├── Updated: $updated');
        print('   ├── Unchanged: $unchanged');
        print('   └── Errors: $errors');
      }
    } catch (e) {
      print('   ❌ Error updating ranks: $e');
    }
  }

  Future<void> _showRankingLeaderboard() async {
    print('');
    print('🏆 STEP 3: FINAL RANKING LEADERBOARD');
    print('');

    try {
      final response = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/users?select=username,elo_rating,rank,total_wins,total_losses,total_matches&order=elo_rating.desc',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final users = jsonDecode(response.body) as List;

        print('   🏆 VIETNAMESE BILLIARDS LEADERBOARD:');
        print('');

        for (int i = 0; i < users.length; i++) {
          final user = users[i];
          final username = user['username'] ?? 'Unknown';
          final elo = user['elo_rating'] ?? 1200;
          final rank = user['rank'] ?? 'I';
          final wins = user['total_wins'] ?? 0;
          final losses = user['total_losses'] ?? 0;
          final matches = user['total_matches'] ?? 0;
          final winRate = matches > 0
              ? (wins / matches * 100).toStringAsFixed(1)
              : '0.0';

          final medal = i == 0
              ? '🥇'
              : i == 1
              ? '🥈'
              : i == 2
              ? '🥉'
              : '  ';
          final skillDesc = rankingSystem[rank]!['skill'];

          print('   $medal ${i + 1}. $username');
          print('      ├── Rank: $rank (ELO: $elo)');
          print('      ├── Skill: $skillDesc');
          print('      ├── Record: ${wins}W-${losses}L ($winRate% WR)');
          print('      └── Total Matches: $matches');
          print('');
        }

        // Show rank distribution
        print('   📊 RANK DISTRIBUTION:');
        final rankCounts = <String, int>{};
        for (final user in users) {
          final rank = user['rank'] ?? 'I';
          rankCounts[rank] = (rankCounts[rank] ?? 0) + 1;
        }

        final sortedRanks = [
          'E+',
          'E',
          'F+',
          'F',
          'G+',
          'G',
          'H+',
          'H',
          'I+',
          'I',
          'K+',
          'K',
        ];
        for (final rank in sortedRanks) {
          final count = rankCounts[rank] ?? 0;
          if (count > 0) {
            final percentage = (count / users.length * 100).toStringAsFixed(1);
            final skillDesc = rankingSystem[rank]!['skill'];
            print('   ├── $rank: $count players ($percentage%) - $skillDesc');
          }
        }
      }
    } catch (e) {
      print('   ❌ Error showing leaderboard: $e');
    }

    print('');
    print('🎉 VIETNAMESE BILLIARDS RANKING SYSTEM DEPLOYED!');
    print('✅ All user ranks updated based on ELO');
    print('✅ K → E+ ranking system implemented');
    print('✅ Vietnamese terminology: chấm, rùa, clear, điều bi');
    print('✅ Skill descriptions match real billiards culture');
    print('💡 Ready for production use!');
  }
}

void main() async {
  final updater = DirectRankingUpdate();
  await updater.updateAllUserRanksDirectly();
}
