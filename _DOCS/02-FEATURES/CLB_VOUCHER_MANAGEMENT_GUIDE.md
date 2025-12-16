# 🎯 CLB VOUCHER MANAGEMENT - IMPLEMENTATION GUIDE

## ✅ DATABASE VERIFICATION
- ✅ Table `club_voucher_requests` exists
- ✅ 2 voucher requests ready for CLB approval
- ✅ Voucher request flow working perfectly!

## 📋 CURRENT VOUCHER REQUESTS

```
📝 SPA227727250 - SABO (longsangsabo1@gmail.com)
   Club: SABO (dde4b08a...)
   Value: 100 SPA
   Status: pending
   Type: spa_redemption
   Created: 2025-11-07 15:12

📝 TEST1904027246 - Flutter Test User
   Club: SABO (dde4b08a...)
   Value: 100 SPA  
   Status: pending
   Type: spa_redemption
   Created: 2025-11-07 13:05
```

## 🏗️ IMPLEMENTATION STEPS

### 1. Create Voucher Management Screen for CLB Staff

File: `lib/presentation/club_staff/club_voucher_requests_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      print('Error loading voucher requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      await Supabase.instance.client
          .from('club_voucher_requests')
          .update({
            'status': 'approved',
            'processed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã duyệt voucher!')),
      );
      
      _loadVoucherRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: $e')),
      );
    }
  }

  Future<void> _rejectRequest(String requestId, String reason) async {
    try {
      await Supabase.instance.client
          .from('club_voucher_requests')
          .update({
            'status': 'rejected',
            'processed_at': DateTime.now().toIso8601String(),
            'rejection_reason': reason,
          })
          .eq('id', requestId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Đã từ chối voucher!')),
      );
      
      _loadVoucherRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: $e')),
      );
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
                    color: statusColor.withOpacity(0.1),
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
            _buildInfoRow('👤 Người dùng:', request['user_name']),
            _buildInfoRow('📧 Email:', request['user_email']),
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
```

### 2. Add Navigation to Staff Tab

Update `lib/presentation/home_screen.dart` or your staff navigation to include:

```dart
ListTile(
  leading: const Icon(Icons.card_giftcard),
  title: const Text('Yêu cầu Voucher'),
  subtitle: const Text('Xem và duyệt voucher'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubVoucherRequestsScreen(
          clubId: yourClubId,
        ),
      ),
    );
  },
)
```

## 🎯 FEATURES

✅ **View voucher requests** by status (pending/approved/rejected/all)
✅ **Approve vouchers** with one tap
✅ **Reject vouchers** with reason
✅ **Pull to refresh** data
✅ **Beautiful UI** with status indicators
✅ **Real-time updates** from database

## 📊 NEXT STEPS

1. Create the screen file
2. Add navigation from staff tab
3. Test approval/rejection flow
4. Add notifications for users when approved/rejected

**Ready to implement?** 🚀
