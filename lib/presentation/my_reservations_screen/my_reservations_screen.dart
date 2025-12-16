import 'package:flutter/material.dart';
import 'package:sabo_arena/models/table_reservation.dart';
import 'package:sabo_arena/services/table_reservation_service.dart';
import 'package:sabo_arena/services/supabase_service.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'package:sizer/sizer.dart';

/// My Reservations Screen
/// Shows user's table reservations with different tabs
class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({Key? key}) : super(key: key);

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  final _reservationService = TableReservationService.instance;
  late TabController _tabController;

  List<TableReservation> _allReservations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = SupabaseService.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final reservations = await _reservationService.getUserReservations(
        currentUser.id,
      );

      setState(() {
        _allReservations = reservations;
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

  List<TableReservation> get _upcomingReservations {
    return _allReservations
        .where(
          (r) =>
              r.status == ReservationStatus.confirmed ||
              r.status == ReservationStatus.pending,
        )
        .where((r) => r.startTime.isAfter(DateTime.now()))
        .toList();
  }

  List<TableReservation> get _completedReservations {
    return _allReservations
        .where(
          (r) =>
              r.status == ReservationStatus.completed ||
              (r.endTime.isBefore(DateTime.now()) &&
                  r.status == ReservationStatus.confirmed),
        )
        .toList();
  }

  List<TableReservation> get _cancelledReservations {
    return _allReservations
        .where(
          (r) =>
              r.status == ReservationStatus.cancelled ||
              r.status == ReservationStatus.noShow,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Đặt Bàn'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Sắp Tới',
              icon: Badge(
                label: Text('${_upcomingReservations.length}'),
                child: const Icon(Icons.schedule),
              ),
            ),
            Tab(
              text: 'Hoàn Thành',
              icon: Badge(
                label: Text('${_completedReservations.length}'),
                child: const Icon(Icons.check_circle_outline),
              ),
            ),
            Tab(
              text: 'Đã Hủy',
              icon: Badge(
                label: Text('${_cancelledReservations.length}'),
                child: const Icon(Icons.cancel_outlined),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: DSSpinner.primary())
          : RefreshIndicator(
              onRefresh: _loadReservations,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReservationList(_upcomingReservations, 'upcoming'),
                  _buildReservationList(_completedReservations, 'completed'),
                  _buildReservationList(_cancelledReservations, 'cancelled'),
                ],
              ),
            ),
    );
  }

  Widget _buildReservationList(
    List<TableReservation> reservations,
    String type,
  ) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'upcoming'
                  ? Icons.event_busy
                  : type == 'completed'
                  ? Icons.history
                  : Icons.cancel,
              size: 80,
              color: AppColors.gray400,
            ),
            SizedBox(height: DesignTokens.space16),
            Text(
              type == 'upcoming'
                  ? 'Chưa có lịch đặt bàn'
                  : type == 'completed'
                  ? 'Chưa có lịch sử'
                  : 'Không có đặt bàn bị hủy',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(DesignTokens.space12),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return _buildReservationCard(reservation, type);
      },
    );
  }

  Widget _buildReservationCard(TableReservation reservation, String type) {
    final club = reservation.club;

    return Card(
      margin: EdgeInsets.only(bottom: DesignTokens.space16),
      child: InkWell(
        onTap: () => _showReservationDetails(reservation),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(reservation.status),
                      borderRadius: BorderRadius.circular(1.w),
                    ),
                    child: Text(
                      '${reservation.status.icon} ${reservation.statusDisplay}',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    reservation.dateDisplay,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Divider(height: DesignTokens.space16),

              // Club Info
              if (club != null) ...[
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                      child: club.profileImageUrl != null
                          ? Image.network(
                              club.profileImageUrl!,
                              width: 12.w,
                              height: 12.w,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildDefaultImage(),
                            )
                          : _buildDefaultImage(),
                    ),
                    SizedBox(width: DesignTokens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            club.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: DesignTokens.space4),
                          Text(
                            club.address ?? 'Chưa có địa chỉ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.space8),
              ],

              // Reservation Details
              _buildInfoRow(
                Icons.access_time,
                'Giờ',
                reservation.timeRangeDisplay,
              ),
              _buildInfoRow(
                Icons.sports_bar,
                'Bàn số',
                '${reservation.tableNumber}',
              ),
              _buildInfoRow(
                Icons.attach_money,
                'Tổng tiền',
                reservation.priceDisplay,
              ),
              _buildInfoRow(
                Icons.payment,
                'Thanh toán',
                reservation.paymentStatusDisplay,
              ),

              // Action Buttons
              if (type == 'upcoming' && reservation.canCancel) ...[
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCancelDialog(reservation),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Hủy Đặt Bàn'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                    if (club != null && club.phone != null) ...[
                      SizedBox(width: 2.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callClub(club.phone!),
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Gọi Club'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: 12.w,
      height: 12.w,
      color: AppColors.gray300,
      child: Icon(Icons.sports_bar, size: 20, color: AppColors.gray500),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.space8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          SizedBox(width: DesignTokens.space8),
          Text(
            '$label: ',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppColors.warning;
      case ReservationStatus.confirmed:
        return AppColors.success;
      case ReservationStatus.cancelled:
        return AppColors.error;
      case ReservationStatus.completed:
        return AppColors.info;
      case ReservationStatus.noShow:
        return AppColors.gray500;
    }
  }

  void _showReservationDetails(TableReservation reservation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 12.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Chi Tiết Đặt Bàn',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),

                // Full details here
                _buildDetailRow('Mã đặt bàn', reservation.id.substring(0, 8)),
                _buildDetailRow('Trạng thái', reservation.statusDisplay),
                _buildDetailRow('Ngày', reservation.dateDisplay),
                _buildDetailRow('Giờ', reservation.timeRangeDisplay),
                _buildDetailRow('Bàn số', '${reservation.tableNumber}'),
                _buildDetailRow(
                  'Thời gian chơi',
                  '${reservation.durationHours}h',
                ),
                _buildDetailRow(
                  'Giá/giờ',
                  '${reservation.pricePerHour.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ',
                ),
                _buildDetailRow('Tổng tiền', reservation.priceDisplay),
                _buildDetailRow('Thanh toán', reservation.paymentStatusDisplay),

                if (reservation.notes != null) ...[
                  SizedBox(height: 1.h),
                  Text(
                    'Ghi chú:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    reservation.notes!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],

                if (reservation.cancellationReason != null) ...[
                  SizedBox(height: 1.h),
                  Text(
                    'Lý do hủy:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    reservation.cancellationReason!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],

                SizedBox(height: 3.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
          ),
          Text(
            value, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(TableReservation reservation) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy Đặt Bàn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn có chắc muốn hủy đặt bàn này?'),
            SizedBox(height: 2.h),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelReservation(
                reservation.id,
                reasonController.text.trim().isEmpty
                    ? 'Hủy bởi khách hàng'
                    : reasonController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hủy Đặt Bàn'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelReservation(String reservationId, String reason) async {
    try {
      final currentUser = SupabaseService.instance.client.auth.currentUser;
      if (currentUser == null) return;

      await _reservationService.cancelReservation(
        reservationId,
        currentUser.id,
        reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Đã hủy đặt bàn'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _callClub(String phone) {
    // Implement phone call functionality
    // You can use url_launcher package for this
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Gọi: $phone')));
  }
}
