import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sabo_arena/core/device/device_info.dart';
import 'package:sabo_arena/models/table_reservation.dart';
import 'package:sabo_arena/models/reservation_models.dart';
import 'package:sabo_arena/models/club.dart';
import 'package:sabo_arena/services/table_reservation_service.dart';
import 'package:sabo_arena/services/supabase_service.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Club Reservation Management Screen
/// For club owners to manage table bookings
class ClubReservationManagementScreen extends StatefulWidget {
  final Club club;

  const ClubReservationManagementScreen({Key? key, required this.club})
    : super(key: key);

  @override
  State<ClubReservationManagementScreen> createState() =>
      _ClubReservationManagementScreenState();
}

class _ClubReservationManagementScreenState
    extends State<ClubReservationManagementScreen> {
  final _reservationService = TableReservationService.instance;

  List<TableReservation> _reservations = [];
  ReservationStats _stats = ReservationStats.empty();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToRealtime() {
    _channel = _reservationService.subscribeToClubReservations(
      clubId: widget.club.id,
      onInsert: (reservation) {
        if (mounted) {
          setState(() {
            _reservations.insert(0, reservation);
          });
          _showNotification('Có đặt bàn mới!');
        }
      },
      onUpdate: (reservation) {
        if (mounted) {
          setState(() {
            final index = _reservations.indexWhere(
              (r) => r.id == reservation.id,
            );
            if (index != -1) {
              _reservations[index] = reservation;
            }
          });
        }
      },
      onDelete: (id) {
        if (mounted) {
          setState(() {
            _reservations.removeWhere((r) => r.id == id);
          });
        }
      },
    );
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load reservations for selected date
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final reservations = await _reservationService.getClubReservations(
        clubId: widget.club.id,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // Load stats for current month
      final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endOfMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        0,
      );

      final stats = await _reservationService.getClubStats(
        clubId: widget.club.id,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      setState(() {
        _reservations = reservations;
        _stats = stats;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Đặt Bàn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
          ),
        ],
      ),
      body: _buildResponsiveBody(),
    );
  }

  Widget _buildResponsiveBody() {
    final isIPad = DeviceInfo.isIPad(context);
    final maxWidth = isIPad ? 1000.0 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsOverview(),
                      SizedBox(height: 2.h),
                      _buildDateSelector(),
                      SizedBox(height: 2.h),
                      _buildQuickActions(),
                      SizedBox(height: 2.h),
                      _buildReservationsList(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Thống Kê Tháng ${_selectedDate.month}', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                _buildStatCard(
                  'Tổng Đặt Bàn',
                  '${_stats.totalReservations}',
                  Icons.event,
                  Colors.blue,
                ),
                SizedBox(width: 2.w),
                _buildStatCard(
                  'Chờ Xác Nhận',
                  '${_stats.pendingReservations}',
                  Icons.pending,
                  Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                _buildStatCard(
                  'Doanh Thu',
                  _stats.totalRevenueDisplay,
                  Icons.attach_money,
                  Colors.green,
                ),
                SizedBox(width: 2.w),
                _buildStatCard(
                  'Dự Kiến',
                  _stats.expectedRevenueDisplay,
                  Icons.trending_up,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(2.w),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    label, style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              value, style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(
                    const Duration(days: 1),
                  );
                });
                _loadData();
              },
            ),
            Text(
              DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate),
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final todayReservations = _reservations.length;
    final pendingCount = _reservations
        .where((r) => r.status == ReservationStatus.pending)
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Hôm Nay',
            '$todayReservations lượt',
            Icons.today,
            Colors.blue,
            () {},
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildActionButton(
            'Chờ Duyệt',
            '$pendingCount',
            Icons.notifications_active,
            Colors.orange,
            () => _filterPending(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2.w),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              SizedBox(height: 1.h),
              Text(
                title, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle, style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationsList() {
    if (_reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.h),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
              SizedBox(height: 2.h),
              Text(
                'Không có đặt bàn nào', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 Danh Sách Đặt Bàn', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reservations.length,
          itemBuilder: (context, index) {
            return _buildReservationCard(_reservations[index]);
          },
        ),
      ],
    );
  }

  Widget _buildReservationCard(TableReservation reservation) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: InkWell(
        onTap: () => _showReservationActions(reservation),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              // Time
              Container(
                width: 16.w,
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _getStatusColor(reservation.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Column(
                  children: [
                    Text(
                      reservation.startTime.hour.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(reservation.status),
                      ),
                    ),
                    Text(
                      reservation.startTime.minute.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _getStatusColor(reservation.status),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Bàn ${reservation.tableNumber}', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(reservation.status),
                            borderRadius: BorderRadius.circular(1.w),
                          ),
                          child: Text(
                            reservation.statusDisplay, style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${reservation.durationHours}h • ${reservation.priceDisplay}', overflow: TextOverflow.ellipsis, style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      reservation.paymentStatusDisplay, style: TextStyle(
                        fontSize: 10.sp,
                        color:
                            reservation.paymentStatus == PaymentStatus.fullyPaid
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              if (reservation.status == ReservationStatus.pending)
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.green;
      case ReservationStatus.cancelled:
        return Colors.red;
      case ReservationStatus.completed:
        return Colors.blue;
      case ReservationStatus.noShow:
        return Colors.grey;
    }
  }

  void _showReservationActions(TableReservation reservation) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bàn ${reservation.tableNumber} - ${reservation.timeRangeDisplay}', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            if (reservation.status == ReservationStatus.pending) ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Xác Nhận'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmReservation(reservation);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Từ Chối'),
                onTap: () {
                  Navigator.pop(context);
                  _rejectReservation(reservation);
                },
              ),
            ],
            if (reservation.status == ReservationStatus.confirmed) ...[
              ListTile(
                leading: const Icon(Icons.done_all, color: Colors.blue),
                title: const Text('Hoàn Thành'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsCompleted(reservation);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_off, color: Colors.grey),
                title: const Text('Không Đến'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsNoShow(reservation);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Xem Chi Tiết'),
              onTap: () {
                Navigator.pop(context);
                // Show details dialog
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReservation(TableReservation reservation) async {
    try {
      final currentUser = SupabaseService.instance.client.auth.currentUser;
      if (currentUser == null) return;

      await _reservationService.confirmReservation(
        reservation.id,
        currentUser.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xác nhận đặt bàn'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectReservation(TableReservation reservation) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ Chối Đặt Bàn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập lý do từ chối:'),
            SizedBox(height: 1.h),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ Chối'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final currentUser = SupabaseService.instance.client.auth.currentUser;
      if (currentUser == null) return;

      await _reservationService.rejectReservation(
        reservation.id,
        currentUser.id,
        reasonController.text.trim().isEmpty
            ? 'Từ chối bởi club'
            : reasonController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã từ chối đặt bàn'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAsCompleted(TableReservation reservation) async {
    try {
      await _reservationService.markAsCompleted(reservation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã đánh dấu hoàn thành'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAsNoShow(TableReservation reservation) async {
    try {
      await _reservationService.markAsNoShow(reservation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Đã đánh dấu không đến'),
            backgroundColor: Colors.grey,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterPending() {
    // Filter to show only pending reservations
    setState(() {
      _reservations = _reservations
          .where((r) => r.status == ReservationStatus.pending)
          .toList();
    });
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }
}
