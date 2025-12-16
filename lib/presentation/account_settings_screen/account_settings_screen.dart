import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_system/design_system.dart';
import '../../core/device/device_info.dart';
import '../../models/user_profile.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_app_bar.dart';

class AccountSettingsScreen extends StatefulWidget {
  final UserProfile userProfile;

  const AccountSettingsScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  // Note: AuthService removed as it was unused - use AuthService.instance directly when needed
  final UserService _userService = UserService.instance;

  bool _isLoading = false;
  String _selectedCategory = 'personal_info'; // For master-detail layout

  // Controllers for editable fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController.text = widget.userProfile.fullName;
    _emailController.text = widget.userProfile.email;
    _phoneController.text = widget.userProfile.phone ?? '';
    _locationController.text = widget.userProfile.location ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIPad = DeviceInfo.isIPad(context);
    final orientation = MediaQuery.of(context).orientation;
    final showMasterDetail = isIPad && orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Tài khoản',
        showBackButton: true,
        actions: [
          if (_hasChanges())
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                'Lưu',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : showMasterDetail
              ? _buildMasterDetailLayout()
              : _buildSingleColumnLayout(),
    );
  }

  // Master-Detail layout for iPad landscape
  Widget _buildMasterDetailLayout() {
    return Row(
      children: [
        // Master panel - Category list (40%, max 420px)
        Container(
          width: MediaQuery.of(context).size.width * 0.4,
          constraints: BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              right: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: _buildCategoryList(),
        ),
        // Detail panel - Selected category content (60%)
        Expanded(
          child: _buildDetailPanel(),
        ),
      ],
    );
  }

  // Single column layout for iPhone/iPad portrait
  Widget _buildSingleColumnLayout() {
    return SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Info Section
                  _buildSectionHeader('Thông tin cá nhân'),
                  SizedBox(height: 2.h),
                  _buildInfoCard(),

                  SizedBox(height: 3.h),

                  // Security Section
                  _buildSectionHeader('Bảo mật'),
                  SizedBox(height: 2.h),
                  _buildSecurityCard(),

                  SizedBox(height: 3.h),

                  // Privacy Section
                  _buildSectionHeader('Quyền riêng tư'),
                  SizedBox(height: 2.h),
                  _buildPrivacyCard(),

                  SizedBox(height: 3.h),

                  // Account Status
                  _buildSectionHeader('Trạng thái tài khoản'),
                  SizedBox(height: 2.h),
                  _buildAccountStatusCard(),

                  SizedBox(height: 3.h),

                  // Danger Zone
                  _buildSectionHeader('Vùng nguy hiểm', color: AppColors.error),
                  SizedBox(height: 2.h),
                  _buildDangerZoneCard(),

                  SizedBox(height: 4.h),
                ],
              ),
            );
  }

  // Category list for master panel
  Widget _buildCategoryList() {
    final categories = [
      {'id': 'personal_info', 'icon': Icons.person, 'title': 'Thông tin cá nhân'},
      {'id': 'security', 'icon': Icons.security, 'title': 'Bảo mật'},
      {'id': 'privacy', 'icon': Icons.privacy_tip, 'title': 'Quyền riêng tư'},
      {'id': 'account_status', 'icon': Icons.info, 'title': 'Trạng thái tài khoản'},
      {'id': 'danger_zone', 'icon': Icons.warning, 'title': 'Vùng nguy hiểm'},
    ];

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategory == category['id'];
        final isDangerZone = category['id'] == 'danger_zone';

        return Container(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : null,
          child: ListTile(
            leading: Icon(
              category['icon'] as IconData,
              color: isDangerZone 
                  ? AppColors.error 
                  : (isSelected ? Theme.of(context).colorScheme.primary : AppColors.textSecondary),
            ),
            title: Text(
              category['title'] as String,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isDangerZone 
                    ? AppColors.error 
                    : (isSelected ? Theme.of(context).colorScheme.primary : AppColors.textPrimary),
              ),
            ),
            onTap: () {
              setState(() {
                _selectedCategory = category['id'] as String;
              });
            },
          ),
        );
      },
    );
  }

  // Detail panel showing selected category content
  Widget _buildDetailPanel() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedCategory == 'personal_info') ...[
            _buildSectionHeader('Thông tin cá nhân'),
            SizedBox(height: 2.h),
            _buildInfoCard(),
          ] else if (_selectedCategory == 'security') ...[
            _buildSectionHeader('Bảo mật'),
            SizedBox(height: 2.h),
            _buildSecurityCard(),
          ] else if (_selectedCategory == 'privacy') ...[
            _buildSectionHeader('Quyền riêng tư'),
            SizedBox(height: 2.h),
            _buildPrivacyCard(),
          ] else if (_selectedCategory == 'account_status') ...[
            _buildSectionHeader('Trạng thái tài khoản'),
            SizedBox(height: 2.h),
            _buildAccountStatusCard(),
          ] else if (_selectedCategory == 'danger_zone') ...[
            _buildSectionHeader('Vùng nguy hiểm', color: AppColors.error),
            SizedBox(height: 2.h),
            _buildDangerZoneCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
          _buildEditableField(
            label: 'Họ và tên',
            controller: _fullNameController,
            icon: Icons.person,
          ),
          Divider(height: 1),
          _buildEditableField(
            label: 'Email',
            controller: _emailController,
            icon: Icons.email,
            readOnly: true, // Email usually cannot be changed
            helperText: 'Email không thể thay đổi',
          ),
          Divider(height: 1),
          _buildEditableField(
            label: 'Số điện thoại',
            controller: _phoneController,
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          Divider(height: 1),
          _buildEditableField(
            label: 'Địa chỉ',
            controller: _locationController,
            icon: Icons.location_on,
          ),
          Divider(height: 1),
          _buildInfoRow(
            label: 'User ID',
            value: widget.userProfile.id,
            icon: Icons.fingerprint,
            onTap: () => _copyToClipboard(widget.userProfile.id, 'User ID'),
          ),
          Divider(height: 1),
          _buildInfoRow(
            label: 'Vai trò',
            value: _getRoleDisplay(widget.userProfile.role),
            icon: Icons.badge,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
          _buildActionRow(
            label: 'Đổi mật khẩu',
            icon: Icons.lock,
            onTap: _changePassword,
          ),
          Divider(height: 1),
          _buildActionRow(
            label: 'Xác thực hai yếu tố (2FA)',
            icon: Icons.security,
            trailing: Switch(
              value: false, // TODO: Implement 2FA status
              onChanged: (value) => _toggle2FA(value),
            ),
          ),
          Divider(height: 1),
          _buildActionRow(
            label: 'Phiên đăng nhập',
            icon: Icons.devices,
            onTap: _viewLoginSessions,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
          _buildActionRow(
            label: 'Hồ sơ công khai',
            icon: Icons.public,
            trailing: Switch(
              value: true, // TODO: Get from profile settings
              onChanged: (value) => _togglePublicProfile(value),
            ),
          ),
          Divider(height: 1),
          _buildActionRow(
            label: 'Hiển thị email',
            icon: Icons.email_outlined,
            trailing: Switch(
              value: false, // TODO: Get from profile settings
              onChanged: (value) => _toggleShowEmail(value),
            ),
          ),
          Divider(height: 1),
          _buildActionRow(
            label: 'Hiển thị số điện thoại',
            icon: Icons.phone_outlined,
            trailing: Switch(
              value: false, // TODO: Get from profile settings
              onChanged: (value) => _toggleShowPhone(value),
            ),
          ),
          Divider(height: 1),
          _buildActionRow(
            label: 'Danh sách chặn',
            icon: Icons.block,
            onTap: _viewBlockedUsers,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
          _buildInfoRow(
            label: 'Trạng thái',
            value: 'Hoạt động',
            icon: Icons.check_circle,
            valueColor: AppColors.success,
          ),
          Divider(height: 1),
          _buildInfoRow(
            label: 'Ngày tạo',
            value: _formatDate(widget.userProfile.createdAt),
            icon: Icons.calendar_today,
          ),
          Divider(height: 1),
          _buildInfoRow(
            label: 'Lần đăng nhập gần nhất',
            value: _formatDate(DateTime.now()), // TODO: Get from auth
            icon: Icons.access_time,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        children: [
          _buildActionRow(
            label: 'Vô hiệu hóa tài khoản',
            icon: Icons.pause_circle,
            onTap: _deactivateAccount,
            textColor: AppColors.error,
          ),
          Divider(height: 1, color: AppColors.error),
          _buildActionRow(
            label: 'Xóa tài khoản',
            icon: Icons.delete_forever,
            onTap: _deleteAccount,
            textColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    String? helperText,
    TextInputType? keyboardType,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      subtitle: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          helperText: helperText,
          helperStyle: TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: valueColor,
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.copy, size: 18, color: AppColors.textTertiary)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildActionRow({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? Theme.of(context).colorScheme.primary)
              .withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: textColor ?? Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: AppColors.textTertiary)
              : null),
      onTap: onTap,
    );
  }

  bool _hasChanges() {
    return _fullNameController.text != widget.userProfile.fullName ||
        _phoneController.text != (widget.userProfile.phone ?? '') ||
        _locationController.text != (widget.userProfile.location ?? '');
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges()) return;

    setState(() => _isLoading = true);

    try {
      await _userService.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.textOnPrimary),
                SizedBox(width: 8),
                Text('Cập nhật thông tin thành công'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changes
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppColors.textOnPrimary),
                SizedBox(width: 8),
                Flexible(child: Text('Lỗi: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check, color: AppColors.textOnPrimary),
            SizedBox(width: 8),
            Text('Đã sao chép $label'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getRoleDisplay(String? role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'super_admin':
        return 'Quản trị viên cấp cao';
      case 'club_owner':
        return 'Chủ câu lạc bộ';
      case 'user':
        return 'Người dùng';
      default:
        return 'Người dùng';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không xác định';
    
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Vừa xong';
        }
        return '${diff.inMinutes} phút trước';
      }
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(),
    );
  }

  void _toggle2FA(bool value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác thực hai yếu tố'),
        content: Text(
          value
              ? 'Bạn có muốn bật xác thực hai yếu tố? Điều này sẽ tăng cường bảo mật cho tài khoản của bạn.'
              : 'Bạn có muốn tắt xác thực hai yếu tố?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
            child: Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _viewLoginSessions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Phiên đăng nhập')),
          body: Center(
            child: Text('Tính năng đang phát triển'),
          ),
        ),
      ),
    );
  }

  void _togglePublicProfile(bool value) {
    // TODO: Implement profile privacy settings update via UserService
    // Need to add updatePrivacySettings() method in UserService
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng đang phát triển'),
      ),
    );
  }

  void _toggleShowEmail(bool value) {
    // TODO: Implement email visibility settings update via UserService
    // Need to add updatePrivacySettings() method in UserService
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng đang phát triển'),
      ),
    );
  }

  void _toggleShowPhone(bool value) {
    // TODO: Implement phone visibility settings update via UserService
    // Need to add updatePrivacySettings() method in UserService
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Số điện thoại sẽ hiển thị công khai'
              : 'Số điện thoại đã được ẩn',
        ),
      ),
    );
  }

  void _viewBlockedUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Danh sách chặn')),
          body: Center(
            child: Text('Tính năng đang phát triển'),
          ),
        ),
      ),
    );
  }

  void _deactivateAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vô hiệu hóa tài khoản'),
        content: Text(
          'Bạn có chắc muốn vô hiệu hóa tài khoản? Tài khoản của bạn sẽ bị ẩn và bạn có thể kích hoạt lại sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tính năng đang phát triển'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa tài khoản', style: TextStyle(color: AppColors.error)),
        content: Text(
          'CẢNH BÁO: Hành động này KHÔNG THỂ HOÀN TÁC!\n\n'
          'Tất cả dữ liệu của bạn sẽ bị xóa vĩnh viễn, bao gồm:\n'
          '• Thông tin cá nhân\n'
          '• Lịch sử trận đấu\n'
          '• Bài đăng và hình ảnh\n'
          '• Bạn bè và kết nối\n\n'
          'Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Xóa tài khoản'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final TextEditingController confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhập "XOA TAI KHOAN" để xác nhận:'),
            SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'XOA TAI KHOAN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text.trim() == 'XOA TAI KHOAN') {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tính năng đang phát triển'),
                    backgroundColor: AppColors.error,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vui lòng nhập chính xác để xác nhận'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Đổi mật khẩu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: !_showCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _showCurrentPassword = !_showCurrentPassword),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
                helperText: 'Ít nhất 6 ký tự',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _showNewPassword = !_showNewPassword),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Đổi mật khẩu'),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mật khẩu mới phải có ít nhất 6 ký tự'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mật khẩu xác nhận không khớp'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.textOnPrimary),
                SizedBox(width: 8),
                Text('Đổi mật khẩu thành công'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppColors.textOnPrimary),
                SizedBox(width: 8),
                Flexible(child: Text('Lỗi: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
