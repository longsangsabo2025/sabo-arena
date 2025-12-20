import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/tournament.dart';
import '../../../widgets/common/app_button.dart';

class RegistrationWidget extends StatefulWidget {
  final Tournament tournament;
  final bool isRegistered;
  final VoidCallback? onRegisterTap;
  final Function(String paymentMethod)?
      onRegisterWithPayment; // NEW: direct payment callback
  final VoidCallback? onWithdrawTap;

  const RegistrationWidget({
    super.key,
    required this.tournament,
    required this.isRegistered,
    this.onRegisterTap,
    this.onRegisterWithPayment, // NEW
    this.onWithdrawTap,
  });

  @override
  State<RegistrationWidget> createState() => _RegistrationWidgetState();
}

class _RegistrationWidgetState extends State<RegistrationWidget> {
  @override
  Widget build(BuildContext context) {
    final registrationDeadline = widget.tournament.registrationDeadline;
    final isDeadlinePassed = DateTime.now().isAfter(registrationDeadline);
    final canRegister = !isDeadlinePassed &&
        widget.tournament.currentParticipants <
            widget.tournament.maxParticipants;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with time remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0866FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.how_to_reg,
                        size: 20,
                        color: Color(0xFF0866FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF050505),
                      ),
                    ),
                  ],
                ),
                if (!isDeadlinePassed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0866FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Color(0xFF0866FF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getCompactTimeRemaining(registrationDeadline),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0866FF),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Compact requirements - 2 columns
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    Icons.calendar_today,
                    DateFormat('dd/MM/yyyy').format(registrationDeadline),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactInfo(
                    Icons.people,
                    '${widget.tournament.currentParticipants}/${widget.tournament.maxParticipants} người',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    Icons.payment,
                    widget.tournament.entryFee == 0
                        ? 'Miễn phí'
                        : '${NumberFormat("#,###").format(widget.tournament.entryFee)} VND',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactInfo(
                    Icons.military_tech,
                    _getSkillLevelDisplay(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: _buildActionButton(context, canRegister, isDeadlinePassed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF65676B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF050505),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getCompactTimeRemaining(DateTime deadline) {
    try {
      final now = DateTime.now();
      final difference = deadline.difference(now);

      if (difference.inDays > 0) {
        return 'Còn ${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return 'Còn ${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return 'Còn ${difference.inMinutes}m';
      } else {
        return 'Sắp hết hạn';
      }
    } catch (e) {
      return 'Kiểm tra';
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    bool canRegister,
    bool isDeadlinePassed,
  ) {
    if (isDeadlinePassed) {
      return AppButton(
        label: 'Hết hạn đăng ký',
        type: AppButtonType.primary,
        size: AppButtonSize.medium,
        customColor: const Color(0xFFE4E6EB),
        customTextColor: const Color(0xFF65676B),
        fullWidth: true,
        onPressed: null,
      );
    }

    if (widget.isRegistered) {
      return AppButton(
        label: 'Đã đăng ký - Rút lui',
        type: AppButtonType.outline,
        size: AppButtonSize.medium,
        icon: Icons.check_circle,
        iconTrailing: false,
        customColor: const Color(0xFFE41E3F),
        customTextColor: const Color(0xFFE41E3F),
        fullWidth: true,
        onPressed: widget.onWithdrawTap,
      );
    }

    if (!canRegister) {
      return AppButton(
        label: 'Đã đầy',
        type: AppButtonType.primary,
        size: AppButtonSize.medium,
        customColor: const Color(0xFFE4E6EB),
        customTextColor: const Color(0xFF65676B),
        fullWidth: true,
        onPressed: null,
      );
    }

    return AppButton(
      label: 'Đăng ký tham gia',
      type: AppButtonType.primary,
      size: AppButtonSize.medium,
      icon: Icons.person_add,
      iconTrailing: false,
      customColor: const Color(0xFF1E8A6F), // Brand teal green
      customTextColor: Colors.white,
      fullWidth: true,
      onPressed: widget.onRegisterTap,
    );
  }

  /// Get formatted skill level display from tournament rank restrictions
  String _getSkillLevelDisplay() {
    if (widget.tournament.minRank != null &&
        widget.tournament.maxRank != null) {
      if (widget.tournament.minRank == widget.tournament.maxRank) {
        return 'Hạng ${widget.tournament.minRank}';
      }
      return 'Hạng ${widget.tournament.minRank} - ${widget.tournament.maxRank}';
    }
    if (widget.tournament.minRank != null) {
      return 'Hạng ${widget.tournament.minRank} trở lên';
    }
    if (widget.tournament.maxRank != null) {
      return 'Hạng ${widget.tournament.maxRank} trở xuống';
    }
    // Fallback to skillLevelRequired or default
    return widget.tournament.skillLevelRequired ?? 'Tất cả trình độ';
  }
}
