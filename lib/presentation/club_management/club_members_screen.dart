import 'package:flutter/material.dart';
import 'package:sabo_arena/core/device/device_info.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
import '../../models/club_permission.dart';
import '../../models/club_role.dart';
import '../../services/club_permission_service.dart';
import 'widgets/grant_permission_dialog.dart';

class ClubMembersScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const ClubMembersScreen({
    Key? key,
    required this.clubId,
    required this.clubName,
  }) : super(key: key);

  @override
  State<ClubMembersScreen> createState() => _ClubMembersScreenState();
}

class _ClubMembersScreenState extends State<ClubMembersScreen> {
  final ClubPermissionService _permissionService = ClubPermissionService();
  List<ClubMemberWithPermissions> _members = [];
  List<ClubMemberWithPermissions> _filteredMembers = [];
  bool _isLoading = true;
  ClubRole? _selectedRoleFilter;
  final TextEditingController _searchController = TextEditingController();
  bool _canManagePermissions = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _checkPermissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final canManage = await _permissionService.canPerformAction(
      clubId: widget.clubId,
      permissionKey: 'manage_permissions',
    );
    setState(() {
      _canManagePermissions = canManage;
    });
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final members = await _permissionService.getClubMembers(widget.clubId);
      setState(() {
        _members = members;
        _filteredMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải danh sách thành viên: $e')),
        );
      }
    }
  }

  void _filterMembers() {
    setState(() {
      _filteredMembers = _members.where((member) {
        // Role filter
        if (_selectedRoleFilter != null && member.role != _selectedRoleFilter) {
          return false;
        }

        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          return member.userName.toLowerCase().contains(searchQuery) ||
              member.userRank?.toLowerCase().contains(searchQuery) == true;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _showGrantPermissionDialog(ClubMemberWithPermissions member) async {
    if (!_canManagePermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền cấp quyền')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => GrantPermissionDialog(
        clubId: widget.clubId,
        member: member,
      ),
    );

    if (result == true) {
      _loadMembers(); // Refresh list
    }
  }

  Widget _buildRoleChip(ClubRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(int.parse(role.badgeColor.replaceFirst('#', '0xFF'))),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(role.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            role.displayName, style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionChip(String label, bool hasPermission) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: hasPermission ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label, style: TextStyle(
          color: hasPermission ? Colors.green.shade800 : Colors.grey.shade600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildMemberCard(ClubMemberWithPermissions member) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: UserAvatarWidget(
          avatarUrl: member.userAvatar,
          size: 40,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.userName, style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildRoleChip(member.role),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (member.userRank != null)
              Text(
                'Hạng: ${member.userRank}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 4),
            Text(
              'Tham gia: ${_formatDate(member.joinedAt)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Permissions
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _buildPermissionChip('Xác thực hạng', member.canVerifyRank),
                _buildPermissionChip('Nhập tỷ số', member.canInputScore),
                _buildPermissionChip('Quản lý bàn', member.canManageTables),
                _buildPermissionChip('Xem báo cáo', member.canViewReports),
              ],
            ),
          ],
        ),
        trailing: _canManagePermissions && member.role != ClubRole.owner
            ? IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showGrantPermissionDialog(member),
              )
            : null,
        onTap: () => _showGrantPermissionDialog(member),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thành viên ${widget.clubName}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm thành viên...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => _filterMembers(),
                ),
              ),
              // Role filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: _selectedRoleFilter == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedRoleFilter = null;
                          _filterMembers();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ...ClubRole.values.map((role) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${role.icon} ${role.displayName}'),
                          selected: _selectedRoleFilter == role,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRoleFilter = selected ? role : null;
                              _filterMembers();
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildResponsiveBody(),
    );
  }

  // 🎯 iPad: Responsive body with max-width constraint
  Widget _buildResponsiveBody() {
    final isIPad = DeviceInfo.isIPad(context);
    final maxWidth = isIPad ? 900.0 : double.infinity;
    
    final bodyWidget = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _filteredMembers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isNotEmpty || _selectedRoleFilter != null
                          ? 'Không tìm thấy thành viên'
                          : 'Chưa có thành viên', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadMembers,
                child: ListView.builder(
                  itemCount: _filteredMembers.length,
                  itemBuilder: (context, index) {
                    return _buildMemberCard(_filteredMembers[index]);
                  },
                ),
              );
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: bodyWidget,
      ),
    );
  }
}
