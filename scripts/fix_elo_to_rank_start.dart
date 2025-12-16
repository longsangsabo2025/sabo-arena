import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Fix ELO to match rank start values

class FixEloToRankStart {
  static String supabaseUrl = '';
  static String serviceRoleKey = '';

  // Rank start ELO mapping
  static const rankStartElo = {
    'K': 1000,
    'K+': 1100,
    'I': 1200,
    'I+': 1300,
    'H': 1400,
    'H+': 1500,
    'G': 1600,
    'G+': 1700,
    'F': 1800,
    'E': 1900,
    'D': 2000,
    'C': 2100,
  };

  static Future<void> fix({bool dryRun = true}) async {
    print('🔧 FIXING ELO TO RANK START VALUES...\n');

    if (dryRun) {
      print('⚠️  DRY RUN MODE - No changes will be made');
      print('   Run with --fix to actually update\n');
    } else {
      print('🔴 LIVE MODE - Will update ELO!');
      print('   Press Ctrl+C within 3 seconds to cancel...\n');
      await Future.delayed(Duration(seconds: 3));
    }

    await _loadCredentials();

    // Fetch all users with rank
    print('📥 Fetching users with rank...');
    final users = await _fetchUsers();
    print('✅ Found ${users.length} users\n');

    if (users.isEmpty) {
      print('⚠️  No users found!');
      return;
    }

    // Prepare updates
    print('🔍 Analyzing users...');
    final updates = <Map<String, dynamic>>[];

    for (var user in users) {
      final rank = user['rank'] as String?;
      final currentElo = user['elo_rating'] as int?;

      if (rank == null || currentElo == null) continue;

      final startElo = rankStartElo[rank];
      if (startElo == null) continue;

      // Only update if ELO is different from rank start
      if (currentElo != startElo) {
        updates.add({
          'id': user['id'],
          'email': user['email'],
          'rank': rank,
          'current_elo': currentElo,
          'new_elo': startElo,
        });
      }
    }

    print('✅ Found ${updates.length} users to update\n');

    if (updates.isEmpty) {
      print('✅ All users already have correct ELO!');
      return;
    }

    // Show preview
    print('📋 Users to update (first 10):');
    print('=' * 80);
    for (var i = 0; i < updates.length && i < 10; i++) {
      final user = updates[i];
      print('${i + 1}. ${user['email']}');
      print('   Rank: ${user['rank']}');
      print('   Current ELO: ${user['current_elo']}');
      print('   → Will set to: ${user['new_elo']} (rank start)');
      print('');
    }
    if (updates.length > 10) {
      print('... and ${updates.length - 10} more');
    }
    print('=' * 80);
    print('');

    // Update users
    if (!dryRun) {
      print('🔄 Updating users...\n');
      int successCount = 0;
      int failCount = 0;

      for (var i = 0; i < updates.length; i++) {
        final user = updates[i];
        final userId = user['id'];
        final email = user['email'];
        final newElo = user['new_elo'];

        print('[${i + 1}/${updates.length}] Updating: $email');
        print('   Setting ELO to: $newElo');

        try {
          await _updateUserElo(userId, newElo);
          successCount++;
          print('  ✅ Updated\n');
        } catch (e) {
          failCount++;
          print('  ❌ Failed: $e\n');
        }

        await Future.delayed(Duration(milliseconds: 200));
      }

      print('=' * 70);
      print('🎉 Fix Complete!');
      print('=' * 70);
      print('Total users:     ${updates.length}');
      print('✅ Updated:      $successCount');
      print('❌ Failed:       $failCount');
      print('=' * 70);
    } else {
      print('✅ Dry run complete');
      print('   Would update: ${updates.length} users');
      print('   Run with --fix to actually update');
    }
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

    print('✅ Loaded credentials\n');
  }

  static Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final response = await http.get(
      Uri.parse(
        '$supabaseUrl/rest/v1/users?select=id,email,rank,elo_rating&rank=not.is.null',
      ),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch users: ${response.statusCode}');
    }

    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  static Future<void> _updateUserElo(String userId, int newElo) async {
    final response = await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/users?id=eq.$userId'),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: jsonEncode({'elo_rating': newElo}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }
  }
}

void main(List<String> args) async {
  try {
    final shouldFix = args.contains('--fix');
    await FixEloToRankStart.fix(dryRun: !shouldFix);
  } catch (e) {
    print('\n❌ Fix failed: $e');
    exit(1);
  }
}
