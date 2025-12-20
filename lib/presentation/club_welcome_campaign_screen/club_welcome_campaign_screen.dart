import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/welcome_voucher_service.dart';

/// Club Owner screen để đăng ký tham gia Welcome Campaign
class ClubWelcomeCampaignScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const ClubWelcomeCampaignScreen({
    Key? key,
    required this.clubId,
    required this.clubName,
  }) : super(key: key);

  @override
  State<ClubWelcomeCampaignScreen> createState() =>
      _ClubWelcomeCampaignScreenState();
}

class _ClubWelcomeCampaignScreenState extends State<ClubWelcomeCampaignScreen> {
  final _welcomeVoucherService = WelcomeVoucherService();

  List<Map<String, dynamic>> _availableCampaigns = [];
  List<Map<String, dynamic>> _myRegistrations = [];

  bool _isLoading = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final available = await _welcomeVoucherService.getAvailableCampaigns();
      final registrations = await _welcomeVoucherService
          .getClubCampaignRegistrations(widget.clubId);

      setState(() {
        _availableCampaigns = available;
        _myRegistrations = registrations;
      });
    } catch (e) {
      _showError('Lỗi tải dữ liệu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chiến Dịch Chào Mừng'),
            Text(
              widget.clubName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildAvailableTab()
                : _buildMyRegistrationsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'Khả Dụng',
              0,
              Icons.campaign,
              _availableCampaigns.length,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Đăng Ký Của Tôi',
              1,
              Icons.how_to_reg,
              _myRegistrations.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon, int count) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isSelected ? Theme.of(context).primaryColor : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== AVAILABLE CAMPAIGNS TAB ====================

  Widget _buildAvailableTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableCampaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có chiến dịch nào đang hoạt động',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng quay lại sau để xem các chiến dịch mới',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableCampaigns.length,
        itemBuilder: (context, index) {
          final campaign = _availableCampaigns[index];
          return _buildCampaignCard(campaign);
        },
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final template = campaign['voucher_template'];
    final isRegistered = _myRegistrations.any(
      (r) => r['campaign_id'] == campaign['id'],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.campaign, color: Colors.blue[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign['name'] ?? 'Chiến dịch chưa đặt tên',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (campaign['description'] != null)
                        Text(
                          campaign['description'],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // Voucher info
            if (template != null) ...[
              Row(
                children: [
                  Icon(Icons.card_giftcard, size: 20, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiết Voucher',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template['name'] ?? 'Voucher Chào Mừng',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (template['description'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            template['description'],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Campaign stats
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.calendar_today,
                  label: 'Bắt đầu',
                  value: _formatDate(campaign['start_date']),
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                if (campaign['max_redemptions'] != null)
                  _buildInfoChip(
                    icon: Icons.people,
                    label: 'Giới hạn',
                    value:
                        '${campaign['current_redemptions']}/${campaign['max_redemptions']}',
                    color: Colors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Register button
            SizedBox(
              width: double.infinity,
              child: isRegistered
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Đã Đăng Ký'),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _registerForCampaign(campaign),
                      icon: const Icon(Icons.how_to_reg),
                      label: const Text('Đăng Ký CLB'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MY REGISTRATIONS TAB ====================

  Widget _buildMyRegistrationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myRegistrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có đăng ký nào',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng ký tham gia chiến dịch ở tab Khả Dụng',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myRegistrations.length,
        itemBuilder: (context, index) {
          final registration = _myRegistrations[index];
          return _buildRegistrationCard(registration);
        },
      ),
    );
  }

  Widget _buildRegistrationCard(Map<String, dynamic> registration) {
    final campaign = registration['campaign'];
    final status = registration['status'] ?? 'pending';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Đã Duyệt';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Từ Chối';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Chờ Duyệt';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    campaign['name'] ?? 'Chiến Dịch',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Đã đăng ký: ${_formatDate(registration['registered_at'])}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            if (status == 'approved' &&
                registration['approved_at'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Đã duyệt: ${_formatDate(registration['approved_at'])}',
                style: TextStyle(color: Colors.green[700], fontSize: 14),
              ),
            ],
            if (status == 'rejected' &&
                registration['rejection_reason'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        registration['rejection_reason'],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.red[900], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _registerForCampaign(Map<String, dynamic> campaign) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng Ký Tham Gia Chiến Dịch'),
        content: Text(
          'Bạn có muốn đăng ký ${widget.clubName} tham gia "${campaign['name']}" không?\n\n'
          'Đăng ký của bạn sẽ được gửi đến admin để phê duyệt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng Ký'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Register
    try {
      await _welcomeVoucherService.registerClubForCampaign(
        campaignId: campaign['id'],
        clubId: widget.clubId,
      );

      _showSuccess('Đã gửi đăng ký! Đang chờ admin phê duyệt.');
      _loadData();
    } catch (e) {
      _showError('Đăng ký thất bại: $e');
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }
}
