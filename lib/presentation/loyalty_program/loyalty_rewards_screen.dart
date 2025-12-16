import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/loyalty_reward_service.dart';

/// Màn hình quản lý Rewards catalog
/// Dành cho Club Owner
class LoyaltyRewardsScreen extends StatefulWidget {
  final String clubId;

  const LoyaltyRewardsScreen({
    Key? key,
    required this.clubId,
  }) : super(key: key);

  @override
  State<LoyaltyRewardsScreen> createState() => _LoyaltyRewardsScreenState();
}

class _LoyaltyRewardsScreenState extends State<LoyaltyRewardsScreen> {
  final _rewardService = LoyaltyRewardService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _rewards = [];
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() => _isLoading = true);
    
    try {
      final rewards = await _rewardService.getClubRewards(
        clubId: widget.clubId,
        activeOnly: false,
      );
      
      setState(() {
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

  List<Map<String, dynamic>> get _filteredRewards {
    if (_filterType == 'all') return _rewards;
    return _rewards.where((r) => r['reward_type'] == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Phần Thưởng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createReward,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRewards.isEmpty
                    ? _buildEmptyState()
                    : _buildRewardsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Tất cả', 'icon': Icons.all_inclusive},
      {'key': 'discount_voucher', 'label': 'Giảm giá', 'icon': Icons.discount},
      {'key': 'free_game', 'label': 'Game miễn phí', 'icon': Icons.sports_esports},
      {'key': 'free_hour', 'label': 'Giờ miễn phí', 'icon': Icons.access_time},
      {'key': 'merchandise', 'label': 'Hàng hóa', 'icon': Icons.shopping_bag},
      {'key': 'food_drink', 'label': 'Đồ ăn/uống', 'icon': Icons.restaurant},
    ];

    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filterType == filter['key'];

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(filter['icon'] as IconData, size: 16.sp),
                  SizedBox(width: 1.w),
                  Text(filter['label'] as String),
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _filterType = filter['key'] as String;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 80.sp, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            _filterType == 'all' ? 'Chưa có phần thưởng' : 'Không tìm thấy',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Thêm phần thưởng để khách hàng đổi điểm',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _createReward,
            icon: const Icon(Icons.add),
            label: const Text('Thêm phần thưởng'),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsList() {
    return RefreshIndicator(
      onRefresh: _loadRewards,
      child: ListView.builder(
        padding: EdgeInsets.all(3.w),
        itemCount: _filteredRewards.length,
        itemBuilder: (context, index) {
          final reward = _filteredRewards[index];
          return _buildRewardCard(reward);
        },
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    final isActive = reward['is_active'] == true;
    final quantityAvailable = reward['quantity_available'] as int?;
    final quantityTotal = reward['quantity_total'] as int?;
    
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _editReward(reward),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25.sp,
                    backgroundColor: _getRewardColor(reward['reward_type']).withValues(alpha: 0.2),
                    child: Icon(
                      _getRewardIcon(reward['reward_type']),
                      color: _getRewardColor(reward['reward_type']),
                      size: 25.sp,
                    ),
                  ),
                  SizedBox(width: 3.w),
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
                        Text(
                          _getRewardTypeLabel(reward['reward_type']),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${reward['points_cost']} điểm',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'Đang bán' : 'Tạm dừng',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (reward['description'] != null) ...[
                SizedBox(height: 1.h),
                Text(
                  reward['description'],
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 1.h),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.stars,
                    'Hạng: ${_getTierLabel(reward['tier_required'])}',
                    _getTierColor(reward['tier_required']),
                  ),
                  if (quantityTotal != null) ...[
                    SizedBox(width: 2.w),
                    _buildInfoChip(
                      Icons.inventory,
                      'Còn: $quantityAvailable/$quantityTotal',
                      quantityAvailable! > 0 ? Colors.blue : Colors.red,
                    ),
                  ],
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _viewRewardStats(reward),
                    icon: Icon(Icons.analytics, size: 16.sp),
                    label: const Text('Thống kê'),
                  ),
                  TextButton.icon(
                    onPressed: () => _editReward(reward),
                    icon: Icon(Icons.edit, size: 16.sp),
                    label: const Text('Sửa'),
                  ),
                  TextButton.icon(
                    onPressed: () => _toggleRewardStatus(reward),
                    icon: Icon(
                      isActive ? Icons.pause : Icons.play_arrow,
                      size: 16.sp,
                    ),
                    label: Text(isActive ? 'Dừng' : 'Kích hoạt'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: color),
          ),
        ],
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
      case 'upgrade':
        return Colors.indigo;
      case 'special_event':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getRewardTypeLabel(String type) {
    switch (type) {
      case 'discount_voucher':
        return 'Voucher giảm giá';
      case 'free_game':
        return 'Game miễn phí';
      case 'free_hour':
        return 'Giờ chơi miễn phí';
      case 'merchandise':
        return 'Hàng hóa';
      case 'food_drink':
        return 'Đồ ăn/uống';
      case 'upgrade':
        return 'Nâng cấp';
      case 'special_event':
        return 'Sự kiện đặc biệt';
      default:
        return type;
    }
  }

  String _getTierLabel(String? tier) {
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
        return 'Đồng';
    }
  }

  Color _getTierColor(String? tier) {
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
        return Colors.brown;
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _createReward() async {
    // TODO: Show dialog/screen to create new reward
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  Future<void> _editReward(Map<String, dynamic> reward) async {
    // TODO: Show dialog/screen to edit reward
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sửa: ${reward['reward_name']}')),
    );
  }

  Future<void> _toggleRewardStatus(Map<String, dynamic> reward) async {
    final currentStatus = reward['is_active'] == true;
    
    try {
      await _rewardService.updateReward(
        rewardId: reward['id'],
        isActive: !currentStatus,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus 
                  ? 'Đã tạm dừng phần thưởng' 
                  : 'Đã kích hoạt phần thưởng',
            ),
          ),
        );
      }
      
      _loadRewards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _viewRewardStats(Map<String, dynamic> reward) async {
    try {
      final stats = await _rewardService.getRewardStats(
        rewardId: reward['id'],
      );
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Thống kê: ${reward['reward_name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Tổng đổi', '${stats['total_redemptions']}'),
                _buildStatRow('Chờ duyệt', '${stats['pending']}'),
                _buildStatRow('Đã duyệt', '${stats['approved']}'),
                _buildStatRow('Sẵn sàng lấy', '${stats['ready_to_collect']}'),
                _buildStatRow('Đã hoàn thành', '${stats['fulfilled']}'),
                _buildStatRow('Đã hủy', '${stats['cancelled']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
