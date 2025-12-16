import 'package:flutter/material.dart';

import '../../../models/achievement.dart';
import '../../../services/achievement_service.dart';
import '../../../widgets/custom_icon_widget.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class AchievementsSectionWidget extends StatefulWidget {
  final String userId;
  final VoidCallback? onViewAll; // Add optional callback

  const AchievementsSectionWidget({
    super.key,
    required this.userId,
    this.onViewAll,
  });

  @override
  State<AchievementsSectionWidget> createState() =>
      _AchievementsSectionWidgetState();
}

class _AchievementsSectionWidgetState extends State<AchievementsSectionWidget> {
  final AchievementService _achievementService = AchievementService.instance;
  List<Achievement> _achievements = [];
  Map<String, int> _achievementStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      setState(() => _isLoading = true);

      final achievements = await _achievementService.getUserAchievements(
        widget.userId,
      );
      final stats = await _achievementService.getAchievementStats(
        widget.userId,
      );

      setState(() {
        _achievements = achievements
            .take(6)
            .toList(); // Limit to 6 achievements
        _achievementStats = stats;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF), // White background
        border: Border(
          top: BorderSide(color: Color(0xFFE4E6EB), width: 0.5),
          bottom: BorderSide(color: Color(0xFFE4E6EB), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thành tích',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF050505), // Facebook black
                ),
              ),
              if (widget.onViewAll != null)
                TextButton(
                  onPressed: widget.onViewAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0866FF), // Facebook blue
                    ),
                  ),
                ),
            ],
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0866FF), // Facebook blue
              ),
            ),
          ] else if (_achievements.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFF0F2F5,
                ), // Facebook light gray background
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  CustomIconWidget(
                    iconName: 'emoji_events_outlined',
                    color: Color(0xFF65676B), // Facebook gray
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có thành tích nào',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF050505),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tham gia trận đấu và giải đấu để mở khóa thành tích!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF65676B),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Achievement stats summary
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F3FF), // Light blue background
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    'Đã mở khóa',
                    '${_achievementStats['unlocked'] ?? 0}',
                    const Color(0xFF0866FF), // Facebook blue
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: const Color(0xFFE4E6EB), // Facebook divider
                  ),
                  _buildStatItem(
                    'Tổng cộng',
                    '${_achievementStats['total'] ?? 0}',
                    const Color(0xFF050505), // Facebook black
                  ),
                ],
              ),
            ),

            // Achievement grid
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(_achievements[index]);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5), // Facebook light gray background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBorderColor(achievement.category),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Achievement icon with badge color
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getBadgeColor(achievement.category),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: achievement.iconUrl ?? 'emoji_events',
                color: const Color(0xFFFFFFFF),
                size: 24,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Achievement name
          Text(
            achievement.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF050505), // Facebook black
            ),
          ),

          const SizedBox(height: 4),

          // Achievement category
          Text(
            _getCategoryDisplayName(achievement.category),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFF65676B), // Facebook gray
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String category) {
    switch (category.toLowerCase()) {
      case 'victory':
        return Colors.green;
      case 'participation':
        return Colors.blue;
      case 'social':
        return Colors.purple;
      case 'skill':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getBorderColor(String category) {
    return _getBadgeColor(category).withValues(alpha: 0.3);
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'victory':
        return 'Chiến thắng';
      case 'participation':
        return 'Tham gia';
      case 'social':
        return 'Xã hội';
      case 'skill':
        return 'Kỹ năng';
      default:
        return 'Khác';
    }
  }
}

