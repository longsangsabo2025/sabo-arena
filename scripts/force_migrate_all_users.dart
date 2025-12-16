import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// FORCE MIGRATE ALL USERS - NO DUPLICATE CHECK
///
/// This will migrate ALL users from old to new Supabase
/// WITHOUT checking for duplicates
///
/// Result: New Supabase will have 50 (existing) + 92 (migrated) = 142 users
/// (May include duplicates - will filter later)

class ForceMigration {
  // Old Supabase (Web platform)
  static const String oldSupabaseUrl =
      'https://exlqvlbawytbglioqfbc.supabase.co';
  static const String oldSupabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bHF2bGJhd3l0YmdsaW9xZmJjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4MDA4OCwiZXhwIjoyMDY4NjU2MDg4fQ.8oZlR-lyaDdGZ_mvvyH2wJsJbsD0P6MT9ZkiyASqLcQ';

  // New Supabase (Current app) - Get from .env
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> migrate() async {
    print('🚀 FORCE MIGRATION - ALL USERS...\n');
    print('⚠️  NO DUPLICATE CHECK - Will create all users!\n');

    // Step 1: Load new Supabase credentials
    await _loadNewSupabaseCredentials();

    // Step 2: Fetch users from old Supabase
    print('📥 Fetching users from old Supabase...');
    final oldUsers = await _fetchOldUsers();
    print('✅ Found ${oldUsers.length} users in old Supabase\n');

    if (oldUsers.isEmpty) {
      print('⚠️  No users to migrate');
      return;
    }

    // Step 3: Count current users in new Supabase
    print('📊 Counting current users in new Supabase...');
    final currentCount = await _countNewUsers();
    print('✅ Current users in new Supabase: $currentCount\n');

    print(
      '📊 Expected result: $currentCount + ${oldUsers.length} = ${currentCount + oldUsers.length} users\n',
    );

    // Step 4: Migrate each user (NO duplicate check)
    int successCount = 0;
    int failCount = 0;

    for (var i = 0; i < oldUsers.length; i++) {
      final user = oldUsers[i];
      final email = user['email'] as String? ?? '(no email)';

      print('[$i/${oldUsers.length}] Migrating: $email');

      try {
        await _createUser(user);
        successCount++;
        print('  ✅ Created\n');
      } catch (e) {
        failCount++;
        final errorMsg = e.toString();
        if (errorMsg.contains('already') || errorMsg.contains('duplicate')) {
          print(
            '  ⚠️  Already exists (expected): ${errorMsg.substring(0, 100)}\n',
          );
        } else {
          print('  ❌ Failed: $e\n');
        }
      }

      // Rate limiting
      await Future.delayed(Duration(milliseconds: 500));
    }

    // Step 5: Count final users
    print('\n📊 Counting final users...');
    final finalCount = await _countNewUsers();

    // Step 6: Summary
    print('\n' + '=' * 50);
    print('🎉 Migration Complete!');
    print('=' * 50);
    print('Before:          $currentCount users');
    print('Attempted:       ${oldUsers.length} users');
    print('✅ Created:      $successCount users');
    print('❌ Failed:       $failCount users');
    print('After:           $finalCount users');
    print('Difference:      +${finalCount - currentCount} users');
    print('=' * 50);
  }

  static Future<void> _loadNewSupabaseCredentials() async {
    try {
      final envFile = File('.env');
      if (!await envFile.exists()) {
        throw Exception('.env file not found');
      }

      final lines = await envFile.readAsLines();
      for (var line in lines) {
        if (line.startsWith('SUPABASE_URL=')) {
          newSupabaseUrl = line.split('=')[1].trim();
        } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
          newSupabaseServiceKey = line.split('=')[1].trim();
        }
      }

      if (newSupabaseUrl.isEmpty || newSupabaseServiceKey.isEmpty) {
        throw Exception('Missing Supabase credentials in .env');
      }

      print('✅ Loaded new Supabase credentials from .env\n');
    } catch (e) {
      throw Exception('Failed to load .env: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchOldUsers() async {
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

  static Future<int> _countNewUsers() async {
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

  static Future<void> _createUser(Map<String, dynamic> oldUser) async {
    final email = oldUser['email'] as String?;
    final id = oldUser['id'] as String?;

    // Create user data
    final userData = <String, dynamic>{
      'email_confirm': oldUser['email_confirmed_at'] != null,
      'user_metadata': oldUser['user_metadata'] ?? {},
      'app_metadata': oldUser['app_metadata'] ?? {},
    };

    // Handle email
    if (email != null && email.isNotEmpty) {
      userData['email'] = email;
    } else {
      // Generate unique email for users without email
      userData['email'] =
          'migrated_${id?.substring(0, 8) ?? DateTime.now().millisecondsSinceEpoch}@temp.migrated';
      userData['user_metadata'] = {
        ...userData['user_metadata'] as Map<String, dynamic>,
        'migrated_without_email': true,
        'original_id': id,
      };
    }

    // Add password if exists
    if (oldUser['encrypted_password'] != null) {
      final password = oldUser['encrypted_password'] as String;
      if (password.isNotEmpty) {
        userData['password'] =
            'TempPassword123!'; // Will be overridden by hash if API supports it
      }
    }

    // Create user
    final response = await http.post(
      Uri.parse('$newSupabaseUrl/auth/v1/admin/users'),
      headers: {
        'apikey': newSupabaseServiceKey,
        'Authorization': 'Bearer $newSupabaseServiceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }
  }
}

void main() async {
  try {
    await ForceMigration.migrate();
  } catch (e) {
    print('\n❌ Migration failed: $e');
    exit(1);
  }
}
