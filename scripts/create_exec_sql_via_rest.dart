import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Create exec_sql function via REST API

class CreateExecSqlViaRest {
  static String supabaseUrl = '';
  static String serviceRoleKey = '';

  static Future<void> create() async {
    print('🔧 CREATING EXEC_SQL FUNCTION...\n');

    await _loadCredentials();

    print('⚠️  Unfortunately, we cannot create functions via REST API.');
    print('   Functions require SQL execution with DDL privileges.\n');

    print('📋 PLEASE RUN THIS IN SUPABASE SQL EDITOR:\n');
    print('=' * 70);
    print('''
CREATE OR REPLACE FUNCTION public.exec_sql(query TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
DECLARE
  result JSONB;
  row_count INTEGER;
BEGIN
  EXECUTE query;
  GET DIAGNOSTICS row_count = ROW_COUNT;
  result := jsonb_build_object(
    'success', true,
    'rows_affected', row_count,
    'message', 'Query executed successfully'
  );
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  result := jsonb_build_object(
    'success', false,
    'error', SQLERRM,
    'message', 'Query execution failed'
  );
  RETURN result;
END;
\$\$;

GRANT EXECUTE ON FUNCTION public.exec_sql(TEXT) TO service_role;
''');
    print('=' * 70);

    print('\n📝 STEPS:');
    print('1. Go to Supabase Dashboard');
    print('2. Open SQL Editor');
    print('3. Copy the SQL above');
    print('4. Click "Run"');
    print(
      '5. Come back and run: dart run scripts/run_rank_system_migration.dart',
    );

    print('\n✅ Or use the file: scripts/create_exec_sql_function_new.sql');
  }

  static Future<void> _loadCredentials() async {
    final envFile = File('.env');
    final lines = await envFile.readAsLines();

    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        supabaseUrl = line.split('=')[1].trim();
      } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
        serviceRoleKey = line.split('=')[1].trim();
      }
    }

    print('✅ Connected to: $supabaseUrl\n');
  }
}

void main() async {
  try {
    await CreateExecSqlViaRest.create();
  } catch (e) {
    print('\n❌ Failed: $e');
    exit(1);
  }
}
