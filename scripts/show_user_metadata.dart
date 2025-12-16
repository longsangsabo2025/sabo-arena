import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Show user metadata structure

class ShowUserMetadata {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> show() async {
    print('🔍 SHOWING USER METADATA STRUCTURE...\n');

    await _loadCredentials();

    // Fetch first 5 users
    print('📥 Fetching users...');
    final response = await http.get(
      Uri.parse('$newSupabaseUrl/auth/v1/admin/users?per_page=5'),
      headers: {
        'apikey': newSupabaseServiceKey,
        'Authorization': 'Bearer $newSupabaseServiceKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch users: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    List users = data is Map && data.containsKey('users')
        ? data['users']
        : data;

    print('✅ Found ${users.length} users\n');

    // Show each user's structure
    for (var i = 0; i < users.length; i++) {
      final user = users[i];
      print('=' * 70);
      print('USER ${i + 1}: ${user['email']}');
      print('=' * 70);
      print('ID: ${user['id']}');
      print('Email: ${user['email']}');
      print('Email confirmed: ${user['email_confirmed_at'] != null}');
      print('');

      print('USER_METADATA:');
      final userMetadata = user['user_metadata'] as Map<String, dynamic>? ?? {};
      if (userMetadata.isEmpty) {
        print('  (empty)');
      } else {
        userMetadata.forEach((key, value) {
          print('  $key: $value');
        });
      }
      print('');

      print('APP_METADATA:');
      final appMetadata = user['app_metadata'] as Map<String, dynamic>? ?? {};
      if (appMetadata.isEmpty) {
        print('  (empty)');
      } else {
        appMetadata.forEach((key, value) {
          print('  $key: $value');
        });
      }
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
    await ShowUserMetadata.show();
  } catch (e) {
    print('\n❌ Failed: $e');
    exit(1);
  }
}
