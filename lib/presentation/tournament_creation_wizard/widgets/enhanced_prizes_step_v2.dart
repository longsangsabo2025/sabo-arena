import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';
import '../../../core/constants/ranking_constants.dart';
import '../../../core/design_system/design_system.dart';
import '../../../models/voucher_campaign.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enhanced Prizes Step with:
/// - Prize distribution templates
/// - Custom prize allocation
/// - Physical prizes
/// - Voucher rewards
/// - Requirements (from Step 1 UI style)
class EnhancedPrizesStepV2 extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;

  const EnhancedPrizesStepV2({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<EnhancedPrizesStepV2> createState() => _EnhancedPrizesStepV2State();
}

class _EnhancedPrizesStepV2State extends State<EnhancedPrizesStepV2> {
  final _entryFeeController = TextEditingController();
  final _totalPrizeController = TextEditingController();

  String _selectedTemplate = 'top_3'; // top_3, top_4, top_8, custom
  List<PrizeItem> _prizes = [];

  // Requirements (from Step 1)
  String? _minRank;
  String? _maxRank;

  // Voucher support - NEW SYSTEM with approved campaigns
  List<VoucherCampaign> _availableVouchers = [];
  bool _isLoadingVouchers = false;

  // Input mode: 'percentage' or 'amount'
  String _inputMode = 'percentage';

  final List<String> _saboRanks = RankingConstants.RANK_ORDER;

  // 🚀 ELON MODE: Validation helpers
  bool get _hasValidCustomPrizes {
    if (_selectedTemplate != 'custom') return true;
    return _prizes.any((p) => p.cashAmount > 0 || p.percentage > 0);
  }

  double get _totalPercentage {
    return _prizes.fold<double>(0, (sum, prize) => sum + prize.percentage);
  }

  String? get _validationError {
    if (_selectedTemplate == 'custom' && !_hasValidCustomPrizes) {
      return 'Vui lòng nhập ít nhất 1 giải thưởng với giá trị > 0';
    }
    if (_totalPercentage > 100) {
      final totalPrize = double.tryParse(_totalPrizeController.text) ?? 0;
      final totalDistributed =
          _prizes.fold<int>(0, (sum, p) => sum + p.cashAmount);
      return 'Tổng giải thưởng vượt quá prize pool!\n'
          'Đang chia: ${_formatCurrency(totalDistributed)} VND\n'
          'Prize pool: ${_formatCurrency(totalPrize.toInt())} VND\n'
          '→ Giảm giải thưởng hoặc tăng prize pool';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadApprovedVouchers();
  }

  /// Load approved voucher campaigns from new system
  Future<void> _loadApprovedVouchers() async {
    setState(() => _isLoadingVouchers = true);
    try {
      final clubId = widget.data['clubId'];
      if (clubId != null) {
        final supabase = Supabase.instance.client;

        // Query approved voucher campaigns for this club
        final response = await supabase
            .from('voucher_campaigns')
            .select()
            .eq('club_id', clubId)
            .eq('approval_status', 'approved')
            .gte('end_date', DateTime.now().toIso8601String())
            .order('created_at', ascending: false);

        final campaigns = (response as List)
            .map((json) => VoucherCampaign.fromJson(json))
            .toList();

        setState(() {
          _availableVouchers = campaigns;
        });

        // Voucher campaigns loaded successfully
      }
    } catch (e) {
      // Error loading vouchers - non-critical, continue
    } finally {
      setState(() => _isLoadingVouchers = false);
    }
  }

  void _initializeData() {
    _entryFeeController.text = (widget.data['entryFee'] ?? 0).toString();
    _totalPrizeController.text = (widget.data['totalPrize'] ?? 0).toString();
    _selectedTemplate = widget.data['prizeTemplate'] ?? 'top_3';
    _minRank = widget.data['minRank'];
    _maxRank = widget.data['maxRank'];

    // Load prizes or use template
    if (widget.data['prizes'] != null) {
      _prizes = (widget.data['prizes'] as List)
          .map((p) => PrizeItem.fromMap(p))
          .toList();
    } else {
      _applyTemplateWithoutUpdate(_selectedTemplate);
    }
  }

  void _updateData() {
    // Defer setState to after build is complete
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 🚀 CRITICAL FIX: Only set customDistribution if template is actually 'custom'
        // Otherwise we pass template data as "custom" which causes confusion
        final customDist = _selectedTemplate == 'custom'
            ? _prizes.map((p) => p.toMap()).toList()
            : null;

        // Validation code commented for production - keeping for reference
        // bool hasValidPrizes = false;
        // if (customDist != null) {
        //   hasValidPrizes = customDist.any((prize) {
        //     final cashAmount = prize['cashAmount'] as int? ?? 0;
        //     final percentage = prize['percentage'] as num? ?? 0;
        //     return cashAmount > 0 || percentage > 0;
        //   });
        // }

        // Debug logging (commented for production)
        // print('🚀 [PRIZE STEP] Updating data:');
        // print('  Template: $_selectedTemplate');
        // print('  Prizes count: ${_prizes.length}');
        // print('  CustomDistribution: ${customDist != null ? "SET (${customDist.length} items)" : "NULL"}');
        // if (customDist != null) {
        //   print('  Custom values: ${customDist.map((p) => "${p['position']}: ${p['cashAmount']}").join(", ")}');
        //   print('  Has valid prizes: $hasValidPrizes');
        //   if (!hasValidPrizes) {
        //     print('  ⚠️ WARNING: Custom template selected but ALL values are ZERO!');
        //     print('  ⚠️ System will fallback to top_3 template to prevent broken tournament');
        //   }
        // }

        widget.onDataChanged({
          'entryFee': double.tryParse(_entryFeeController.text) ?? 0,
          'totalPrize': double.tryParse(_totalPrizeController.text) ?? 0,
          'prizePool': double.tryParse(_totalPrizeController.text) ??
              0, // Đảm bảo prizePool được cập nhật
          'prizeTemplate': _selectedTemplate,
          'prizes': _prizes.map((p) => p.toMap()).toList(),
          'customDistribution': customDist,
          'minRank': _minRank,
          'maxRank': _maxRank,
        });
        setState(() {});
      }
    });
  }

  // Apply template WITHOUT triggering setState (safe for initState)
  void _applyTemplateWithoutUpdate(String template) {
    switch (template) {
      case 'top_3':
        _prizes = [
          PrizeItem(position: 1, percentage: 50, cashAmount: 0),
          PrizeItem(position: 2, percentage: 30, cashAmount: 0),
          PrizeItem(position: 3, percentage: 20, cashAmount: 0),
        ];
        break;
      case 'top_4':
        // Đồng hạng 3: 2 người cùng hạng 3 (không có hạng 4)
        _prizes = [
          PrizeItem(position: 1, percentage: 40, cashAmount: 0),
          PrizeItem(position: 2, percentage: 30, cashAmount: 0),
          PrizeItem(
              position: 3,
              percentage: 15,
              cashAmount: 0), // Đồng hạng 3 - người thứ nhất
          PrizeItem(
              position: 3,
              percentage: 15,
              cashAmount: 0), // Đồng hạng 3 - người thứ hai
        ];
        break;
      case 'top_8':
        _prizes = [
          PrizeItem(position: 1, percentage: 35, cashAmount: 0),
          PrizeItem(position: 2, percentage: 25, cashAmount: 0),
          PrizeItem(position: 3, percentage: 15, cashAmount: 0),
          PrizeItem(position: 5, percentage: 10, cashAmount: 0), // Hạng 5
          PrizeItem(position: 5, percentage: 5, cashAmount: 0), // Đồng hạng 5
          PrizeItem(position: 5, percentage: 5, cashAmount: 0), // Đồng hạng 5
          PrizeItem(position: 5, percentage: 2.5, cashAmount: 0), // Đồng hạng 5
          PrizeItem(position: 5, percentage: 2.5, cashAmount: 0), // Đồng hạng 5
        ];
        break;
      case 'custom':
        _prizes = [PrizeItem(position: 1, percentage: 0, cashAmount: 0)];
        break;
    }
    // Calculate amounts but DON'T call _updateData
    final totalPrize = double.tryParse(_totalPrizeController.text) ?? 0;
    for (var prize in _prizes) {
      prize.cashAmount = (totalPrize * prize.percentage / 100).round();
    }
  }

  // Apply template WITH update (triggers setState)
  void _applyTemplate(String template) {
    _applyTemplateWithoutUpdate(template);
    _calculatePrizes();
  }

  void _calculatePrizes() {
    final totalPrize = double.tryParse(_totalPrizeController.text) ?? 0;
    for (var prize in _prizes) {
      prize.cashAmount = (totalPrize * prize.percentage / 100).round();
    }
    _updateData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          // Compact header
          _buildCompactHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Financial Info Card
                  _buildFinancialCard(),

                  SizedBox(height: 16.h),

                  // Prize Distribution Card
                  _buildPrizeDistributionCard(),

                  SizedBox(height: 16.h),

                  // Requirements Card (from Step 1 style)
                  _buildRequirementsCard(),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appTheme.primary,
            context.appTheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.textOnPrimary, size: 16),
                  SizedBox(width: 6.w),
                  Text(
                    'BƯỚC 3/4',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.check_circle,
                      color: AppColors.textOnPrimary, size: 14),
                  SizedBox(width: 4.w),
                  Text(
                    '75%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Tài chính & Giải thưởng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.75,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.appTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_money, color: context.appTheme.primary),
                SizedBox(width: 12.w),
                Text(
                  'Thông tin tài chính',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Entry Fee
                _buildMoneyField(
                  label: 'Phí đăng ký',
                  controller: _entryFeeController,
                  icon: Icons.payment,
                  hint: '0',
                  helper: 'Để 0 nếu miễn phí',
                ),

                SizedBox(height: 16.h),

                // Total Prize
                _buildMoneyField(
                  label: 'Tổng giải thưởng',
                  controller: _totalPrizeController,
                  icon: Icons.emoji_events,
                  hint: '0',
                  helper: 'Có thể để 0 nếu chưa xác định',
                  isRequired: true,
                  onChanged: (value) => _calculatePrizes(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? helper,
    bool isRequired = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: context.appTheme.primary, size: 18),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            suffixText: 'VNĐ',
            filled: true,
            fillColor: AppColors.gray50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appTheme.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
          onChanged: onChanged,
        ),
        if (helper != null)
          Padding(
            padding: EdgeInsets.only(top: 6.h, left: 12.w),
            child: Text(
              helper,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  Widget _buildPrizeDistributionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.appTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.pie_chart, color: context.appTheme.primary),
                SizedBox(width: 12.w),
                Text(
                  'Phân bổ giải thưởng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Template selector
                Text(
                  'Chọn mẫu phân bổ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12.h),

                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _buildTemplateChip('Top 3', 'top_3'),
                    _buildTemplateChip('Đồng hạng 3', 'top_4'),
                    _buildTemplateChip('Top 8', 'top_8'),
                    _buildTemplateChip('Tùy chỉnh', 'custom'),
                  ],
                ),

                // 🚨 VALIDATION WARNING
                if (_validationError != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700, size: 20),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Input mode toggle (only for custom template)
                if (_selectedTemplate == 'custom') ...[
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.info50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.info100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cách nhập giải thưởng',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child:
                                  _buildInputModeButton('Nhập %', 'percentage'),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildInputModeButton(
                                  'Nhập số tiền', 'amount'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 20.h),

                // Prize list
                ..._prizes.asMap().entries.map((entry) {
                  return _buildPrizeItem(entry.key, entry.value);
                }),

                // Add prize button (custom mode)
                if (_selectedTemplate == 'custom')
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _prizes.add(
                          PrizeItem(
                            position: _prizes.length + 1,
                            percentage: 0,
                            cashAmount: 0,
                          ),
                        );
                      });
                    },
                    icon: Icon(Icons.add_circle_outline),
                    label: Text('Thêm hạng thưởng'),
                  ),

                // Total check
                SizedBox(height: 16.h),
                _buildTotalCheck(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(String label, String value) {
    final isSelected = _selectedTemplate == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTemplate = value;
          _applyTemplate(value);
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    context.appTheme.primary,
                    context.appTheme.primary.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.appTheme.primary : AppColors.gray300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildInputModeButton(String label, String mode) {
    final isSelected = _inputMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _inputMode = mode;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.info600 : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.info600 : AppColors.info500,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.textOnPrimary : AppColors.info700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrizeItem(int index, PrizeItem prize) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Position badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getPositionColor(prize.position),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${prize.position}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Input field (percentage or amount)
              if (_selectedTemplate == 'custom')
                Expanded(
                  child: TextFormField(
                    key: ValueKey('${prize.position}_$_inputMode'),
                    keyboardType: TextInputType.number,
                    initialValue: _inputMode == 'percentage'
                        ? prize.percentage.toStringAsFixed(0)
                        : prize.cashAmount.toString(),
                    decoration: InputDecoration(
                      hintText: _inputMode == 'percentage' ? '%' : 'VNĐ',
                      suffixText: _inputMode == 'percentage' ? '%' : 'đ',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      final numValue = double.tryParse(value) ?? 0;
                      if (_inputMode == 'percentage') {
                        // User nhập %
                        prize.percentage = numValue;
                        _calculatePrizes();
                      } else {
                        // User nhập số tiền VND
                        final totalPrize =
                            double.tryParse(_totalPrizeController.text) ?? 0;
                        prize.cashAmount = numValue.toInt();
                        // Tính ngược % từ số tiền
                        if (totalPrize > 0) {
                          prize.percentage = (numValue / totalPrize) * 100;
                        }
                        // 🚨 CRITICAL: Phải call _updateData() để update validation
                        _updateData();
                      }
                    },
                  ),
                )
              else
                Expanded(
                  child: Text(
                    '${prize.percentage}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

              SizedBox(width: 8.w),

              // Cash amount display
              Text(
                '${_formatMoney(prize.cashAmount)} VNĐ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.appTheme.primary,
                ),
              ),

              // Delete button (custom mode)
              if (_selectedTemplate == 'custom' && _prizes.length > 1)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () {
                    setState(() {
                      _prizes.removeAt(index);
                      // Reorder positions
                      for (int i = 0; i < _prizes.length; i++) {
                        _prizes[i].position = i + 1;
                      }
                      _calculatePrizes();
                    });
                  },
                ),
            ],
          ),

          // Physical prize
          SizedBox(height: 8.h),
          TextField(
            controller: TextEditingController(text: prize.physicalPrize),
            decoration: InputDecoration(
              hintText: 'Phần thưởng hiện vật (tùy chọn)',
              hintStyle: TextStyle(fontSize: 13),
              prefixIcon: Icon(Icons.card_giftcard, size: 18),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              prize.physicalPrize = value;
              _updateData();
            },
          ),

          // 🚀 ELON MODE: Quick select cho phần thưởng phổ biến
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildQuickPrizeChip(prize, '🏆 Cúp vô địch'),
              _buildQuickPrizeChip(prize, '🥈 Cúp á quân'),
              _buildQuickPrizeChip(prize, '🥉 Cúp hạng 3'),
              _buildQuickPrizeChip(prize, '📜 Bảng vinh danh'),
              _buildQuickPrizeChip(prize, '🎖️ Huy chương'),
              _buildQuickPrizeChip(prize, '🎁 Quà tặng'),
            ],
          ),

          // 🎟️ Voucher reward section
          SizedBox(height: 8.h),
          _buildVoucherSelector(prize),
        ],
      ),
    );
  }

  /// 🎟️ Build voucher selector for prize
  Widget _buildVoucherSelector(PrizeItem prize) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.premium50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.premium100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.confirmation_number,
                  size: 18, color: AppColors.premium),
              SizedBox(width: 8.w),
              Text(
                'Voucher thưởng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.premium600,
                ),
              ),
              Spacer(),
              if (prize.voucherId != null)
                IconButton(
                  icon: Icon(Icons.clear, size: 18, color: AppColors.error),
                  constraints: BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      prize.voucherId = null;
                      prize.voucherName = null;
                      _updateData();
                    });
                  },
                ),
            ],
          ),
          if (prize.voucherId == null) ...[
            SizedBox(height: 8.h),
            ElevatedButton.icon(
              onPressed: () => _showVoucherPicker(prize),
              icon: Icon(Icons.add, size: 16),
              label: Text('Chọn voucher', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.premium,
                foregroundColor: AppColors.textOnPrimary,
                minimumSize: Size(double.infinity, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: prize.voucherType == 'prize'
                    ? AppColors.success50
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: prize.voucherType == 'prize'
                      ? AppColors.success500
                      : AppColors.premium500,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    prize.voucherType == 'prize'
                        ? Icons.payments
                        : Icons.local_activity,
                    size: 20,
                    color: prize.voucherType == 'prize'
                        ? AppColors.success
                        : AppColors.premium,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              prize.voucherName ?? 'Voucher',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: prize.voucherType == 'prize'
                                    ? AppColors.success
                                    : AppColors.premium,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                prize.voucherType == 'prize' ? 'PRIZE' : 'CLUB',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textOnPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Số lượng: ${prize.voucherQuantity}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (prize.voucherValueVnd != null) ...[
                          SizedBox(height: 2),
                          Text(
                            'Trị giá: ${_formatMoney(prize.voucherValueVnd!)} VNĐ',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (prize.voucherType == 'prize' &&
                            prize.voucherValidDays != null) ...[
                          SizedBox(height: 2),
                          Text(
                            'Hiệu lực: ${prize.voucherValidDays} ngày',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit,
                        size: 18,
                        color: prize.voucherType == 'prize'
                            ? AppColors.success
                            : AppColors.premium),
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showVoucherPicker(prize),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🎟️ Show voucher picker dialog
  Future<void> _showVoucherPicker(PrizeItem prize) async {
    if (_isLoadingVouchers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đang tải danh sách voucher...')),
      );
      return;
    }

    // First, ask user to choose voucher type
    final voucherType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chọn loại voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.premium50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.discount, color: AppColors.premium),
              ),
              title: Text('Club Voucher'),
              subtitle: Text('Discount, time bonus, drinks từ club'),
              onTap: () => Navigator.pop(context, 'club'),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.payments, color: AppColors.success),
              ),
              title: Text('Prize Voucher'),
              subtitle: Text('Voucher tiền mặt để thanh toán bàn'),
              onTap: () => Navigator.pop(context, 'prize'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
        ],
      ),
    );

    if (voucherType == null) return;

    if (voucherType == 'prize') {
      // Prize voucher - nhập trực tiếp giá trị VNĐ
      await _showPrizeVoucherConfig(prize);
    } else {
      // Club voucher - chọn từ danh sách
      await _showClubVoucherPicker(prize);
    }
  }

  /// Show club voucher picker (UPDATED - uses new approval system)
  Future<void> _showClubVoucherPicker(PrizeItem prize) async {
    if (_availableVouchers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Chưa có voucher đã duyệt'),
            ],
          ),
          content: Text(
            'CLB chưa có voucher nào được admin phê duyệt.\n\n'
            'Bạn có thể:\n'
            '1. Đăng ký voucher campaign mới từ tab Khuyến Mãi\n'
            '2. Chờ admin phê duyệt các campaign đã đăng ký\n'
            '3. Hoặc sử dụng "Prize Voucher" (phần thưởng tiền mặt VNĐ)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    final result = await showDialog<VoucherCampaign>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.confirmation_number, color: AppColors.premium),
            SizedBox(width: 8),
            Text('Chọn Club Voucher'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chọn từ các voucher campaign đã được admin phê duyệt',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: AppColors.success, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tất cả voucher dưới đây đã được admin phê duyệt',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.success700),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableVouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = _availableVouchers[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.premium50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.confirmation_number,
                            color: AppColors.premium,
                            size: 24,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                voucher.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.verified,
                                color: AppColors.success, size: 16),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            if (voucher.description != null)
                              Text(
                                voucher.description!,
                                style: TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.payments,
                                    size: 12, color: AppColors.textTertiary),
                                SizedBox(width: 4),
                                Text(
                                  '${_formatCurrency(voucher.voucherValue)} ${_getVoucherTypeText(voucher.voucherType)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.inventory_2,
                                    size: 12, color: AppColors.textTertiary),
                                SizedBox(width: 4),
                                Text(
                                  'Còn ${voucher.totalQuantity - voucher.issuedQuantity}/${voucher.totalQuantity}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 12, color: AppColors.textTertiary),
                                SizedBox(width: 4),
                                Text(
                                  'Đến ${_formatDate(voucher.endDate)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.pop(context, voucher),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        prize.voucherId = result.id;
        prize.voucherName = result.title;
        prize.voucherType = 'club';
        // Show quantity picker
        _showQuantityPicker(prize);
      });
    }
  }

  String _getVoucherTypeText(String type) {
    switch (type) {
      case 'spa_balance':
        return 'SPA Balance';
      case 'fixed_value':
        return 'Fixed Value';
      case 'percentage_discount':
        return '% Discount';
      default:
        return type;
    }
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// Show prize voucher config dialog
  Future<void> _showPrizeVoucherConfig(PrizeItem prize) async {
    int quantity = prize.voucherQuantity;
    int vndValue = prize.voucherValueVnd ?? 700000; // Default 700K
    int validDays = prize.voucherValidDays ?? 30; // Default 30 days

    final vndController = TextEditingController(text: vndValue.toString());

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payments, color: AppColors.success),
            SizedBox(width: 8),
            Text('Prize Voucher'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Giá trị voucher
                  Text(
                    'Giá trị voucher (VNĐ)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Số tiền có thể dùng để thanh toán bàn',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: vndController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '700000',
                      suffix: Text('VNĐ'),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      vndValue = int.tryParse(value) ?? 0;
                    },
                  ),

                  SizedBox(height: 16),

                  // Quick presets
                  Text(
                    'Gợi ý nhanh',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPresetChip(
                          '300K', 300000, vndController, setDialogState),
                      _buildPresetChip(
                          '500K', 500000, vndController, setDialogState),
                      _buildPresetChip(
                          '700K', 700000, vndController, setDialogState),
                      _buildPresetChip(
                          '1M', 1000000, vndController, setDialogState),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Số lượng
                  Text(
                    'Số lượng voucher',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: quantity > 1
                            ? () {
                                setDialogState(() => quantity--);
                              }
                            : null,
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '$quantity',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setDialogState(() => quantity++);
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Validity days
                  Text(
                    'Thời hạn hiệu lực (ngày)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Slider(
                    value: validDays.toDouble(),
                    min: 7,
                    max: 90,
                    divisions: 11,
                    label: '$validDays ngày',
                    onChanged: (value) {
                      setDialogState(() => validDays = value.toInt());
                    },
                  ),
                  Text(
                    '$validDays ngày',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // Read from controller to get the latest value (including preset selections)
              final finalVndValue =
                  int.tryParse(vndController.text) ?? vndValue;
              Navigator.pop(context, {
                'quantity': quantity,
                'vndValue': finalVndValue,
                'validDays': validDays,
              });
            },
            child: Text('Xong'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        prize.voucherId =
            'prize_${prize.position}_${DateTime.now().millisecondsSinceEpoch}';
        prize.voucherName =
            'Prize Voucher ${_formatMoney(result['vndValue'])} VNĐ';
        prize.voucherType = 'prize';
        prize.voucherQuantity = result['quantity'];
        prize.voucherValueVnd = result['vndValue'];
        prize.voucherValidDays = result['validDays'];
        _updateData();
      });
    }
  }

  Widget _buildPresetChip(String label, int value,
      TextEditingController controller, StateSetter setState) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        controller.text = value.toString();
        setState(() {});
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Show quantity picker for voucher
  Future<void> _showQuantityPicker(PrizeItem prize) async {
    int quantity = prize.voucherQuantity;
    final vndController = TextEditingController(
      text: prize.voucherValueVnd?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cấu hình voucher'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity selector
                  Text(
                    'Số lượng voucher',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Số voucher người chiến thắng sẽ nhận',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: quantity > 1
                            ? () {
                                setDialogState(() => quantity--);
                              }
                            : null,
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '$quantity',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setDialogState(() => quantity++);
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 12),

                  // VND value input
                  Text(
                    'Trị giá voucher (tùy chọn)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Để hiển thị giá trị voucher cho người chơi',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: vndController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: 50000',
                      suffixText: 'VNĐ',
                      prefixIcon: Icon(Icons.money, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '💡 Ví dụ: Voucher giảm giá 50.000 VNĐ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.info700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // Read from controller for consistency with Prize Voucher dialog
              final finalVndValue = vndController.text.isEmpty
                  ? null
                  : int.tryParse(vndController.text);
              setState(() {
                prize.voucherQuantity = quantity;
                prize.voucherValueVnd = finalVndValue;
                _updateData();
              });
              Navigator.pop(context);
            },
            child: Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCheck() {
    final total = _totalPercentage;
    final totalPrize = double.tryParse(_totalPrizeController.text) ?? 0;
    final totalDistributed =
        _prizes.fold<int>(0, (sum, p) => sum + p.cashAmount);

    final isValid = (total - 100).abs() < 0.01;
    final hasError = total > 100;
    final hasWarning =
        total > 0 && total < 100 && _selectedTemplate == 'custom';

    Color bgColor = AppColors.success50;
    Color borderColor = AppColors.success;
    Color iconColor = AppColors.success;
    IconData icon = Icons.check_circle;

    if (hasError) {
      bgColor = AppColors.error50;
      borderColor = AppColors.error;
      iconColor = AppColors.error;
      icon = Icons.error;
    } else if (hasWarning) {
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange;
      iconColor = Colors.orange.shade700;
      icon = Icons.info;
    } else if (!isValid) {
      bgColor = AppColors.warning50;
      borderColor = AppColors.warning;
      iconColor = AppColors.warning;
      icon = Icons.warning;
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  isValid
                      ? 'Tổng phân bổ: ${total.toStringAsFixed(1)}% ✓'
                      : 'Tổng phân bổ: ${total.toStringAsFixed(1)}%${hasError ? " (vượt quá 100%!)" : hasWarning ? " (còn thiếu)" : " (cần đúng 100%)"}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          if (totalPrize > 0) ...[
            SizedBox(height: 4.h),
            Text(
              'Số tiền: ${_formatCurrency(totalDistributed)} / ${_formatCurrency(totalPrize.toInt())}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (hasWarning) ...[
            SizedBox(height: 4.h),
            Text(
              'Lưu ý: Còn ${(100 - total).toStringAsFixed(1)}% chưa phân bổ',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementsCard() {
    final rankOptions = <String?, String>{
      null: 'Không giới hạn',
      ..._saboRanks.fold<Map<String?, String>>({}, (map, rank) {
        final displayName =
            RankingConstants.RANK_DETAILS[rank]?['name'] ?? rank;
        map[rank] = displayName;
        return map;
      }),
    };

    // Validate current values - if not in options, reset to null
    if (_minRank != null && !rankOptions.containsKey(_minRank)) {
      _minRank = null;
    }
    if (_maxRank != null && !rankOptions.containsKey(_maxRank)) {
      _maxRank = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.appTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.military_tech_outlined,
                  color: context.appTheme.primary,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Điều kiện tham gia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Min Rank
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hạng thấp nhất',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: DropdownButton<String?>(
                          value: _minRank,
                          underline: SizedBox(),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textSecondary,
                          ),
                          dropdownColor: AppColors.surface,
                          isExpanded: true,
                          items: rankOptions.entries.map((entry) {
                            return DropdownMenuItem<String?>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: entry.key == null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _minRank = value);
                            _updateData();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                // Max Rank
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hạng cao nhất',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: DropdownButton<String?>(
                          value: _maxRank,
                          underline: SizedBox(),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textSecondary,
                          ),
                          dropdownColor: AppColors.surface,
                          isExpanded: true,
                          items: rankOptions.entries.map((entry) {
                            return DropdownMenuItem<String?>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: entry.key == null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _maxRank = value);
                            _updateData();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 ELON MODE: Quick select chip cho phần thưởng vật chất
  Widget _buildQuickPrizeChip(PrizeItem prize, String text) {
    final isSelected = prize.physicalPrize == text;
    return InkWell(
      onTap: () {
        setState(() {
          prize.physicalPrize = isSelected ? null : text;
          _updateData();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return AppColors.warning600; // Gold
      case 2:
        return AppColors.gray400; // Silver
      case 3:
        return AppColors.warning600; // Bronze
      default:
        return context.appTheme.primary;
    }
  }

  String _formatMoney(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

class PrizeItem {
  int position;
  double percentage;
  int cashAmount;
  String? physicalPrize;
  String? voucherId; // 🎟️ ID của voucher campaign
  String? voucherName; // Tên voucher (để hiển thị)
  int voucherQuantity; // Số lượng voucher (mặc định 1)
  int? voucherValueVnd; // Trị giá voucher bằng VNĐ (tùy chọn, để hiển thị)
  String?
      voucherType; // 🎯 'club' (discount/time) hoặc 'prize' (cash for table payment)
  int? voucherValidDays; // Số ngày hiệu lực (cho prize voucher)

  PrizeItem({
    required this.position,
    required this.percentage,
    required this.cashAmount,
    this.physicalPrize,
    this.voucherId,
    this.voucherName,
    this.voucherQuantity = 1,
    this.voucherValueVnd,
    this.voucherType = 'club', // Mặc định là club voucher
    this.voucherValidDays = 30, // Mặc định 30 ngày
  });

  Map<String, dynamic> toMap() {
    return {
      'position': position,
      'percentage': percentage,
      'cashAmount': cashAmount,
      'physicalPrize': physicalPrize,
      'voucherId': voucherId,
      'voucherName': voucherName,
      'voucherQuantity': voucherQuantity,
      'voucherValueVnd': voucherValueVnd,
      'voucherType': voucherType,
      'voucherValidDays': voucherValidDays,
    };
  }

  factory PrizeItem.fromMap(Map<String, dynamic> map) {
    return PrizeItem(
      position: map['position'] ?? 0,
      percentage: (map['percentage'] ?? 0).toDouble(),
      cashAmount: map['cashAmount'] ?? 0,
      physicalPrize: map['physicalPrize'],
      voucherId: map['voucherId'],
      voucherName: map['voucherName'],
      voucherQuantity: map['voucherQuantity'] ?? 1,
      voucherValueVnd: map['voucherValueVnd'],
      voucherType: map['voucherType'] ?? 'club',
      voucherValidDays: map['voucherValidDays'] ?? 30,
    );
  }
}
