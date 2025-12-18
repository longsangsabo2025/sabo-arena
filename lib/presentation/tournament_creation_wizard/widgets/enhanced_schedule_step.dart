import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import '../widgets/form_enhancement_widgets.dart';
import '../widgets/venue_autocomplete_field.dart';

class EnhancedScheduleStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;

  const EnhancedScheduleStep({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<EnhancedScheduleStep> createState() => _EnhancedScheduleStepState();
}

class _EnhancedScheduleStepState extends State<EnhancedScheduleStep> {
  final _venueController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  // Form validation
  final Map<String, String> _errors = {};
  final Map<String, String> _warnings = {};
  final Map<String, String> _successes = {};

  @override
  void initState() {
    super.initState();
    _initializeFromData();
  }

  @override
  void didUpdateWidget(EnhancedScheduleStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      // Only update if controllers are empty (don't overwrite user input)
      if (_venueController.text.isEmpty && widget.data['venue'] != null) {
        _venueController.text = widget.data['venue'];
      }
      if (_contactNameController.text.isEmpty && widget.data['venueContact'] != null) {
        _contactNameController.text = widget.data['venueContact'];
      }
      if (_contactPhoneController.text.isEmpty && widget.data['venuePhone'] != null) {
        _contactPhoneController.text = widget.data['venuePhone'];
      }
    }
  }

  @override
  void dispose() {
    _venueController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _initializeFromData() {
    _venueController.text = widget.data['venue'] ?? '';
    _contactNameController.text = widget.data['venueContact'] ?? '';
    _contactPhoneController.text = widget.data['venuePhone'] ?? '';
  }

  void _validateAndUpdate() {
    _errors.clear();
    _warnings.clear();
    _successes.clear();

    final venue = _venueController.text.trim();
    final contactName = _contactNameController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();
    final regStartDate = widget.data['registrationStartDate'] as DateTime?;
    final regEndDate = widget.data['registrationEndDate'] as DateTime?;
    final tournamentStartDate = widget.data['tournamentStartDate'] as DateTime?;
    final tournamentEndDate = widget.data['tournamentEndDate'] as DateTime?;

    // Venue validation
    if (venue.isEmpty) {
      _errors['Địa điểm'] = 'Bắt buộc phải có địa điểm tổ chức';
    } else if (venue.length < 5) {
      _warnings['Địa điểm'] = 'Nên có thông tin địa điểm chi tiết hơn';
    } else {
      _successes['Địa điểm'] = 'Địa điểm hợp lệ';
    }

    // Contact validation (Optional but recommended)
    if (contactPhone.isNotEmpty && contactPhone.length < 10) {
      _warnings['Liên hệ'] = 'Số điện thoại có vẻ không đúng';
    }

    // Date validation
    final now = DateTime.now();

    if (regStartDate == null) {
      _errors['Ngày mở đăng ký'] = 'Cần chọn ngày mở đăng ký';
    } else if (regStartDate.isBefore(now)) {
      _warnings['Ngày mở đăng ký'] = 'Ngày mở đăng ký đã qua';
    } else {
      _successes['Đăng ký'] = 'Thời gian đăng ký hợp lệ';
    }

    if (regEndDate == null) {
      _errors['Ngày đóng đăng ký'] = 'Cần chọn ngày đóng đăng ký';
    } else if (regStartDate != null && regEndDate.isBefore(regStartDate)) {
      _errors['Ngày đóng đăng ký'] = 'Phải sau ngày mở đăng ký';
    }

    if (tournamentStartDate == null) {
      _errors['Ngày bắt đầu'] = 'Cần chọn ngày bắt đầu giải đấu';
    } else if (regEndDate != null && tournamentStartDate.isBefore(regEndDate)) {
      _warnings['Ngày bắt đầu'] =
          'Nên để thời gian chuẩn bị sau khi đóng đăng ký';
    } else {
      _successes['Lịch trình'] = 'Lịch trình hợp lý';
    }

    if (tournamentEndDate != null && tournamentStartDate != null) {
      if (tournamentEndDate.isBefore(tournamentStartDate)) {
        _errors['Ngày kết thúc'] = 'Phải sau ngày bắt đầu';
      }
    }

    // Update data
    widget.onDataChanged({
      'venue': venue,
      'venueContact': contactName,
      'venuePhone': contactPhone,
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Validation feedback
          ValidationFeedbackWidget(
            errors: _errors,
            warnings: _warnings,
            successes: _successes,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Thời gian & Địa điểm',
                    style: TextStyle(
                      fontSize: 24.h,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Thiết lập lịch trình và địa điểm tổ chức giải đấu',
                    style: TextStyle(
                      fontSize: 16.h,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Registration period
                  _buildRegistrationPeriod(),

                  SizedBox(height: 24.h),

                  // Tournament period
                  _buildTournamentPeriod(),

                  SizedBox(height: 24.h),

                  // Venue with autocomplete
                  VenueAutocompleteField(
                    value: _venueController.text,
                    isValid:
                        !_errors.containsKey('Địa điểm') &&
                        _venueController.text.length >= 5,
                    errorText: _errors['Địa điểm'],
                    onChanged: (value) {
                      _venueController.text = value;
                      _validateAndUpdate();
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Contact Info
                  Text(
                    'Thông tin liên hệ (Tại địa điểm)',
                    style: TextStyle(
                      fontSize: 16.h,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: EnhancedFormField(
                          label: 'Người liên hệ',
                          controller: _contactNameController,
                          prefixIcon: Icons.person_outline,
                          onChanged: (_) => _validateAndUpdate(),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: EnhancedFormField(
                          label: 'Số điện thoại',
                          controller: _contactPhoneController,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => _validateAndUpdate(),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Schedule summary
                  _buildScheduleSummary(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationPeriod() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.app_registration,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 12.w),
              Text(
                'Thời gian đăng ký',
                style: TextStyle(fontSize: 18.h, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildDateTimePicker(
                  label: 'Mở đăng ký',
                  value: widget.data['registrationStartDate'] as DateTime?,
                  onChanged: (date) {
                    widget.onDataChanged({'registrationStartDate': date});
                    _validateAndUpdate();
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildDateTimePicker(
                  label: 'Đóng đăng ký',
                  value: widget.data['registrationEndDate'] as DateTime?,
                  onChanged: (date) {
                    widget.onDataChanged({'registrationEndDate': date});
                    _validateAndUpdate();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentPeriod() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber),
              SizedBox(width: 12.w),
              Text(
                'Thời gian thi đấu',
                style: TextStyle(fontSize: 18.h, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildDateTimePicker(
                  label: 'Bắt đầu',
                  value: widget.data['tournamentStartDate'] as DateTime?,
                  onChanged: (date) {
                    widget.onDataChanged({'tournamentStartDate': date});
                    _validateAndUpdate();
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildDateTimePicker(
                  label: 'Kết thúc (dự kiến)',
                  value: widget.data['tournamentEndDate'] as DateTime?,
                  onChanged: (date) {
                    widget.onDataChanged({'tournamentEndDate': date});
                    _validateAndUpdate();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime) onChanged,
  }) {
    return GestureDetector(
      onTap: () => _selectDateTime(onChanged, value),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.h,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              value != null ? _formatDateTime(value) : 'Chọn ngày giờ',
              style: TextStyle(
                fontSize: 14.h,
                color: value != null ? Colors.black : Colors.grey.shade500,
                fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSummary() {
    final regStart = widget.data['registrationStartDate'] as DateTime?;
    final regEnd = widget.data['registrationEndDate'] as DateTime?;
    final tournamentStart = widget.data['tournamentStartDate'] as DateTime?;
    final tournamentEnd = widget.data['tournamentEndDate'] as DateTime?;

    if (regStart == null || tournamentStart == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Theme.of(context).primaryColor),
              SizedBox(width: 8.w),
              Text(
                'Tóm tắt lịch trình',
                style: TextStyle(
                  fontSize: 16.h,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildTimelineItem(
            icon: Icons.app_registration,
            title: 'Mở đăng ký',
            time: _formatDateTime(regStart),
            color: Colors.green,
          ),
          if (regEnd != null) ...[
            SizedBox(height: 8.h),
            _buildTimelineItem(
              icon: Icons.close,
              title: 'Đóng đăng ký',
              time: _formatDateTime(regEnd),
              color: Colors.orange,
            ),
          ],
          SizedBox(height: 8.h),
          _buildTimelineItem(
            icon: Icons.play_arrow,
            title: 'Bắt đầu thi đấu',
            time: _formatDateTime(tournamentStart),
            color: Colors.blue,
          ),
          if (tournamentEnd != null) ...[
            SizedBox(height: 8.h),
            _buildTimelineItem(
              icon: Icons.emoji_events,
              title: 'Dự kiến kết thúc',
              time: _formatDateTime(tournamentEnd),
              color: Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.white, size: 16.w),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14.h, fontWeight: FontWeight.w600),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 12.h, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime(
    Function(DateTime) onChanged,
    DateTime? currentValue,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (!mounted) return;

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onChanged(dateTime);
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekday = weekdays[dateTime.weekday % 7];

    return '$weekday, ${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
