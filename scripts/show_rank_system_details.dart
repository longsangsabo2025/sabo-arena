import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Show detailed rank_system table structure

class ShowRankSystemDetails {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> show() async {
    print('🔍 RANK_SYSTEM TABLE DETAILS...\n');

    await _loadCredentials();

    final response = await http.get(
      Uri.parse('$newSupabaseUrl/rest/v1/rank_system?select=*'),
      headers: {
        'apikey': newSupabaseServiceKey,
        'Authorization': 'Bearer $newSupabaseServiceKey',
      },
    );

    if (response.statusCode != 200) {
      print('❌ Error: ${response.statusCode}');
      return;
    }

    final ranks = jsonDecode(response.body) as List;
    print('✅ Found ${ranks.length} ranks\n');

    // Show first rank structure
    if (ranks.isNotEmpty) {
      print('📊 TABLE STRUCTURE (first rank):');
      print('=' * 70);
      final first = ranks[0] as Map<String, dynamic>;
      first.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });
      print('=' * 70);
      print('');
    }

    // Show all ranks
    print('📋 ALL RANKS:');
    print('=' * 70);
    for (var i = 0; i < ranks.length; i++) {
      final rank = ranks[i] as Map<String, dynamic>;
      print('${i + 1}. Rank: ${rank}');
      print('');
    }
    print('=' * 70);
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
    await ShowRankSystemDetails.show();
  } catch (e) {
    print('\n❌ Failed: $e');
    exit(1);
  }
}
