import 'package:flutter/material.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Facebook-style Profile Info Section Widget
/// Displays user information in Facebook 2025 design standards
///
/// Design specs:
/// - White background #FFFFFF
/// - 0.5px borders #E4E6EB
/// - 16px padding
/// - Icons 24px with colors
/// - Typography: 15px body, 13px secondary
class ProfileInfoSectionWidget extends StatelessWidget {
  final Map<String, dynamic> userInfo;
  final VoidCallback? onEditInfo;

  const ProfileInfoSectionWidget({
    super.key,
    required this.userInfo,
    this.onEditInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thông tin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (onEditInfo != null)
                TextButton(
                  onPressed: onEditInfo,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Chỉnh sửa',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Info items
          if (userInfo['bio'] != null && (userInfo['bio'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'description',
              iconColor: const Color(0xFF65676B), // Gray
              text: userInfo['bio'] as String,
              isMultiLine: true,
            ),

          if (userInfo['location'] != null &&
              (userInfo['location'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'location_on',
              iconColor: const Color(0xFFF3425F), // Facebook red
              text: 'Sống tại ${userInfo['location']}',
            ),

          if (userInfo['hometown'] != null &&
              (userInfo['hometown'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'home',
              iconColor: const Color(0xFF65676B), // Gray
              text: 'Đến từ ${userInfo['hometown']}',
            ),

          if (userInfo['workplace'] != null &&
              (userInfo['workplace'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'work',
              iconColor: const Color(0xFF9B51E0), // Purple
              text: 'Làm việc tại ${userInfo['workplace']}',
            ),

          if (userInfo['education'] != null &&
              (userInfo['education'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'school',
              iconColor: const Color(0xFF0866FF), // Blue
              text: 'Học tại ${userInfo['education']}',
            ),

          if (userInfo['relationship'] != null &&
              (userInfo['relationship'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'favorite',
              iconColor: const Color(0xFFF3425F), // Red
              text: _getRelationshipText(userInfo['relationship'] as String),
            ),

          if (userInfo['phone'] != null &&
              (userInfo['phone'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'phone',
              iconColor: const Color(0xFF45BD62), // Green
              text: userInfo['phone'] as String,
            ),

          if (userInfo['email'] != null &&
              (userInfo['email'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'email',
              iconColor: const Color(0xFF0866FF), // Blue
              text: userInfo['email'] as String,
            ),

          if (userInfo['website'] != null &&
              (userInfo['website'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'link',
              iconColor: const Color(0xFF0866FF), // Blue
              text: userInfo['website'] as String,
              isLink: true,
            ),

          if (userInfo['birthday'] != null &&
              (userInfo['birthday'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'cake',
              iconColor: const Color(0xFFF7B928), // Yellow
              text: 'Sinh nhật ${userInfo['birthday']}',
            ),

          // Gender
          if (userInfo['gender'] != null &&
              (userInfo['gender'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'person',
              iconColor: const Color(0xFF65676B), // Gray
              text: _getGenderText(userInfo['gender'] as String),
            ),

          // Joined date
          if (userInfo['joinedDate'] != null &&
              (userInfo['joinedDate'] as String).isNotEmpty)
            _buildInfoItem(context,
              icon: 'calendar_today',
              iconColor: const Color(0xFF65676B), // Gray
              text: 'Tham gia ${userInfo['joinedDate']}',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required String icon,
    required Color iconColor,
    required String text,
    bool isMultiLine = false,
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: isMultiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          // Icon
          CustomIconWidget(iconName: icon, color: iconColor, size: 24),
          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isLink
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                decoration: isLink ? TextDecoration.underline : null,
              ),
              maxLines: isMultiLine ? null : 1,
              overflow: isMultiLine ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getRelationshipText(String status) {
    switch (status.toLowerCase()) {
      case 'single':
        return 'Độc thân';
      case 'in_relationship':
        return 'Đang hẹn hò';
      case 'engaged':
        return 'Đã đính hôn';
      case 'married':
        return 'Đã kết hôn';
      case 'complicated':
        return 'Phức tạp';
      default:
        return status;
    }
  }

  String _getGenderText(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      case 'other':
        return 'Khác';
      default:
        return gender;
    }
  }
}
