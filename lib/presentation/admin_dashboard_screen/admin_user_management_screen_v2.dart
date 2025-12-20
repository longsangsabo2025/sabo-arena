import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../models/admin_user_view.dart';

class AdminUserManagementScreenV2 extends StatefulWidget {
  const AdminUserManagementScreenV2({super.key});

  @override
  State<AdminUserManagementScreenV2> createState() =>
      _AdminUserManagementScreenV2State();
}

class _AdminUserManagementScreenV2State
    extends State<AdminUserManagementScreenV2> {
  final AdminService _adminService = AdminService.instance;

  List<AdminUserView> _users = [];
  List<AdminUserView> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final users = await _adminService.getAdminUsersView(
        limit: 100,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _users = users;
          _filterUsers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    _filteredUsers = _users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'all' ||
          (_selectedFilter == 'active' && user.status == 'active') ||
          (_selectedFilter == 'inactive' && user.status == 'inactive') ||
          (_selectedFilter == 'blocked' && user.status == 'blocked') ||
          (_selectedFilter == 'admin' && user.role == 'admin') ||
          (_selectedFilter == 'verified' && user.isVerified) ||
          (_selectedFilter == 'unverified' && !user.isVerified);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _onSearchChanged(String query) {
    if (mounted) {
      setState(() {
        _searchQuery = query;
        _filterUsers();
      });
    }
  }

  void _onFilterChanged(String? filter) {
    if (filter != null && mounted) {
      setState(() {
        _selectedFilter = filter;
        _filterUsers();
      });
    }
  }

  Future<void> _blockUser(AdminUserView user) async {
    final confirmed = await _showConfirmDialog(
      'Chặn người dùng',
      'Bạn có chắc muốn chặn ${user.displayName}?',
    );

    if (confirmed == true) {
      try {
        await _adminService.blockUser(user.id, reason: 'Chặn bởi admin');
        await _loadUsers();
        _showSuccessSnackBar('Đã chặn ${user.displayName}');
      } catch (e) {
        _showErrorSnackBar('Lỗi chặn người dùng: $e');
      }
    }
  }

  Future<void> _unblockUser(AdminUserView user) async {
    try {
      await _adminService.unblockUser(user.id);
      await _loadUsers();
      _showSuccessSnackBar('Đã bỏ chặn ${user.displayName}');
    } catch (e) {
      _showErrorSnackBar('Lỗi bỏ chặn người dùng: $e');
    }
  }

  Future<void> _deleteUser(AdminUserView user) async {
    final confirmed = await _showConfirmDialog(
      'Xóa người dùng',
      'Bạn có chắc muốn xóa ${user.displayName}? Hành động này không thể hoàn tác.',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteUser(user.id);
        await _loadUsers();
        _showSuccessSnackBar('Đã xóa ${user.displayName}');
      } catch (e) {
        _showErrorSnackBar('Lỗi xóa người dùng: $e');
      }
    }
  }

  Future<void> _verifyUser(AdminUserView user) async {
    try {
      await _adminService.verifyUser(user.id);
      await _loadUsers();
      _showSuccessSnackBar('Đã xác thực ${user.displayName}');
    } catch (e) {
      _showErrorSnackBar('Lỗi xác thực người dùng: $e');
    }
  }

  Future<bool?> _showConfirmDialog(
    String title,
    String message, {
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDestructive ? Colors.red : AppTheme.primaryLight,
            ),
            child: Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilter(),
        _buildStats(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildUserList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(bottom: BorderSide(color: AppTheme.dividerLight)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên hoặc email...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all'),
                _buildFilterChip('Hoạt động', 'active'),
                _buildFilterChip('Bị chặn', 'blocked'),
                _buildFilterChip('Admin', 'admin'),
                _buildFilterChip('Đã xác thực', 'verified'),
                _buildFilterChip('Chưa xác thực', 'unverified'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => _onFilterChanged(value),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryLight.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color:
              isSelected ? AppTheme.primaryDark : AppTheme.textSecondaryLight,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStats() {
    final activeUsers = _users.where((u) => u.status == 'active').length;
    final blockedUsers = _users.where((u) => u.status == 'blocked').length;
    final adminUsers = _users.where((u) => u.role == 'admin').length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(bottom: BorderSide(color: AppTheme.dividerLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Tổng số', '${_users.length}', Icons.people),
          _buildStatItem(
            'Hoạt động',
            '$activeUsers',
            Icons.check_circle,
            color: Colors.green,
          ),
          _buildStatItem(
            'Bị chặn',
            '$blockedUsers',
            Icons.block,
            color: Colors.red,
          ),
          _buildStatItem(
            'Admin',
            '$adminUsers',
            Icons.admin_panel_settings,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.primaryLight, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy người dùng',
              style: TextStyle(color: AppTheme.textSecondaryLight),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          return _buildUserCard(_filteredUsers[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(AdminUserView user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                UserAvatarWidget(
                  avatarUrl: user.avatarUrl,
                  size: 60,
                ),
                SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (user.isAdmin)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          if (user.isVerified) ...[
                            SizedBox(width: 4),
                            Icon(Icons.verified, color: Colors.blue, size: 16),
                          ],
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusChip(user.status),
                          SizedBox(width: 8),
                          if (user.rank != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Hạng: ${user.rank}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Thắng', '${user.totalWins}'),
                _buildMiniStat('Thua', '${user.totalLosses}'),
                _buildMiniStat('Giải đấu', '${user.totalTournaments}'),
                if (user.eloRating != null)
                  _buildMiniStat('ELO', '${user.eloRating}'),
              ],
            ),
            SizedBox(height: 12),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!user.isVerified)
                  TextButton.icon(
                    onPressed: () => _verifyUser(user),
                    icon: Icon(Icons.verified, size: 16),
                    label: Text('Xác thực'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                if (user.isBlocked)
                  TextButton.icon(
                    onPressed: () => _unblockUser(user),
                    icon: Icon(Icons.check_circle, size: 16),
                    label: Text('Bỏ chặn'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  )
                else if (!user.isAdmin)
                  TextButton.icon(
                    onPressed: () => _blockUser(user),
                    icon: Icon(Icons.block, size: 16),
                    label: Text('Chặn'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                if (!user.isAdmin)
                  TextButton.icon(
                    onPressed: () => _deleteUser(user),
                    icon: Icon(Icons.delete, size: 16),
                    label: Text('Xóa'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Hoạt động';
        break;
      case 'inactive':
        color = Colors.grey;
        label = 'Không hoạt động';
        break;
      case 'blocked':
        color = Colors.red;
        label = 'Bị chặn';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }
}
