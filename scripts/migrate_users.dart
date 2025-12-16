import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Script to migrate users from old Supabase to new Supabase
///
/// This script will:
/// 1. Fetch all users from old Supabase
/// 2. Create users in new Supabase with same credentials
/// 3. Preserve user metadata and email verification status
///
/// IMPORTANT: Run this ONCE to avoid duplicates

class UserMigration {
  // Old Supabase (Web platform)
  static const String oldSupabaseUrl =
      'https://exlqvlbawytbglioqfbc.supabase.co';
  static const String oldSupabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bHF2bGJhd3l0YmdsaW9xZmJjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4MDA4OCwiZXhwIjoyMDY4NjU2MDg4fQ.8oZlR-lyaDdGZ_mvvyH2wJsJbsD0P6MT9ZkiyASqLcQ';

  // New Supabase (Current app) - Get from .env
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> migrate() async {
    print('🚀 Starting User Migration...\n');

    // Step 1: Load new Supabase credentials from .env
    await _loadNewSupabaseCredentials();

    // Step 2: Fetch users from old Supabase
    print('📥 Fetching users from old Supabase...');
    final oldUsers = await _fetchOldUsers();
    print('✅ Found ${oldUsers.length} users in old Supabase\n');

    if (oldUsers.isEmpty) {
      print('⚠️  No users to migrate');
      return;
    }

    // Step 3: Migrate each user
    int successCount = 0;
    int failCount = 0;

    for (var i = 0; i < oldUsers.length; i++) {
      final user = oldUsers[i];
      final email = user['email'] as String?;

      print('[$i/${oldUsers.length}] Migrating: $email');

      try {
        await _migrateUser(user);
        successCount++;
        print('  ✅ Success\n');
      } catch (e) {
        failCount++;
        print('  ❌ Failed: $e\n');
      }

      // Rate limiting - wait between requests
      await Future.delayed(Duration(milliseconds: 500));
    }

    // Step 4: Summary
    print('\n' + '=' * 50);
    print('🎉 Migration Complete!');
    print('=' * 50);
    print('✅ Success: $successCount');
    print('❌ Failed: $failCount');
    print('📊 Total: ${oldUsers.length}');
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
    try {
      List<Map<String, dynamic>> allUsers = [];
      int page = 1;
      const perPage = 100;

      while (true) {
        // Use Supabase Admin API with pagination
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
          throw Exception(
            'Failed to fetch users: ${response.statusCode} ${response.body}',
          );
        }

        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> pageUsers = [];

        // Handle both response formats
        if (data is Map && data.containsKey('users')) {
          pageUsers = List<Map<String, dynamic>>.from(data['users']);
        } else if (data is List) {
          pageUsers = List<Map<String, dynamic>>.from(data);
        }

        if (pageUsers.isEmpty) {
          break; // No more users
        }

        allUsers.addAll(pageUsers);

        // If we got less than perPage, we're done
        if (pageUsers.length < perPage) {
          break;
        }

        page++;
      }

      return allUsers;
    } catch (e) {
      throw Exception('Error fetching old users: $e');
    }
  }

  static Future<void> _migrateUser(Map<String, dynamic> oldUser) async {
    final email = oldUser['email'] as String?;
    final id = oldUser['id'] as String?;

    if (email == null || id == null) {
      throw Exception('Missing email or id');
    }

    // Check if user already exists in new Supabase
    final exists = await _userExistsInNewSupabase(email);
    if (exists) {
      print('  ⚠️  User already exists, skipping...');
      return;
    }

    // Create user in new Supabase
    final userData = {
      'email': email,
      'email_confirm': oldUser['email_confirmed_at'] != null,
      'user_metadata': oldUser['user_metadata'] ?? {},
      'app_metadata': oldUser['app_metadata'] ?? {},
    };

    // If we have the password hash, include it
    if (oldUser['encrypted_password'] != null) {
      userData['password_hash'] = oldUser['encrypted_password'];
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
      throw Exception(
        'Failed to create user: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<bool> _userExistsInNewSupabase(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$newSupabaseUrl/auth/v1/admin/users?email=$email'),
        headers: {
          'apikey': newSupabaseServiceKey,
          'Authorization': 'Bearer $newSupabaseServiceKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('users')) {
          return (data['users'] as List).isNotEmpty;
        } else if (data is List) {
          return data.isNotEmpty;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}

void main() async {
  try {
    await UserMigration.migrate();
  } catch (e) {
    print('\n❌ Migration failed: $e');
    exit(1);
  }
}
