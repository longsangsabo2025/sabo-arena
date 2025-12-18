import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'package:sabo_arena/models/table_reservation.dart';
import 'package:sabo_arena/services/table_reservation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reservation Management Screen for Club Owners
/// Allows owners to view and manage all table reservations
class ReservationManagementScreen extends StatefulWidget {
  final String clubId;

  const ReservationManagementScreen({Key? key, required this.clubId})
    : super(key: key);

  @override
  State<ReservationManagementScreen> createState() =>
      _ReservationManagementScreenState();
}

class _ReservationManagementScreenState
    extends State<ReservationManagementScreen>
    with SingleTickerProviderStateMixin {
  final _reservationService = TableReservationService.instance;
  late TabController _tabController;

  List<TableReservation> _pendingReservations = [];
  List<TableReservation> _confirmedReservations = [];
  List<TableReservation> _completedReservations = [];
  List<TableReservation> _cancelledReservations = [];
  // List<dynamic> _allReservations = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reservations = await _reservationService.getClubReservations(
        clubId: widget.clubId,
      );

      setState(() {
        // _allReservations = reservations;
        _pendingReservations = reservations
            .where((r) => r.status == ReservationStatus.pending)
            .toList();
        _confirmedReservations = reservations
            .where((r) => r.status == ReservationStatus.confirmed)
            .toList();
        _completedReservations = reservations
            .where((r) => r.status == ReservationStatus.completed)
            .toList();
        _cancelledReservations = reservations
            .where((r) => r.status == ReservationStatus.cancelled)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateReservationStatus(
    String reservationId,
    String newStatus,
  ) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

      if (newStatus == 'confirmed') {
        await _reservationService.confirmReservation(
          reservationId,
          currentUserId,
        );
      } else if (newStatus == 'cancelled') {
        await _reservationService.cancelReservation(
          reservationId,
          currentUserId,
          'Hủy bởi quản trị viên',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật trạng thái thành công'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadReservations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quản lý đặt bàn', overflow: TextOverflow.ellipsis, style: AppTypography.headingMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: '.SF Pro Display',
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadReservations,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Chờ duyệt (${_pendingReservations.length})'),
            Tab(text: 'Đã xác nhận (${_confirmedReservations.length})'),
            Tab(text: 'Hoàn thành (${_completedReservations.length})'),
            Tab(text: 'Đã hủy (${_cancelledReservations.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  SizedBox(height: 16),
                  Text(_errorMessage!, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium),
                  SizedBox(height: 16),
                  DSButton(text: 'Thử lại', onPressed: _loadReservations),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReservationList(_pendingReservations, 'pending'),
                _buildReservationList(_confirmedReservations, 'confirmed'),
                _buildReservationList(_completedReservations, 'completed'),
                _buildReservationList(_cancelledReservations, 'cancelled'),
              ],
            ),
    );
  }

  Widget _buildReservationList(
    List<TableReservation> reservations,
    String statusFilter,
  ) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_seat_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              'Không có đặt bàn nào', overflow: TextOverflow.ellipsis, style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontFamily: '.SF Pro Display',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: reservations.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return _buildReservationCard(reservation, statusFilter);
      },
    );
  }

  Widget _buildReservationCard(
    TableReservation reservation,
    String statusFilter,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    Color statusColor;
    IconData statusIcon;

    switch (reservation.status) {
      case ReservationStatus.pending:
        statusColor = AppColors.warning;
        statusIcon = Icons.pending;
        break;
      case ReservationStatus.confirmed:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case ReservationStatus.completed:
        statusColor = AppColors.info;
        statusIcon = Icons.done_all;
        break;
      case ReservationStatus.cancelled:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status & Table number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      reservation.status.displayName, style: AppTypography.labelMedium.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Bàn ${reservation.tableNumber}', overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),
            Divider(height: 1),
            SizedBox(height: 12),

            // User info
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8),
                Text(
                  reservation.user?.fullName ?? 'N/A', overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium.copyWith(
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Date & Time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8),
                Text(
                  '${dateFormat.format(reservation.startTime)} - ${DateFormat('HH:mm').format(reservation.endTime)}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Price
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8),
                Text(
                  '${reservation.totalPrice.toStringAsFixed(0)} VNĐ',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),

            if (reservation.notes != null && reservation.notes!.isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reservation.notes!, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons for pending reservations
            if (statusFilter == 'pending') ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DSButton(
                      text: 'Xác nhận',
                      onPressed: () =>
                          _updateReservationStatus(reservation.id, 'confirmed'),
                      variant: DSButtonVariant.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: DSButton(
                      text: 'Từ chối',
                      onPressed: () =>
                          _updateReservationStatus(reservation.id, 'cancelled'),
                      variant: DSButtonVariant.tertiary,
                    ),
                  ),
                ],
              ),
            ],

            // Mark as completed button for confirmed reservations
            if (statusFilter == 'confirmed') ...[
              SizedBox(height: 16),
              DSButton(
                text: 'Đánh dấu hoàn thành',
                onPressed: () =>
                    _updateReservationStatus(reservation.id, 'completed'),
                variant: DSButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

}
