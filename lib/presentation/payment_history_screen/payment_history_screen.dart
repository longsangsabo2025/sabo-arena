import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import 'package:intl/intl.dart';
import '../../services/payment_method_service.dart';
import '../../services/auth_service.dart';
import '../../models/payment_method.dart';
import '../../core/design_system/design_system.dart';
import '../../widgets/empty_state_widget.dart';

/// Payment History Screen
/// Shows all user payments with filtering and search
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _paymentService = PaymentMethodService.instance;
  final _searchController = TextEditingController();

  List<TournamentPayment> _allPayments = [];
  List<TournamentPayment> _filteredPayments = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, pending, verified, rejected

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // Get all user payments
      final payments = await _paymentService.getUserPayments(userId);

      setState(() {
        _allPayments = payments;
        _filteredPayments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterPayments() {
    setState(() {
      _filteredPayments = _allPayments.where((payment) {
        // Filter by status
        if (_selectedFilter != 'all' &&
            payment.status.value != _selectedFilter) {
          return false;
        }

        // Filter by search query
        final query = _searchController.text.toLowerCase();
        if (query.isNotEmpty) {
          return payment.tournamentId.toLowerCase().contains(query) ||
              (payment.transactionReference?.toLowerCase().contains(query) ??
                  false);
        }

        return true;
      }).toList();

      // Sort by created date (newest first)
      _filteredPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử thanh toán'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: EdgeInsets.all(DesignTokens.space16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo giải đấu hoặc mã GD',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterPayments();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                  ),
                  onChanged: (value) => _filterPayments(),
                ),

                SizedBox(height: 12.h),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'all', _allPayments.length),
                      SizedBox(width: DesignTokens.space8),
                      _buildFilterChip(
                        'Chờ xác nhận',
                        'pending',
                        _allPayments
                            .where((p) => p.status.value == 'pending')
                            .length,
                      ),
                      SizedBox(width: DesignTokens.space8),
                      _buildFilterChip(
                        'Đã xác nhận',
                        'verified',
                        _allPayments
                            .where((p) => p.status.value == 'verified')
                            .length,
                      ),
                      SizedBox(width: DesignTokens.space8),
                      _buildFilterChip(
                        'Từ chối',
                        'rejected',
                        _allPayments
                            .where((p) => p.status.value == 'rejected')
                            .length,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Payment list
          Expanded(
            child: _isLoading
                ? const Center(child: DSSpinner(size: DSSpinnerSize.medium))
                : _filteredPayments.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadPayments,
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: EdgeInsets.all(DesignTokens.space16),
                      itemCount: _filteredPayments.length,
                      itemBuilder: (context, index) {
                        return _buildPaymentCard(_filteredPayments[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _filterPayments();
        });
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildPaymentCard(TournamentPayment payment) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
          onTap: () => _showPaymentDetails(payment),
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Status badge and amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(payment.status),
                    Text(
                      _formatCurrency(payment.amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: DesignTokens.space12),

                // Tournament info
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: DesignTokens.space8),
                    Expanded(
                      child: Text(
                        'Giải đấu: ${payment.tournamentId}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: DesignTokens.space8),

                // Payment method
                Row(
                  children: [
                    Icon(Icons.payment, size: 20, color: AppColors.textSecondary),
                    SizedBox(width: DesignTokens.space8),
                    Text(
                      _getPaymentMethodName(payment.paymentMethodId),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: DesignTokens.space8),

                // Date
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: DesignTokens.space8),
                    Text(
                      _formatDate(payment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Transaction reference (if available)
                if (payment.transactionReference != null) ...[
                  SizedBox(height: DesignTokens.space8),
                  Row(
                    children: [
                      Icon(Icons.tag, size: 20, color: AppColors.textSecondary),
                      SizedBox(width: DesignTokens.space8),
                      Expanded(
                        child: Text(
                          'Mã GD: ${payment.transactionReference}',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PaymentStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case PaymentStatus.verified:
        color = AppColors.success;
        label = 'Đã xác nhận';
        icon = Icons.check_circle;
        break;
      case PaymentStatus.rejected:
        color = AppColors.error;
        label = 'Từ chối';
        icon = Icons.cancel;
        break;
      case PaymentStatus.verifying:
        color = AppColors.info;
        label = 'Đang xác minh';
        icon = Icons.hourglass_empty;
        break;
      case PaymentStatus.pending:
      default:
        color = AppColors.warning;
        label = 'Chờ xác nhận';
        icon = Icons.pending;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: DesignTokens.space4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.receipt_long,
      message: 'Chưa có giao dịch nào',
      subtitle: 'Lịch sử thanh toán sẽ hiển thị ở đây',
    );
  }

  void _showPaymentDetails(TournamentPayment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(DesignTokens.space24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chi tiết thanh toán',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Status
            _buildDetailRow(
              'Trạng thái',
              '',
              customValue: _buildStatusBadge(payment.status),
            ),

            // Amount
            _buildDetailRow('Số tiền', _formatCurrency(payment.amount)),

            // Tournament
            _buildDetailRow('Giải đấu', payment.tournamentId),

            // Payment method
            _buildDetailRow(
              'Phương thức',
              _getPaymentMethodName(payment.paymentMethodId),
            ),

            // Transaction reference
            if (payment.transactionReference != null)
              _buildDetailRow('Mã giao dịch', payment.transactionReference!),

            // Created date
            _buildDetailRow('Ngày tạo', _formatDate(payment.createdAt)),

            // Verified date
            if (payment.verifiedAt != null)
              _buildDetailRow(
                'Ngày xác nhận',
                _formatDate(payment.verifiedAt!),
              ),

            // Rejection reason
            if (payment.rejectionReason != null)
              _buildDetailRow(
                'Lý do từ chối',
                payment.rejectionReason!,
                isError: true,
              ),

            // Transaction note
            if (payment.transactionNote != null)
              _buildDetailRow('Ghi chú', payment.transactionNote!),

            SizedBox(height: DesignTokens.space20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Widget? customValue,
    bool isError = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child:
                customValue ??
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isError ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _getPaymentMethodName(String? type) {
    switch (type) {
      case 'momo':
        return 'MoMo';
      case 'zalopay':
        return 'ZaloPay';
      case 'vnpay':
        return 'VNPay';
      default:
        return 'Chuyển khoản';
    }
  }
}
