import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Tournament Card Widget - Shared component for both Tournament List and User Profile
/// Design: Large ball icon left, club logo + tournament name, info rows, action buttons
class TournamentCardWidget extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final VoidCallback? onTap;
  final VoidCallback? onResultTap;
  final VoidCallback? onDetailTap;
  final VoidCallback? onShareTap;

  const TournamentCardWidget({
    super.key,
    required this.tournament,
    this.onTap,
    this.onResultTap,
    this.onDetailTap,
    this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = tournament['name'] as String? ?? 'Tournament';
    final date = tournament['date'] as String? ?? '06/09 - Thứ 7';
    final startTime = tournament['startTime'] as String? ?? '9AM';
    final playersCount = tournament['playersCount'] as String? ?? '16/16';
    final prizePool = tournament['prizePool'] as String? ?? '10 Million';
    final rating = tournament['rating'] as String? ?? 'I → H+';
    final iconNumber = tournament['iconNumber'] as String? ?? '9';
    final clubLogo = tournament['clubLogo'] as String?;
    final clubName = tournament['clubName'] as String? ?? 'Sabo';
    final mangCount = tournament['mangCount'] as int? ?? 2;
    final isLive = tournament['isLive'] as bool? ?? false;
    final status = tournament['status'] as String? ?? 'ready';
    
    // NEW: Extract enhancement data
    final entryFee = tournament['entryFee'] as String?;
    final registrationDeadline = tournament['registrationDeadline'] as String?;
    final prizeBreakdown = tournament['prizeBreakdown'] as Map<String, dynamic>?;
    final venue = tournament['venue'] as String?;
    
    // Calculate registration progress
    final registrationParts = playersCount.split('/');
    final currentPlayers = int.tryParse(registrationParts[0]) ?? 0;
    final maxPlayers = int.tryParse(registrationParts[1]) ?? 64;
    final registrationProgress = maxPlayers > 0 ? currentPlayers / maxPlayers : 0.0;
    
    // Calculate days until deadline
    int? daysUntilDeadline;
    if (registrationDeadline != null) {
      try {
        final deadline = DateTime.parse(registrationDeadline);
        final now = DateTime.now();
        daysUntilDeadline = deadline.difference(now).inDays;
      } catch (e) {
        daysUntilDeadline = null;
      }
    }

    // Debug log
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // 🚀 ELON STYLE: Calculate urgency level
    final bool isUrgent = daysUntilDeadline != null && daysUntilDeadline <= 1;
    final bool isAlmostFull = registrationProgress >= 0.8;
    final bool shouldHighlight = isUrgent || isAlmostFull;
    
    // 💰 Calculate TOTAL prize value (cash + vouchers)
    final totalPrizeDisplay = _calculateTotalPrize(prizeBreakdown, prizePool);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: shouldHighlight ? AppColors.warning : Colors.transparent,
            width: shouldHighlight ? 2.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: shouldHighlight 
                  ? AppColors.warning.withValues(alpha: 0.25)
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                    errorBuilder: (_, __, ___) => _buildClubLogoFallback(clubName),
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
                                    const Icon(Icons.location_on, size: 10, color: AppColors.textOnPrimary),
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
                        // Urgent Badge
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🔥', style: TextStyle(fontSize: 10)),
                                SizedBox(width: 2),
                                Text(
                                  'HÔM NAY',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textOnPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 🎯 MAIN CONTENT AREA
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: AppColors.textOnPrimary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$date · $startTime',
                                      style: const TextStyle(
                                        fontFamily: '.SF Pro Text',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textOnPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // 💰 TOTAL PRIZE - HERO SECTION
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                                // Removed background decoration as requested
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.emoji_events, size: 14, color: AppColors.warning),
                                        const SizedBox(width: 6),
                                        Text(
                                          'TỔNG GIẢI THƯỞNG',
                                          style: TextStyle(
                                            fontFamily: '.SF Pro Text',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.warning.withValues(alpha: 0.9),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      totalPrizeDisplay,
                                      style: const TextStyle(
                                        fontFamily: '.SF Pro Display',
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.warning,
                                        letterSpacing: -0.5,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Bonus indicators
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_hasVoucher(prizeBreakdown))
                                          _buildPrizeTag('🎁 Voucher', AppColors.success),
                                        if (_hasHonorBoard(prizeBreakdown)) ...[
                                          const SizedBox(width: 6),
                                          _buildPrizeTag('📜 Vinh danh', AppColors.warning),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 📊 BOTTOM STATS BAR
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        _buildStatChip('👥', playersCount, isAlmostFull ? AppColors.error : AppColors.textTertiary),
                        const SizedBox(width: 8),
                        // Rank
                        _buildStatChip('🎯', rating, AppColors.info),
                        const SizedBox(width: 8),
                        // Entry Fee
                        _buildStatChip(
                          entryFee?.toLowerCase() == 'free' || entryFee == '0' ? '🆓' : '💵',
                          entryFee?.toLowerCase() == 'free' || entryFee == '0' ? 'FREE' : (entryFee ?? '100K'),
                          entryFee?.toLowerCase() == 'free' || entryFee == '0' ? AppColors.success : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        // Mạng
                        if (mangCount > 0) _buildStatChip('❤️', '$mangCount Mạng', AppColors.error),
                        
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
  String _calculateTotalPrize(Map<String, dynamic>? prizeBreakdown, String prizePool) {
    if (prizeBreakdown == null) return prizePool;
    
    double totalCash = 0;
    double totalVoucher = 0;
    
    for (final value in prizeBreakdown.values) {
      if (value is String) {
        // Parse cash amounts like "1.000.000 VNĐ"
        final cashMatch = RegExp(r'([\d.,]+)\s*(triệu|tr|M|VNĐ|VND|k|K)').firstMatch(value);
        if (cashMatch != null) {
          String numStr = cashMatch.group(1)!.replaceAll('.', '').replaceAll(',', '');
          double amount = double.tryParse(numStr) ?? 0;
          String unit = cashMatch.group(2)?.toLowerCase() ?? '';
          
          if (unit == 'triệu' || unit == 'tr' || unit == 'm') {
            amount *= 1000000;
          } else if (unit == 'k') {
            amount *= 1000;
          }
          totalCash += amount;
        }
        
        // Parse voucher amounts like "500k Voucher"
        final voucherMatch = RegExp(r'([\d.,]+)\s*k?\s*[Vv]oucher').firstMatch(value);
        if (voucherMatch != null) {
          String numStr = voucherMatch.group(1)!.replaceAll('.', '').replaceAll(',', '');
          double amount = double.tryParse(numStr) ?? 0;
          if (value.toLowerCase().contains('k')) {
            amount *= 1000;
          }
          totalVoucher += amount;
        }
      }
    }
    
    double total = totalCash + totalVoucher;
    
    if (total >= 1000000) {
      return '${(total / 1000000).toStringAsFixed(1)}M VNĐ';
    } else if (total >= 1000) {
      return '${(total / 1000).toStringAsFixed(0)}K VNĐ';
    } else if (total > 0) {
      return '${total.toStringAsFixed(0)} VNĐ';
    }
    
    return prizePool;
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
    
    if (status == 'done') {
      bgColor = AppColors.textSecondary;
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
        if (status == 'done') {
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
  Widget _buildBonusChip(String emoji, String label, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: label,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.shade200),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  // Stat Item
  Widget _buildStatItem(String emoji, String value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Divider
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.border,
    );
  }

  // Action Button
  Widget _buildActionButton(String status, bool isLive) {
    if (status == 'done') {
      return _buildMiniButton('Kết quả', AppColors.textSecondary, Icons.emoji_events);
    } else if (isLive) {
      return _buildMiniButton('LIVE', AppColors.error, Icons.play_circle);
    } else {
      return _buildMiniButton('Chi tiết', AppColors.info, Icons.arrow_forward);
    }
  }

  Widget _buildMiniButton(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 12,
              fontWeight: FontWeight.w600,
                            color: AppColors.surface,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: AppColors.textOnPrimary),
        ],
      ),
    );
  }

  // ============ HELPER METHODS ============

  Widget _buildTournamentIcon(String number) {
    // Determine ball image based on number
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
        ballImage = 'assets/images/9ball.png'; // Default to 9-ball
    }

    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          ballImage,
          width: 110,
          height: 110,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image not found
            return Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 48,
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

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMangBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        '$count Mạng',
        style: const TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.info,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildLiveButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_fill, size: 14, color: AppColors.textOnPrimary),
          const SizedBox(width: 4),
          Text(
            'Live',
            style: const TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 12,
              fontWeight: FontWeight.w600,
                            color: AppColors.surface,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultButton() {
    return GestureDetector(
      onTap: onResultTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.info,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: AppColors.info.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 14, color: AppColors.textOnPrimary),
            const SizedBox(width: 4),
            Text(
              'Kết Quả',
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                            color: AppColors.surface,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailButton() {
    return GestureDetector(
      onTap: onDetailTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 14, color: AppColors.textOnPrimary),
            const SizedBox(width: 4),
            Text(
              'Chi Tiết',
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                            color: AppColors.surface,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return GestureDetector(
      onTap: onShareTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gray300, width: 1),
        ),
        child: const Icon(
          Icons.share,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPrizeItem(String emoji, String prize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          prize,
          style: const TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPrizeItemWithTitle(String emoji, String title, String prize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          prize,
          style: const TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Get first place prize from prizeBreakdown or fallback to prizePool
  String _getFirstPlacePrize(Map<String, dynamic>? prizeBreakdown, String prizePool) {
    if (prizeBreakdown != null && prizeBreakdown['first'] != null) {
      final firstPrize = prizeBreakdown['first'] as String;
      // If prize contains "+", just show the cash part for card display
      if (firstPrize.contains('+')) {
        final cashPart = firstPrize.split('+').first.trim();
        return cashPart;
      }
      return firstPrize;
    }
    return prizePool;
  }

  /// Check if prize breakdown contains voucher
  bool _hasVoucher(Map<String, dynamic>? prizeBreakdown) {
    if (prizeBreakdown == null) return false;
    
    // Check all prize entries for "voucher" keyword
    for (final value in prizeBreakdown.values) {
      if (value is String && value.toLowerCase().contains('voucher')) {
        return true;
      }
    }
    return false;
  }

  /// Check if prize breakdown contains honor board (bảng vinh danh)
  bool _hasHonorBoard(Map<String, dynamic>? prizeBreakdown) {
    if (prizeBreakdown == null) return false;
    
    // Check all prize entries for "vinh danh" or "bảng" keyword
    for (final value in prizeBreakdown.values) {
      if (value is String && 
          (value.toLowerCase().contains('vinh danh') || 
           value.toLowerCase().contains('bảng vinh'))) {
        return true;
      }
    }
    return false;
  }
}

