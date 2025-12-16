import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Check users table structure and data

class CheckUsersTable {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> check() async {
    print('🔍 CHECKING USERS TABLE...\n');

    await _loadCredentials();

    // Fetch users
    print('📥 Fetching users...');
    final response = await http.get(
      Uri.parse('$newSupabaseUrl/rest/v1/users?select=*&limit=10'),
      headers: {
        'apikey': newSupabaseServiceKey,
        'Authorization': 'Bearer $newSupabaseServiceKey',
      },
    );

    if (response.statusCode == 404) {
      print('❌ Table users does not exist!');
      return;
    }

    if (response.statusCode != 200) {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }

    final profiles = jsonDecode(response.body) as List;
    print('✅ Found ${profiles.length} profiles\n');

    if (profiles.isEmpty) {
      print('⚠️  Table is empty!');
      return;
    }

    // Show structure
    print('📊 TABLE STRUCTURE (first profile):');
    print('=' * 70);
    final first = profiles[0] as Map<String, dynamic>;
    first.forEach((key, value) {
      print('  $key: $value (${value.runtimeType})');
    });
    print('=' * 70);
    print('');

    // Show all profiles
    print('📋 ALL PROFILES:');
    print('=' * 70);
    for (var i = 0; i < profiles.length; i++) {
      final profile = profiles[i] as Map<String, dynamic>;
      print('${i + 1}. ID: ${profile['id']}');
      print('   username: ${profile['username']}');
      print('   display_name: ${profile['display_name']}');
      print('   full_name: ${profile['full_name'] ?? '(none)'}');
      print('');
    }
    print('=' * 70);
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

    print('✅ Connected to: $newSupabaseUrl\n');
  }
}

void main() async {
  try {
    await CheckUsersTable.check();
  } catch (e) {
    print('\n❌ Failed: $e');
    exit(1);
  }
}
