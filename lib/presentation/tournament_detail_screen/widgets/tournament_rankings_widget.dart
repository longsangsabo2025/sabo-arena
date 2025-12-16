import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
import '../../../services/tournament_service.dart';
import '../../../services/tournament_prize_voucher_service.dart';
import '../../../core/utils/user_display_name.dart';
import '../../../services/tournament/reward_execution_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class TournamentRankingsWidget extends StatefulWidget {
  final String tournamentId;
  final String tournamentStatus;

  const TournamentRankingsWidget({
    super.key,
    required this.tournamentId,
    required this.tournamentStatus,
  });

  @override
  State<TournamentRankingsWidget> createState() =>
      _TournamentRankingsWidgetState();
}

class _TournamentRankingsWidgetState extends State<TournamentRankingsWidget> {
  final TournamentService _tournamentService = TournamentService.instance;
  final TournamentPrizeVoucherService _prizeVoucherService = TournamentPrizeVoucherService();
  List<Map<String, dynamic>> _rankings = [];
  List<Map<String, dynamic>> _prizeVouchers = [];
  bool _isLoading = true;
  String? _error;

  /// 🆕 PUBLIC GETTER: Expose current rankings data for tournament completion
  /// This allows TournamentCompletionOrchestrator to use the ALREADY CALCULATED data
  /// instead of re-calculating everything
  List<Map<String, dynamic>> get currentRankings => List.unmodifiable(_rankings);

  @override
  void initState() {
    super.initState();
    _loadRankings();
    _loadPrizeVouchers();
  }

  Future<void> _loadPrizeVouchers() async {
    try {
      final vouchers = await _prizeVoucherService.getTournamentPrizeVouchers(widget.tournamentId);
      if (mounted) {
        setState(() {
          _prizeVouchers = vouchers;
        });
      }
    } catch (e) {
      ProductionLogger.info('❌ Error loading prize vouchers: $e', tag: 'tournament_rankings_widget');
      // Don't show error to user - vouchers are optional
    }
  }

  Map<String, dynamic>? _getVoucherForPosition(int position) {
    try {
      return _prizeVouchers.firstWhere(
        (v) => v['position'] == position,
      );
    } catch (e) {
      return null;
    }
  }

  /// Main entry point - decides whether to load from tournament_results or calculate live
  Future<void> _loadRankings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      ProductionLogger.info('🔍 [RANKINGS WIDGET] Loading rankings for tournament ${widget.tournamentId}', tag: 'tournament_rankings_widget');

      // ═══════════════════════════════════════════════════════════════
      // 🆕 NEW: Check if tournament is completed → read from tournament_results
      // ═══════════════════════════════════════════════════════════════
      if (widget.tournamentStatus == 'completed') {
        await _loadCompletedTournamentRankings();
        return;
      }

      // ═══════════════════════════════════════════════════════════════
      // OLD: For ongoing tournaments → calculate dynamically
      // ═══════════════════════════════════════════════════════════════
      await _loadLiveRankings();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Load rankings from tournament_results (for completed tournaments)
  /// This reads from the SOURCE OF TRUTH - no calculation needed
  Future<void> _loadCompletedTournamentRankings() async {
    try {
      ProductionLogger.info('✅ [RANKINGS WIDGET] Tournament completed - loading from tournament_results', tag: 'tournament_rankings_widget');

      // Read from tournament_results (SOURCE OF TRUTH)
      final resultsResponse = await Supabase.instance.client
          .from('tournament_results')
          .select('''
            participant_id,
            participant_name,
            position,
            matches_won,
            matches_lost,
            matches_played,
            win_percentage,
            spa_reward,
            elo_change,
            prize_money_vnd,
            old_elo,
            new_elo
          ''')
          .eq('tournament_id', widget.tournamentId)
          .order('position', ascending: true);

      final results = resultsResponse as List<dynamic>;

      if (results.isEmpty) {
        ProductionLogger.info('⚠️ [RANKINGS WIDGET] No results found in tournament_results, falling back to live calculation', tag: 'tournament_rankings_widget');
        await _loadLiveRankings();
        return;
      }

      ProductionLogger.info('✅ [RANKINGS WIDGET] Loaded ${results.length} results from tournament_results', tag: 'tournament_rankings_widget');

      // Fetch user details for avatar/display name (tournament_results might have stale names)
      final userIds = results.map((r) => r['participant_id'] as String).toList();
      final usersResponse = await Supabase.instance.client
          .from('users')
          .select('id, username, full_name, avatar_url')
          .inFilter('id', userIds);

      final usersMap = {
        for (var user in usersResponse as List<dynamic>)
          user['id'] as String: user
      };

      // Map results to rankings format (with CORRECT rewards from source of truth)
      final rankings = results.map((result) {
        final userId = result['participant_id'] as String;
        final user = usersMap[userId];

        return {
          'user_id': userId,
          'display_name': user?['full_name'] ?? result['participant_name'] ?? 'Unknown',
          'full_name': user?['full_name'] ?? result['participant_name'] ?? 'Unknown',
          'username': user?['username'] ?? result['participant_name'] ?? 'Unknown',
          'avatar_url': user?['avatar_url'],
          'rank': result['position'], // Position is the rank for completed tournaments
          'wins': result['matches_won'] ?? 0,
          'losses': result['matches_lost'] ?? 0,
          'draws': 0,
          'total_games': result['matches_played'] ?? 0,
          'win_rate': (result['win_percentage'] as num?)?.toDouble() ?? 0.0,
          'points': (result['matches_won'] ?? 0) * 3,
          'total_points': (result['matches_won'] ?? 0) * 3,
          // ✅ CRITICAL: Read rewards from SOURCE OF TRUTH (tournament_results)
          'elo_bonus': result['elo_change'] ?? 0,
          'spa_bonus': result['spa_reward'] ?? 0,
          'prize_money': (result['prize_money_vnd'] as num?)?.toInt() ?? 0,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _rankings = rankings;
          _isLoading = false;
        });
      }

      ProductionLogger.info('✅ [RANKINGS WIDGET] Displayed rankings with CORRECT rewards from tournament_results', tag: 'tournament_rankings_widget');
    } catch (e) {
      ProductionLogger.info('❌ [RANKINGS WIDGET] Error loading completed tournament rankings: $e', tag: 'tournament_rankings_widget');
      // Fallback to live calculation
      await _loadLiveRankings();
    }
  }

  /// Load rankings by calculating live (for ongoing tournaments)
  Future<void> _loadLiveRankings() async {
    try {
      ProductionLogger.info('🔍 [RANKINGS WIDGET] Calculating live rankings from matches', tag: 'tournament_rankings_widget');

      // Get tournament info (for prize pool)
      final tournamentResponse = await Supabase.instance.client
          .from('tournaments')
          .select('prize_pool, prize_distribution, max_participants')
          .eq('id', widget.tournamentId)
          .single();

      ProductionLogger.info('🔍 [RANKINGS WIDGET] Tournament response: $tournamentResponse', tag: 'tournament_rankings_widget');

      final prizePool =
          (tournamentResponse['prize_pool'] as num?)?.toDouble() ?? 0.0;

      // Handle prize_distribution - can be either String or Map
      String prizeDistribution = 'standard';
      List<Map<String, dynamic>>? customDistribution;
      final prizeDistData = tournamentResponse['prize_distribution'];
      if (prizeDistData is String) {
        prizeDistribution = prizeDistData;
      } else if (prizeDistData is Map) {
        // If it's a Map, extract template or use default
        prizeDistribution = prizeDistData['template']?.toString() ?? 'standard';
        // ✅ Check for custom distribution
        if (prizeDistribution == 'custom' && prizeDistData['distribution'] != null) {
          customDistribution = (prizeDistData['distribution'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          ProductionLogger.info('✅ [RANKINGS] Found custom distribution with ${customDistribution.length} positions', tag: 'tournament_rankings_widget');
        }
      }

      ProductionLogger.info('🔍 [RANKINGS WIDGET] Prize pool: $prizePool, distribution: $prizeDistribution',  tag: 'tournament_rankings_widget');
      ProductionLogger.info('🔍 [RANKINGS WIDGET] Raw prize_distribution type: ${prizeDistData.runtimeType}',  tag: 'tournament_rankings_widget');
      if (customDistribution != null) {
        ProductionLogger.info('🔍 [RANKINGS WIDGET] Custom distribution: $customDistribution', tag: 'tournament_rankings_widget');
      }

      // Get tournament participants
      final participants = await _tournamentService.getTournamentParticipants(
        widget.tournamentId,
      );

      // Get matches to calculate stats - simplified query without joins
      final matchesResponse = await Supabase.instance.client
          .from('matches')
          .select('player1_id, player2_id, winner_id, status')
          .eq('tournament_id', widget.tournamentId);

      final matches = matchesResponse as List<dynamic>;

      // Calculate stats for each participant
      final rankings = participants.map((participant) {
        int wins = 0;
        int losses = 0;
        int totalGames = 0;
        for (final match in matches) {
          final player1Id = match['player1_id'] as String?;
          final player2Id = match['player2_id'] as String?;
          final winnerId = match['winner_id'] as String?;
          final status = match['status'] as String?;
          // Skip pending matches
          if (status != 'completed' || winnerId == null) continue;
          if (participant.id == player1Id || participant.id == player2Id) {
            totalGames++;
            if (participant.id == winnerId) {
              wins++;
            } else {
              losses++;
            }
          }
        }
        double winRate = totalGames > 0 ? (wins / totalGames) * 100 : 0.0;
        return {
          'user_id': participant.id,
          'display_name': participant.displayName,
          'full_name': participant.fullName,
          'username': participant.username,
          'avatar_url': participant.avatarUrl,
          'wins': wins.toInt(),
          'losses': losses.toInt(),
          'draws': 0,
          'total_games': totalGames.toInt(),
          'win_rate': winRate.toDouble(),
          'points': (wins * 3).toInt(),
          'total_points': (wins * 3).toInt(),
          'elo_bonus': 0,
          'spa_bonus': 0,
          'prize_money': 0,
        };
      }).toList();

      // Sort by points (wins), then by win rate
      rankings.sort((a, b) {
        int pointsCompare = (b['points'] as num).toInt().compareTo(
          (a['points'] as num).toInt(),
        );
        if (pointsCompare != 0) return pointsCompare;
        return (b['win_rate'] as num).toDouble().compareTo(
          (a['win_rate'] as num).toDouble(),
        );
      });

      // Get prize distribution percentages OR custom amounts
      List<double> prizePercentages = [];
      List<int> customPrizeAmounts = [];
      
      if (customDistribution != null) {
        // ✅ Use custom distribution amounts directly
        customPrizeAmounts = customDistribution.map((item) {
          final amount = item['cashAmount'] ?? item['amount'] ?? 0;
          return (amount is int) ? amount : (amount as double).toInt();
        }).toList();
        ProductionLogger.info('✅ [RANKINGS] Using custom prize amounts: $customPrizeAmounts', tag: 'tournament_rankings_widget');
      } else {
        // Use template percentages
        prizePercentages = _getPrizeDistribution(
          prizeDistribution,
          rankings.length,
        );
        ProductionLogger.info('✅ [RANKINGS] Using template percentages: $prizePercentages', tag: 'tournament_rankings_widget');
      }

      // Assign ranks with tie handling - same points/win_rate = same rank
      final totalParticipants = rankings.length;
      int currentRank = 1;
      for (int i = 0; i < rankings.length; i++) {
        final position = i + 1;
        
        // Check if this player has same stats as previous player (tie)
        if (i > 0) {
          final prevPoints = rankings[i - 1]['points'] as int;
          final prevWinRate = rankings[i - 1]['win_rate'] as double;
          final currPoints = rankings[i]['points'] as int;
          final currWinRate = rankings[i]['win_rate'] as double;
          
          // If different stats, increment rank to current position
          if (prevPoints != currPoints || prevWinRate != currWinRate) {
            currentRank = position;
          }
          // else: same stats, keep same rank
        }
        
        rankings[i]['rank'] = currentRank;
        rankings[i]['elo_bonus'] = _calculateEloBonus(
          currentRank, // ELO uses rank (handles ties)
          totalParticipants,
        );
        rankings[i]['spa_bonus'] = _calculateSpaBonus(
          position, // ✅ SPA uses position (i+1), NOT rank! Must match backend logic
          totalParticipants,
        );

        // Calculate prize money for top positions
        if (customPrizeAmounts.isNotEmpty && i < customPrizeAmounts.length) {
          // ✅ Use custom amount directly
          rankings[i]['prize_money'] = customPrizeAmounts[i];
        } else if (prizePool > 0 && i < prizePercentages.length) {
          // Use percentage-based calculation
          final percentage = prizePercentages[i];
          rankings[i]['prize_money'] = (prizePool * percentage / 100).round();
        }
      }

      if (mounted) {
        setState(() {
          _rankings = rankings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Fixed at top
          Row(
            children: [
              Icon(Icons.leaderboard, color: Colors.orange, size: 24.sp),
              SizedBox(width: 8.sp),
              Text(
                'Bảng xếp hạng',
                style: TextStyle(
                  fontSize: 18.sp, // Increased from 14.sp
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              // 🎁 Compact Reward Distribution Button
              if (!_isLoading && _error == null && _rankings.isNotEmpty)
                _buildCompactRewardButton(),
              if (!_isLoading)
                IconButton(
                  onPressed: _loadRankings,
                  icon: Icon(Icons.refresh, size: 20.sp),
                  tooltip: 'Làm mới',
                ),
            ],
          ),
          SizedBox(height: 12.sp),

          // Content - Expanded to fill remaining space and handle its own scroll
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                ? _buildErrorState()
                : _rankings.isEmpty
                ? _buildEmptyState()
                : _buildRankingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200.sp,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.sp),
            Text(
              'Đang tải bảng xếp hạng...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 300.sp,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.red[300]),
            SizedBox(height: 16.sp),
            Text(
              'Lỗi khi tải bảng xếp hạng',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8.sp),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.sp),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.sp),
            ElevatedButton.icon(
              onPressed: _loadRankings,
              icon: Icon(Icons.refresh),
              label: Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 250.sp,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48.sp,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16.sp),
            Text(
              'Chưa có bảng xếp hạng',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.sp),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.sp),
              child: Text(
                widget.tournamentStatus == 'completed'
                    ? 'Bảng xếp hạng sẽ được tạo sau khi hoàn thành giải đấu'
                    : 'Bảng xếp hạng sẽ được cập nhật khi có kết quả trận đấu',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingsList() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 8.sp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // NO HEADER - Tiết kiệm space, dùng icons trong items

          // Rankings List với 2-line compact layout
          ..._rankings.asMap().entries.map((entry) {
            final index = entry.key;
            final ranking = entry.value;
            return _buildRankingItem(ranking, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildRankingItem(Map<String, dynamic> ranking, int position) {
    final rank = ranking['rank'] as int? ?? position; // Use rank from data, fallback to position
    final isTopFour = rank <= 4; // Top 4 includes both 3rd & 4th (đồng hạng 3)
    final bgColor = isTopFour ? _getTopThreeColor(rank) : Colors.white; // Use rank for color
    final textColor = isTopFour ? Colors.white : Colors.grey[800]!;
    final borderColor = isTopFour ? Colors.transparent : Colors.grey[200]!;

    return Container(
      margin: EdgeInsets.only(bottom: 8.sp),
      padding: EdgeInsets.symmetric(vertical: 10.sp, horizontal: 12.sp),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          if (isTopFour)
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Changed from start to center
        children: [
          // Position Badge - Show actual position number or medal icon
          SizedBox(
            width: 28.sp,
            child: Center(
              // Center the badge
              child: isTopFour
                  ? Icon(
                      _getPositionIcon(rank), // Use rank for icon (includes 3rd & 4th)
                      size: 22.sp, // Increased from 18.sp
                      color: Colors.white,
                    )
                  : Container(
                      width: 26.sp, // Increased from 22.sp
                      height: 26.sp,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$position', // Still show position for ordering
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp, // Increased from 13.sp
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
            ),
          ),

          SizedBox(width: 10.sp),

          // Player Avatar - Smaller
          Container(
            width: 28.sp, // Reduced from 32.sp
            height: 28.sp,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isTopFour
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: UserAvatarWidget(
              avatarUrl: ranking['avatar_url'],
              size: 24.sp,
            ),
          ),

          SizedBox(width: 10.sp),

          // Player Info + Stats (2 lines)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              children: [
                // Line 1: Player name + W/L
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        UserDisplayName.fromMap(ranking),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp, // Increased from 15.sp
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: 10.sp),
                    // W/L badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 3.sp,
                        horizontal: 8.sp,
                      ),
                      decoration: BoxDecoration(
                        color: isTopFour
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6.sp),
                      ),
                      child: Text(
                        '${ranking['wins'] ?? 0}/${ranking['losses'] ?? 0}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp, // Increased from 13.sp
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8.sp),

                // Line 2: Rewards với icons
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Center align icons and text
                  children: [
                    // 💰 VND
                    if ((ranking['prize_money'] ?? 0) > 0) ...[
                      Icon(
                        Icons.monetization_on,
                        size: 16.sp, // Increased from 14.sp
                        color: isTopFour
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.blue[600],
                      ),
                      SizedBox(width: 4.sp),
                      Text(
                        _formatPrizeMoney(ranking['prize_money'] ?? 0),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp, // Increased from 13.sp
                          color: isTopFour
                              ? Colors.white.withValues(alpha: 0.95)
                              : Colors.blue[700],
                        ),
                      ),
                      SizedBox(width: 14.sp),
                    ],

                    // 🎁 Voucher
                    if (_getVoucherForPosition(rank) != null) ...[
                      Icon(
                        Icons.card_giftcard,
                        size: 16.sp,
                        color: isTopFour
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.green[600],
                      ),
                      SizedBox(width: 4.sp),
                      Text(
                        _formatPrizeMoney(_getVoucherForPosition(rank)!['vnd_value'] ?? 0),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: isTopFour
                              ? Colors.white.withValues(alpha: 0.95)
                              : Colors.green[700],
                        ),
                      ),
                      SizedBox(width: 14.sp),
                    ],

                    // ⚡ ELO
                    Icon(
                      Icons.trending_up,
                      size: 16.sp, // Increased from 14.sp
                      color: isTopFour
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.green[600],
                    ),
                    SizedBox(width: 4.sp),
                    Text(
                      '${ranking['elo_bonus'] ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp, // Increased from 13.sp
                        color: isTopFour
                            ? Colors.white.withValues(alpha: 0.95)
                            : Colors.green[700],
                      ),
                    ),

                    SizedBox(width: 14.sp),

                    // ⭐ SPA
                    Icon(
                      Icons.stars,
                      size: 16.sp, // Increased from 14.sp
                      color: isTopFour
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.orange[600],
                    ),
                    SizedBox(width: 4.sp),
                    Text(
                      '${ranking['spa_bonus'] ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp, // Increased from 13.sp
                        color: isTopFour
                            ? Colors.white.withValues(alpha: 0.95)
                            : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTopThreeColor(int position) {
    switch (position) {
      case 1:
        return Color(0xFFFFA500); // Gold - Orange
      case 2:
        return Color(0xFF808080); // Silver - Gray
      case 3:
      case 4: // Đồng hạng 3 (Both 3rd & 4th place)
        return Color(0xFFCD7F32); // Bronze - Brown
      default:
        return Colors.white;
    }
  }

  IconData _getPositionIcon(int position) {
    switch (position) {
      case 1:
        return Icons.emoji_events; // Trophy
      case 2:
        return Icons.military_tech; // Medal
      case 3:
      case 4: // Đồng hạng 3 (Both 3rd & 4th place)
        return Icons.military_tech; // Medal
      default:
        return Icons.circle;
    }
  }

  /// Calculate ELO bonus based on position (matches tournament_completion_service.dart logic)
  int _calculateEloBonus(int position, int totalParticipants) {
    if (position == 1) {
      return 75; // ✅ 1st Place: +75 ELO
    } else if (position == 2) {
      return 50; // ✅ 2nd Place: +50 ELO
    } else if (position == 3 || position == 4) {
      return 35; // ✅ Đồng hạng 3 (Both 3rd & 4th): +35 ELO
    } else if (position <= totalParticipants * 0.25) {
      return 25; // Top 25%: +25 ELO
    } else if (position <= totalParticipants * 0.5) {
      return 15; // Top 50%: +15 ELO
    } else if (position <= totalParticipants * 0.75) {
      return 10; // Top 75%: +10 ELO
    } else {
      return -5; // Bottom 25%: -5 ELO
    }
  }

  /// Calculate SPA bonus based on position (matches PrizeDistributionService logic)
  /// IMPORTANT: position is 1-indexed position in the standings list (after sorting)
  /// NOT the rank number! Rank handles ties, position does not.
  int _calculateSpaBonus(int position, int totalParticipants) {
    // These thresholds use ceil() to match PrizeDistributionService exactly
    final top25 = (totalParticipants * 0.25).ceil();
    final top50 = (totalParticipants * 0.5).ceil();
    final top75 = (totalParticipants * 0.75).ceil();
    
    if (position == 1) {
      return 1000; // Winner: +1000 SPA
    } else if (position == 2) {
      return 800; // Runner-up: +800 SPA
    } else if (position == 3 || position == 4) {
      return 550; // Đồng hạng 3 (3rd & 4th place): +550 SPA each
    } else if (position <= top25) {
      return 400; // Top 25%: +400 SPA
    } else if (position <= top50) {
      return 300; // Top 50%: +300 SPA
    } else if (position <= top75) {
      return 200; // Top 75%: +200 SPA
    } else {
      return 100; // Bottom 25%: +100 SPA
    }
  }

  /// Get prize distribution percentages (matches tournament_completion_service.dart logic)
  List<double> _getPrizeDistribution(String template, int participantCount) {
    switch (template) {
      case 'winner_takes_all':
        return [100.0];
      
      // Template: Top 3 - Chia cho 3 người đầu
      case 'top_3':
        return [60.0, 25.0, 15.0];
      
      // Template: Top 4 (Đồng hạng 3) - Chia cho 4 người (vị trí 3 & 4 đồng hạng)
      case 'top_4':
        return [40.0, 30.0, 15.0, 15.0]; // Position 3 & 4 đều nhận 15%
      
      // Template: Top 8 - Chia cho 8 người đầu
      case 'top_8':
        return [35.0, 25.0, 15.0, 10.0, 5.0, 5.0, 2.5, 2.5];
      
      // Template: Đồng hạng 3 - Top 4 với đồng hạng 3
      case 'dong_hang_3':
        return [40.0, 30.0, 15.0, 15.0]; // Giống top_4
      
      case 'top_heavy':
        if (participantCount <= 4) return [60.0, 30.0, 10.0];
        if (participantCount <= 8) return [50.0, 30.0, 12.0, 8.0];
        return [40.0, 25.0, 15.0, 10.0, 5.0, 3.0, 2.0];
      
      case 'flat':
        if (participantCount <= 4) return [40.0, 30.0, 20.0, 10.0];
        if (participantCount <= 8) return [30.0, 25.0, 20.0, 12.0, 8.0, 5.0];
        return [25.0, 20.0, 15.0, 12.0, 10.0, 8.0, 5.0, 3.0, 2.0];
      
      case 'standard':
      default:
        if (participantCount <= 4) return [50.0, 30.0, 20.0];
        if (participantCount <= 8)
          return [40.0, 25.0, 15.0, 10.0, 5.0, 3.0, 2.0];
        return [40.0, 25.0, 15.0, 10.0, 5.0, 3.0, 2.0];
    }
  }

  /// Format prize money with short notation (VD: 1.5 Tr, 200 K)
  String _formatPrizeMoney(int amount) {
    if (amount == 0) return '-';
    if (amount >= 1000000) {
      // Triệu (Million)
      final millions = amount / 1000000;
      if (millions == millions.toInt()) {
        return '${millions.toInt()} Tr';
      }
      return '${millions.toStringAsFixed(1)} Tr';
    } else if (amount >= 1000) {
      // Nghìn (Thousand)
      final thousands = amount / 1000;
      if (thousands == thousands.toInt()) {
        return '${thousands.toInt()} K';
      }
      return '${thousands.toStringAsFixed(1)} K';
    }
    return '$amount';
  }

  /// Build compact reward distribution button for header
  Widget _buildCompactRewardButton() {
    return Container(
      margin: EdgeInsets.only(right: 8.sp),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.sp),
          onTap: _distributeRewards,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.sp),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 16.sp,
                ),
                SizedBox(width: 4.sp),
                Text(
                  'Gửi Quà',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Distribute rewards using RewardDistributionButton logic
  Future<void> _distributeRewards() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.green),
            SizedBox(width: 8),
            Text('🎁 Xác nhận phân phối quà'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn gửi quà cho ${_rankings.length} người chơi?'),
            SizedBox(height: 16),
            Text('Quà bao gồm:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• SPA Points (100-1000 tùy hạng)'),
            Text('• ELO Rating (+75 đến -5)'),
            Text('• Prize Money (nếu có)'),
            Text('• Vouchers (Top 4)'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ Hành động này không thể hoàn tác!',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('🎁 Gửi Quà'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Đang phân phối quà...'),
          ],
        ),
      ),
    );

    try {
      // Use RewardExecutionService
      final rewardService = RewardExecutionService();
      final success = await rewardService.executeRewardsFromResults(
        tournamentId: widget.tournamentId,
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Quà đã được gửi thành công cho ${_rankings.length} người chơi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Reward distribution failed');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Có lỗi khi gửi quà: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
