import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Update username from display_name in users table

class UpdateUsernameFromDisplayName {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> update({bool dryRun = true}) async {
    print('🔄 UPDATING USERNAME FROM DISPLAY_NAME...\n');

    if (dryRun) {
      print('⚠️  DRY RUN MODE - No changes will be made');
      print('   Set dryRun=false to actually update\n');
    } else {
      print('🔴 LIVE MODE - Will update users table!');
      print('   Press Ctrl+C within 3 seconds to cancel...\n');
      await Future.delayed(Duration(seconds: 3));
    }

    await _loadCredentials();

    // Fetch all users
    print('📥 Fetching all users from table...');
    final users = await _fetchAllUsers();
    print('✅ Found ${users.length} users\n');

    if (users.isEmpty) {
      print('⚠️  No users found!');
      return;
    }

    // Show preview
    print('📋 Users to update (first 10):');
    print('=' * 70);
    for (var i = 0; i < users.length && i < 10; i++) {
      final user = users[i];
      print('${i + 1}. ${user['email']}');
      print('   Current username: ${user['username']}');
      print('   display_name: ${user['display_name']}');
      print('   → Will set username to: ${user['display_name']}');
      print('');
    }
    if (users.length > 10) {
      print('... and ${users.length - 10} more');
    }
    print('=' * 70);
    print('');

    // Update users
    if (!dryRun) {
      print('🔄 Updating users...\n');
      int successCount = 0;
      int failCount = 0;

      for (var i = 0; i < users.length; i++) {
        final user = users[i];
        final email = user['email'];
        final displayName = user['display_name'];
        final userId = user['id'];

        print('[${i + 1}/${users.length}] Updating: $email');
        print('   Setting username to: $displayName');

        try {
          await _updateUsername(userId, displayName);
          successCount++;
          print('  ✅ Updated\n');
        } catch (e) {
          failCount++;
          print('  ❌ Failed: $e\n');
        }

        await Future.delayed(Duration(milliseconds: 200));
      }

      print('=' * 50);
      print('🎉 Update Complete!');
      print('=' * 50);
      print('Total users:     ${users.length}');
      print('✅ Updated:      $successCount');
      print('❌ Failed:       $failCount');
      print('=' * 50);
    } else {
      print('✅ Dry run complete');
      print('   Would update: ${users.length} users');
      print('   Run with dryRun=false to actually update');
    }
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

    print('✅ Loaded credentials\n');
  }

  static Future<List<Map<String, dynamic>>> _fetchAllUsers() async {
    final response = await http.get(
      Uri.parse(
        '$newSupabaseUrl/rest/v1/users?select=id,email,username,display_name',
      ),
      headers: {
        'apikey': newSupabaseServiceKey,
        'Authorization': 'Bearer $newSupabaseServiceKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch users: ${response.statusCode}');
    }

    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  static Future<void> _updateUsername(String userId, String newUsername) async {
    final response = await http.patch(
      Uri.parse('$newSupabaseUrl/rest/v1/users?id=eq.$userId'),
      headers: {
        'apikey': newSupabaseServiceKey,
        'Authorization': 'Bearer $newSupabaseServiceKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: jsonEncode({'username': newUsername}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }
  }
}

void main(List<String> args) async {
  try {
    final shouldUpdate = args.contains('--update');
    await UpdateUsernameFromDisplayName.update(dryRun: !shouldUpdate);
  } catch (e) {
    print('\n❌ Update failed: $e');
    exit(1);
  }
}
