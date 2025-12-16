import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Replace duplicate users in New Supabase with users from Old Supabase
/// Priority: Keep users from OLD database

class ReplaceDuplicateUsers {
  static const String oldSupabaseUrl =
      'https://exlqvlbawytbglioqfbc.supabase.co';
  static const String oldSupabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bHF2bGJhd3l0YmdsaW9xZmJjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4MDA4OCwiZXhwIjoyMDY4NjU2MDg4fQ.8oZlR-lyaDdGZ_mvvyH2wJsJbsD0P6MT9ZkiyASqLcQ';

  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> replace() async {
    print('🔄 REPLACING DUPLICATE USERS...\n');
    print('⚠️  Priority: Keep users from OLD database\n');

    // Load credentials
    await _loadNewSupabaseCredentials();

    // Fetch all users from both databases
    print('📥 Fetching users from OLD Supabase...');
    final oldUsers = await _fetchUsers(oldSupabaseUrl, oldSupabaseKey);
    print('✅ Found ${oldUsers.length} users in OLD\n');

    print('📥 Fetching users from NEW Supabase...');
    final newUsers = await _fetchUsers(newSupabaseUrl, newSupabaseServiceKey);
    print('✅ Found ${newUsers.length} users in NEW\n');

    // Find duplicates by email
    print('🔍 Finding duplicates...');
    final duplicates = _findDuplicates(oldUsers, newUsers);
    print('✅ Found ${duplicates.length} duplicate emails\n');

    if (duplicates.isEmpty) {
      print('✅ No duplicates to replace!');
      return;
    }

    // Show list
    print('📋 Duplicate users to be REPLACED:');
    print('=' * 70);
    for (var i = 0; i < duplicates.length; i++) {
      final dup = duplicates[i];
      print('${i + 1}. ${dup['email']}');
      print('   OLD ID: ${dup['oldId']}');
      print('   NEW ID: ${dup['newId']} (will be deleted)');
      print('');
    }
    print('=' * 70);
    print(
      '\n⚠️  Will DELETE ${duplicates.length} users from NEW and REPLACE with OLD\n',
    );

    // Confirm
    print('Press Enter to continue or Ctrl+C to cancel...');
    stdin.readLineSync();

    // Replace each duplicate
    int successCount = 0;
    int failCount = 0;

    for (var i = 0; i < duplicates.length; i++) {
      final dup = duplicates[i];
      final email = dup['email'];

      print('[${i + 1}/${duplicates.length}] Replacing: $email');

      try {
        // Step 1: Delete from NEW
        print('  🗑️  Deleting from NEW...');
        await _deleteUser(dup['newId']);

        // Step 2: Create from OLD
        print('  ➕ Creating from OLD...');
        await _createUser(dup['oldUser']);

        successCount++;
        print('  ✅ Replaced!\n');
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
    print('🎉 Replacement Complete!');
    print('=' * 50);
    print('Duplicates found:    ${duplicates.length}');
    print('✅ Replaced:         $successCount');
    print('❌ Failed:           $failCount');
    print('Final user count:    $finalCount');
    print('=' * 50);

    // List replaced users
    if (successCount > 0) {
      print('\n📋 REPLACED USERS LIST:');
      print('=' * 70);
      for (var i = 0; i < duplicates.length; i++) {
        if (i < successCount) {
          print('${i + 1}. ${duplicates[i]['email']}');
        }
      }
      print('=' * 70);
    }
  }

  static Future<void> _loadNewSupabaseCredentials() async {
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

  static List<Map<String, dynamic>> _findDuplicates(
    List<Map<String, dynamic>> oldUsers,
    List<Map<String, dynamic>> newUsers,
  ) {
    final duplicates = <Map<String, dynamic>>[];

    for (var oldUser in oldUsers) {
      final oldEmail = oldUser['email'] as String?;
      if (oldEmail == null || oldEmail.isEmpty) continue;

      // Find matching email in new users
      final newUser = newUsers.firstWhere(
        (u) => u['email'] == oldEmail,
        orElse: () => {},
      );

      if (newUser.isNotEmpty) {
        duplicates.add({
          'email': oldEmail,
          'oldId': oldUser['id'],
          'newId': newUser['id'],
          'oldUser': oldUser,
          'newUser': newUser,
        });
      }
    }

    return duplicates;
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
      throw Exception('Delete failed: ${response.statusCode}');
    }
  }

  static Future<void> _createUser(Map<String, dynamic> oldUser) async {
    final email = oldUser['email'] as String?;

    final userData = <String, dynamic>{
      'email': email,
      'email_confirm': oldUser['email_confirmed_at'] != null,
      'user_metadata': oldUser['user_metadata'] ?? {},
      'app_metadata': oldUser['app_metadata'] ?? {},
    };

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
      throw Exception('Create failed: ${response.statusCode} ${response.body}');
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
    await ReplaceDuplicateUsers.replace();
  } catch (e) {
    print('\n❌ Failed: $e');
    exit(1);
  }
}
