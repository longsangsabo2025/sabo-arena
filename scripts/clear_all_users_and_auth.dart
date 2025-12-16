import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Clear all data from users table AND auth.users

class ClearAllUsersAndAuth {
  static String supabaseUrl = '';
  static String serviceRoleKey = '';

  static Future<void> clear() async {
    print('🗑️  CLEARING ALL USERS DATA (PUBLIC + AUTH)...\n');

    print('🔴 WARNING: This will DELETE ALL USERS from both tables!');
    print('   - public.users');
    print('   - auth.users');
    print('   Press Ctrl+C within 5 seconds to cancel...\n');
    await Future.delayed(Duration(seconds: 5));

    await _loadCredentials();

    // Step 1: Count users
    print('📊 Counting users...');
    final publicUsers = await _fetchPublicUsers();
    print('✅ Found ${publicUsers.length} users in public.users');

    // Step 2: Confirm
    print('\n⚠️  About to delete ALL USERS!');
    print('   This action CANNOT be undone!');
    print('   Waiting 3 more seconds...\n');
    await Future.delayed(Duration(seconds: 3));

    // Step 3: Delete using exec_sql (can delete from both tables)
    print('🗑️  Deleting all users...\n');

    try {
      // Delete from public.users first
      print('1. Deleting from public.users...');
      await _execSql('DELETE FROM public.users;');
      print('   ✅ Deleted from public.users\n');

      // Delete from auth.users
      print('2. Deleting from auth.users...');
      await _execSql('DELETE FROM auth.users;');
      print('   ✅ Deleted from auth.users\n');

      // Verify
      print('📊 Verifying...');
      final remaining = await _fetchPublicUsers();
      print('   Remaining in public.users: ${remaining.length}');

      if (remaining.isEmpty) {
        print('\n🎉 All users deleted successfully!');
        print('   - public.users: EMPTY ✅');
        print('   - auth.users: EMPTY ✅');
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

  static Future<List<Map<String, dynamic>>> _fetchPublicUsers() async {
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/users?select=id'),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
      },
    );

    if (response.statusCode != 200) {
      return [];
    }

    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  static Future<void> _execSql(String sql) async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc/exec_sql'),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'query': sql}),
    );

    if (response.statusCode != 200) {
      throw Exception('SQL Error: ${response.statusCode} - ${response.body}');
    }
  }
}

void main() async {
  try {
    await ClearAllUsersAndAuth.clear();
  } catch (e, stackTrace) {
    print('\n❌ Clear failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
