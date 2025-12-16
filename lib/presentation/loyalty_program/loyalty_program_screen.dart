import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/loyalty_service.dart';
import '../../services/loyalty_reward_service.dart';

/// Màn hình quản lý Loyalty Program
/// Dành cho Club Owner để config program
class LoyaltyProgramScreen extends StatefulWidget {
  final String clubId;

  const LoyaltyProgramScreen({
    Key? key,
    required this.clubId,
  }) : super(key: key);

  @override
  State<LoyaltyProgramScreen> createState() => _LoyaltyProgramScreenState();
}

class _LoyaltyProgramScreenState extends State<LoyaltyProgramScreen> {
  final _loyaltyService = LoyaltyService();
  final _rewardService = LoyaltyRewardService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _program;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _rewards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load program config
      final program = await _loyaltyService.getLoyaltyProgram(
        clubId: widget.clubId,
      );
      
      // Load stats
      final stats = await _loyaltyService.getClubStats(
        clubId: widget.clubId,
      );
      
      // Load rewards
      final rewards = await _rewardService.getClubRewards(
        clubId: widget.clubId,
        activeOnly: false,
      );
      
      setState(() {
        _program = program;
        _stats = stats;
        _rewards = rewards;
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
        title: const Text('Chương trình Loyalty'),
        actions: [
          if (_program == null)
            TextButton.icon(
              onPressed: _createProgram,
              icon: const Icon(Icons.add),
              label: const Text('Tạo Program'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _program == null
              ? _buildEmptyState()
              : _buildProgramContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars, size: 80.sp, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'Chưa có Loyalty Program',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Tạo chương trình để tích điểm cho khách hàng',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _createProgram,
            icon: const Icon(Icons.add),
            label: const Text('Tạo Loyalty Program'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          _buildStatisticsCard(),
          SizedBox(height: 2.h),
          _buildProgramInfoCard(),
          SizedBox(height: 2.h),
          _buildPointsRulesCard(),
          SizedBox(height: 2.h),
          _buildMultipliersCard(),
          SizedBox(height: 2.h),
          _buildTierSystemCard(),
          SizedBox(height: 2.h),
          _buildRewardsSection(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Thống Kê',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Thành viên',
                    _stats!['total_members']?.toString() ?? '0',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Điểm tích',
                    _stats!['total_points_issued']?.toString() ?? '0',
                    Icons.stars,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Điểm đổi',
                    _stats!['total_points_redeemed']?.toString() ?? '0',
                    Icons.redeem,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Điểm hết hạn',
                    _stats!['total_points_expired']?.toString() ?? '0',
                    Icons.access_time,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 0.5.h),
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
          ),
        ],
      ),
    );
  }

  Widget _buildProgramInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ℹ️ Thông Tin Program',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editProgramInfo,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            _buildInfoRow('Tên chương trình', _program!['program_name']),
            _buildInfoRow(
              'Trạng thái',
              _program!['is_active'] == true ? '✅ Đang hoạt động' : '❌ Tạm dừng',
            ),
            _buildInfoRow(
              'Điểm hết hạn sau',
              '${_program!['points_expiry_days']} ngày',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsRulesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🎯 Quy Tắc Tích Điểm',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editPointsRules,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            _buildInfoRow(
              'Mỗi game',
              '${_program!['points_per_game']} điểm',
            ),
            _buildInfoRow(
              'Mỗi 1,000 VNĐ',
              '${(_program!['points_per_vnd'] * 1000).toStringAsFixed(1)} điểm',
            ),
            _buildInfoRow(
              'Mỗi giờ chơi',
              '${_program!['points_per_hour']} điểm',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipliersCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🎁 Hệ Số Nhân',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editMultipliers,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            _buildInfoRow(
              'Sinh nhật',
              'x${_program!['birthday_multiplier']}',
            ),
            _buildInfoRow(
              'Cuối tuần',
              'x${_program!['weekend_multiplier']}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierSystemCard() {
    final tierSystem = _program!['tier_system'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '👑 Hệ Thống Hạng',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editTierSystem,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            _buildTierItem('Đồng', tierSystem['bronze'], Colors.brown),
            _buildTierItem('Bạc', tierSystem['silver'], Colors.grey),
            _buildTierItem('Vàng', tierSystem['gold'], Colors.amber),
            _buildTierItem('Bạch Kim', tierSystem['platinum'], Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildTierItem(String name, dynamic tier, Color color) {
    if (tier == null) return const SizedBox.shrink();

    final minPoints = tier['min_points'] ?? 0;
    final maxPoints = tier['max_points'];
    final discount = tier['discount_percent'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.stars, color: color, size: 20.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  maxPoints != null
                      ? '$minPoints - $maxPoints điểm'
                      : 'Từ $minPoints điểm',
                  style: TextStyle(fontSize: 11.sp),
                ),
              ],
            ),
          ),
          Text(
            'Giảm $discount%',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🎁 Phần Thưởng (${_rewards.length})',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _navigateToRewardsScreen,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Quản lý'),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        if (_rewards.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(5.w),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.card_giftcard, size: 40.sp, color: Colors.grey),
                    SizedBox(height: 1.h),
                    Text(
                      'Chưa có phần thưởng',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 1.h),
                    ElevatedButton.icon(
                      onPressed: _navigateToRewardsScreen,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm phần thưởng'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rewards.length > 3 ? 3 : _rewards.length,
            itemBuilder: (context, index) {
              final reward = _rewards[index];
              return _buildRewardCard(reward);
            },
          ),
        if (_rewards.length > 3)
          Center(
            child: TextButton(
              onPressed: _navigateToRewardsScreen,
              child: Text('Xem tất cả ${_rewards.length} phần thưởng →'),
            ),
          ),
      ],
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber.withValues(alpha: 0.2),
          child: Icon(
            _getRewardIcon(reward['reward_type']),
            color: Colors.amber,
          ),
        ),
        title: Text(
          reward['reward_name'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${reward['points_cost']} điểm'),
        trailing: Icon(
          reward['is_active'] == true ? Icons.check_circle : Icons.cancel,
          color: reward['is_active'] == true ? Colors.green : Colors.red,
        ),
      ),
    );
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
      case 'upgrade':
        return Icons.upgrade;
      case 'special_event':
        return Icons.event;
      default:
        return Icons.card_giftcard;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _createProgram() async {
    final name = await _showTextInputDialog(
      'Tạo Loyalty Program',
      'Tên chương trình',
      'VD: SaboArena VIP',
    );

    if (name == null || name.isEmpty) return;

    try {
      await _loyaltyService.createLoyaltyProgram(
        clubId: widget.clubId,
        programName: name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo chương trình thành công!')),
        );
      }

      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _editProgramInfo() {
    // TODO: Show dialog to edit program name, status, expiry days
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _editPointsRules() {
    // TODO: Show dialog to edit points rules
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _editMultipliers() {
    // TODO: Show dialog to edit multipliers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _editTierSystem() {
    // TODO: Show dialog to edit tier system
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _navigateToRewardsScreen() {
    Navigator.pushNamed(
      context,
      '/loyalty-rewards',
      arguments: {'clubId': widget.clubId},
    );
  }

  Future<String?> _showTextInputDialog(
    String title,
    String label,
    String hint,
  ) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
