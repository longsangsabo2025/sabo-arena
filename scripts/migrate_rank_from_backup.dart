import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Migrate rank data from backup file to new database

class MigrateRankFromBackup {
  static String newSupabaseUrl = '';
  static String newServiceRoleKey = '';

  static Future<void> migrate({bool dryRun = true}) async {
    print('🔄 MIGRATING RANK DATA FROM BACKUP...\n');

    if (dryRun) {
      print('⚠️  DRY RUN MODE - No changes will be made');
      print('   Run with --migrate to actually update\n');
    } else {
      print('🔴 LIVE MODE - Will update ranks!');
      print('   Press Ctrl+C within 3 seconds to cancel...\n');
      await Future.delayed(Duration(seconds: 3));
    }

    await _loadCredentials();

    // Step 1: Load backup file
    print('📂 Loading backup file...');
    final backupFile = File(
      'old_supabase_users_backup_1760846487393_cleaned.json',
    );

    if (!backupFile.existsSync()) {
      print('❌ Backup file not found!');
      return;
    }

    final backupContent = await backupFile.readAsString();
    final backupData = jsonDecode(backupContent) as Map<String, dynamic>;
    final backupUsers = backupData['users'] as List;
    print('✅ Loaded ${backupUsers.length} users from backup\n');

    // Step 2: Fetch users from NEW database
    print('📥 Fetching users from NEW database...');
    final newUsers = await _fetchNewUsers();
    print('✅ Found ${newUsers.length} users in new DB\n');

    // Step 3: Match users by email and prepare updates
    print('🔍 Matching users by email...');
    final updates = <Map<String, dynamic>>[];

    for (var backupUser in backupUsers) {
      final userData = backupUser['user_metadata'] as Map<String, dynamic>?;
      if (userData == null) continue;

      final email = userData['email'] as String?;
      if (email == null) continue;

      // Find matching user in new DB
      final newUser = newUsers.firstWhere(
        (u) => u['email'] == email,
        orElse: () => <String, dynamic>{},
      );

      if (newUser.isEmpty) continue;

      // Get rank/elo from backup user_metadata
      final oldRank = userData['rank'] as String?;
      final oldElo = userData['elo_rating'] as int?;

      // Only migrate if backup user has rank/elo
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
      print('⚠️  No users need rank migration!');
      return;
    }

    // Step 4: Show preview
    print('📋 Users to update (first 10):');
    print('=' * 80);
    for (var i = 0; i < updates.length && i < 10; i++) {
      final user = updates[i];
      print('${i + 1}. ${user['email']}');
      print(
        '   OLD (backup): rank=${user['old_rank']}, elo=${user['old_elo']}',
      );
      print(
        '   NEW (current): rank=${user['new_rank']}, elo=${user['new_elo']}',
      );
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

  static Future<void> _loadCredentials() async {
    final envFile = File('.env');
    final lines = await envFile.readAsLines();

    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        newSupabaseUrl = line.split('=')[1].trim();
      } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        newServiceRoleKey = line.split('=')[1].trim();
      }
    }

    print('✅ Loaded credentials\n');
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
      throw Exception('Failed to fetch users: ${response.statusCode}');
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
    await MigrateRankFromBackup.migrate(dryRun: !shouldMigrate);
  } catch (e) {
    print('\n❌ Migration failed: $e');
    exit(1);
  }
}
