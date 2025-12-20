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
    extends State<ClubOwnerRankApprovalScreen>
    with SingleTickerProviderStateMixin {
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

      if (!mounted) return;

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
            content: Text('Lỗi: ${result['error'] ?? 'Lỗi không xác định'}'),
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
          'Duyệt yêu cầu hạng',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildBody(List<Map<String, dynamic>> requests,
      {required bool isPending}) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang tải yêu cầu...',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
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
              'Có lỗi xảy ra',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
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
              isPending ? 'Không có yêu cầu nào' : 'Chưa có lịch sử duyệt',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
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
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
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

  Widget _buildRequestCard(Map<String, dynamic> request,
      {required bool isPending}) {
    final userData = request['users'] ?? {};
    final userName = userData['display_name'] ??
        userData['email']?.split('@')[0] ??
        'Người dùng';
    final userEmail = userData['email'] ?? '';
    final avatarUrl = userData['avatar_url'];
    final currentRank = userData['rank'] ?? 'N/A';
    final requestedRank = _extractRequestedRank(request['notes'] ?? '');
    final reason = request['notes'] ?? '';
    final requestedAt =
        DateTime.tryParse(request['requested_at'] ?? '') ?? DateTime.now();
    final status = request['status'] ?? 'pending';

    // Elon Audit: Don't show arrow if no change
    final isRankChange = currentRank != requestedRank;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // More rounded, modern
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03), // Subtler shadow
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20), // More breathing room
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info header - Simplified
            Row(
              children: [
                CircleAvatar(
                  radius: 24, // Slightly larger
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage:
                      avatarUrl != null && avatarUrl.toString().isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                  child: avatarUrl == null || avatarUrl.toString().isEmpty
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        )
                      : null,
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
                              userName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!isPending) _buildStatusBadge(status),
                          if (isPending)
                            Text(
                              _formatDate(requestedAt),
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                        ],
                      ),
                      if (userEmail.isNotEmpty)
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Rank change info - The Core Value
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRankBadge(currentRank, label: "Hiện tại"),
                  if (isRankChange) ...[
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.grey.shade400, size: 20),
                    _buildRankBadge(requestedRank,
                        isRequested: true, label: "Đề xuất"),
                  ] else
                    Text("Không thay đổi hạng",
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            if (reason.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: reason
                      .replaceAll(RegExp(r'Rank mong muốn:.*?\n'), '')
                      .trim()
                      .split('\n')
                      .map<Widget>((line) {
                    if (line.contains(':')) {
                      final parts = line.split(':');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${parts[0].trim()}: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                parts.sublist(1).join(':').trim(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Text(
                      line,
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Only show action buttons for pending requests
            if (isPending) ...[
              SizedBox(height: 20),

              // Action buttons - High Contrast
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _showRejectDialog(request['id']),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Từ chối',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2, // Approve is the primary action
                    child: ElevatedButton(
                      onPressed: () =>
                          _handleRequestReview(request['id'], true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Musk Black
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Chấp thuận',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildRankBadge(String rank,
      {bool isRequested = false, String? label}) {
    final rankCode = RankMigrationHelper.getRankCodeFromName(rank) ?? rank;
    final displayName = RankMigrationHelper.getNewDisplayName(rank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(label.toUpperCase(),
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isRequested
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isRequested
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isRequested
                      ? Colors.green.shade700
                      : Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
              if (rankCode.isNotEmpty && rankCode != 'N/A') ...[
                SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: (isRequested ? Colors.green : Colors.grey)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Rank $rankCode',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isRequested
                          ? Colors.green.shade800
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
          'Từ chối yêu cầu',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold),
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
