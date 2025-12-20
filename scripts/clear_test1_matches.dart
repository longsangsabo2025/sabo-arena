import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  print('🧹 Clear matches for tournament "test1"...\n');

  // Load environment variables
  final env = DotEnv()..load(['.env']);
  
  final supabaseUrl = env['SUPABASE_URL'] ?? '';
  final supabaseKey = env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    print('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
    exit(1);
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  final supabase = Supabase.instance.client;

  try {
    // 1. Find tournament "test1"
    print('🔍 Looking for tournament "test1"...');
    final tournamentResponse = await supabase
        .from('tournaments')
        .select('id, name, status')
        .ilike('name', '%test1%')
        .maybeSingle();

    if (tournamentResponse == null) {
      print('❌ Tournament "test1" not found!');
      exit(1);
    }

    final tournamentId = tournamentResponse['id'];
    final tournamentName = tournamentResponse['name'];
    print('✅ Found tournament: $tournamentName (ID: $tournamentId)');

    // 2. Count matches
    print('\n🔢 Counting matches...');
    final countResponse = await supabase
        .from('matches')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('tournament_id', tournamentId);
    
    final matchCount = countResponse.count ?? 0;
    
    if (matchCount == 0) {
      print('✅ No matches found for this tournament!');
      exit(0);
    }

    print('📊 Found $matchCount matches');

    // 3. Confirm deletion
    print('\n⚠️  WARNING: This will delete $matchCount matches!');
    stdout.write('Type "DELETE" to confirm: ');
    final confirmation = stdin.readLineSync()?.trim();

    if (confirmation != 'DELETE') {
      print('❌ Operation cancelled');
      exit(0);
    }

    // 4. Delete matches
    print('\n🗑️  Deleting matches...');
    await supabase
        .from('matches')
        .delete()
        .eq('tournament_id', tournamentId);

    print('✅ Successfully deleted $matchCount matches from tournament "$tournamentName"!');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
