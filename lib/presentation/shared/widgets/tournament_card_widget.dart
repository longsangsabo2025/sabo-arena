import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/design_system.dart';
import '../../../models/tournament.dart';
// ELON_MODE_AUTO_FIX

/// Tournament Card Widget - Shared component for both Tournament List and User Profile
/// Design: Large ball icon left, club logo + tournament name, info rows, action buttons
class TournamentCardWidget extends StatelessWidget {
  final Map<String, dynamic>? tournamentMap;
  final Tournament? tournamentObj;
  final VoidCallback? onTap;
  final VoidCallback? onResultTap;
  final VoidCallback? onDetailTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;

  const TournamentCardWidget({
    super.key,
    this.tournamentMap,
    this.tournamentObj,
    this.onTap,
    this.onResultTap,
    this.onDetailTap,
    this.onShareTap,
    this.onDelete,
    this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    if (tournamentMap == null && tournamentObj == null) {
      return const SizedBox.shrink();
    }

    // ELON AUDIT: Prefer strong-typed object over Map
    final name = tournamentObj?.title ??
        tournamentMap?['name'] as String? ??
        'Tournament';

    String date;
    if (tournamentObj != null) {
      date = DateFormat('dd/MM').format(tournamentObj!.startDate);
    } else {
      date = tournamentMap?['date'] as String? ?? '06/09 - Thứ 7';
    }

    final startTime = tournamentObj != null
        ? DateFormat('h a').format(tournamentObj!.startDate)
        : tournamentMap?['startTime'] as String? ?? '9AM';

    final playersCount = tournamentObj != null
        ? '${tournamentObj!.currentParticipants}/${tournamentObj!.maxParticipants}'
        : tournamentMap?['playersCount'] as String? ?? '16/16';

    // 🚀 ELON MODE: Chỉ format số, KHÔNG tính toán gì thêm
    final prizePool = tournamentObj != null
        ? _formatPrizeSimple(tournamentObj!.prizePool.toDouble())
        : tournamentMap?['prizePool'] as String? ?? '0 VNĐ';

    final rating = tournamentObj != null
        ? tournamentObj!.rankRange
        : tournamentMap?['rating'] as String? ?? 'I → H+';

    final iconNumber = tournamentObj?.iconNumber ??
        tournamentMap?['iconNumber'] as String? ??
        '9';
    final clubLogo =
        tournamentObj?.clubLogo ?? tournamentMap?['clubLogo'] as String?;
    final clubName = tournamentObj?.clubName ??
        tournamentMap?['clubName'] as String? ??
        'Sabo';

    final isLive = tournamentObj != null
        ? tournamentObj!.status == 'active' ||
            tournamentObj!.status == 'live' ||
            tournamentObj!.status == 'ongoing'
        : tournamentMap?['isLive'] as bool? ?? false;

    final status =
        tournamentObj?.status ?? tournamentMap?['status'] as String? ?? 'ready';
    final tournamentType = tournamentObj?.tournamentType ??
        tournamentMap?['tournamentType'] as String?;

    // NEW: Extract enhancement data
    final entryFee = tournamentObj != null
        ? (tournamentObj!.entryFee > 0
            ? NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                .format(tournamentObj!.entryFee)
            : 'Free')
        : tournamentMap?['entryFee'] as String?;

    final registrationDeadline =
        tournamentObj?.registrationDeadline.toIso8601String() ??
            tournamentMap?['registrationDeadline'] as String?;

    final prizeBreakdown = tournamentObj?.prizeDistribution ??
        tournamentMap?['prizeBreakdown'] as Map<String, dynamic>?;

    final venue =
        tournamentObj?.venueAddress ?? tournamentMap?['venue'] as String?;

    // Logic Mạng (Lives)
    int mangCount = 1;
    if (tournamentObj != null) {
      mangCount = tournamentObj!.mangCount;
    } else if (tournamentType != null) {
      if (tournamentType.toLowerCase().contains('double') ||
          tournamentType.toLowerCase().contains('de')) {
        mangCount = 2;
      } else if (tournamentType.toLowerCase().contains('single') ||
          tournamentType.toLowerCase().contains('se')) {
        mangCount = 1;
      } else {
        mangCount = tournamentMap?['mangCount'] as int? ?? 1;
      }
    } else {
      // Fallback if tournamentType is missing (e.g. Club Detail tab)
      mangCount = tournamentMap?['mangCount'] as int? ?? 1;
    }

    // Calculate registration progress
    final int currentPlayers;
    final int maxPlayers;

    if (tournamentObj != null) {
      currentPlayers = tournamentObj!.currentParticipants;
      maxPlayers = tournamentObj!.maxParticipants;
    } else {
      final registrationParts = playersCount.split('/');
      currentPlayers = int.tryParse(registrationParts[0]) ?? 0;
      maxPlayers = (registrationParts.length > 1)
          ? (int.tryParse(registrationParts[1]) ?? 64)
          : 64;
    }

    final registrationProgress =
        maxPlayers > 0 ? currentPlayers / maxPlayers : 0.0;

    // 🚀 ELON STYLE: Smart Status Logic (Fixed)
    // Calculate time difference accurately
    Duration? timeUntilDeadline;
    bool isPastDeadline = false;

    if (registrationDeadline != null) {
      try {
        final deadline = DateTime.parse(registrationDeadline);
        final now = DateTime.now();
        timeUntilDeadline = deadline.difference(now);
        isPastDeadline = timeUntilDeadline.isNegative;
      } catch (e) {
        // ignore
      }
    }

    // Determine badge state
    // Priority: Completed > Live > Full > Past Deadline > Today > Urgent
    String? badgeText;
    Color badgeColor = AppColors.error;
    String badgeEmoji = '🔥';

    if (status == 'completed' || status == 'done' || status == 'cancelled') {
      badgeText = null; // Clean look for completed
    } else if (isLive) {
      badgeText = 'LIVE';
      badgeColor = AppColors.error;
      badgeEmoji = '🔴';
    } else if (currentPlayers >= maxPlayers && maxPlayers > 0) {
      badgeText = 'FULL';
      badgeColor = AppColors.textSecondary;
      badgeEmoji = '⛔';
    } else if (isPastDeadline) {
      badgeText = 'CLOSED'; // Show closed if past deadline
      badgeColor = AppColors.textSecondary;
      badgeEmoji = '🔒';
    } else if (timeUntilDeadline != null) {
      if (timeUntilDeadline.inHours <= 24) {
        badgeText = 'HÔM NAY';
        badgeColor = AppColors.error;
        badgeEmoji = '🔥';
      } else if (timeUntilDeadline.inDays <= 2) {
        badgeText = 'GẤP';
        badgeColor = AppColors.warning;
        badgeEmoji = '⚠️';
      }
    }

    final bool showBadge = badgeText != null;
    final bool isAlmostFull = registrationProgress >= 0.8;
    final bool shouldHighlight = showBadge || isAlmostFull;

    // 💰 Calculate TOTAL prize value (cash + vouchers)
    final totalPrizeDisplay = _calculateTotalPrize(prizeBreakdown, prizePool);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: shouldHighlight ? badgeColor : Colors.transparent,
            width: shouldHighlight ? 2.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: shouldHighlight
                  ? badgeColor.withValues(alpha: 0.25)
                  : AppColors.shadowDark,
              blurRadius: shouldHighlight ? 16 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // 🎱 BACKGROUND: Custom tournament card background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/tournament_card_bg.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Dark overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.shadowDark,
                        AppColors.shadowDark.withValues(alpha: 0.64),
                        AppColors.shadowDark.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),

              // Decorative balls in corner
              Positioned(
                right: -20,
                bottom: -20,
                child: Opacity(
                  opacity: 0.15,
                  child: Text(
                    iconNumber,
                    style: const TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),

              // 📦 MAIN CONTENT
              Column(
                children: [
                  // 🏢 CLUB HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.shadowDark,
                    ),
                    child: Row(
                      children: [
                        // Club Logo
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.textOnPrimary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: clubLogo != null && clubLogo.isNotEmpty
                                ? Image.network(
                                    clubLogo,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildClubLogoFallback(clubName),
                                  )
                                : _buildClubLogoFallback(clubName),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Club Name + Venue
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clubName,
                                style: const TextStyle(
                                  fontFamily: '.SF Pro Text',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textOnPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (venue != null && venue.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 10,
                                        color: AppColors.textOnPrimary),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        venue,
                                        style: const TextStyle(
                                          fontFamily: '.SF Pro Text',
                                          fontSize: 11,
                                          color: AppColors.textOnPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Smart Status Badge
                        if (showBadge)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(badgeEmoji,
                                    style: const TextStyle(fontSize: 10)),
                                const SizedBox(width: 2),
                                Text(
                                  badgeText,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textOnPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 🚀 ELON STYLE: Menu Button
                        const SizedBox(width: 8),
                        _buildMenuButton(context),
                      ],
                    ),
                  ),

                  // 🎯 MAIN CONTENT AREA
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // 1. TOP SECTION: Icon + Name + Date
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ball Icon
                            _buildTournamentIconCompact(iconNumber),

                            const SizedBox(width: 14),

                            // Info Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tournament Name
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontFamily: '.SF Pro Display',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textOnPrimary,
                                      letterSpacing: -0.5,
                                      height: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: AppColors.shadow,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 10),

                                  // Date + Time Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade700,
                                          Colors.blue.shade900
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_month_rounded,
                                            size: 14, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$date · $startTime',
                                          style: const TextStyle(
                                            fontFamily: '.SF Pro Text',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 2. MIDDLE SECTION: Prize Pool (Full Width Center)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.emoji_events,
                                      size: 14, color: AppColors.warning),
                                  const SizedBox(width: 6),
                                  Text(
                                    'TỔNG GIẢI THƯỞNG',
                                    style: TextStyle(
                                      fontFamily: '.SF Pro Text',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.warning
                                          .withValues(alpha: 0.9),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                totalPrizeDisplay,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: '.SF Pro Display',
                                  fontSize: 38, // Increased size
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.warning,
                                  letterSpacing: -1.0,
                                  height: 1.1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      offset: Offset(0, 4),
                                      blurRadius: 8,
                                    ),
                                    Shadow(
                                      color: AppColors.warning,
                                      blurRadius: 16,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Bonus indicators
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_hasVoucher(prizeBreakdown))
                                    _buildPrizeTag(
                                        '🎁 Voucher', AppColors.success),
                                  if (_hasHonorBoard(prizeBreakdown)) ...[
                                    const SizedBox(width: 6),
                                    _buildPrizeTag(
                                        '📜 Vinh danh', AppColors.warning),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 3. BOTTOM SECTION: Lives Badge
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  Colors.orange.shade800.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.orange.shade300
                                      .withValues(alpha: 0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite,
                                    size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  '$mangCount Mạng',
                                  style: const TextStyle(
                                    fontFamily: '.SF Pro Text',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 📊 BOTTOM STATS BAR
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.textOnPrimary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Slots
                        Flexible(
                          child: _buildStatChip(
                              '👥',
                              playersCount,
                              isAlmostFull
                                  ? AppColors.error
                                  : AppColors.textTertiary),
                        ),
                        const SizedBox(width: 6),
                        // Rank
                        Flexible(
                          child: _buildStatChip('🎯', rating, AppColors.info),
                        ),
                        const SizedBox(width: 6),
                        // Entry Fee
                        Flexible(
                          child: _buildStatChip(
                            entryFee?.toLowerCase() == 'free' || entryFee == '0'
                                ? '🆓'
                                : '💵',
                            entryFee?.toLowerCase() == 'free' || entryFee == '0'
                                ? 'FREE'
                                : 'Lệ phí ${entryFee ?? '100K'}',
                            entryFee?.toLowerCase() == 'free' || entryFee == '0'
                                ? AppColors.success
                                : AppColors.textTertiary,
                          ),
                        ),

                        const Spacer(),

                        // Action Button
                        _buildActionButtonNew(status, isLive),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Prize Tag
  Widget _buildPrizeTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // Calculate total prize value
  // 🚀 ELON MODE: BỎ TOÀN BỘ LOGIC TÍNH TOÁN
  // Chỉ format số từ totalPrizePool trong prize_distribution
  // Hoặc fallback về prizePool string đã format sẵn
  String _calculateTotalPrize(
      Map<String, dynamic>? prizeBreakdown, String prizePool) {
    // Nếu có totalPrizePool trong prize_distribution, dùng nó
    if (prizeBreakdown != null &&
        prizeBreakdown.containsKey('totalPrizePool')) {
      final total =
          (prizeBreakdown['totalPrizePool'] as num?)?.toDouble() ?? 0.0;
      if (total > 0) {
        return _formatPrizeSimple(total);
      }
    }

    // Không tính toán gì cả, trả về string đã format sẵn
    return prizePool;
  }

  // 🚀 ELON MODE: Helper đơn giản để format số thành VNĐ
  String _formatPrizeSimple(double amount) {
    if (amount >= 1000000) {
      final val = amount / 1000000;
      final str = val.toStringAsFixed(1);
      // Bỏ .0 nếu là số nguyên (10.0M -> 10M)
      return '${str.endsWith('.0') ? str.substring(0, str.length - 2) : str}M VNĐ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K VNĐ';
    } else {
      return '${amount.toStringAsFixed(0)} VNĐ';
    }
  }

  // Stat Chip for bottom bar
  Widget _buildStatChip(String emoji, String value, Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundShade(baseColor),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderShade(baseColor)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _getTextShade(baseColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundShade(Color baseColor) {
    if (baseColor == AppColors.error) return AppColors.error50;
    if (baseColor == AppColors.info) return AppColors.info50;
    if (baseColor == AppColors.success) return AppColors.success50;
    return AppColors.gray50;
  }

  Color _getBorderShade(Color baseColor) {
    if (baseColor == AppColors.error) return AppColors.error100;
    if (baseColor == AppColors.info) return AppColors.info100;
    if (baseColor == AppColors.success) return AppColors.success100;
    return AppColors.gray200;
  }

  Color _getTextShade(Color baseColor) {
    if (baseColor == AppColors.error) return AppColors.error700;
    if (baseColor == AppColors.info) return AppColors.info700;
    if (baseColor == AppColors.success) return AppColors.success700;
    return AppColors.gray700;
  }

  // New Action Button
  Widget _buildActionButtonNew(String status, bool isLive) {
    Color bgColor;
    String text;
    IconData icon;

    if (status == 'done' || status == 'completed') {
      bgColor = AppColors.primary; // Highlighted color for results
      text = 'Kết quả';
      icon = Icons.emoji_events;
    } else if (isLive) {
      bgColor = AppColors.error;
      text = '• LIVE';
      icon = Icons.play_circle;
    } else {
      bgColor = AppColors.success700;
      text = 'Xem';
      icon = Icons.arrow_forward;
    }

    return GestureDetector(
      onTap: () {
        if (status == 'done' || status == 'completed') {
          onResultTap?.call();
        } else {
          // Prefer onDetailTap, fallback to onTap
          if (onDetailTap != null) {
            onDetailTap!();
          } else {
            onTap?.call();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: AppColors.textOnPrimary),
          ],
        ),
      ),
    );
  }

  // 🎱 Compact Ball Icon
  Widget _buildTournamentIconCompact(String number) {
    String ballImage;
    switch (number) {
      case '8':
        ballImage = 'assets/images/8ball.png';
        break;
      case '9':
        ballImage = 'assets/images/9ball.png';
        break;
      case '10':
        ballImage = 'assets/images/10ball.png';
        break;
      default:
        ballImage = 'assets/images/9ball.png';
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          ballImage,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Bonus Chip
  // ============ HELPER METHODS ============

  Widget _buildClubLogoFallback(String clubName) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          clubName.isNotEmpty ? clubName[0].toUpperCase() : 'S',
          style: const TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.info,
          ),
        ),
      ),
    );
  }

  /// 🎟️ Check if prize breakdown contains voucher
  bool _hasVoucher(Map<String, dynamic>? prizeBreakdown) {
    if (prizeBreakdown == null) return false;

    // 🚀 ELON MODE: Check trong 'distribution' array (từ DB structure mới)
    if (prizeBreakdown.containsKey('distribution') &&
        prizeBreakdown['distribution'] is List) {
      final distribution = prizeBreakdown['distribution'] as List;
      return distribution.any((prize) =>
          prize is Map &&
          prize['voucherId'] != null &&
          prize['voucherId'] != '');
    }

    // Fallback: Check old format (string values)
    for (final value in prizeBreakdown.values) {
      if (value is String && value.toLowerCase().contains('voucher')) {
        return true;
      }
    }
    return false;
  }

  /// 🏆 Check if prize breakdown contains physical prizes (cúp, bảng vinh danh)
  bool _hasHonorBoard(Map<String, dynamic>? prizeBreakdown) {
    if (prizeBreakdown == null) return false;

    // 🚀 ELON MODE: Check trong 'distribution' array
    if (prizeBreakdown.containsKey('distribution') &&
        prizeBreakdown['distribution'] is List) {
      final distribution = prizeBreakdown['distribution'] as List;
      return distribution.any((prize) =>
          prize is Map &&
          prize['physicalPrize'] != null &&
          prize['physicalPrize'] != '');
    }

    // Fallback: Check old format
    for (final value in prizeBreakdown.values) {
      if (value is String &&
          (value.toLowerCase().contains('vinh danh') ||
              value.toLowerCase().contains('bảng vinh') ||
              value.toLowerCase().contains('cúp') ||
              value.toLowerCase().contains('trophy'))) {
        return true;
      }
    }
    return false;
  }

  Widget _buildMenuButton(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert,
            color: AppColors.textOnPrimary, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 160),
        offset: const Offset(0, 40),
        onSelected: (value) {
          switch (value) {
            case 'share':
              onShareTap?.call();
              break;
            case 'hide':
              onHide?.call();
              break;
            case 'delete':
              onDelete?.call();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'share',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.share_outlined,
                    size: 18, color: AppColors.textPrimary),
                SizedBox(width: 12),
                Text('Chia sẻ',
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              ],
            ),
          ),
          if (onHide != null)
            const PopupMenuItem(
              value: 'hide',
              height: 40,
              child: Row(
                children: [
                  Icon(Icons.visibility_off_outlined,
                      size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 12),
                  Text('Ẩn giải đấu',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textPrimary)),
                ],
              ),
            ),
          if (onDelete != null)
            const PopupMenuItem(
              value: 'delete',
              height: 40,
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  SizedBox(width: 12),
                  Text('Xóa giải đấu',
                      style: TextStyle(fontSize: 14, color: AppColors.error)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
