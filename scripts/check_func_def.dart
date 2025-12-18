import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  String supabaseUrl = '';
  String serviceRoleKey = '';

  for (var line in lines) {
    if (line.startsWith('SUPABASE_URL=')) {
      supabaseUrl = line.split('=')[1].trim();
    } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
      serviceRoleKey = line.split('=')[1].trim();
    }
  }

  print('Checking get_rank_from_elo definition...');
  
  final sql = "SELECT pg_get_functiondef(p.oid) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_rank_from_elo'";

  final response = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/rpc/exec_sql'),
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'query': sql}),
  );

  print('Response: ${response.body}');
}
