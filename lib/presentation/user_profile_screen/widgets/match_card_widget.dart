import 'package:flutter/material.dart';
import '../../../services/club_permission_service.dart';
import '../../../services/user_service.dart';
import '../../../services/match_service.dart'; // Import Match model
// ELON_MODE_AUTO_FIX
import 'package:sabo_arena/widgets/club/club_logo_widget.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
import '../../../widgets/common/app_button.dart';

/// Match Card Widget - Hiển thị thông tin trận đấu theo thiết kế mới
/// Design: 2 players (left vs right) với match info ở giữa
class MatchCardWidget extends StatefulWidget {
  final Map<String, dynamic>? matchMap;
  final Match? matchObj;
  final VoidCallback? onTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onInputScore; // ✅ NEW: Callback for score input
  final Widget? bottomAction; // ✅ NEW: Custom bottom action widget

  const MatchCardWidget({
    super.key,
    this.matchMap,
    this.matchObj,
    this.onTap,
    this.onShareTap,
    this.onInputScore,
    this.bottomAction,
  }) : assert(matchMap != null || matchObj != null,
            'Either matchMap or matchObj must be provided');

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
      final clubId =
          widget.matchObj?.clubId ?? widget.matchMap?['clubId'] as String?;

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
      final isOwner =
          await _permissionService.isClubOwner(clubId, currentUser.id);

      if (mounted) {
        setState(() {
          _canInputScore = isOwner;
          _isCheckingPermission = false;
        });
      }
    } catch (e) {
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
    // Player info extraction (Elon Style: Strong typing preference)
    final String? player1Id;
    final String player1Name;
    final String? player1Rank;
    final String? player1Avatar;
    final bool player1Online;

    final String? player2Id;
    final String player2Name;
    final String? player2Rank;
    final String? player2Avatar;
    final bool player2Online;

    if (widget.matchObj != null) {
      final m = widget.matchObj!;
      player1Id = m.player1Id;
      player1Name = m.player1Name ?? 'Player 1';
      player1Rank = m.player1Rank;
      player1Avatar = m.player1Avatar;
      player1Online = false; // TODO: Real presence

      player2Id = m.player2Id;
      player2Name = m.player2Name ?? 'Player 2';
      player2Rank = m.player2Rank;
      player2Avatar = m.player2Avatar;
      player2Online = false; // TODO: Real presence
    } else {
      final m = widget.matchMap!;
      player1Id = m['player1Id'] as String?;
      player1Name = m['player1Name'] as String? ?? 'Player 1';
      player1Rank = m['player1Rank'] as String?;
      player1Avatar = m['player1Avatar'] as String?;
      player1Online = m['player1Online'] as bool? ?? false;

      player2Id = m['player2Id'] as String?;
      player2Name = m['player2Name'] as String? ?? 'Player 2';
      player2Rank = m['player2Rank'] as String?;
      player2Avatar = m['player2Avatar'] as String?;
      player2Online = m['player2Online'] as bool? ?? false;
    }

    // Club info
    final String? clubName;
    final String? clubLogo;
    final String? clubAddress;

    // Match info
    final String status;
    final String? matchType;
    final String date;
    final String time;
    final String score1;
    final String score2;
    final String handicap;
    final String prize;
    final String raceInfo;
    final String currentTable;

    // Winner info
    final String? winnerId;

    if (widget.matchObj != null) {
      final m = widget.matchObj!;
      // Assuming Match object has these fields or we need to join/fetch them
      // For now, using what's available in Match model or defaults
      clubName = null; // Match model doesn't have clubName directly yet
      clubLogo = null;
      clubAddress = null;

      status = m.status;
      matchType = null; // Not in Match model

      if (m.scheduledTime != null) {
        // Format date/time
        // We need intl here, but let's assume it's imported or use basic string
        // Using basic string formatting to avoid import issues if intl is not available
        // But wait, intl is likely available. Let's try to use it if possible or stick to basic.
        // Actually, let's use basic formatting for now to be safe and fast.
        final dt = m.scheduledTime!;
        date =
            "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}";
        time =
            "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } else {
        date = 'T7 - 06/09';
        time = '19:00';
      }

      score1 = m.player1Score.toString();
      score2 = m.player2Score.toString();
      handicap = m.notes ?? 'Handicap 0.5 ván';
      prize = '100 SPA'; // Placeholder
      raceInfo = m.tournamentTitle ?? 'Race to 7';
      currentTable = 'Round ${m.roundNumber}';
      winnerId = m.winnerId;
    } else {
      final m = widget.matchMap!;
      clubName = m['clubName'] as String?;
      clubLogo = m['clubLogo'] as String?;
      clubAddress = m['clubAddress'] as String?;

      status = m['status'] as String? ?? 'ready';
      matchType = m['matchType'] as String?;
      date = m['date'] as String? ?? 'T7 - 06/09';
      time = m['time'] as String? ?? '19:00';
      score1 = m['score1'] as String? ?? '?';
      score2 = m['score2'] as String? ?? '?';
      handicap = m['handicap'] as String? ?? 'Handicap 0.5 ván';
      prize = m['prize'] as String? ?? '100 SPA';
      raceInfo = m['raceInfo'] as String? ?? 'Race to 7';
      currentTable = m['currentTable'] as String? ?? 'Bàn 1';
      winnerId = m['winnerId'] as String?;
    }

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
                    // Date & Time - Highlighted
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
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
                child: AppButton(
                  label: 'Nhập tỷ số',
                  type: AppButtonType.primary,
                  size: AppButtonSize.medium,
                  icon: Icons.edit_note,
                  iconTrailing: false,
                  customColor: Colors.transparent,
                  customTextColor: Colors.white,
                  onPressed: widget.onInputScore,
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF00695C)),
                  ),
                ),
              ),
            ],

            // ✅ NEW: Custom Bottom Action
            if (widget.bottomAction != null) ...[
              const SizedBox(height: 12),
              widget.bottomAction!,
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
      case 'scheduled':
        bgColor = const Color(0xFF2196F3); // Blue
        textColor = Colors.white;
        label = 'Sắp đấu';
        break;
      case 'done':
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
            : const Color(0xFF1976D2)
                .withValues(alpha: 0.1), // Xanh cho giao lưu
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
    // Check if this is a "Waiting" placeholder
    final isWaiting = name == 'Đang chờ...' || name == 'Waiting...';

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
                decoration: isWinner
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 3,
                        ),
                      )
                    : null,
                child: isWaiting
                    ? _buildWaitingAvatar() // ✅ NEW: Distinct waiting avatar
                    : UserAvatarWidget(
                        avatarUrl: avatar,
                        userName: name,
                        rankCode: rank,
                        size: 60,
                        showRankBorder: rank != null && rank.isNotEmpty,
                      ),
              ),
              if (isOnline && !isWaiting)
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
              color: isWaiting
                  ? const Color(0xFF9E9E9E) // Grey for waiting
                  : (isWinner
                      ? const Color(0xFFF57F17)
                      : const Color(0xFF212121)),
              fontStyle: isWaiting ? FontStyle.italic : FontStyle.normal,
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
      ),
    );
  }

  // ✅ NEW: Distinct waiting avatar with pulse effect or dashed border
  Widget _buildWaitingAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey[400]!,
          width: 2,
          style: BorderStyle.solid, // Could use dashed border if custom painter
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: 32,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  // Note: Old rank badge methods removed - now using unified UserRankBadgeWidget

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
