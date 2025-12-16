import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import '../../models/membership_type.dart';
import '../../services/membership_types_service.dart';

/// Màn hình quản lý các loại thành viên CLB
/// VIP, Thường, Học sinh, v.v.
class MembershipTypesScreen extends StatefulWidget {
  final String clubId;

  const MembershipTypesScreen({super.key, required this.clubId});

  @override
  State<MembershipTypesScreen> createState() => _MembershipTypesScreenState();
}

class _MembershipTypesScreenState extends State<MembershipTypesScreen> {
  final MembershipTypesService _service = MembershipTypesService();
  List<MembershipType> _membershipTypes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMembershipTypes();
  }

  Future<void> _loadMembershipTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final types = await _service.getClubMembershipTypes(widget.clubId);
      setState(() {
        _membershipTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Loại thành viên'),
      backgroundColor: AppTheme.backgroundLight,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Lỗi: $_errorMessage',
                style: TextStyle(color: Colors.red[700], fontSize: 16.sp),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadMembershipTypes,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_membershipTypes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_membership, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Chưa có loại thành viên nào',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _addNewType,
                icon: const Icon(Icons.add),
                label: const Text('Thêm loại thành viên đầu tiên'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembershipTypes,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          ..._membershipTypes.map((type) => _buildTypeCard(type)),
          const SizedBox(height: 20),
          _buildAddTypeButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withValues(alpha: 0.1),
            AppTheme.primaryLight.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_membership,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loại thành viên',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thiết lập các loại thành viên và quyền lợi',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(MembershipType type) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: type.color.withValues(alpha: 0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              type.color.withValues(alpha: 0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(type.iconData, color: type.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        Text(
                          type.description,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: type.isActive,
                    onChanged: (value) => _toggleActive(type),
                    activeThumbColor: type.color,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Price
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: type.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments, color: type.color, size: 20),
                    const SizedBox(width: 8),
                    if (type.monthlyFee > 0)
                      Text(
                        '${_formatCurrency(type.monthlyFee)}/tháng',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: type.color,
                        ),
                      )
                    else if (type.dailyFee != null)
                      Text(
                        '${_formatCurrency(type.dailyFee!)}/ngày',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: type.color,
                        ),
                      )
                    else
                      Text(
                        'Miễn phí',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: type.color,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Benefits
              Text(
                'Quyền lợi:',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              ...type.benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: type.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editType(type),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Chỉnh sửa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: type.color,
                        side: BorderSide(color: type.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmDelete(type),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Xóa',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewMembers(type),
                      icon: const Icon(Icons.people, size: 18),
                      label: const Text('Xem thành viên'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type.color,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTypeButton() {
    return OutlinedButton.icon(
      onPressed: _addNewType,
      icon: const Icon(Icons.add),
      label: const Text('Thêm loại thành viên mới'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: AppTheme.primaryLight),
        foregroundColor: AppTheme.primaryLight,
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}đ';
  }

  Future<void> _toggleActive(MembershipType type) async {
    try {
      await _service.toggleActive(type.id, !type.isActive);
      await _loadMembershipTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type.isActive ? 'Đã tắt ${type.name}' : 'Đã bật ${type.name}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editType(MembershipType type) {
    _showMembershipTypeDialog(type: type);
  }

  void _viewMembers(MembershipType type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Xem thành viên ${type.name}')),
    );
    // TODO: Navigate to members list filtered by type
  }

  void _addNewType() {
    _showMembershipTypeDialog();
  }

  /// Dialog để thêm/sửa membership type
  Future<void> _showMembershipTypeDialog({MembershipType? type}) async {
    final isEdit = type != null;
    final nameController = TextEditingController(text: type?.name ?? '');
    final descController = TextEditingController(text: type?.description ?? '');
    final monthlyFeeController =
        TextEditingController(text: type?.monthlyFee.toStringAsFixed(0) ?? '');
    final dailyFeeController =
        TextEditingController(text: type?.dailyFee?.toStringAsFixed(0) ?? '');
    final benefitsController =
        TextEditingController(text: type?.benefits.join('\n') ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Chỉnh sửa loại thành viên' : 'Thêm loại thành viên'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên loại thành viên *',
                  hintText: 'VD: VIP, Thường, Học sinh',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Mô tả ngắn gọn về loại thành viên',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: monthlyFeeController,
                decoration: const InputDecoration(
                  labelText: 'Phí tháng (đ) *',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dailyFeeController,
                decoration: const InputDecoration(
                  labelText: 'Phí ngày (đ)',
                  hintText: 'Để trống nếu không có',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: benefitsController,
                decoration: const InputDecoration(
                  labelText: 'Quyền lợi',
                  hintText: 'Mỗi quyền lợi một dòng',
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validation
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên loại thành viên')),
                );
                return;
              }

              if (monthlyFeeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập phí tháng')),
                );
                return;
              }

              Navigator.pop(context, true);
            },
            child: Text(isEdit ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Parse data
      final name = nameController.text.trim();
      final description = descController.text.trim();
      final monthlyFee = double.tryParse(monthlyFeeController.text) ?? 0;
      final dailyFee = dailyFeeController.text.trim().isEmpty
          ? null
          : double.tryParse(dailyFeeController.text);
      final benefits = benefitsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      try {
        if (isEdit) {
          // Update - use toInsertJson from copyWith result
          final updated = type.copyWith(
            name: name,
            description: description,
            monthlyFee: monthlyFee,
            dailyFee: dailyFee,
            benefits: benefits,
          );
          await _service.updateMembershipType(type.id, updated.toInsertJson());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật loại thành viên'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Create new
          final newType = MembershipType(
            id: '', // Generated by database
            clubId: widget.clubId,
            name: name,
            description: description,
            color: const Color(0xFFE91E63), // Pink default
            icon: 'card_membership',
            monthlyFee: monthlyFee,
            dailyFee: dailyFee,
            benefits: benefits,
            priority: 0,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _service.createMembershipType(newType);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã thêm loại thành viên mới'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

        // Reload
        await _loadMembershipTypes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    nameController.dispose();
    descController.dispose();
    monthlyFeeController.dispose();
    dailyFeeController.dispose();
    benefitsController.dispose();
  }

  /// Xác nhận xóa membership type
  Future<void> _confirmDelete(MembershipType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa loại thành viên "${type.name}"?\n\n'
          'Lưu ý: Không thể xóa nếu có thành viên đang sử dụng loại này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteMembershipType(type.id);
        await _loadMembershipTypes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa ${type.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
