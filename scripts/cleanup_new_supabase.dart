import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Cleanup New Supabase - Remove demo users and +old duplicates
///
/// This will DELETE:
/// 1. Demo users (@temp.demo, @demo.billiards.vn, etc.)
/// 2. Users with +old in email (duplicates)
///
/// Keep: Real users with original emails

class CleanupNewSupabase {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> cleanup({bool dryRun = true}) async {
    print('🧹 CLEANUP NEW SUPABASE...\n');

    if (dryRun) {
      print('⚠️  DRY RUN MODE - No users will be deleted');
      print('   Set dryRun=false to actually delete\n');
    } else {
      print('🔴 LIVE MODE - Users WILL BE DELETED!');
      print('   Press Ctrl+C within 5 seconds to cancel...\n');
      await Future.delayed(Duration(seconds: 5));
    }

    // Load credentials
    await _loadCredentials();

    // Fetch all users
    print('📥 Fetching users from NEW Supabase...');
    final allUsers = await _fetchAllUsers();
    print('✅ Found ${allUsers.length} total users\n');

    // Identify users to delete
    print('🔍 Identifying users to delete...');
    final toDelete = _identifyUsersToDelete(allUsers);
    final toKeep = allUsers.length - toDelete.length;

    print('📊 Analysis:');
    print('   Total users:     ${allUsers.length}');
    print('   To DELETE:       ${toDelete.length}');
    print('   To KEEP:         $toKeep\n');

    if (toDelete.isEmpty) {
      print('✅ No users to delete!');
      return;
    }

    // Show users to delete
    print('🗑️  Users to be deleted:');
    print('=' * 70);

    int demoCount = 0;
    int oldCount = 0;

    for (var i = 0; i < toDelete.length && i < 20; i++) {
      final user = toDelete[i];
      final email = user['email'] ?? '(no email)';
      final reason = _getDeleteReason(email);
      print('${i + 1}. $email ($reason)');

      if (reason == 'demo') demoCount++;
      if (reason == '+old duplicate') oldCount++;
    }

    if (toDelete.length > 20) {
      print('   ... and ${toDelete.length - 20} more');
    }

    print('');
    print('Breakdown:');
    print('   Demo users:      $demoCount');
    print('   +old duplicates: $oldCount');
    print('=' * 70);
    print('');

    // Delete users
    if (!dryRun) {
      print('🗑️  Deleting users...\n');
      int successCount = 0;
      int failCount = 0;

      for (var i = 0; i < toDelete.length; i++) {
        final user = toDelete[i];
        final email = user['email'] ?? '(no email)';

        print('[$i/${toDelete.length}] Deleting: $email');

        try {
          await _deleteUser(user['id']);
          successCount++;
          print('  ✅ Deleted\n');
        } catch (e) {
          failCount++;
          final errorMsg = e.toString();
          if (errorMsg.contains('23503') || errorMsg.contains('foreign key')) {
            print('  ⚠️  Has data, skipping (foreign key)\n');
          } else {
            print('  ❌ Failed: $e\n');
          }
        }

        await Future.delayed(Duration(milliseconds: 300));
      }

      // Final count
      print('\n📊 Counting final users...');
      final finalCount = await _countUsers();

      print('\n' + '=' * 50);
      print('🎉 Cleanup Complete!');
      print('=' * 50);
      print('Before:          ${allUsers.length} users');
      print('To delete:       ${toDelete.length} users');
      print('✅ Deleted:      $successCount users');
      print('⚠️  Skipped:      ${failCount} users (has data)');
      print('After:           $finalCount users');
      print('Removed:         ${allUsers.length - finalCount} users');
      print('=' * 50);
    } else {
      print('✅ Dry run complete - no users deleted');
      print('   Run with dryRun=false to actually delete');
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

  static List<Map<String, dynamic>> _identifyUsersToDelete(
    List<Map<String, dynamic>> users,
  ) {
    return users.where((user) {
      final email = user['email'] as String?;

      if (email == null || email.isEmpty) {
        return true; // Delete users with no email
      }

      // Delete +old duplicates
      if (email.contains('+old')) {
        return true;
      }

      // Delete demo patterns
      if (email.contains('@demo.billiards.vn')) return true;
      if (email.contains('@temp.demo')) return true;
      if (email.contains('@old.migrated')) return true;
      if (email.contains('@temp.migrated')) return true;
      if (email.startsWith('demo')) return true;
      if (email.contains('_demo')) return true;
      if (email.contains('test@')) return true;
      if (email.startsWith('migrated_')) return true;

      return false;
    }).toList();
  }

  static String _getDeleteReason(String email) {
    if (email.contains('+old')) return '+old duplicate';
    if (email.isEmpty || email == '(no email)') return 'no email';
    if (email.contains('@temp.demo')) return 'demo';
    if (email.contains('@demo.billiards.vn')) return 'demo';
    if (email.contains('@old.migrated')) return 'migrated';
    if (email.contains('@temp.migrated')) return 'migrated';
    return 'demo';
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
      throw Exception(
        'Failed to delete: ${response.statusCode} ${response.body}',
      );
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
    // Default: dry run (safe)
    // To actually delete: dart run scripts/cleanup_new_supabase.dart --delete
    final shouldDelete = args.contains('--delete');

    await CleanupNewSupabase.cleanup(dryRun: !shouldDelete);
  } catch (e) {
    print('\n❌ Cleanup failed: $e');
    exit(1);
  }
}
