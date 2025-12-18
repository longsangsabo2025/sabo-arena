import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // Load env
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found');
    return;
  }
  
  final envLines = await envFile.readAsLines();
  String? supabaseUrl;
  String? supabaseKey;
  
  for (final line in envLines) {
    if (line.startsWith('SUPABASE_URL=')) {
      supabaseUrl = line.substring('SUPABASE_URL='.length);
    } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
      supabaseKey = line.substring('SUPABASE_ANON_KEY='.length);
    }
  }

  if (supabaseUrl == null || supabaseKey == null) {
    print('Error: SUPABASE_URL or SUPABASE_ANON_KEY not found in .env');
    return;
  }

  final headers = {
    'apikey': supabaseKey,
    'Authorization': 'Bearer $supabaseKey',
    'Content-Type': 'application/json',
    'Prefer': 'count=exact',
  };

  try {
    // 1. Count total users
    final countUrl = Uri.parse('$supabaseUrl/rest/v1/users?select=*&limit=1');
    final countResponse = await http.get(countUrl, headers: headers);
    
    if (countResponse.statusCode >= 200 && countResponse.statusCode < 300) {
      final contentRange = countResponse.headers['content-range'];
      if (contentRange != null) {
        final total = contentRange.split('/').last;
        print('Total users: $total');
      } else {
        print('Could not determine total users count from headers.');
      }
    } else {
      print('Error counting users: ${countResponse.statusCode} ${countResponse.body}');
    }

    // 2. Count active users
    final activeCountUrl = Uri.parse('$supabaseUrl/rest/v1/users?select=*&is_active=eq.true&limit=1');
    final activeCountResponse = await http.get(activeCountUrl, headers: headers);

    if (activeCountResponse.statusCode >= 200 && activeCountResponse.statusCode < 300) {
      final contentRange = activeCountResponse.headers['content-range'];
      if (contentRange != null) {
        final total = contentRange.split('/').last;
        print('Active users: $total');
      } else {
        print('Could not determine active users count from headers.');
      }
    } else {
      print('Error counting active users: ${activeCountResponse.statusCode} ${activeCountResponse.body}');
    }

    // 3. Fetch a few users to check data
    final usersUrl = Uri.parse('$supabaseUrl/rest/v1/users?select=id,display_name,is_active,latitude,longitude,rank,elo_rating&limit=5');
    final usersResponse = await http.get(usersUrl, headers: headers);

    if (usersResponse.statusCode >= 200 && usersResponse.statusCode < 300) {
      final users = jsonDecode(usersResponse.body) as List;
      print('\nSample users:');
      for (final user in users) {
        print(user);
      }
    } else {
      print('Error fetching users: ${usersResponse.statusCode} ${usersResponse.body}');
    }

  } catch (e) {
    print('Error: $e');
  }
}
