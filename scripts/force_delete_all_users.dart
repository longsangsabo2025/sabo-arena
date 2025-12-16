import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Force delete ALL users - no foreign key constraints since tables are empty

class ForceDeleteAllUsers {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> deleteAll({bool dryRun = true}) async {
    print('🗑️  FORCE DELETE ALL USERS...\n');

    if (dryRun) {
      print('⚠️  DRY RUN MODE');
      print('   Set dryRun=false to actually delete\n');
    } else {
      print('🔴 LIVE MODE - DELETING ALL USERS!');
      print('   Press Ctrl+C within 5 seconds to cancel...\n');
      await Future.delayed(Duration(seconds: 5));
    }

    await _loadCredentials();

    // Fetch all users
    print('📥 Fetching all users...');
    final users = await _fetchAllUsers();
    print('✅ Found ${users.length} users\n');

    if (users.isEmpty) {
      print('✅ No users to delete!');
      return;
    }

    if (!dryRun) {
      print('🗑️  Deleting users...\n');
      int successCount = 0;
      int failCount = 0;

      for (var i = 0; i < users.length; i++) {
        final user = users[i];
        final email = user['email'] ?? '(no email)';
        final userId = user['id'];

        print('[${i + 1}/${users.length}] Deleting: $email');

        try {
          await _deleteUser(userId);
          successCount++;
          print('  ✅ Deleted');
        } catch (e) {
          failCount++;
          print('  ❌ Failed: $e');
        }

        // Rate limiting
        if (i % 10 == 0 && i > 0) {
          await Future.delayed(Duration(milliseconds: 200));
        }
      }

      // Final count
      print('\n📊 Counting remaining users...');
      final finalCount = await _countUsers();

      print('\n' + '=' * 50);
      print('🎉 Delete Complete!');
      print('=' * 50);
      print('Before:          ${users.length} users');
      print('✅ Deleted:      $successCount users');
      print('❌ Failed:       $failCount users');
      print('After:           $finalCount users');
      print('=' * 50);

      if (finalCount == 0) {
        print('\n✅ DATABASE IS NOW CLEAN!');
        print('✅ Ready to restore 55 users from backup!');
      }
    } else {
      print('✅ Dry run complete');
      print('   Would delete: ${users.length} users');
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

  static Future<void> _deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('$newSupabaseUrl/auth/v1/admin/users/$userId'),
      headers: {
        'apikey': newSupabaseServiceKey,
        'Authorization': 'Bearer $newSupabaseServiceKey',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed: ${response.statusCode}');
    }
  }

  static Future<int> _countUsers() async {
    int total = 0;
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
      List users = [];

      if (data is Map && data.containsKey('users')) {
        users = data['users'] as List;
      } else if (data is List) {
        users = data;
      }

      if (users.isEmpty) break;
      total += users.length;
      if (users.length < perPage) break;

      page++;
    }

    return total;
  }
}

void main(List<String> args) async {
  try {
    final shouldDelete = args.contains('--delete');
    await ForceDeleteAllUsers.deleteAll(dryRun: !shouldDelete);
  } catch (e) {
    print('\n❌ Delete failed: $e');
    exit(1);
  }
}
