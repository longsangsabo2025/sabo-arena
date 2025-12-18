import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  group('Supabase Connection Check', () {
    test('Verify env.json and Connection', () async {
      // 1. Check env.json existence
      final file = File('env.json');
      if (!file.existsSync()) {
        fail('❌ env.json file not found in project root!');
      }
      print('✅ env.json found');

      // 2. Parse env.json
      final content = await file.readAsString();
      final Map<String, dynamic> env = jsonDecode(content);
      
      final url = env['SUPABASE_URL'];
      final key = env['SUPABASE_ANON_KEY'];
      
      if (url == null || url.toString().isEmpty) {
        fail('❌ SUPABASE_URL is missing or empty in env.json');
      }
      if (key == null || key.toString().isEmpty) {
        fail('❌ SUPABASE_ANON_KEY is missing or empty in env.json');
      }
      print('✅ Credentials found in env.json');
      print('   URL: $url');

      // 3. Test Connection
      // We use the raw SupabaseClient to avoid Flutter binding initialization issues in a pure test
      // and to isolate the credential validity from the app's service logic.
      final client = SupabaseClient(url, key);
      
      try {
        print('⏳ Attempting to connect to Supabase...');
        // Query the 'users' table which we know exists
        final response = await client.from('users').select('id').limit(1);
        print('✅ Connection SUCCESSFUL!');
        print('   Query result: $response');
      } catch (e) {
        fail('❌ Connection FAILED: $e');
      }
    });
  });
}
