import 'package:flutter/material.dart';
import '../../../models/member_data.dart';
import '../../../core/design_system/design_system.dart';

class AddMemberDialog extends StatefulWidget {
  final String clubId;
  final Function(MemberData) onMemberAdded;

  const AddMemberDialog({
    super.key,
    required this.clubId,
    required this.onMemberAdded,
  });

  @override
  _AddMemberDialogState createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Invite tab controllers
  final TextEditingController _inviteEmailController = TextEditingController();
  final TextEditingController _inviteMessageController =
      TextEditingController();

  MembershipType _selectedMembershipType = MembershipType.regular;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _inviteEmailController.dispose();
    _inviteMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85, // 85% screen height, responsive
          minHeight: 500,
        ),
        child: Column(
          children: [
            // Header - iOS/Facebook style
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Thêm thành viên mới',
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 18),
                      color: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar - iOS/Facebook style
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: Icon(Icons.person_outline, size: 20),
                    text: 'Thêm 1 người',
                    height: 60,
                  ),
                  Tab(
                    icon: Icon(Icons.email_outlined, size: 20),
                    text: 'Mời tham gia',
                    height: 60,
                  ),
                ],
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                labelStyle: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: AppTypography.labelMedium.copyWith(
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildSingleMemberTab(), _buildInviteTab()],
              ),
            ),

            // Action buttons - iOS/Facebook style
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DSButton.tertiary(
                      text: 'Hủy',
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      size: DSButtonSize.large,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DSButton.primary(
                      text: _isLoading ? '' : _getActionButtonText(),
                      onPressed: _isLoading ? null : _handleAddMember,
                      size: DSButtonSize.large,
                      leadingIcon:
                          _isLoading ? null : Icons.person_add_outlined,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleMemberTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username field
          DSTextField(
            controller: _usernameController,
            label: 'Tên đăng nhập *',
            hintText: 'Nhập tên đăng nhập',
            prefixIcon: Icons.person_outline,
            variant: DSTextFieldVariant.outlined,
          ),

          SizedBox(height: 16),

          // Email field
          DSTextField(
            controller: _emailController,
            label: 'Email',
            hintText: 'Nhập email (tùy chọn)',
            prefixIcon: Icons.email_outlined,
            variant: DSTextFieldVariant.outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          SizedBox(height: 16),

          // Name field
          DSTextField(
            controller: _nameController,
            label: 'Họ và tên',
            hintText: 'Nhập họ và tên (tùy chọn)',
            prefixIcon: Icons.badge_outlined,
            variant: DSTextFieldVariant.outlined,
          ),

          SizedBox(height: 16),

          // Phone field
          DSTextField(
            controller: _phoneController,
            label: 'Số điện thoại',
            hintText: 'Nhập số điện thoại (tùy chọn)',
            prefixIcon: Icons.phone_outlined,
            variant: DSTextFieldVariant.outlined,
            keyboardType: TextInputType.phone,
          ),

          SizedBox(height: 20),

          // Membership type
          Text(
            'Loại thành viên',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MembershipType.values.map((type) {
              final isSelected = _selectedMembershipType == type;
              return DSChip(
                label: _getMembershipTypeLabel(type),
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedMembershipType = type;
                  });
                },
                variant:
                    isSelected ? DSChipVariant.filled : DSChipVariant.outlined,
                size: DSChipSize.medium,
                leadingIcon: _getMembershipIcon(type),
              );
            }).toList(),
          ),

          SizedBox(height: 20),

          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Thành viên sẽ nhận được thông báo mời tham gia câu lạc bộ qua email hoặc trong ứng dụng.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title section - iOS/Facebook style
          Text(
            'Mời thành viên tham gia',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Tạo liên kết mời hoặc gửi email mời trực tiếp đến thành viên mới.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          SizedBox(height: 24),

          // Invite link section - iOS/Facebook card style
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.link_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Liên kết mời',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 14),

                // Link display container
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'https://saboarena.com/invite/abc123',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          onTap: _copyInviteLink,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.copy_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DSButton.secondary(
                        text: 'Tạo mới',
                        onPressed: _generateNewLink,
                        size: DSButtonSize.medium,
                        leadingIcon: Icons.refresh_outlined,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DSButton.primary(
                        text: 'Chia sẻ',
                        onPressed: _shareInviteLink,
                        size: DSButtonSize.medium,
                        leadingIcon: Icons.share_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Email invite section - iOS/Facebook card style
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Mời qua email',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                DSTextField(
                  controller: _inviteEmailController,
                  label: 'Địa chỉ email',
                  hintText: 'Nhập email của thành viên',
                  variant: DSTextFieldVariant.outlined,
                  prefixIcon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                DSTextField(
                  controller: _inviteMessageController,
                  label: 'Tin nhắn tùy chỉnh (tùy chọn)',
                  hintText: 'Thêm tin nhắn cá nhân...',
                  variant: DSTextFieldVariant.outlined,
                  prefixIcon: Icons.message_outlined,
                  maxLines: 3,
                ),
                SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: DSButton.primary(
                    text: 'Gửi lời mời',
                    onPressed: _sendEmailInvite,
                    size: DSButtonSize.large,
                    leadingIcon: Icons.send_outlined,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getActionButtonText() {
    switch (_tabController.index) {
      case 0:
        return 'Thêm';
      case 1:
        return 'Gửi lời mời';
      default:
        return 'Thêm';
    }
  }

  String _getMembershipTypeLabel(MembershipType type) {
    switch (type) {
      case MembershipType.regular:
        return 'Thường';
      case MembershipType.vip:
        return 'VIP';
      case MembershipType.premium:
        return 'Premium';
    }
  }

  IconData _getMembershipIcon(MembershipType type) {
    switch (type) {
      case MembershipType.regular:
        return Icons.check_circle_outline;
      case MembershipType.vip:
        return Icons.star_outline;
      case MembershipType.premium:
        return Icons.workspace_premium_outlined;
    }
  }

  Future<void> _handleAddMember() async {
    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      if (!mounted) return;

      // Create mock member data based on current tab
      MemberData newMember = _createMockMember();

      widget.onMemberAdded(newMember);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm thành viên thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi thêm thành viên!'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  MemberData _createMockMember() {
    final now = DateTime.now();
    return MemberData(
      id: 'new_member_${now.millisecondsSinceEpoch}',
      user: UserInfo(
        id: 'user_${now.millisecondsSinceEpoch}',
        avatar:
            'https://images.unsplash.com/photo-1580000000000?w=100&h=100&fit=crop&crop=face',
        name: _nameController.text.isNotEmpty
            ? _nameController.text
            : _usernameController.text,
        username: _usernameController.text,
        rank: 'beginner',
        elo: 1000,
        isOnline: false,
      ),
      membershipInfo: MembershipInfo(
        membershipId: 'MB${1000 + now.millisecond}',
        joinDate: now,
        status: 'pending',
        type: _selectedMembershipType.toString().split('.').last,
        autoRenewal: false,
      ),
      activityStats: ActivityStats(
        activityScore: 0,
        winRate: 0.0,
        totalMatches: 0,
        lastActive: now,
        tournamentsJoined: 0,
      ),
    );
  }

  void _copyInviteLink() {
    // Implementation for copying invite link
  }

  void _generateNewLink() {
    // Implementation for generating new invite link
  }

  void _shareInviteLink() {
    // Implementation for sharing invite link
  }

  void _sendEmailInvite() {
    // Implementation for sending email invite
  }
}
