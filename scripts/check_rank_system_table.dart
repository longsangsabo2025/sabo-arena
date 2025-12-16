import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Check rank_system table in database

class CheckRankSystemTable {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> check() async {
    print('🔍 CHECKING RANK_SYSTEM TABLE...\n');

    await _loadCredentials();

    // Check if rank_system table exists
    print('📊 Checking rank_system table...\n');

    final response = await http.get(
      Uri.parse('$newSupabaseUrl/rest/v1/rank_system?select=*'),
      headers: {
        'apikey': newSupabaseServiceKey,
        'Authorization': 'Bearer $newSupabaseServiceKey',
      },
    );

    if (response.statusCode == 404) {
      print('❌ Table rank_system does NOT exist!');
      print(
        '\n💡 This is OK - rank system is defined in code (sabo_rank_system.dart)',
      );
      return;
    }

    if (response.statusCode != 200) {
      print('⚠️  Error: ${response.statusCode}');
      print('   ${response.body}');
      return;
    }

    final ranks = jsonDecode(response.body) as List;
    print('✅ Found ${ranks.length} ranks in database\n');

    if (ranks.isEmpty) {
      print('⚠️  Table exists but is empty!');
      return;
    }

    // Show all ranks
    print('📋 RANK SYSTEM IN DATABASE:');
    print('=' * 80);
    print(
      '${'Rank'.padRight(8)} ${'Name'.padRight(20)} ${'ELO'.padRight(8)} ${'Skill Description'}',
    );
    print('=' * 80);

    for (var rank in ranks) {
      final rankCode = rank['rank_code'] ?? rank['code'] ?? rank['id'] ?? '?';
      final name = rank['name'] ?? rank['display_name'] ?? '?';
      final elo = rank['min_elo'] ?? rank['elo'] ?? rank['elo_rating'] ?? '?';
      final skill = rank['skill_description'] ?? rank['description'] ?? '?';

      print(
        '${rankCode.toString().padRight(8)} ${name.toString().padRight(20)} ${elo.toString().padRight(8)} $skill',
      );
    }

    print('=' * 80);
    print('\n📊 COMPARISON WITH CODE:');
    print('Database has: ${ranks.length} ranks');
    print('Code has: 12 ranks (K, K+, I, I+, H, H+, G, G+, F, F+, E, E+)');
  }

  static Future<void> _loadCredentials() async {
    final envFile = File('.env');
    final lines = await envFile.readAsLines();

    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        newSupabaseUrl = line.split('=')[1].trim();
      } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        newSupabaseServiceKey = line.split('=')[1].trim();
      }
    }

    print('✅ Connected to: $newSupabaseUrl\n');
  }
}

void main() async {
  try {
    await CheckRankSystemTable.check();
  } catch (e) {
    print('\n❌ Failed: $e');
    exit(1);
  }
}
