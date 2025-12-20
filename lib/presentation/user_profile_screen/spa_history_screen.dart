import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/common/app_button.dart';

/// Screen hiển thị lịch sử giao dịch SPA của user
class SpaHistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const SpaHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<SpaHistoryScreen> createState() => _SpaHistoryScreenState();
}

class _SpaHistoryScreenState extends State<SpaHistoryScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _spaHistory = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSpaHistory();
  }

  Future<void> _loadSpaHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('spa_transactions')
          .select('*')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      setState(() {
        _spaHistory = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải lịch sử SPA: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử SPA Points',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Thử lại',
                          type: AppButtonType.primary,
                          size: AppButtonSize.medium,
                          onPressed: _loadSpaHistory,
                        ),
                      ],
                    ),
                  ),
                )
              : _spaHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có lịch sử giao dịch SPA',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSpaHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _spaHistory.length,
                        itemBuilder: (context, index) {
                          final record = _spaHistory[index];
                          return _buildSpaHistoryCard(record);
                        },
                      ),
                    ),
    );
  }

  Widget _buildSpaHistoryCard(Map<String, dynamic> record) {
    final amount = record['amount'] as int? ?? 0;
    final balanceBefore = record['balance_before'] as int? ?? 0;
    final balanceAfter = record['balance_after'] as int? ?? 0;
    final transactionType = record['transaction_type'] as String? ?? '';
    final description = record['description'] as String? ?? '';
    final createdAt = DateTime.parse(record['created_at'] as String);

    final isPositive = amount > 0;
    final changeColor = isPositive ? Colors.green : Colors.red;
    final changeIcon = isPositive ? Icons.add_circle : Icons.remove_circle;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Type + Amount
            Row(
              children: [
                // Icon for transaction type
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTransactionIcon(transactionType),
                    size: 24,
                    color: changeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTransactionTypeText(transactionType),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 13, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: changeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(changeIcon, size: 16, color: changeColor),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${_formatNumber(amount)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Description
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Balance Change: Before → After
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Balance Before
                  Column(
                    children: [
                      Text(
                        'Số dư trước',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.stars,
                              size: 16, color: Color(0xFFFFA726)),
                          const SizedBox(width: 4),
                          Text(
                            _formatNumber(balanceBefore),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.arrow_forward,
                        size: 20, color: Colors.grey[600]),
                  ),

                  // Balance After
                  Column(
                    children: [
                      Text(
                        'Số dư sau',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: changeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.stars, size: 16, color: changeColor),
                          const SizedBox(width: 4),
                          Text(
                            _formatNumber(balanceAfter),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: changeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'tournament_reward':
        return Icons.emoji_events;
      case 'tournament_bonus':
        return Icons.card_giftcard;
      case 'challenge_win':
        return Icons.military_tech;
      case 'challenge_loss':
        return Icons.trending_down;
      case 'challenge_bonus':
        return Icons.stars;
      case 'reward_redemption':
        return Icons.redeem;
      case 'admin_adjustment':
        return Icons.settings;
      case 'refund':
        return Icons.refresh;
      default:
        return Icons.swap_horiz;
    }
  }

  String _getTransactionTypeText(String type) {
    switch (type) {
      case 'tournament_reward':
        return '🏆 Thưởng giải đấu';
      case 'tournament_bonus':
        return '🎁 Bonus giải đấu';
      case 'challenge_win':
        return '⚔️ Thắng Challenge';
      case 'challenge_loss':
        return '💔 Thua Challenge';
      case 'challenge_bonus':
        return '✨ Bonus Challenge';
      case 'reward_redemption':
        return '🎁 Đổi thưởng';
      case 'admin_adjustment':
        return '🔧 Điều chỉnh';
      case 'refund':
        return '↩️ Hoàn trả';
      default:
        return type;
    }
  }

  String _formatNumber(int number) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(number);
  }
}
