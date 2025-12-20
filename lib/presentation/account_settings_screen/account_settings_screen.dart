import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_system/design_system.dart';
import '../../core/device/device_info.dart';
import '../../models/user_profile.dart';
import '../../services/user_service.dart';
import '../../services/privacy_service.dart';
import '../../services/user_blocks_service.dart';
import '../../services/account_management_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/common/app_button.dart';

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
  final UserService _userService = UserService.instance;
  final PrivacyService _privacyService = PrivacyService.instance;
  final AccountManagementService _accountService =
      AccountManagementService.instance;

  bool _isLoading = false;
  String _selectedCategory = 'personal_info'; // For master-detail layout

  // Privacy settings state
  UserPrivacySettings? _privacySettings;

  // Controllers for editable fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadPrivacySettings();
  }

  void _initializeControllers() {
    _fullNameController.text = widget.userProfile.fullName;
    _emailController.text = widget.userProfile.email;
    _phoneController.text = widget.userProfile.phone ?? '';
    _locationController.text = widget.userProfile.location ?? '';
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final settings = await _privacyService.getMyPrivacySettings();
      if (mounted) {
        setState(() {
          _privacySettings = settings;
        });
      }
    } catch (e) {
      // Default to public profile if error
      if (mounted) {
        setState(() {
          _privacySettings = UserPrivacySettings(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });
      }
    }
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
      {
        'id': 'personal_info',
        'icon': Icons.person,
        'title': 'Thông tin cá nhân'
      },
      {'id': 'security', 'icon': Icons.security, 'title': 'Bảo mật'},
      {'id': 'privacy', 'icon': Icons.privacy_tip, 'title': 'Quyền riêng tư'},
      {
        'id': 'account_status',
        'icon': Icons.info,
        'title': 'Trạng thái tài khoản'
      },
      {'id': 'danger_zone', 'icon': Icons.warning, 'title': 'Vùng nguy hiểm'},
    ];

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategory == category['id'];
        final isDangerZone = category['id'] == 'danger_zone';

        return Container(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : null,
          child: ListTile(
            leading: Icon(
              category['icon'] as IconData,
              color: isDangerZone
                  ? AppColors.error
                  : (isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.textSecondary),
            ),
            title: Text(
              category['title'] as String,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isDangerZone
                    ? AppColors.error
                    : (isSelected
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.textPrimary),
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
              value: _privacySettings?.profilePublic ?? true,
              onChanged: (value) => _togglePublicProfile(value),
            ),
          ),
          Divider(height: 1),
          _buildActionRow(
            label: 'Hiển thị email',
            icon: Icons.email_outlined,
            trailing: Switch(
              value: _privacySettings?.showEmail ?? false,
              onChanged: (value) => _toggleShowEmail(value),
            ),
          ),
          Divider(height: 1),
          _buildActionRow(
            label: 'Hiển thị số điện thoại',
            icon: Icons.phone_outlined,
            trailing: Switch(
              value: _privacySettings?.showPhone ?? false,
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
          AppButton(
            label: 'Xác nhận',
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
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

  void _togglePublicProfile(bool value) async {
    setState(() => _isLoading = true);
    try {
      final updated = await _privacyService.updatePrivacySettings(
        profilePublic: value,
      );
      if (mounted) {
        setState(() {
          _privacySettings = updated;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Hồ sơ của bạn giờ đây công khai'
                  : 'Hồ sơ của bạn đã được ẩn',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleShowEmail(bool value) async {
    setState(() => _isLoading = true);
    try {
      final updated = await _privacyService.updatePrivacySettings(
        showEmail: value,
      );
      if (mounted) {
        setState(() {
          _privacySettings = updated;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Email giờ đây hiển thị công khai' : 'Email đã được ẩn',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleShowPhone(bool value) async {
    setState(() => _isLoading = true);
    try {
      final updated = await _privacyService.updatePrivacySettings(
        showPhone: value,
      );
      if (mounted) {
        setState(() {
          _privacySettings = updated;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Số điện thoại sẽ hiển thị công khai'
                  : 'Số điện thoại đã được ẩn',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _viewBlockedUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BlockedUsersScreen(),
      ),
    );
  }

  void _deactivateAccount() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vô hiệu hóa tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn vô hiệu hóa tài khoản? Tài khoản của bạn sẽ bị ẩn và bạn có thể kích hoạt lại sau.',
            ),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Lý do (không bắt buộc)',
                hintText: 'Tại sao bạn muốn vô hiệu hóa tài khoản?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          AppButton(
            label: 'Vô hiệu hóa',
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
            customColor: AppColors.warning,
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              setState(() => _isLoading = true);

              try {
                await _accountService.deactivateAccount(
                  reason: reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
                );
                // User will be signed out, navigate to login
                if (mounted) {
                  navigator.popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
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
          AppButton(
            label: 'Xóa tài khoản',
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
            customColor: AppColors.error,
            customTextColor: Colors.white,
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteAccount();
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhập mật khẩu để xác nhận:'),
            SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Mật khẩu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 16),
            Text('Lý do xóa tài khoản (không bắt buộc):'),
            SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Tại sao bạn muốn xóa tài khoản?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          AppButton(
            label: 'Xác nhận xóa',
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
            customColor: AppColors.error,
            customTextColor: Colors.white,
            onPressed: () async {
              final password = passwordController.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              if (password.isEmpty) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Vui lòng nhập mật khẩu'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              navigator.pop();
              setState(() => _isLoading = true);

              try {
                await _accountService.deleteAccountPermanently(
                  password: password,
                  reason: reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
                );
                // User will be signed out, navigate to login
                if (mounted) {
                  navigator.popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
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
                  onPressed: () => setState(
                      () => _showCurrentPassword = !_showCurrentPassword),
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
        AppButton(
          label: 'Đổi mật khẩu',
          type: AppButtonType.primary,
          size: AppButtonSize.medium,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _changePassword,
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
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
      // STEP 1: Verify current password by re-authenticating
      final user = Supabase.instance.client.auth.currentUser;
      final email = user?.email;

      if (email == null) {
        throw Exception('Không thể xác thực. Vui lòng đăng nhập lại.');
      }

      // Re-authenticate with current password to verify it's correct
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // STEP 2: If re-auth successful, update to new password
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
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi: ${e.message}';

        // Handle specific auth errors
        if (e.message.contains('Invalid login credentials') ||
            e.message.contains('invalid_credentials')) {
          errorMessage = 'Mật khẩu hiện tại không đúng';
        } else if (e.message.contains('Email not confirmed')) {
          errorMessage = 'Email chưa được xác thực';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppColors.textOnPrimary),
                SizedBox(width: 8),
                Flexible(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: AppColors.error,
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

// Blocked Users Screen
class _BlockedUsersScreen extends StatefulWidget {
  @override
  State<_BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<_BlockedUsersScreen> {
  final UserBlocksService _blocksService = UserBlocksService.instance;
  bool _isLoading = true;
  List<BlockedUser> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _blocksService.getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _unblockUser(BlockedUser user) async {
    try {
      await _blocksService.unblockUser(user.blockedUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã bỏ chặn ${user.blockedUserName}'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadBlockedUsers(); // Reload list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách chặn'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có người dùng bị chặn',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _blockedUsers.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _blockedUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.blockedUserAvatar != null
                            ? NetworkImage(user.blockedUserAvatar!)
                            : null,
                        child: user.blockedUserAvatar == null
                            ? Text(user.blockedUserName[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user.blockedUserName),
                      subtitle: Text(
                        'Chặn lúc: ${_formatDate(user.blockedAt)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () => _showUnblockConfirmation(user),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: Text('Bỏ chặn'),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} năm trước';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} tháng trước';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _showUnblockConfirmation(BlockedUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bỏ chặn người dùng'),
        content: Text('Bạn có chắc muốn bỏ chặn ${user.blockedUserName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _unblockUser(user);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text('Bỏ chặn'),
          ),
        ],
      ),
    );
  }
}
