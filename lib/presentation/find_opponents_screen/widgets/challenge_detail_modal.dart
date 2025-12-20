import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../../services/challenge_list_service.dart';

/// Modal to show challenge details and confirm accept/decline
class ChallengeDetailModal extends StatefulWidget {
  final Map<String, dynamic> challenge;
  final bool isCompetitive;
  final VoidCallback? onAccepted;
  final VoidCallback? onDeclined;

  const ChallengeDetailModal({
    super.key,
    required this.challenge,
    this.isCompetitive = true,
    this.onAccepted,
    this.onDeclined,
  });

  @override
  State<ChallengeDetailModal> createState() => _ChallengeDetailModalState();
}

class _ChallengeDetailModalState extends State<ChallengeDetailModal> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final challenger = widget.challenge['challenger'] as Map<String, dynamic>?;
    final matchConditions = ChallengeListService.instance.parseMatchConditions(
      widget.challenge['match_conditions'],
    );

    final gameType = matchConditions['game_type'] ?? '8-ball';
    final location = matchConditions['location'] ?? 'Chưa xác định';
    final scheduledTime = matchConditions['scheduled_time'];
    final spaPoints = widget.challenge['stakes_amount'] ?? 0;
    final message = widget.challenge['message']?.toString() ?? '';

    // 🎯 Check if challenge is already accepted
    final status = widget.challenge['status']?.toString() ?? 'pending';
    final isAlreadyAccepted = status == 'accepted';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCED0D4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                Text(
                  widget.isCompetitive
                      ? 'Chi tiết Thách đấu'
                      : 'Chi tiết Lời mời',
                  style: TextStyle(
                    fontFamily: _getSystemFont(),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF050505),
                    letterSpacing: -0.4,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    size: 24,
                    color: Color(0xFF65676B),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challenger Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isCompetitive
                            ? [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)]
                            : [
                                const Color(0xFFE3F2FD),
                                const Color(0xFFBBDEFB),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.isCompetitive
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFF64B5F6),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isCompetitive
                                ? const Color(0xFFFF9800)
                                : const Color(0xFF0866FF),
                          ),
                          child: Center(
                            child: Text(
                              (challenger?['display_name'] ?? 'U')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontFamily: _getSystemFont(),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenger?['display_name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontFamily: _getSystemFont(),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF050505),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hạng: ${challenger?['rank'] ?? 'Unranked'}',
                                style: TextStyle(
                                  fontFamily: _getSystemFont(),
                                  fontSize: 14,
                                  color: const Color(0xFF65676B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildStatChip(
                                    '${challenger?['total_wins'] ?? 0}W',
                                    Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatChip(
                                    '${challenger?['total_losses'] ?? 0}L',
                                    Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatChip(
                                    'ELO ${challenger?['elo_rating'] ?? 0}',
                                    Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Match Details
                  _buildSectionTitle('Thông tin trận đấu'),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    Icons.sports_baseball,
                    'Loại game',
                    gameType,
                    const Color(0xFF0866FF),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Thời gian',
                    ChallengeListService.instance.formatChallengeDateTime(
                      scheduledTime,
                    ),
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.location_on,
                    'Địa điểm',
                    location,
                    const Color(0xFFEF4444),
                  ),

                  if (widget.isCompetitive && spaPoints > 0) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.monetization_on,
                      'SPA Bonus',
                      '$spaPoints điểm',
                      const Color(0xFFFF9800),
                    ),
                  ],

                  // Message
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('Lời nhắn'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          fontFamily: _getSystemFont(),
                          fontSize: 15,
                          color: const Color(0xFF050505),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 🎯 Show message if already accepted
                  if (isAlreadyAccepted)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF2E7D32),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Thách đấu này đã được chấp nhận rồi. Vui lòng kiểm tra mục "Giao lưu" để xem trận đấu.',
                              style: TextStyle(
                                fontFamily: _getSystemFont(),
                                fontSize: 13,
                                color: const Color(0xFF050505),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Warning/Info Box (only show if NOT accepted)
                  if (!isAlreadyAccepted)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9C4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFBC02D),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFF57F17),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.isCompetitive
                                  ? 'Chấp nhận thách đấu sẽ tạo trận đấu chính thức. Bạn có chắc chắn?'
                                  : 'Chấp nhận lời mời sẽ xác nhận tham gia. Bạn có chắc chắn?',
                              style: TextStyle(
                                fontFamily: _getSystemFont(),
                                fontSize: 13,
                                color: const Color(0xFF050505),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Action Buttons (only show if NOT accepted)
                  if (!isAlreadyAccepted)
                    Row(
                      children: [
                        // Decline Button
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextButton(
                              onPressed: _isLoading ? null : _handleDecline,
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Từ chối',
                                style: TextStyle(
                                  fontFamily: _getSystemFont(),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Accept Button
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.isCompetitive
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
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.isCompetitive
                                          ? const Color(0xFFFF9800)
                                          : const Color(0xFF0866FF))
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: _isLoading ? null : _handleAccept,
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Chấp nhận',
                                      style: TextStyle(
                                        fontFamily: _getSystemFont(),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // 🎯 Close button if already accepted
                  if (isAlreadyAccepted)
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0866FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Đóng',
                          style: TextStyle(
                            fontFamily: _getSystemFont(),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: _getSystemFont(),
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF050505),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCED0D4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: _getSystemFont(),
                    fontSize: 12,
                    color: const Color(0xFF65676B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: _getSystemFont(),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF050505),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: _getSystemFont(),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);

    try {
      await ChallengeListService.instance.acceptChallenge(
        widget.challenge['id'],
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAccepted?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Đã chấp nhận ${widget.isCompetitive ? 'thách đấu' : 'lời mời'}!',
              style: TextStyle(fontFamily: _getSystemFont()),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Lỗi: $e',
              style: TextStyle(fontFamily: _getSystemFont()),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDecline() async {
    setState(() => _isLoading = true);

    try {
      await ChallengeListService.instance.declineChallenge(
        widget.challenge['id'],
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onDeclined?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã từ chối ${widget.isCompetitive ? 'thách đấu' : 'lời mời'}',
              style: TextStyle(fontFamily: _getSystemFont()),
            ),
            backgroundColor: const Color(0xFF65676B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Lỗi: $e',
              style: TextStyle(fontFamily: _getSystemFont()),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getSystemFont() {
    try {
      if (Platform.isIOS) {
        return '.SF Pro Display';
      } else {
        return 'Roboto';
      }
    } catch (e) {
      return 'Roboto';
    }
  }
}
