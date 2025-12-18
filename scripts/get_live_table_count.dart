import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  // Using Service Role Key for maximum visibility
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';

  print('🚀 Elon Musk is querying the Supabase Matrix (Live)...');
  print('📡 Target: $url');

  // The Supabase REST API root returns the OpenAPI description of the exposed schema
  final apiUrl = Uri.parse('$url/rest/v1/?apikey=$key');

  try {
    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final Map<String, dynamic> spec = jsonDecode(response.body);
      final definitions = spec['definitions'] as Map<String, dynamic>?;

      if (definitions != null) {
        final tables = definitions.keys.toList();
        tables.sort();
        
        print('\n✅ LIVE SCAN COMPLETE.');
        print('📊 Total Tables Detected: ${tables.length}');
        print('----------------------------------------');
        for (var i = 0; i < tables.length; i++) {
          print('${i + 1}. ${tables[i]}');
        }
        print('----------------------------------------');
        print('Note: This list includes all tables exposed via the Postgrest API (public schema).');
      } else {
        print('⚠️ No definitions found in OpenAPI spec.');
      }
    } else {
      print('❌ Failed to fetch schema. Status: ${response.statusCode}');
      print('Body: ${response.body}');
    }
  } catch (e) {
    print('💥 Exception: $e');
  }
}
