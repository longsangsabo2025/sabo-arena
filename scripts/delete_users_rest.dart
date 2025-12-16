import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🗑️  DELETING ALL USERS VIA REST API...\n');

  // Load credentials
  final envFile = File('.env');
  final lines = await envFile.readAsLines();

  String url = '';
  String key = '';

  for (var line in lines) {
    if (line.startsWith('SUPABASE_URL=')) {
      url = line.split('=')[1].trim();
    } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
      key = line.split('=')[1].trim();
    }
  }

  print('Connected: $url\n');

  // Get all user IDs
  print('📥 Fetching users...');
  final getResponse = await http.get(
    Uri.parse('$url/rest/v1/users?select=id'),
    headers: {'apikey': key, 'Authorization': 'Bearer $key'},
  );

  if (getResponse.statusCode != 200) {
    print('❌ Failed to fetch: ${getResponse.statusCode}');
    exit(1);
  }

  final users = jsonDecode(getResponse.body) as List;
  print('✅ Found ${users.length} users\n');

  if (users.isEmpty) {
    print('✅ No users to delete!');
    exit(0);
  }

  // Delete each user
  print('🗑️  Deleting users...\n');
  int deleted = 0;
  int failed = 0;

  for (var i = 0; i < users.length; i++) {
    final userId = users[i]['id'];
    print('[${i + 1}/${users.length}] Deleting: $userId');

    try {
      final deleteResponse = await http.delete(
        Uri.parse('$url/rest/v1/users?id=eq.$userId'),
        headers: {
          'apikey': key,
          'Authorization': 'Bearer $key',
          'Prefer': 'return=minimal',
        },
      );

      if (deleteResponse.statusCode == 200 ||
          deleteResponse.statusCode == 204) {
        deleted++;
        print('  ✅ Deleted');
      } else {
        failed++;
        print('  ❌ Failed: ${deleteResponse.statusCode}');
      }
    } catch (e) {
      failed++;
      print('  ❌ Error: $e');
    }

    await Future.delayed(Duration(milliseconds: 100));
  }

  print('\n' + '=' * 70);
  print('🎉 Complete!');
  print('=' * 70);
  print('Total:    ${users.length}');
  print('✅ Deleted: $deleted');
  print('❌ Failed:  $failed');
  print('=' * 70);

  // Verify
  print('\n📊 Verifying...');
  final verifyResponse = await http.get(
    Uri.parse('$url/rest/v1/users?select=id'),
    headers: {'apikey': key, 'Authorization': 'Bearer $key'},
  );

  if (verifyResponse.statusCode == 200) {
    final remaining = jsonDecode(verifyResponse.body) as List;
    print('Remaining users: ${remaining.length}');

    if (remaining.isEmpty) {
      print('\n🎉 All users deleted successfully!');
    }
  }
}
