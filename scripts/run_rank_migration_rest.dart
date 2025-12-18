import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Run rank system migration using REST API

class RunRankMigrationRest {
  static String supabaseUrl = '';
  static String serviceRoleKey = '';

  static Future<void> run() async {
    print('🚀 RUNNING RANK SYSTEM MIGRATION (REST API)...\n');

    await _loadCredentials();

    // Step 1: Delete all existing ranks
    print('Step 1: Deleting existing ranks...');
    final deleteResponse = await http.delete(
      Uri.parse(
        '$supabaseUrl/rest/v1/rank_system?id=neq.00000000-0000-0000-0000-000000000000',
      ),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Prefer': 'return=minimal',
      },
    );
    print('✅ Deleted (${deleteResponse.statusCode})\n');

    // Step 2: Insert new rank system
    print('Step 2: Inserting new rank system (12 ranks)...');

    final ranks = [
      {
        'rank_code': 'K',
        'rank_order': 1,
        'rank_name': 'Starter',
        'rank_name_vi': 'Người mới',
        'rank_color': '#8BC34A',
        'elo_min': 1000,
        'elo_max': 1099,
      },
      {
        'rank_code': 'K+',
        'rank_order': 2,
        'rank_name': 'Apprentice',
        'rank_name_vi': 'Học việc',
        'rank_color': '#4CAF50',
        'elo_min': 1100,
        'elo_max': 1199,
      },
      {
        'rank_code': 'I',
        'rank_order': 3,
        'rank_name': 'Worker III',
        'rank_name_vi': 'Thợ 3',
        'rank_color': '#2196F3',
        'elo_min': 1200,
        'elo_max': 1299,
      },
      {
        'rank_code': 'I+',
        'rank_order': 4,
        'rank_name': 'Worker II',
        'rank_name_vi': 'Thợ 2',
        'rank_color': '#1976D2',
        'elo_min': 1300,
        'elo_max': 1399,
      },
      {
        'rank_code': 'H',
        'rank_order': 5,
        'rank_name': 'Worker I',
        'rank_name_vi': 'Thợ 1',
        'rank_color': '#9C27B0',
        'elo_min': 1400,
        'elo_max': 1499,
      },
      {
        'rank_code': 'H+',
        'rank_order': 6,
        'rank_name': 'Master Worker',
        'rank_name_vi': 'Thợ chính',
        'rank_color': '#673AB7',
        'elo_min': 1500,
        'elo_max': 1599,
      },
      {
        'rank_code': 'G',
        'rank_order': 7,
        'rank_name': 'Skilled Worker',
        'rank_name_vi': 'Thợ giỏi',
        'rank_color': '#FF9800',
        'elo_min': 1600,
        'elo_max': 1699,
      },
      {
        'rank_code': 'G+',
        'rank_order': 8,
        'rank_name': 'Master Craftsman',
        'rank_name_vi': 'Thợ cả',
        'rank_color': '#FF5722',
        'elo_min': 1700,
        'elo_max': 1799,
      },
      {
        'rank_code': 'F',
        'rank_order': 9,
        'rank_name': 'Expert',
        'rank_name_vi': 'Chuyên gia',
        'rank_color': '#F44336',
        'elo_min': 1800,
        'elo_max': 1899,
      },
      {
        'rank_code': 'E',
        'rank_order': 10,
        'rank_name': 'Master',
        'rank_name_vi': 'Cao thủ',
        'rank_color': '#D32F2F',
        'elo_min': 1900,
        'elo_max': 1999,
      },
      {
        'rank_code': 'D',
        'rank_order': 11,
        'rank_name': 'Legend',
        'rank_name_vi': 'Huyền Thoại',
        'rank_color': '#795548',
        'elo_min': 2000,
        'elo_max': 2099,
      },
      {
        'rank_code': 'C',
        'rank_order': 12,
        'rank_name': 'Champion',
        'rank_name_vi': 'Vô địch',
        'rank_color': '#FFD700',
        'elo_min': 2100,
        'elo_max': 2199,
      },
    ];

    final insertResponse = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rank_system'),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: jsonEncode(ranks),
    );

    if (insertResponse.statusCode == 201) {
      print('✅ Inserted 12 ranks\n');
    } else {
      print('⚠️  Insert status: ${insertResponse.statusCode}');
      print('   ${insertResponse.body}\n');
    }

    // Verification
    print('=' * 70);
    print('🎉 MIGRATION COMPLETED!\n');
    print('Verifying...\n');

    final verifyResponse = await http.get(
      Uri.parse(
        '$supabaseUrl/rest/v1/rank_system?select=rank_code,rank_name_vi,elo_min,elo_max&order=rank_order.asc',
      ),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
      },
    );

    if (verifyResponse.statusCode == 200) {
      final ranksResult = jsonDecode(verifyResponse.body) as List;
      print('📊 Rank System (${ranksResult.length} ranks):');
      for (var rank in ranksResult) {
        print(
          '  ${rank['rank_code'].toString().padRight(4)} ${rank['elo_min']}-${rank['elo_max']} (${rank['rank_name_vi']})',
        );
      }
    }

    print('\n✅ ALL DONE! Rank system updated successfully!');
    print('\n⚠️  NOTE: You still need to run the SQL file manually for:');
    print('   - ALTER TABLE statements (allow NULL)');
    print('   - CREATE FUNCTION statements');
    print('   - CREATE TRIGGER statements');
    print('\n📄 Run this in Supabase SQL Editor:');
    print('   scripts/update_rank_system_new.sql (lines 41-203)');
    print('=' * 70);
  }

  static Future<void> _loadCredentials() async {
    final envFile = File('.env');
    final lines = await envFile.readAsLines();

    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        supabaseUrl = line.split('=')[1].trim();
      } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        serviceRoleKey = line.split('=')[1].trim();
      }
    }

    print('✅ Connected to: $supabaseUrl\n');
  }
}

void main() async {
  try {
    await RunRankMigrationRest.run();
  } catch (e, stackTrace) {
    print('\n❌ Migration failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
