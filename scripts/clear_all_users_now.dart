import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Clear all users immediately (no countdown)

class ClearAllUsersNow {
  static String supabaseUrl = '';
  static String serviceRoleKey = '';

  static Future<void> clear() async {
    print('🗑️  CLEARING ALL USERS (PUBLIC + AUTH)...\n');

    await _loadCredentials();

    print('📊 Counting users...');
    final publicUsers = await _fetchPublicUsers();
    print('✅ Found ${publicUsers.length} users in public.users\n');

    print('🗑️  Deleting all users...\n');

    try {
      // Delete from public.users first
      print('1. Deleting from public.users...');
      await _execSql('DELETE FROM public.users;');
      print('   ✅ Deleted\n');

      // Delete from auth.users
      print('2. Deleting from auth.users...');
      await _execSql('DELETE FROM auth.users;');
      print('   ✅ Deleted\n');

      // Verify
      print('📊 Verifying...');
      final remaining = await _fetchPublicUsers();
      print('   Remaining: ${remaining.length}');

      if (remaining.isEmpty) {
        print('\n🎉 All users deleted successfully!');
      } else {
        print('\n⚠️  ${remaining.length} users still remain!');
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

    print('✅ Connected: $supabaseUrl\n');
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
    await ClearAllUsersNow.clear();
  } catch (e) {
    print('\n❌ Failed: $e');
    exit(1);
  }
}
