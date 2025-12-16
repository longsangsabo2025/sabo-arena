import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX
import 'package:sabo_arena/widgets/club/club_logo_widget.dart';

/// Match Card Widget with Real-time Updates - Phase 5-6
/// Features:
/// - Real-time score updates via Supabase Realtime
/// - Live streaming badge and "Watch Live" button
/// - Automatic UI refresh when match data changes
/// - Support for in_progress matches with live scores
class MatchCardWidgetRealtime extends StatefulWidget {
  final Map<String, dynamic> match;
  final VoidCallback? onTap;
  final VoidCallback? onWatchLive; // New: Open live stream

  const MatchCardWidgetRealtime({
    super.key,
    required this.match,
    this.onTap,
    this.onWatchLive,
  });

  @override
  State<MatchCardWidgetRealtime> createState() =>
      _MatchCardWidgetRealtimeState();
}

class _MatchCardWidgetRealtimeState extends State<MatchCardWidgetRealtime> {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _realtimeChannel;
  
  // Local state for real-time updates
  late Map<String, dynamic> _currentMatch;
  late int _player1Score;
  late int _player2Score;
  late String _status;
  late bool _isLive;

  @override
  void initState() {
    super.initState();
    _initializeMatchData();
    _subscribeToMatchUpdates();
  }

  @override
  void dispose() {
    _unsubscribeFromUpdates();
    super.dispose();
  }

  /// Initialize match data from props
  void _initializeMatchData() {
    _currentMatch = Map<String, dynamic>.from(widget.match);
    _player1Score = _currentMatch['player1_score'] as int? ?? 0;
    _player2Score = _currentMatch['player2_score'] as int? ?? 0;
    _status = _currentMatch['status'] as String? ?? 'pending';
    _isLive = _currentMatch['is_live'] as bool? ?? false;
  }

  /// Subscribe to real-time match updates
  void _subscribeToMatchUpdates() {
    final matchId = widget.match['id'];
    if (matchId == null) return;

    // Only subscribe if match is in_progress
    if (_status != 'in_progress') {
      ProductionLogger.info('⏸️ Match $matchId not in progress, skipping real-time subscription', tag: 'match_card_widget_realtime');
      return;
    }

    ProductionLogger.info('🔔 Subscribing to real-time updates for match: $matchId', tag: 'match_card_widget_realtime');

    try {
      _realtimeChannel = _supabase
          .channel('match_$matchId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'matches',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: matchId,
            ),
            callback: (payload) {
              ProductionLogger.info('🔄 Real-time update received for match $matchId', tag: 'match_card_widget_realtime');
              _handleMatchUpdate(payload.newRecord);
            },
          )
          .subscribe();

      ProductionLogger.info('✅ Real-time subscription active for match: $matchId', tag: 'match_card_widget_realtime');
    } catch (e) {
      ProductionLogger.info('❌ Failed to subscribe to real-time updates: $e', tag: 'match_card_widget_realtime');
    }
  }

  /// Handle real-time match update
  void _handleMatchUpdate(Map<String, dynamic> newData) {
    if (!mounted) return;

    setState(() {
      _player1Score = newData['player1_score'] as int? ?? _player1Score;
      _player2Score = newData['player2_score'] as int? ?? _player2Score;
      _status = newData['status'] as String? ?? _status;
      _isLive = newData['is_live'] as bool? ?? _isLive;
      
      // Update current match data
      _currentMatch.addAll(newData);
    });

    ProductionLogger.info('✅ UI updated - Score: $_player1Score - $_player2Score, Status: $_status, Live: $_isLive', tag: 'match_card_widget_realtime');
  }

  /// Unsubscribe from real-time updates
  void _unsubscribeFromUpdates() {
    if (_realtimeChannel != null) {
      ProductionLogger.info('🔕 Unsubscribing from real-time updates', tag: 'match_card_widget_realtime');
      _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Player info
    final player1Name = _currentMatch['player1Name'] as String? ?? 
                        _currentMatch['player1']?['full_name'] as String? ?? 
                        'Player 1';
    final player1Rank = _currentMatch['player1Rank'] as String? ?? 
                        _currentMatch['player1']?['rank'] as String? ?? 
                        'H';
    final player1Avatar = _currentMatch['player1Avatar'] as String? ?? 
                          _currentMatch['player1']?['avatar_url'] as String?;
    final player1Online = _currentMatch['player1Online'] as bool? ?? false;

    final player2Name = _currentMatch['player2Name'] as String? ?? 
                        _currentMatch['player2']?['full_name'] as String? ?? 
                        'Player 2';
    final player2Rank = _currentMatch['player2Rank'] as String? ?? 
                        _currentMatch['player2']?['rank'] as String? ?? 
                        'H';
    final player2Avatar = _currentMatch['player2Avatar'] as String? ?? 
                          _currentMatch['player2']?['avatar_url'] as String?;
    final player2Online = _currentMatch['player2Online'] as bool? ?? false;

    // Club info
    final clubName = _currentMatch['clubName'] as String? ?? 
                     _currentMatch['club']?['name'] as String?;
    final clubLogo = _currentMatch['clubLogo'] as String? ?? 
                     _currentMatch['club']?['logo_url'] as String?;
    final clubAddress = _currentMatch['clubAddress'] as String? ?? 
                        _currentMatch['club']?['address'] as String?;

    // Match info
    final matchType = _currentMatch['matchType'] as String? ?? 
                      (_currentMatch['challenge_type'] == 'thach_dau' ? 'Thách đấu' : 'Giao lưu');
    final date = _currentMatch['date'] as String? ?? 
                 _formatDate(_currentMatch['scheduled_time']);
    final time = _currentMatch['time'] as String? ?? 
                 _formatTime(_currentMatch['scheduled_time']);
    final handicap = _currentMatch['handicap'] as String? ?? 'Handicap 0.5 ván';
    final prize = _currentMatch['prize'] as String? ?? '100 SPA';
    final raceInfo = _currentMatch['raceInfo'] as String? ?? 'Race to 7';
    final currentTable = _currentMatch['currentTable'] as String? ?? 
                         (_currentMatch['table_number'] != null 
                           ? 'Bàn ${_currentMatch['table_number']}' 
                           : 'Bàn 1');

    // Video URL for live streaming
    final videoUrl = _currentMatch['video_url'] as String?;
    final canWatchLive = _isLive && videoUrl != null && videoUrl.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isLive ? const Color(0xFFFF5722) : const Color(0xFFE0E0E0),
            width: _isLive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isLive 
                ? const Color(0xFFFF5722).withValues(alpha: 0.2) 
                : Colors.black.withValues(alpha: 0.05),
              blurRadius: _isLive ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top row: Club Info (left), Status Badge (center), Match Type (right)
            Row(
              children: [
                // Club Info ở góc trái
                if (clubName != null)
                  Expanded(
                    child: _buildClubInfo(
                      clubName: clubName,
                      clubLogo: clubLogo,
                      clubAddress: clubAddress,
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),

                // Status Badge ở giữa với live indicator
                _buildStatusBadge(_status, _isLive),

                // Match Type badge ở góc phải
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildMatchTypeBadge(matchType),
                  ),
                ),
              ],
            ),

            // Live streaming badge (nếu đang live)
            if (_isLive) ...[
              const SizedBox(height: 8),
              _buildLiveStreamingBadge(),
            ],

            const SizedBox(height: 12),

            // Main content: Player 1 vs Player 2
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player 1 (Left)
                Expanded(
                  child: _buildPlayerInfo(
                    name: player1Name,
                    rank: player1Rank,
                    avatar: player1Avatar,
                    isOnline: player1Online,
                  ),
                ),

                const SizedBox(width: 16),

                // Match Info (Center)
                Column(
                  children: [
                    // Date & Time
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Score with real-time updates
                    _buildScoreDisplay(),

                    const SizedBox(height: 8),

                    // Handicap
                    Text(
                      handicap,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Player 2 (Right)
                Expanded(
                  child: _buildPlayerInfo(
                    name: player2Name,
                    rank: player2Rank,
                    avatar: player2Avatar,
                    isOnline: player2Online,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom info: Prize + Race + Table
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Prize
                const Icon(
                  Icons.emoji_events,
                  size: 14,
                  color: Color(0xFF00695C),
                ),
                const SizedBox(width: 4),
                Text(
                  prize,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),

                const SizedBox(width: 16),

                // Race info
                Text(
                  raceInfo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                  ),
                ),

                const SizedBox(width: 16),

                // Current table
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    currentTable,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),
              ],
            ),

            // Watch Live button (nếu có live stream)
            if (canWatchLive) ...[
              const SizedBox(height: 12),
              _buildWatchLiveButton(),
            ],
          ],
        ),
      ),
    );
  }

  /// Build score display with real-time animation
  Widget _buildScoreDisplay() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: Row(
        key: ValueKey('$_player1Score-$_player2Score'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _player1Score.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '–',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _player2Score.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  /// Build status badge with live indicator
  Widget _buildStatusBadge(String status, bool isLive) {
    Color bgColor;
    Color textColor;
    String label;

    // Map database status to display status
    switch (status) {
      case 'pending':
        bgColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        label = 'Ready';
        break;
      case 'in_progress':
        bgColor = const Color(0xFFFF9800);
        textColor = Colors.white;
        label = isLive ? 'Live' : 'Playing';
        break;
      case 'completed':
        bgColor = const Color(0xFF9E9E9E);
        textColor = Colors.white;
        label = 'Done';
        break;
      default:
        bgColor = const Color(0xFFE0E0E0);
        textColor = const Color(0xFF757575);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build live streaming badge
  Widget _buildLiveStreamingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5722).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.videocam,
            size: 16,
            color: Colors.white,
          ),
          SizedBox(width: 6),
          Text(
            'ĐANG PHÁT TRỰC TIẾP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build "Watch Live" button
  Widget _buildWatchLiveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onWatchLive,
        icon: const Icon(Icons.play_circle_fill, size: 20),
        label: const Text(
          'XEM TRỰC TIẾP',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5722),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildMatchTypeBadge(String matchType) {
    final isChallenge = matchType == 'Thách đấu';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isChallenge
            ? const Color(0xFFE53935).withValues(alpha: 0.1)
            : const Color(0xFF1976D2).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChallenge
              ? const Color(0xFFE53935).withValues(alpha: 0.3)
              : const Color(0xFF1976D2).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        matchType,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isChallenge ? const Color(0xFFE53935) : const Color(0xFF1976D2),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo({
    required String name,
    required String rank,
    String? avatar,
    required bool isOnline,
  }) {
    return Column(
      children: [
        // Avatar with online status
        Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE0E0E0),
                border: Border.all(color: const Color(0xFFBDBDBD), width: 2),
              ),
              child: ClipOval(
                child: avatar != null
                    ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 32,
                            color: Color(0xFF757575),
                          );
                        },
                      )
                    : const Icon(
                        Icons.person,
                        size: 32,
                        color: Color(0xFF757575),
                      ),
              ),
            ),
            if (isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Player name
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF212121),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Rank badge
        _buildRankBadge(rank),
      ],
    );
  }

  Widget _buildRankBadge(String rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF00695C).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF00695C).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        rank,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF00695C),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildClubInfo({
    required String clubName,
    String? clubLogo,
    String? clubAddress,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Club Logo
        if (clubLogo != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ClubLogoWidget(
              logoUrl: clubLogo,
              size: 24,
              borderRadius: 4,
            ),
          )
        else
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00695C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.sports_tennis,
              size: 14,
              color: Color(0xFF00695C),
            ),
          ),

        // Club Name & Address
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clubName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (clubAddress != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 10,
                      color: Color(0xFF9E9E9E),
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        clubAddress,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9E9E9E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Format date from ISO string
  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'T7 - 06/09';
    try {
      final dt = DateTime.parse(dateTime.toString());
      final weekday = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'][dt.weekday % 7];
      return '$weekday - ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'T7 - 06/09';
    }
  }

  /// Format time from ISO string
  String _formatTime(dynamic dateTime) {
    if (dateTime == null) return '19:00';
    try {
      final dt = DateTime.parse(dateTime.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '19:00';
    }
  }
}
