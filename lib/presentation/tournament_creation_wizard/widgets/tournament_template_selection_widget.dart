import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';

class TournamentTemplateSelectionWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onTemplateSelected;

  const TournamentTemplateSelectionWidget({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  State<TournamentTemplateSelectionWidget> createState() =>
      _TournamentTemplateSelectionWidgetState();
}

class _TournamentTemplateSelectionWidgetState
    extends State<TournamentTemplateSelectionWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(DesignTokens.space20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.dashboard_customize,
                  color: context.appTheme.primary,
                  size: 24.w,
                ),
                SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: Text(
                    'Chọn mẫu giải đấu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 24.w),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            color: AppColors.gray50,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              isScrollable: true,
              tabs: [
                Tab(text: 'Phổ biến'),
                Tab(text: 'Theo thể thức'),
                Tab(text: 'Theo thời gian'),
                Tab(text: 'Tùy chỉnh'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPopularTemplates(),
                _buildFormatTemplates(),
                _buildTimeTemplates(),
                _buildCustomTemplates(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTemplates() {
    final templates = [
      {
        'id': 'evening_8ball',
        'name': '8-Ball Buổi Tối',
        'description': 'Giải đấu 8-ball thân thiện cho buổi tối',
        'format': 'single_elimination',
        'gameType': '8-ball',
        'maxParticipants': 16,
        'entryFee': 50000,
        'estimatedDuration': '3-4 giờ',
        'icon': Icons.sports_bar,
        'color': AppColors.info,
        'data': {
          'name': '8-Ball Buổi Tối',
          'gameType': '8-ball',
          'format': 'single_elimination',
          'maxParticipants': 16,
          'entryFee': 50000.0,
          'hasThirdPlaceMatch': true,
          'prizeDistribution': 'top_3_standard',
          'organizerFeePercent': 10.0,
        },
      },
      {
        'id': 'weekend_9ball',
        'name': '9-Ball Cuối Tuần',
        'description': 'Giải 9-ball chuyên nghiệp cuối tuần',
        'format': 'double_elimination',
        'gameType': '9-ball',
        'maxParticipants': 32,
        'entryFee': 100000,
        'estimatedDuration': '6-8 giờ',
        'icon': Icons.sports_cricket,
        'color': AppColors.success,
        'data': {
          'name': '9-Ball Cuối Tuần',
          'gameType': '9-ball',
          'format': 'double_elimination',
          'maxParticipants': 32,
          'entryFee': 100000.0,
          'hasThirdPlaceMatch': true,
          'prizeDistribution': 'top_4',
          'organizerFeePercent': 15.0,
        },
      },
      {
        'id': 'quick_tournament',
        'name': 'Giải Nhanh',
        'description': 'Giải đấu nhanh trong 1-2 giờ',
        'format': 'single_elimination',
        'gameType': '8-ball',
        'maxParticipants': 8,
        'entryFee': 30000,
        'estimatedDuration': '1-2 giờ',
        'icon': Icons.flash_on,
        'color': AppColors.warning,
        'data': {
          'name': 'Giải Nhanh',
          'gameType': '8-ball',
          'format': 'single_elimination',
          'maxParticipants': 8,
          'entryFee': 30000.0,
          'hasThirdPlaceMatch': false,
          'prizeDistribution': 'winner_takes_all',
          'organizerFeePercent': 5.0,
        },
      },
      {
        'id': 'championship',
        'name': 'Giải Vô Địch',
        'description': 'Giải đấu lớn với giải thưởng cao',
        'format': 'double_elimination',
        'gameType': '10-ball',
        'maxParticipants': 64,
        'entryFee': 200000,
        'estimatedDuration': '2 ngày',
        'icon': Icons.emoji_events,
        'color': AppColors.accent,
        'data': {
          'name': 'Giải Vô Địch',
          'gameType': '10-ball',
          'format': 'double_elimination',
          'maxParticipants': 64,
          'entryFee': 200000.0,
          'hasThirdPlaceMatch': true,
          'prizeDistribution': 'top_8',
          'organizerFeePercent': 20.0,
        },
      },
    ];

    return _buildTemplateGrid(templates);
  }

  Widget _buildFormatTemplates() {
    final templates = [
      {
        'id': 'single_elim_template',
        'name': 'Loại Trực Tiếp',
        'description': 'Thua 1 trận là bị loại',
        'format': 'single_elimination',
        'icon': Icons.trending_up,
        'color': AppColors.error,
        'enabled': true,
        'data': {
          'format': 'single_elimination',
          'hasThirdPlaceMatch': true,
          'prizeDistribution': 'top_3_standard',
        },
      },
      {
        'id': 'double_elim_template',
        'name': 'Loại Kép',
        'description': 'Cơ hội thứ hai trong nhánh thua (Sắp có)',
        'format': 'double_elimination',
        'icon': Icons.call_split,
        'color': AppColors.gray500,
        'enabled': false,
        'data': {
          'format': 'double_elimination',
          'hasThirdPlaceMatch': false,
          'prizeDistribution': 'top_4',
        },
      },
      {
        'id': 'round_robin_template',
        'name': 'Vòng Tròn',
        'description': 'Mọi người đấu với mọi người (Sắp có)',
        'format': 'round_robin',
        'icon': Icons.replay,
        'color': AppColors.gray500,
        'enabled': false,
        'data': {
          'format': 'round_robin',
          'maxParticipants': 8,
          'prizeDistribution': 'top_3_standard',
        },
      },
      {
        'id': 'swiss_template',
        'name': 'Swiss System',
        'description': 'Đấu theo điểm số tương đồng (Sắp có)',
        'format': 'swiss',
        'icon': Icons.shuffle,
        'color': AppColors.gray500,
        'enabled': false,
        'data': {
          'format': 'swiss',
          'maxParticipants': 16,
          'prizeDistribution': 'top_4',
        },
      },
    ];

    return _buildTemplateGrid(templates);
  }

  Widget _buildTimeTemplates() {
    final templates = [
      {
        'id': 'morning_template',
        'name': 'Giải Sáng',
        'description': 'Bắt đầu 8:00 AM',
        'icon': Icons.wb_sunny,
        'color': AppColors.warning,
        'data': {
          'name': 'Giải Sáng',
          'tournamentStartTime': '08:00',
          'maxParticipants': 16,
          'estimatedDuration': 4,
        },
      },
      {
        'id': 'afternoon_template',
        'name': 'Giải Chiều',
        'description': 'Bắt đầu 2:00 PM',
        'icon': Icons.wb_cloudy,
        'color': AppColors.info500,
        'data': {
          'name': 'Giải Chiều',
          'tournamentStartTime': '14:00',
          'maxParticipants': 24,
          'estimatedDuration': 5,
        },
      },
      {
        'id': 'evening_template',
        'name': 'Giải Tối',
        'description': 'Bắt đầu 7:00 PM',
        'icon': Icons.nights_stay,
        'color': AppColors.primary700,
        'data': {
          'name': 'Giải Tối',
          'tournamentStartTime': '19:00',
          'maxParticipants': 32,
          'estimatedDuration': 6,
        },
      },
      {
        'id': 'weekend_template',
        'name': 'Giải Cuối Tuần',
        'description': 'Diễn ra cả ngày Thứ 7',
        'icon': Icons.weekend,
        'color': AppColors.success,
        'data': {
          'name': 'Giải Cuối Tuần',
          'tournamentStartTime': '10:00',
          'maxParticipants': 64,
          'estimatedDuration': 8,
        },
      },
    ];

    return _buildTemplateGrid(templates);
  }

  Widget _buildCustomTemplates() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_circle_outlined,
            size: 64.w,
            color: AppColors.gray400,
          ),
          SizedBox(height: DesignTokens.space16),
          Text(
            'Tạo từ đầu',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: DesignTokens.space8),
          Text(
            'Tự cấu hình tất cả các thiết lập',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: DesignTokens.space24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onTemplateSelected({'isCustom': true, 'data': {}});
            },
            icon: Icon(Icons.add),
            label: Text('Tạo tùy chỉnh'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.space24,
                vertical: DesignTokens.space12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateGrid(List<Map<String, dynamic>> templates) {
    return GridView.builder(
      padding: EdgeInsets.all(DesignTokens.space20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: DesignTokens.space16,
        mainAxisSpacing: DesignTokens.space16,
        childAspectRatio: 0.85,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final isEnabled = template['enabled'] as bool? ?? true;
    
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: isEnabled ? () {
          Navigator.pop(context);
          widget.onTemplateSelected({
            'template': template,
            'data': template['data'] ?? {},
          });
        } : null,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
            border: Border.all(
              color: isEnabled ? AppColors.border : AppColors.gray300,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(DesignTokens.space16),
                    decoration: BoxDecoration(
                      color: (template['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(DesignTokens.radiusLG),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(DesignTokens.space12),
                          decoration: BoxDecoration(
                            color: template['color'] as Color,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                          ),
                          child: Icon(
                            template['icon'] as IconData,
                            color: AppColors.textOnPrimary,
                            size: 32.w,
                          ),
                        ),
                        SizedBox(height: DesignTokens.space8),
                        Text(
                          template['name'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: template['color'] as Color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template['description'],
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: DesignTokens.space12),

                          // Template details
                          if (template['format'] != null) ...[
                            _buildTemplateDetail(
                              Icons.account_tree,
                              _getFormatLabel(template['format']),
                            ),
                          ],

                          if (template['maxParticipants'] != null) ...[
                            _buildTemplateDetail(
                              Icons.people,
                              '${template['maxParticipants']} người',
                            ),
                          ],

                          if (template['entryFee'] != null) ...[
                            _buildTemplateDetail(
                              Icons.payments,
                              '₫${_formatMoney(template['entryFee'])}',
                            ),
                          ],

                          if (template['estimatedDuration'] != null) ...[
                            _buildTemplateDetail(
                              Icons.schedule,
                              template['estimatedDuration'],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // "Sắp có" badge for disabled templates
              if (!isEnabled)
                Positioned(
                  top: DesignTokens.space12,
                  right: DesignTokens.space12,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.space8,
                      vertical: DesignTokens.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning500,
                      borderRadius: DesignTokens.radius(DesignTokens.radiusMD),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Sắp có',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateDetail(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.space8),
      child: Row(
        children: [
          Icon(icon, size: 16.w, color: AppColors.textTertiary),
          SizedBox(width: DesignTokens.space8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getFormatLabel(String format) {
    switch (format) {
      case 'single_elimination':
        return 'Loại trực tiếp';
      case 'double_elimination':
        return 'Loại kép';
      case 'round_robin':
        return 'Vòng tròn';
      case 'swiss':
        return 'Swiss';
      default:
        return format;
    }
  }

  String _formatMoney(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toString();
    }
  }
}
