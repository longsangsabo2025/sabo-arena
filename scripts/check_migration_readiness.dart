import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Pre-migration check script
/// Run this BEFORE migrate_users.dart to verify everything is ready

class MigrationReadinessCheck {
  static const String oldSupabaseUrl =
      'https://exlqvlbawytbglioqfbc.supabase.co';
  static const String oldSupabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bHF2bGJhd3l0YmdsaW9xZmJjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4MDA4OCwiZXhwIjoyMDY4NjU2MDg4fQ.8oZlR-lyaDdGZ_mvvyH2wJsJbsD0P6MT9ZkiyASqLcQ';

  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> check() async {
    print('🔍 Checking Migration Readiness...\n');
    print('=' * 50);

    bool allChecksPass = true;

    // Check 1: .env file exists
    print('\n1️⃣  Checking .env file...');
    if (!await _checkEnvFile()) {
      allChecksPass = false;
    }

    // Check 2: Old Supabase connection
    print('\n2️⃣  Checking old Supabase connection...');
    if (!await _checkOldSupabase()) {
      allChecksPass = false;
    }

    // Check 3: New Supabase connection
    print('\n3️⃣  Checking new Supabase connection...');
    if (!await _checkNewSupabase()) {
      allChecksPass = false;
    }

    // Check 4: Count users
    print('\n4️⃣  Counting users...');
    await _countUsers();

    // Check 5: Sample user data
    print('\n5️⃣  Checking sample user data...');
    await _checkSampleUser();

    // Summary
    print('\n' + '=' * 50);
    if (allChecksPass) {
      print('✅ ALL CHECKS PASSED!');
      print('🚀 Ready to run migration!');
      print('\nRun: dart run scripts/migrate_users.dart');
    } else {
      print('❌ SOME CHECKS FAILED!');
      print('⚠️  Fix issues before running migration');
    }
    print('=' * 50);
  }

  static Future<bool> _checkEnvFile() async {
    try {
      final envFile = File('.env');
      if (!await envFile.exists()) {
        print('  ❌ .env file not found');
        return false;
      }

      final lines = await envFile.readAsLines();
      bool hasUrl = false;
      bool hasServiceKey = false;

      for (var line in lines) {
        if (line.startsWith('SUPABASE_URL=')) {
          newSupabaseUrl = line.split('=')[1].trim();
          hasUrl = newSupabaseUrl.isNotEmpty;
        } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
          newSupabaseServiceKey = line.split('=')[1].trim();
          hasServiceKey = newSupabaseServiceKey.isNotEmpty;
        }
      }

      if (!hasUrl) {
        print('  ❌ SUPABASE_URL not found in .env');
        return false;
      }

      if (!hasServiceKey) {
        print('  ❌ SUPABASE_SERVICE_ROLE_KEY not found in .env');
        return false;
      }

      print('  ✅ .env file OK');
      print('     URL: $newSupabaseUrl');
      print('     Service Key: ${newSupabaseServiceKey.substring(0, 20)}...');
      return true;
    } catch (e) {
      print('  ❌ Error reading .env: $e');
      return false;
    }
  }

  static Future<bool> _checkOldSupabase() async {
    try {
      final response = await http
          .get(
            Uri.parse('$oldSupabaseUrl/auth/v1/health'),
            headers: {'apikey': oldSupabaseKey},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('  ✅ Old Supabase connection OK');
        return true;
      } else {
        print('  ❌ Old Supabase returned: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('  ❌ Cannot connect to old Supabase: $e');
      return false;
    }
  }

  static Future<bool> _checkNewSupabase() async {
    try {
      final response = await http
          .get(
            Uri.parse('$newSupabaseUrl/auth/v1/health'),
            headers: {'apikey': newSupabaseServiceKey},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('  ✅ New Supabase connection OK');
        return true;
      } else {
        print('  ❌ New Supabase returned: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('  ❌ Cannot connect to new Supabase: $e');
      return false;
    }
  }

  static Future<void> _countUsers() async {
    try {
      // Count old users
      final oldResponse = await http.get(
        Uri.parse('$oldSupabaseUrl/auth/v1/admin/users'),
        headers: {
          'apikey': oldSupabaseKey,
          'Authorization': 'Bearer $oldSupabaseKey',
        },
      );

      int oldCount = 0;
      if (oldResponse.statusCode == 200) {
        final data = jsonDecode(oldResponse.body);
        if (data is Map && data.containsKey('users')) {
          oldCount = (data['users'] as List).length;
        } else if (data is List) {
          oldCount = data.length;
        }
      }

      // Count new users
      final newResponse = await http.get(
        Uri.parse('$newSupabaseUrl/auth/v1/admin/users'),
        headers: {
          'apikey': newSupabaseServiceKey,
          'Authorization': 'Bearer $newSupabaseServiceKey',
        },
      );

      int newCount = 0;
      if (newResponse.statusCode == 200) {
        final data = jsonDecode(newResponse.body);
        if (data is Map && data.containsKey('users')) {
          newCount = (data['users'] as List).length;
        } else if (data is List) {
          newCount = data.length;
        }
      }

      print('  📊 Old Supabase: $oldCount users');
      print('  📊 New Supabase: $newCount users');

      if (oldCount == 0) {
        print('  ⚠️  No users to migrate from old Supabase');
      } else {
        print('  ℹ️  Will migrate $oldCount users');
      }
    } catch (e) {
      print('  ⚠️  Could not count users: $e');
    }
  }

  static Future<void> _checkSampleUser() async {
    try {
      final response = await http.get(
        Uri.parse('$oldSupabaseUrl/auth/v1/admin/users?per_page=1'),
        headers: {
          'apikey': oldSupabaseKey,
          'Authorization': 'Bearer $oldSupabaseKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List users = [];

        if (data is Map && data.containsKey('users')) {
          users = data['users'] as List;
        } else if (data is List) {
          users = data;
        }

        if (users.isNotEmpty) {
          final user = users[0];
          print('  📝 Sample user:');
          print('     Email: ${user['email']}');
          print('     ID: ${user['id']}');
          print('     Verified: ${user['email_confirmed_at'] != null}');
          print('     Created: ${user['created_at']}');

          // Check if has password hash
          if (user['encrypted_password'] != null) {
            print('     ✅ Has password hash (will be migrated)');
          } else {
            print(
              '     ⚠️  No password hash (user may need to reset password)',
            );
          }
        } else {
          print('  ⚠️  No users found');
        }
      }
    } catch (e) {
      print('  ⚠️  Could not fetch sample user: $e');
    }
  }
}

void main() async {
  try {
    await MigrationReadinessCheck.check();
  } catch (e) {
    print('\n❌ Check failed: $e');
    exit(1);
  }
}
