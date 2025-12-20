import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo',
  );

  final supabase = Supabase.instance.client;

  print('\n🔍 Fetching sabo1 tournament...');
  final tournament = await supabase
      .from('tournaments')
      .select('id, title, prize_pool, prize_distribution, custom_distribution')
      .eq('title', 'sabo1')
      .single();

  print('\n📋 TOURNAMENT DATA:');
  print('  Title: ${tournament['title']}');
  print('  Prize Pool: ${tournament['prize_pool']} VND');
  print('  Prize Distribution: ${tournament['prize_distribution']}');
  print('  Prize Distribution Type: ${tournament['prize_distribution'].runtimeType}');
  
  if (tournament['custom_distribution'] != null) {
    print('  Custom Distribution: ${tournament['custom_distribution']}');
  } else {
    print('  Custom Distribution: NULL');
  }

  // Parse prize_distribution
  print('\n💰 ANALYZING PRIZE DISTRIBUTION:');
  final prizeDist = tournament['prize_distribution'];
  
  if (prizeDist is String) {
    print('  → String template: "$prizeDist"');
  } else if (prizeDist is Map) {
    print('  → Map/JSON object:');
    final template = prizeDist['template'];
    print('    template: $template');
    
    if (prizeDist['distribution'] != null) {
      print('    distribution: ${prizeDist['distribution']}');
      final dist = prizeDist['distribution'] as List;
      for (var i = 0; i < dist.length; i++) {
        final item = dist[i];
        final amount = item['cashAmount'] ?? item['amount'] ?? 0;
        print('      Position ${i+1}: $amount VND');
      }
    }
  }

  // Get current standings
  print('\n🏆 CURRENT STANDINGS:');
  final participants = await supabase
      .from('tournament_participants')
      .select('user_id, users(full_name)')
      .eq('tournament_id', tournament['id']);

  final matches = await supabase
      .from('matches')
      .select('player1_id, player2_id, winner_id, status')
      .eq('tournament_id', tournament['id']);

  // Calculate wins
  final winsCount = <String, int>{};
  final lossesCount = <String, int>{};
  
  for (final match in matches) {
    if (match['status'] == 'completed' && match['winner_id'] != null) {
      final winner = match['winner_id'] as String;
      final p1 = match['player1_id'] as String;
      final p2 = match['player2_id'] as String;
      final loser = winner == p2 ? p1 : p2;
      
      winsCount[winner] = (winsCount[winner] ?? 0) + 1;
      lossesCount[loser] = (lossesCount[loser] ?? 0) + 1;
    }
  }

  // Build rankings
  final rankings = <Map<String, dynamic>>[];
  for (final p in participants) {
    final userId = p['user_id'] as String;
    final users = p['users'] as Map?;
    final name = users?['full_name'] ?? 'Unknown';
    final wins = winsCount[userId] ?? 0;
    final losses = lossesCount[userId] ?? 0;
    
    rankings.add({'name': name, 'wins': wins, 'losses': losses, 'user_id': userId});
  }

  // Sort by wins
  rankings.sort((a, b) => (b['wins'] as int).compareTo(a['wins'] as int));

  for (var i = 0; i < rankings.length; i++) {
    final r = rankings[i];
    print('  ${i+1}. ${(r['name'] as String).padRight(20)} ${r['wins']}/${r['losses']}');
  }

  print('\n✅ Done');
}
