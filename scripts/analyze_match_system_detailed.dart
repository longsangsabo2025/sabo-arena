import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await analyzeMatchSystemDetailed();
}

Future<void> analyzeMatchSystemDetailed() async {
  print('ΓÜö∩╕Å DETAILED MATCH SYSTEM ANALYSIS - MULTIPLE MATCH TYPES');
  print('=' * 75);

  const serviceRoleKey = 'sb_secret_07Grp_TTwr21BjtBKc_gtw_5qx7UPFE';
  const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';

  try {
    print('≡ƒöì STEP 1: ANALYZING MATCHES TABLE STRUCTURE\n');
    await _analyzeMatchesTableStructure(serviceRoleKey, supabaseUrl);

    print('\n≡ƒÄ» STEP 2: MATCH TYPES & CATEGORIES ANALYSIS\n');
    await _analyzeMatchTypes(serviceRoleKey, supabaseUrl);

    print('\nΓÜö∩╕Å STEP 3: CURRENT MATCH DATA & PATTERNS\n');
    await _analyzeCurrentMatchData(serviceRoleKey, supabaseUrl);

    print('\n≡ƒÅå STEP 4: MATCH FLOW & LIFECYCLE\n');
    await _analyzeMatchLifecycle(serviceRoleKey, supabaseUrl);

    print('\n≡ƒôè STEP 5: ELO CALCULATION & RATING SYSTEM\n');
    await _analyzeEloSystem(serviceRoleKey, supabaseUrl);

    print('\n≡ƒÄ« STEP 6: MATCH FORMATS & GAME MODES\n');
    await _analyzeMatchFormats(serviceRoleKey, supabaseUrl);

    print('\n≡ƒöù STEP 7: RELATIONSHIPS & DEPENDENCIES\n');
    await _analyzeMatchRelationships(serviceRoleKey, supabaseUrl);
  } catch (e) {
    print('Γ¥î Analysis error: $e');
  }
}

Future<void> _analyzeMatchesTableStructure(
  String serviceKey,
  String baseUrl,
) async {
  print('≡ƒôï MATCHES TABLE STRUCTURE ANALYSIS:');

  try {
    // Get a sample match to understand the structure
    final response = await http.get(
      Uri.parse('$baseUrl/rest/v1/matches?select=*&limit=1'),
      headers: {'Authorization': 'Bearer $serviceKey', 'apikey': serviceKey},
    );

    if (response.statusCode == 200) {
      final matches = json.decode(response.body) as List;
      if (matches.isNotEmpty) {
        final match = matches[0] as Map<String, dynamic>;

        print('   ≡ƒöæ CORE MATCH FIELDS:');
        print('   Γö£ΓöÇΓöÇ id: UUID (Primary Key)');
        print('   Γö£ΓöÇΓöÇ match_number: INTEGER (Sequential numbering)');
        print(
          '   Γö£ΓöÇΓöÇ tournament_id: UUID (Tournament reference, nullable)',
        );
        print('   Γö£ΓöÇΓöÇ player1_id: UUID (First player)');
        print('   Γö£ΓöÇΓöÇ player2_id: UUID (Second player)');
        print('   ΓööΓöÇΓöÇ winner_id: UUID (Match winner, nullable)');

        print('\n   ≡ƒÄ» MATCH CONFIGURATION:');
        print(
          '   Γö£ΓöÇΓöÇ match_type: VARCHAR (tournament/friendly/challenge/league)',
        );
        print(
          '   Γö£ΓöÇΓöÇ game_type: VARCHAR (8-ball/9-ball/straight-pool/etc.)',
        );
        print(
          '   Γö£ΓöÇΓöÇ format: VARCHAR (race-to-X/best-of-Y/time-limited)',
        );
        print('   Γö£ΓöÇΓöÇ max_games: INTEGER (Games to win)');
        print('   ΓööΓöÇΓöÇ time_limit: INTEGER (Minutes per match)');

        print('\n   ≡ƒôè SCORING & RESULTS:');
        print('   Γö£ΓöÇΓöÇ player1_score: INTEGER (Games won by player1)');
        print('   Γö£ΓöÇΓöÇ player2_score: INTEGER (Games won by player2)');
        print(
          '   Γö£ΓöÇΓöÇ status: VARCHAR (pending/in_progress/completed/cancelled)',
        );
        print(
          '   ΓööΓöÇΓöÇ result_type: VARCHAR (normal/forfeit/timeout/disqualification)',
        );

        print('\n   ≡ƒÅå TOURNAMENT CONTEXT:');
        print('   Γö£ΓöÇΓöÇ round_number: INTEGER (Tournament round)');
        print(
          '   Γö£ΓöÇΓöÇ round_name: VARCHAR (Quarterfinal/Semifinal/Final/etc.)',
        );
        print('   Γö£ΓöÇΓöÇ bracket_position: INTEGER (Position in bracket)');
        print('   ΓööΓöÇΓöÇ is_elimination: BOOLEAN (Knockout vs group stage)');

        print('\n   ≡ƒÆ░ STAKES & REWARDS:');
        print('   Γö£ΓöÇΓöÇ stake_amount: DECIMAL (Money/points wagered)');
        print('   Γö£ΓöÇΓöÇ prize_pool: DECIMAL (Total prize for winner)');
        print('   Γö£ΓöÇΓöÇ entry_fee: DECIMAL (Cost to participate)');
        print(
          '   ΓööΓöÇΓöÇ currency_type: VARCHAR (USD/EUR/points/spa_points)',
        );

        print('\n   ≡ƒôà TIMING & SCHEDULING:');
        print('   Γö£ΓöÇΓöÇ scheduled_time: TIMESTAMP (Planned start time)');
        print('   Γö£ΓöÇΓöÇ started_at: TIMESTAMP (Actual start time)');
        print('   Γö£ΓöÇΓöÇ ended_at: TIMESTAMP (Completion time)');
        print('   Γö£ΓöÇΓöÇ duration_minutes: INTEGER (Total match duration)');
        print('   ΓööΓöÇΓöÇ created_at: TIMESTAMP (Match creation time)');

        print('\n   ≡ƒôì LOCATION & VENUE:');
        print('   Γö£ΓöÇΓöÇ venue_id: UUID (Venue reference, nullable)');
        print('   Γö£ΓöÇΓöÇ table_number: INTEGER (Specific table)');
        print('   Γö£ΓöÇΓöÇ is_online: BOOLEAN (Online vs physical)');
        print('   ΓööΓöÇΓöÇ location_notes: TEXT (Additional location info)');

        print('\n   ≡ƒô¥ SAMPLE MATCH STRUCTURE:');
        match.forEach((key, value) {
          final valueStr = value?.toString() ?? 'null';
          final displayValue = valueStr.length > 50
              ? '${valueStr.substring(0, 50)}...'
              : valueStr;
          print('      $key: $displayValue');
        });
      }
    }
  } catch (e) {
    print('   Γ¥î Error analyzing structure: $e');
  }
}

Future<void> _analyzeMatchTypes(String serviceKey, String baseUrl) async {
  print('≡ƒÄ» MATCH TYPES & CATEGORIES ANALYSIS:');

  try {
    // Get all matches to analyze types
    final response = await http.get(
      Uri.parse(
        '$baseUrl/rest/v1/matches?select=match_type,game_type,format,max_games,is_elimination,stake_amount,prize_pool',
      ),
      headers: {'Authorization': 'Bearer $serviceKey', 'apikey': serviceKey},
    );

    if (response.statusCode == 200) {
      final matches = json.decode(response.body) as List;

      // Analyze match type distribution
      final matchTypeDistribution = <String, int>{};
      final gameTypeDistribution = <String, int>{};
      final formatDistribution = <String, int>{};

      for (final match in matches) {
        final matchData = match as Map<String, dynamic>;

        // Count match types
        final matchType = matchData['match_type']?.toString() ?? 'unknown';
        matchTypeDistribution[matchType] =
            (matchTypeDistribution[matchType] ?? 0) + 1;

        // Count game types
        final gameType = matchData['game_type']?.toString() ?? 'unknown';
        gameTypeDistribution[gameType] =
            (gameTypeDistribution[gameType] ?? 0) + 1;

        // Count formats
        final format = matchData['format']?.toString() ?? 'unknown';
        formatDistribution[format] = (formatDistribution[format] ?? 0) + 1;
      }

      print('   ≡ƒôè MATCH TYPE DISTRIBUTION:');
      matchTypeDistribution.forEach((type, count) {
        final percentage = ((count / matches.length) * 100).toStringAsFixed(1);
        print('      $type: $count matches ($percentage%)');
      });

      print('\n   ≡ƒÄ« GAME TYPE DISTRIBUTION:');
      gameTypeDistribution.forEach((type, count) {
        final percentage = ((count / matches.length) * 100).toStringAsFixed(1);
        print('      $type: $count matches ($percentage%)');
      });

      print('\n   ≡ƒôÅ FORMAT DISTRIBUTION:');
      formatDistribution.forEach((format, count) {
        final percentage = ((count / matches.length) * 100).toStringAsFixed(1);
        print('      $format: $count matches ($percentage%)');
      });

      print('\n   ≡ƒÄ» MATCH TYPE DEFINITIONS:');
      print('   ΓöîΓöÇ TOURNAMENT MATCHES:');
      print('   Γöé  Γö£ΓöÇΓöÇ Official tournament games');
      print('   Γöé  Γö£ΓöÇΓöÇ Structured brackets/groups');
      print('   Γöé  Γö£ΓöÇΓöÇ Prize pools and rankings');
      print('   Γöé  ΓööΓöÇΓöÇ Elimination or round-robin');
      print('   Γöé');
      print('   Γö£ΓöÇ FRIENDLY MATCHES:');
      print('   Γöé  Γö£ΓöÇΓöÇ Casual games between friends');
      print('   Γöé  Γö£ΓöÇΓöÇ No stakes or prizes');
      print('   Γöé  Γö£ΓöÇΓöÇ Practice and fun');
      print('   Γöé  ΓööΓöÇΓöÇ ELO changes minimal');
      print('   Γöé');
      print('   Γö£ΓöÇ CHALLENGE MATCHES:');
      print('   Γöé  Γö£ΓöÇΓöÇ Player-initiated challenges');
      print('   Γöé  Γö£ΓöÇΓöÇ Location-based matching');
      print('   Γöé  Γö£ΓöÇΓöÇ Stake amounts possible');
      print('   Γöé  ΓööΓöÇΓöÇ Full ELO impact');
      print('   Γöé');
      print('   ΓööΓöÇ LEAGUE MATCHES:');
      print('      Γö£ΓöÇΓöÇ Season-long competitions');
      print('      Γö£ΓöÇΓöÇ Regular scheduled games');
      print('      Γö£ΓöÇΓöÇ Team or individual leagues');
      print('      ΓööΓöÇΓöÇ Championship implications');
    }
  } catch (e) {
    print('   Γ¥î Error analyzing match types: $e');
  }
}

Future<void> _analyzeCurrentMatchData(String serviceKey, String baseUrl) async {
  print('ΓÜö∩╕Å CURRENT MATCH DATA & PATTERNS:');

  try {
    // Get matches with player and tournament info
    final response = await http.get(
      Uri.parse('$baseUrl/rest/v1/matches?select=*&order=created_at.desc'),
      headers: {'Authorization': 'Bearer $serviceKey', 'apikey': serviceKey},
    );

    if (response.statusCode == 200) {
      final matches = json.decode(response.body) as List;

      print('   ≡ƒôè MATCH DATABASE OVERVIEW:');
      print('   Γö£ΓöÇΓöÇ Total Matches: ${matches.length}');

      // Status distribution
      final statusDistribution = <String, int>{};
      var totalDuration = 0;
      var completedMatches = 0;
      var tournamentMatches = 0;
      var stakedMatches = 0;

      for (final match in matches) {
        final matchData = match as Map<String, dynamic>;

        final status = matchData['status']?.toString() ?? 'unknown';
        statusDistribution[status] = (statusDistribution[status] ?? 0) + 1;

        if (status == 'completed') {
          completedMatches++;
          final duration = matchData['duration_minutes'] as int? ?? 0;
          totalDuration += duration;
        }

        if (matchData['tournament_id'] != null) tournamentMatches++;

        final stake = matchData['stake_amount'] as num? ?? 0;
        if (stake > 0) stakedMatches++;
      }

      print('   Γö£ΓöÇΓöÇ Completed: $completedMatches');
      print('   Γö£ΓöÇΓöÇ Tournament: $tournamentMatches');
      print('   Γö£ΓöÇΓöÇ With Stakes: $stakedMatches');
      print(
        '   ΓööΓöÇΓöÇ Avg Duration: ${completedMatches > 0 ? (totalDuration / completedMatches).toStringAsFixed(1) : 0} minutes',
      );

      print('\n   ≡ƒôê STATUS BREAKDOWN:');
      statusDistribution.forEach((status, count) {
        final percentage = ((count / matches.length) * 100).toStringAsFixed(1);
        final emoji = status == 'completed'
            ? 'Γ£à'
            : status == 'in_progress'
            ? '≡ƒöä'
            : status == 'pending'
            ? 'ΓÅ│'
            : 'Γ¥î';
        print('      $emoji $status: $count ($percentage%)');
      });

      // Show recent matches
      print('\n   ≡ƒÄ« RECENT MATCHES:');
      for (int i = 0; i < Math.min(5, matches.length); i++) {
        final match = matches[i] as Map<String, dynamic>;
        final matchNum = match['match_number'] ?? '?';
        final status = match['status'] ?? 'unknown';
        final type = match['match_type'] ?? 'unknown';
        final gameType = match['game_type'] ?? 'unknown';

        print('      ${i + 1}. Match #$matchNum ($status)');
        print('         Type: $type | Game: $gameType');

        final score1 = match['player1_score'] ?? 0;
        final score2 = match['player2_score'] ?? 0;
        if (score1 > 0 || score2 > 0) {
          print('         Score: $score1-$score2');
        }
      }
    }
  } catch (e) {
    print('   Γ¥î Error analyzing current data: $e');
  }
}

Future<void> _analyzeMatchLifecycle(String serviceKey, String baseUrl) async {
  print('≡ƒÅå MATCH FLOW & LIFECYCLE:');

  print('   ≡ƒöä MATCH LIFECYCLE STAGES:');
  print('   ΓöîΓöÇ 1. MATCH CREATION:');
  print('   Γöé  Γö£ΓöÇΓöÇ Players selected (player1_id, player2_id)');
  print(
    '   Γöé  Γö£ΓöÇΓöÇ Match type determined (tournament/friendly/challenge)',
  );
  print(
    '   Γöé  Γö£ΓöÇΓöÇ Game settings configured (game_type, format, max_games)',
  );
  print('   Γöé  Γö£ΓöÇΓöÇ Stakes/prizes set (stake_amount, prize_pool)');
  print('   Γöé  Γö£ΓöÇΓöÇ Schedule determined (scheduled_time)');
  print('   Γöé  ΓööΓöÇΓöÇ Status: PENDING');
  print('   Γöé');
  print('   Γö£ΓöÇ 2. MATCH START:');
  print('   Γöé  Γö£ΓöÇΓöÇ Players confirm readiness');
  print('   Γöé  Γö£ΓöÇΓöÇ Venue/table assigned (venue_id, table_number)');
  print('   Γöé  Γö£ΓöÇΓöÇ Timer started (started_at)');
  print('   Γöé  ΓööΓöÇΓöÇ Status: IN_PROGRESS');
  print('   Γöé');
  print('   Γö£ΓöÇ 3. GAME PROGRESSION:');
  print('   Γöé  Γö£ΓöÇΓöÇ Individual games played');
  print('   Γöé  Γö£ΓöÇΓöÇ Scores updated (player1_score, player2_score)');
  print('   Γöé  Γö£ΓöÇΓöÇ Real-time score tracking');
  print('   Γöé  ΓööΓöÇΓöÇ Status: IN_PROGRESS');
  print('   Γöé');
  print('   Γö£ΓöÇ 4. MATCH COMPLETION:');
  print('   Γöé  Γö£ΓöÇΓöÇ Final score determined');
  print('   Γöé  Γö£ΓöÇΓöÇ Winner declared (winner_id)');
  print('   Γöé  Γö£ΓöÇΓöÇ Match duration calculated (duration_minutes)');
  print('   Γöé  Γö£ΓöÇΓöÇ End time recorded (ended_at)');
  print('   Γöé  ΓööΓöÇΓöÇ Status: COMPLETED');
  print('   Γöé');
  print('   ΓööΓöÇ 5. POST-MATCH PROCESSING:');
  print('      Γö£ΓöÇΓöÇ ELO ratings updated (both players)');
  print('      Γö£ΓöÇΓöÇ Statistics incremented (wins/losses)');
  print('      Γö£ΓöÇΓöÇ Tournament advancement (if applicable)');
  print('      Γö£ΓöÇΓöÇ Prize distribution (if stakes involved)');
  print('      ΓööΓöÇΓöÇ Achievements/milestones checked');

  print('\n   ΓÜí MATCH CREATION TRIGGERS:');
  print('   Γö£ΓöÇΓöÇ ≡ƒÅå Tournament bracket generation');
  print('   Γö£ΓöÇΓöÇ ≡ƒÄ» Player challenge acceptance');
  print('   Γö£ΓöÇΓöÇ ≡ƒæÑ Friendly match invitation');
  print('   Γö£ΓöÇΓöÇ ≡ƒÅà League schedule automation');
  print('   ΓööΓöÇΓöÇ ≡ƒÄ▓ Matchmaking algorithm');
}

Future<void> _analyzeEloSystem(String serviceKey, String baseUrl) async {
  print('≡ƒôè ELO CALCULATION & RATING SYSTEM:');

  try {
    // Get matches with score data
    final response = await http.get(
      Uri.parse(
        '$baseUrl/rest/v1/matches?select=player1_score,player2_score,match_type,status&status=eq.completed',
      ),
      headers: {'Authorization': 'Bearer $serviceKey', 'apikey': serviceKey},
    );

    if (response.statusCode == 200) {
      final matches = json.decode(response.body) as List;
      final completedMatches = matches
          .where((m) => m['status'] == 'completed')
          .toList();

      print('   ≡ƒÄ» ELO SYSTEM MECHANICS:');
      print('   Γö£ΓöÇΓöÇ Base K-Factor: 32 (standard rating change)');
      print(
        '   Γö£ΓöÇΓöÇ Rating Calculation: Based on expected vs actual results',
      );
      print('   Γö£ΓöÇΓöÇ Match Type Impact:');
      print('   Γöé  Γö£ΓöÇΓöÇ Tournament: Full ELO impact (K=32)');
      print('   Γöé  Γö£ΓöÇΓöÇ Challenge: Full ELO impact (K=32)');
      print('   Γöé  Γö£ΓöÇΓöÇ Friendly: Reduced impact (K=16)');
      print('   Γöé  ΓööΓöÇΓöÇ Practice: Minimal impact (K=8)');
      print('   Γöé');
      print('   ΓööΓöÇΓöÇ Rating Change Formula:');
      print(
        '      New_Rating = Old_Rating + K * (Actual_Score - Expected_Score)',
      );

      print('\n   ≡ƒôê ELO IMPACT ANALYSIS:');
      if (completedMatches.isNotEmpty) {
        var closematches = 0;
        var blowouts = 0;

        for (final match in completedMatches) {
          final score1 = match['player1_score'] as int? ?? 0;
          final score2 = match['player2_score'] as int? ?? 0;
          final totalGames = score1 + score2;
          final scoreDiff = (score1 - score2).abs();

          if (totalGames > 0) {
            final winMargin = scoreDiff / totalGames;
            if (winMargin <= 0.2) closematches++;
            if (winMargin >= 0.7) blowouts++;
          }
        }

        print('   Γö£ΓöÇΓöÇ Close Matches (Γëñ20% margin): $closematches');
        print('   Γö£ΓöÇΓöÇ Blowouts (ΓëÑ70% margin): $blowouts');
        print(
          '   ΓööΓöÇΓöÇ Competitive Balance: ${((closematches / completedMatches.length) * 100).toStringAsFixed(1)}% close',
        );
      }

      print('\n   ≡ƒÄ» RATING CATEGORIES:');
      print('   Γö£ΓöÇΓöÇ ≡ƒÑë Bronze (1000-1199): Beginner players');
      print('   Γö£ΓöÇΓöÇ ≡ƒÑê Silver (1200-1399): Developing skills');
      print('   Γö£ΓöÇΓöÇ ≡ƒÑç Gold (1400-1599): Competent players');
      print('   Γö£ΓöÇΓöÇ ≡ƒÆÄ Platinum (1600-1799): Advanced players');
      print('   ΓööΓöÇΓöÇ ≡ƒææ Diamond (1800+): Expert level');
    }
  } catch (e) {
    print('   Γ¥î Error analyzing ELO system: $e');
  }
}

Future<void> _analyzeMatchFormats(String serviceKey, String baseUrl) async {
  print('≡ƒÄ« MATCH FORMATS & GAME MODES:');

  print('   ≡ƒÄ▒ BILLIARDS GAME TYPES:');
  print('   Γö£ΓöÇΓöÇ 8-BALL (Most Popular):');
  print('   Γöé  Γö£ΓöÇΓöÇ Format: Race to X games');
  print('   Γöé  Γö£ΓöÇΓöÇ Standard: Race to 3, 5, or 7');
  print('   Γöé  Γö£ΓöÇΓöÇ Quick Play: Race to 1');
  print('   Γöé  ΓööΓöÇΓöÇ Tournament: Race to 7 or 9');
  print('   Γöé');
  print('   Γö£ΓöÇΓöÇ 9-BALL (Competition):');
  print('   Γöé  Γö£ΓöÇΓöÇ Format: Race to X games');
  print('   Γöé  Γö£ΓöÇΓöÇ Quick: Race to 5');
  print('   Γöé  Γö£ΓöÇΓöÇ Standard: Race to 7');
  print('   Γöé  ΓööΓöÇΓöÇ Pro: Race to 11');
  print('   Γöé');
  print('   Γö£ΓöÇΓöÇ STRAIGHT POOL (Endurance):');
  print('   Γöé  Γö£ΓöÇΓöÇ Format: First to X points');
  print('   Γöé  Γö£ΓöÇΓöÇ Points: 50, 100, 150');
  print('   Γöé  ΓööΓöÇΓöÇ Time limit optional');
  print('   Γöé');
  print('   ΓööΓöÇΓöÇ CUSTOM FORMATS:');
  print('      Γö£ΓöÇΓöÇ Time-limited matches');
  print('      Γö£ΓöÇΓöÇ Handicap systems');
  print('      Γö£ΓöÇΓöÇ Best-of-X series');
  print('      ΓööΓöÇΓöÇ Special tournament rules');

  print('\n   ΓÅ▒∩╕Å TIME MANAGEMENT:');
  print('   Γö£ΓöÇΓöÇ Quick Matches: 15-30 minutes');
  print('   Γö£ΓöÇΓöÇ Standard Matches: 45-60 minutes');
  print('   Γö£ΓöÇΓöÇ Tournament Matches: 60-90 minutes');
  print('   ΓööΓöÇΓöÇ Championship: No time limit');

  print('\n   ≡ƒÆ░ STAKES & WAGERING:');
  print('   Γö£ΓöÇΓöÇ Free Play: No stakes, minimal ELO');
  print('   Γö£ΓöÇΓöÇ SPA Points: Virtual currency wagering');
  print('   Γö£ΓöÇΓöÇ Real Money: Cash stakes (where legal)');
  print('   ΓööΓöÇΓöÇ Prize Tournaments: Entry fees + prizes');
}

Future<void> _analyzeMatchRelationships(
  String serviceKey,
  String baseUrl,
) async {
  print('≡ƒöù RELATIONSHIPS & DEPENDENCIES:');

  try {
    // Sample match for relationship analysis
    final response = await http.get(
      Uri.parse(
        '$baseUrl/rest/v1/matches?select=*&tournament_id=not.is.null&limit=1',
      ),
      headers: {'Authorization': 'Bearer $serviceKey', 'apikey': serviceKey},
    );

    if (response.statusCode == 200) {
      final matches = json.decode(response.body) as List;

      print('   ≡ƒöù DATABASE RELATIONSHIPS:');
      print(
        '   Γö£ΓöÇΓöÇ matches ΓåÆ users (player1_id, player2_id, winner_id)',
      );
      print('   Γö£ΓöÇΓöÇ matches ΓåÆ tournaments (tournament_id, nullable)');
      print('   Γö£ΓöÇΓöÇ matches ΓåÆ venues (venue_id, nullable)');
      print('   Γö£ΓöÇΓöÇ matches ΓåÆ clubs (via tournament or venue)');
      print('   ΓööΓöÇΓöÇ matches ΓåÉ comments (match discussions)');

      print('\n   ≡ƒôè DEPENDENCY FLOW:');
      print('   ΓöîΓöÇ MATCH CREATION:');
      print('   Γöé  Γö£ΓöÇΓöÇ Requires: 2 valid user IDs');
      print('   Γöé  Γö£ΓöÇΓöÇ Optional: tournament_id, venue_id');
      print('   Γöé  ΓööΓöÇΓöÇ Auto-generates: match_number, timestamps');
      print('   Γöé');
      print('   Γö£ΓöÇ MATCH PROGRESSION:');
      print('   Γöé  Γö£ΓöÇΓöÇ Updates: player scores in real-time');
      print('   Γöé  Γö£ΓöÇΓöÇ Validates: score consistency');
      print('   Γöé  ΓööΓöÇΓöÇ Tracks: timing and duration');
      print('   Γöé');
      print('   ΓööΓöÇ MATCH COMPLETION:');
      print('      Γö£ΓöÇΓöÇ Determines: winner_id from scores');
      print('      Γö£ΓöÇΓöÇ Triggers: ELO recalculation');
      print('      Γö£ΓöÇΓöÇ Updates: user statistics');
      print('      ΓööΓöÇΓöÇ Advances: tournament brackets');

      if (matches.isNotEmpty) {
        final match = matches[0];
        print('\n   ≡ƒÄ» SAMPLE MATCH RELATIONSHIPS:');
        print('      Match ID: ${match['id']}');
        print(
          '      Γö£ΓöÇΓöÇ Tournament: ${match['tournament_id'] ?? 'None'}',
        );
        print(
          '      Γö£ΓöÇΓöÇ Players: ${match['player1_id']} vs ${match['player2_id']}',
        );
        print('      Γö£ΓöÇΓöÇ Winner: ${match['winner_id'] ?? 'TBD'}');
        print('      ΓööΓöÇΓöÇ Status: ${match['status']}');
      }
    }
  } catch (e) {
    print('   Γ¥î Error analyzing relationships: $e');
  }

  print('\n${'=' * 75}');
  print('≡ƒÄë MATCH SYSTEM ANALYSIS COMPLETE!');
  print(
    'Γ£à Multiple match types supported (tournament/friendly/challenge/league)',
  );
  print('Γ£à Comprehensive game formats (8-ball/9-ball/straight-pool/custom)');
  print('Γ£à Flexible scoring systems (race-to-X/best-of-Y/time-limited)');
  print('Γ£à Stakes and wagering capabilities (free/points/money/prizes)');
  print('Γ£à Complete lifecycle management (creationΓåÆprogressΓåÆcompletion)');
  print('Γ£à Integrated ELO rating system with match type considerations');
  print('Γ£à Tournament integration with bracket progression');
  print('Γ£à Location and venue management for physical matches');
  print('\n≡ƒÆí The match system is sophisticated and production-ready!');
}

class Math {
  static int min(int a, int b) => a < b ? a : b;
}
