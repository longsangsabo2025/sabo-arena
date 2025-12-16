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
          // Header with Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thông tin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF050505), // Facebook black
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
                  child: const Text(
                    'Chỉnh sửa',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0866FF), // Facebook blue
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Info items
          if (userInfo['bio'] != null && (userInfo['bio'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'description',
              iconColor: const Color(0xFF65676B), // Gray
              text: userInfo['bio'] as String,
              isMultiLine: true,
            ),

          if (userInfo['location'] != null &&
              (userInfo['location'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'location_on',
              iconColor: const Color(0xFFF3425F), // Facebook red
              text: 'Sống tại ${userInfo['location']}',
            ),

          if (userInfo['hometown'] != null &&
              (userInfo['hometown'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'home',
              iconColor: const Color(0xFF65676B), // Gray
              text: 'Đến từ ${userInfo['hometown']}',
            ),

          if (userInfo['workplace'] != null &&
              (userInfo['workplace'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'work',
              iconColor: const Color(0xFF9B51E0), // Purple
              text: 'Làm việc tại ${userInfo['workplace']}',
            ),

          if (userInfo['education'] != null &&
              (userInfo['education'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'school',
              iconColor: const Color(0xFF0866FF), // Blue
              text: 'Học tại ${userInfo['education']}',
            ),

          if (userInfo['relationship'] != null &&
              (userInfo['relationship'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'favorite',
              iconColor: const Color(0xFFF3425F), // Red
              text: _getRelationshipText(userInfo['relationship'] as String),
            ),

          if (userInfo['phone'] != null &&
              (userInfo['phone'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'phone',
              iconColor: const Color(0xFF45BD62), // Green
              text: userInfo['phone'] as String,
            ),

          if (userInfo['email'] != null &&
              (userInfo['email'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'email',
              iconColor: const Color(0xFF0866FF), // Blue
              text: userInfo['email'] as String,
            ),

          if (userInfo['website'] != null &&
              (userInfo['website'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'link',
              iconColor: const Color(0xFF0866FF), // Blue
              text: userInfo['website'] as String,
              isLink: true,
            ),

          if (userInfo['birthday'] != null &&
              (userInfo['birthday'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'cake',
              iconColor: const Color(0xFFF7B928), // Yellow
              text: 'Sinh nhật ${userInfo['birthday']}',
            ),

          // Gender
          if (userInfo['gender'] != null &&
              (userInfo['gender'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'person',
              iconColor: const Color(0xFF65676B), // Gray
              text: _getGenderText(userInfo['gender'] as String),
            ),

          // Joined date
          if (userInfo['joinedDate'] != null &&
              (userInfo['joinedDate'] as String).isNotEmpty)
            _buildInfoItem(
              icon: 'calendar_today',
              iconColor: const Color(0xFF65676B), // Gray
              text: 'Tham gia ${userInfo['joinedDate']}',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
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
                    ? const Color(0xFF0866FF) // Blue for links
                    : const Color(0xFF050505), // Black for normal text
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
