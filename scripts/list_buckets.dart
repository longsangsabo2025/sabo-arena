import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';
  
  final client = SupabaseClient(url, key);
  
  try {
    final buckets = await client.storage.listBuckets();
    print('Buckets:');
    for (final bucket in buckets) {
      print('- ${bucket.id} (public: ${bucket.public})');
    }
  } catch (e) {
    print('Error: $e');
  }
}
