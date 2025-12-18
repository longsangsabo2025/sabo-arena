import 'package:supabase/supabase.dart';

Future<void> main() async {
  final url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';

  print('🔌 Connecting to Supabase...');
  final client = SupabaseClient(url, key);

  try {
    print('📦 Checking storage buckets...');
    final buckets = await client.storage.listBuckets();
    for (var bucket in buckets) {
      print(' - Bucket: ${bucket.name} (Public: ${bucket.public})');
    }

    final userImagesBucket = buckets.firstWhere((b) => b.name == 'user-images', orElse: () => throw Exception('Bucket user-images not found'));
    print('✅ Found user-images bucket.');

    print('📂 Checking folders in user-images...');
    final avatars = await client.storage.from('user-images').list(path: 'avatars');
    print(' - avatars/ folder has ${avatars.length} items');

    final covers = await client.storage.from('user-images').list(path: 'covers');
    print(' - covers/ folder has ${covers.length} items');

  } catch (e) {
    print('❌ Error: $e');
  }
}
