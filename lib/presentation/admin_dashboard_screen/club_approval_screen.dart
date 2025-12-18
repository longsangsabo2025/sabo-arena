import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/admin_service.dart';
import '../../models/club.dart';
import '../../widgets/custom_app_bar.dart';
// ELON_MODE_AUTO_FIX

class ClubApprovalScreen extends StatefulWidget {
  final String? initialFilter;

  const ClubApprovalScreen({super.key, this.initialFilter});

  @override
  State<ClubApprovalScreen> createState() => _ClubApprovalScreenState();
}

class _ClubApprovalScreenState extends State<ClubApprovalScreen>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService.instance;

  late TabController _tabController;
  List<Club> _pendingClubs = [];
  List<Club> _approvedClubs = [];
  List<Club> _rejectedClubs = [];

  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set initial tab based on filter
    if (widget.initialFilter == 'pending') {
      _tabController.index = 0;
    } else if (widget.initialFilter == 'approved') {
      _tabController.index = 1;
    } else if (widget.initialFilter == 'rejected') {
      _tabController.index = 2;
    }

    _loadClubs();

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadClubs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });


      // Load each status separately to identify which one fails
      List<Club> pendingClubs = [];
      List<Club> approvedClubs = [];
      List<Club> rejectedClubs = [];

      try {
        pendingClubs = await _adminService.getClubsForAdmin(status: 'pending');
      } catch (e) {
        throw Exception('Failed to load pending clubs: $e');
      }

      try {
        approvedClubs = await _adminService.getClubsForAdmin(
          status: 'approved',
        );
      } catch (e) {
        throw Exception('Failed to load approved clubs: $e');
      }

      try {
        rejectedClubs = await _adminService.getClubsForAdmin(
          status: 'rejected',
        );
      } catch (e) {
        throw Exception('Failed to load rejected clubs: $e');
      }

      setState(() {
        _pendingClubs = pendingClubs;
        _approvedClubs = approvedClubs;
        _rejectedClubs = rejectedClubs;
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi tải danh sách CLB: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: "Quản lý CLB",
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textPrimaryLight),
            onPressed: _loadClubs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.errorLight),
          SizedBox(height: 16),
          Text(
            _errorMessage!, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _loadClubs, child: Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Container(
          color: AppTheme.backgroundLight,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryLight,
            unselectedLabelColor: AppTheme.textSecondaryLight,
            indicatorColor: AppTheme.primaryLight,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pending_actions, size: 18),
                    SizedBox(width: 8),
                    Text('Chờ duyệt'),
                    if (_pendingClubs.isNotEmpty) ...[
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _pendingClubs.length.toString(),
                          style: TextStyle(
                            color: AppTheme.onPrimaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 18),
                    SizedBox(width: 8),
                    Text('Đã duyệt'),
                    if (_approvedClubs.isNotEmpty) ...[
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _approvedClubs.length.toString(),
                          style: TextStyle(
                            color: AppTheme.onPrimaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel, size: 18),
                    SizedBox(width: 8),
                    Text('Từ chối'),
                    if (_rejectedClubs.isNotEmpty) ...[
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _rejectedClubs.length.toString(),
                          style: TextStyle(
                            color: AppTheme.onPrimaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildClubList(_pendingClubs, 'pending'),
              _buildClubList(_approvedClubs, 'approved'),
              _buildClubList(_rejectedClubs, 'rejected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClubList(List<Club> clubs, String status) {
    if (clubs.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadClubs,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: clubs.length,
        itemBuilder: (context, index) {
          return _buildClubCard(clubs[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'pending':
        message = 'Không có CLB nào chờ duyệt';
        icon = Icons.pending_actions;
        break;
      case 'approved':
        message = 'Chưa có CLB nào được duyệt';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        message = 'Chưa có CLB nào bị từ chối';
        icon = Icons.cancel;
        break;
      default:
        message = 'Không có dữ liệu';
        icon = Icons.inbox;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textDisabledLight),
          SizedBox(height: 16),
          Text(
            message, style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard(Club club) {
    Color statusColor = AppTheme.textDisabledLight;
    IconData statusIcon = Icons.info;
    String statusText = club.approvalStatus;

    switch (club.approvalStatus) {
      case 'pending':
        statusColor = AppTheme.warningLight;
        statusIcon = Icons.pending;
        statusText = 'Chờ duyệt';
        break;
      case 'approved':
        statusColor = AppTheme.successLight;
        statusIcon = Icons.check_circle;
        statusText = 'Đã duyệt';
        break;
      case 'rejected':
        statusColor = AppTheme.errorLight;
        statusIcon = Icons.cancel;
        statusText = 'Từ chối';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with club image and status
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              image: club.coverImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(club.coverImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: club.coverImageUrl == null ? Color(0xFFEEEEEE) : null,
            ),
            child: Stack(
              children: [
                if (club.coverImageUrl == null)
                  Center(
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: AppTheme.textDisabledLight,
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: AppTheme.onPrimaryLight,
                        ),
                        SizedBox(width: 4),
                        Text(
                          statusText, style: TextStyle(
                            color: AppTheme.onPrimaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Club info
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (club.address != null) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppTheme.textSecondaryLight,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          club.address!, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondaryLight),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 8),

                // Club details
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.table_bar,
                      text: '${club.totalTables} bàn',
                    ),
                    SizedBox(width: 8),
                    if (club.pricePerHour != null)
                      _buildInfoChip(
                        icon: Icons.monetization_on,
                        text: '${club.pricePerHour!.toInt()}k/h',
                      ),
                  ],
                ),

                if (club.description != null) ...[
                  SizedBox(height: 12),
                  Text(
                    club.description!, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                    ),
                    maxLines: 2,
                  ),
                ],

                if (club.rejectionReason != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.errorLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: AppTheme.errorLight,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lý do từ chối: ${club.rejectionReason}', overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.errorLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 16),

                // Action buttons
                if (club.approvalStatus == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(club),
                          icon: Icon(Icons.cancel, size: 18),
                          label: Text('Từ chối'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorLight,
                            side: BorderSide(color: AppTheme.errorLight),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveClub(club),
                          icon: Icon(Icons.check_circle, size: 18),
                          label: Text('Duyệt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successLight,
                            foregroundColor: AppTheme.onPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _showClubDetails(club),
                    icon: Icon(Icons.visibility, size: 18),
                    label: Text('Xem chi tiết'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.textSecondaryLight,
                      foregroundColor: AppTheme.onPrimaryLight,
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryLight),
          SizedBox(width: 4),
          Text(
            text, style: TextStyle(
              color: AppTheme.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveClub(Club club) async {
    try {
      await _adminService.approveClub(club.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã duyệt CLB "${club.name}" thành công'),
            backgroundColor: AppTheme.successLight,
          ),
        );
      }

      await _loadClubs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi duyệt CLB: $e'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    }
  }

  void _showRejectDialog(Club club) {
    String rejectionReason = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Từ chối CLB "${club.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vui lòng nhập lý do từ chối:'),
            SizedBox(height: 16),
            TextField(
              onChanged: (value) => rejectionReason = value,
              decoration: InputDecoration(
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: rejectionReason.trim().isEmpty
                ? null
                : () {
                    Navigator.pop(context);
                    _rejectClub(club, rejectionReason.trim());
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorLight,
            ),
            child: Text(
              'Từ chối', overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.onPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectClub(Club club, String reason) async {
    try {
      await _adminService.rejectClub(club.id, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã từ chối CLB "${club.name}"'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }

      await _loadClubs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi từ chối CLB: $e'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    }
  }

  void _showClubDetails(Club club) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(club.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (club.description != null) ...[
                Text('Mô tả:', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(club.description!),
                SizedBox(height: 16),
              ],
              if (club.address != null) ...[
                Text('Địa chỉ:', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(club.address!),
                SizedBox(height: 16),
              ],
              if (club.phone != null) ...[
                Text(
                  'Điện thoại:', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(club.phone!),
                SizedBox(height: 16),
              ],
              if (club.email != null) ...[
                Text('Email:', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(club.email!),
                SizedBox(height: 16),
              ],
              Text('Số bàn:', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(club.totalTables.toString()),
              if (club.pricePerHour != null) ...[
                SizedBox(height: 16),
                Text('Giá/giờ:', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${club.pricePerHour!.toInt()},000 VNĐ'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

