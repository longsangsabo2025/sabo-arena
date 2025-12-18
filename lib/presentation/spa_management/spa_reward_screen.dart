import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/club_spa_service.dart';
import '../../../services/user_service.dart';

import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Screen for users to view their SPA balance and redeem rewards
class SpaRewardScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const SpaRewardScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<SpaRewardScreen> createState() => _SpaRewardScreenState();
}

class _SpaRewardScreenState extends State<SpaRewardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClubSpaService _spaService = ClubSpaService();
  final UserService _userService = UserService.instance;

  Map<String, dynamic>? _userSpaBalance;
  List<Map<String, dynamic>> _availableRewards = [];
  List<Map<String, dynamic>> _spaTransactions = [];
  List<Map<String, dynamic>> _userVouchers = [];
  bool _isLoading = true;
  String? _userId;
  RealtimeChannel? _voucherChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    // Setup subscription after getting userId - will be called in _loadUserData
  }

  @override
  void dispose() {
    _voucherChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    if (_userId == null) return;
    
    // Listen to changes in user_vouchers table for current user only
    _voucherChannel = Supabase.instance.client
        .channel('user_vouchers_${_userId}_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_vouchers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (payload) {
            
            final newStatus = payload.newRecord['status'];
            final voucherCode = payload.newRecord['voucher_code'];
            
            // Show notification based on status change
            if (mounted) {
              if (newStatus == 'used') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Voucher $voucherCode đã được CLB xác nhận sử dụng!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (newStatus == 'cancelled') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Voucher $voucherCode đã bị từ chối'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
            
            // Reload vouchers when any voucher is updated
            _loadUserData();
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
          } else if (error != null) {
          }
        });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user
      final user = await _userService.getCurrentUserProfile();
      if (user == null) return;

      _userId = user.id;

      // Load all data concurrently
      final results = await Future.wait([
        _spaService.getUserSpaBalance(_userId!, widget.clubId),
        _spaService.getClubRewards(widget.clubId),
        _spaService.getUserSpaTransactions(_userId!, widget.clubId),
        _spaService.getUserRedemptions(_userId!, widget.clubId),
      ]);

      setState(() {
        _userSpaBalance = results[0] as Map<String, dynamic>?;
        _availableRewards = results[1] as List<Map<String, dynamic>>;
        _spaTransactions = results[2] as List<Map<String, dynamic>>;
        _userVouchers = results[3] as List<Map<String, dynamic>>;
      });
      
      // Setup realtime subscription after we have userId
      if (_voucherChannel == null && _userId != null) {
        _setupRealtimeSubscription();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    if (_userId == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận đổi thưởng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn đổi phần thưởng này?'),
            const SizedBox(height: 16),
            Text('🎁 ${reward['reward_name']}'),
            Text('💰 Chi phí: ${reward['spa_cost'] ?? 0} SPA'),
            Text(
              '💳 Số dư hiện tại: ${_userSpaBalance?['spa_balance'] ?? 0} SPA',
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
            child: const Text('Xác nhận đổi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    // Show progress dialog with clear message
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // Prevent back button
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with pulse animation
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, double scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          size: 48,
                          color: Colors.green.shade700,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    // Restart animation if dialog still showing
                    if (context.mounted) {
                      Future.delayed(Duration.zero, () {
                        if (context.mounted) {
                          (context as Element).markNeedsBuild();
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đang xử lý đổi thưởng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Vui lòng không tắt ứng dụng\nQuá trình này có thể mất vài giây...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const LinearProgressIndicator(
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await _spaService.redeemReward(
        reward['id'],
        _userId!,
        widget.clubId,
      );

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      if (result != null && result['success'] == true) {
        // Show success dialog with redemption code
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Đổi thưởng thành công!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mã đổi thưởng của bạn:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          result['redemption_code'], overflow: TextOverflow.ellipsis, style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: result['redemption_code']),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã copy mã!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng đưa mã này cho nhân viên câu lạc bộ để nhận thưởng.', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadUserData(); // Refresh data
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Show error dialog with better error messages
        String errorMessage = result?['error'] ?? 'Có lỗi xảy ra khi đổi thưởng';
        
        // Improve error messages for users
        if (errorMessage.contains('Insufficient SPA balance')) {
          errorMessage = 'Số dư SPA không đủ để đổi thưởng này';
        } else if (errorMessage.contains('Reward not found')) {
          errorMessage = 'Không tìm thấy phần thưởng này';
        } else if (errorMessage.contains('out of stock')) {
          errorMessage = 'Phần thưởng đã hết';
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Đổi thưởng không thành công'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SPA của bạn không bị trừ do lỗi đổi thưởng',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadUserData(); // Refresh to show correct balance
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      
      if (!mounted) return;

      // Show detailed error in dialog instead of snackbar
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Lỗi hệ thống'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Đã xảy ra lỗi không mong muốn:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  e.toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vui lòng kiểm tra lại số dư SPA của bạn',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadUserData(); // Refresh data to check actual state
              },
              child: const Text('Làm mới'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SPA Rewards - ${widget.clubName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Số dư'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Đổi thưởng'),
            Tab(icon: Icon(Icons.local_offer), text: 'My Voucher'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBalanceTab(),
                _buildRewardsTab(),
                _buildMyVoucherTab(),
              ],
            ),
    );
  }

  Widget _buildBalanceTab() {
    final balance = _userSpaBalance?['spa_balance'] ?? 0.0;
    final totalEarned = _userSpaBalance?['total_earned'] ?? 0.0;
    final totalSpent = _userSpaBalance?['total_spent'] ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Balance Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Số dư SPA', overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${balance.toStringAsFixed(0)} SPA',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.green),
                          const SizedBox(height: 8),
                          Text('Tổng kiếm được'),
                          Text(
                            '${totalEarned.toStringAsFixed(0)} SPA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.trending_down, color: Colors.orange),
                          const SizedBox(height: 8),
                          Text('Tổng đã dùng'),
                          Text(
                            '${totalSpent.toStringAsFixed(0)} SPA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Transactions
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Giao dịch gần đây',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ..._spaTransactions.take(5).map((transaction) {
                      return _buildTransactionCard(transaction);
                    }),
                    if (_spaTransactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có giao dịch nào',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Các giao dịch SPA sẽ hiển thị tại đây',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: _availableRewards.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_giftcard_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('Chưa có phần thưởng nào'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableRewards.length,
              itemBuilder: (context, index) {
                final reward = _availableRewards[index];
                final userBalance = _userSpaBalance?['spa_balance'] ?? 0.0;
                final spaCost = (reward['spa_cost'] ?? 0) as num;
                final canAfford = userBalance >= spaCost;
                // Check stock availability (available_quantity is the actual column name)
                final availableQty = reward['available_quantity'] as int?;
                final isAvailable = availableQty == null || availableQty > 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        canAfford ? Colors.teal.shade400 : Colors.grey.shade400,
                        canAfford ? Colors.teal.shade600 : Colors.grey.shade600,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: canAfford 
                            ? Colors.teal.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      
                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon and Title Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getRewardIconData(reward['reward_type']),
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reward['reward_name'] ?? 'Phần thưởng',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (reward['description'] != null)
                                        Text(
                                          reward['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 13,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Divider
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Price and Button Row
                            Row(
                              children: [
                                // Price Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.stars_rounded,
                                        color: canAfford ? Colors.teal.shade600 : Colors.grey.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${reward['spa_cost'] ?? 0} SPA',
                                        style: TextStyle(
                                          color: canAfford ? Colors.teal.shade700 : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                if (reward['quantity_available'] != null) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Còn ${availableQty ?? 0}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                const Spacer(),
                                
                                // Redeem Button
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: canAfford && isAvailable
                                        ? [
                                            BoxShadow(
                                              color: Colors.white.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: canAfford && isAvailable
                                        ? () => _redeemReward(reward)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: canAfford 
                                          ? Colors.teal.shade700 
                                          : Colors.grey.shade700,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          !isAvailable
                                              ? Icons.block
                                              : !canAfford
                                                  ? Icons.lock
                                                  : Icons.card_giftcard,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          !isAvailable
                                              ? 'Hết hàng'
                                              : !canAfford
                                                  ? 'Không đủ SPA'
                                                  : 'Đổi thưởng',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }





  IconData _getRewardIconData(String rewardType) {
    switch (rewardType) {
      case 'discount_code':
        return Icons.discount;
      case 'physical_item':
        return Icons.inventory;
      case 'service':
        return Icons.room_service;
      case 'merchandise':
        return Icons.shopping_bag;
      case 'voucher':
        return Icons.card_giftcard;
      default:
        return Icons.card_giftcard;
    }
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final spaAmount = (transaction['spa_amount'] ?? 0) as num;
    final isPositive = spaAmount > 0;
    final description = transaction['description'] ?? 'Giao dịch SPA';
    final createdAt = DateTime.parse(transaction['created_at']);
    
    // Format time nicely
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    String timeText;
    
    if (difference.inDays > 7) {
      timeText = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      timeText = '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      timeText = '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      timeText = '${difference.inMinutes} phút trước';
    } else {
      timeText = 'Vừa xong';
    }

    // Get transaction icon and color based on description
    IconData transactionIcon;
    Color backgroundColor;
    
    if (description.toLowerCase().contains('redeemed')) {
      transactionIcon = Icons.redeem;
      backgroundColor = Colors.purple.withValues(alpha: 0.1);
    } else if (isPositive) {
      transactionIcon = Icons.add_circle_outline;
      backgroundColor = Colors.green.withValues(alpha: 0.1);
    } else {
      transactionIcon = Icons.remove_circle_outline; 
      backgroundColor = Colors.red.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Transaction Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                transactionIcon,
                color: isPositive ? Colors.green[700] : Colors.red[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTransactionDescription(description),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeText,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // SPA Amount
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${spaAmount.toStringAsFixed(0)} SPA',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTransactionDescription(String description) {
    // Handle "null SPA" cases and improve formatting
    if (description.toLowerCase().contains('null spa')) {
      return 'Đổi thưởng thành công';
    }
    
    if (description.toLowerCase().contains('redeemed reward')) {
      final parts = description.split(':');
      if (parts.length > 1) {
        final rewardName = parts[1].trim();
        return 'Đã đổi thưởng: $rewardName';
      }
    }
    
    return description;
  }

  Widget _buildMyVoucherTab() {
    // Separate vouchers by status
    final activeVouchers = _userVouchers.where((v) => 
      v['status'] == 'active' || v['status'] == 'claimed'
    ).toList();
    
    final usedVouchers = _userVouchers.where((v) => 
      v['status'] == 'used'
    ).toList();
    
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Sẵn sàng', icon: Icon(Icons.check_circle)),
              Tab(text: 'Đã sử dụng', icon: Icon(Icons.history)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildVoucherList(activeVouchers, 'Chưa có voucher sẵn sàng'),
                _buildVoucherList(usedVouchers, 'Chưa có voucher đã sử dụng'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList(List<Map<String, dynamic>> vouchers, String emptyMessage) {
    if (vouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          return _buildVoucherCard(vouchers[index]);
        },
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final String voucherCode = voucher['voucher_code'] ?? 'N/A';
    // Get reward name from spa_rewards relation or fallback to direct field
    final String rewardName = voucher['spa_rewards']?['reward_name'] ?? 
                              voucher['reward_name'] ?? 
                              'Voucher';
    final String status = voucher['status'] ?? 'claimed'; // Mặc định là đã claim
    final DateTime? redeemedAt = voucher['redeemed_at'] != null
        ? DateTime.parse(voucher['redeemed_at'])
        : null;

    Color statusColor;
    String statusText;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Chờ xử lý';
        break;
      case 'approved':
        statusColor = Colors.blue;
        statusText = 'Đã gửi CLB';  // User đã gửi yêu cầu, chờ CLB xác nhận
        break;
      case 'claimed':
        statusColor = Colors.green;
        statusText = 'Sẵn sàng';
        break;
      case 'used':
        statusColor = Colors.purple;
        statusText = 'Đã sử dụng';
        break;
      case 'expired':
        statusColor = Colors.grey;
        statusText = 'Hết hạn';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Đã hủy';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
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
                Icon(Icons.local_offer, color: Colors.teal, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rewardName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã: $voucherCode',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (redeemedAt != null) 
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Ngày đổi: ${redeemedAt.day}/${redeemedAt.month}/${redeemedAt.year}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildVoucherActionButton(voucher, status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showVoucherDetailsDialog(voucher);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Chi tiết'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUseVoucherDialog(Map<String, dynamic> voucher) {
    final rewardName = voucher['spa_rewards']?['reward_name'] ?? 
                       voucher['reward_name'] ?? 
                       'N/A';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sử dụng voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎁 $rewardName'),
            const SizedBox(height: 8),
            Text('📋 Mã voucher: ${voucher['voucher_code'] ?? 'N/A'}'),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Sau khi sử dụng, mã voucher này sẽ được gửi đến CLB để xác nhận và không thể hoàn tác.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              '✅ CLB sẽ xác nhận và cập nhật trạng thái voucher.',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _useVoucher(voucher);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận sử dụng'),
          ),
        ],
      ),
    );
  }

  Future<void> _useVoucher(Map<String, dynamic> voucher) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Đang gửi mã đến CLB...'),
          ],
        ),
      ),
    );

    try {
      // Lấy thông tin user hiện tại
      final currentUser = await _userService.getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('Không thể xác định người dùng');
      }

      // ✅ DIRECT CLUB_VOUCHER_REQUESTS APPROACH
      ProductionLogger.info('🔧 DEBUG: Creating record directly in club_voucher_requests', tag: 'spa_reward_screen');
      ProductionLogger.info('   Voucher data: $voucher', tag: 'spa_reward_screen');
      
      Map<String, dynamic> result;
      
      try {
        // Extract voucher data
        final redemptionId = voucher['id'];
        final voucherCode = voucher['voucher_code'] ?? voucher['redemption_code'];
        final spaValue = (voucher['spa_spent'] ?? 
                         voucher['rewards']?['value'] ?? 
                         voucher['spa_cost'] ?? 
                         0) as num;
        
        ProductionLogger.info('   RedemptionId: $redemptionId', tag: 'spa_reward_screen');
        ProductionLogger.info('   VoucherCode: $voucherCode', tag: 'spa_reward_screen');
        ProductionLogger.info('   SpaValue: $spaValue', tag: 'spa_reward_screen');
        ProductionLogger.info('   ClubId: ${widget.clubId}', tag: 'spa_reward_screen');
        
        // 🎯 NEW APPROACH: Create user_voucher first, then use its ID
        var voucherId = voucher['voucher_id'];
        
        if (voucherId == null) {
          ProductionLogger.info('⚠️ No voucher_id link, finding or creating user_voucher...', tag: 'spa_reward_screen');
          
          try {
            // First try to find existing user_voucher by voucher_code
            final existing = await Supabase.instance.client
                .from('user_vouchers')
                .select('id')
                .eq('voucher_code', voucherCode)
                .maybeSingle();
            
            if (existing != null) {
              voucherId = existing['id'];
              ProductionLogger.info('✅ Found existing user_voucher: $voucherId', tag: 'spa_reward_screen');
              
              // Update redemption with the found voucher_id
              await Supabase.instance.client
                  .from('spa_reward_redemptions')
                  .update({'voucher_id': voucherId})
                  .eq('id', redemptionId);
              
              ProductionLogger.info('🔗 Updated redemption with voucher_id', tag: 'spa_reward_screen');
            } else {
              // Create new user_voucher if not exists
              final newUserVoucher = await Supabase.instance.client
                  .from('user_vouchers')
                  .insert({
                    'user_id': currentUser.id,
                    'club_id': widget.clubId,
                    'voucher_code': voucherCode,
                    'status': 'active',
                    'issue_reason': 'spa_redemption',
                    'issue_details': {
                      'redemption_id': redemptionId,
                      'spa_spent': spaValue,
                    },
                    'rewards': {
                      'type': 'spa_voucher',
                      'value': spaValue,
                    },
                    'issued_at': DateTime.now().toIso8601String(),
                    'expires_at': DateTime.now().add(Duration(days: 90)).toIso8601String(),
                  })
                  .select()
                  .single();
              
              voucherId = newUserVoucher['id'];
              ProductionLogger.info('✅ Created new user_voucher: $voucherId', tag: 'spa_reward_screen');
              
              // Update redemption with voucher_id link
              await Supabase.instance.client
                  .from('spa_reward_redemptions')
                  .update({'voucher_id': voucherId})
                  .eq('id', redemptionId);
              
              ProductionLogger.info('🔗 Linked redemption to voucher', tag: 'spa_reward_screen');
            }
          } catch (e) {
            ProductionLogger.info('⚠️ Error finding/creating user_voucher: $e', tag: 'spa_reward_screen');
            // Continue anyway, might be race condition
          }
        }
        
        ProductionLogger.info('   VoucherId (user_vouchers): $voucherId', tag: 'spa_reward_screen');
        
        // Now create club_voucher_request
        final directResult = await Supabase.instance.client
            .from('club_voucher_requests')
            .insert({
              'voucher_id': voucherId,
              'voucher_code': voucherCode,
              'user_id': currentUser.id,
              'user_email': currentUser.email,
              'user_name': currentUser.fullName,
              'club_id': widget.clubId,
              'spa_value': spaValue,
              'status': 'pending',
              'voucher_type': 'spa_redemption',
            })
            .select()
            .single();
        
        ProductionLogger.info('🎯 Direct creation result: $directResult', tag: 'spa_reward_screen');
        
        result = {
          'success': true,
          'message': 'Voucher request submitted successfully',
          'auto_approved': false,
          'request_id': directResult['id'],
        };
        
        ProductionLogger.info('🎯 Final result: $result', tag: 'spa_reward_screen');
      } catch (e) {
        ProductionLogger.info('❌ Direct creation error: $e', tag: 'spa_reward_screen');
        result = {
          'success': false,
          'message': 'Failed to submit voucher request: $e',
        };
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (result['success']) {
        // ✅ PROFESSIONAL SUCCESS MODAL
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '🎉 Gửi voucher thành công!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.confirmation_number, color: Colors.blue.shade600),
                              const SizedBox(width: 8),
                              const Text('Mã voucher:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              voucher['voucher_code'] ?? voucher['redemption_code'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade600),
                              const SizedBox(width: 8),
                              const Text('Trạng thái yêu cầu:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result['auto_approved'] == true 
                              ? '✅ Đã được duyệt tự động' 
                              : '⏳ Đang chờ CLB xác nhận',
                            style: TextStyle(
                              fontSize: 14,
                              color: result['auto_approved'] == true ? Colors.green.shade700 : Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (result['auto_approved'] != true) ...[
                            const SizedBox(height: 8),
                            Text(
                              'CLB sẽ xem xét và phản hồi trong vòng 24h.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadUserData(); // Refresh data
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đã hiểu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('❌ Lỗi'),
              content: Text(result['message']),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Lỗi'),
            content: Text('Có lỗi xảy ra: $e'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showVoucherDetailsDialog(Map<String, dynamic> voucher) {
    final rewardName = voucher['spa_rewards']?['reward_name'] ?? 
                       voucher['reward_name'] ?? 
                       'N/A';
    final rewardDescription = voucher['spa_rewards']?['description'] ?? 
                              voucher['reward_description'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎁 $rewardName'),
            const SizedBox(height: 8),
            Text('📋 Mã: ${voucher['voucher_code'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('📅 Ngày đổi: ${voucher['redeemed_at'] != null ? DateTime.parse(voucher['redeemed_at']).toLocal().toString().split(' ')[0] : 'N/A'}'),
            const SizedBox(height: 8),
            Text('📋 Trạng thái: ${_getStatusText(voucher['status'] ?? 'claimed')}'),
            if (rewardDescription != null) ...[
              const SizedBox(height: 8),
              Text('📝 Mô tả: $rewardDescription'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: voucher['voucher_code'] ?? ''));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã copy mã voucher!')),
              );
            },
            child: const Text('Copy mã'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'approved':
        return 'Đã gửi CLB';  // User đã gửi yêu cầu, chờ CLB confirm
      case 'claimed':
        return 'Sẵn sàng';
      case 'used':
        return 'Đã sử dụng';
      case 'expired':
        return 'Hết hạn';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Widget _buildVoucherActionButton(Map<String, dynamic> voucher, String status) {
    // Status: pending, approved, claimed, used, expired, cancelled
    switch (status) {
      case 'claimed':
        // Voucher sẵn sàng - có thể sử dụng
        return ElevatedButton.icon(
          onPressed: () => _showUseVoucherDialog(voucher),
          icon: const Icon(Icons.redeem, size: 16),
          label: const Text('Sử dụng'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        );
      case 'approved':
        // Đã gửi yêu cầu đến CLB - chờ xác nhận
        return ElevatedButton.icon(
          onPressed: null,  // Disable - chờ club confirm
          icon: const Icon(Icons.schedule_send, size: 16),
          label: const Text('Đã gửi CLB'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            disabledBackgroundColor: Colors.blue.shade100,
            disabledForegroundColor: Colors.blue.shade700,
          ),
        );
      case 'used':
        // Đã sử dụng - hiển thị trạng thái
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle, size: 16),
          label: const Text('Đã sử dụng'),
        );
      case 'expired':
        // Hết hạn - hiển thị trạng thái
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.timer_off, size: 16),
          label: const Text('Hết hạn'),
        );
      case 'cancelled':
        // Đã hủy - hiển thị trạng thái
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.cancel, size: 16),
          label: const Text('Đã hủy'),
        );
      default:
        // pending - chưa duyệt
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_empty, size: 16),
          label: Text(_getStatusText(status)),
        );
    }
  }

}

