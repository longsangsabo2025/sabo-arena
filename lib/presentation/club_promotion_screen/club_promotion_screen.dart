import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../models/club_promotion.dart';
import '../../theme/app_theme.dart';
import 'create_promotion_screen.dart';
import 'promotion_detail_screen.dart';

class ClubPromotionScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const ClubPromotionScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubPromotionScreen> createState() => _ClubPromotionScreenState();
}

class _ClubPromotionScreenState extends State<ClubPromotionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;
  String? _errorMessage;

  List<ClubPromotion> _allPromotions = [];
  List<ClubPromotion> _activePromotions = [];
  List<ClubPromotion> _upcomingPromotions = [];
  List<ClubPromotion> _expiredPromotions = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _allPromotions = _getMockPromotions();
      _activePromotions = _allPromotions.where((p) => p.isActive).toList();
      _upcomingPromotions = _allPromotions.where((p) => p.isUpcoming).toList();
      _expiredPromotions = _allPromotions.where((p) => p.isExpired).toList();
      _stats = {
        'active_promotions': _activePromotions.length,
        'total_redemptions': 150,
        'total_savings': 5000000,
      };
    });
  }

  List<ClubPromotion> _getMockPromotions() {
    final now = DateTime.now();
    return [
      ClubPromotion(
        id: '1',
        clubId: widget.clubId,
        title: 'Giảm giá 20% cho thành viên mới',
        description:
            'Ưu đãi đặc biệt dành cho thành viên đăng ký trong tháng này',
        imageUrl: null,
        type: PromotionType.discount,
        status: PromotionStatus.active,
        startDate: now.subtract(Duration(days: 5)),
        endDate: now.add(Duration(days: 25)),
        conditions: {'min_spend': 100000},
        rewards: {'discount_percentage': 20},
        maxRedemptions: 100,
        currentRedemptions: 15,
        discountPercentage: 20,
        discountAmount: null,
        promoCode: 'NEWMEMBER20',
        applicableServices: ['table_booking', 'membership'],
        priority: 1,
        createdAt: now.subtract(Duration(days: 10)),
        updatedAt: now.subtract(Duration(days: 1)),
        createdBy: 'admin',
      ),
      ClubPromotion(
        id: '2',
        clubId: widget.clubId,
        title: 'Combo bàn + đồ uống',
        description: 'Đặt bàn 2 giờ tặng kèm 2 ly nước ngọt',
        imageUrl: null,
        type: PromotionType.bundleOffer,
        status: PromotionStatus.active,
        startDate: now.subtract(Duration(days: 2)),
        endDate: now.add(Duration(days: 18)),
        conditions: {'min_hours': 2},
        rewards: {'free_drinks': 2},
        maxRedemptions: null,
        currentRedemptions: 43,
        discountPercentage: null,
        discountAmount: 30000,
        promoCode: null,
        applicableServices: ['table_booking'],
        priority: 2,
        createdAt: now.subtract(Duration(days: 7)),
        updatedAt: now.subtract(Duration(days: 2)),
        createdBy: 'admin',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khuyến mãi & Ưu đãi',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            Text(
              widget.clubName,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              size: 20, color: AppTheme.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.primaryLight),
            onPressed: _navigateToCreatePromotion,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textSecondaryLight),
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(140),
          child: Column(
            children: [
              // Stats cards
              Container(
                height: 80,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatsCard(
                        title: 'Đang hoạt động',
                        value: '${_stats['active_promotions'] ?? 0}',
                        icon: Icons.local_offer,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildStatsCard(
                        title: 'Tổng lượt sử dụng',
                        value: '${_stats['total_redemptions'] ?? 0}',
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildStatsCard(
                        title: 'Tổng tiết kiệm',
                        value: NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: 'đ',
                          decimalDigits: 0,
                        ).format(_stats['total_savings'] ?? 0),
                        icon: Icons.savings,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppTheme.primaryLight,
                  unselectedLabelColor: AppTheme.textSecondaryLight,
                  indicatorColor: AppTheme.primaryLight,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Tất cả'),
                          if (_allPromotions.isNotEmpty) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_allPromotions.length}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.sp),
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
                          Text('Đang hoạt động'),
                          if (_activePromotions.isNotEmpty) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_activePromotions.length}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11.sp, color: Colors.green),
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
                          Text('Sắp diễn ra'),
                          if (_upcomingPromotions.isNotEmpty) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_upcomingPromotions.length}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11.sp, color: Colors.blue),
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
                          Text('Đã kết thúc'),
                          if (_expiredPromotions.isNotEmpty) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_expiredPromotions.length}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11.sp, color: Colors.grey),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePromotion,
        backgroundColor: AppTheme.primaryLight,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(_errorMessage!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPromotionList(
            _allPromotions, 'Chưa có chương trình khuyến mãi nào'),
        _buildPromotionList(
            _activePromotions, 'Không có khuyến mãi đang hoạt động'),
        _buildPromotionList(
            _upcomingPromotions, 'Không có khuyến mãi sắp diễn ra'),
        _buildPromotionList(
            _expiredPromotions, 'Không có khuyến mãi đã kết thúc'),
      ],
    );
  }

  Widget _buildPromotionList(
      List<ClubPromotion> promotions, String emptyMessage) {
    if (promotions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Tạo chương trình khuyến mãi mới để thu hút khách hàng',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreatePromotion,
              icon: Icon(Icons.add),
              label: Text('Tạo khuyến mãi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          return _buildPromotionCard(promotion);
        },
      ),
    );
  }

  Widget _buildPromotionCard(ClubPromotion promotion) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () => _navigateToPromotionDetail(promotion),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promotion.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          promotion.description,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    children: [
                      _buildStatusBadge(promotion),
                      SizedBox(height: 8),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Chỉnh sửa'),
                              dense: true,
                            ),
                            onTap: () => _navigateToEditPromotion(promotion),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(
                                  promotion.status == PromotionStatus.active
                                      ? Icons.pause
                                      : Icons.play_arrow),
                              title: Text(
                                  promotion.status == PromotionStatus.active
                                      ? 'Tạm dừng'
                                      : 'Kích hoạt'),
                              dense: true,
                            ),
                            onTap: () => _togglePromotionStatus(promotion),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Xóa',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.red)),
                              dense: true,
                            ),
                            onTap: () => _showDeleteConfirmation(promotion),
                          ),
                        ],
                        child: Icon(Icons.more_vert, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (promotion.promoCode != null) ...[
                          Row(
                            children: [
                              Icon(Icons.confirmation_num,
                                  size: 16, color: AppTheme.primaryLight),
                              SizedBox(width: 4),
                              Text(
                                promotion.promoCode!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${DateFormat('dd/MM').format(promotion.startDate)} - ${DateFormat('dd/MM/yyyy').format(promotion.endDate)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        if (promotion.maxRedemptions != null) ...[
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.people, size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                '${promotion.currentRedemptions}/${promotion.maxRedemptions} lượt sử dụng',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (promotion.discountPercentage != null) ...[
                        Text(
                          '${promotion.discountPercentage}% OFF',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ] else if (promotion.discountAmount != null) ...[
                        Text(
                          '-${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(promotion.discountAmount)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'MIỄN PHÍ',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 4),
                      Text(
                        promotion.type.displayName,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Progress bar for limited promotions
              if (promotion.maxRedemptions != null) ...[
                SizedBox(height: 12),
                LinearProgressIndicator(
                  value: promotion.completionPercentage / 100,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    promotion.completionPercentage > 80
                        ? Colors.red
                        : AppTheme.primaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ClubPromotion promotion) {
    Color color;
    String text;

    if (promotion.isActive) {
      color = Colors.green;
      text = 'Hoạt động';
    } else if (promotion.isUpcoming) {
      color = Colors.blue;
      text = 'Sắp diễn ra';
    } else if (promotion.isExpired) {
      color = Colors.grey;
      text = 'Đã hết hạn';
    } else {
      color = Colors.orange;
      text = promotion.status.displayName;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _navigateToCreatePromotion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePromotionScreen(
          clubId: widget.clubId,
          clubName: widget.clubName,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _navigateToEditPromotion(ClubPromotion promotion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePromotionScreen(
          clubId: widget.clubId,
          clubName: widget.clubName,
          editingPromotion: promotion,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _navigateToPromotionDetail(ClubPromotion promotion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromotionDetailScreen(
          promotion: promotion,
        ),
      ),
    ).then((_) {
      _loadData();
    });
  }

  void _showDeleteConfirmation(ClubPromotion promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa khuyến mãi'),
        content: Text(
            'Bạn có chắc chắn muốn xóa "${promotion.title}"?\n\nThao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePromotion(promotion.id);
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

  void _deletePromotion(String promotionId) {
    setState(() {
      _allPromotions.removeWhere((p) => p.id == promotionId);
      _activePromotions.removeWhere((p) => p.id == promotionId);
      _upcomingPromotions.removeWhere((p) => p.id == promotionId);
      _expiredPromotions.removeWhere((p) => p.id == promotionId);
      _stats['active_promotions'] = _activePromotions.length;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa khuyến mãi thành công'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _togglePromotionStatus(ClubPromotion promotion) {
    setState(() {
      final index = _allPromotions.indexWhere((p) => p.id == promotion.id);
      if (index != -1) {
        // This would normally update the promotion status via API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tính năng thay đổi trạng thái đang được phát triển'),
            backgroundColor: AppTheme.primaryLight,
          ),
        );
      }
    });
  }
}
