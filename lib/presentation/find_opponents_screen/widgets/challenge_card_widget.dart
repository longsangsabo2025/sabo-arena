import 'package:flutter/material.dart';
import '../../../services/challenge_list_service.dart';

/// Card widget to display a challenge/invite in list
class ChallengeCardWidget extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final VoidCallback? onTap;
  final bool isCompetitive; // true = thach_dau, false = giao_luu

  const ChallengeCardWidget({
    super.key,
    required this.challenge,
    this.onTap,
    this.isCompetitive = true,
  });

  @override
  Widget build(BuildContext context) {
    final challenger = challenge['challenger'] as Map<String, dynamic>?;
    final matchConditions = ChallengeListService.instance.parseMatchConditions(
      challenge['match_conditions'],
    );

    final gameType = matchConditions['game_type'] ?? '8-ball';
    final location = matchConditions['location'] ?? 'Chưa xác định';
    final scheduledTime = matchConditions['scheduled_time'];
    final spaPoints = challenge['stakes_amount'] ?? 0;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompetitive
              ? const Color(0xFFFFB74D).withValues(alpha: 0.3)
              : const Color(0xFF0866FF).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar + Name + Badge
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: isTablet ? 60 : 50,
                      height: isTablet ? 60 : 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0866FF),
                      ),
                      child: Center(
                        child: Text(
                          (challenger?['display_name'] ?? 'U')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),

                    // Name + Rank
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenger?['display_name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Rank Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 10,
                              vertical: isTablet ? 5 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCompetitive
                                  ? const Color(0xFFFF9800)
                                  : const Color(0xFF0866FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              challenger?['rank'] ?? 'Unranked',
                              style: TextStyle(
                                fontSize: isTablet ? 12 : 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Challenge Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCompetitive
                              ? [
                                  const Color(0xFFFF9800),
                                  const Color(0xFFFF6F00),
                                ]
                              : [
                                  const Color(0xFF0866FF),
                                  const Color(0xFF0952CC),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompetitive ? Icons.emoji_events : Icons.groups,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompetitive ? 'Thách đấu' : 'Giao lưu',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.grey.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Challenge Info
                _buildInfoRow(
                  Icons.sports_esports,
                  'Game',
                  gameType,
                  const Color(0xFF0866FF),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Thời gian',
                  ChallengeListService.instance.formatChallengeDateTime(
                    scheduledTime,
                  ),
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.location_on,
                  'Địa điểm',
                  location,
                  const Color(0xFFEF4444),
                ),

                if (isCompetitive && spaPoints > 0) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.monetization_on,
                    'SPA Bonus',
                    '$spaPoints điểm',
                    const Color(0xFFFF9800),
                  ),
                ],

                // Message if exists
                if (challenge['message'] != null &&
                    challenge['message'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.message,
                          size: 16,
                          color: Color(0xFF65676B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            challenge['message'].toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF050505),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action Button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompetitive
                          ? [const Color(0xFFFF9800), const Color(0xFFFF6F00)]
                          : [const Color(0xFF0866FF), const Color(0xFF0952CC)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isCompetitive
                                    ? const Color(0xFFFF9800)
                                    : const Color(0xFF0866FF))
                                .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCompetitive
                              ? 'Nhận thách đấu'
                              : 'Chấp nhận lời mời',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF65676B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF050505),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
