import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// FORCE CLEAR New Supabase - Delete ALL data and users
///
/// ⚠️ EXTREMELY DANGEROUS - WILL DELETE EVERYTHING!
///
/// This will:
/// 1. Delete all data from related tables
/// 2. Delete all users from auth.users
///
/// Result: Clean empty database

class ForceClearNewSupabase {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> clear({bool dryRun = true}) async {
    print('🔴 FORCE CLEAR NEW SUPABASE - DELETE EVERYTHING!\n');

    if (dryRun) {
      print('⚠️  DRY RUN MODE - No data will be deleted');
      print('   Set dryRun=false to actually delete\n');
    } else {
      print('🔴🔴🔴 LIVE MODE - ALL DATA WILL BE DELETED! 🔴🔴🔴');
      print('⚠️  THIS CANNOT BE UNDONE!');
      print('⚠️  Press Ctrl+C within 10 seconds to cancel...\n');

      for (var i = 10; i > 0; i--) {
        print('   Deleting in $i seconds...');
        await Future.delayed(Duration(seconds: 1));
      }
      print('');
    }

    // Load credentials
    await _loadCredentials();

    // Count current users
    print('📊 Counting current users...');
    final userCount = await _countUsers();
    print('✅ Found $userCount users\n');

    if (userCount == 0) {
      print('✅ Database already empty!');
      return;
    }

    if (!dryRun) {
      print('🗑️  STEP 1: Deleting related data...\n');
      await _deleteRelatedData();

      print('\n🗑️  STEP 2: Deleting all users...\n');
      await _deleteAllUsers();

      // Final count
      print('\n📊 Counting final users...');
      final finalCount = await _countUsers();

      print('\n' + '=' * 50);
      print('🎉 Clear Complete!');
      print('=' * 50);
      print('Before:          $userCount users');
      print('After:           $finalCount users');
      print('Deleted:         ${userCount - finalCount} users');
      print('=' * 50);

      if (finalCount == 0) {
        print('\n✅ Database is now CLEAN and EMPTY!');
        print('✅ Ready for fresh migration!');
      } else {
        print('\n⚠️  Warning: $finalCount users still remain');
        print('   (May have additional constraints)');
      }
    } else {
      print('✅ Dry run complete');
      print('   Would delete: $userCount users + all related data');
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

  static Future<void> _deleteRelatedData() async {
    // List of tables to clear (in order to respect foreign keys)
    final tables = [
      'sabo32_matches',
      'tournament_registrations',
      'user_profiles',
      'clubs_members',
      'payment_methods',
      // Add more tables as needed
    ];

    for (var table in tables) {
      print('  Clearing table: $table');
      try {
        final response = await http.delete(
          Uri.parse(
            '$newSupabaseUrl/rest/v1/$table?id=neq.00000000-0000-0000-0000-000000000000',
          ),
          headers: {
            'apikey': newSupabaseServiceKey,
            'Authorization': 'Bearer $newSupabaseServiceKey',
            'Prefer': 'return=minimal',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          print('    ✅ Cleared');
        } else {
          print('    ⚠️  Status: ${response.statusCode} (may not exist)');
        }
      } catch (e) {
        print('    ⚠️  Error: $e (table may not exist)');
      }
    }
  }

  static Future<void> _deleteAllUsers() async {
    // Fetch all users
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

    print('  Found ${allUsers.length} users to delete\n');

    // Delete each user
    int successCount = 0;
    int failCount = 0;

    for (var i = 0; i < allUsers.length; i++) {
      final user = allUsers[i];
      final email = user['email'] ?? '(no email)';
      final userId = user['id'];

      print('  [$i/${allUsers.length}] Deleting: $email');

      try {
        final response = await http.delete(
          Uri.parse('$newSupabaseUrl/auth/v1/admin/users/$userId'),
          headers: {
            'apikey': newSupabaseServiceKey,
            'Authorization': 'Bearer $newSupabaseServiceKey',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          successCount++;
          print('    ✅ Deleted');
        } else {
          failCount++;
          print('    ❌ Failed: ${response.statusCode}');
        }
      } catch (e) {
        failCount++;
        print('    ❌ Error: $e');
      }

      // Rate limiting
      if (i % 10 == 0) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    print('\n  Summary:');
    print('    ✅ Deleted: $successCount');
    print('    ❌ Failed:  $failCount');
  }
}

void main(List<String> args) async {
  try {
    // Default: dry run (safe)
    // To actually delete: dart run scripts/force_clear_new_supabase.dart --delete
    final shouldDelete = args.contains('--delete');

    await ForceClearNewSupabase.clear(dryRun: !shouldDelete);
  } catch (e) {
    print('\n❌ Clear failed: $e');
    exit(1);
  }
}
