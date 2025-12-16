import 'package:flutter/material.dart';
import '../../../services/club_permission_service.dart';
import '../../../services/user_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX
import 'package:sabo_arena/widgets/club/club_logo_widget.dart';

/// Match Card Widget - Hiển thị thông tin trận đấu theo thiết kế mới
/// Design: 2 players (left vs right) với match info ở giữa
class MatchCardWidget extends StatefulWidget {
  final Map<String, dynamic> match;
  final VoidCallback? onTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onInputScore; // ✅ NEW: Callback for score input

  const MatchCardWidget({
    super.key,
    required this.match,
    this.onTap,
    this.onShareTap,
    this.onInputScore,
  });
  
  @override
  State<MatchCardWidget> createState() => _MatchCardWidgetState();
}

class _MatchCardWidgetState extends State<MatchCardWidget> {
  final ClubPermissionService _permissionService = ClubPermissionService();
  final UserService _userService = UserService.instance;
  bool _canInputScore = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkScoreInputPermission();
  }
  
  Future<void> _checkScoreInputPermission() async {
    try {
      // Get club_id from match data
      final clubId = widget.match['clubId'] as String?;
      
      if (clubId == null || clubId.isEmpty) {
        // No club → no permission needed
        if (mounted) {
          setState(() {
            _canInputScore = false;
            _isCheckingPermission = false;
          });
        }
        return;
      }
      
      // Get current user
      final currentUser = await _userService.getCurrentUserProfile();
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _canInputScore = false;
            _isCheckingPermission = false;
          });
        }
        return;
      }
      
      // ✅ Check if user is CLB owner
      final isOwner = await _permissionService.isClubOwner(clubId, currentUser.id);
      
      if (mounted) {
        setState(() {
          _canInputScore = isOwner;
          _isCheckingPermission = false;
        });
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (mounted) {
        setState(() {
          _canInputScore = false;
          _isCheckingPermission = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Player info
    final player1Id = widget.match['player1Id'] as String?;
    final player1Name = widget.match['player1Name'] as String? ?? 'Player 1';
    final player1Rank = widget.match['player1Rank'] as String?; // NULL = chưa xác minh
    final player1Avatar = widget.match['player1Avatar'] as String?;
    final player1Online = widget.match['player1Online'] as bool? ?? false;

    final player2Id = widget.match['player2Id'] as String?;
    final player2Name = widget.match['player2Name'] as String? ?? 'Player 2';
    final player2Rank = widget.match['player2Rank'] as String?; // NULL = chưa xác minh
    final player2Avatar = widget.match['player2Avatar'] as String?;
    final player2Online = widget.match['player2Online'] as bool? ?? false;

    // Club info
    final clubName = widget.match['clubName'] as String?;
    final clubLogo = widget.match['clubLogo'] as String?;
    final clubAddress = widget.match['clubAddress'] as String?;

    // Match info
    final status = widget.match['status'] as String? ?? 'ready'; // ready, live, done
    final matchType = widget.match['matchType'] as String?; // Giao lưu hoặc Thách đấu
    final date = widget.match['date'] as String? ?? 'T7 - 06/09';
    final time = widget.match['time'] as String? ?? '19:00';
    final score1 = widget.match['score1'] as String? ?? '?';
    final score2 = widget.match['score2'] as String? ?? '?';
    final handicap = widget.match['handicap'] as String? ?? 'Handicap 0.5 ván';
    final prize = widget.match['prize'] as String? ?? '100 SPA';
    final raceInfo = widget.match['raceInfo'] as String? ?? 'Race to 7';
    final currentTable = widget.match['currentTable'] as String? ?? 'Bàn 1';
    
    // Winner info (for completed matches)
    final winnerId = widget.match['winnerId'] as String?;
    final isPlayer1Winner = winnerId != null && winnerId == player1Id;
    final isPlayer2Winner = winnerId != null && winnerId == player2Id;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
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

                // Status Badge ở giữa
                _buildStatusBadge(status),

                // Match Type badge ở góc phải
                Expanded(
                  child: matchType != null
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: _buildMatchTypeBadge(matchType),
                        )
                      : const SizedBox(),
                ),
              ],
            ),

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
                    isWinner: isPlayer1Winner, // ✅ Highlight winner
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

                    // Score
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          score1,
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
                          score2,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),

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
                    isWinner: isPlayer2Winner, // ✅ Highlight winner
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

            // Share button (if callback provided)
            if (widget.onShareTap != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: widget.onShareTap,
                  icon: const Icon(Icons.share, size: 20),
                  color: Colors.grey[600],
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: 'Chia sẻ trận đấu',
                ),
              ),
            ],
            
            // ✅ NEW: Score Input Button (CLB Owner only)
            if (_canInputScore && widget.onInputScore != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00695C), Color(0xFF00897B)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00695C).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: widget.onInputScore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_note,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Nhập tỷ số',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            
            // ✅ Loading indicator while checking permission
            if (_isCheckingPermission) ...[
              const SizedBox(height: 8),
              const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00695C)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'ready':
        bgColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        label = 'Ready';
        break;
      case 'live':
        bgColor = const Color(0xFFFF9800);
        textColor = Colors.white;
        label = 'Live';
        break;
      case 'done':
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
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMatchTypeBadge(String matchType) {
    // matchType: "Giao lưu" hoặc "Thách đấu"
    final isChallenge = matchType == 'Thách đấu';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isChallenge
            ? const Color(0xFFE53935).withValues(alpha: 0.1) // Đỏ cho thách đấu
            : const Color(0xFF1976D2).withValues(alpha: 0.1), // Xanh cho giao lưu
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
          color: isChallenge
              ? const Color(0xFFE53935) // Đỏ cho thách đấu
              : const Color(0xFF1976D2), // Xanh cho giao lưu
        ),
      ),
    );
  }

  Widget _buildPlayerInfo({
    required String name,
    String? rank, // NULL = chưa xác minh hạng
    String? avatar,
    required bool isOnline,
    bool isWinner = false, // ✅ NEW: Winner highlight
  }) {
    return Container(
      padding: isWinner ? const EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: isWinner
          ? BoxDecoration(
              color: const Color(0xFFFFF9C4), // Light yellow background
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700), // Gold border
                width: 2,
              ),
            )
          : null,
      child: Column(
        children: [
          // Avatar with online status + Winner badge
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE0E0E0),
                  border: Border.all(
                    color: isWinner ? const Color(0xFFFFD700) : const Color(0xFFBDBDBD),
                    width: isWinner ? 3 : 2,
                  ),
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
              // ✅ Winner trophy icon
              if (isWinner)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Player name
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w700,
              color: isWinner ? const Color(0xFFF57F17) : const Color(0xFF212121),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Rank badge (only show if rank is verified)
          if (rank != null) _buildRankBadge(rank),
          if (rank == null) _buildUnverifiedBadge(),
        ],
      ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildUnverifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF9E9E9E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF9E9E9E).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Text(
        '?',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9E9E9E),
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
}

