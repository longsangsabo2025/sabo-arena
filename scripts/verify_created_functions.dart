import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await verifyCreatedFunctions();
}

Future<void> verifyCreatedFunctions() async {
  print('🔍 VERIFYING CREATED FUNCTIONS...\n');

  const serviceRoleKey = 'sb_secret_07Grp_TTwr21BjtBKc_gtw_5qx7UPFE';
  const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';

  // Get actual function list from database
  await _listDatabaseFunctions(serviceRoleKey, supabaseUrl);

  // Test each function directly
  await _testEachFunction(serviceRoleKey, supabaseUrl);
}

Future<void> _listDatabaseFunctions(String serviceKey, String baseUrl) async {
  print('📋 LISTING ALL DATABASE FUNCTIONS:\n');

  try {
    final query = '''
      SELECT 
        p.proname as function_name,
        pg_get_function_result(p.oid) as return_type,
        pg_get_function_arguments(p.oid) as arguments,
        CASE 
          WHEN p.prokind = 'f' THEN 'FUNCTION'
          WHEN p.prokind = 'p' THEN 'PROCEDURE'
          ELSE 'OTHER'
        END as type
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname NOT LIKE 'pg_%'
        AND p.proname NOT LIKE 'information_schema_%'
      ORDER BY p.proname;
    ''';

    final response = await http.post(
      Uri.parse('$baseUrl/rest/v1/rpc/exec_sql'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serviceKey',
        'apikey': serviceKey,
      },
      body: json.encode({'query': query}),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      final functions = result['data'] as List? ?? [];

      if (functions.isEmpty) {
        print('⚠️  No functions found in database');
      } else {
        print('📊 Found ${functions.length} functions:');
        for (final func in functions) {
          print('   ✅ ${func['function_name']} (${func['type']})');
          if (func['arguments'].isNotEmpty) {
            print('      Args: ${func['arguments']}');
          }
          print('      Returns: ${func['return_type']}');
          print('');
        }
      }
    } else {
      print('❌ Could not list functions: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Error listing functions: $e');
  }
}

Future<void> _testEachFunction(String serviceKey, String baseUrl) async {
  print('\n🧪 TESTING EACH FUNCTION:\n');

  final testCases = [
    {
      'name': 'get_user_stats',
      'params': {'user_id_param': '669cd5df-240d-4e22-a23b-30364d0e51be'},
      'description': 'Get comprehensive user statistics',
    },
    {
      'name': 'get_user_by_id',
      'params': {'user_id_param': '669cd5df-240d-4e22-a23b-30364d0e51be'},
      'description': 'Get user profile by ID',
    },
    {
      'name': 'get_club_members',
      'params': {'club_id_param': '6d984e0e-601e-4fd3-9659-7077295ac3bf'},
      'description': 'Get all members of a club',
    },
    {
      'name': 'get_tournament_leaderboard',
      'params': {'tournament_id_param': '213f4d07-bac7-4f21-ad72-e5a65baeb93a'},
      'description': 'Get tournament standings',
    },
    {
      'name': 'update_comment_count',
      'params': {'post_id_param': 'f47ac10b-58cc-4372-a567-0e02b2c3d479'},
      'description': 'Update comment count for a post',
    },
    {
      'name': 'create_match',
      'params': {
        'tournament_id_param': '213f4d07-bac7-4f21-ad72-e5a65baeb93a',
        'player1_id_param': '669cd5df-240d-4e22-a23b-30364d0e51be',
        'player2_id_param': '8dc68b2e-8c94-47d7-a2d7-a70b218c32a8',
      },
      'description': 'Create a new match',
    },
  ];

  for (final test in testCases) {
    print('🔧 Testing ${test['name']}: ${test['description']}');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rest/v1/rpc/${test['name']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serviceKey',
          'apikey': serviceKey,
        },
        body: json.encode(test['params']),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('   ✅ SUCCESS');

        // Pretty print result
        if (result is Map || result is List) {
          final resultStr = const JsonEncoder.withIndent('   ').convert(result);
          final lines = resultStr.split('\n');
          if (lines.length > 10) {
            print('   Result (first 8 lines):');
            for (int i = 0; i < 8; i++) {
              print('   ${lines[i]}');
            }
            print('   ... (${lines.length - 8} more lines)');
          } else {
            print('   Result: $result');
          }
        } else {
          print('   Result: $result');
        }
      } else if (response.statusCode == 404) {
        print('   ❌ FUNCTION NOT FOUND');
      } else {
        print('   ⚠️  ERROR ${response.statusCode}');
        print('   ${response.body}');
      }
    } catch (e) {
      print('   ❌ EXCEPTION: $e');
    }
    print('');
  }
}
