import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';

  print('🚀 Elon Musk is auditing Storage Buckets...');
  
  final apiUrl = Uri.parse('$url/storage/v1/bucket');

  try {
    final response = await http.get(
      apiUrl,
      headers: {
        'Authorization': 'Bearer $key',
        'apikey': key,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> buckets = jsonDecode(response.body);
      final bucketNames = buckets.map((b) => b['name'] as String).toSet();
      
      print('✅ Found ${bucketNames.length} buckets:');
      for (var name in bucketNames) {
        print('   - $name');
      }

      final requiredBuckets = {'club_assets', 'tournament_assets'};
      final missing = requiredBuckets.difference(bucketNames);

      if (missing.isNotEmpty) {
        print('\n🚨 MISSING CRITICAL BUCKETS:');
        for (var bucket in missing) {
          print('   ❌ $bucket');
          print('   🛠️ Attempting to create bucket: $bucket...');
          await createBucket(url, key, bucket);
        }
      } else {
        print('\n✅ All required buckets exist. Systems nominal.');
      }
    } else {
      print('❌ Failed to list buckets. Status: ${response.statusCode}');
      print('Body: ${response.body}');
    }
  } catch (e) {
    print('💥 Exception: $e');
  }
}

Future<void> createBucket(String url, String key, String bucketName) async {
  final apiUrl = Uri.parse('$url/storage/v1/bucket');
  try {
    final response = await http.post(
      apiUrl,
      headers: {
        'Authorization': 'Bearer $key',
        'apikey': key,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': bucketName,
        'public': true,
        'file_size_limit': 5242880, // 5MB
        'allowed_mime_types': ['image/png', 'image/jpeg', 'image/jpg']
      }),
    );

    if (response.statusCode == 200) {
      print('   ✅ Bucket "$bucketName" created successfully.');
    } else {
      print('   ❌ Failed to create bucket "$bucketName". Status: ${response.statusCode}');
      print('   Body: ${response.body}');
    }
  } catch (e) {
    print('   💥 Exception creating bucket: $e');
  }
}
