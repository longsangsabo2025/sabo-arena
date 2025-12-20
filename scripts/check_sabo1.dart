import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ',
  );

  final supabase = Supabase.instance.client;

  // Get tournament details
  final tournament = await supabase
      .from('tournaments')
      .select('*')
      .eq('title', 'sabo1')
      .single();

  print('\n📋 TOURNAMENT INFO:');
  print('  ID: ${tournament['id']}');
  print('  Title: ${tournament['title']}');
  print('  Prize Pool: ${tournament['prize_pool']} VND');
  print('  Prize Distribution: ${tournament['prize_distribution']}');
  print('  Custom Distribution: ${tournament['custom_distribution']}');
  print('  Status: ${tournament['status']}');

  // Get tournament_results if completed
  if (tournament['status'] == 'completed') {
    final results = await supabase
        .from('tournament_results')
        .select('*')
        .eq('tournament_id', tournament['id'])
        .order('position');

    print('\n🏆 RESULTS FROM DATABASE:');
    for (final r in results) {
      print('  ${r['position']}. ${r['participant_name']?.toString().padRight(20)} '
            '${r['matches_won']}/${r['matches_lost']} - '
            '${r['prize_money_vnd']} VND');
    }
  }
}
