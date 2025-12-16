import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import '../widgets/form_enhancement_widgets.dart';
import '../widgets/rules_checklist_widget.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class EnhancedRulesReviewStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback? onCreateTournament;
  final bool isCreating;

  const EnhancedRulesReviewStep({
    super.key,
    required this.data,
    required this.onDataChanged,
    this.onCreateTournament,
    this.isCreating = false,
  });

  @override
  State<EnhancedRulesReviewStep> createState() =>
      _EnhancedRulesReviewStepState();
}

class _EnhancedRulesReviewStepState extends State<EnhancedRulesReviewStep> {
  final _contactController = TextEditingController();
  List<String> _selectedRules = [];

  // Form validation
  final Map<String, String> _errors = {};
  final Map<String, String> _warnings = {};
  final Map<String, String> _successes = {};

  @override
  void initState() {
    super.initState();
    _initializeFromData();
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  void _initializeFromData() {
    _selectedRules = List<String>.from(widget.data['selectedRules'] ?? []);
    _contactController.text = widget.data['contactInfo'] ?? '';
    
    // If no rules selected, add some default rules
    if (_selectedRules.isEmpty) {
      _selectedRules = [
        'Đến đúng giờ, trễ quá 15 phút = thua WO',
        'Mặc trang phục lịch sự, không mặc áo ba lỗ',
        'Tuân thủ quyết định của trọng tài',
        'Cấm sử dụng điện thoại trong khi thi đấu',
        'Bắt tay đối thủ trước và sau trận đấu',
      ];
      // Update data immediately with default rules
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateAndUpdate();
      });
    }
  }

  void _validateAndUpdate() {
    _errors.clear();
    _warnings.clear();
    _successes.clear();

    final contact = _contactController.text.trim();

    // Rules validation
    if (_selectedRules.isEmpty) {
      _warnings['Quy định'] = 'Nên chọn ít nhất một quy định';
    } else if (_selectedRules.length < 3) {
      _warnings['Quy định'] =
          'Nên có thêm quy định để giải đấu chuyên nghiệp hơn';
    } else {
      _successes['Quy định'] = 'Đã chọn ${_selectedRules.length} quy định';
    }

    // Contact validation
    if (contact.isEmpty) {
      _warnings['Thông tin liên hệ'] =
          'Nên có thông tin liên hệ để người chơi hỏi đáp';
    } else if (contact.length < 5) {
      _warnings['Thông tin liên hệ'] = 'Thông tin liên hệ quá ngắn';
    } else {
      _successes['Liên hệ'] = 'Thông tin liên hệ đầy đủ';
    }

    // Overall validation
    final name = widget.data['name']?.toString() ?? '';
    final venue = widget.data['venue']?.toString() ?? '';
    final regStartDate = widget.data['registrationStartDate'] as DateTime?;
    final tournamentStartDate = widget.data['tournamentStartDate'] as DateTime?;

    if (name.isNotEmpty &&
        venue.isNotEmpty &&
        regStartDate != null &&
        tournamentStartDate != null) {
      _successes['Giải đấu'] = 'Sẵn sàng tạo giải đấu';
    } else {
      _errors['Thông tin thiếu'] = 'Vui lòng hoàn thành các bước trước';
    }

    // Update data - defer to after build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Tạo rules từ selectedRules
        // Nếu không có rules nào được chọn, sử dụng default rules
        final rulesText = _selectedRules.isNotEmpty
            ? _selectedRules.join('\n')
            : 'Giải đấu áp dụng luật thi đấu chuẩn\nTuân thủ quyết định của trọng tài\nĐến đúng giờ, trễ quá 15 phút sẽ bị loại';

        ProductionLogger.info('📋 Rules text being saved: $rulesText', tag: 'enhanced_rules_review_step');
        ProductionLogger.info('📋 Rules length: ${rulesText.length}', tag: 'enhanced_rules_review_step');

        widget.onDataChanged({
          'selectedRules': _selectedRules,
          'contactInfo': contact,
          'rules': rulesText, // Thêm rules vào data
        });
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ProductionLogger.info('🎯 STEP 4: EnhancedRulesReviewStep - Starting build', tag: 'enhanced_rules_review_step');
    ProductionLogger.info('   widget.data[format] = ${widget.data['format']}', tag: 'enhanced_rules_review_step');
    ProductionLogger.info('   widget.data[gameType] = ${widget.data['gameType']}', tag: 'enhanced_rules_review_step');
    ProductionLogger.info('   widget.data[entryFee] = ${widget.data['entryFee']}', tag: 'enhanced_rules_review_step');
    ProductionLogger.info('   widget.data[maxParticipants] = ${widget.data['maxParticipants']}', tag: 'enhanced_rules_review_step');

    try {
      ProductionLogger.info('✅ STEP 4: Building Scaffold', tag: 'enhanced_rules_review_step');
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Validation feedback
            Builder(
              builder: (context) {
                try {
                  ProductionLogger.info('✅ STEP 4: Building ValidationFeedbackWidget', tag: 'enhanced_rules_review_step');
                  return ValidationFeedbackWidget(
                    errors: _errors,
                    warnings: _warnings,
                    successes: _successes,
                  );
                } catch (e, stack) {
                  ProductionLogger.info('❌ STEP 4 ERROR in ValidationFeedback: $e', tag: 'enhanced_rules_review_step');
                  ProductionLogger.info('Stack: $stack', tag: 'enhanced_rules_review_step');
                  return Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.orange.shade100,
                    child: Text(
                      'Validation Widget Error: $e',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                }
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Builder(
                      builder: (context) {
                        try {
                          ProductionLogger.info('✅ STEP 4: Building Header', tag: 'enhanced_rules_review_step');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quy định & Xem lại',
                                style: TextStyle(
                                  fontSize: 24.h,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Hoàn thiện quy định và xem lại toàn bộ thông tin giải đấu',
                                style: TextStyle(
                                  fontSize: 16.h,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          );
                        } catch (e) {
                          ProductionLogger.info('❌ STEP 4 ERROR in Header: $e', tag: 'enhanced_rules_review_step');
                          return Text(
                            'Header Error: $e',
                            style: TextStyle(color: Colors.red),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 32.h),

                    // Rules checklist
                    Builder(
                      builder: (context) {
                        try {
                          ProductionLogger.info('✅ STEP 4: Building RulesChecklistWidget', tag: 'enhanced_rules_review_step');
                          return RulesChecklistWidget(
                            selectedRules: _selectedRules,
                            onChanged: (rules) {
                              setState(() {
                                _selectedRules = rules;
                              });
                              _validateAndUpdate();
                            },
                          );
                        } catch (e, stack) {
                          ProductionLogger.info('❌ STEP 4 ERROR in RulesChecklist: $e', tag: 'enhanced_rules_review_step');
                          ProductionLogger.info('Stack: $stack', tag: 'enhanced_rules_review_step');
                          return Container(
                            padding: EdgeInsets.all(16),
                            color: Colors.red.shade100,
                            child: Text('Rules Checklist Error: $e'),
                          );
                        }
                      },
                    ),

                    SizedBox(height: 32.h),

                    // Rest of the content...
                    Builder(
                      builder: (context) {
                        try {
                          ProductionLogger.info('✅ STEP 4: Building Contact & Review sections', tag: 'enhanced_rules_review_step');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildContactSection(),
                              SizedBox(height: 32.h),
                              _buildReviewSection(),
                              SizedBox(height: 40.h),
                            ],
                          );
                        } catch (e, stack) {
                          ProductionLogger.info('❌ STEP 4 ERROR in Contact/Review: $e', tag: 'enhanced_rules_review_step');
                          ProductionLogger.info('Stack: $stack', tag: 'enhanced_rules_review_step');
                          return Container(
                            padding: EdgeInsets.all(16),
                            color: Colors.red.shade100,
                            child: Text('Contact/Review Error: $e'),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      ProductionLogger.info('❌ STEP 4 FATAL ERROR: $e', tag: 'enhanced_rules_review_step');
      ProductionLogger.info('Stack trace: $stack', tag: 'enhanced_rules_review_step');
      return Container(
        color: Colors.red.shade50,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Step 4 Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        // Contact info
        EnhancedFormField(
          label: 'Thông tin liên hệ',
          value: _contactController.text,
          hintText: 'SĐT, Email, Zalo của ban tổ chức...',
          helperText: 'Để người chơi có thể liên hệ khi cần hỗ trợ',
          prefixIcon: Icons.contact_phone,
          maxLines: 3,
          maxLength: 200,
          onChanged: (value) {
            _contactController.text = value;
            _validateAndUpdate();
          },
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tournament preview
        _buildTournamentPreview(),
        SizedBox(height: 32.h),
        // Create button
        _buildCreateButton(),
      ],
    );
  }

  Widget _buildTournamentPreview() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: Theme.of(context).primaryColor,
                size: 24.w,
              ),
              SizedBox(width: 12.w),
              Text(
                'Xem trước giải đấu',
                style: TextStyle(
                  fontSize: 20.h,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Tournament info
          _buildPreviewSection('Thông tin cơ bản', [
            _buildPreviewItem(
              'Tên giải',
              widget.data['name'] ?? 'Chưa đặt tên',
            ),
            _buildPreviewItem(
              'Loại bi-a',
              _getGameTypeLabel(widget.data['gameType']),
            ),
            _buildPreviewItem(
              'Thể thức',
              _getFormatLabel(widget.data['format']),
            ),
            _buildPreviewItem(
              'Số người',
              '${widget.data['maxParticipants'] ?? 0} người',
            ),
          ]),

          SizedBox(height: 16.h),

          _buildPreviewSection('Thời gian & Địa điểm', [
            _buildPreviewItem('Địa điểm', widget.data['venue'] ?? 'Chưa có'),
            _buildPreviewItem('Đăng ký', _getRegistrationPeriod()),
            _buildPreviewItem('Thi đấu', _getTournamentPeriod()),
          ]),

          SizedBox(height: 16.h),

          _buildPreviewSection('Giải thưởng', [
            _buildPreviewItem(
              'Phí tham gia',
              _formatMoney(widget.data['entryFee'] ?? 0),
            ),
            _buildPreviewItem(
              'Tổng giải thưởng',
              _formatMoney(widget.data['prizePool'] ?? widget.data['totalPrize'] ?? 0),
            ),
            _buildPreviewItem('Phân bổ', _getPrizeDistribution()),
          ]),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.h,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8.h),
        ...items,
      ],
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 14.h, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.h, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    final canCreate =
        _errors.isEmpty && widget.data['name']?.toString().isNotEmpty == true;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canCreate && !widget.isCreating
            ? widget.onCreateTournament
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canCreate ? 4 : 0,
        ),
        child: widget.isCreating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Đang tạo giải đấu...',
                    style: TextStyle(
                      fontSize: 16.h,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch, size: 20.w),
                  SizedBox(width: 8.w),
                  Text(
                    'Tạo giải đấu',
                    style: TextStyle(
                      fontSize: 16.h,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getGameTypeLabel(String? gameType) {
    switch (gameType) {
      case '8-ball':
        return '8-Ball';
      case '9-ball':
        return '9-Ball';
      case '10-ball':
        return '10-Ball';
      case 'straight-pool':
        return 'Straight Pool';
      default:
        return 'Chưa chọn';
    }
  }

  String _getFormatLabel(String? format) {
    switch (format) {
      case 'single_elimination':
        return 'Loại trực tiếp';
      case 'double_elimination':
        return 'Loại kép';
      case 'sabo_de16':
        return 'SABO DE16';
      case 'sabo_de32':
        return 'SABO DE32';
      case 'sabo_de64':
        return 'SABO DE64 🏆 PRO';
      case 'round_robin':
        return 'Vòng tròn';
      case 'swiss':
      case 'swiss_system':
        return 'Swiss System';
      default:
        return 'Chưa chọn';
    }
  }

  String _getRegistrationPeriod() {
    final start = widget.data['registrationStartDate'] as DateTime?;
    final end = widget.data['registrationEndDate'] as DateTime?;

    if (start == null) return 'Chưa đặt';
    if (end == null) return _formatDate(start);

    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _getTournamentPeriod() {
    final start = widget.data['tournamentStartDate'] as DateTime?;
    final end = widget.data['tournamentEndDate'] as DateTime?;

    if (start == null) return 'Chưa đặt';
    if (end == null) return _formatDate(start);

    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _getPrizeDistribution() {
    final distribution = widget.data['prizeTemplate'] ?? widget.data['prizeDistribution'] ?? 'top_3';
    switch (distribution) {
      case 'top_3':
        return 'Top 3 (50%-30%-20%)';
      case 'top_4':
        return 'Top 4 (40%-30%-20%-10%)';
      case 'top_8':
        return 'Top 8';
      case 'custom':
        return 'Tùy chỉnh';
      case 'winner_takes_all':
        return 'Người thắng nhận tất cả';
      case 'top_3_standard':
        return 'Top 3 (50%-30%-20%)';
      case 'top_3_weighted':
        return 'Top 3 (60%-25%-15%)';
      default:
        return 'Tùy chỉnh';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatMoney(dynamic amount) {
    if (amount == null || amount == 0) return 'Miễn phí';
    final value = amount is String
        ? double.tryParse(amount) ?? 0
        : amount.toDouble();
    if (value >= 1000000) {
      return '₫${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '₫${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '₫${value.toStringAsFixed(0)}';
    }
  }
}
