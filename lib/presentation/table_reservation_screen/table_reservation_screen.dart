import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sabo_arena/core/design_system/responsive_grid.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'package:sabo_arena/models/club.dart';
import 'package:sabo_arena/models/reservation_models.dart';
import 'package:sabo_arena/services/table_reservation_service.dart';
import 'package:sabo_arena/services/supabase_service.dart';
import 'package:sizer/sizer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX
import '../../widgets/common/app_button.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;

/// Table Reservation Booking Screen
/// Allows users to book a table at a club
class TableReservationScreen extends StatefulWidget {
  final Club club;

  const TableReservationScreen({Key? key, required this.club})
      : super(key: key);

  @override
  State<TableReservationScreen> createState() => _TableReservationScreenState();
}

class _TableReservationScreenState extends State<TableReservationScreen> {
  final _reservationService = TableReservationService.instance;
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay(hour: 18, minute: 0);
  TimeSlotOption? _selectedTimeSlot;
  final double _selectedDuration = 2.0;
  int? _selectedTable;
  final String _paymentMethod = 'counter'; // 'counter' or 'deposit'

  List<AvailableSlot> _availableSlots = [];
  bool _isLoading = false;
  bool _isBooking = false;
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoading = true);

    try {
      final slots = await _reservationService.getAvailableSlots(
        clubId: widget.club.id,
        date: _selectedDate,
        durationHours: _selectedDuration,
      );

      setState(() {
        _availableSlots = slots;
        // ✅ KHÔNG reset _selectedTimeSlot nữa, giữ lại user selection
        // Only reset table when slots change
        _selectedTable = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _bookTable() async {
    if (_selectedTimeSlot == null || _selectedTable == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn giờ và bàn')));
      return;
    }

    setState(() => _isBooking = true);

    try {
      final currentUser = SupabaseService.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Vui lòng đăng nhập để đặt bàn');
      }

      final startTime = _selectedTimeSlot!.startTime;
      final endTime = _selectedTimeSlot!.endTime;
      final totalPrice = widget.club.pricePerHour! * _selectedDuration;
      final depositAmount =
          _paymentMethod == 'deposit' ? totalPrice * 0.3 : 0.0;

      final request = ReservationRequest(
        clubId: widget.club.id,
        userId: currentUser.id,
        tableNumber: _selectedTable!,
        startTime: startTime,
        endTime: endTime,
        durationHours: _selectedDuration,
        pricePerHour: widget.club.pricePerHour!,
        totalPrice: totalPrice,
        depositAmount: depositAmount,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text
            : null,
        numberOfPlayers: 2,
      );

      await _reservationService.createReservation(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Đặt bàn thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Đặt bàn thất bại: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: DesignTokens.elevation1,
        shadowColor: AppColors.shadow,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đặt Bàn',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: DSSpinner(size: DSSpinnerSize.medium))
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 1.h),
                  _buildClubInfo(),
                  SizedBox(height: 1.h),
                  _buildTimePickerSelector(),
                  SizedBox(height: 2.h),
                  _buildDateSelector(),
                  SizedBox(height: 3.h),
                  _buildTableSelector(),
                  SizedBox(height: 3.h),
                  _buildPriceInfo(),
                  SizedBox(height: 3.h),
                  _buildNotesInput(),
                  SizedBox(height: 4.h),
                  _buildBookButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildClubInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Club Image
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            child: Container(
              width: 60,
              height: 60,
              color: AppColors.gray100,
              child: widget.club.profileImageUrl != null
                  ? Image.network(
                      widget.club.profileImageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.business,
                          size: 28,
                          color: AppColors.gray400),
                    )
                  : Icon(Icons.business, size: 28, color: AppColors.gray400),
            ),
          ),
          SizedBox(width: 3.w),
          // Club Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.club.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.club.address ?? 'Chưa có địa chỉ',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.club.priceDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            picker.DatePicker.showTimePicker(
              context,
              showTitleActions: true,
              onConfirm: (time) {
                setState(() {
                  _selectedTime = TimeOfDay(
                    hour: time.hour,
                    minute: time.minute,
                  );
                  // Update time slot based on selected time
                  final selectedDateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    time.hour,
                    time.minute,
                  );
                  // Auto-create time slot
                  _selectedTimeSlot = TimeSlotOption(
                    startTime: selectedDateTime,
                    durationHours: _selectedDuration,
                  );
                });
                _loadAvailableSlots();
              },
              currentTime: DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              ),
              locale: picker.LocaleType.vi,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn Giờ',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.gray400, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _showCalendar = !_showCalendar;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chọn Ngày',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat(
                              'EEEE, dd/MM/yyyy',
                              'vi',
                            ).format(_selectedDate),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _showCalendar ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.gray400,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Calendar
          if (_showCalendar) ...[
            Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _showCalendar = false;
                  });
                  _loadAvailableSlots();
                },
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: AppColors.textPrimary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: AppColors.textPrimary,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: TextStyle(color: AppColors.error),
                  outsideDaysVisible: false,
                  cellMargin: const EdgeInsets.all(4),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  weekendStyle: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableSelector() {
    if (_selectedTimeSlot == null) {
      return const SizedBox.shrink();
    }

    // 🔍 Tìm slot tương ứng với time đã chọn
    AvailableSlot? selectedSlot;
    try {
      selectedSlot = _availableSlots.firstWhere(
        (slot) => slot.startTime == _selectedTimeSlot!.startTime,
      );
    } catch (e) {
      // Không tìm thấy slot → không hiện selector
      ProductionLogger.info(
          '⚠️ Không tìm thấy slot cho ${_selectedTimeSlot!.startTime}',
          tag: 'table_reservation_screen');
      ProductionLogger.info(
          '📋 Available slots: ${_availableSlots.map((s) => s.startTime).toList()}',
          tag: 'table_reservation_screen');
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.table_bar,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Chọn Bàn',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            items: List.generate(widget.club.totalTables, (index) => index + 1),
            itemBuilder: (context, tableNum, index) {
              final isAvailable = selectedSlot!.availableTables.contains(
                tableNum,
              );
              final isSelected = _selectedTable == tableNum;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isAvailable
                      ? () => setState(() => _selectedTable = tableNum)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !isAvailable
                          ? AppColors.gray100
                          : isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isAvailable
                            ? AppColors.gray300
                            : isSelected
                                ? AppColors.primary
                                : AppColors.gray300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$tableNum',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: !isAvailable
                                ? AppColors.gray400
                                : isSelected
                                    ? AppColors.textOnPrimary
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAvailable ? 'Trống' : 'Đã đặt',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: !isAvailable
                                ? AppColors.gray400
                                : isSelected
                                    ? AppColors.textOnPrimary
                                        .withValues(alpha: 0.7)
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            spacing: 10,
            runSpacing: 10,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo() {
    if (_selectedTimeSlot == null || _selectedTable == null) {
      return const SizedBox.shrink();
    }

    final totalPrice = widget.club.pricePerHour! * _selectedDuration;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giá/giờ:',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Text(
                widget.club.priceDisplay,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thời gian:',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Text(
                '${_selectedDuration}h',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tiền:',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '${totalPrice.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesInput() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_note,
                    color: AppColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Ghi Chú (Tùy chọn)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Yêu cầu đặc biệt hoặc ghi chú...',
              hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.only(bottom: 2.h),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: AppButton(
          label: 'Đặt bàn',
          type: AppButtonType.primary,
          size: AppButtonSize.large,
          isLoading: _isBooking,
          fullWidth: true,
          onPressed: _isBooking ? null : _bookTable,
        ),
      ),
    );
  }
}
