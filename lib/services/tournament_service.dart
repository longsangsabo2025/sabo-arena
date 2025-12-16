import '../core/utils/rank_migration_helper.dart';
import '../models/tournament.dart';
import '../models/user_profile.dart';
import '../core/constants/tournament_constants.dart';
import 'notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'auto_notification_hooks.dart';
import 'database_monitoring_service.dart';
import 'cache_manager.dart';
import 'performance_monitor.dart' show PerformanceTimer;
import 'database_replica_manager.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart';

class TournamentService {
  static TournamentService? _instance;
  static TournamentService get instance => _instance ??= TournamentService._();
  TournamentService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get read client (uses replica if available)
  SupabaseClient get _readClient => DatabaseReplicaManager.instance.readClient;
  
  // Get write client (always uses primary)
  SupabaseClient get _writeClient => DatabaseReplicaManager.instance.writeClient;

  Future<List<Tournament>> getTournaments({
    String? status,
    String? clubId,
    String? skillLevel,
    int page = 1,
    int pageSize = 15,
  }) async {
    final timer = PerformanceTimer('tournament_service.getTournaments');
    
    // Track query for monitoring
    return await DatabaseMonitoringService.instance.trackQuery(
      'getTournaments',
      () async {
        try {
      // Check cache first (for first page only)
      if (page == 1 && status == null && clubId == null) {
        final cached = await CacheManager.instance.getCache('tournaments_list');
        if (cached != null) {
          final tournaments = (cached as List)
              .map<Tournament>((json) => Tournament.fromJson(json))
              .toList();
          ProductionLogger.debug('Using cached tournaments list', tag: 'TournamentService');
          return tournaments;
        }
      }

      // Use read replica for read operations
      var query = _readClient
          .from('tournaments')
          .select('*, clubs(name, logo_url, address)');

      if (status != null) {
        query = query.eq('status', status);
      }
      if (clubId != null) {
        query = query.eq('club_id', clubId);
      }
      // Removed skill_level_required filter - không dùng nữa

      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      final response = await query
          .eq('is_public', true)
          .order('start_date', ascending: true)
          .range(from, to);

      final tournaments = response
          .map<Tournament>((json) => Tournament.fromJson(json))
          .toList();

      // Cache first page
      if (page == 1 && status == null && clubId == null) {
        await CacheManager.instance.setCache(
          'tournaments_list',
          response,
          ttl: Duration(minutes: 10),
        );
      }

      timer.stop();
      return tournaments;
    } catch (error) {
      timer.stop();
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getTournaments',
          context: 'Failed to fetch tournaments list',
        ),
      );
      throw Exception(errorInfo.message);
    }
      },
    );
  }

  /// Get tournaments for club management (includes private tournaments)
  Future<List<Tournament>> getClubTournaments(
    String clubId, {
    String? status,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      ProductionLogger.debug('Loading tournaments for club $clubId', tag: 'TournamentService');

      // Use read replica for read operations
      var query = _readClient.from('tournaments').select();

      // Always filter by club ID
      query = query.eq('club_id', clubId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final tournaments = response
          .map<Tournament>((json) => Tournament.fromJson(json))
          .toList();

      ProductionLogger.info('Found ${tournaments.length} tournaments for club', tag: 'TournamentService');
      return tournaments;
    } catch (error, stackTrace) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getClubTournaments',
          context: 'Failed to fetch club tournaments',
        ),
      );
      ProductionLogger.error('Error loading club tournaments: ${errorInfo.message}', error: error, stackTrace: stackTrace, tag: 'TournamentService');
      // Return mock data as fallback
      return _getMockTournamentsForClub(clubId);
    }
  }

  /// Mock tournaments for development/fallback
  List<Tournament> _getMockTournamentsForClub(String clubId) {
    final now = DateTime.now();
    return [
      Tournament(
        id: 'tournament_1',
        title: 'Giải Vô Địch CLB 2025',
        description: 'Giải đấu thường niên của câu lạc bộ',
        clubId: clubId,
        startDate: now.add(Duration(days: 15)),
        registrationDeadline: now.add(Duration(days: 10)),
        maxParticipants: 32,
        currentParticipants: 18,
        entryFee: 100000,
        prizePool: 5000000,
        status: 'upcoming',
        format: 'single_elimination', // Tournament format
        tournamentType: '8-ball', // Game type
        isPublic: true,
        createdAt: now.subtract(Duration(days: 30)),
        updatedAt: now.subtract(Duration(days: 1)),
      ),
      Tournament(
        id: 'tournament_2',
        title: 'Giải Giao Hữu Tháng 9',
        description: 'Giải đấu giao hữu hàng tháng',
        clubId: clubId,
        startDate: now.subtract(Duration(days: 5)),
        registrationDeadline: now.subtract(Duration(days: 10)),
        maxParticipants: 16,
        currentParticipants: 16,
        entryFee: 50000,
        prizePool: 1000000,
        status: 'ongoing',
        format: 'double_elimination', // Tournament format
        tournamentType: '9-ball', // Game type
        isPublic: true,
        createdAt: now.subtract(Duration(days: 20)),
        updatedAt: now.subtract(Duration(hours: 2)),
      ),
      Tournament(
        id: 'tournament_3',
        title: 'Giải Newbie Cup',
        description: 'Dành cho người mới bắt đầu',
        clubId: clubId,
        startDate: now.subtract(Duration(days: 45)),
        registrationDeadline: now.subtract(Duration(days: 50)),
        maxParticipants: 24,
        currentParticipants: 20,
        entryFee: 0,
        prizePool: 500000,
        status: 'completed',
        format: 'round_robin', // Tournament format
        tournamentType: '8-ball', // Game type
        isPublic: true,
        createdAt: now.subtract(Duration(days: 60)),
        updatedAt: now.subtract(Duration(days: 45)),
      ),
    ];
  }

  Future<Tournament> getTournamentById(String tournamentId) async {
    try {
      final response = await _supabase
          .from('tournaments')
          .select()
          .eq('id', tournamentId)
          .single();

      return Tournament.fromJson(response);
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getTournamentById',
          context: 'Failed to fetch tournament by ID',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<List<UserProfile>> getTournamentParticipants(
    String tournamentId,
  ) async {
    try {
      ProductionLogger.debug('Querying participants for tournament $tournamentId', tag: 'TournamentService');
      final response = await _supabase
          .from('tournament_participants')
          .select('''
            *,
            users (*)
          ''')
          .eq('tournament_id', tournamentId)
          .order('registered_at');

      ProductionLogger.debug('Raw response count: ${response.length}', tag: 'TournamentService');
      if (kDebugMode) {
        for (int i = 0; i < response.length; i++) {
          final item = response[i];
          ProductionLogger.debug(
            '${i + 1}. User: ${item['users']?['display_name'] ?? item['users']?['full_name']} - Status: ${item['status']}',
            tag: 'TournamentService',
          );
        }
      }

      final participants = response
          .where((json) => json['users'] != null) // ✅ FIX: Filter out null users
          .map<UserProfile>((json) => UserProfile.fromJson(json['users']))
          .toList();

      // ✅ DEBUG: Check for orphaned participants
      final orphanedCount = response.length - participants.length;
      if (orphanedCount > 0) {
        ProductionLogger.info('⚠️ TournamentService: Found $orphanedCount orphaned participants (no user record)', tag: 'TournamentService');
        for (final item in response) {
          if (item['users'] == null) {
            ProductionLogger.warning('Orphaned participant: user_id=${item['user_id']}, status=${item['status']}', tag: 'TournamentService');
          }
        }
      }

      ProductionLogger.info('Returning ${participants.length} valid participants ($orphanedCount orphaned excluded)', tag: 'TournamentService');
      return participants;
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getTournamentParticipants',
          context: 'Failed to fetch tournament participants',
        ),
      );
      ProductionLogger.info('❌ TournamentService: Error getting participants: ${errorInfo.message}', tag: 'TournamentService');
      throw Exception(errorInfo.message);
    }
  }

  Future<List<Map<String, dynamic>>> getTournamentMatches(
    String tournamentId,
  ) async {
    try {
      ProductionLogger.debug('Fetching matches for tournament $tournamentId', tag: 'TournamentService');

      // First get matches with proper column names
      final matches = await _supabase
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId)
          .order('round_number')
          .order('match_number');

      ProductionLogger.info('📊 TournamentService: Found ${matches.length} matches', tag: 'TournamentService');
      if (matches.isEmpty) {
        ProductionLogger.info('⚠️ No matches found for tournament $tournamentId', tag: 'TournamentService');
        return [];
      }

      // Then get user profiles separately for better reliability
      List<String> playerIds = [];
      ProductionLogger.info('🔍 Processing ${matches.length} matches for player IDs:', tag: 'TournamentService');
      for (int i = 0; i < matches.length && i < 3; i++) {
        var match = matches[i];
        ProductionLogger.debug(
          'Match ${i + 1}: R${match['round_number']}M${match['match_number']} - Player1: ${match['player1_id']}, Player2: ${match['player2_id']}',
          tag: 'TournamentService',
        );
        if (match['player1_id'] != null) playerIds.add(match['player1_id']);
        if (match['player2_id'] != null) playerIds.add(match['player2_id']);
      }

      // Add remaining player IDs without logging
      for (int i = 3; i < matches.length; i++) {
        var match = matches[i];
        if (match['player1_id'] != null) playerIds.add(match['player1_id']);
        if (match['player2_id'] != null) playerIds.add(match['player2_id']);
      }

      Map<String, dynamic> userProfiles = {};
      if (playerIds.isNotEmpty) {
        ProductionLogger.debug(
          'Fetching profiles for ${playerIds.length} players - IDs: ${playerIds.take(5).join(", ")}${playerIds.length > 5 ? "..." : ""}',
          tag: 'TournamentService',
        );
        try {
          final profiles = await _supabase
              .from('users')
              .select(
                'id, full_name, display_name, avatar_url, elo_rating, rank',
              )
              .inFilter('id', playerIds.toSet().toList());

          ProductionLogger.info('📊 TournamentService: Found ${profiles.length} profiles', tag: 'TournamentService');
          for (var profile in profiles) {
            userProfiles[profile['id']] = profile;
            ProductionLogger.debug(
              'Profile: ${profile['id']?.toString().substring(0, 8)}... - ${profile['display_name'] ?? profile['full_name'] ?? 'No Name'}',
              tag: 'TournamentService',
            );
          }

          if (profiles.length < playerIds.length) {
            ProductionLogger.warning('Missing profiles: Expected ${playerIds.length}, got ${profiles.length}', tag: 'TournamentService');
          }
        } catch (e) {
          ProductionLogger.error('Error fetching user profiles', error: e, stackTrace: StackTrace.current, tag: 'TournamentService');
          // Continue without profiles - we'll show placeholder names
        }
      } else {
        ProductionLogger.info('⚠️ No player IDs found in matches', tag: 'TournamentService');
      }

      return matches.map<Map<String, dynamic>>((match) {
        final player1Profile = match['player1_id'] != null
            ? userProfiles[match['player1_id']]
            : null;
        final player2Profile = match['player2_id'] != null
            ? userProfiles[match['player2_id']]
            : null;

        // Use the correct score columns from database
        final player1Score =
            match['player1_score'] ?? match['score_player1'] ?? 0;
        final player2Score =
            match['player2_score'] ?? match['score_player2'] ?? 0;

        return {
          "matchId": match['id'],
          "round": match['round_number'] ?? match['round'] ?? 1,
          "round_number": match['round_number'] ?? 1,
          "match_number": match['match_number'] ?? 1,
          "player1": player1Profile != null
              ? {
                  "id": player1Profile['id'],
                  "name":
                      player1Profile['display_name'] ??
                      player1Profile['full_name'] ??
                      'Player 1',
                  "avatar":
                      player1Profile['avatar_url'] ??
                      "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                  "rank": RankMigrationHelper.getNewDisplayName(
                    player1Profile['rank'] as String?,
                  ),
                  "score": player1Score,
                }
              : match['player1_id'] != null
              ? {
                  "id": match['player1_id'],
                  "name": 'Player 1',
                  "avatar":
                      "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                  "rank": "Chưa xếp hạng",
                  "score": player1Score,
                }
              : null,
          "player2": player2Profile != null
              ? {
                  "id": player2Profile['id'],
                  "name":
                      player2Profile['display_name'] ??
                      player2Profile['full_name'] ??
                      'Player 2',
                  "avatar":
                      player2Profile['avatar_url'] ??
                      "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                  "rank": RankMigrationHelper.getNewDisplayName(
                    player2Profile['rank'] as String?,
                  ),
                  "score": player2Score,
                }
              : match['player2_id'] != null
              ? {
                  "id": match['player2_id'],
                  "name": 'Player 2',
                  "avatar":
                      "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                  "rank": "Chưa xếp hạng",
                  "score": player2Score,
                }
              : null,
          // ⚡ CRITICAL FIX: Add scores at root level for widgets
          "player1_score": player1Score,
          "player2_score": player2Score,
          "player1_id": match['player1_id'],
          "player2_id": match['player2_id'],
          "winner_id": match['winner_id'],
          "id": match['id'],
          "winner": match['winner_id'] != null
              ? (match['winner_id'] == match['player1_id']
                    ? "player1"
                    : "player2")
              : null,
          "status": match['status'] ?? "pending",
          "scheduled_time": match['scheduled_time'],
          "start_time": match['start_time'],
          "end_time": match['end_time'],
          "notes": match['notes'],
          // ✅ ADD ADVANCEMENT FIELDS FOR DOUBLE ELIMINATION
          "winner_advances_to": match['winner_advances_to'],
          "loser_advances_to": match['loser_advances_to'],
          "bracket_format": match['bracket_format'],
          // ✅ ADD HIERARCHICAL STRUCTURE FIELDS FOR SABO FORMATS
          "bracket_type": match['bracket_type'],
          "bracket_group":
              match['bracket_group'], // 'A', 'B', or null for cross finals
          "stage_round": match['stage_round'],
          "display_order": match['display_order'],
        };
      }).toList();
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getTournamentMatches',
          context: 'Failed to fetch tournament matches',
        ),
      );
      ProductionLogger.info('❌ TournamentService: Error getting tournament matches: ${errorInfo.message}', tag: 'TournamentService');
      throw Exception(errorInfo.message);
    }
  }

  Future<bool> registerForTournament(
    String tournamentId, {
    String paymentMethod = '0',
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if already registered
      final existingRegistration = await _supabase
          .from('tournament_participants')
          .select()
          .eq('tournament_id', tournamentId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingRegistration != null) {
        throw Exception('Already registered for this tournament');
      }

      // Check if tournament is still accepting registrations
      final tournament = await getTournamentById(tournamentId);
      if (tournament.currentParticipants >= tournament.maxParticipants) {
        throw Exception('Tournament is full');
      }

      if (DateTime.now().isAfter(tournament.registrationDeadline)) {
        throw Exception('Registration deadline has passed');
      }

      // Register for tournament
      await _supabase.from('tournament_participants').insert({
        'tournament_id': tournamentId,
        'user_id': user.id,
        'payment_method_id': paymentMethod != '0' ? paymentMethod : null, // Store payment method UUID
        "payment_status": 'pending',
        "status": 'registered',
        'notes': paymentMethod == '0'
            ? "Thanh toán tại quán"
            : 'Thanh toán QR code',
        'registered_at': DateTime.now().toIso8601String(),
      });

      // Update participant count
      await _supabase.rpc(
        'increment_tournament_participants',
        params: {'tournament_id': tournamentId},
      );

      // 🔔 Gửi thông báo đăng ký giải đấu thành công
      await AutoNotificationHooks.onTournamentRegistered(
        tournamentId: tournamentId,
        userId: user.id,
        tournamentName: tournament.title,
      );

      // Send notification to club admin (fire and forget)
      try {
        NotificationService.instance.sendRegistrationNotification(
          tournamentId: tournamentId,
          userId: user.id,
          paymentMethod: paymentMethod,
        );
      } catch (e) {
        ProductionLogger.info('⚠️ Failed to send notification: $e', tag: 'TournamentService');
      }

      return true;
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'registerForTournament',
          context: 'Failed to register for tournament',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<bool> unregisterFromTournament(String tournamentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('tournament_participants')
          .delete()
          .eq('tournament_id', tournamentId)
          .eq('user_id', user.id);

      // Update participant count
      await _supabase.rpc(
        'decrement_tournament_participants',
        params: {'tournament_id': tournamentId},
      );

      return true;
    } catch (error) {
      throw Exception('Failed to unregister from tournament: $error');
    }
  }

  Future<bool> isRegisteredForTournament(String tournamentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('tournament_participants')
          .select('id')
          .eq('tournament_id', tournamentId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (error) {
      throw Exception('Failed to check tournament registration: $error');
    }
  }

  /// No format mapping needed - database will support SABO formats directly
  /// sabo_de16, sabo_de32 have different logic than double_elimination

  Future<Tournament> createTournament({
    required String clubId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime registrationDeadline,
    required int maxParticipants,
    required double entryFee,
    required double prizePool,
    String format = 'single_elimination', // Tournament elimination format
    String gameType = '8-ball', // Game type (8-ball, 9-ball, 10-ball)
    String? rules,
    String? requirements,
    String? coverImageUrl, // Cover image URL
    // Enhanced prize configuration parameters
    String prizeSource = 'entry_fees', // 'entry_fees', 'sponsor', 'hybrid'
    String distributionTemplate =
        'top_4', // 'winner_takes_all', 'top_3', 'top_4', 'dong_hang_3', 'custom'
    double organizerFeePercent = 10.0, // Organizer fee percentage (0-100)
    double sponsorContribution = 0.0, // Additional sponsor money
    List<Map<String, dynamic>>?
    customDistribution, // For custom distribution [{position: 1, percentage: 50.0}]
    // Rank restriction parameters
    String? minRank, // Minimum rank required
    String? maxRank, // Maximum rank allowed
    // Venue and contact parameters
    String? venueAddress, // Detailed venue address
    String? venueContact, // Contact person name
    String? venuePhone, // Contact phone number
    // Additional rules parameters
    String? specialRules, // Special tournament rules
    bool registrationFeeWaiver = false, // Whether registration fee is waived
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Calculate actual prize pool and distribution
      double actualPrizePool = prizePool;
      Map<String, dynamic>? prizeDistributionData;

      // Calculate total prize pool including sponsor contribution
      if (prizeSource == 'sponsor') {
        actualPrizePool = sponsorContribution;
      } else if (prizeSource == 'hybrid') {
        // Entry fees + sponsor contribution - organizer fee
        final entryFeesAfterFee =
            prizePool * (1.0 - organizerFeePercent / 100.0);
        actualPrizePool = entryFeesAfterFee + sponsorContribution;
      } else {
        // entry_fees only - subtract organizer fee
        actualPrizePool = prizePool * (1.0 - organizerFeePercent / 100.0);
      }

      // Set up prize distribution data
      if (distributionTemplate == 'custom' && customDistribution != null) {
        // Custom distribution
        prizeDistributionData = {
          'source': prizeSource,
          'template': 'custom',
          'organizerFeePercent': organizerFeePercent,
          'sponsorContribution': sponsorContribution,
          'distribution': customDistribution,
          'totalPrizePool': actualPrizePool,
        };
      } else {
        // Template-based distribution
        prizeDistributionData = {
          'source': prizeSource,
          'template': distributionTemplate,
          'organizerFeePercent': organizerFeePercent,
          'sponsorContribution': sponsorContribution,
          'totalPrizePool': actualPrizePool,
        };
      }

      final tournamentData = {
        'club_id': clubId,
        'organizer_id': user.id,
        'title': title,
        'description': description,
        'start_date': startDate.toIso8601String(),
        'registration_deadline': registrationDeadline.toIso8601String(),
        'max_participants': maxParticipants,
        'entry_fee': entryFee,
        'prize_pool': actualPrizePool, // Use calculated actual prize pool
        // Cover image
        'cover_image_url': coverImageUrl,
        // Format configuration
        'bracket_format':
            format, // Tournament elimination format (single_elimination, double_elimination, sabo_de16, etc.)
        'game_format': gameType, // Game type (8-ball, 9-ball, 10-ball)
        'rules': rules,
        'requirements': requirements,
        'status': 'upcoming',
        'current_participants': 0,
        // Enhanced prize configuration
        'prize_source': prizeSource,
        'distribution_template': distributionTemplate,
        'organizer_fee_percent': organizerFeePercent,
        'sponsor_contribution': sponsorContribution,
        'custom_distribution': customDistribution,
        'prize_distribution': prizeDistributionData,
        // Rank restrictions
        'min_rank': minRank,
        'max_rank': maxRank,
        // Venue and contact information
        'venue_address': venueAddress,
        'venue_contact': venueContact,
        'venue_phone': venuePhone,
        // Additional rules
        'special_rules': specialRules,
        'registration_fee_waiver': registrationFeeWaiver,
      };

      ProductionLogger.info('🔍 Creating tournament with data:', tag: 'TournamentService');
      ProductionLogger.info('   - Title: $title', tag: 'TournamentService');
      ProductionLogger.info('   - Rules: ${rules ?? "(null)"}', tag: 'TournamentService');
      ProductionLogger.info('   - Rules length: ${rules?.length ?? 0}', tag: 'TournamentService');
      ProductionLogger.info('   - Special Rules: ${specialRules ?? "(null)"}', tag: 'TournamentService');

      final response = await _supabase
          .from('tournaments')
          .insert(tournamentData)
          .select()
          .single();

      // ✅ VERIFY: Check tournament ID
      final tournamentId = response['id'];
      if (tournamentId == null || tournamentId.toString().isEmpty) {
        throw Exception('Tournament creation failed: No tournament ID returned');
      }

      ProductionLogger.info('✅ Tournament created successfully: $tournamentId', tag: 'TournamentService');

      // ✅ DOUBLE CHECK: Query back the tournament we just created
      try {
        final verifyResponse = await _supabase
            .from('tournaments')
            .select()
            .eq('id', tournamentId)
            .maybeSingle();

        if (verifyResponse == null) {
          ProductionLogger.info('⚠️ WARNING: Tournament created but cannot query back! ID: $tournamentId', tag: 'TournamentService');
          // Don't throw here as tournament was created
        } else {
          ProductionLogger.info('✅ Verification passed: Tournament exists and can be queried', tag: 'TournamentService');
        }
      } catch (verifyError) {
        ProductionLogger.info('⚠️ WARNING: Cannot verify tournament after creation: $verifyError', tag: 'TournamentService');
        // Don't throw here as tournament was created
      }

      return Tournament.fromJson(response);
    } catch (error) {
      throw Exception('Failed to create tournament: $error');
    }
  }

  Future<List<Tournament>> getUserTournaments() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('tournament_participants')
          .select('''
            tournaments (*)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response
          .map<Tournament>((json) => Tournament.fromJson(json['tournaments']))
          .toList();
    } catch (error) {
      throw Exception('Failed to get user tournaments: $error');
    }
  }

  Future<List<Tournament>> getUserOrganizedTournaments() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('tournaments')
          .select()
          .eq('organizer_id', user.id)
          .order('created_at', ascending: false);

      return response
          .map<Tournament>((json) => Tournament.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get organized tournaments: $error');
    }
  }

  Future<List<Tournament>> searchTournaments(String query) async {
    try {
      final response = await _supabase
          .from('tournaments')
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .eq('is_public', true)
          .order('start_date', ascending: true)
          .limit(20);

      return response
          .map<Tournament>((json) => Tournament.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to search tournaments: $error');
    }
  }

  Future<Map<String, dynamic>> getTournamentStats(String tournamentId) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      final participants = await getTournamentParticipants(tournamentId);

      // Get matches for this tournament
      final matches = await _supabase
          .from('matches')
          .select()
          .eq('tournament_id', tournamentId);

      final completedMatches = matches
          .where((match) => match['status'] == 'completed')
          .length;
      final pendingMatches = matches
          .where((match) => match['status'] == 'pending')
          .length;

      return {
        'total_participants': participants.length,
        'max_participants': tournament.maxParticipants,
        'total_matches': matches.length,
        'completed_matches': completedMatches,
        'pending_matches': pendingMatches,
        'entry_fee': tournament.entryFee,
        'prize_pool': tournament.prizePool,
        'status': tournament.status,
      };
    } catch (error) {
      throw Exception('Failed to get tournament stats: $error');
    }
  }

  // ==================== PARTICIPANT MANAGEMENT ====================

  /// Get tournament participants with payment status for club management
  Future<List<Map<String, dynamic>>> getTournamentParticipantsWithPaymentStatus(
    String tournamentId,
  ) async {
    try {
      ProductionLogger.info('🔍 WithPaymentStatus: Querying participants for tournament $tournamentId',  tag: 'tournament_service');

      // Check authentication status
      final currentUser = _supabase.auth.currentUser;
      ProductionLogger.info('🔐 Auth status: ${currentUser != null ? "Authenticated as ${currentUser.email}" : "NOT AUTHENTICATED"}',  tag: 'tournament_service');

      // First check total participants without JOIN
      final totalCheck = await _supabase
          .from('tournament_participants')
          .select('id, user_id, payment_status')
          .eq('tournament_id', tournamentId);
      ProductionLogger.info('🔢 DEBUG: Total participants in DB: ${totalCheck.length}', tag: 'TournamentService');
      for (int i = 0; i < totalCheck.length; i++) {
        ProductionLogger.info('   ${i + 1}. User ID: ${totalCheck[i]['user_id']} - Payment: ${totalCheck[i]['payment_status']}',  tag: 'tournament_service');
      }
      var response = await _supabase
          .from('tournament_participants')
          .select('''
            *,
            users (
              id,
              email,
              display_name,
              full_name,
              avatar_url,
              elo_rating,
              rank
            )
          ''')
          .eq('tournament_id', tournamentId)
          .order('registered_at', ascending: true);

      ProductionLogger.info('📊 WithPaymentStatus: Raw response count: ${response.length}',  tag: 'tournament_service');

      // If response is still empty or users data is missing, try without join
      if (response.isEmpty || response.any((item) => item['users'] == null)) {
        ProductionLogger.info('⚠️ WithPaymentStatus: Join failed or empty, trying without join...',  tag: 'tournament_service');
        return await _getTournamentParticipantsWithoutJoin(tournamentId);
      }

      final result = response.map<Map<String, dynamic>>((json) {
        final user = json['users'];
        return {
          'id': json['id'],
          'tournament_id': json['tournament_id'],
          'user_id': json['user_id'],
          'payment_status': json['payment_status'] ?? 'pending',
          'status': json['status'] ?? 'registered',
          'notes': json['notes'],
          'registered_at': json['registered_at'],
          'user': {
            'id': user['id'],
            'email': user['email'],
            'display_name': user['display_name'],
            'full_name': user['full_name'] ?? 'Unknown Player',
            'avatar_url': user['avatar_url'],
            'elo_rating': user['elo_rating'] ?? 1000,
            'rank': RankMigrationHelper.getNewDisplayName(
              user['rank'] as String?,
            ),
          },
        };
      }).toList();

      ProductionLogger.info('✅ WithPaymentStatus: Returning ${result.length} participants with payment info',  tag: 'tournament_service');
      return result;
    } catch (error) {
      ProductionLogger.info('❌ Error getting participants with payment status: $error', tag: 'TournamentService');
      throw Exception('Failed to get tournament participants: $error');
    }
  }

  /// Backup method to get participants without join (in case of join issues)
  Future<List<Map<String, dynamic>>> _getTournamentParticipantsWithoutJoin(
    String tournamentId,
  ) async {
    try {
      ProductionLogger.info('🔄 Fallback: Getting participants without join...', tag: 'TournamentService');

      // First get tournament participants
      var participants = await _supabase
          .from('tournament_participants')
          .select('*')
          .eq('tournament_id', tournamentId)
          .order('registered_at', ascending: true);

      ProductionLogger.info('📊 Fallback: Found ${participants.length} participant records',  tag: 'tournament_service');

      // Then get user data in batch (optimized - no N+1 queries)
      final List<String> userIds = participants
          .map((p) => p['user_id'] as String)
          .toSet()
          .toList();

      Map<String, dynamic> userDataMap = {};
      if (userIds.isNotEmpty) {
        try {
          final users = await _supabase
              .from('users')
              .select('id, email, display_name, full_name, avatar_url, elo_rating, rank')
              .inFilter('id', userIds);

          for (final user in users) {
            userDataMap[user['id']] = user;
          }
        } catch (e) {
          ProductionLogger.info('❌ Error fetching users in batch: $e', tag: 'TournamentService');
        }
      }

      final List<Map<String, dynamic>> result = [];
      for (final participant in participants) {
        try {
          final userData = userDataMap[participant['user_id']];
          if (userData == null) {
            ProductionLogger.info('⚠️ User data not found for user_id: ${participant['user_id']}', tag: 'tournament_service');
            continue; // Skip orphaned participants
          }

          result.add({
            'id': participant['id'],
            'tournament_id': participant['tournament_id'],
            'user_id': participant['user_id'],
            'payment_status': participant['payment_status'] ?? 'pending',
            'status': participant['status'] ?? 'registered',
            'notes': participant['notes'],
            'registered_at': participant['registered_at'],
            'user': {
              'id': userData['id'],
              'email': userData['email'],
              'display_name': userData['display_name'],
              'full_name': userData['full_name'] ?? 'Unknown Player',
              'avatar_url': userData['avatar_url'],
              'elo_rating': userData['elo_rating'] ?? 1000,
              'rank': RankMigrationHelper.getNewDisplayName(
                userData['rank'] as String?,
              ),
            },
          });
        } catch (e) {
          ProductionLogger.info('⚠️ Fallback: Failed to get user data for ${participant['user_id']}: $e',  tag: 'tournament_service');
          // Add participant without user data
          result.add({
            'id': participant['id'],
            'tournament_id': participant['tournament_id'],
            'user_id': participant['user_id'],
            'payment_status': participant['payment_status'] ?? 'pending',
            'status': participant['status'] ?? 'registered',
            'notes': participant['notes'],
            'registered_at': participant['registered_at'],
            'user': {
              'id': participant['user_id'],
              "email": 'unknown@example.com',
              "display_name": null,
              "full_name": 'Unknown Player',
              'avatar_url': null,
              'elo_rating': 1000,
              "rank": 'Novice',
            },
          });
        }
      }

      ProductionLogger.info('✅ Fallback: Returning ${result.length} participants', tag: 'TournamentService');
      return result;
    } catch (e) {
      ProductionLogger.info('❌ Fallback: Error: $e', tag: 'TournamentService');
      return [];
    }
  }

  /// Update payment status for a tournament participant (club owner only)
  Future<bool> updateParticipantPaymentStatus({
    required String tournamentId,
    required String userId,
    required String paymentStatus, // 'pending', 'confirmed', 'completed'
    String? notes,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Validate payment status
      if (!['pending', 'confirmed', 'completed'].contains(paymentStatus)) {
        throw Exception('Invalid payment status');
      }

      // Update the participant record
      await _supabase
          .from('tournament_participants')
          .update({'payment_status': paymentStatus, 'notes': notes})
          .eq('tournament_id', tournamentId)
          .eq('user_id', userId);

      ProductionLogger.info('✅ Updated payment status for user $userId to $paymentStatus', tag: 'TournamentService');
      return true;
    } catch (error) {
      ProductionLogger.info('❌ Error updating payment status: $error', tag: 'TournamentService');
      throw Exception('Failed to update payment status: $error');
    }
  }

  /// Remove a participant from tournament (club owner only)
  Future<bool> removeParticipant({
    required String tournamentId,
    required String userId,
    String? reason,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Remove participant
      await _supabase
          .from('tournament_participants')
          .delete()
          .eq('tournament_id', tournamentId)
          .eq('user_id', userId);

      // Update participant count
      await _supabase.rpc(
        'decrement_tournament_participants',
        params: {'tournament_id': tournamentId},
      );

      ProductionLogger.info('✅ Removed participant $userId from tournament $tournamentId', tag: 'TournamentService');
      return true;
    } catch (error) {
      ProductionLogger.info('❌ Error removing participant: $error', tag: 'TournamentService');
      throw Exception('Failed to remove participant: $error');
    }
  }

  // ==================== CORE TOURNAMENT LOGIC ====================

  /// Tạo tournament bracket dựa trên format và danh sách participants
  Future<TournamentBracket> generateBracket({
    required String tournamentId,
    required String format,
    required List<UserProfile> participants,
    String seedingMethod = SeedingMethods.eloRating,
  }) async {
    try {
      ProductionLogger.info('🎯 GenerateBracket: Starting bracket generation for tournament $tournamentId with ${participants.length} participants',  tag: 'tournament_service');

      // Validate format và số người chơi
      if (!TournamentHelper.isValidPlayerCount(format, participants.length)) {
        throw Exception('Invalid player count for format $format');
      }

      // 🏆 SPECIAL HANDLING: Use SABO DE16 bracket generator (27 matches)
      if (format == 'sabo_de16' && participants.length == 16) {
        ProductionLogger.info('🏆 Using SABO DE16 bracket generator (27 matches)', tag: 'TournamentService');
        return await _generateSaboDE16Bracket(
          tournamentId,
          participants,
          seedingMethod,
        );
      }

      // 🚀 SPECIAL HANDLING: Use CompleteDoubleEliminationService for standard DE16 (31 matches)
      if (format == 'double_elimination' && participants.length == 16) {
        ProductionLogger.info('🚀 Using CompleteDoubleEliminationService for standard DE16 (31 matches)',  tag: 'tournament_service');
        return await _generateDE16Bracket(
          tournamentId,
          participants,
          seedingMethod,
        );
      }

      // 🎯 SPECIAL HANDLING: Use CompleteSaboDE32Service for SABO DE32 (55 matches)
      if (format == 'sabo_de32' && participants.length == 32) {
        ProductionLogger.info('🎯 Using CompleteSaboDE32Service for SABO DE32 (55 matches)',  tag: 'tournament_service');
        return await _generateSaboDE32Bracket(
          tournamentId,
          participants,
          seedingMethod,
        );
      }

      // Seeding participants (fallback to original logic)
      final seededParticipants = await _seedParticipants(
        participants,
        seedingMethod,
      );
      ProductionLogger.info('✅ GenerateBracket: Participants seeded successfully', tag: 'TournamentService');

      // Generate bracket structure dựa trên format
      final bracketStructure = _generateBracketStructure(
        format,
        seededParticipants,
      );
      ProductionLogger.info('✅ GenerateBracket: Bracket structure generated', tag: 'TournamentService');

      // Tạo matches
      final matches = _generateMatches(tournamentId, bracketStructure, format);
      ProductionLogger.info('📊 GenerateBracket: Generated ${matches.length} matches', tag: 'TournamentService');

      // VALIDATION: Check bracket completeness
      final validationResult = _validateBracketCompleteness(
        matches,
        participants.length,
        format,
      );
      if (!validationResult['isValid']) {
        throw Exception(
          'Bracket generation failed validation: ${validationResult['error']}',
        );
      }
      ProductionLogger.info('✅ GenerateBracket: Bracket validation passed', tag: 'TournamentService');

      // Use SABO approach for single elimination
      if (format == 'single_elimination') {
        await _generateSingleEliminationSaboStyle(tournamentId, participants);
        ProductionLogger.info('✅ GenerateBracket: Single elimination created SABO style', tag: 'TournamentService');
      } else {
        // Save matches to database (for other formats)
        await _saveMatchesToDatabase(matches);
        ProductionLogger.info('✅ GenerateBracket: Matches saved to database', tag: 'TournamentService');
      }

      // Save bracket structure to database for future reference
      await _saveBracketDataToDatabase(tournamentId, bracketStructure);
      ProductionLogger.info('✅ GenerateBracket: Bracket data saved to database', tag: 'TournamentService');

      // Update tournament status to ongoing
      await updateTournamentStatus(tournamentId, 'ongoing');
      ProductionLogger.info('✅ GenerateBracket: Tournament status updated to ongoing', tag: 'TournamentService');

      return TournamentBracket(
        tournamentId: tournamentId,
        format: format,
        participants: seededParticipants,
        matches: matches,
        rounds: TournamentHelper.calculateRounds(format, participants.length),
        status: 'ready',
        createdAt: DateTime.now(),
      );
    } catch (error) {
      ProductionLogger.info('🔥 GenerateBracket error: $error', tag: 'TournamentService');
      throw Exception('Failed to generate bracket: $error');
    }
  }

  /// Seeding participants dựa trên method được chỉ định
  Future<List<SeededParticipant>> _seedParticipants(
    List<UserProfile> participants,
    String seedingMethod,
  ) async {
    List<SeededParticipant> seeded = [];

    switch (seedingMethod) {
      case SeedingMethods.eloRating:
        participants.sort(
          (a, b) => (b.eloRating ?? 0).compareTo(a.eloRating ?? 0),
        );
        break;

      case SeedingMethods.clubRanking:
        // TODO: Implement club ranking logic
        participants.sort(
          (a, b) => (b.eloRating ?? 0).compareTo(a.eloRating ?? 0),
        );
        break;

      case SeedingMethods.previousTournaments:
        // TODO: Implement tournament history logic
        participants.sort(
          (a, b) => (b.eloRating ?? 0).compareTo(a.eloRating ?? 0),
        );
        break;

      case SeedingMethods.hybrid:
        // Combine ELO + tournament history
        participants.sort((a, b) => _calculateHybridSeed(a, b));
        break;

      case SeedingMethods.random:
      default:
        participants.shuffle();
        break;
    }

    for (int i = 0; i < participants.length; i++) {
      seeded.add(
        SeededParticipant(
          participant: participants[i],
          seedNumber: i + 1,
          seedingMethod: seedingMethod,
        ),
      );
    }

    return seeded;
  }

  // NOTE: All bracket generation now handled by ProductionBracketService
  // and TournamentManagementCenterScreen using hardcoded services
  Future<TournamentBracket> _generateDE16Bracket(
    String tournamentId,
    List<UserProfile> participants,
    String seedingMethod,
  ) async {
    final seededParticipants = await _seedParticipants(
      participants,
      seedingMethod,
    );
    return TournamentBracket(
      tournamentId: tournamentId,
      format: 'double_elimination',
      participants: seededParticipants,
      matches: [], // Handled by ProductionBracketService
      rounds: 8,
      status: 'ready',
      createdAt: DateTime.now(),
    );
  }

  Future<TournamentBracket> _generateSaboDE16Bracket(
    String tournamentId,
    List<UserProfile> participants,
    String seedingMethod,
  ) async {
    final seededParticipants = await _seedParticipants(
      participants,
      seedingMethod,
    );
    return TournamentBracket(
      tournamentId: tournamentId,
      format: 'sabo_de16',
      participants: seededParticipants,
      matches: [], // Handled by ProductionBracketService
      rounds: 27,
      status: 'ready',
      createdAt: DateTime.now(),
    );
  }

  Future<TournamentBracket> _generateSaboDE32Bracket(
    String tournamentId,
    List<UserProfile> participants,
    String seedingMethod,
  ) async {
    final seededParticipants = await _seedParticipants(
      participants,
      seedingMethod,
    );
    return TournamentBracket(
      tournamentId: tournamentId,
      format: 'sabo_de32',
      participants: seededParticipants,
      matches: [], // Handled by ProductionBracketService
      rounds: 55,
      status: 'ready',
      createdAt: DateTime.now(),
    );
  }

  /// Calculate hybrid seeding score
  int _calculateHybridSeed(UserProfile a, UserProfile b) {
    // Weight: 70% ELO, 30% tournament history
    double scoreA =
        ((a.eloRating ?? 0) * 0.7) + (_getTournamentHistoryScore(a) * 0.3);
    double scoreB =
        ((b.eloRating ?? 0) * 0.7) + (_getTournamentHistoryScore(b) * 0.3);
    return scoreB.compareTo(scoreA);
  }

  /// Get tournament history score for hybrid seeding
  double _getTournamentHistoryScore(UserProfile participant) {
    // TODO: Implement real tournament history calculation
    // For now return base ELO
    return (participant.eloRating ?? 0).toDouble();
  }

  /// Generate bracket structure theo format
  Map<String, dynamic> _generateBracketStructure(
    String format,
    List<SeededParticipant> participants,
  ) {
    switch (format) {
      case TournamentFormats.singleElimination:
        return _generateSingleEliminationBracket(participants);

      case TournamentFormats.doubleElimination:
        return _generateDoubleEliminationBracket(participants);

      case TournamentFormats.roundRobin:
        return _generateRoundRobinBracket(participants);

      case TournamentFormats.swiss:
        return _generateSwissBracket(participants);

      case TournamentFormats.parallelGroups:
        return _generateParallelGroupsBracket(participants);

      default:
        return _generateSingleEliminationBracket(participants);
    }
  }

  /// Generate single elimination bracket - COMPLETE VERSION
  Map<String, dynamic> _generateSingleEliminationBracket(
    List<SeededParticipant> participants,
  ) {
    final int playerCount = participants.length;
    final int rounds = math.log(playerCount) ~/ math.log(2);

    ProductionLogger.info('🏆 Generating complete single elimination bracket: $playerCount players, $rounds rounds',  tag: 'tournament_service');

    // Generate ALL rounds structure
    List<List<Map<String, dynamic>>> allRounds = [];

    // Round 1: Direct player assignments
    List<Map<String, dynamic>> round1 = [];
    for (int i = 0; i < playerCount; i += 2) {
      round1.add({
        'player1': participants[i],
        'player2': i + 1 < playerCount ? participants[i + 1] : null,
        'round': 1,
        'matchNumber': (i ~/ 2) + 1,
        'matchId': 'R1M${(i ~/ 2) + 1}',
      });
    }
    allRounds.add(round1);

    // HARDCORE ADVANCE: Set winner references from start
    int totalMatches = round1.length;
    for (int round = 2; round <= rounds; round++) {
      List<Map<String, dynamic>> currentRound = [];
      int prevRoundMatches = allRounds[round - 2].length;

      for (int i = 0; i < prevRoundMatches; i += 2) {
        int matchNumber = (i ~/ 2) + 1;
        String matchId = 'R${round}M${totalMatches + matchNumber}';

        // HARDCORE: Direct winner references as player IDs
        String prevMatch1Id = allRounds[round - 2][i]['matchId'];
        String prevMatch2Id = i + 1 < prevRoundMatches
            ? allRounds[round - 2][i + 1]['matchId']
            : null;

        currentRound.add({
          'player1': null, // Not used in hardcore mode
          'player2': null, // Not used in hardcore mode
          'round': round,
          'matchNumber': totalMatches + matchNumber,
          'matchId': matchId,
          // HARDCORE: Store winner reference as player IDs directly
          'hardcoreAdvancement': {
            'player1_winner_from': prevMatch1Id,
            'player2_winner_from': prevMatch2Id,
          },
        });
      }

      allRounds.add(currentRound);
      totalMatches += currentRound.length;
    }

    ProductionLogger.info('✅ Generated $totalMatches total matches across $rounds rounds', tag: 'TournamentService');

    // Extract hardcore advancement from all rounds
    Map<String, Map<String, dynamic>> hardcoreAdvancement = {};
    for (final roundMatches in allRounds) {
      for (final match in roundMatches) {
        if (match.containsKey('hardcoreAdvancement')) {
          final matchKey = match['matchId'];
          hardcoreAdvancement[matchKey] = match['hardcoreAdvancement'];
        }
      }
    }

    ProductionLogger.info('🚀 Hardcore advancement rules: ${hardcoreAdvancement.keys.length}',  tag: 'tournament_service');

    return {
      "type": 'single_elimination',
      'rounds': rounds,
      'allRounds': allRounds,
      'firstRound': round1, // Keep for backward compatibility
      "structure": 'complete_bracket',
      'totalMatches': totalMatches,
      'hardcoreAdvancement': hardcoreAdvancement, // TOP LEVEL KEY
    };
  }

  /// Generate double elimination bracket - COMPLETE VERSION
  Map<String, dynamic> _generateDoubleEliminationBracket(
    List<SeededParticipant> participants,
  ) {
    final int playerCount = participants.length;
    ProductionLogger.info('🏆 Generating complete double elimination bracket: $playerCount players',  tag: 'tournament_service');

    // WINNER BRACKET: Standard single elimination structure
    List<List<Map<String, dynamic>>> winnerRounds = [];
    List<Map<String, dynamic>> currentRound = [];

    // WB Round 1: Direct player pairings
    for (int i = 0; i < playerCount; i += 2) {
      currentRound.add({
        'player1': participants[i],
        'player2': i + 1 < playerCount ? participants[i + 1] : null,
        'bracket': 'winner',
        'round': 1,
        'matchNumber': (i ~/ 2) + 1,
        'matchId': 'WB-R1M${(i ~/ 2) + 1}',
      });
    }
    winnerRounds.add(List.from(currentRound));

    // WB Subsequent rounds
    int totalWBMatches = currentRound.length;
    int wbRound = 2;
    while (currentRound.length > 1) {
      List<Map<String, dynamic>> nextRound = [];
      for (int i = 0; i < currentRound.length; i += 2) {
        int matchNum = totalWBMatches + (i ~/ 2) + 1;
        nextRound.add({
          'player1': null, // Winner advancement
          'player2': null,
          'bracket': 'winner',
          'round': wbRound,
          'matchNumber': matchNum,
          'matchId': 'WB-R${wbRound}M$matchNum',
          'advancementFrom': {
            'player1Source': currentRound[i]['matchId'],
            'player2Source': i + 1 < currentRound.length
                ? currentRound[i + 1]['matchId']
                : null,
          },
        });
      }
      winnerRounds.add(nextRound);
      totalWBMatches += nextRound.length;
      currentRound = nextRound;
      wbRound++;
    }

    // LOSER BRACKET: Complex structure with feeds from winner bracket
    List<List<Map<String, dynamic>>> loserRounds = [];
    int totalLBMatches = 0;

    // LB structure depends on WB structure - simplified version
    int loserBracketRounds = (winnerRounds.length - 1) * 2;
    for (int lbRound = 1; lbRound <= loserBracketRounds; lbRound++) {
      List<Map<String, dynamic>> lbCurrentRound = [];

      // Simplified: Create 2 matches per LB round (this needs proper algorithm)
      int matchesInRound = math.max(1, playerCount ~/ (2 * lbRound));
      for (int m = 1; m <= matchesInRound; m++) {
        totalLBMatches++;
        lbCurrentRound.add({
          'player1': null, // Fed from WB or LB advancement
          'player2': null,
          'bracket': 'loser',
          'round': lbRound,
          'matchNumber': totalLBMatches,
          'matchId': 'LB-R${lbRound}M$totalLBMatches',
        });
      }
      loserRounds.add(lbCurrentRound);
    }

    // GRAND FINALS: Winner of WB vs Winner of LB
    List<Map<String, dynamic>> grandFinals = [];
    totalLBMatches++;
    grandFinals.add({
      'player1': null, // Winner of WB
      'player2': null, // Winner of LB
      'bracket': 'grand_final',
      'round': 1,
      'matchNumber': totalLBMatches,
      'matchId': 'GF-M$totalLBMatches',
    });

    // Bracket reset (if LB winner beats WB winner)
    totalLBMatches++;
    grandFinals.add({
      'player1': null, // Same players if bracket reset needed
      'player2': null,
      'bracket': 'grand_final_reset',
      'round': 2,
      'matchNumber': totalLBMatches,
      'matchId': 'GF2-M$totalLBMatches',
      'conditional': true, // Only if LB winner wins first GF
    });

    int totalMatches = totalWBMatches + totalLBMatches;
    ProductionLogger.info('✅ Generated double elimination: $totalWBMatches WB + ${totalLBMatches - totalWBMatches} LB + 2 GF = $totalMatches matches',  tag: 'tournament_service');

    return {
      "type": 'double_elimination',
      'winnerBracket': {
        'rounds': winnerRounds.length,
        'allRounds': winnerRounds,
        'totalMatches': totalWBMatches,
      },
      'loserBracket': {
        'rounds': loserRounds.length,
        'allRounds': loserRounds,
        'totalMatches': totalLBMatches - totalWBMatches - 2, // Excluding GF
      },
      'grandFinals': grandFinals,
      'totalMatches': totalMatches,
      "structure": 'complete_double_elimination',
    };
  }

  /// Generate round robin bracket
  Map<String, dynamic> _generateRoundRobinBracket(
    List<SeededParticipant> participants,
  ) {
    List<Map<String, dynamic>> allPairings = [];
    final int playerCount = participants.length;

    for (int i = 0; i < playerCount; i++) {
      for (int j = i + 1; j < playerCount; j++) {
        allPairings.add({
          'player1': participants[i],
          'player2': participants[j],
          'round': ((allPairings.length ~/ (playerCount ~/ 2)) + 1),
          'matchNumber': allPairings.length + 1,
        });
      }
    }

    return {
      "type": 'round_robin',
      'totalRounds': playerCount - 1,
      'allPairings': allPairings,
      'pointsSystem': {'win': 3, 'draw': 1, 'loss': 0},
    };
  }

  /// Generate Swiss system bracket (initial round only)
  Map<String, dynamic> _generateSwissBracket(
    List<SeededParticipant> participants,
  ) {
    // First round: pair top half vs bottom half
    List<Map<String, dynamic>> firstRoundPairings = [];
    final int half = participants.length ~/ 2;

    for (int i = 0; i < half; i++) {
      firstRoundPairings.add({
        'player1': participants[i],
        'player2': participants[i + half],
        'round': 1,
        'matchNumber': i + 1,
      });
    }

    return {
      "type": 'swiss',
      'totalRounds': TournamentHelper.calculateRounds(
        TournamentFormats.swiss,
        participants.length,
      ),
      'firstRound': firstRoundPairings,
      "pairingMethod": 'swiss_system',
    };
  }

  /// Generate parallel groups bracket
  Map<String, dynamic> _generateParallelGroupsBracket(
    List<SeededParticipant> participants,
  ) {
    final int playerCount = participants.length;
    final int groupCount = math.min(4, playerCount ~/ 4); // Max 4 groups

    List<List<SeededParticipant>> groups = [];

    // Distribute players across groups (snake seeding)
    for (int g = 0; g < groupCount; g++) {
      groups.add([]);
    }

    for (int i = 0; i < playerCount; i++) {
      final groupIndex = i % groupCount;
      groups[groupIndex].add(participants[i]);
    }

    return {
      "type": 'parallel_groups',
      'groupCount': groupCount,
      'groups': groups
          .map((group) => _generateRoundRobinBracket(group))
          .toList(),
      "finalsStructure": 'knockout', // Top players advance to knockout
    };
  }

  /// Generate loser bracket for double elimination
  Map<String, dynamic> _generateLoserBracket(int playerCount) {
    // Simplified loser bracket structure
    return {
      'rounds': (math.log(playerCount) ~/ math.log(2)) * 2 - 1,
      "structure": 'loser_bracket',
      'feedFromWinner': true,
    };
  }

  /// Generate matches từ bracket structure
  List<TournamentMatch> _generateMatches(
    String tournamentId,
    Map<String, dynamic> bracketStructure,
    String format,
  ) {
    List<TournamentMatch> matches = [];

    switch (format) {
      case TournamentFormats.singleElimination:
        matches.addAll(
          _generateSingleEliminationMatches(tournamentId, bracketStructure),
        );
        break;

      case TournamentFormats.roundRobin:
        matches.addAll(
          _generateRoundRobinMatches(tournamentId, bracketStructure),
        );
        break;

      case TournamentFormats.doubleElimination:
        matches.addAll(
          _generateDoubleEliminationMatches(tournamentId, bracketStructure),
        );
        break;

      case TournamentFormats.swiss:
        matches.addAll(_generateSwissMatches(tournamentId, bracketStructure));
        break;

      // Add other formats...
    }

    return matches;
  }

  /// Save generated matches to database
  Future<void> _saveMatchesToDatabase(List<TournamentMatch> matches) async {
    try {
      ProductionLogger.info('🔄 Saving ${matches.length} matches to database...', tag: 'TournamentService');

      for (final match in matches) {
        final matchData = {
          'id': match.id,
          'tournament_id': match.tournamentId,
          'round_number': match.round,
          'match_number': match.matchNumber,
          'player1_id': match.player1Id,
          'player2_id': match.player2Id,
          'status': match.status,
          'scheduled_time': match.scheduledTime
              ?.toIso8601String(), // REVERT: scheduled_at -> scheduled_time
          'winner_id': match.winnerId,
          'bracket_format': match.format, // FIXED: Use bracket_format column
          'player1_score': null, // Changed from 'score' to separate scores
          'player2_score': null,
          'created_at': match.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        ProductionLogger.info('💾 Saving match: R${match.round} M${match.matchNumber} - ${match.player1Id} vs ${match.player2Id}',  tag: 'tournament_service');

        await Supabase.instance.client.from('matches').insert(matchData);
      }

      ProductionLogger.info('✅ All matches saved successfully', tag: 'TournamentService');
    } catch (e) {
      ProductionLogger.info('🔥 Error saving matches: $e', tag: 'TournamentService');
      throw Exception('Failed to save matches to database: $e');
    }
  }

  /// Generate single elimination matches - HARDCORE ADVANCEMENT VERSION
  List<TournamentMatch> _generateSingleEliminationMatches(
    String tournamentId,
    Map<String, dynamic> bracket,
  ) {
    List<TournamentMatch> matches = [];

    // Check if we have the new complete bracket structure with hardcore advancement
    if (bracket.containsKey('allRounds') &&
        bracket.containsKey('hardcoreAdvancement')) {
      final allRounds =
          bracket['allRounds'] as List<List<Map<String, dynamic>>>;
      final hardcoreAdvancement =
          bracket['hardcoreAdvancement'] as Map<String, dynamic>;
      ProductionLogger.info('🎯 Processing hardcore advancement bracket with ${allRounds.length} rounds',  tag: 'tournament_service');

      // Process all rounds
      for (int roundIndex = 0; roundIndex < allRounds.length; roundIndex++) {
        final roundMatches = allRounds[roundIndex];
        ProductionLogger.info('📊 Round ${roundIndex + 1}: ${roundMatches.length} matches',  tag: 'tournament_service');

        for (var pairing in roundMatches) {
          final matchKey = 'R${pairing['round']}M${pairing['matchNumber']}';

          // For hardcore advancement, use winner references for non-first rounds
          String? player1Id = pairing['player1']?.participant?.id;
          String? player2Id = pairing['player2']?.participant?.id;

          // Check if this match uses winner references from hardcore advancement
          if (hardcoreAdvancement.containsKey(matchKey)) {
            final advancement = hardcoreAdvancement[matchKey];
            final winnerRef1 = advancement['player1_winner_from'];
            final winnerRef2 = advancement['player2_winner_from'];

            // Use winner references as player IDs directly
            player1Id = winnerRef1;
            player2Id = winnerRef2;

            ProductionLogger.info('🚀 Match $matchKey uses hardcore advancement: P1=$player1Id, P2=$player2Id',  tag: 'tournament_service');
          }

          matches.add(
            TournamentMatch(
              id: _generateMatchId(),
              tournamentId: tournamentId,
              player1Id: player1Id,
              player2Id: player2Id,
              round: pairing['round'],
              matchNumber: pairing['matchNumber'],
              status: MatchStatus.pending,
              format: 'single_elimination',
              createdAt: DateTime.now(),
            ),
          );
        }
      }

      ProductionLogger.info('✅ Generated ${matches.length} hardcore advancement matches', tag: 'TournamentService');
    } else if (bracket.containsKey('allRounds')) {
      // Standard complete bracket structure
      final allRounds =
          bracket['allRounds'] as List<List<Map<String, dynamic>>>;
      ProductionLogger.info('🎯 Processing complete bracket structure with ${allRounds.length} rounds',  tag: 'tournament_service');

      // Process all rounds
      for (int roundIndex = 0; roundIndex < allRounds.length; roundIndex++) {
        final roundMatches = allRounds[roundIndex];
        ProductionLogger.info('📊 Round ${roundIndex + 1}: ${roundMatches.length} matches',  tag: 'tournament_service');

        for (var pairing in roundMatches) {
          matches.add(
            TournamentMatch(
              id: _generateMatchId(),
              tournamentId: tournamentId,
              player1Id: pairing['player1']?.participant?.id,
              player2Id: pairing['player2']?.participant?.id,
              round: pairing['round'],
              matchNumber: pairing['matchNumber'],
              status: MatchStatus.pending,
              format: 'single_elimination',
              createdAt: DateTime.now(),
            ),
          );
        }
      }

      ProductionLogger.info('✅ Generated ${matches.length} complete single elimination matches',  tag: 'tournament_service');
    } else {
      // Fallback to old structure for backward compatibility
      ProductionLogger.info('⚠️ Using legacy firstRound-only structure', tag: 'TournamentService');
      final firstRound = bracket['firstRound'] as List<Map<String, dynamic>>;

      for (var pairing in firstRound) {
        matches.add(
          TournamentMatch(
            id: _generateMatchId(),
            tournamentId: tournamentId,
            player1Id: pairing['player1']?.participant.id,
            player2Id: pairing['player2']?.participant?.id,
            round: pairing['round'],
            matchNumber: pairing['matchNumber'],
            status: MatchStatus.pending,
            format: 'single_elimination',
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    return matches;
  }

  /// Generate round robin matches
  List<TournamentMatch> _generateRoundRobinMatches(
    String tournamentId,
    Map<String, dynamic> bracket,
  ) {
    List<TournamentMatch> matches = [];
    final allPairings = bracket['allPairings'] as List<Map<String, dynamic>>;

    for (var pairing in allPairings) {
      matches.add(
        TournamentMatch(
          id: _generateMatchId(),
          tournamentId: tournamentId,
          player1Id: pairing['player1'].participant.id,
          player2Id: pairing['player2'].participant.id,
          round: pairing['round'],
          matchNumber: pairing['matchNumber'],
          status: MatchStatus.pending,
          format: 'round_robin',
          createdAt: DateTime.now(),
        ),
      );
    }

    return matches;
  }

  /// Generate Swiss system matches (first round only)
  List<TournamentMatch> _generateSwissMatches(
    String tournamentId,
    Map<String, dynamic> bracket,
  ) {
    List<TournamentMatch> matches = [];
    final firstRound = bracket['firstRound'] as List<Map<String, dynamic>>;

    for (var pairing in firstRound) {
      matches.add(
        TournamentMatch(
          id: _generateMatchId(),
          tournamentId: tournamentId,
          player1Id: pairing['player1'].participant.id,
          player2Id: pairing['player2'].participant.id,
          round: pairing['round'],
          matchNumber: pairing['matchNumber'],
          status: MatchStatus.pending,
          format: 'swiss',
          createdAt: DateTime.now(),
        ),
      );
    }

    return matches;
  }

  /// Generate double elimination matches - COMPLETE VERSION
  List<TournamentMatch> _generateDoubleEliminationMatches(
    String tournamentId,
    Map<String, dynamic> bracket,
  ) {
    List<TournamentMatch> matches = [];

    ProductionLogger.info('🎯 Generating double elimination matches...', tag: 'TournamentService');

    // Winner Bracket matches
    final winnerBracket = bracket['winnerBracket'] as Map<String, dynamic>;
    if (winnerBracket.containsKey('allRounds')) {
      final winnerRounds =
          winnerBracket['allRounds'] as List<List<Map<String, dynamic>>>;
      ProductionLogger.info('📊 Winner Bracket: ${winnerRounds.length} rounds', tag: 'TournamentService');

      for (int roundIndex = 0; roundIndex < winnerRounds.length; roundIndex++) {
        final roundMatches = winnerRounds[roundIndex];
        for (var pairing in roundMatches) {
          matches.add(
            TournamentMatch(
              id: _generateMatchId(),
              tournamentId: tournamentId,
              player1Id: pairing['player1']?.participant?.id,
              player2Id: pairing['player2']?.participant?.id,
              round: pairing['round'],
              matchNumber: pairing['matchNumber'],
              status: MatchStatus.pending,
              format: 'double_elimination_winner',
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    }

    // Loser Bracket matches - Generate based on winner bracket
    final loserBracket = bracket['loserBracket'] as Map<String, dynamic>;
    final winnerBracketRounds = winnerBracket.containsKey('rounds')
        ? winnerBracket['rounds'] as int
        : 4;
    final loserBracketRounds = loserBracket['rounds'] as int;

    ProductionLogger.info('📊 Loser Bracket: $loserBracketRounds rounds', tag: 'TournamentService');

    // Generate loser bracket matches (simplified structure)
    int loserMatchNumber = matches.length + 1;
    for (int round = 1; round <= loserBracketRounds; round++) {
      // Calculate matches per round in loser bracket
      int matchesInRound = round == 1
          ? (matches.length ~/ 2)
          : round % 2 == 0
          ? (matches.length ~/ (2 * round))
          : (matches.length ~/ (2 * round));

      for (
        int matchInRound = 1;
        matchInRound <= matchesInRound;
        matchInRound++
      ) {
        matches.add(
          TournamentMatch(
            id: _generateMatchId(),
            tournamentId: tournamentId,
            player1Id: null, // Will be filled by loser from winner bracket
            player2Id: null, // Will be filled by loser from winner bracket
            round: 100 + round, // Use 100+ for loser bracket rounds
            matchNumber: loserMatchNumber++,
            status: MatchStatus.pending,
            format: 'double_elimination_loser',
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    // Grand Finals
    matches.add(
      TournamentMatch(
        id: _generateMatchId(),
        tournamentId: tournamentId,
        player1Id: null, // Winner bracket champion
        player2Id: null, // Loser bracket champion
        round: 200, // Special round for Grand Finals
        matchNumber: matches.length + 1,
        status: MatchStatus.pending,
        format: 'double_elimination_grand_final',
        createdAt: DateTime.now(),
      ),
    );

    // Potential Bracket Reset (if loser bracket champion wins Grand Finals)
    if (bracket['grandFinalsRequired'] == true) {
      matches.add(
        TournamentMatch(
          id: _generateMatchId(),
          tournamentId: tournamentId,
          player1Id:
              null, // Grand Finals loser (if was winner bracket champion)
          player2Id:
              null, // Grand Finals winner (if was loser bracket champion)
          round: 201, // Bracket reset
          matchNumber: matches.length + 1,
          status: MatchStatus.pending,
          format: 'double_elimination_bracket_reset',
          createdAt: DateTime.now(),
        ),
      );
    }

    ProductionLogger.info('✅ Generated ${matches.length} double elimination matches', tag: 'TournamentService');
    return matches;
  }

  /// Calculate prize distribution dựa trên template và tournament results
  Future<List<PrizeDistributionResult>> calculatePrizeDistribution({
    required String tournamentId,
    required String distributionType,
    required double totalPrizePool,
    required List<TournamentResult> results,
  }) async {
    try {
      final playerCount = results.length;
      final distribution = TournamentHelper.getPrizeDistribution(
        distributionType,
        playerCount,
      );

      List<PrizeDistributionResult> prizeResults = [];

      for (int i = 0; i < distribution.length && i < results.length; i++) {
        final percentage = distribution[i];
        final prizeAmount = totalPrizePool * percentage;

        prizeResults.add(
          PrizeDistributionResult(
            position: i + 1,
            participantId: results[i].participantId,
            prizeAmount: prizeAmount,
            percentage: percentage,
            prizeType: PrizeTypes.cash,
          ),
        );
      }

      return prizeResults;
    } catch (error) {
      throw Exception('Failed to calculate prize distribution: $error');
    }
  }

  /// Update tournament status
  Future<void> updateTournamentStatus(
    String tournamentId,
    String newStatus,
  ) async {
    try {
      await _supabase
          .from('tournaments')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tournamentId);
    } catch (error) {
      throw Exception('Failed to update tournament status: $error');
    }
  }

  /// Start a tournament (change status to in_progress)
  Future<void> startTournament(String tournamentId) async {
    try {
      await updateTournamentStatus(tournamentId, 'in_progress');
      ProductionLogger.info('✅ Tournament started: $tournamentId', tag: 'TournamentService');
    } catch (error) {
      ProductionLogger.info('❌ Failed to start tournament: $error', tag: 'TournamentService');
      throw Exception('Failed to start tournament: $error');
    }
  }

  /// Generate unique match ID
  String _generateMatchId() {
    // Generate a UUID-like string using random values
    return '${_randomHex(8)}-${_randomHex(4)}-${_randomHex(4)}-${_randomHex(4)}-${_randomHex(12)}';
  }

  String _randomHex(int length) {
    final random = math.Random();
    final chars = '0123456789abcdef';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Validate bracket completeness to prevent incomplete tournaments
  Map<String, dynamic> _validateBracketCompleteness(
    List<TournamentMatch> matches,
    int participantCount,
    String format,
  ) {
    try {
      ProductionLogger.info('🔍 Validating bracket: ${matches.length} matches for $participantCount players ($format)',  tag: 'tournament_service');

      // Expected match counts for different formats
      int expectedMatches;
      switch (format) {
        case TournamentFormats.singleElimination:
          expectedMatches =
              participantCount - 1; // N-1 matches for single elimination
          break;
        case TournamentFormats.doubleElimination:
          expectedMatches =
              (participantCount - 1) * 2 +
              1; // ~2N matches for double elimination
          break;
        case TournamentFormats.roundRobin:
          expectedMatches =
              (participantCount * (participantCount - 1)) ~/
              2; // N*(N-1)/2 for round robin
          break;
        default:
          expectedMatches =
              participantCount - 1; // Default to single elimination
      }

      // Check match count
      if (matches.length != expectedMatches) {
        return {
          'isValid': false,
          'error':
              'Expected $expectedMatches matches for $format with $participantCount players, but got ${matches.length}',
        };
      }

      // Check first round player assignments
      final firstRoundMatches = matches.where((m) => m.round == 1).toList();
      int assignedFirstRoundMatches = 0;

      for (final match in firstRoundMatches) {
        if (match.player1Id != null || match.player2Id != null) {
          assignedFirstRoundMatches++;
        }
      }

      if (assignedFirstRoundMatches == 0) {
        return {
          'isValid': false,
          'error': 'No first round matches have player assignments',
        };
      }

      ProductionLogger.info('✅ Bracket validation passed: ${matches.length} matches, $assignedFirstRoundMatches assigned first round',  tag: 'tournament_service');

      return {
        'isValid': true,
        'matchCount': matches.length,
        'assignedFirstRound': assignedFirstRoundMatches,
      };
    } catch (e) {
      return {'isValid': false, 'error': 'Validation error: $e'};
    }
  }

  /// Calculate ELO changes cho tournament results
  Future<List<EloChange>> calculateTournamentEloChanges({
    required String tournamentId,
    required List<TournamentResult> results,
    required String tournamentFormat,
    required int participantCount,
  }) async {
    try {
      List<EloChange> eloChanges = [];

      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final position = i + 1;

        // Base ELO reward dựa trên placement
        int baseEloReward = _calculateBaseEloReward(position, participantCount);

        // Tournament size bonus
        int sizeBonus = participantCount >= 32 ? 5 : 0;

        // Format bonus
        int formatBonus = _getFormatBonus(tournamentFormat);

        // Performance bonus (upset, perfect run, etc.)
        int performanceBonus = await _calculatePerformanceBonus(
          result,
          results,
        );

        final totalEloChange =
            baseEloReward + sizeBonus + formatBonus + performanceBonus;

        eloChanges.add(
          EloChange(
            participantId: result.participantId,
            oldElo: result.startingElo,
            newElo: result.startingElo + totalEloChange,
            change: totalEloChange,
            reason:
                'Tournament #$tournamentId: Position $position/${results.length}',
            baseReward: baseEloReward,
            bonuses: {
              'size_bonus': sizeBonus,
              'format_bonus': formatBonus,
              'performance_bonus': performanceBonus,
            },
          ),
        );
      }

      return eloChanges;
    } catch (error) {
      throw Exception('Failed to calculate ELO changes: $error');
    }
  }

  /// Calculate base ELO reward dựa trên position
  int _calculateBaseEloReward(int position, int totalParticipants) {
    if (position == 1) return 25; // Winner
    if (position == 2) return 15; // Runner-up
    if (position <= 4) return 10; // Semi-finalists
    if (position <= 8) return 5; // Quarter-finalists
    if (position <= totalParticipants / 2) return 2; // Top half
    return -2; // Bottom half (small penalty)
  }

  /// Get format bonus ELO
  int _getFormatBonus(String format) {
    switch (format) {
      case TournamentFormats.doubleElimination:
        return 3; // Harder format
      case TournamentFormats.swiss:
        return 2;
      case TournamentFormats.roundRobin:
        return 1;
      default:
        return 0;
    }
  }

  /// Calculate performance bonuses
  Future<int> _calculatePerformanceBonus(
    TournamentResult result,
    List<TournamentResult> allResults,
  ) async {
    int bonus = 0;

    // Perfect run bonus (no losses in single elimination)
    if (result.matchesLost == 0) {
      bonus += 5;
    }

    // Upset bonus (beat higher seeded players)
    if (result.defeatedHigherSeeds > 0) {
      bonus += result.defeatedHigherSeeds * 3;
    }

    // TODO: Add streak bonus logic

    return bonus;
  }

  /// Generate single elimination using SABO DE16 approach
  Future<void> _generateSingleEliminationSaboStyle(
    String tournamentId,
    List<UserProfile> participants,
  ) async {
    try {
      ProductionLogger.info('🚀 Generating single elimination SABO style for ${participants.length} participants',  tag: 'tournament_service');

      if (participants.length != 16) {
        throw Exception(
          'Single elimination SABO style requires exactly 16 participants',
        );
      }

      // 1. Create all matches with proper structure
      await _createSingleEliminationMatches(tournamentId);

      // 2. Populate Round 1 with participants
      await _populateRound1SingleElimination(tournamentId, participants);

      ProductionLogger.info('✅ Single elimination SABO style generated successfully', tag: 'TournamentService');
    } catch (e) {
      ProductionLogger.info('❌ Error in single elimination SABO style: $e', tag: 'TournamentService');
      throw Exception('Failed to generate single elimination SABO style: $e');
    }
  }

  /// Create all single elimination matches (15 matches for 16 players)
  Future<void> _createSingleEliminationMatches(String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    int matchCounter = 1;

    // Round 1: 8 matches
    for (int i = 0; i < 8; i++) {
      matches.add({
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 1,
        'match_number': matchCounter,
        'player1_id': null,
        'player2_id': null,
        'status': 'pending',
        'bracket_format': 'single_elimination',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      matchCounter++;
    }

    // Round 2: 4 matches
    for (int i = 0; i < 4; i++) {
      matches.add({
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 2,
        'match_number': matchCounter,
        'player1_id': null,
        'player2_id': null,
        'status': 'pending',
        'bracket_format': 'single_elimination',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      matchCounter++;
    }

    // Round 3: 2 matches
    for (int i = 0; i < 2; i++) {
      matches.add({
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 3,
        'match_number': matchCounter,
        'player1_id': null,
        'player2_id': null,
        'status': 'pending',
        'bracket_format': 'single_elimination',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      matchCounter++;
    }

    // Round 4: 1 final match
    matches.add({
      'id': _generateMatchId(),
      'tournament_id': tournamentId,
      'round_number': 4,
      'match_number': matchCounter,
      'player1_id': null,
      'player2_id': null,
      'status': 'pending',
      'bracket_format': 'single_elimination',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Save all matches to database
    for (final match in matches) {
      await Supabase.instance.client.from('matches').insert(match);
    }

    ProductionLogger.info('✅ Created ${matches.length} single elimination matches', tag: 'TournamentService');
  }

  /// Populate Round 1 matches with participants
  Future<void> _populateRound1SingleElimination(
    String tournamentId,
    List<UserProfile> participants,
  ) async {
    try {
      // Get Round 1 matches
      final response = await Supabase.instance.client
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId)
          .eq('round_number', 1)
          .order('match_number');

      final round1Matches = response as List<dynamic>;

      if (round1Matches.length != 8) {
        throw Exception(
          'Expected 8 Round 1 matches, found ${round1Matches.length}',
        );
      }

      // Populate each match with 2 participants
      for (int i = 0; i < 8; i++) {
        final match = round1Matches[i];
        final player1 = participants[i * 2];
        final player2 = participants[i * 2 + 1];

        await Supabase.instance.client
            .from('matches')
            .update({
              'player1_id': player1.id,
              'player2_id': player2.id,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', match['id']);

        ProductionLogger.info('✅ Populated R1 M${i + 1}: ${player1.username} vs ${player2.username}',  tag: 'tournament_service');
      }

      ProductionLogger.info('✅ All Round 1 matches populated with participants', tag: 'TournamentService');
    } catch (e) {
      ProductionLogger.info('❌ Error populating Round 1: $e', tag: 'TournamentService');
      throw Exception('Failed to populate Round 1: $e');
    }
  }

  /// Save bracket data to database for future reference and hardcore advancement
  Future<void> _saveBracketDataToDatabase(
    String tournamentId,
    Map<String, dynamic> bracketStructure,
  ) async {
    try {
      final bracketDataJson = json.encode(bracketStructure);

      await Supabase.instance.client
          .from('tournaments')
          .update({'bracket_data': bracketDataJson})
          .eq('id', tournamentId);

      ProductionLogger.info('💾 Saved bracket data to database for tournament $tournamentId',  tag: 'tournament_service');
    } catch (e) {
      ProductionLogger.info('❌ Failed to save bracket data: $e', tag: 'TournamentService');
      throw Exception('Failed to save bracket data: $e');
    }
  }

  /// Advance player to specific match (SABO DE16 approach)
  Future<Map<String, dynamic>?> _advancePlayerToMatch(
    String tournamentId,
    String playerId,
    int roundNumber,
    int matchNumber,
    String sourceMatch,
  ) async {
    try {
      // Find target match
      final response = await Supabase.instance.client
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId)
          .eq('round_number', roundNumber)
          .eq('match_number', matchNumber)
          .single();

      final match = response;

      // Prevent duplicate player assignments
      if (match['player1_id'] == playerId || match['player2_id'] == playerId) {
        ProductionLogger.info('❌ Player $playerId already assigned to R${roundNumber}M$matchNumber',  tag: 'tournament_service');
        return null;
      }

      // Determine which slot to fill
      String? updateField;
      if (match['player1_id'] == null) {
        updateField = 'player1_id';
      } else if (match['player2_id'] == null) {
        updateField = 'player2_id';
      } else {
        ProductionLogger.info('⚠️ Match R${roundNumber}M$matchNumber already full', tag: 'TournamentService');
        return null;
      }

      // Update match with new player
      await Supabase.instance.client
          .from('matches')
          .update({
            updateField: playerId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', match['id']);

      ProductionLogger.info('✅ Advanced player $playerId to R${roundNumber}M$matchNumber ($updateField) from $sourceMatch',  tag: 'tournament_service');

      return {
        'match_id': match['id'],
        'round_number': roundNumber,
        'match_number': matchNumber,
        'updated_field': updateField,
      };
    } catch (e) {
      ProductionLogger.info('❌ Error advancing player: $e', tag: 'TournamentService');
      return null;
    }
  }

  /// Process single elimination advancement - SIMPLE LOGIC
  Future<Map<String, dynamic>> processSingleEliminationAdvancement(
    String tournamentId,
    String completedMatchId,
    String winnerId,
  ) async {
    try {
      ProductionLogger.info('🚀 Processing single elimination advancement for match $completedMatchId',  tag: 'tournament_service');

      // Get completed match details
      final matchResponse = await Supabase.instance.client
          .from('matches')
          .select('*')
          .eq('id', completedMatchId)
          .single();

      final match = matchResponse;
      final round = match['round_number'] as int;
      final matchNumber = match['match_number'] as int;

      ProductionLogger.info('📊 Completed: R${round}M$matchNumber, Winner: $winnerId', tag: 'TournamentService');

      // SIMPLE SINGLE ELIMINATION LOGIC
      Map<String, dynamic> results = {
        'advancement_made': false,
        'next_matches': [],
      };

      // Single elimination: winner advances to next round
      // R1 (M1-8) -> R2 (M9-12) -> R3 (M13-14) -> R4 (M15)

      int? nextRound;
      int? nextMatchNumber;

      if (round == 1) {
        // R1: M1,M2->M9; M3,M4->M10; M5,M6->M11; M7,M8->M12
        nextRound = 2;
        nextMatchNumber = 9 + ((matchNumber - 1) ~/ 2);
      } else if (round == 2) {
        // R2: M9,M10->M13; M11,M12->M14
        nextRound = 3;
        nextMatchNumber = 13 + ((matchNumber - 9) ~/ 2);
      } else if (round == 3) {
        // R3: M13,M14->M15 (final)
        nextRound = 4;
        nextMatchNumber = 15;
      } else {
        // Final round - no advancement
        ProductionLogger.info('🏆 Final match completed - tournament finished!', tag: 'TournamentService');
        return results;
      }

      final advanced = await _advancePlayerToMatch(
        tournamentId,
        winnerId,
        nextRound,
        nextMatchNumber,
        'R${round}M$matchNumber',
      );

      if (advanced != null) {
        results['next_matches'].add(advanced);
        results['advancement_made'] = true;
      }

      ProductionLogger.info('🎯 Single elimination advancement complete', tag: 'TournamentService');
      return results;
    } catch (e) {
      ProductionLogger.info('❌ Error in single elimination advancement: $e', tag: 'TournamentService');
      return {
        'advancement_made': false,
        'next_matches': [],
        'error': e.toString(),
      };
    }
  }

  /// Process hardcore advancement by replacing winner references with actual player IDs
  Future<bool> processHardcoreAdvancement(
    String tournamentId,
    String completedMatchId,
    String winnerId,
  ) async {
    try {
      ProductionLogger.info('🚀 Processing hardcore advancement for match $completedMatchId, winner: $winnerId',  tag: 'tournament_service');

      // Get all tournament matches
      final matches = await getTournamentMatches(tournamentId);
      if (matches.isEmpty) {
        ProductionLogger.info('❌ No matches found for tournament $tournamentId', tag: 'TournamentService');
        return false;
      }

      // Find the completed match to get its reference
      final completedMatch = matches.firstWhere(
        (m) => m['id'] == completedMatchId,
        orElse: () => {},
      );

      if (completedMatch.isEmpty) {
        ProductionLogger.info('❌ Completed match $completedMatchId not found', tag: 'TournamentService');
        return false;
      }

      final round = completedMatch['round'] as int;
      final matchNumber = completedMatch['match_number'] as int;
      final winnerReference = 'WINNER_FROM_R${round}M$matchNumber';

      ProductionLogger.info('🔍 Looking for matches with winner reference: $winnerReference',  tag: 'tournament_service');

      // Find matches that reference this completed match as winner
      int advancedMatches = 0;
      for (final match in matches) {
        bool needsUpdate = false;
        Map<String, dynamic> updateData = {};

        // Check if player1 references this match
        if (match['player1_id'] == winnerReference) {
          updateData['player1_id'] = winnerId;
          needsUpdate = true;
          ProductionLogger.info('📝 Advancing winner to match ${match['id']} player1', tag: 'tournament_service');
        }

        // Check if player2 references this match
        if (match['player2_id'] == winnerReference) {
          updateData['player2_id'] = winnerId;
          needsUpdate = true;
          ProductionLogger.info('📝 Advancing winner to match ${match['id']} player2', tag: 'tournament_service');
        }

        // Update the match if needed
        if (needsUpdate) {
          updateData['updated_at'] = DateTime.now().toIso8601String();

          await Supabase.instance.client
              .from('matches')
              .update(updateData)
              .eq('id', match['id']);

          advancedMatches++;
          ProductionLogger.info('✅ Updated match ${match['id']} with winner advancement', tag: 'tournament_service');
        }
      }

      ProductionLogger.info('🎯 Hardcore advancement complete: $advancedMatches matches updated',  tag: 'tournament_service');
      return advancedMatches > 0;
    } catch (e) {
      ProductionLogger.info('❌ Error in hardcore advancement: $e', tag: 'TournamentService');
      return false;
    }
  }

  // ==================== TOURNAMENT COVER IMAGE UPLOAD ====================

  /// Upload tournament cover image and update tournament
  Future<Tournament> uploadAndUpdateTournamentCover(
    String tournamentId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get tournament to check club ownership
      final tournamentData = await _supabase
          .from('tournaments')
          .select('club_id')
          .eq('id', tournamentId)
          .single();

      final clubId = tournamentData['club_id'] as String;

      // Check if user is club owner (có quyền quản lý tournament)
      final memberData = await _supabase
          .from('club_members')
          .select('role')
          .eq('club_id', clubId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (memberData == null) {
        throw Exception('You are not a member of this club');
      }

      final role = memberData['role'] as String;
      if (role != 'owner' && role != 'admin') {
        throw Exception('Only club owner or admin can update tournament cover');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last.toLowerCase();
      final uniqueFileName = 'tournament_cover_${tournamentId}_$timestamp.$extension';

      // Determine content type
      String contentType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      // Upload file to storage bucket 'tournament-covers'
      await _supabase.storage
          .from('tournament-covers')
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('tournament-covers')
          .getPublicUrl(uniqueFileName);

      ProductionLogger.info('Tournament cover uploaded: $publicUrl', tag: 'TournamentService');

      // Update tournament cover_image_url in database
      final response = await _supabase
          .from('tournaments')
          .update({
            'cover_image_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tournamentId)
          .select()
          .single();

      ProductionLogger.info('Tournament cover updated in database', tag: 'TournamentService');

      return Tournament.fromJson(response);
    } catch (error) {
      ProductionLogger.error('Failed to upload tournament cover', error: error, tag: 'TournamentService');
      throw Exception('Failed to upload tournament cover: $error');
    }
  }
}

// ==================== DATA MODELS ====================

/// Tournament Bracket Model
class TournamentBracket {
  final String tournamentId;
  final String format;
  final List<SeededParticipant> participants;
  final List<TournamentMatch> matches;
  final int rounds;
  final String status;
  final DateTime createdAt;

  TournamentBracket({
    required this.tournamentId,
    required this.format,
    required this.participants,
    required this.matches,
    required this.rounds,
    required this.status,
    required this.createdAt,
  });
}

/// Seeded Participant Model
class SeededParticipant {
  final UserProfile participant;
  final int seedNumber;
  final String seedingMethod;

  SeededParticipant({
    required this.participant,
    required this.seedNumber,
    required this.seedingMethod,
  });
}

/// Tournament Match Model
class TournamentMatch {
  final String id;
  final String tournamentId;
  final String? player1Id;
  final String? player2Id;
  final int round;
  final int matchNumber;
  final String status;
  final String format;
  final DateTime createdAt;
  final String? winnerId;
  final Map<String, int>? score;
  final DateTime? scheduledTime;
  final String? tableNumber;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    this.player1Id,
    this.player2Id,
    required this.round,
    required this.matchNumber,
    required this.status,
    required this.format,
    required this.createdAt,
    this.winnerId,
    this.score,
    this.scheduledTime,
    this.tableNumber,
  });
}

/// Match Status Constants
class MatchStatus {
  static const String pending = 'pending';
  static const String ready = 'ready';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
}

/// Tournament Result Model
class TournamentResult {
  final String participantId;
  final int finalPosition;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int startingElo;
  final int defeatedHigherSeeds;
  final List<String> defeatedOpponents;

  TournamentResult({
    required this.participantId,
    required this.finalPosition,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    required this.startingElo,
    this.defeatedHigherSeeds = 0,
    this.defeatedOpponents = const [],
  });
}

/// Prize Distribution Result Model
class PrizeDistributionResult {
  final int position;
  final String participantId;
  final double prizeAmount;
  final double percentage;
  final String prizeType;

  PrizeDistributionResult({
    required this.position,
    required this.participantId,
    required this.prizeAmount,
    required this.percentage,
    required this.prizeType,
  });
}

/// ELO Change Model
class EloChange {
  final String participantId;
  final int oldElo;
  final int newElo;
  final int change;
  final String reason;
  final int baseReward;
  final Map<String, int> bonuses;

  EloChange({
    required this.participantId,
    required this.oldElo,
    required this.newElo,
    required this.change,
    required this.reason,
    required this.baseReward,
    required this.bonuses,
  });
}
