import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Migrate full_name to username in user metadata

class MigrateFullNameToUsername {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> migrate({bool dryRun = true}) async {
    print('🔄 MIGRATING FULL_NAME TO USERNAME...\n');

    if (dryRun) {
      print('⚠️  DRY RUN MODE - No changes will be made');
      print('   Set dryRun=false to actually update\n');
    } else {
      print('🔴 LIVE MODE - Will update users!');
      print('   Press Ctrl+C within 3 seconds to cancel...\n');
      await Future.delayed(Duration(seconds: 3));
    }

    await _loadCredentials();

    // Fetch all users
    print('📥 Fetching all users...');
    final users = await _fetchAllUsers();
    print('✅ Found ${users.length} users\n');

    if (users.isEmpty) {
      print('⚠️  No users found!');
      return;
    }

    // Analyze users
    print('🔍 Analyzing users...');
    final toUpdate = <Map<String, dynamic>>[];

    for (var user in users) {
      final metadata = user['user_metadata'] as Map<String, dynamic>? ?? {};
      final fullName = metadata['full_name'] as String?;
      final username = metadata['username'] as String?;

      if (fullName != null && fullName.isNotEmpty) {
        toUpdate.add({
          'id': user['id'],
          'email': user['email'],
          'full_name': fullName,
          'current_username': username,
          'metadata': metadata,
        });
      }
    }

    print('✅ Found ${toUpdate.length} users with full_name\n');

    if (toUpdate.isEmpty) {
      print('✅ No users need updating!');
      return;
    }

    // Show preview
    print('📋 Users to update (first 10):');
    print('=' * 70);
    for (var i = 0; i < toUpdate.length && i < 10; i++) {
      final user = toUpdate[i];
      print('${i + 1}. ${user['email']}');
      print('   full_name: ${user['full_name']}');
      print('   username: ${user['current_username'] ?? '(none)'}');
      print('   → Will set username to: ${user['full_name']}');
      print('');
    }
    if (toUpdate.length > 10) {
      print('... and ${toUpdate.length - 10} more');
    }
    print('=' * 70);
    print('');

    // Update users
    if (!dryRun) {
      print('🔄 Updating users...\n');
      int successCount = 0;
      int failCount = 0;

      for (var i = 0; i < toUpdate.length; i++) {
        final user = toUpdate[i];
        final email = user['email'] ?? '(no email)';
        final fullName = user['full_name'];

        print('[${i + 1}/${toUpdate.length}] Updating: $email');
        print('   Setting username to: $fullName');

        try {
          await _updateUser(user['id'], fullName, user['metadata']);
          successCount++;
          print('  ✅ Updated\n');
        } catch (e) {
          failCount++;
          print('  ❌ Failed: $e\n');
        }

        await Future.delayed(Duration(milliseconds: 300));
      }

      print('=' * 50);
      print('🎉 Migration Complete!');
      print('=' * 50);
      print('Total users:     ${users.length}');
      print('To update:       ${toUpdate.length}');
      print('✅ Updated:      $successCount');
      print('❌ Failed:       $failCount');
      print('=' * 50);
    } else {
      print('✅ Dry run complete');
      print('   Would update: ${toUpdate.length} users');
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
    List<Map<String, dynamic>> allUsers = [];
    int page = 1;
    const perPage = 100;

    while (true) {
      final response = await http.get(
        Uri.parse(
          '$newSupabaseUrl/auth/v1/admin/users?page=$page&per_page=$perPage',
        ),
        headers: {
          'apikey': newSupabaseServiceKey,
          'Authorization': 'Bearer $newSupabaseServiceKey',
        },
      );

      if (response.statusCode != 200) break;

      final data = jsonDecode(response.body);
      List<Map<String, dynamic>> pageUsers = [];

      if (data is Map && data.containsKey('users')) {
        pageUsers = List<Map<String, dynamic>>.from(data['users']);
      } else if (data is List) {
        pageUsers = List<Map<String, dynamic>>.from(data);
      }

      if (pageUsers.isEmpty) break;
      allUsers.addAll(pageUsers);
      if (pageUsers.length < perPage) break;

      page++;
    }

    return allUsers;
  }

  static Future<void> _updateUser(
    String userId,
    String username,
    Map<String, dynamic> currentMetadata,
  ) async {
    // Update user metadata: set username from display_name
    final updatedMetadata = {...currentMetadata, 'username': username};

    final response = await http.put(
      Uri.parse('$newSupabaseUrl/auth/v1/admin/users/$userId'),
      headers: {
        'apikey': newSupabaseServiceKey,
        'Authorization': 'Bearer $newSupabaseServiceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_metadata': updatedMetadata}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }
  }
}

void main(List<String> args) async {
  try {
    final shouldUpdate = args.contains('--update');
    await MigrateFullNameToUsername.migrate(dryRun: !shouldUpdate);
  } catch (e) {
    print('\n❌ Migration failed: $e');
    exit(1);
  }
}
