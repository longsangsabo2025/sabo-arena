import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/loyalty_service.dart';
import '../../services/loyalty_reward_service.dart';

/// Màn hình Loyalty Dashboard cho User
/// Hiển thị tier, points, available rewards
class UserLoyaltyDashboardScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const UserLoyaltyDashboardScreen({
    Key? key,
    required this.clubId,
    required this.clubName,
  }) : super(key: key);

  @override
  State<UserLoyaltyDashboardScreen> createState() => _UserLoyaltyDashboardScreenState();
}

class _UserLoyaltyDashboardScreenState extends State<UserLoyaltyDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _loyaltyService = LoyaltyService();
  final _rewardService = LoyaltyRewardService();
  final _supabase = Supabase.instance.client;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _userLoyalty;
  Map<String, dynamic>? _program;
  List<Map<String, dynamic>> _availableRewards = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _redemptions = [];

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
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // Get/Create loyalty account
      final loyalty = await _loyaltyService.getOrCreateUserLoyalty(
        userId: userId,
        clubId: widget.clubId,
      );

      // Get program config
      final program = await _loyaltyService.getLoyaltyProgram(
        clubId: widget.clubId,
      );

      // Get available rewards (by tier)
      final rewards = await _rewardService.getRewardsByTier(
        clubId: widget.clubId,
        tier: loyalty['current_tier'] ?? 'bronze',
        activeOnly: true,
      );

      // Get transactions
      final transactions = await _loyaltyService.getTransactions(
        userId: userId,
        clubId: widget.clubId,
        limit: 50,
      );

      // Get redemptions
      final redemptions = await _rewardService.getUserRedemptions(
        userId: userId,
        clubId: widget.clubId,
        limit: 50,
      );

      setState(() {
        _userLoyalty = loyalty;
        _program = program;
        _availableRewards = rewards;
        _transactions = transactions;
        _redemptions = redemptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loyalty - ${widget.clubName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.stars), text: 'Điểm'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Phần thưởng'),
            Tab(icon: Icon(Icons.history), text: 'Lịch sử'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPointsTab(),
                _buildRewardsTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  // ============================================================
  // TAB 1: POINTS
  // ============================================================

  Widget _buildPointsTab() {
    if (_userLoyalty == null || _program == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final currentTier = _userLoyalty!['current_tier'] ?? 'bronze';
    final currentBalance = _userLoyalty!['current_balance'] ?? 0;
    final pointsToNext = _userLoyalty!['points_to_next_tier'];
    final tierSystem = _program!['tier_system'] as Map<String, dynamic>;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildTierCard(currentTier, tierSystem),
          SizedBox(height: 3.h),
          _buildPointsCard(currentBalance, pointsToNext),
          SizedBox(height: 3.h),
          _buildStatsCards(),
          SizedBox(height: 3.h),
          _buildHowToEarnSection(),
        ],
      ),
    );
  }

  Widget _buildTierCard(String tier, Map<String, dynamic> tierSystem) {
    final tierInfo = tierSystem[tier];
    final tierColor = _getTierColor(tier);
    final tierLabel = _getTierLabel(tier);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [tierColor.withValues(alpha: 0.7), tierColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(5.w),
        child: Column(
          children: [
            Icon(Icons.stars, size: 50.sp, color: Colors.white),
            SizedBox(height: 2.h),
            Text(
              'Hạng $tierLabel',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 1.h),
            if (tierInfo != null) ...[
              Text(
                'Giảm giá ${tierInfo['discount_percent']}%',
                style: TextStyle(fontSize: 16.sp, color: Colors.white),
              ),
              Text(
                'Ưu tiên đặt bàn: Mức ${tierInfo['priority_booking']}',
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(int currentBalance, int? pointsToNext) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Text(
              'Điểm Hiện Tại',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 1.h),
            Text(
              currentBalance.toString(),
              style: TextStyle(
                fontSize: 40.sp,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            if (pointsToNext != null) ...[
              SizedBox(height: 2.h),
              LinearProgressIndicator(
                value: 0.6, // TODO: Calculate actual progress
                backgroundColor: Colors.grey[300],
                color: Colors.amber,
                minHeight: 1.h,
              ),
              SizedBox(height: 1.h),
              Text(
                'Còn $pointsToNext điểm để lên hạng',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Tích lũy',
            (_userLoyalty!['total_earned'] ?? 0).toString(),
            Icons.trending_up,
            Colors.green,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            'Đã đổi',
            (_userLoyalty!['points_redeemed'] ?? 0).toString(),
            Icons.redeem,
            Colors.blue,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            'Hết hạn',
            (_userLoyalty!['points_expired'] ?? 0).toString(),
            Icons.access_time,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToEarnSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💡 Cách Tích Điểm',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildEarnRule(
              Icons.sports_esports,
              'Mỗi game',
              '${_program!['points_per_game']} điểm',
            ),
            _buildEarnRule(
              Icons.attach_money,
              'Mỗi 1,000 VNĐ',
              '${(_program!['points_per_vnd'] * 1000).toStringAsFixed(1)} điểm',
            ),
            _buildEarnRule(
              Icons.access_time,
              'Mỗi giờ chơi',
              '${_program!['points_per_hour']} điểm',
            ),
            Divider(height: 3.h),
            _buildEarnRule(
              Icons.cake,
              'Sinh nhật',
              'x${_program!['birthday_multiplier']} điểm',
              color: Colors.pink,
            ),
            _buildEarnRule(
              Icons.weekend,
              'Cuối tuần',
              'x${_program!['weekend_multiplier']} điểm',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnRule(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: color ?? Colors.amber),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.sp)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 2: REWARDS
  // ============================================================

  Widget _buildRewardsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _availableRewards.isEmpty
          ? _buildNoRewardsState()
          : ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _availableRewards.length,
              itemBuilder: (context, index) {
                final reward = _availableRewards[index];
                return _buildRewardCard(reward);
              },
            ),
    );
  }

  Widget _buildNoRewardsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 80.sp, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'Chưa có phần thưởng',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Tích thêm điểm để mở khóa phần thưởng',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    final canRedeem = _rewardService.canUserRedeemReward(
      reward: reward,
      userPoints: _userLoyalty!['current_balance'] ?? 0,
      userTier: _userLoyalty!['current_tier'] ?? 'bronze',
    );

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: canRedeem ? () => _showRedeemDialog(reward) : null,
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30.sp,
                backgroundColor: _getRewardColor(reward['reward_type']).withValues(alpha: 0.2),
                child: Icon(
                  _getRewardIcon(reward['reward_type']),
                  color: _getRewardColor(reward['reward_type']),
                  size: 30.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward['reward_name'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (reward['description'] != null)
                      Text(
                        reward['description'],
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(Icons.stars, size: 14.sp, color: Colors.amber),
                        SizedBox(width: 1.w),
                        Text(
                          '${reward['points_cost']} điểm',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: canRedeem ? () => _showRedeemDialog(reward) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRedeem ? Colors.amber : Colors.grey,
                ),
                child: Text(canRedeem ? 'Đổi' : 'Không đủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TAB 3: HISTORY
  // ============================================================

  Widget _buildHistoryTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Giao dịch'),
              Tab(text: 'Đổi thưởng'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTransactionsList(),
                _buildRedemptionsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Text(
          'Chưa có giao dịch',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final tx = _transactions[index];
          return _buildTransactionItem(tx);
        },
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final type = tx['type'] as String;
    final points = tx['points_amount'] as int;
    final isEarn = type.startsWith('earn');
    final date = DateTime.parse(tx['created_at']);

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEarn ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
          child: Icon(
            isEarn ? Icons.add : Icons.remove,
            color: isEarn ? Colors.green : Colors.red,
          ),
        ),
        title: Text(_getTransactionTypeLabel(type)),
        subtitle: Text(
          '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
        ),
        trailing: Text(
          '${isEarn ? '+' : '-'}$points',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isEarn ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildRedemptionsList() {
    if (_redemptions.isEmpty) {
      return Center(
        child: Text(
          'Chưa có đổi thưởng',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _redemptions.length,
        itemBuilder: (context, index) {
          final redemption = _redemptions[index];
          return _buildRedemptionItem(redemption);
        },
      ),
    );
  }

  Widget _buildRedemptionItem(Map<String, dynamic> redemption) {
    final reward = redemption['reward'] as Map<String, dynamic>?;
    final status = redemption['status'] as String;
    final date = DateTime.parse(redemption['created_at']);
    final code = redemption['redemption_code'];

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRewardColor(reward?['reward_type'] ?? '').withValues(alpha: 0.2),
          child: Icon(
            _getRewardIcon(reward?['reward_type'] ?? ''),
            color: _getRewardColor(reward?['reward_type'] ?? ''),
          ),
        ),
        title: Text(reward?['reward_name'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${date.day}/${date.month}/${date.year}'),
            if (code != null)
              Text(
                'Mã: $code',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            _getRedemptionStatusLabel(status),
            style: TextStyle(fontSize: 10.sp),
          ),
          backgroundColor: _getRedemptionStatusColor(status),
        ),
      ),
    );
  }

  // ============================================================
  // REDEEM ACTION
  // ============================================================

  Future<void> _showRedeemDialog(Map<String, dynamic> reward) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đổi thưởng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reward['reward_name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text('Chi phí: ${reward['points_cost']} điểm'),
            Text(
              'Còn lại: ${(_userLoyalty!['current_balance'] ?? 0) - reward['points_cost']} điểm',
            ),
            SizedBox(height: 2.h),
            const Text(
              'Sau khi đổi, bạn sẽ nhận được mã để sử dụng tại quầy.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final result = await _rewardService.redeemReward(
        userId: userId,
        rewardId: reward['id'],
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Đổi thưởng thành công!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mã của bạn:', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    result['redemption_code'],
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                const Text(
                  'Vui lòng xuất trình mã này tại quầy để nhận thưởng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadData();
                },
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _getTierLabel(String tier) {
    switch (tier) {
      case 'bronze':
        return 'Đồng';
      case 'silver':
        return 'Bạc';
      case 'gold':
        return 'Vàng';
      case 'platinum':
        return 'Bạch Kim';
      default:
        return tier;
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey;
      case 'gold':
        return Colors.amber;
      case 'platinum':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRewardIcon(String type) {
    switch (type) {
      case 'discount_voucher':
        return Icons.discount;
      case 'free_game':
        return Icons.sports_esports;
      case 'free_hour':
        return Icons.access_time;
      case 'merchandise':
        return Icons.shopping_bag;
      case 'food_drink':
        return Icons.restaurant;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getRewardColor(String type) {
    switch (type) {
      case 'discount_voucher':
        return Colors.orange;
      case 'free_game':
        return Colors.blue;
      case 'free_hour':
        return Colors.purple;
      case 'merchandise':
        return Colors.green;
      case 'food_drink':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'earn_game':
        return 'Chơi game';
      case 'earn_purchase':
        return 'Mua hàng';
      case 'earn_bonus':
        return 'Thưởng';
      case 'earn_birthday':
        return 'Sinh nhật';
      case 'redeem_reward':
        return 'Đổi thưởng';
      case 'adjustment':
        return 'Điều chỉnh';
      case 'expired':
        return 'Hết hạn';
      case 'refund':
        return 'Hoàn điểm';
      default:
        return type;
    }
  }

  String _getRedemptionStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'ready_to_collect':
        return 'Sẵn sàng';
      case 'fulfilled':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'expired':
        return 'Hết hạn';
      default:
        return status;
    }
  }

  Color _getRedemptionStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.withValues(alpha: 0.2);
      case 'approved':
        return Colors.blue.withValues(alpha: 0.2);
      case 'ready_to_collect':
        return Colors.green.withValues(alpha: 0.2);
      case 'fulfilled':
        return Colors.teal.withValues(alpha: 0.2);
      case 'cancelled':
        return Colors.red.withValues(alpha: 0.2);
      case 'expired':
        return Colors.grey.withValues(alpha: 0.2);
      default:
        return Colors.grey.withValues(alpha: 0.2);
    }
  }
}
