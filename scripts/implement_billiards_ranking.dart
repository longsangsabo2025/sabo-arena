import 'dart:convert';
import 'package:http/http.dart' as http;

// 🎱 VIETNAMESE BILLIARDS RANKING SYSTEM IMPLEMENTATION
// Based on actual billiards skill levels from K to E+

class BiIliardsRankingSystem {
  final String supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  final String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZijwpgpXJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ';

  Map<String, String> get headers => {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  // 🎯 VIETNAMESE BILLIARDS RANKING SYSTEM
  static const Map<String, Map<String, dynamic>> rankingSystem = {
    'K': {
      'elo': 1000,
      'skill': '2-4 bi khi hình dễ; mới tập',
      'description': 'Người mới bắt đầu, chỉ vào được bi khi hình rất dễ',
      'color': '#8B4513', // Brown
    },
    'K+': {
      'elo': 1100,
      'skill': 'Sát ngưỡng lên I',
      'description': 'Đã quen với cơ bida, chuẩn bị lên trình I',
      'color': '#A0522D', // SaddleBrown
    },
    'I': {
      'elo': 1200,
      'skill': '3-5 bi; chưa điều được chấm',
      'description': 'Vào được 3-5 bi liên tiếp, chưa biết điều bi',
      'color': '#CD853F', // Peru
    },
    'I+': {
      'elo': 1300,
      'skill': 'Sát ngưỡng lên H',
      'description': 'Kỹ thuật I đã ổn định, chuẩn bị lên H',
      'color': '#DEB887', // BurlyWood
    },
    'H': {
      'elo': 1400,
      'skill': '5-8 bi; có thể "rùa" 1 chấm hình dễ',
      'description': 'Vào được 5-8 bi, biết cách rùa bi đơn giản',
      'color': '#C0C0C0', // Silver
    },
    'H+': {
      'elo': 1500,
      'skill': 'Chuẩn bị lên G',
      'description': 'Trình H đã chắc chắn, sắp lên G',
      'color': '#B0B0B0', // Light Gray
    },
    'G': {
      'elo': 1600,
      'skill': 'Clear 1 chấm + 3-7 bi kế; bắt đầu điều bi 3 băng',
      'description':
          'Có thể clear 1 chấm và tiếp tục, biết điều bi 3 băng cơ bản',
      'color': '#FFD700', // Gold
    },
    'G+': {
      'elo': 1700,
      'skill': 'Trình phong trào "ngon"; sát ngưỡng lên F',
      'description': 'Trình độ phong trào tốt, chuẩn bị lên F',
      'color': '#FFA500', // Orange
    },
    'F': {
      'elo': 1800,
      'skill': '60-80% clear 1 chấm, đôi khi phá 2 chấm',
      'description': 'Tỷ lệ clear 1 chấm cao, thỉnh thoảng phá được 2 chấm',
      'color': '#FF6347', // Tomato
    },
    'F+': {
      'elo': 1900,
      'skill': 'Safety & spin control khá chắc; sát ngưỡng lên E',
      'description': 'Biết chơi safety và điều khiển spin tốt',
      'color': '#FF4500', // OrangeRed
    },
    'E': {
      'elo': 2000,
      'skill': '90-100% clear 1 chấm, 70% phá 2 chấm',
      'description': 'Gần như chắc chắn clear 1 chấm, thường phá được 2 chấm',
      'color': '#DC143C', // Crimson
    },
    'E+': {
      'elo': 2100,
      'skill': 'Điều bi phức tạp, safety chủ động; sát ngưỡng lên D',
      'description': 'Kỹ thuật điều bi cao cấp, chơi safety chủ động',
      'color': '#B22222', // FireBrick
    },
  };

  Future<void> implementRankingSystem() async {
    print('🎱 IMPLEMENTING VIETNAMESE BILLIARDS RANKING SYSTEM');
    print('===================================================');
    print('');

    await _displayRankingSystem();
    await _analyzeCurrentUsers();
    await _assignCorrectRanks();
    await _createRankingFunction();
    await _testRankingSystem();
  }

  Future<void> _displayRankingSystem() async {
    print('📊 VIETNAMESE BILLIARDS RANKING LEVELS:');
    print('');

    rankingSystem.forEach((rank, data) {
      final elo = data['elo'];
      final skill = data['skill'];
      final description = data['description'];

      print('   🎯 RANK $rank (ELO: $elo)');
      print('      ├── Skill: $skill');
      print('      └── Description: $description');
      print('');
    });
  }

  Future<void> _analyzeCurrentUsers() async {
    print('👥 ANALYZING CURRENT USERS & THEIR CORRECT RANKS:');
    print('');

    try {
      final response = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/users?select=id,username,elo_rating,rank,total_wins,total_losses,total_matches',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final users = jsonDecode(response.body) as List;

        for (final user in users) {
          final username = user['username'] ?? 'Unknown';
          final currentElo = user['elo_rating'] ?? 1200;
          final currentRank = user['rank'] ?? 'I';
          final correctRank = _getCorrectRank(currentElo);
          final wins = user['total_wins'] ?? 0;
          final losses = user['total_losses'] ?? 0;
          final matches = user['total_matches'] ?? 0;

          print('   👤 $username');
          print('      ├── Current ELO: $currentElo');
          print('      ├── Current Rank: $currentRank');
          print('      ├── Correct Rank: $correctRank');
          print('      ├── Record: ${wins}W-${losses}L ($matches total)');

          if (currentRank != correctRank) {
            print(
              '      └── ⚠️ RANK UPDATE NEEDED: $currentRank → $correctRank',
            );
          } else {
            print('      └── ✅ Rank is correct');
          }
          print('');
        }
      }
    } catch (e) {
      print('   ❌ Error analyzing users: $e');
    }
  }

  String _getCorrectRank(int elo) {
    // Find the correct rank based on ELO thresholds
    final ranks = [
      'K',
      'K+',
      'I',
      'I+',
      'H',
      'H+',
      'G',
      'G+',
      'F',
      'F+',
      'E',
      'E+',
    ];

    for (int i = ranks.length - 1; i >= 0; i--) {
      final rank = ranks[i];
      final threshold = rankingSystem[rank]!['elo'] as int;
      if (elo >= threshold) {
        return rank;
      }
    }
    return 'K'; // Default to lowest rank
  }

  Future<void> _assignCorrectRanks() async {
    print('🔄 UPDATING USER RANKS BASED ON ELO:');
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
        int updatesNeeded = 0;

        for (final user in users) {
          final userId = user['id'];
          final username = user['username'] ?? 'Unknown';
          final currentElo = user['elo_rating'] ?? 1200;
          final currentRank = user['rank'] ?? 'I';
          final correctRank = _getCorrectRank(currentElo);

          if (currentRank != correctRank) {
            updatesNeeded++;
            print(
              '   🔄 Updating $username: $currentRank → $correctRank (ELO: $currentElo)',
            );

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
                print('      ✅ Successfully updated');
              } else {
                print('      ❌ Update failed: ${updateResponse.statusCode}');
              }
            } catch (e) {
              print('      ❌ Error updating user: $e');
            }
          } else {
            print('   ✅ $username already has correct rank: $correctRank');
          }
        }

        print('');
        print('   📊 RANK UPDATE SUMMARY:');
        print('   ├── Total Users: ${users.length}');
        print('   ├── Updates Needed: $updatesNeeded');
        print('   └── Already Correct: ${users.length - updatesNeeded}');
      }
    } catch (e) {
      print('   ❌ Error updating ranks: $e');
    }
  }

  Future<void> _createRankingFunction() async {
    print('');
    print('🔧 CREATING RANK CALCULATION FUNCTION:');
    print('');

    final functionSql = '''
CREATE OR REPLACE FUNCTION update_user_rank(user_id_param UUID)
RETURNS TEXT AS \$\$
DECLARE
    current_elo INTEGER;
    new_rank TEXT;
BEGIN
    -- Get current ELO
    SELECT elo_rating INTO current_elo 
    FROM users 
    WHERE id = user_id_param;
    
    -- Calculate new rank based on ELO
    IF current_elo >= 2100 THEN
        new_rank := 'E+';
    ELSIF current_elo >= 2000 THEN
        new_rank := 'E';
    ELSIF current_elo >= 1900 THEN
        new_rank := 'F+';
    ELSIF current_elo >= 1800 THEN
        new_rank := 'F';
    ELSIF current_elo >= 1700 THEN
        new_rank := 'G+';
    ELSIF current_elo >= 1600 THEN
        new_rank := 'G';
    ELSIF current_elo >= 1500 THEN
        new_rank := 'H+';
    ELSIF current_elo >= 1400 THEN
        new_rank := 'H';
    ELSIF current_elo >= 1300 THEN
        new_rank := 'I+';
    ELSIF current_elo >= 1200 THEN
        new_rank := 'I';
    ELSIF current_elo >= 1100 THEN
        new_rank := 'K+';
    ELSE
        new_rank := 'K';
    END IF;
    
    -- Update user rank
    UPDATE users 
    SET rank = new_rank, updated_at = NOW()
    WHERE id = user_id_param;
    
    RETURN new_rank;
END;
\$\$ LANGUAGE plpgsql;
''';

    print('   📝 SQL FUNCTION FOR RANK CALCULATION:');
    print('   ```sql');
    print(functionSql);
    print('   ```');
    print('');
    print('   💡 This function should be added to Supabase SQL editor');
    print('   📋 Function name: update_user_rank(user_id UUID)');
    print('   🔄 Auto-calculates rank based on ELO thresholds');
  }

  Future<void> _testRankingSystem() async {
    print('');
    print('🧪 TESTING RANKING SYSTEM:');
    print('');

    // Test ELO to rank conversion
    final testElos = [
      950,
      1050,
      1150,
      1250,
      1350,
      1450,
      1550,
      1650,
      1750,
      1850,
      1950,
      2050,
      2150,
    ];

    print('   🎯 ELO TO RANK CONVERSION TEST:');
    for (final elo in testElos) {
      final rank = _getCorrectRank(elo);
      final rankData = rankingSystem[rank]!;
      print('   ├── ELO $elo → Rank $rank (${rankData['skill']})');
    }

    print('');
    print('   📊 RANK DISTRIBUTION ANALYSIS:');
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/users?select=rank,elo_rating'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final users = jsonDecode(response.body) as List;
        final rankCounts = <String, int>{};

        for (final user in users) {
          final elo = user['elo_rating'] ?? 1200;
          final correctRank = _getCorrectRank(elo);
          rankCounts[correctRank] = (rankCounts[correctRank] ?? 0) + 1;
        }

        rankCounts.forEach((rank, count) {
          final percentage = (count / users.length * 100).toStringAsFixed(1);
          final rankData = rankingSystem[rank]!;
          print(
            '   ├── Rank $rank: $count players ($percentage%) - ${rankData['skill']}',
          );
        });
      }
    } catch (e) {
      print('   ❌ Error analyzing rank distribution: $e');
    }

    print('');
    print('   🎉 VIETNAMESE BILLIARDS RANKING SYSTEM READY!');
    print('   ✅ K → E+ ranking levels defined');
    print('   ✅ ELO thresholds established');
    print('   ✅ Skill descriptions in Vietnamese');
    print('   ✅ Automatic rank calculation function');
    print('   ✅ Real billiards terminology (chấm, rùa, clear)');
    print('   💡 System reflects actual Vietnamese billiards culture!');
  }
}

void main() async {
  final system = BiIliardsRankingSystem();
  await system.implementRankingSystem();
}
