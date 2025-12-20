import 'package:supabase/supabase.dart';
import 'dart:io';

Future<void> main() async {
  // Initialize Supabase
  final env = File('env.json').readAsStringSync();
  // Simple parsing for env.json to get URL and Key
  // Assuming env.json is a simple JSON object
  final urlRegex = RegExp(r'"SUPABASE_URL":\s*"([^"]+)"');
  final keyRegex = RegExp(r'"SUPABASE_ANON_KEY":\s*"([^"]+)"');
  
  final urlMatch = urlRegex.firstMatch(env);
  final keyMatch = keyRegex.firstMatch(env);

  if (urlMatch == null || keyMatch == null) {
    print('Error: Could not parse env.json');
    return;
  }

  final supabaseUrl = urlMatch.group(1)!;
  final supabaseKey = keyMatch.group(1)!;

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final response = await supabase
        .from('tournaments')
        .select('id, title, status, bracket_format')
        .ilike('title', '%test%');
    
    print('Found tournaments:');
    for (var t in response) {
      print('ID: ${t['id']} | Title: ${t['title']} | Status: ${t['status']} | Format: ${t['bracket_format']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
