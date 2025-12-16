import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Script to cleanup demo users from old Supabase
///
/// This will DELETE users matching demo patterns:
/// - demo*.billiards.vn
/// - *@temp.demo
/// - Empty emails
///
/// IMPORTANT: This is DESTRUCTIVE! Review before running!

class DemoUserCleanup {
  // Old Supabase (Web platform)
  static const String oldSupabaseUrl =
      'https://exlqvlbawytbglioqfbc.supabase.co';
  static const String oldSupabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bHF2bGJhd3l0YmdsaW9xZmJjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4MDA4OCwiZXhwIjoyMDY4NjU2MDg4fQ.8oZlR-lyaDdGZ_mvvyH2wJsJbsD0P6MT9ZkiyASqLcQ';

  static Future<void> cleanup({bool dryRun = true}) async {
    print('🧹 Starting Demo User Cleanup...\n');

    if (dryRun) {
      print('⚠️  DRY RUN MODE - No users will be deleted');
      print('   Set dryRun=false to actually delete\n');
    } else {
      print('🔴 LIVE MODE - Users WILL BE DELETED!');
      print('   Press Ctrl+C within 5 seconds to cancel...\n');
      await Future.delayed(Duration(seconds: 5));
    }

    // Step 1: Fetch all users
    print('📥 Fetching users from old Supabase...');
    final allUsers = await _fetchAllUsers();
    print('✅ Found ${allUsers.length} total users\n');

    // Step 2: Identify demo users
    print('🔍 Identifying demo users...');
    final demoUsers = _identifyDemoUsers(allUsers);
    final realUsers = allUsers.length - demoUsers.length;

    print('📊 Analysis:');
    print('   Total users: ${allUsers.length}');
    print('   Demo users: ${demoUsers.length}');
    print('   Real users: $realUsers\n');

    if (demoUsers.isEmpty) {
      print('✅ No demo users found!');
      return;
    }

    // Step 3: Show demo users
    print('🗑️  Demo users to be deleted:');
    for (var i = 0; i < demoUsers.length && i < 10; i++) {
      final user = demoUsers[i];
      print('   - ${user['email'] ?? '(no email)'} (${user['id']})');
    }
    if (demoUsers.length > 10) {
      print('   ... and ${demoUsers.length - 10} more');
    }
    print('');

    // Step 4: Delete demo users
    if (!dryRun) {
      print('🗑️  Deleting demo users...');
      int successCount = 0;
      int failCount = 0;

      for (var i = 0; i < demoUsers.length; i++) {
        final user = demoUsers[i];
        final email = user['email'] ?? '(no email)';

        print('[$i/${demoUsers.length}] Deleting: $email');

        try {
          await _deleteUser(user['id']);
          successCount++;
          print('  ✅ Deleted\n');
        } catch (e) {
          failCount++;
          print('  ❌ Failed: $e\n');
        }

        // Rate limiting
        await Future.delayed(Duration(milliseconds: 300));
      }

      print('\n' + '=' * 50);
      print('🎉 Cleanup Complete!');
      print('=' * 50);
      print('✅ Deleted: $successCount');
      print('❌ Failed: $failCount');
      print('📊 Remaining: $realUsers real users');
      print('=' * 50);
    } else {
      print('✅ Dry run complete - no users deleted');
      print('   Run with dryRun=false to actually delete');
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchAllUsers() async {
    List<Map<String, dynamic>> allUsers = [];
    int page = 1;
    const perPage = 100;

    while (true) {
      final response = await http.get(
        Uri.parse(
          '$oldSupabaseUrl/auth/v1/admin/users?page=$page&per_page=$perPage',
        ),
        headers: {
          'apikey': oldSupabaseKey,
          'Authorization': 'Bearer $oldSupabaseKey',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }

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

  static List<Map<String, dynamic>> _identifyDemoUsers(
    List<Map<String, dynamic>> users,
  ) {
    return users.where((user) {
      final email = user['email'] as String?;

      if (email == null || email.isEmpty) {
        return true; // Delete users with no email
      }

      // Demo patterns
      if (email.contains('@demo.billiards.vn')) return true;
      if (email.contains('@temp.demo')) return true;
      if (email.startsWith('demo')) return true;
      if (email.contains('_demo')) return true;
      if (email.contains('test@')) return true;

      return false;
    }).toList();
  }

  static Future<void> _deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('$oldSupabaseUrl/auth/v1/admin/users/$userId'),
      headers: {
        'apikey': oldSupabaseKey,
        'Authorization': 'Bearer $oldSupabaseKey',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete: ${response.statusCode} ${response.body}',
      );
    }
  }
}

void main(List<String> args) async {
  try {
    // Default: dry run (safe)
    // To actually delete: dart run scripts/cleanup_demo_users.dart --delete
    final shouldDelete = args.contains('--delete');

    await DemoUserCleanup.cleanup(dryRun: !shouldDelete);
  } catch (e) {
    print('\n❌ Cleanup failed: $e');
    exit(1);
  }
}
