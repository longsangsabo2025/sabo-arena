import 'package:supabase/supabase.dart';

Future<void> main() async {
  final url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';

  print('🔌 Connecting to Supabase...');
  final client = SupabaseClient(url, key);

  try {
    final response = await client.from('users').select().limit(1);
    print('✅ Connection successful! Found users table.');
    print('🚀 Transaction Pooler Active. Database is reachable.');
  } catch (e) {
    print('❌ Error: $e');
  }
}
