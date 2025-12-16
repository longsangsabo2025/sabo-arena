import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Check elo_rating logic - why is it 1200?

class CheckEloRatingLogic {
  static String newSupabaseUrl = '';
  static String newSupabaseServiceKey = '';

  static Future<void> check() async {
    print('🔍 CHECKING ELO_RATING LOGIC...\n');

    await _loadCredentials();

    // Check table schema
    print('📊 Checking table schema for elo_rating column...\n');

    final schemaQuery = '''
      SELECT 
        column_name,
        data_type,
        column_default,
        is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'users'
        AND column_name = 'elo_rating';
    ''';

    try {
      final response = await http.post(
        Uri.parse('$newSupabaseUrl/rest/v1/rpc/exec_sql'),
        headers: {
          'apikey': newSupabaseServiceKey,
          'Authorization': 'Bearer $newSupabaseServiceKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'query': schemaQuery}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('Schema info:');
        print(JsonEncoder.withIndent('  ').convert(result));
      } else {
        print('⚠️  Could not query schema via RPC');
        print('   Status: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️  RPC not available: $e');
    }

    print('\n' + '=' * 70);

    // Check actual user data
    print('\n📋 Checking actual user elo_rating values...\n');

    final usersResponse = await http.get(
      Uri.parse(
        '$newSupabaseUrl/rest/v1/users?select=id,email,elo_rating&limit=10',
      ),
      headers: {
        'apikey': newSupabaseServiceKey,
        'Authorization': 'Bearer $newSupabaseServiceKey',
      },
    );

    if (usersResponse.statusCode == 200) {
      final users = jsonDecode(usersResponse.body) as List;

      final eloValues = <int, int>{};
      for (var user in users) {
        final elo = user['elo_rating'] as int?;
        if (elo != null) {
          eloValues[elo] = (eloValues[elo] ?? 0) + 1;
        }
      }

      print('ELO Rating distribution (first 10 users):');
      eloValues.forEach((elo, count) {
        print('  $elo: $count users');
      });

      print('\nSample users:');
      for (var i = 0; i < users.length && i < 5; i++) {
        final user = users[i];
        print(
          '  ${i + 1}. ${user['email']}: elo_rating = ${user['elo_rating']}',
        );
      }
    }

    print('\n' + '=' * 70);
    print('\n💡 ANALYSIS:\n');
    print('The elo_rating = 1200 is likely coming from:');
    print('1. ✅ Database DEFAULT value (column default)');
    print('2. ✅ Trigger function (handle_new_user or similar)');
    print('3. ✅ Application code default (when creating users)');
    print('');
    print('📝 RECOMMENDATION:');
    print('If you want to change the default ELO:');
    print('1. Update database column default');
    print('2. Update trigger functions');
    print('3. Update application code defaults');
    print('=' * 70);
  }

  static Future<void> _loadCredentials() async {
    final envFile = File('.env');
    final lines = await envFile.readAsLines();

    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        newSupabaseUrl = line.split('=')[1].trim();
      } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        newSupabaseServiceKey = line.split('=')[1].trim();
      }
    }

    print('✅ Connected to: $newSupabaseUrl\n');
  }
}

void main() async {
  try {
    await CheckEloRatingLogic.check();
  } catch (e) {
    print('\n❌ Failed: $e');
    exit(1);
  }
}
