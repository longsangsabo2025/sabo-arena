import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  // Load env vars (simplified for script)
  final env = File('env.json').readAsStringSync();
  // Simple regex to extract keys (robust enough for this task)
  final url = RegExp(r'"SUPABASE_URL":\s*"([^"]+)"').firstMatch(env)?.group(1);
  final key = RegExp(r'"SUPABASE_ANON_KEY":\s*"([^"]+)"').firstMatch(env)?.group(1);

  if (url == null || key == null) {
    print('Error: Could not parse env.json');
    return;
  }

  await Supabase.initialize(url: url, anonKey: key);
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from('tournaments')
        .select('id, name, status, start_date, is_public')
        .order('start_date', ascending: false);

    print('--- All Tournaments ---');
    for (var t in response) {
      print('Name: ${t['name']}');
      print('  Status: ${t['status']}');
      print('  Start Date: ${t['start_date']}');
      print('  Is Public: ${t['is_public']}');
      print('-------------------------');
    }
  } catch (e) {
    print('Error fetching tournaments: $e');
  }
}
