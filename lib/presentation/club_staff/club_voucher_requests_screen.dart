import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class ClubVoucherRequestsScreen extends StatefulWidget {
  final String clubId;
  
  const ClubVoucherRequestsScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<ClubVoucherRequestsScreen> createState() => _ClubVoucherRequestsScreenState();
}

class _ClubVoucherRequestsScreenState extends State<ClubVoucherRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _filter = 'pending'; // pending, approved, rejected, all

  @override
  void initState() {
    super.initState();
    _loadVoucherRequests();
  }

  Future<void> _loadVoucherRequests() async {
    setState(() => _isLoading = true);
    
    try {
      var query = Supabase.instance.client
          .from('club_voucher_requests')
          .select('*')
          .eq('club_id', widget.clubId);
      
      if (_filter != 'all') {
        query = query.eq('status', _filter);
      }
      
      final data = await query.order('created_at', ascending: false);
      
      setState(() {
        _requests = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      // Get request details first to find voucher_code
      final request = await Supabase.instance.client
          .from('club_voucher_requests')
          .select('voucher_code')
          .eq('id', requestId)
          .single();
      
      final voucherCode = request['voucher_code'];
      
      // Update both tables in transaction-like manner
      // 1. Update club_voucher_requests
      await Supabase.instance.client
          .from('club_voucher_requests')
          .update({
            'status': 'approved',
            'processed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
      
      // 2. Update user_vouchers to mark as used (approved by staff)
      await Supabase.instance.client
          .from('user_vouchers')
          .update({
            'status': 'used', // Mark as 'used' when staff approves
          })
          .eq('voucher_code', voucherCode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã duyệt voucher!')),
        );
      }
      
      _loadVoucherRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId, String reason) async {
    try {
      // Get request details first to find voucher_code
      final request = await Supabase.instance.client
          .from('club_voucher_requests')
          .select('voucher_code')
          .eq('id', requestId)
          .single();
      
      final voucherCode = request['voucher_code'];
      
      // Update both tables
      // 1. Update club_voucher_requests
      await Supabase.instance.client
          .from('club_voucher_requests')
          .update({
            'status': 'rejected',
            'processed_at': DateTime.now().toIso8601String(),
            'rejection_reason': reason,
          })
          .eq('id', requestId);
      
      // 2. Update user_vouchers to mark as cancelled
      await Supabase.instance.client
          .from('user_vouchers')
          .update({
            'status': 'cancelled', // Mark as 'cancelled' when staff rejects
          })
          .eq('voucher_code', voucherCode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Đã từ chối voucher!')),
        );
      }
      
      _loadVoucherRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu sử dụng Voucher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVoucherRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Chờ duyệt', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã duyệt', 'approved'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Từ chối', 'rejected'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Tất cả', 'all'),
                ],
              ),
            ),
          ),
          
          // Request list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? Center(
                        child: Text(
                          'Không có yêu cầu ${_getFilterLabel()}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadVoucherRequests,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(_requests[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
        _loadVoucherRequests();
      },
    );
  }

  String _getFilterLabel() {
    switch (_filter) {
      case 'pending': return 'chờ duyệt';
      case 'approved': return 'đã duyệt';
      case 'rejected': return 'bị từ chối';
      default: return '';
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'];
    final isPending = status == 'pending';
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request['voucher_code'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // User info
            _buildInfoRow('👤 Người dùng:', request['user_name'] ?? 'N/A'),
            _buildInfoRow('📧 Email:', request['user_email'] ?? 'N/A'),
            _buildInfoRow('💰 Giá trị:', '${request['spa_value']} SPA'),
            _buildInfoRow('📅 Thời gian:', _formatDate(request['created_at'])),
            
            if (request['processed_at'] != null)
              _buildInfoRow('✅ Xử lý lúc:', _formatDate(request['processed_at'])),
            
            if (request['rejection_reason'] != null)
              _buildInfoRow('❌ Lý do:', request['rejection_reason']),
            
            // Actions
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(request['id']),
                      icon: const Icon(Icons.check),
                      label: const Text('Duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRejectDialog(request['id']),
                      icon: const Icon(Icons.close),
                      label: const Text('Từ chối'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Chờ duyệt';
      case 'approved': return 'Đã duyệt';
      case 'rejected': return 'Từ chối';
      default: return status;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showRejectDialog(String requestId) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối',
            hintText: 'Nhập lý do...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectRequest(requestId, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}

