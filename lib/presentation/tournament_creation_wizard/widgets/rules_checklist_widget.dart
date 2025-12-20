import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ELON_MODE_AUTO_FIX

/// Rules checklist with common tournament rules
class RulesChecklistWidget extends StatefulWidget {
  final List<String> selectedRules;
  final Function(List<String>) onChanged;

  const RulesChecklistWidget({
    super.key,
    required this.selectedRules,
    required this.onChanged,
  });

  @override
  State<RulesChecklistWidget> createState() => _RulesChecklistWidgetState();
}

class _RulesChecklistWidgetState extends State<RulesChecklistWidget> {
  final TextEditingController _customRuleController = TextEditingController();
  List<String> _selectedRules = [];
  final List<String> _customRules = [];
  List<RuleTemplate> _recentTemplates = [];

  // Common tournament rules organized by category
  final Map<String, List<RuleItem>> _ruleCategories = {
    'Quy định nghiêm ngặt': [
      RuleItem(
        id: 'strict_1',
        title: 'Cấm sử dụng điện thoại trong khi thi đấu',
        description: 'Vi phạm sẽ bị cảnh cáo hoặc loại',
        icon: Icons.phone_disabled,
        color: Colors.red,
      ),
      RuleItem(
        id: 'strict_2',
        title: 'Không được rời khỏi bàn khi chưa kết thúc trận',
        description: 'Trừ khi có sự đồng ý của trọng tài',
        icon: Icons.not_interested,
        color: Colors.red,
      ),
      RuleItem(
        id: 'strict_3',
        title: 'Cấm hút thuốc trong khu vực thi đấu',
        description: 'Vi phạm sẽ bị phạt điểm',
        icon: Icons.smoke_free,
        color: Colors.red,
      ),
      RuleItem(
        id: 'strict_4',
        title: 'Nghiêm cấm cá cược trong giải đấu',
        description: 'Vi phạm sẽ bị loại khỏi giải',
        icon: Icons.money_off,
        color: Colors.red,
      ),
    ],
    'Quy định thân thiện': [
      RuleItem(
        id: 'friendly_1',
        title: 'Giải đấu mang tính chất giao lưu, vui vẻ',
        description: 'Khuyến khích tinh thần fair play',
        icon: Icons.emoji_emotions,
        color: Colors.green,
      ),
      RuleItem(
        id: 'friendly_2',
        title: 'Được phép nghỉ giữa giờ (5 phút/trận)',
        description: 'Thông báo trọng tài trước khi nghỉ',
        icon: Icons.coffee,
        color: Colors.green,
      ),
      RuleItem(
        id: 'friendly_3',
        title: 'Cho phép người thân/bạn bè cổ vũ',
        description: 'Không gây ồn ào, ảnh hưởng thi đấu',
        icon: Icons.people,
        color: Colors.green,
      ),
      RuleItem(
        id: 'friendly_4',
        title: 'Có giải khuyến khích (Fair Play Award)',
        description: 'Trao cho VĐV có tinh thần tốt nhất',
        icon: Icons.emoji_events,
        color: Colors.green,
      ),
    ],
    'Quy định chung': [
      RuleItem(
        id: 'general_1',
        title: 'Đến đúng giờ, trễ quá 15 phút = thua WO',
        description: 'Thông báo BTC nếu có lý do chính đáng',
        icon: Icons.access_time,
        color: Colors.blue,
      ),
      RuleItem(
        id: 'general_2',
        title: 'Mặc trang phục lịch sự, không mặc áo ba lỗ',
        description: 'Khuyến khích mặc áo giải đấu',
        icon: Icons.checkroom,
        color: Colors.blue,
      ),
      RuleItem(
        id: 'general_3',
        title: 'Tuân thủ quyết định của trọng tài',
        description: 'Có thể khiếu nại sau trận đấu',
        icon: Icons.gavel,
        color: Colors.blue,
      ),
      RuleItem(
        id: 'general_4',
        title: 'Bắt tay đối thủ trước và sau trận đấu',
        description: 'Thể hiện tinh thần thể thao',
        icon: Icons.handshake,
        color: Colors.blue,
      ),
      RuleItem(
        id: 'general_5',
        title: 'Không được can thiệp vào trận đấu của người khác',
        description: 'Trừ khi được mời làm trọng tài',
        icon: Icons.visibility_off,
        color: Colors.blue,
      ),
    ],
    'Quy định kỹ thuật': [
      RuleItem(
        id: 'technical_1',
        title: 'Sử dụng cơ và bi do BTC cung cấp',
        description: 'Không được mang cơ riêng (trừ khi cho phép)',
        icon: Icons.sports_baseball,
        color: Colors.orange,
      ),
      RuleItem(
        id: 'technical_2',
        title: 'Mỗi trận đấu có giới hạn thời gian',
        description: 'Thời gian tùy theo thể thức',
        icon: Icons.timer,
        color: Colors.orange,
      ),
      RuleItem(
        id: 'technical_3',
        title: 'Áp dụng luật VNBF (Vietnam Billiards Federation)',
        description: 'Hoặc luật quốc tế WPA',
        icon: Icons.rule,
        color: Colors.orange,
      ),
      RuleItem(
        id: 'technical_4',
        title: 'Có trọng tài chính thức cho các trận quan trọng',
        description: 'Vòng bán kết và chung kết',
        icon: Icons.person_pin,
        color: Colors.orange,
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedRules = List.from(widget.selectedRules);
    _loadRecentTemplates();
  }

  @override
  void dispose() {
    _customRuleController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templates = prefs.getStringList('recent_rule_templates') ?? [];

      if (mounted) {
        setState(() {
          _recentTemplates =
              templates.map((json) => RuleTemplate.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _saveAsTemplate(String name) async {
    if (_selectedRules.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final template = RuleTemplate(
        name: name,
        rules: _selectedRules,
        createdAt: DateTime.now(),
      );

      final templates = prefs.getStringList('recent_rule_templates') ?? [];
      templates.insert(0, template.toJson());

      // Keep only last 5 templates
      if (templates.length > 5) {
        templates.removeRange(5, templates.length);
      }

      await prefs.setStringList('recent_rule_templates', templates);
      await _loadRecentTemplates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu mẫu "$name"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Ignore error
    }
  }

  void _loadTemplate(RuleTemplate template) {
    setState(() {
      _selectedRules = List.from(template.rules);
    });
    widget.onChanged(_selectedRules);
  }

  void _toggleRule(String ruleId) {
    setState(() {
      if (_selectedRules.contains(ruleId)) {
        _selectedRules.remove(ruleId);
      } else {
        _selectedRules.add(ruleId);
      }
    });
    widget.onChanged(_selectedRules);
  }

  void _addCustomRule() {
    final rule = _customRuleController.text.trim();
    if (rule.isEmpty) return;

    setState(() {
      final customId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      _customRules.add(rule);
      _selectedRules.add(customId);
      _customRuleController.clear();
    });
    widget.onChanged(_selectedRules);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent templates
        if (_recentTemplates.isNotEmpty) ...[
          Text(
            'Mẫu đã lưu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 80.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentTemplates.length,
              itemBuilder: (context, index) {
                final template = _recentTemplates[index];
                return _buildTemplateCard(template);
              },
            ),
          ),
          SizedBox(height: 20.h),
        ],

        // Rule categories
        ..._ruleCategories.entries.map((entry) {
          return _buildRuleCategory(entry.key, entry.value);
        }),

        SizedBox(height: 20.h),

        // Custom rules
        _buildCustomRulesSection(),

        SizedBox(height: 20.h),

        // Save template button
        if (_selectedRules.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _showSaveTemplateDialog(),
            icon: Icon(Icons.save),
            label: Text('Lưu làm mẫu'),
          ),
      ],
    );
  }

  Widget _buildTemplateCard(RuleTemplate template) {
    return GestureDetector(
      onTap: () => _loadTemplate(template),
      child: Container(
        width: 150.w,
        margin: EdgeInsets.only(right: 12.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.appTheme.primary,
              context.appTheme.primary.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: context.appTheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              template.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Icon(Icons.rule, color: Colors.white, size: 14),
                SizedBox(width: 4.w),
                Text(
                  '${template.rules.length} luật',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCategory(String category, List<RuleItem> rules) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            category,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            '${rules.where((r) => _selectedRules.contains(r.id)).length}/${rules.length} đã chọn',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          children: rules.map<Widget>((rule) => _buildRuleItem(rule)).toList(),
        ),
      ),
    );
  }

  Widget _buildRuleItem(RuleItem rule) {
    final isSelected = _selectedRules.contains(rule.id);

    return InkWell(
      onTap: () => _toggleRule(rule.id),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? rule.color.withValues(alpha: 0.05) : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? rule.color : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? rule.color : Colors.white,
                border: Border.all(
                  color: isSelected ? rule.color : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),

            SizedBox(width: 12.w),

            // Icon
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: rule.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(rule.icon, color: rule.color, size: 20),
            ),

            SizedBox(width: 12.w),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    rule.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRulesSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: context.appTheme.primary),
              SizedBox(width: 8.w),
              Text(
                'Thêm luật tùy chỉnh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customRuleController,
                  decoration: InputDecoration(
                    hintText: 'VD: Không được uống rượu trong giải',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                  ),
                  onSubmitted: (_) => _addCustomRule(),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: _addCustomRule,
                icon: Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: context.appTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_customRules.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ..._customRules.asMap().entries.map((entry) {
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(entry.value,
                          style: TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _customRules.removeAt(entry.key);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _showSaveTemplateDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lưu mẫu quy định'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Tên mẫu',
            hintText: 'VD: Giải đấu chuyên nghiệp',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                _saveAsTemplate(name);
                Navigator.pop(context);
              }
            },
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class RuleItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  RuleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class RuleTemplate {
  final String name;
  final List<String> rules;
  final DateTime createdAt;

  RuleTemplate({
    required this.name,
    required this.rules,
    required this.createdAt,
  });

  String toJson() {
    return '$name|||${rules.join(';;;')}|||${createdAt.toIso8601String()}';
  }

  factory RuleTemplate.fromJson(String json) {
    final parts = json.split('|||');
    return RuleTemplate(
      name: parts[0],
      rules: parts[1].split(';;;'),
      createdAt: DateTime.parse(parts[2]),
    );
  }
}
