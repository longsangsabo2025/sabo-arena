import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Run rank system migration using Service Role Key

class RunRankSystemMigration {
  static String supabaseUrl = '';
  static String serviceRoleKey = '';

  static Future<void> run() async {
    print('🚀 RUNNING RANK SYSTEM MIGRATION...\n');

    await _loadCredentials();

    // Step 1: Truncate rank_system table
    print('Step 1: Truncating rank_system table...');
    await _executeSql('TRUNCATE TABLE public.rank_system CASCADE;');
    print('✅ Done\n');

    // Step 2: Insert new rank system
    print('Step 2: Inserting new rank system (12 ranks)...');
    final insertSql = '''
INSERT INTO public.rank_system (rank_code, rank_value, rank_name, rank_name_vi, color_hex, elo_min, elo_max) VALUES
('K',  1,  'Starter',           'Người mới',        '#8BC34A', 1000, 1099),
('K+', 2,  'Apprentice',        'Học việc',         '#4CAF50', 1100, 1199),
('I',  3,  'Worker III',        'Thợ 3',            '#2196F3', 1200, 1299),
('I+', 4,  'Worker II',         'Thợ 2',            '#1976D2', 1300, 1399),
('H',  5,  'Worker I',          'Thợ 1',            '#9C27B0', 1400, 1499),
('H+', 6,  'Master Worker',     'Thợ chính',        '#673AB7', 1500, 1599),
('G',  7,  'Skilled Worker',    'Thợ giỏi',         '#FF9800', 1600, 1699),
('G+', 8,  'Master Craftsman',  'Thợ cả',           '#FF5722', 1700, 1799),
('F',  9,  'Expert',            'Chuyên gia',       '#F44336', 1800, 1899),
('E',  10, 'Master',            'Cao thủ',          '#D32F2F', 1900, 1999),
('D',  11, 'Legend',            'Huyền Thoại',      '#795548', 2000, 2099),
('C',  12, 'Champion',          'Vô địch',          '#FFD700', 2100, 2199);
''';
    await _executeSql(insertSql);
    print('✅ Done\n');

    // Step 3: Allow NULL for rank and elo_rating
    print('Step 3: Allowing NULL for rank and elo_rating...');
    await _executeSql(
      'ALTER TABLE public.users ALTER COLUMN rank DROP NOT NULL;',
    );
    await _executeSql(
      'ALTER TABLE public.users ALTER COLUMN elo_rating DROP NOT NULL;',
    );
    print('✅ Done\n');

    // Step 4: Remove default values
    print('Step 4: Removing default values...');
    await _executeSql(
      'ALTER TABLE public.users ALTER COLUMN rank DROP DEFAULT;',
    );
    await _executeSql(
      'ALTER TABLE public.users ALTER COLUMN elo_rating DROP DEFAULT;',
    );
    print('✅ Done\n');

    // Step 5: Update handle_new_user trigger
    print('Step 5: Updating handle_new_user trigger...');
    final triggerSql = '''
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
BEGIN
    INSERT INTO public.users (
        id, email, full_name, role, display_name, username,
        rank, elo_rating, created_at, updated_at
    )
    VALUES (
        NEW.id, NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'player')::public.user_role,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || extract(epoch from now())::bigint::text),
        NULL, NULL, NOW(), NOW()
    );
    RETURN NEW;
END;
\$\$;
''';
    await _executeSql(triggerSql);
    print('✅ Done\n');

    // Step 6: Create get_rank_from_elo function
    print('Step 6: Creating get_rank_from_elo function...');
    final getRankSql = '''
CREATE OR REPLACE FUNCTION public.get_rank_from_elo(elo INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
DECLARE
  rank_code TEXT;
BEGIN
  IF elo IS NULL THEN RETURN NULL; END IF;
  SELECT rs.rank_code INTO rank_code
  FROM public.rank_system rs
  WHERE elo >= rs.elo_min AND elo <= rs.elo_max
  ORDER BY rs.rank_value DESC LIMIT 1;
  RETURN COALESCE(rank_code, 'K');
END;
\$\$;
''';
    await _executeSql(getRankSql);
    print('✅ Done\n');

    // Step 7: Create assign_initial_rank function
    print('Step 7: Creating assign_initial_rank function...');
    final assignRankSql = '''
CREATE OR REPLACE FUNCTION public.assign_initial_rank(user_id UUID, initial_elo INTEGER DEFAULT 1000)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
DECLARE
  assigned_rank TEXT;
  result JSONB;
BEGIN
  assigned_rank := get_rank_from_elo(initial_elo);
  UPDATE public.users SET rank = assigned_rank, elo_rating = initial_elo, updated_at = NOW() WHERE id = user_id;
  SELECT jsonb_build_object('success', true, 'user_id', user_id, 'rank', assigned_rank, 'elo_rating', initial_elo, 'message', 'Initial rank assigned successfully') INTO result;
  RETURN result;
END;
\$\$;
''';
    await _executeSql(assignRankSql);
    print('✅ Done\n');

    // Step 8: Create update_user_rank trigger function
    print('Step 8: Creating update_user_rank trigger function...');
    final updateRankSql = '''
CREATE OR REPLACE FUNCTION public.update_user_rank()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
DECLARE new_rank TEXT;
BEGIN
  IF NEW.elo_rating IS NOT NULL AND (OLD.elo_rating IS NULL OR NEW.elo_rating != OLD.elo_rating) THEN
    new_rank := get_rank_from_elo(NEW.elo_rating);
    NEW.rank := new_rank;
  END IF;
  RETURN NEW;
END;
\$\$;
''';
    await _executeSql(updateRankSql);
    print('✅ Done\n');

    // Step 9: Create trigger
    print('Step 9: Creating trigger...');
    await _executeSql(
      'DROP TRIGGER IF EXISTS trigger_update_user_rank ON public.users;',
    );
    await _executeSql(
      'CREATE TRIGGER trigger_update_user_rank BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_user_rank();',
    );
    print('✅ Done\n');

    // Step 10: Create user_has_rank function
    print('Step 10: Creating user_has_rank function...');
    final hasRankSql = '''
CREATE OR REPLACE FUNCTION public.user_has_rank(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
DECLARE has_rank BOOLEAN;
BEGIN
  SELECT (rank IS NOT NULL AND elo_rating IS NOT NULL) INTO has_rank FROM public.users WHERE id = user_id;
  RETURN COALESCE(has_rank, false);
END;
\$\$;
''';
    await _executeSql(hasRankSql);
    print('✅ Done\n');

    // Step 11: Create ranked_users view
    print('Step 11: Creating ranked_users view...');
    await _executeSql(
      'CREATE OR REPLACE VIEW public.ranked_users AS SELECT * FROM public.users WHERE rank IS NOT NULL AND elo_rating IS NOT NULL AND is_active = true;',
    );
    print('✅ Done\n');

    // Step 12: Grant permissions
    print('Step 12: Granting permissions...');
    await _executeSql('GRANT SELECT ON public.ranked_users TO authenticated;');
    await _executeSql('GRANT SELECT ON public.rank_system TO authenticated;');
    print('✅ Done\n');

    // Verification
    print('=' * 70);
    print('🎉 MIGRATION COMPLETED!\n');
    print('Verifying...\n');

    final ranks = await _query(
      'SELECT rank_code, rank_name_vi, elo_min, elo_max FROM public.rank_system ORDER BY rank_value;',
    );
    print('📊 Rank System (${ranks.length} ranks):');
    for (var rank in ranks) {
      print(
        '  ${rank['rank_code']}: ${rank['elo_min']}-${rank['elo_max']} (${rank['rank_name_vi']})',
      );
    }

    print('\n✅ ALL DONE! Rank system updated successfully!');
    print('=' * 70);
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

  static Future<void> _executeSql(String sql) async {
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
      throw Exception('SQL Error: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> _query(String sql) async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc/exec_sql'),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'query': sql}),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final result = jsonDecode(response.body);
    if (result is List) {
      return List<Map<String, dynamic>>.from(result);
    }
    return [];
  }
}

void main() async {
  try {
    await RunRankSystemMigration.run();
  } catch (e) {
    print('\n❌ Migration failed: $e');
    exit(1);
  }
}
