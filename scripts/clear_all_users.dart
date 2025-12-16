import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Clear all data from users table

class ClearAllUsers {
  static String supabaseUrl = '';
  static String serviceRoleKey = '';

  static Future<void> clear() async {
    print('🗑️  CLEARING ALL USERS DATA...\n');

    print('🔴 WARNING: This will DELETE ALL USERS!');
    print('   Press Ctrl+C within 5 seconds to cancel...\n');
    await Future.delayed(Duration(seconds: 5));

    await _loadCredentials();

    // Step 1: Count users
    print('📊 Counting users...');
    final users = await _fetchUsers();
    print('✅ Found ${users.length} users\n');

    if (users.isEmpty) {
      print('✅ No users to delete!');
      return;
    }

    // Step 2: Confirm
    print('⚠️  About to delete ${users.length} users!');
    print('   This action CANNOT be undone!');
    print('   Waiting 3 more seconds...\n');
    await Future.delayed(Duration(seconds: 3));

    // Step 3: Delete all users
    print('🗑️  Deleting all users...\n');

    try {
      await _deleteAllUsers();
      print('\n✅ All users deleted successfully!');

      // Verify
      final remaining = await _fetchUsers();
      print('📊 Remaining users: ${remaining.length}');

      if (remaining.isEmpty) {
        print('\n🎉 Users table is now empty!');
      } else {
        print('\n⚠️  Warning: ${remaining.length} users still remain!');
      }
    } catch (e) {
      print('\n❌ Delete failed: $e');
      exit(1);
    }
  }

  static Future<void> _loadCredentials() async {
    final envFile = File('.env');
    final lines = await envFile.readAsLines();

    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        supabaseUrl = line.split('=')[1].trim();
      } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        serviceRoleKey = line.split('=')[1].trim();
      }
    }

    print('✅ Connected to: $supabaseUrl\n');
  }

  static Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/users?select=id'),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch users: ${response.statusCode}');
    }

    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  static Future<void> _deleteAllUsers() async {
    // Delete all users using wildcard
    final response = await http.delete(
      Uri.parse(
        '$supabaseUrl/rest/v1/users?id=neq.00000000-0000-0000-0000-000000000000',
      ),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Prefer': 'return=minimal',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete: ${response.statusCode} ${response.body}',
      );
    }
  }
}

void main() async {
  try {
    await ClearAllUsers.clear();
  } catch (e) {
    print('\n❌ Clear failed: $e');
    exit(1);
  }
}
