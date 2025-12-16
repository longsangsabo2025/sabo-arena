import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// FORCE migrate remaining users with modified emails
/// Strategy: Add suffix to duplicate emails to bypass unique constraint

class ForceMigrateRemaining {
  static const String oldSupabaseUrl =
      'https://exlqvlbawytbglioqfbc.supabase.co';
  static const String oldSupabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bHF2bGJhd3l0YmdsaW9xZmJjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4MDA4OCwiZXhwIjoyMDY4NjU2MDg4fQ.8oZlR-lyaDdGZ_mvvyH2wJsJbsD0P6MT9ZkiyASqLcQ';

  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> migrate() async {
    print('🚀 FORCE MIGRATE REMAINING USERS...\n');
    print('⚠️  Will modify duplicate emails with +old suffix\n');

    // Load credentials
    await _loadCredentials();

    // Fetch users
    print('📥 Fetching users...');
    final oldUsers = await _fetchUsers(oldSupabaseUrl, oldSupabaseKey);
    final newUsers = await _fetchUsers(newSupabaseUrl, newSupabaseServiceKey);

    print('✅ OLD: ${oldUsers.length} users');
    print('✅ NEW: ${newUsers.length} users\n');

    // Find users not yet migrated
    print('🔍 Finding users not yet migrated...');
    final notMigrated = _findNotMigrated(oldUsers, newUsers);
    print('✅ Found ${notMigrated.length} users to migrate\n');

    if (notMigrated.isEmpty) {
      print('✅ All users already migrated!');
      return;
    }

    // Show list
    print('📋 Users to be migrated:');
    print('=' * 70);
    for (var i = 0; i < notMigrated.length; i++) {
      final user = notMigrated[i];
      final email = user['email'] ?? '(no email)';
      final newEmail = _modifyEmail(email, user['id']);
      print('${i + 1}. $email');
      if (newEmail != email) {
        print('   → Modified to: $newEmail');
      }
    }
    print('=' * 70);
    print('\n🚀 Starting migration...\n');

    // Migrate each
    int successCount = 0;
    int failCount = 0;
    final migratedList = <String>[];

    for (var i = 0; i < notMigrated.length; i++) {
      final user = notMigrated[i];
      final originalEmail = user['email'] as String? ?? '(no email)';
      final modifiedEmail = _modifyEmail(originalEmail, user['id']);

      print('[${i + 1}/${notMigrated.length}] Migrating: $originalEmail');
      if (modifiedEmail != originalEmail) {
        print('   Using: $modifiedEmail');
      }

      try {
        await _createUserWithModifiedEmail(user, modifiedEmail);
        successCount++;
        migratedList.add('$originalEmail → $modifiedEmail');
        print('  ✅ Created\n');
      } catch (e) {
        failCount++;
        print('  ❌ Failed: $e\n');
      }

      await Future.delayed(Duration(milliseconds: 500));
    }

    // Final count
    print('\n📊 Counting final users...');
    final finalCount = await _countUsers(newSupabaseUrl, newSupabaseServiceKey);

    // Summary
    print('\n' + '=' * 50);
    print('🎉 Migration Complete!');
    print('=' * 50);
    print('Before:          ${newUsers.length} users');
    print('Attempted:       ${notMigrated.length} users');
    print('✅ Created:      $successCount users');
    print('❌ Failed:       $failCount users');
    print('After:           $finalCount users');
    print('Difference:      +${finalCount - newUsers.length} users');
    print('=' * 50);

    // List migrated users
    if (migratedList.isNotEmpty) {
      print('\n📋 MIGRATED USERS LIST:');
      print('=' * 70);
      for (var i = 0; i < migratedList.length; i++) {
        print('${i + 1}. ${migratedList[i]}');
      }
      print('=' * 70);
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

  static Future<List<Map<String, dynamic>>> _fetchUsers(
    String url,
    String key,
  ) async {
    List<Map<String, dynamic>> allUsers = [];
    int page = 1;
    const perPage = 100;

    while (true) {
      final response = await http.get(
        Uri.parse('$url/auth/v1/admin/users?page=$page&per_page=$perPage'),
        headers: {'apikey': key, 'Authorization': 'Bearer $key'},
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

  static List<Map<String, dynamic>> _findNotMigrated(
    List<Map<String, dynamic>> oldUsers,
    List<Map<String, dynamic>> newUsers,
  ) {
    final notMigrated = <Map<String, dynamic>>[];
    final newEmails = newUsers.map((u) => u['email'] as String?).toSet();

    for (var oldUser in oldUsers) {
      final email = oldUser['email'] as String?;

      // Check if this email exists in new
      if (email != null && email.isNotEmpty && newEmails.contains(email)) {
        // This is a duplicate - need to migrate with modified email
        notMigrated.add(oldUser);
      }
    }

    return notMigrated;
  }

  static String _modifyEmail(String email, String? userId) {
    if (email.isEmpty || email == '(no email)') {
      return 'migrated_${userId?.substring(0, 8) ?? DateTime.now().millisecondsSinceEpoch}@old.migrated';
    }

    // Add +old before @
    if (email.contains('@')) {
      final parts = email.split('@');
      return '${parts[0]}+old@${parts[1]}';
    }

    return '${email}+old';
  }

  static Future<void> _createUserWithModifiedEmail(
    Map<String, dynamic> oldUser,
    String modifiedEmail,
  ) async {
    final userData = <String, dynamic>{
      'email': modifiedEmail,
      'email_confirm': oldUser['email_confirmed_at'] != null,
      'user_metadata': {
        ...oldUser['user_metadata'] as Map<String, dynamic>? ?? {},
        'original_email': oldUser['email'],
        'migrated_from_old': true,
        'old_user_id': oldUser['id'],
      },
      'app_metadata': oldUser['app_metadata'] ?? {},
    };

    // Add password
    if (oldUser['encrypted_password'] != null) {
      userData['password'] = 'TempPassword123!';
    }

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

  static Future<int> _countUsers(String url, String key) async {
    int total = 0;
    int page = 1;
    const perPage = 100;

    while (true) {
      final response = await http.get(
        Uri.parse('$url/auth/v1/admin/users?page=$page&per_page=$perPage'),
        headers: {'apikey': key, 'Authorization': 'Bearer $key'},
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

void main() async {
  try {
    await ForceMigrateRemaining.migrate();
  } catch (e) {
    print('\n❌ Failed: $e');
    exit(1);
  }
}
