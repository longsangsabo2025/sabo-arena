import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/challenge_list_service.dart';
import '../../../services/challenge_service.dart';
import '../../../widgets/common/app_button.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';

/// Card widget to display a challenge/invite in list
/// Redesigned with 2-column layout and teal theme
class ChallengeCardWidgetRedesign extends StatefulWidget {
  final Map<String, dynamic> challenge;
  final VoidCallback? onTap;
  final bool isCompetitive; // true = thach_dau, false = giao_luu

  const ChallengeCardWidgetRedesign({
    super.key,
    required this.challenge,
    this.onTap,
    this.isCompetitive = true,
  });

  @override
  State<ChallengeCardWidgetRedesign> createState() =>
      _ChallengeCardWidgetRedesignState();
}

class _ChallengeCardWidgetRedesignState
    extends State<ChallengeCardWidgetRedesign> {
  @override
  Widget build(BuildContext context) {
    final challenger = widget.challenge['challenger'] as Map<String, dynamic>?;
    final matchConditions = ChallengeListService.instance.parseMatchConditions(
      widget.challenge['match_conditions'],
    );

    final gameType = matchConditions['game_type'] ?? '8-ball';

    // Get club data from database join (priority) or fallback to match_conditions
    final club = widget.challenge['club'] as Map<String, dynamic>?;
    final clubName = club?['name'] as String?;
    final clubAddress = club?['address'] as String?;
    final clubLogoUrl = club?['logo_url'] as String?;

    // Fallback to location from match_conditions if no club data
    final location = clubName ??
        matchConditions['location_name'] ??
        matchConditions['location'] ??
        'Chưa xác định';

    final scheduledTime = matchConditions['scheduled_time'];
    final spaPoints = widget.challenge['stakes_amount'] ?? 0;
    final avatarUrl = challenger?['avatar_url'] as String?;

    // Get rank restrictions
    final rankMin = matchConditions['rank_min'] as String?;
    final rankMax = matchConditions['rank_max'] as String?;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Màu chủ đạo: Teal cho thách đấu, Purple cho giao lưu
    final primaryColor = widget.isCompetitive
        ? const Color(0xFF00695C) // Teal for competitive
        : const Color(0xFF7B1FA2); // Purple for social
    final darkPrimary = widget.isCompetitive
        ? const Color(0xFF004D40) // Dark teal
        : const Color(0xFF6A1B9A); // Dark purple

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Avatar + Name + Badge
                Row(
                  children: [
                    // Avatar với unified component
                    UserAvatarWidget(
                      avatarUrl: avatarUrl,
                      userName: challenger?['display_name'],
                      rankCode: challenger?['rank'],
                      size: isTablet ? 56.0 : 48.0,
                      showRankBorder: true,
                    ),
                    SizedBox(width: isTablet ? 14 : 12),

                    // Name + Rank
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenger?['display_name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Rank Badge with unified component
                          UserRankBadgeWidget(
                            rankCode: challenger?['rank'],
                            style: RankBadgeStyle.compact,
                          ),
                        ],
                      ),
                    ),

                    // Challenge Type Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12 : 10,
                        vertical: isTablet ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, darkPrimary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isCompetitive
                                ? Icons.emoji_events
                                : Icons.groups,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: isTablet ? 6 : 4),
                          Text(
                            widget.isCompetitive ? 'Thách đấu' : 'Giao lưu',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Club Info Row - Logo + Tên + Địa chỉ
                if (clubName != null ||
                    clubAddress != null ||
                    clubLogoUrl != null) ...[
                  const SizedBox(height: 10),
                  _buildClubInfoRow(
                    clubLogoUrl,
                    clubName ?? location,
                    clubAddress,
                    isTablet,
                  ),
                ],

                const SizedBox(height: 10),

                // Info Grid - 2 cột
                _buildInfoGrid(
                  gameType,
                  scheduledTime,
                  location,
                  clubAddress,
                  clubLogoUrl,
                  spaPoints,
                  rankMin,
                  rankMax,
                  isTablet,
                ),

                // Message if exists
                if (widget.challenge['message'] != null &&
                    widget.challenge['message'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.challenge['message'].toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF050505),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Action Buttons Row
                Row(
                  children: [
                    // Accept Challenge Button
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: isTablet ? 44 : 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, darkPrimary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: widget.onTap,
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.isCompetitive
                                      ? 'Nhận thách đấu'
                                      : 'Chấp nhận',
                                  style: TextStyle(
                                    fontSize: isTablet ? 15 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Schedule Button
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: isTablet ? 44 : 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => _showScheduleModal(context),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                size: 16,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Hẹn lịch',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Note: _buildAvatar method removed - now using unified UserAvatarWidget

  /// Build 2-column info grid
  Widget _buildInfoGrid(
    String gameType,
    String? scheduledTime,
    String location,
    String? clubAddress,
    String? clubLogoUrl,
    int spaPoints,
    String? rankMin,
    String? rankMax,
    bool isTablet,
  ) {
    // Format rank range
    String rankRange = 'Tất cả';
    if (rankMin != null && rankMax != null) {
      rankRange = '$rankMin - $rankMax';
    } else if (rankMin != null) {
      rankRange = '$rankMin+';
    } else if (rankMax != null) {
      rankRange = '≤ $rankMax';
    }

    return Column(
      children: [
        // Row 1: Game Type + Time
        Row(
          children: [
            Expanded(
              child: _buildCompactInfoItem(
                Icons.sports_baseball,
                'Game',
                gameType,
                const Color(0xFF1E88E5),
                isTablet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactInfoItem(
                Icons.schedule,
                'Thời gian',
                ChallengeListService.instance.formatChallengeDateTime(
                  scheduledTime,
                ),
                const Color(0xFF10B981),
                isTablet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: SPA + Rank Range
        Row(
          children: [
            Expanded(
              child: _buildCompactInfoItem(
                Icons.monetization_on,
                'SPA',
                '$spaPoints điểm',
                const Color(0xFFFFB74D),
                isTablet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactInfoItem(
                Icons.emoji_events,
                'Yêu cầu Rank',
                rankRange,
                const Color(0xFF9C27B0),
                isTablet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Compact info item for 2-column layout
  Widget _buildCompactInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 10,
                    color: const Color(0xFF65676B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 13 : 12,
              color: const Color(0xFF050505),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build club info row - Logo + Tên + Icon vị trí + Địa chỉ
  Widget _buildClubInfoRow(
    String? clubLogoUrl,
    String clubName,
    String? clubAddress,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 10 : 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        children: [
          // Club logo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: clubLogoUrl != null && clubLogoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: clubLogoUrl,
                    width: isTablet ? 40 : 36,
                    height: isTablet ? 40 : 36,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: isTablet ? 40 : 36,
                      height: isTablet ? 40 : 36,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: isTablet ? 40 : 36,
                      height: isTablet ? 40 : 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        size: 20,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  )
                : Container(
                    width: isTablet ? 40 : 36,
                    height: isTablet ? 40 : 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_city,
                      size: 20,
                      color: Color(0xFFEF4444),
                    ),
                  ),
          ),
          SizedBox(width: isTablet ? 12 : 10),
          // Club name + address
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tên CLB
                Text(
                  clubName,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: const Color(0xFF050505),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (clubAddress != null && clubAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  // Icon vị trí + Địa chỉ
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clubAddress,
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 11,
                            color: const Color(0xFF65676B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show schedule modal for selecting date/time
  void _showScheduleModal(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 2));
    String selectedTimeSlot = '18:00 - 20:00';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: Color(0xFF00695C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hẹn lịch chơi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Chọn thời gian thuận tiện cho bạn',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF65676B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Date Picker
              const Text(
                'Chọn ngày',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF00695C),
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event,
                        color: Color(0xFF00695C),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Time Range Picker (Từ - Đến)
              const Text(
                'Khung giờ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Start Time
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF00695C),
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null) {
                          final timeString =
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          setModalState(() {
                            final parts = selectedTimeSlot.split(' - ');
                            selectedTimeSlot =
                                '$timeString - ${parts.length > 1 ? parts[1] : '20:00'}';
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Từ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedTimeSlot.split(' - ')[0],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // End Time
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now().replacing(
                            hour: TimeOfDay.now().hour + 2,
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF00695C),
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null) {
                          final timeString =
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          setModalState(() {
                            final parts = selectedTimeSlot.split(' - ');
                            selectedTimeSlot = '${parts[0]} - $timeString';
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Đến',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedTimeSlot.split(' - ').length > 1
                                  ? selectedTimeSlot.split(' - ')[1]
                                  : '20:00',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
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

              // Send Button - iOS style
              AppButton(
                label: 'Gửi lời mời hẹn lịch',
                type: AppButtonType.primary,
                size: AppButtonSize.large,
                customColor: const Color(0xFF00695C), // Brand teal green
                customTextColor: Colors.white,
                isLoading: isLoading,
                fullWidth: true,
                onPressed: isLoading
                    ? null
                    : () async {
                        setModalState(() => isLoading = true);

                        try {
                          final challengerId =
                              widget.challenge['challenger_id'];

                          await ChallengeService.instance.sendScheduleRequest(
                            targetUserId: challengerId,
                            scheduledDate: selectedDate,
                            timeSlot: selectedTimeSlot,
                            message: 'Lời mời hẹn lịch chơi bida',
                          );

                          if (modalContext.mounted) {
                            Navigator.pop(modalContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Đã gửi lời mời hẹn lịch!'),
                                  ],
                                ),
                                backgroundColor: Color(0xFF00695C),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (modalContext.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text('Lỗi: $e')),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } finally {
                          if (modalContext.mounted) {
                            setModalState(() => isLoading = false);
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
