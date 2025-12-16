import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../models/voucher_campaign.dart';
import '../../services/admin_service.dart';
import './widgets/admin_scaffold_wrapper.dart';
import '../../core/design_system/design_system.dart';
import '../../widgets/empty_state_widget.dart';

class AdminVoucherCampaignApprovalScreen extends StatefulWidget {
  const AdminVoucherCampaignApprovalScreen({super.key});

  @override
  State<AdminVoucherCampaignApprovalScreen> createState() =>
      _AdminVoucherCampaignApprovalScreenState();
}

class _AdminVoucherCampaignApprovalScreenState
    extends State<AdminVoucherCampaignApprovalScreen> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService.instance;
  late TabController _tabController;
  
  List<VoucherCampaign> _pendingCampaigns = [];
  List<VoucherCampaign> _approvedCampaigns = [];
  List<VoucherCampaign> _rejectedCampaigns = [];
  
  bool _isLoading = true;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final results = await Future.wait([
        _adminService.getVoucherCampaigns(status: 'pending'),
        _adminService.getVoucherCampaigns(status: 'approved'),
        _adminService.getVoucherCampaigns(status: 'rejected'),
        _adminService.getVoucherCampaignStats(),
      ]);

      setState(() {
        _pendingCampaigns = results[0] as List<VoucherCampaign>;
        _approvedCampaigns = results[1] as List<VoucherCampaign>;
        _rejectedCampaigns = results[2] as List<VoucherCampaign>;
        _stats = results[3] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _approveCampaign(VoucherCampaign campaign) async {
    final notes = await _showNotesDialog(
      title: 'Phê duyệt Campaign',
      hint: 'Ghi chú cho club owner (tùy chọn)...',
    );
    
    if (notes == null) return; // User cancelled

    try {
      await _adminService.approveVoucherCampaign(campaign.id, adminNotes: notes.isEmpty ? null : notes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('✅ Đã phê duyệt!'), backgroundColor: AppColors.success),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectCampaign(VoucherCampaign campaign) async {
    final reason = await _showNotesDialog(
      title: 'Từ chối Campaign',
      hint: 'Lý do từ chối (bắt buộc)...',
      required: true,
    );
    
    if (reason == null || reason.isEmpty) return;

    try {
      await _adminService.rejectVoucherCampaign(campaign.id, reason: reason);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('❌ Đã từ chối!'), backgroundColor: AppColors.warning),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<String?> _showNotesDialog({
    required String title,
    required String hint,
    bool required = false,
  }) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (required && controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do')),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffoldWrapper(
      title: 'Phê Duyệt Voucher',
      currentIndex: 4,
      onBottomNavTap: (index) => Navigator.pop(context),
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: EdgeInsets.all(DesignTokens.space12),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Chờ duyệt', _stats['pending'] ?? 0, AppColors.warning)),
                SizedBox(width: DesignTokens.space8),
                Expanded(child: _buildStatCard('Đã duyệt', _stats['approved'] ?? 0, AppColors.success)),
                SizedBox(width: DesignTokens.space8),
                Expanded(child: _buildStatCard('Từ chối', _stats['rejected'] ?? 0, AppColors.error)),
              ],
            ),
          ),
          
          // Tabs
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Chờ duyệt (${_pendingCampaigns.length})'),
                Tab(text: 'Đã duyệt (${_approvedCampaigns.length})'),
                Tab(text: 'Từ chối (${_rejectedCampaigns.length})'),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: DSSpinner(size: DSSpinnerSize.medium))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCampaignList(_pendingCampaigns, showActions: true),
                      _buildCampaignList(_approvedCampaigns),
                      _buildCampaignList(_rejectedCampaigns),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: DesignTokens.space16,
        horizontal: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignList(List<VoucherCampaign> campaigns, {bool showActions = false}) {
    if (campaigns.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inbox,
        message: 'Không có campaign nào',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(3.w),
        itemCount: campaigns.length,
        itemBuilder: (context, index) => _buildCampaignCard(campaigns[index], showActions: showActions),
      ),
    );
  }

  Widget _buildCampaignCard(VoucherCampaign campaign, {bool showActions = false}) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(campaign.approvalStatus).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    campaign.statusDisplay,
                    style: TextStyle(
                      color: _getStatusColor(campaign.approvalStatus),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    campaign.campaignTypeDisplay,
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                SizedBox(width: 1.w),
                Text(
                  DateFormat('dd/MM/yy').format(campaign.createdAt),
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            
            // Title
            Text(
              campaign.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            // Club info
            if (campaign.clubName != null) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.store, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 1.w),
                  Text(
                    campaign.clubName!,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  if (campaign.clubOwnerName != null) ...[
                    Text(' • ', style: TextStyle(color: AppColors.textTertiary)),
                    Text(
                      campaign.clubOwnerName!,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
            
            SizedBox(height: 1.5.h),
            Divider(),
            SizedBox(height: 1.h),
            
            // Details
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.card_giftcard,
                    campaign.voucherTypeDisplay,
                    '${formatter.format(campaign.voucherValue)} ${campaign.voucherType == "percentage_discount" ? "%" : "VNĐ"}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.inventory,
                    'Số lượng',
                    '${campaign.totalQuantity}',
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.event,
                    'Bắt đầu',
                    DateFormat('dd/MM/yyyy').format(campaign.startDate),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.event_busy,
                    'Kết thúc',
                    DateFormat('dd/MM/yyyy').format(campaign.endDate),
                  ),
                ),
              ],
            ),
            
            // Description
            if (campaign.description != null && campaign.description!.isNotEmpty) ...[
              SizedBox(height: 1.5.h),
              Text(
                campaign.description!,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            // Admin notes
            if (campaign.adminNotes != null && campaign.adminNotes!.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppColors.warning50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: AppColors.warning700),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        campaign.adminNotes!,
                        style: TextStyle(fontSize: 12, color: AppColors.warning700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons
            if (showActions) ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectCampaign(campaign),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveCampaign(campaign),
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Phê duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.textOnPrimary,
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

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        SizedBox(width: 1.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }
}
