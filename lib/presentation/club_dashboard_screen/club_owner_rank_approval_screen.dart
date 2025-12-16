import 'package:flutter/material.dart';
import '../../services/admin_rank_approval_service.dart';
import '../../services/club_permission_service.dart';
import '../../core/utils/rank_migration_helper.dart';

class ClubOwnerRankApprovalScreen extends StatefulWidget {
  final String clubId;

  const ClubOwnerRankApprovalScreen({super.key, required this.clubId});

  @override
  State<ClubOwnerRankApprovalScreen> createState() =>
      _ClubOwnerRankApprovalScreenState();
}

class _ClubOwnerRankApprovalScreenState
    extends State<ClubOwnerRankApprovalScreen> with SingleTickerProviderStateMixin {
  final AdminRankApprovalService _approvalService = AdminRankApprovalService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _approvedRequests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load pending requests
      final pending = await _approvalService.getPendingRankRequests();
      
      // Load approved/rejected requests
      final approved = await _approvalService.getApprovedRankRequests();

      setState(() {
        _pendingRequests = pending;
        _approvedRequests = approved;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRequestReview(
    String requestId,
    bool approved, {
    String? comments,
  }) async {
    try {
      // 🔐 PERMISSION CHECK: Verify user can verify rank
      final canVerify = await ClubPermissionService().canPerformAction(
        clubId: widget.clubId,
        permissionKey: 'verify_rank',
      );
      
      if (!canVerify) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Bạn không có quyền xác thực hạng'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await _approvalService.approveRankRequest(
        requestId: requestId,
        approved: approved,
        comments: comments,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved ? 'Đã chấp thuận yêu cầu' : 'Đã từ chối yêu cầu',
            ),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
        _loadAllRequests(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${result['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Duyệt yêu cầu hạng', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Đợi duyệt',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Đã duyệt',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildApprovedTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return _buildBody(_pendingRequests, isPending: true);
  }

  Widget _buildApprovedTab() {
    return _buildBody(_approvedRequests, isPending: false);
  }

  Widget _buildBody(List<Map<String, dynamic>> requests, {required bool isPending}) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang tải yêu cầu...', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAllRequests,
              child: Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              isPending ? 'Không có yêu cầu nào' : 'Chưa có lịch sử duyệt', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              isPending 
                ? 'Hiện tại không có yêu cầu duyệt hạng nào cần xử lý'
                : 'Lịch sử các yêu cầu đã duyệt sẽ hiển thị tại đây',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request, isPending: isPending);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, {required bool isPending}) {
    final userName = request['users']?['display_name'] ?? 'Unknown User';
    final userEmail = request['users']?['email'] ?? '';
    final currentRank = request['users']?['rank'] ?? '';
    final requestedRank = _extractRequestedRank(request['notes'] ?? '');
    final reason = request['notes'] ?? '';
    final requestedAt =
        DateTime.tryParse(request['requested_at'] ?? '') ?? DateTime.now();
    final status = request['status'] ?? 'pending';
    final reviewedAt = request['reviewed_at'] != null 
        ? DateTime.tryParse(request['reviewed_at']) 
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              userName, style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (!isPending) _buildStatusBadge(status),
                        ],
                      ),
                      if (userEmail.isNotEmpty)
                        Text(
                          userEmail, style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        isPending 
                          ? 'Gửi lúc: ${_formatDate(requestedAt)}'
                          : 'Duyệt lúc: ${reviewedAt != null ? _formatDate(reviewedAt) : "N/A"}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Rank change info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildRankBadge(currentRank),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  _buildRankBadge(requestedRank, isRequested: true),
                ],
              ),
            ),

            if (reason.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Lý do yêu cầu:', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                reason, style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],

            // Only show action buttons for pending requests
            if (isPending) ...[
              SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(request['id']),
                      icon: Icon(Icons.close, size: 18),
                      label: Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleRequestReview(request['id'], true),
                      icon: Icon(Icons.check, size: 18),
                      label: Text('Chấp thuận'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(String rank, {bool isRequested = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRequested
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRequested ? Colors.green : Colors.blue,
          width: 1,
        ),
      ),
      child: Text(
        RankMigrationHelper.getNewDisplayName(rank),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isRequested ? Colors.green : Colors.blue,
          fontSize: 12,
        ),
      ),
    );
  }

  String _extractRequestedRank(String notes) {
    final rankMatch = RegExp(r'Rank mong muốn: ([A-Z+]+)').firstMatch(notes);
    return rankMatch?.group(1) ?? 'Unknown';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showRejectDialog(String requestId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Từ chối yêu cầu', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vui lòng cho biết lý do từ chối:'),
            SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleRequestReview(
                requestId,
                false,
                comments: reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        label = 'Đã duyệt';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        label = 'Từ chối';
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = 'Đợi duyệt';
        icon = Icons.pending;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
