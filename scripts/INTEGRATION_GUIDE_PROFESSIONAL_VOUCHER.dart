// 🎯 INTEGRATION GUIDE: UPDATE FLUTTER APP TO USE PROFESSIONAL VOUCHER SYSTEM
// Replace the old notification-based approach with ClubVoucherManagementService

// 1. UPDATE spa_rewards_page.dart
/* REPLACE THIS OLD CODE:
await Supabase.instance.client
    .from('notifications')
    .insert({
      'recipient_type': 'club',
      'type': 'voucher_usage_request',
      // ... old notification approach
    });
*/

/* WITH THIS NEW PROFESSIONAL CODE:
import '../services/club_voucher_management_service.dart';

final voucherService = ClubVoucherManagementService();

final result = await voucherService.createVoucherRequest(
  voucherId: voucherId,
  voucherCode: voucherCode,
  userId: _userId!,
  userEmail: userEmail,
  userName: userName,
  clubId: _clubId,
  spaValue: spaCost,
);

if (result['success']) {
  if (result['auto_approved']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Voucher đã được tự động phê duyệt!')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Yêu cầu voucher đã được gửi đến club!')),
    );
  }
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Lỗi: ${result['error']}')),
  );
}
*/

// 2. CREATE CLUB VOUCHER MANAGEMENT SCREEN
/* 
lib/pages/club_voucher_management_page.dart:

import 'package:flutter/material.dart';
import '../services/club_voucher_management_service.dart';

class ClubVoucherManagementPage extends StatefulWidget {
  final String clubId;
  
  const ClubVoucherManagementPage({Key? key, required this.clubId}) : super(key: key);
  
  @override
  _ClubVoucherManagementPageState createState() => _ClubVoucherManagementPageState();
}

class _ClubVoucherManagementPageState extends State<ClubVoucherManagementPage> {
  final ClubVoucherManagementService _voucherService = ClubVoucherManagementService();
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }
  
  Future<void> _loadPendingRequests() async {
    setState(() => _loading = true);
    try {
      final requests = await _voucherService.getPendingVoucherRequests(widget.clubId);
      setState(() {
        _pendingRequests = requests;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    }
  }
  
  Future<void> _approveRequest(String requestId) async {
    final result = await _voucherService.approveVoucherRequest(
      requestId: requestId,
      approvedBy: 'current_user_id', // Get from auth
      approvalNotes: 'Approved via app',
    );
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      _loadPendingRequests(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${result['error']}')),
      );
    }
  }
  
  Future<void> _rejectRequest(String requestId, String reason) async {
    final result = await _voucherService.rejectVoucherRequest(
      requestId: requestId,
      rejectedBy: 'current_user_id', // Get from auth
      rejectionReason: reason,
    );
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      _loadPendingRequests(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${result['error']}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý Voucher'),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Không có yêu cầu voucher nào'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = _pendingRequests[index];
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Voucher: ${request['voucher_code']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User: ${request['user_name'] ?? request['user_email']}'),
                            Text('SPA Value: ${request['spa_value']}'),
                            Text('Requested: ${request['requested_at']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveRequest(request['id']),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _showRejectDialog(request['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
  
  void _showRejectDialog(String requestId) {
    String reason = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Từ chối yêu cầu'),
        content: TextField(
          onChanged: (value) => reason = value,
          decoration: InputDecoration(
            labelText: 'Lý do từ chối',
            hintText: 'Nhập lý do...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (reason.isNotEmpty) {
                Navigator.pop(context);
                _rejectRequest(requestId, reason);
              }
            },
            child: Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
*/

// 3. UPDATE NAVIGATION TO INCLUDE CLUB VOUCHER MANAGEMENT
/* Add this to your club dashboard or navigation:

ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ClubVoucherManagementPage(clubId: _clubId),
    ),
  ),
  child: Text('Quản lý Voucher'),
)
*/