import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart';
import 'package:sabo_arena/widgets/club/club_logo_widget.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
import 'package:sabo_arena/models/match.dart';

/// Match Card Widget with Real-time Updates - Phase 5-6
/// Features:
/// - Real-time score updates via Supabase Realtime
/// - Live streaming badge and "Watch Live" button
/// - Automatic UI refresh when match data changes
/// - Support for in_progress matches with live scores
class MatchCardWidgetRealtime extends StatefulWidget {
  final Match match;
  final VoidCallback? onTap;
  final VoidCallback? onWatchLive;

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
  late Match _currentMatch;

  @override
  void initState() {
    super.initState();
    _currentMatch = widget.match;
    _subscribeToMatchUpdates();
  }

  @override
  void didUpdateWidget(MatchCardWidgetRealtime oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.match.id != oldWidget.match.id) {
      _unsubscribeFromUpdates();
      _currentMatch = widget.match;
      _subscribeToMatchUpdates();
    }
  }

  @override
  void dispose() {
    _unsubscribeFromUpdates();
    super.dispose();
  }

  /// Subscribe to real-time match updates
  void _subscribeToMatchUpdates() {
    final matchId = widget.match.id;
    if (matchId.isEmpty) return;

    // Only subscribe if match is in_progress
    if (!_currentMatch.isInProgress) {
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
      _currentMatch = _currentMatch.copyWith(
        player1Score: newData['player1_score'] as int?,
        player2Score: newData['player2_score'] as int?,
        status: newData['status'] as String?,
        isLive: newData['is_live'] as bool?,
      );
    });

    ProductionLogger.info('✅ UI updated - Score: ${_currentMatch.player1Score} - ${_currentMatch.player2Score}, Status: ${_currentMatch.status}, Live: ${_currentMatch.isLive}', tag: 'match_card_widget_realtime');
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
    final player1Name = _currentMatch.player1Profile?.fullName ?? 
                        _currentMatch.player1Name ?? 
                        'Player 1';
    final player1Rank = _currentMatch.player1Profile?.rank ?? 'H';
    final player1Avatar = _currentMatch.player1Profile?.avatarUrl;
    final player1Online = false;

    final player2Name = _currentMatch.player2Profile?.fullName ?? 
                        _currentMatch.player2Name ?? 
                        'Player 2';
    final player2Rank = _currentMatch.player2Profile?.rank ?? 'H';
    final player2Avatar = _currentMatch.player2Profile?.avatarUrl;
    final player2Online = false;

    // Club info
    final clubName = _currentMatch.club?.name;
    final clubLogo = _currentMatch.club?.logoUrl;
    final clubAddress = _currentMatch.club?.address;

    // Match info
    final matchType = _currentMatch.matchType == 'thach_dau' ? 'Thách đấu' : 
                      (_currentMatch.matchType == 'giao_luu' ? 'Giao lưu' : 
                      _currentMatch.matchTypeDisplay);
    
    final date = _formatDate(_currentMatch.scheduledAt);
    final time = _formatTime(_currentMatch.scheduledAt);
    
    final handicap = _currentMatch.metadata?['handicap'] as String? ?? 'Handicap 0.5 ván';
    final prize = _currentMatch.metadata?['prize'] as String? ?? '100 SPA';
    final raceInfo = _currentMatch.metadata?['race_to'] != null 
        ? 'Race to ${_currentMatch.metadata!['race_to']}' 
        : 'Race to 7';
    final currentTable = _currentMatch.table != null 
        ? 'Bàn ${_currentMatch.table}' 
        : 'Bàn 1';

    // Video URL for live streaming
    final videoUrl = _currentMatch.videoUrls?.isNotEmpty == true ? _currentMatch.videoUrls!.first : null;
    final canWatchLive = _currentMatch.isLive && videoUrl != null && videoUrl.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _currentMatch.isLive ? const Color(0xFFFF5722) : const Color(0xFFE0E0E0),
            width: _currentMatch.isLive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _currentMatch.isLive 
                ? const Color(0xFFFF5722).withValues(alpha: 0.2) 
                : Colors.black.withValues(alpha: 0.05),
              blurRadius: _currentMatch.isLive ? 12 : 8,
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
                _buildStatusBadge(_currentMatch.status, _currentMatch.isLive),

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
            if (_currentMatch.isLive) ...[
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
                    // Date & Time - Highlighted
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
        key: ValueKey('${_currentMatch.player1Score}-${_currentMatch.player2Score}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (_currentMatch.player1Score ?? 0).toString(),
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
            (_currentMatch.player2Score ?? 0).toString(),
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
        label = 'Hoàn thành';
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
            UserAvatarWidget(
              avatarUrl: avatar,
              userName: name,
              rankCode: rank,
              size: 60,
              showRankBorder: rank.isNotEmpty,
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

        // Rank badge using unified component
        UserRankBadgeWidget(
          rankCode: rank,
          style: RankBadgeStyle.compact,
        ),
      ],
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
