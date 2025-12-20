import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../services/challenge_service.dart';

class ScheduleMatchModal extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const ScheduleMatchModal({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  State<ScheduleMatchModal> createState() => _ScheduleMatchModalState();
}

class _ScheduleMatchModalState extends State<ScheduleMatchModal> {
  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  TimeOfDay? customStartTime;
  TimeOfDay? customEndTime;
  bool isCustomTime = false;
  bool isSubmitting = false;

  final List<String> timeSlots = [
    '09:00 - 11:00',
    '14:00 - 16:00',
    '19:00 - 21:00',
    '20:00 - 22:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hẹn lịch với ${widget.targetUserName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Chọn thời gian phù hợp để chơi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date Selection
          const Text(
            'Chọn ngày:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDateOption(
                  context,
                  DateTime.now(),
                  'Hôm nay',
                  'Chơi ngay trong ngày',
                  selectedDate,
                  (date) => setState(() => selectedDate = date),
                ),
                const Divider(height: 1),
                _buildDateOption(
                  context,
                  DateTime.now().add(const Duration(days: 1)),
                  'Ngày mai',
                  _formatDate(DateTime.now().add(const Duration(days: 1))),
                  selectedDate,
                  (date) => setState(() => selectedDate = date),
                ),
                const Divider(height: 1),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.blue,
                              onPrimary: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setState(() => selectedDate = pickedDate);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Chọn ngày khác...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Time Selection
          const Text(
            'Khung giờ:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: timeSlots.map((slot) {
              final isSelected = selectedTimeSlot == slot;
              return InkWell(
                onTap: () {
                  setState(() {
                    selectedTimeSlot = slot;
                    isCustomTime = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      color: isSelected ? Colors.blue[700] : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Hủy',
                  type: AppButtonType.outline,
                  fullWidth: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: isSubmitting ? 'Đang gửi...' : 'Xác nhận',
                  fullWidth: true,
                  onPressed: (selectedTimeSlot != null && !isSubmitting)
                      ? _handleSubmit
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => isSubmitting = true);
    try {
      final challengeService = ChallengeService.instance;

      await challengeService.sendScheduleRequest(
        targetUserId: widget.targetUserId,
        scheduledDate: selectedDate,
        timeSlot: selectedTimeSlot!,
        message: 'Lời mời hẹn lịch chơi bida từ ứng dụng SABO ARENA',
      );

      if (mounted) {
        Navigator.pop(context);
        final dateStr = _isToday(selectedDate)
            ? 'hôm nay'
            : _isTomorrow(selectedDate)
                ? 'ngày mai'
                : _formatDate(selectedDate);

        AppSnackbar.success(
          context: context,
          message:
              'Đã gửi lời mời hẹn lịch đến ${widget.targetUserName} - $dateStr, $selectedTimeSlot thành công! 📅',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => isSubmitting = false);
        AppSnackbar.error(
          context: context,
          message: 'Lỗi: ${error.toString().replaceAll('Exception: ', '')}',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Widget _buildDateOption(
    BuildContext context,
    DateTime date,
    String title,
    String subtitle,
    DateTime selectedDate,
    Function(DateTime) onSelect,
  ) {
    final isSelected = _isSameDay(date, selectedDate);

    return InkWell(
      onTap: () => onSelect(date),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: isSelected ? Colors.blue.withValues(alpha: 0.05) : null,
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.blue[800] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.blue[600] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _isSameDay(date, tomorrow);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
