import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Inspect database structure - check what tables/data exist

class InspectDatabase {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> inspect() async {
    print('🔍 INSPECTING DATABASE STRUCTURE...\n');

    await _loadCredentials();

    // Check users
    print('=' * 70);
    print('👥 AUTH USERS');
    print('=' * 70);
    await _checkUsers();

    // Try to discover tables by attempting common table names
    print('\n' + '=' * 70);
    print('📊 CHECKING COMMON TABLES');
    print('=' * 70);

    final commonTables = [
      'user_profiles',
      'profiles',
      'users',
      'sabo32_matches',
      'matches',
      'tournaments',
      'tournament_registrations',
      'registrations',
      'clubs',
      'clubs_members',
      'payment_methods',
      'payments',
    ];

    final existingTables = <String>[];

    for (var table in commonTables) {
      final exists = await _checkTable(table);
      if (exists != null) {
        existingTables.add(table);
        print('✅ $table: ${exists['count']} rows');
      }
    }

    if (existingTables.isEmpty) {
      print(
        '⚠️  No common tables found - database may be empty or have different schema',
      );
    }

    // Summary
    print('\n' + '=' * 70);
    print('📊 SUMMARY');
    print('=' * 70);
    print('Existing tables: ${existingTables.length}');
    if (existingTables.isNotEmpty) {
      print('Tables found:');
      for (var table in existingTables) {
        print('  - $table');
      }
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

  static Future<void> _checkUsers() async {
    try {
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

      print('Total users: $total');

      if (total > 0) {
        print('\nSample users (first 5):');
        final response = await http.get(
          Uri.parse('$newSupabaseUrl/auth/v1/admin/users?per_page=5'),
          headers: {
            'apikey': newSupabaseServiceKey,
            'Authorization': 'Bearer $newSupabaseServiceKey',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          List users = data is Map && data.containsKey('users')
              ? data['users']
              : data;

          for (var i = 0; i < users.length; i++) {
            final user = users[i];
            print(
              '  ${i + 1}. ${user['email'] ?? '(no email)'} - ${user['id']}',
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error checking users: $e');
    }
  }

  static Future<Map<String, dynamic>?> _checkTable(String tableName) async {
    try {
      // Try to query the table
      final response = await http.get(
        Uri.parse('$newSupabaseUrl/rest/v1/$tableName?select=*&limit=0'),
        headers: {
          'apikey': newSupabaseServiceKey,
          'Authorization': 'Bearer $newSupabaseServiceKey',
          'Prefer': 'count=exact',
        },
      );

      if (response.statusCode == 200) {
        // Table exists, try to get count
        final countHeader = response.headers['content-range'];
        int count = 0;

        if (countHeader != null) {
          final parts = countHeader.split('/');
          if (parts.length > 1) {
            count = int.tryParse(parts[1]) ?? 0;
          }
        }

        return {'exists': true, 'count': count};
      } else if (response.statusCode == 404) {
        return null; // Table doesn't exist
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

void main() async {
  try {
    await InspectDatabase.inspect();
  } catch (e) {
    print('\n❌ Inspection failed: $e');
    exit(1);
  }
}
