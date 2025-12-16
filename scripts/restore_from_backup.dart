import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Restore users from backup JSON to New Supabase
/// Run this AFTER clearing New Supabase

class RestoreFromBackup {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> restore(String backupFile) async {
    print('📦 RESTORING USERS FROM BACKUP...\n');

    // Load credentials
    await _loadCredentials();

    // Read backup file
    print('📂 Reading backup file: $backupFile');
    final file = File(backupFile);
    if (!await file.exists()) {
      throw Exception('Backup file not found: $backupFile');
    }

    final content = await file.readAsString();
    final backup = jsonDecode(content);

    final users = List<Map<String, dynamic>>.from(backup['users']);
    print('✅ Found ${users.length} users in backup\n');

    print('Backup info:');
    print('  Date: ${backup['backup_date']}');
    print('  Source: ${backup['source']}');
    print('  Total: ${backup['total_users']}\n');

    // Check current users in New Supabase
    print('📊 Checking New Supabase...');
    final currentCount = await _countUsers();
    print('⚠️  Current users in New Supabase: $currentCount');

    if (currentCount > 0) {
      print('\n⚠️  WARNING: New Supabase is NOT empty!');
      print('   You should clear it first to avoid duplicates.');
      print('   Continue anyway? (y/n)');
      final answer = stdin.readLineSync();
      if (answer?.toLowerCase() != 'y') {
        print('Aborted.');
        return;
      }
    }

    print('\n🚀 Starting restore...\n');

    // Restore each user
    int successCount = 0;
    int failCount = 0;

    for (var i = 0; i < users.length; i++) {
      final user = users[i];
      final email = user['email'] as String? ?? '(no email)';

      print('[${i + 1}/${users.length}] Restoring: $email');

      try {
        await _createUser(user);
        successCount++;
        print('  ✅ Created\n');
      } catch (e) {
        failCount++;
        print('  ❌ Failed: $e\n');
      }

      await Future.delayed(Duration(milliseconds: 500));
    }

    // Final count
    print('\n📊 Counting final users...');
    final finalCount = await _countUsers();

    // Summary
    print('\n' + '=' * 50);
    print('🎉 Restore Complete!');
    print('=' * 50);
    print('From backup:     ${users.length} users');
    print('✅ Created:      $successCount users');
    print('❌ Failed:       $failCount users');
    print('Final count:     $finalCount users');
    print('=' * 50);
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

  static Future<void> _createUser(Map<String, dynamic> oldUser) async {
    final email = oldUser['email'] as String?;

    final userData = <String, dynamic>{
      'email_confirm': oldUser['email_confirmed_at'] != null,
      'user_metadata': oldUser['user_metadata'] ?? {},
      'app_metadata': oldUser['app_metadata'] ?? {},
    };

    // Handle email
    if (email != null && email.isNotEmpty) {
      userData['email'] = email;
    } else {
      final id = oldUser['id'] as String?;
      userData['email'] =
          'migrated_${id?.substring(0, 8) ?? DateTime.now().millisecondsSinceEpoch}@restored.temp';
      userData['user_metadata'] = {
        ...userData['user_metadata'] as Map<String, dynamic>,
        'restored_without_email': true,
        'original_id': id,
      };
    }

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
}

void main(List<String> args) async {
  try {
    if (args.isEmpty) {
      print(
        'Usage: dart run scripts/restore_from_backup.dart <backup_file.json>',
      );
      exit(1);
    }

    await RestoreFromBackup.restore(args[0]);
  } catch (e) {
    print('\n❌ Restore failed: $e');
    exit(1);
  }
}
