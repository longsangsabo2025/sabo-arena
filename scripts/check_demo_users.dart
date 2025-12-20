import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  // Load env.json
  final envFile = File('env.json');
  if (!envFile.existsSync()) {
    print('Error: env.json not found');
    return;
  }

  final envContent = await envFile.readAsString();
  final env = jsonDecode(envContent) as Map<String, dynamic>;

  final supabaseUrl = env['SUPABASE_URL'];
  final supabaseKey = env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    print('Error: Missing Supabase credentials in env.json');
    return;
  }

  print('Connecting to $supabaseUrl...');
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    print('Fetching users...');
    // Fetch users from 'users' table
    final response = await client
        .from('users')
        .select('id, email, full_name, display_name, created_at')
        .order('created_at', ascending: false)
        .limit(20);

    final List<dynamic> users = response as List<dynamic>;
    print('Most recent 20 users:');

    for (final user in users) {
      print('ID: ${user['id']} | Email: ${user['email']} | Name: ${user['full_name']} | Created: ${user['created_at']}');
    }

  } catch (e) {
    print('Error fetching users: $e');
  }
}
