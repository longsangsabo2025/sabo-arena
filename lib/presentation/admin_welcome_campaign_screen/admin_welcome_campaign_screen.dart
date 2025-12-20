import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/welcome_voucher_service.dart';

/// Admin screen để quản lý Welcome Voucher Campaigns
class AdminWelcomeCampaignScreen extends StatefulWidget {
  const AdminWelcomeCampaignScreen({Key? key}) : super(key: key);

  @override
  State<AdminWelcomeCampaignScreen> createState() =>
      _AdminWelcomeCampaignScreenState();
}

class _AdminWelcomeCampaignScreenState extends State<AdminWelcomeCampaignScreen>
    with SingleTickerProviderStateMixin {
  final _welcomeVoucherService = WelcomeVoucherService();

  late TabController _tabController;

  List<Map<String, dynamic>> _campaigns = [];
  Map<String, dynamic>? _selectedCampaign;
  List<Map<String, dynamic>> _clubRegistrations = [];
  Map<String, dynamic>? _overallStats;

  bool _isLoading = false;
  String _selectedTab = 'campaigns'; // campaigns, registrations, stats

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = [
          'campaigns',
          'registrations',
          'stats',
        ][_tabController.index];
      });
      _loadData();
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (_selectedTab == 'campaigns') {
        final campaigns = await _welcomeVoucherService.getAllCampaigns();
        setState(() => _campaigns = campaigns);
      } else if (_selectedTab == 'registrations' && _selectedCampaign != null) {
        final registrations = await _welcomeVoucherService
            .getCampaignClubRegistrations(_selectedCampaign!['id']);
        setState(() => _clubRegistrations = registrations);
      } else if (_selectedTab == 'stats') {
        final stats = await _welcomeVoucherService.getOverallStats();
        setState(() => _overallStats = stats);
      }
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
        title: const Text('Welcome Campaigns'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Campaigns', icon: Icon(Icons.campaign)),
            Tab(text: 'Club Registrations', icon: Icon(Icons.store)),
            Tab(text: 'Statistics', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCampaignsTab(),
          _buildRegistrationsTab(),
          _buildStatsTab(),
        ],
      ),
      floatingActionButton: _selectedTab == 'campaigns'
          ? FloatingActionButton.extended(
              onPressed: _showCreateCampaignDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Campaign'),
            )
          : null,
    );
  }

  // ==================== CAMPAIGNS TAB ====================

  Widget _buildCampaignsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No campaigns yet',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showCreateCampaignDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create First Campaign'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _campaigns.length,
        itemBuilder: (context, index) {
          final campaign = _campaigns[index];
          return _buildCampaignCard(campaign);
        },
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final isActive = campaign['is_active'] ?? false;
    final currentRedemptions = campaign['current_redemptions'] ?? 0;
    final maxRedemptions = campaign['max_redemptions'];
    final template = campaign['voucher_template'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _viewCampaignDetails(campaign),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      campaign['name'] ?? 'Unnamed Campaign',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Switch(
                    value: isActive,
                    onChanged: (value) =>
                        _toggleCampaignStatus(campaign['id'], value),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (campaign['description'] != null)
                Text(
                  campaign['description'],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              const SizedBox(height: 12),
              if (template != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          template['name'] ?? 'Voucher Template',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.redeem,
                    label: 'Issued',
                    value:
                        '$currentRedemptions${maxRedemptions != null ? '/$maxRedemptions' : ''}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.store,
                    label: 'Clubs',
                    value: '?',
                    color: Colors.orange,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _viewCampaignDetails(campaign),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
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
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            overflow: TextOverflow.ellipsis,
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

  // ==================== REGISTRATIONS TAB ====================

  Widget _buildRegistrationsTab() {
    if (_selectedCampaign == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select a campaign first',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(0);
              },
              child: const Text('Go to Campaigns'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clubRegistrations.isEmpty) {
      return Center(
        child: Text(
          'No club registrations yet',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _clubRegistrations.length,
        itemBuilder: (context, index) {
          final registration = _clubRegistrations[index];
          return _buildRegistrationCard(registration);
        },
      ),
    );
  }

  Widget _buildRegistrationCard(Map<String, dynamic> registration) {
    final club = registration['club'];
    final status = registration['status'] ?? 'pending';

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
                    club['name'] ?? 'Unknown Club',
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
                        status.toUpperCase(),
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
            if (club['address'] != null)
              Text(
                club['address'],
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            const SizedBox(height: 8),
            Text(
              'Registered: ${_formatDate(registration['registered_at'])}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(registration['id']),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'Reject',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRegistration(registration['id']),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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

  // ==================== STATS TAB ====================

  Widget _buildStatsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_overallStats == null) {
      return const Center(child: Text('No statistics available'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsCard(
            'Total Campaigns',
            '${_overallStats!['total_campaigns'] ?? 0}',
            Icons.campaign,
            Colors.blue,
            subtitle: 'Active: ${_overallStats!['active_campaigns'] ?? 0}',
          ),
          _buildStatsCard(
            'Club Registrations',
            '${_overallStats!['total_club_registrations'] ?? 0}',
            Icons.store,
            Colors.orange,
            subtitle: 'Approved: ${_overallStats!['approved_clubs'] ?? 0}',
          ),
          _buildStatsCard(
            'Vouchers Issued',
            '${_overallStats!['total_vouchers_issued'] ?? 0}',
            Icons.redeem,
            Colors.green,
            subtitle: 'To new users',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _toggleCampaignStatus(String campaignId, bool isActive) async {
    try {
      await _welcomeVoucherService.updateCampaignStatus(campaignId, isActive);
      _showSuccess('Campaign ${isActive ? 'activated' : 'deactivated'}');
      _loadData();
    } catch (e) {
      _showError('Failed to update campaign: $e');
    }
  }

  Future<void> _approveRegistration(String registrationId) async {
    try {
      await _welcomeVoucherService.approveClubRegistration(registrationId);
      _showSuccess('Club registration approved!');
      _loadData();
    } catch (e) {
      _showError('Failed to approve: $e');
    }
  }

  void _showRejectDialog(String registrationId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Registration'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'Nhập lý do từ chối...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                _showError('Please enter a reason');
                return;
              }

              Navigator.pop(context);

              try {
                await _welcomeVoucherService.rejectClubRegistration(
                  registrationId,
                  reasonController.text,
                );
                _showSuccess('Club registration rejected');
                _loadData();
              } catch (e) {
                _showError('Failed to reject: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _viewCampaignDetails(Map<String, dynamic> campaign) {
    setState(() => _selectedCampaign = campaign);
    _tabController.animateTo(1);
    _loadData();
  }

  void _showCreateCampaignDialog() {
    // TODO: Implement create campaign dialog
    _showError('Create campaign feature coming soon');
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }
}
