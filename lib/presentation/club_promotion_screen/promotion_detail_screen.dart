import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../models/club_promotion.dart';
import '../../theme/app_theme.dart';

class PromotionDetailScreen extends StatefulWidget {
  final ClubPromotion promotion;

  const PromotionDetailScreen({super.key, required this.promotion});

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildPromotionHeader(),
                _buildTabBar(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      pinned: true,
      expandedHeight: 200,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          size: 20,
          color: AppTheme.textPrimaryLight,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Chỉnh sửa'),
                dense: true,
              ),
              onTap: () => _editPromotion(),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Chia sẻ'),
                dense: true,
              ),
              onTap: () => _sharePromotion(),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(
                  widget.promotion.status == PromotionStatus.active
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                title: Text(
                  widget.promotion.status == PromotionStatus.active
                      ? 'Tạm dừng'
                      : 'Kích hoạt',
                ),
                dense: true,
              ),
              onTap: () => _toggleStatus(),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.red)),
                dense: true,
              ),
              onTap: () => _deletePromotion(),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getPromotionColor().withValues(alpha: 0.1),
                _getPromotionColor().withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 80), // Account for app bar
                Icon(
                  _getPromotionIcon(),
                  size: 48,
                  color: _getPromotionColor(),
                ),
                SizedBox(height: 12),
                Text(
                  widget.promotion.title, style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                _buildStatusBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.promotion.description, style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.schedule,
                  title: 'Thời gian',
                  value:
                      '${DateFormat('dd/MM').format(widget.promotion.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.promotion.endDate)}',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.category,
                  title: 'Loại',
                  value: widget.promotion.type.displayName,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              if (widget.promotion.maxRedemptions != null) ...[
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.people,
                    title: 'Sử dụng',
                    value:
                        '${widget.promotion.currentRedemptions}/${widget.promotion.maxRedemptions}',
                  ),
                ),
                SizedBox(width: 12),
              ],
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.local_offer,
                  title: 'Ưu đãi',
                  value: _getDiscountText(),
                ),
              ),
            ],
          ),
          if (widget.promotion.promoCode != null) ...[
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.confirmation_num, color: AppTheme.primaryLight),
                  SizedBox(width: 8),
                  Text(
                    'Mã khuyến mãi: ', overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.promotion.promoCode!, overflow: TextOverflow.ellipsis, style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: AppTheme.primaryLight),
                    onPressed: () => _copyPromoCode(),
                    tooltip: 'Sao chép mã',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
        ),
        tabs: [
          Tab(text: 'Chi tiết'),
          Tab(text: 'Điều kiện'),
          Tab(text: 'Thống kê'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      height: 400,
      margin: EdgeInsets.all(16),
      child: TabBarView(
        controller: _tabController,
        children: [_buildDetailsTab(), _buildConditionsTab(), _buildStatsTab()],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('ID khuyến mãi', widget.promotion.id),
            _buildDetailItem('Trạng thái', widget.promotion.status.displayName),
            _buildDetailItem('Độ ưu tiên', '${widget.promotion.priority}'),
            _buildDetailItem(
              'Ngày tạo',
              DateFormat('dd/MM/yyyy HH:mm').format(widget.promotion.createdAt),
            ),
            _buildDetailItem(
              'Cập nhật lần cuối',
              DateFormat('dd/MM/yyyy HH:mm').format(widget.promotion.updatedAt),
            ),
            if (widget.promotion.createdBy != null)
              _buildDetailItem('Người tạo', widget.promotion.createdBy!),
            SizedBox(height: 16),
            Text(
              'Dịch vụ áp dụng', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 8),
            if (widget.promotion.applicableServices != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.promotion.applicableServices!.map((service) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getServiceName(service),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Text(
                'Áp dụng cho tất cả dịch vụ', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsTab() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Điều kiện áp dụng', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 16),
          if (widget.promotion.conditions != null) ...[
            ...widget.promotion.conditions!.entries.map(
              (entry) => _buildConditionItem(entry.key, entry.value),
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Không có điều kiện đặc biệt', overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê sử dụng', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Tổng lượt sử dụng',
                  value: '${widget.promotion.currentRedemptions}',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Tỉ lệ hoàn thành',
                  value:
                      '${widget.promotion.completionPercentage.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          if (widget.promotion.maxRedemptions != null) ...[
            SizedBox(height: 16),
            Text(
              'Tiến độ sử dụng', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: widget.promotion.completionPercentage / 100,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.promotion.completionPercentage > 80
                    ? Colors.red
                    : AppTheme.primaryLight,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${widget.promotion.currentRedemptions} / ${widget.promotion.maxRedemptions} lượt', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _sharePromotion,
              icon: Icon(Icons.share),
              label: Text('Chia sẻ'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _editPromotion,
              icon: Icon(Icons.edit),
              label: Text('Chỉnh sửa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    if (widget.promotion.isActive) {
      color = Colors.green;
      text = 'Đang hoạt động';
    } else if (widget.promotion.isUpcoming) {
      color = Colors.blue;
      text = 'Sắp diễn ra';
    } else if (widget.promotion.isExpired) {
      color = Colors.grey;
      text = 'Đã hết hạn';
    } else {
      color = Colors.orange;
      text = widget.promotion.status.displayName;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text, style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.textSecondaryLight),
              SizedBox(width: 4),
              Text(
                title, style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value, style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label, style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value, style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem(String key, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatCondition(key, value),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value, style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title, style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPromotionColor() {
    switch (widget.promotion.type) {
      case PromotionType.discount:
        return Colors.red;
      case PromotionType.cashback:
        return Colors.green;
      case PromotionType.freeService:
        return Colors.blue;
      case PromotionType.bundleOffer:
        return Colors.orange;
      case PromotionType.membershipDiscount:
        return Colors.purple;
      case PromotionType.eventSpecial:
        return Colors.pink;
      case PromotionType.seasonalOffer:
        return Colors.teal;
      case PromotionType.loyaltyReward:
        return Colors.amber;
    }
  }

  IconData _getPromotionIcon() {
    switch (widget.promotion.type) {
      case PromotionType.discount:
        return Icons.percent;
      case PromotionType.cashback:
        return Icons.attach_money;
      case PromotionType.freeService:
        return Icons.star;
      case PromotionType.bundleOffer:
        return Icons.redeem;
      case PromotionType.membershipDiscount:
        return Icons.card_membership;
      case PromotionType.eventSpecial:
        return Icons.event;
      case PromotionType.seasonalOffer:
        return Icons.ac_unit;
      case PromotionType.loyaltyReward:
        return Icons.loyalty;
    }
  }

  String _getDiscountText() {
    if (widget.promotion.discountPercentage != null) {
      return '${widget.promotion.discountPercentage}% OFF';
    } else if (widget.promotion.discountAmount != null) {
      return NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'đ',
        decimalDigits: 0,
      ).format(widget.promotion.discountAmount);
    } else {
      return 'Ưu đãi đặc biệt';
    }
  }

  String _getServiceName(String service) {
    final serviceNames = {
      'table_booking': 'Đặt bàn',
      'membership': 'Thành viên',
      'food_drink': 'Đồ ăn & uống',
      'equipment_rental': 'Thuê thiết bị',
      'training': 'Đào tạo',
      'tournament': 'Giải đấu',
    };
    return serviceNames[service] ?? service;
  }

  String _formatCondition(String key, dynamic value) {
    switch (key) {
      case 'min_spend':
        return 'Chi tiêu tối thiểu: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(value)}';
      case 'min_hours':
        return 'Đặt bàn tối thiểu: $value giờ';
      case 'weekends_only':
        return 'Chỉ áp dụng cuối tuần';
      case 'time_range':
        return 'Khung giờ: $value';
      case 'new_members_only':
        return 'Chỉ dành cho thành viên mới';
      default:
        return '$key: $value';
    }
  }

  void _editPromotion() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng chỉnh sửa đang được phát triển'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }

  void _sharePromotion() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng chia sẻ đang được phát triển'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }

  void _toggleStatus() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng thay đổi trạng thái đang được phát triển'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }

  void _deletePromotion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa khuyến mãi'),
        content: Text(
          'Bạn có chắc chắn muốn xóa khuyến mãi này?\n\nThao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa khuyến mãi thành công'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _copyPromoCode() {
    // Copy to clipboard functionality would go here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã khuyến mãi'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
