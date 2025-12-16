import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/tournament_prize_voucher_service.dart';
import '../../theme/app_theme.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Screen quản lý Prize Voucher cho CLB
/// Prize Voucher = Voucher tiền mặt VNĐ dùng cho giải đấu
class ClubPrizeVoucherScreen extends StatefulWidget {
  final String clubId;

  const ClubPrizeVoucherScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<ClubPrizeVoucherScreen> createState() => _ClubPrizeVoucherScreenState();
}

class _ClubPrizeVoucherScreenState extends State<ClubPrizeVoucherScreen> {
  final TournamentPrizeVoucherService _service = TournamentPrizeVoucherService();
  List<Map<String, dynamic>> _prizeVouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrizeVouchers();
  }

  Future<void> _loadPrizeVouchers() async {
    setState(() => _isLoading = true);
    try {
      final vouchers = await _service.getClubPrizeVouchers(widget.clubId);
      setState(() {
        _prizeVouchers = vouchers;
        _isLoading = false;
      });
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Prize Voucher',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryLight,
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prizeVouchers.isEmpty
              ? _buildEmptyState()
              : _buildVoucherList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments, size: 20.w, color: Colors.grey[400]),
            SizedBox(height: 4.w),
            Text(
              'Chưa có Prize Voucher',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 2.w),
            Text(
              'Prize Voucher được tạo tự động khi bạn\ntạo giải đấu và cấu hình voucher tiền mặt\ncho giải thưởng',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.w),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.green[700], size: 5.w),
                      SizedBox(width: 2.w),
                      Text(
                        'Cách tạo Prize Voucher:',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.w),
                  _buildHelpStep('1', 'Tạo giải đấu mới'),
                  _buildHelpStep('2', 'Đến Bước 3: Giải thưởng'),
                  _buildHelpStep('3', 'Chọn "Thêm Voucher" cho hạng thưởng'),
                  _buildHelpStep('4', 'Chọn loại "PRIZE Voucher"'),
                  _buildHelpStep('5', 'Nhập giá trị VNĐ (300K-1M)'),
                  _buildHelpStep('6', 'Hoàn tất tạo giải đấu'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w, bottom: 1.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5.w,
            height: 5.w,
            decoration: BoxDecoration(
              color: Colors.green[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.green[900],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList() {
    // Group by tournament
    final groupedVouchers = <String, List<Map<String, dynamic>>>{};
    for (var voucher in _prizeVouchers) {
      final tournamentId = voucher['tournament_id'] as String;
      groupedVouchers.putIfAbsent(tournamentId, () => []);
      groupedVouchers[tournamentId]!.add(voucher);
    }

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        // Summary Card
        _buildSummaryCard(),
        SizedBox(height: 4.w),

        // Voucher Groups
        ...groupedVouchers.entries.map((entry) {
          return _buildTournamentGroup(entry.key, entry.value);
        }),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final totalVouchers = _prizeVouchers.length;
    final totalValue = _prizeVouchers.fold<double>(
      0,
      (sum, v) => sum + ((v['voucher_value'] as num?)?.toDouble() ?? 0),
    );

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.payments, color: Colors.white, size: 10.w),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng Prize Voucher',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 1.w),
                Text(
                  '$totalVouchers voucher',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(totalValue / 1000).toStringAsFixed(0)}K VNĐ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentGroup(String tournamentId, List<Map<String, dynamic>> vouchers) {
    final tournamentName = vouchers.first['tournament_name'] as String? ?? 'Giải đấu';
    
    return Container(
      margin: EdgeInsets.only(bottom: 4.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.green[700], size: 6.w),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    tournamentName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${vouchers.length} voucher',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vouchers
          ...vouchers.map((voucher) => _buildVoucherItem(voucher)),
        ],
      ),
    );
  }

  Widget _buildVoucherItem(Map<String, dynamic> voucher) {
    final position = voucher['position'] as int;
    final positionLabel = voucher['position_label'] as String? ?? 'Top $position';
    final value = (voucher['voucher_value'] as num?)?.toDouble() ?? 0;
    final codePrefix = voucher['code_prefix'] as String? ?? 'PRIZE';
    final validDays = voucher['valid_days'] as int? ?? 30;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Position Badge
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: _getPositionColor(position),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$position',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),

          // Voucher Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  positionLabel,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 1.w),
                Row(
                  children: [
                    Icon(Icons.payments, size: 4.w, color: Colors.green),
                    SizedBox(width: 1.w),
                    Text(
                      '${(value / 1000).toStringAsFixed(0)}K VNĐ',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.w),
                Text(
                  'Code: $codePrefix-xxx • Hạn: $validDays ngày',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return Colors.blue;
    }
  }
}

