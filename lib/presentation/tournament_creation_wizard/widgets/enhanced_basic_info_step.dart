import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import 'package:sabo_arena/core/constants/ranking_constants.dart';
import '../widgets/form_enhancement_widgets.dart';
import '../widgets/tournament_cover_upload_widget.dart';

class EnhancedBasicInfoStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;

  const EnhancedBasicInfoStep({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<EnhancedBasicInfoStep> createState() => _EnhancedBasicInfoStepState();
}

class _EnhancedBasicInfoStepState extends State<EnhancedBasicInfoStep> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form validation
  final Map<String, String> _errors = {};
  final Map<String, String> _warnings = {};
  final Map<String, String> _successes = {};

  // SABO ranking system - MOVED TO STEP 3
  // final List<String> _saboRanks = RankingConstants.RANK_ORDER;

  @override
  void initState() {
    super.initState();
    _initializeFromData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeFromData() {
    _nameController.text = widget.data['name'] ?? '';
    _descriptionController.text = widget.data['description'] ?? '';

    // Ensure defaults are set
    widget.data['gameType'] ??= '8-ball';
    widget.data['format'] ??= 'single_elimination';
    widget.data['maxParticipants'] ??= 16;
  }

  void _validateAndUpdate() {
    _errors.clear();
    _warnings.clear();
    _successes.clear();

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final gameType = widget.data['gameType'] ?? '8-ball';
    final format = widget.data['format'] ?? 'single_elimination';
    final maxParticipants = widget.data['maxParticipants'] ?? 16;

    // Validation
    if (name.isEmpty) {
      _errors['Tên giải đấu'] = 'Bắt buộc phải có tên giải đấu';
    } else if (name.length < 3) {
      _errors['Tên giải đấu'] = 'Tên phải có ít nhất 3 ký tự';
    } else if (name.length > 50) {
      _errors['Tên giải đấu'] = 'Tên không được quá 50 ký tự';
    } else {
      _successes['Tên giải đấu'] = 'Tên hợp lệ';
    }

    if (description.isNotEmpty) {
      if (description.length < 10) {
        _warnings['Mô tả'] = 'Nên có mô tả chi tiết hơn (ít nhất 10 ký tự)';
      } else if (description.length > 500) {
        _errors['Mô tả'] = 'Mô tả không được quá 500 ký tự';
      } else {
        _successes['Mô tả'] = 'Mô tả chi tiết tốt';
      }
    }

    if (maxParticipants < 4) {
      _warnings['Số người tham gia'] = 'Ít nhất 4 người để có giải đấu thú vị';
    } else {
      _successes['Cấu hình'] = 'Thiết lập cơ bản hoàn tất';
    }

    // Rank restrictions validation
    final minRank = widget.data['minRank'] as String?;
    final maxRank = widget.data['maxRank'] as String?;

    if (minRank != null && maxRank != null) {
      final minIndex = RankingConstants.RANK_ORDER.indexOf(minRank);
      final maxIndex = RankingConstants.RANK_ORDER.indexOf(maxRank);

      if (minIndex > maxIndex) {
        _errors['Hạng'] = 'Hạng tối thiểu không thể cao hơn hạng tối đa';
      } else {
        _successes['Hạng'] = 'Giới hạn hạng hợp lệ';
      }
    } else if (minRank != null || maxRank != null) {
      _successes['Hạng'] = 'Có giới hạn hạng được thiết lập';
    }

    // Update data
    widget.onDataChanged({
      'name': name,
      'description': description,
      'gameType': gameType,
      'format': format,
      'maxParticipants': maxParticipants,
      'minRank': widget.data['minRank'],
      'maxRank': widget.data['maxRank'],
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final completionPercentage = _calculateCompletion();

    return Container(
      color: Color(0xFFF8F9FA),
      child: Column(
        children: [
          // 🎨 Compact header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator & completion in one row
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 16),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'BƯỚC 1/4',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        completionPercentage == 100
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${completionPercentage.toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Title compact
                  Text(
                    'Thông tin cơ bản',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completionPercentage / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Validation feedback (compact)
          if (_errors.isNotEmpty || _warnings.isNotEmpty)
            ValidationFeedbackWidget(
              errors: _errors,
              warnings: _warnings,
              successes: _successes,
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Professional card container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tournament name with validation icon
                        _buildProfessionalFormField(
                          label: 'Tên giải đấu',
                          value: _nameController.text,
                          hintText: 'VD: Giải 8-Ball Mùa Thu 2025',
                          icon: Icons.emoji_events_outlined,
                          isValid:
                              !_errors.containsKey('Tên giải đấu') &&
                              _nameController.text.length >= 3,
                          onChanged: (value) {
                            _nameController.text = value;
                            _validateAndUpdate();
                          },
                        ),

                        _buildProfessionalDivider(),

                        // Description
                        _buildProfessionalFormField(
                          label: 'Mô tả giải đấu',
                          value: _descriptionController.text,
                          hintText:
                              'Mô tả chi tiết về quy định, giải thưởng...',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          isValid:
                              _descriptionController.text.isEmpty ||
                              _descriptionController.text.length >= 10,
                          onChanged: (value) {
                            _descriptionController.text = value;
                            _validateAndUpdate();
                          },
                        ),

                        _buildProfessionalDivider(),

                        // Game type with chips
                        _buildGameTypeChipSelector(),

                        _buildProfessionalDivider(),

                        // Tournament format with chips
                        _buildFormatChipSelector(),

                        _buildProfessionalDivider(),

                        // Max participants with visual grid
                        _buildParticipantsVisualSelector(),

                        // Rank restrictions - MOVED TO STEP 3 (Requirements Card)
                        // _buildProfessionalDivider(),
                        // _buildRankRestrictionsSelector(),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Tournament Cover Image Upload
                  TournamentCoverUploadWidget(
                    coverImageUrl: widget.data['coverImageUrl'] as String?,
                    onImageSelected: (bytes, fileName) {
                      widget.onDataChanged({
                        ...widget.data,
                        'coverImageBytes': bytes,
                        'coverImageFileName': fileName,
                      });
                    },
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate completion percentage
  double _calculateCompletion() {
    int completed = 0;
    int total = 4; // Name, GameType, Format, Participants

    if (_nameController.text.length >= 3) completed++;
    if (widget.data['gameType'] != null) completed++;
    if (widget.data['format'] != null) completed++;
    if (widget.data['maxParticipants'] != null) completed++;

    return (completed / total) * 100;
  }

  /// Professional divider
  Widget _buildProfessionalDivider() {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey.shade200,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  /// Professional form field with validation icon
  Widget _buildProfessionalFormField({
    required String label,
    required String value,
    required String hintText,
    required IconData icon,
    required Function(String) onChanged,
    bool isValid = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with validation status
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 20),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              if (value.isNotEmpty)
                Icon(
                  isValid ? Icons.check_circle : Icons.circle_outlined,
                  color: isValid ? Colors.green : Colors.grey.shade400,
                  size: 20,
                ),
            ],
          ),
          SizedBox(height: 12.h),
          // Input field
          TextField(
            controller: TextEditingController(text: value)
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: value.length),
              ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
            style: TextStyle(fontSize: 15, color: Colors.black87),
            maxLines: maxLines,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Game type chip selector (professional design)
  Widget _buildGameTypeChipSelector() {
    final gameTypes = [
      {'id': '8-ball', 'name': '8-Ball', 'icon': '🎱'},
      {'id': '9-ball', 'name': '9-Ball', 'icon': '9️⃣'},
      {'id': '10-ball', 'name': '10-Ball', 'icon': '🔟'},
      // {'id': 'straight-pool', 'name': 'Straight Pool', 'icon': '🎯'}, // Tạm ẩn - chưa phát triển
    ];

    final currentValue = widget.data['gameType'] ?? '8-ball';

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_bar_outlined,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              SizedBox(width: 8.w),
              Text(
                'Loại bi-a',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: gameTypes.map((gameType) {
              final isSelected = currentValue == gameType['id'];
              return GestureDetector(
                onTap: () {
                  widget.onDataChanged({'gameType': gameType['id']});
                  _validateAndUpdate();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gameType['icon'] as String,
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        gameType['name'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (isSelected) ...[
                        SizedBox(width: 8.w),
                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Format chip selector
  Widget _buildFormatChipSelector() {
    final formats = [
      {'id': 'single_elimination', 'name': 'Loại trực tiếp', 'icon': '⚡', 'enabled': true},
      {'id': 'double_elimination', 'name': 'Loại kép', 'icon': '🔄', 'enabled': false, 'comingSoon': true},
      {'id': 'sabo_de16', 'name': 'SABO DE16', 'icon': '🏆', 'enabled': true},
      {'id': 'sabo_de24', 'name': 'SABO DE24', 'icon': '🎯', 'badge': '✨ NEW', 'enabled': true},
      {'id': 'sabo_de32', 'name': 'SABO DE32', 'icon': '👑', 'enabled': true},
      {'id': 'sabo_de64', 'name': 'SABO DE64', 'icon': '🚀', 'badge': '🏆 PRO', 'enabled': true},
      {'id': 'round_robin', 'name': 'Vòng tròn', 'icon': '🔁', 'enabled': false, 'comingSoon': true},
      {'id': 'swiss_system', 'name': 'Swiss', 'icon': '♟️', 'enabled': false, 'comingSoon': true},
    ];

    final currentValue = widget.data['format'] ?? 'single_elimination';

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              SizedBox(width: 8.w),
              Text(
                'Thể thức thi đấu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: formats.map((format) {
              final isSelected = currentValue == format['id'];
              final isEnabled = format['enabled'] as bool? ?? true;
              final comingSoon = format['comingSoon'] as bool? ?? false;
              
              return Opacity(
                opacity: isEnabled ? 1.0 : 0.5,
                child: GestureDetector(
                  onTap: isEnabled ? () {
                    widget.onDataChanged({'format': format['id']});
                    _validateAndUpdate();
                  } : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected && isEnabled
                          ? LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withValues(alpha: 0.8),
                              ],
                            )
                          : null,
                      color: isSelected && isEnabled 
                          ? null 
                          : isEnabled 
                              ? Colors.grey.shade100
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected && isEnabled
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                        width: isSelected && isEnabled ? 2 : 1,
                      ),
                      boxShadow: isSelected && isEnabled
                          ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          format['icon'] as String,
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          format['name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected && isEnabled 
                                ? Colors.white 
                                : isEnabled
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                            decoration: !isEnabled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (isSelected && isEnabled) ...[
                          SizedBox(width: 8.w),
                          Icon(Icons.check_circle, color: Colors.white, size: 16),
                        ],
                        if (format['badge'] != null && isEnabled) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              format['badge'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? Colors.white
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                        if (comingSoon) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Sắp có',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Participants visual selector with grid
  Widget _buildParticipantsVisualSelector() {
    // Get allowed participant options based on selected format
    final format = widget.data['format'] ?? 'single_elimination';
    final List<int> participantOptions = _getAllowedParticipants(format);
    final currentValue = widget.data['maxParticipants'] ?? 16;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              SizedBox(width: 8.w),
              Text(
                'Số người tham gia',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Warning for fixed participant formats
          if ([
            'sabo_de16',
            'sabo_de32',
            'sabo_de64',
            'double_elimination',
          ].contains(format)) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 18,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      format == 'sabo_de16'
                          ? '⚠️ SABO DE16 yêu cầu ĐÚNG 16 người'
                          : format == 'sabo_de32'
                          ? '⚠️ SABO DE32 yêu cầu ĐÚNG 32 người'
                          : format == 'sabo_de64'
                          ? '⚠️ SABO DE64 yêu cầu ĐÚNG 64 người (4 bảng × 16)'
                          : 'Double Elimination yêu cầu 16 người',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],
          Row(
            children: participantOptions.map((option) {
              final isSelected = currentValue == option;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onDataChanged({'maxParticipants': option});
                    _validateAndUpdate();
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: option != 64 ? 8.w : 0),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withValues(alpha: 0.8),
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$option',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'người',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 🗑️ REMOVED: Rank restrictions selector
  // This feature has been moved to Step 3 (Enhanced Prizes Step V2)
  // to avoid duplication and better organize requirements together

  /// Get allowed participant counts based on tournament format
  List<int> _getAllowedParticipants(String format) {
    switch (format) {
      case 'sabo_de16':
        return [16]; // SABO DE16 requires exactly 16 players
      case 'sabo_de24':
        return [24]; // SABO DE24 requires exactly 24 players
      case 'sabo_de32':
        return [32]; // SABO DE32 requires exactly 32 players
      case 'sabo_de64':
        return [64]; // SABO DE64 requires exactly 64 players
      case 'double_elimination':
        return [16]; // Double Elimination typically works with 16 players
      case 'single_elimination':
        return [4, 8, 16, 32, 64]; // Single Elimination supports power of 2
      case 'round_robin':
      case 'swiss_system':
        return [4, 6, 8, 12, 16, 24, 32]; // These formats are more flexible
      default:
        return [4, 8, 16, 32, 64]; // Default: power of 2
    }
  }
}
