import 'package:supabase/supabase.dart';

Future<void> main() async {
  final supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ';

  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    print('Fetching users...');
    final response = await client.from('users').select('id, display_name, email').limit(10);
    print('Users found: ${response.length}');
    for (var user in response) {
      print('- ${user['display_name']} (${user['email']})');
    }
  } catch (e) {
    print('Error fetching users: $e');
  }
}
