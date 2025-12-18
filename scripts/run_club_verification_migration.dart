import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Run club verification migration using Service Role Key

class RunClubVerificationMigration {
  static String supabaseUrl = '';
  static String serviceRoleKey = '';

  static Future<void> run() async {
    print('🚀 RUNNING CLUB VERIFICATION MIGRATION...\n');

    await _loadCredentials();

    // Step 1: Add columns to clubs table
    print('Step 1: Adding verification columns to clubs table...');
    final sql = '''
      ALTER TABLE public.clubs 
      ADD COLUMN IF NOT EXISTS business_license_url text,
      ADD COLUMN IF NOT EXISTS identity_card_url text;

      COMMENT ON COLUMN public.clubs.business_license_url IS 'URL to the business license image';
      COMMENT ON COLUMN public.clubs.identity_card_url IS 'URL to the identity card/CCCD image';
    ''';
    
    await _executeSql(sql);
    print('✅ Done\n');

    print('\n✅ ALL DONE! Club verification columns added successfully!');
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
        supabaseUrl = line.split('=')[1].trim();
      } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        serviceRoleKey = line.split('=')[1].trim();
      }
    }

    if (supabaseUrl.isEmpty || serviceRoleKey.isEmpty) {
      throw Exception('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
    }

    print('✅ Connected to: $supabaseUrl\n');
  }

  static Future<void> _executeSql(String sql) async {
    // Note: This assumes there is an RPC function 'exec_sql' or similar that accepts a query.
    // If not, we might need to use the SQL Editor in Supabase Dashboard.
    // Based on previous script, it seems 'exec_sql' RPC exists.
    
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc/exec_sql'),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'query': sql}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      // If exec_sql doesn't exist, we might get 404.
      // In that case, we can't run DDL via API easily without the specific RPC.
      // But let's try.
      throw Exception('SQL Error: ${response.statusCode} - ${response.body}');
    }
  }
}

void main() async {
  try {
    await RunClubVerificationMigration.run();
  } catch (e) {
    print('\n❌ Migration failed: $e');
    exit(1);
  }
}
