import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Reset all existing users to NULL rank and elo

class ResetUsersToNullRank {
  static String supabaseUrl = '';
  static String serviceRoleKey = '';

  static Future<void> reset({bool dryRun = true}) async {
    print('🔄 RESETTING USERS TO NULL RANK/ELO...\n');

    if (dryRun) {
      print('⚠️  DRY RUN MODE - No changes will be made');
      print('   Run with --reset to actually update\n');
    } else {
      print('🔴 LIVE MODE - Will reset all users!');
      print('   Press Ctrl+C within 3 seconds to cancel...\n');
      await Future.delayed(Duration(seconds: 3));
    }

    await _loadCredentials();

    // Get all users
    print('📥 Fetching all users...');
    final users = await _fetchAllUsers();
    print('✅ Found ${users.length} users\n');

    if (users.isEmpty) {
      print('⚠️  No users found!');
      return;
    }

    // Show preview
    print('📋 Users to reset (first 10):');
    print('=' * 70);
    for (var i = 0; i < users.length && i < 10; i++) {
      final user = users[i];
      print('${i + 1}. ${user['email']}');
      print('   Current: rank=${user['rank']}, elo=${user['elo_rating']}');
      print('   → Will set: rank=NULL, elo=NULL');
      print('');
    }
    if (users.length > 10) {
      print('... and ${users.length - 10} more');
    }
    print('=' * 70);
    print('');

    if (!dryRun) {
      print('🔄 Resetting users...\n');

      // Use SQL to update all at once
      final sql = 'UPDATE public.users SET rank = NULL, elo_rating = NULL;';

      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/exec_sql'),
        headers: {
          'apikey': serviceRoleKey,
          'Authorization': 'Bearer $serviceRoleKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'query': sql}),
      );

      if (response.statusCode == 200) {
        print('✅ All users reset successfully!\n');
      } else {
        print('❌ Failed: ${response.statusCode}');
        print('   ${response.body}\n');
      }

      // Verify
      print('Verifying...');
      final verifyUsers = await _fetchAllUsers();
      final nullCount = verifyUsers
          .where((u) => u['rank'] == null && u['elo_rating'] == null)
          .length;

      print('=' * 50);
      print('🎉 Reset Complete!');
      print('=' * 50);
      print('Total users:     ${verifyUsers.length}');
      print('✅ NULL rank/elo: $nullCount');
      print('=' * 50);
    } else {
      print('✅ Dry run complete');
      print('   Would reset: ${users.length} users');
      print('   Run with --reset to actually update');
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

  static Future<List<Map<String, dynamic>>> _fetchAllUsers() async {
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/users?select=id,email,rank,elo_rating'),
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
}

void main(List<String> args) async {
  try {
    final shouldReset = args.contains('--reset');
    await ResetUsersToNullRank.reset(dryRun: !shouldReset);
  } catch (e) {
    print('\n❌ Reset failed: $e');
    exit(1);
  }
}
