import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/tournament.dart';

class RegistrationWidget extends StatefulWidget {
  final Tournament tournament;
  final bool isRegistered;
  final VoidCallback? onRegisterTap;
  final Function(String paymentMethod)? onRegisterWithPayment; // NEW: direct payment callback
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
    final canRegister =
        !isDeadlinePassed &&
        widget.tournament.currentParticipants < widget.tournament.maxParticipants;

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
                    widget.tournament.skillLevelRequired ?? 'Tất cả trình độ',
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
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE4E6EB),
          disabledBackgroundColor: const Color(0xFFE4E6EB),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Hết hạn đăng ký',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF65676B),
          ),
        ),
      );
    }

    if (widget.isRegistered) {
      return OutlinedButton(
        onPressed: widget.onWithdrawTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE41E3F), width: 1.5),
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, color: Color(0xFFE41E3F), size: 20),
            SizedBox(width: 8),
            Text(
              'Đã đăng ký - Rút lui',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE41E3F),
              ),
            ),
          ],
        ),
      );
    }

    if (!canRegister) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE4E6EB),
          disabledBackgroundColor: const Color(0xFFE4E6EB),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Đã đầy',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF65676B),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: widget.onRegisterTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0866FF),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.how_to_reg, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'Đăng ký ngay',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }


}
