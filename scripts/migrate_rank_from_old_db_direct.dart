import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Migrate rank data directly from old database to new database

class MigrateRankFromOldDbDirect {
  // Old database
  static const oldSupabaseUrl = 'https://exlqvlbawytbglioqfbc.supabase.co';
  static const oldServiceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bHF2bGJhd3l0YmdsaW9xZmJjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4MDA4OCwiZXhwIjoyMDY4NjU2MDg4fQ.8oZlR-lyaDdGZ_mvvyH2wJsJbsD0P6MT9ZkiyASqLcQ';

  // New database
  static String newSupabaseUrl = '';
  static String newServiceRoleKey = '';

  static Future<void> migrate({bool dryRun = true}) async {
    print('🔄 MIGRATING RANK DATA FROM OLD DATABASE...\n');

    if (dryRun) {
      print('⚠️  DRY RUN MODE - No changes will be made');
      print('   Run with --migrate to actually update\n');
    } else {
      print('🔴 LIVE MODE - Will update ranks!');
      print('   Press Ctrl+C within 3 seconds to cancel...\n');
      await Future.delayed(Duration(seconds: 3));
    }

    await _loadNewDbCredentials();

    // Step 1: Fetch users from OLD database
    print('📥 Fetching users from OLD database...');
    final oldUsers = await _fetchOldUsers();
    print('✅ Found ${oldUsers.length} users in old DB\n');

    if (oldUsers.isEmpty) {
      print('⚠️  No users found in old database!');
      return;
    }

    // Step 2: Fetch users from NEW database
    print('📥 Fetching users from NEW database...');
    final newUsers = await _fetchNewUsers();
    print('✅ Found ${newUsers.length} users in new DB\n');

    // Step 3: Match users by email and prepare updates
    print('🔍 Matching users by email...');
    final updates = <Map<String, dynamic>>[];

    for (var oldUser in oldUsers) {
      final email = oldUser['email'] as String?;
      if (email == null) continue;

      // Find matching user in new DB
      final newUser = newUsers.firstWhere(
        (u) => u['email'] == email,
        orElse: () => <String, dynamic>{},
      );

      if (newUser.isEmpty) continue;

      final oldRank = oldUser['rank'] as String?;
      final oldElo = oldUser['elo_rating'] as int?;

      // Only migrate if old user has rank/elo
      if (oldRank != null || oldElo != null) {
        updates.add({
          'id': newUser['id'],
          'email': email,
          'old_rank': oldRank,
          'old_elo': oldElo,
          'new_rank': newUser['rank'],
          'new_elo': newUser['elo_rating'],
        });
      }
    }

    print('✅ Found ${updates.length} users to update\n');

    if (updates.isEmpty) {
      print('⚠️  No users with rank/elo found in old database!');
      print('   This might mean:');
      print('   1. Old database users table has no rank/elo data');
      print('   2. Email addresses don\'t match between databases');
      return;
    }

    // Step 4: Show preview
    print('📋 Users to update (first 10):');
    print('=' * 80);
    for (var i = 0; i < updates.length && i < 10; i++) {
      final user = updates[i];
      print('${i + 1}. ${user['email']}');
      print('   OLD: rank=${user['old_rank']}, elo=${user['old_elo']}');
      print('   NEW: rank=${user['new_rank']}, elo=${user['new_elo']}');
      print(
        '   → Will restore to: rank=${user['old_rank']}, elo=${user['old_elo']}',
      );
      print('');
    }
    if (updates.length > 10) {
      print('... and ${updates.length - 10} more');
    }
    print('=' * 80);
    print('');

    // Step 5: Update users in NEW database
    if (!dryRun) {
      print('🔄 Updating users in NEW database...\n');
      int successCount = 0;
      int failCount = 0;

      for (var i = 0; i < updates.length; i++) {
        final user = updates[i];
        final userId = user['id'];
        final email = user['email'];
        final rank = user['old_rank'];
        final elo = user['old_elo'];

        print('[${i + 1}/${updates.length}] Updating: $email');
        print('   Setting: rank=$rank, elo=$elo');

        try {
          await _updateUserRank(userId, rank, elo);
          successCount++;
          print('  ✅ Updated\n');
        } catch (e) {
          failCount++;
          print('  ❌ Failed: $e\n');
        }

        await Future.delayed(Duration(milliseconds: 200));
      }

      print('=' * 70);
      print('🎉 Migration Complete!');
      print('=' * 70);
      print('Total users:     ${updates.length}');
      print('✅ Updated:      $successCount');
      print('❌ Failed:       $failCount');
      print('=' * 70);
    } else {
      print('✅ Dry run complete');
      print('   Would update: ${updates.length} users');
      print('   Run with --migrate to actually update');
    }
  }

  static Future<void> _loadNewDbCredentials() async {
    final envFile = File('.env');
    final lines = await envFile.readAsLines();

    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        newSupabaseUrl = line.split('=')[1].trim();
      } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        newServiceRoleKey = line.split('=')[1].trim();
      }
    }

    print('✅ Connected to NEW DB: $newSupabaseUrl');
    print('✅ Connected to OLD DB: $oldSupabaseUrl\n');
  }

  static Future<List<Map<String, dynamic>>> _fetchOldUsers() async {
    final response = await http.get(
      Uri.parse(
        '$oldSupabaseUrl/rest/v1/profiles?select=email,current_rank,elo',
      ),
      headers: {
        'apikey': oldServiceRoleKey,
        'Authorization': 'Bearer $oldServiceRoleKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch old users: ${response.statusCode}');
    }

    final profiles = List<Map<String, dynamic>>.from(jsonDecode(response.body));

    // Map to expected format
    return profiles
        .map(
          (p) => {
            'email': p['email'],
            'rank': p['current_rank'],
            'elo_rating': p['elo'],
          },
        )
        .toList();
  }

  static Future<List<Map<String, dynamic>>> _fetchNewUsers() async {
    final response = await http.get(
      Uri.parse(
        '$newSupabaseUrl/rest/v1/users?select=id,email,rank,elo_rating',
      ),
      headers: {
        'apikey': newServiceRoleKey,
        'Authorization': 'Bearer $newServiceRoleKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch new users: ${response.statusCode}');
    }

    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  static Future<void> _updateUserRank(
    String userId,
    String? rank,
    int? elo,
  ) async {
    final response = await http.patch(
      Uri.parse('$newSupabaseUrl/rest/v1/users?id=eq.$userId'),
      headers: {
        'apikey': newServiceRoleKey,
        'Authorization': 'Bearer $newServiceRoleKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: jsonEncode({'rank': rank, 'elo_rating': elo}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }
  }
}

void main(List<String> args) async {
  try {
    final shouldMigrate = args.contains('--migrate');
    await MigrateRankFromOldDbDirect.migrate(dryRun: !shouldMigrate);
  } catch (e, stackTrace) {
    print('\n❌ Migration failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
