import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
import '../../../models/club_permission.dart';
import '../../../models/club_role.dart';
import '../../../services/club_permission_service.dart';

class GrantPermissionDialog extends StatefulWidget {
  final String clubId;
  final ClubMemberWithPermissions member;

  const GrantPermissionDialog({
    Key? key,
    required this.clubId,
    required this.member,
  }) : super(key: key);

  @override
  State<GrantPermissionDialog> createState() => _GrantPermissionDialogState();
}

class _GrantPermissionDialogState extends State<GrantPermissionDialog> {
  final ClubPermissionService _permissionService = ClubPermissionService();
  late ClubRole _selectedRole;
  late Map<String, bool> _customPermissions;
  bool _isLoading = false;
  bool _useCustomPermissions = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.member.role;
    _customPermissions = {
      'can_verify_rank': widget.member.canVerifyRank,
      'can_input_score': widget.member.canInputScore,
      'can_manage_tables': widget.member.canManageTables,
      'can_view_reports': widget.member.canViewReports,
      'can_manage_members': widget.member.canManageMembers,
      'can_manage_permissions': widget.member.canManagePermissions,
    };
  }

  Future<void> _updateRole() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('Không tìm thấy user hiện tại');
      }

      await _permissionService.updateMemberRole(
        clubId: widget.clubId,
        userId: widget.member.userId,
        newRole: _selectedRole,
        grantedBy: currentUserId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật vai trò thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCustomPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('Không tìm thấy user hiện tại');
      }

      await _permissionService.grantCustomPermissions(
        clubId: widget.clubId,
        userId: widget.member.userId,
        permissions: _customPermissions,
        grantedBy: currentUserId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật quyền thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn vai trò:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        RadioGroup<ClubRole>(
          value: _selectedRole,
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() {
                    _selectedRole = value!;
                    _useCustomPermissions = false;
                    // Update permissions based on role
                    _customPermissions = {
                      'can_verify_rank': value.canVerifyRank,
                      'can_input_score': value.canInputScore,
                      'can_manage_tables': value.canManageTables,
                      'can_view_reports': value.canViewReports,
                      'can_manage_members': value.canManageMembers,
                      'can_manage_permissions': value.canManagePermissions,
                    };
                  });
                },
          child: Column(
            children: ClubRole.values
                .where((role) => role != ClubRole.owner)
                .map((role) {
              return RadioListTile<ClubRole>(
                title: Row(
                  children: [
                    Text(role.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            role.description,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                value: role,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomPermissions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Tùy chỉnh quyền chi tiết'),
          subtitle: const Text('Bật để tùy chỉnh từng quyền cụ thể'),
          value: _useCustomPermissions,
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() {
                    _useCustomPermissions = value;
                  });
                },
        ),
        if (_useCustomPermissions) ...[
          const Divider(),
          _buildPermissionSwitch(
            'can_verify_rank',
            'Xác thực hạng',
            'Cho phép xác thực hạng của người chơi',
            Icons.verified_user,
          ),
          _buildPermissionSwitch(
            'can_input_score',
            'Nhập tỷ số',
            'Cho phép nhập kết quả trận đấu',
            Icons.scoreboard,
          ),
          _buildPermissionSwitch(
            'can_manage_tables',
            'Quản lý bàn',
            'Cho phép quản lý bàn bi-a trong CLB',
            Icons.table_restaurant,
          ),
          _buildPermissionSwitch(
            'can_view_reports',
            'Xem báo cáo',
            'Cho phép xem báo cáo hoạt động CLB',
            Icons.analytics,
          ),
          _buildPermissionSwitch(
            'can_manage_members',
            'Quản lý thành viên',
            'Cho phép thêm/xóa thành viên',
            Icons.people,
          ),
          _buildPermissionSwitch(
            'can_manage_permissions',
            'Quản lý quyền',
            'Cho phép cấp/thu hồi quyền của thành viên khác',
            Icons.admin_panel_settings,
          ),
        ],
      ],
    );
  }

  Widget _buildPermissionSwitch(
    String key,
    String title,
    String description,
    IconData icon,
  ) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.teal),
      title: Text(title),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      value: _customPermissions[key] ?? false,
      onChanged: _isLoading
          ? null
          : (value) {
              setState(() {
                _customPermissions[key] = value;
              });
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          UserAvatarWidget(
            avatarUrl: widget.member.userAvatar,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member.userName,
                  style: const TextStyle(fontSize: 18),
                ),
                if (widget.member.userRank != null)
                  Text(
                    'Hạng: ${widget.member.userRank}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoleSelector(),
            const SizedBox(height: 16),
            _buildCustomPermissions(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (_useCustomPermissions) {
                    _updateCustomPermissions();
                  } else {
                    _updateRole();
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
