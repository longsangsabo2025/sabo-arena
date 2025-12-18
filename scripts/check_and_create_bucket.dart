import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Check and create storage bucket using Service Role Key

class CheckAndCreateBucket {
  static String supabaseUrl = '';
  static String serviceRoleKey = '';

  static Future<void> run() async {
    print('🚀 CHECKING SUPABASE STORAGE BUCKETS...\n');

    await _loadCredentials();

    // Step 1: List buckets
    print('Step 1: Listing existing buckets...');
    final buckets = await _listBuckets();
    final bucketNames = buckets.map((b) => b['name']).toList();
    print('   Found buckets: $bucketNames');

    // Step 2: Check for 'club_documents'
    if (bucketNames.contains('club_documents')) {
      print('✅ Bucket "club_documents" already exists.');
      
      // Optional: Check if it is public
      final bucket = buckets.firstWhere((b) => b['name'] == 'club_documents');
      if (bucket['public'] == true) {
        print('   - Public access: ENABLED');
      } else {
        print('   ⚠️ Public access: DISABLED (You might want to enable this for easy access)');
        // We could try to update it, but let's just warn for now.
        await _updateBucketPublic('club_documents', true);
      }

    } else {
      print('❌ Bucket "club_documents" NOT FOUND.');
      
      // Step 3: Create bucket
      print('Step 3: Creating bucket "club_documents"...');
      await _createBucket('club_documents', public: true);
      print('✅ Bucket "club_documents" created successfully!');
    }

    print('\n✅ STORAGE CHECK COMPLETED!');
    print('=' * 70);
  }

  static Future<void> _loadCredentials() async {
    final envFile = File('.env');
    if (!await envFile.exists()) {
      throw Exception('.env file not found');
    }
    final lines = await envFile.readAsLines();

    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        supabaseUrl = line.substring('SUPABASE_URL='.length).trim();
      } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        serviceRoleKey = line.substring('SUPABASE_SERVICE_ROLE_KEY='.length).trim();
      }
    }

    if (supabaseUrl.isEmpty || serviceRoleKey.isEmpty) {
      throw Exception('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
    }

    print('✅ Connected to: $supabaseUrl');
  }

  static Future<List<dynamic>> _listBuckets() async {
    final response = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket'),
      headers: {
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list buckets: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<void> _createBucket(String name, {bool public = false}) async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/storage/v1/bucket'),
      headers: {
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'public': public,
        'file_size_limit': 5242880, // 5MB
        'allowed_mime_types': ['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create bucket: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> _updateBucketPublic(String name, bool public) async {
    print('   - Attempting to update public status...');
    final response = await http.put(
      Uri.parse('$supabaseUrl/storage/v1/bucket/$name'),
      headers: {
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'public': public,
      }),
    );

    if (response.statusCode == 200) {
      print('   ✅ Updated public status to: $public');
    } else {
      print('   ⚠️ Failed to update bucket: ${response.statusCode} - ${response.body}');
    }
  }
}

void main() async {
  try {
    await CheckAndCreateBucket.run();
  } catch (e) {
    print('\n❌ Operation failed: $e');
    exit(1);
  }
}
