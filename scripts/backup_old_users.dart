import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Backup all users from Old Supabase to JSON file

class BackupOldUsers {
  static const String oldSupabaseUrl =
      'https://exlqvlbawytbglioqfbc.supabase.co';
  static const String oldSupabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bHF2bGJhd3l0YmdsaW9xZmJjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4MDA4OCwiZXhwIjoyMDY4NjU2MDg4fQ.8oZlR-lyaDdGZ_mvvyH2wJsJbsD0P6MT9ZkiyASqLcQ';

  static Future<void> backup() async {
    print('💾 BACKING UP USERS FROM OLD SUPABASE...\n');

    // Fetch all users
    print('📥 Fetching users...');
    final users = await _fetchAllUsers();
    print('✅ Found ${users.length} users\n');

    // Save to file
    final filename =
        'old_supabase_users_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(filename);

    print('💾 Saving to $filename...');
    await file.writeAsString(
      JsonEncoder.withIndent('  ').convert({
        'backup_date': DateTime.now().toIso8601String(),
        'source': oldSupabaseUrl,
        'total_users': users.length,
        'users': users,
      }),
    );

    print('✅ Backup saved!\n');

    // Summary
    print('=' * 50);
    print('📊 BACKUP SUMMARY');
    print('=' * 50);
    print('File:        $filename');
    print('Total users: ${users.length}');
    print('File size:   ${(await file.length() / 1024).toStringAsFixed(2)} KB');
    print('=' * 50);

    // Show sample users
    print('\n📋 Sample users (first 10):');
    for (var i = 0; i < users.length && i < 10; i++) {
      final user = users[i];
      print('${i + 1}. ${user['email'] ?? '(no email)'} - ${user['id']}');
    }

    print('\n✅ Backup complete! Ready for clean migration.');
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
}

void main() async {
  try {
    await BackupOldUsers.backup();
  } catch (e) {
    print('\n❌ Backup failed: $e');
    exit(1);
  }
}
