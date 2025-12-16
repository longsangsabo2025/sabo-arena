import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Inspect old database structure

class InspectOldDatabase {
  static const oldSupabaseUrl = 'https://exlqvlbawytbglioqfbc.supabase.co';
  static const oldServiceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bHF2bGJhd3l0YmdsaW9xZmJjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4MDA4OCwiZXhwIjoyMDY4NjU2MDg4fQ.8oZlR-lyaDdGZ_mvvyH2wJsJbsD0P6MT9ZkiyASqLcQ';

  static Future<void> inspect() async {
    print('🔍 INSPECTING OLD DATABASE STRUCTURE...\n');
    print('Database: $oldSupabaseUrl\n');

    final commonTables = [
      'users',
      'user_profiles',
      'profiles',
      'sabo32_matches',
      'matches',
      'tournaments',
      'clubs',
      'posts',
    ];

    print('=' * 70);
    print('📊 CHECKING COMMON TABLES');
    print('=' * 70);

    final existingTables = <String>[];

    for (var table in commonTables) {
      final exists = await _checkTable(table);
      if (exists != null) {
        existingTables.add(table);
        print('✅ $table: ${exists['count']} rows');

        // Show sample data structure
        if (exists['sample'] != null) {
          print('   Sample fields:');
          final sample = exists['sample'] as Map<String, dynamic>;
          sample.forEach((key, value) {
            print('     - $key: ${value.runtimeType}');
          });
        }
        print('');
      } else {
        print('❌ $table: Not found');
      }
    }

    print('=' * 70);
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

  static Future<Map<String, dynamic>?> _checkTable(String tableName) async {
    try {
      // Try to fetch one row to check if table exists
      final response = await http.get(
        Uri.parse('$oldSupabaseUrl/rest/v1/$tableName?select=*&limit=1'),
        headers: {
          'apikey': oldServiceRoleKey,
          'Authorization': 'Bearer $oldServiceRoleKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        // Get count
        final countResponse = await http.get(
          Uri.parse('$oldSupabaseUrl/rest/v1/$tableName?select=count'),
          headers: {
            'apikey': oldServiceRoleKey,
            'Authorization': 'Bearer $oldServiceRoleKey',
            'Prefer': 'count=exact',
          },
        );

        int count = 0;
        if (countResponse.headers['content-range'] != null) {
          final range = countResponse.headers['content-range']!;
          final parts = range.split('/');
          if (parts.length > 1) {
            count = int.tryParse(parts[1]) ?? 0;
          }
        }

        return {'count': count, 'sample': data.isNotEmpty ? data[0] : null};
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

void main() async {
  try {
    await InspectOldDatabase.inspect();
  } catch (e) {
    print('\n❌ Inspection failed: $e');
    exit(1);
  }
}
