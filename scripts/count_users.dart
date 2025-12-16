import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Quick script to count users in both Supabase instances

void main() async {
  print('📊 Counting Users...\n');

  // Old Supabase
  const oldUrl = 'https://exlqvlbawytbglioqfbc.supabase.co';
  const oldKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bHF2bGJhd3l0YmdsaW9xZmJjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4MDA4OCwiZXhwIjoyMDY4NjU2MDg4fQ.8oZlR-lyaDdGZ_mvvyH2wJsJbsD0P6MT9ZkiyASqLcQ';

  // New Supabase
  const newUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  const newKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';

  try {
    // Count old
    print('🔍 Counting Old Supabase...');
    final oldCount = await _countUsers(oldUrl, oldKey);
    print('   Old Supabase: $oldCount users\n');

    // Count new
    print('🔍 Counting New Supabase...');
    final newCount = await _countUsers(newUrl, newKey);
    print('   New Supabase: $newCount users\n');

    // Summary
    print('=' * 50);
    print('📊 SUMMARY:');
    print('=' * 50);
    print('Old Supabase (Web):     $oldCount users');
    print('New Supabase (App):     $newCount users');
    print('Difference:             ${newCount - oldCount}');
    print('=' * 50);

    if (oldCount == newCount) {
      print('✅ Perfect sync!');
    } else if (newCount > oldCount) {
      print('⚠️  New has more users');
    } else {
      print('⚠️  Old has more users - migration needed?');
    }
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

Future<int> _countUsers(String url, String key) async {
  int total = 0;
  int page = 1;
  const perPage = 100;

  while (true) {
    final response = await http.get(
      Uri.parse('$url/auth/v1/admin/users?page=$page&per_page=$perPage'),
      headers: {'apikey': key, 'Authorization': 'Bearer $key'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed: ${response.statusCode}');
    }

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
