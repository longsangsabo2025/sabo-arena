import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/models/pricing_models.dart';
import 'package:sabo_arena/services/pricing_service.dart';

class PricingSettingsScreen extends StatefulWidget {
  final String clubId;

  const PricingSettingsScreen({super.key, required this.clubId});

  @override
  State<PricingSettingsScreen> createState() => _PricingSettingsScreenState();
}

class _PricingSettingsScreenState extends State<PricingSettingsScreen> {
  final _pricingService = PricingService();
  
  List<TableRate> tableRates = [];
  List<MembershipFee> membershipFees = [];
  List<AdditionalService> additionalServices = [];
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    setState(() => _isLoading = true);
    try {
      final pricing = await _pricingService.getClubPricing(widget.clubId);
      setState(() {
        tableRates = pricing.tableRates;
        membershipFees = pricing.membershipFees;
        additionalServices = pricing.additionalServices;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Bảng giá dịch vụ'),
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildTableRates(),
                  const SizedBox(height: 32),
                  _buildMembershipFees(),
                  const SizedBox(height: 32),
                  _buildAdditionalServices(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
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
              Icons.monetization_on,
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
                  'Quản lý bảng giá', overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thiết lập giá cho các dịch vụ và sân chơi', overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildTableRates() {
    return _buildPricingSection(
      title: 'Giá thuê bàn',
      subtitle: 'Thiết lập giá thuê theo giờ cho các loại bàn',
      icon: Icons.table_restaurant,
      items: tableRates,
      onAdd: () => _showTableRateDialog(),
      onEdit: (item, index) => _showTableRateDialog(item: item, index: index),
      onDelete: (index) => _deleteTableRate(index),
      itemBuilder: (item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name, overflow: TextOverflow.ellipsis, style: TextStyle(
              color: AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatCurrency(item.hourlyRate.toInt())}/giờ',
            style: TextStyle(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.description, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipFees() {
    return _buildPricingSection(
      title: 'Phí thành viên',
      subtitle: 'Thiết lập phí cho các loại thành viên',
      icon: Icons.card_membership,
      items: membershipFees,
      onAdd: () => _showMembershipFeeDialog(),
      onEdit: (item, index) =>
          _showMembershipFeeDialog(item: item, index: index),
      onDelete: (index) => _deleteMembershipFee(index),
      itemBuilder: (item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name, overflow: TextOverflow.ellipsis, style: TextStyle(
              color: AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_formatCurrency(item.monthlyFee.toInt())}/tháng',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatCurrency(item.yearlyFee.toInt())}/năm',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.benefits, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalServices() {
    return _buildPricingSection(
      title: 'Dịch vụ bổ sung',
      subtitle: 'Thiết lập giá cho các dịch vụ khác',
      icon: Icons.room_service,
      items: additionalServices,
      onAdd: () => _showAdditionalServiceDialog(),
      onEdit: (item, index) =>
          _showAdditionalServiceDialog(item: item, index: index),
      onDelete: (index) => _deleteAdditionalService(index),
      itemBuilder: (item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name, overflow: TextOverflow.ellipsis, style: TextStyle(
              color: AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatCurrency(item.price.toInt())}/${item.unit}',
            style: TextStyle(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.description, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection<T>({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<T> items,
    required VoidCallback onAdd,
    required Function(T, int) onEdit,
    required Function(int) onDelete,
    required Widget Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle, style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: onAdd,
              icon: Icon(Icons.add, color: AppTheme.primaryLight),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          _buildEmptyState(title)
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                int index = entry.key;
                T item = entry.value;
                bool isActive = item is TableRate
                    ? item.isActive
                    : item is MembershipFee
                        ? item.isActive
                        : (item as AdditionalService).isActive;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: index < items.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color:
                                  AppTheme.dividerLight.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryLight.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: isActive ? AppTheme.primaryLight : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: itemBuilder(item)),
                      Switch(
                        value: isActive,
                        onChanged: (value) => _toggleItemStatus(item, value),
                        activeThumbColor: AppTheme.primaryLight,
                      ),
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: AppTheme.textSecondaryLight,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: AppTheme.primaryLight),
                                const SizedBox(width: 12),
                                const Text('Chỉnh sửa'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.red),
                                const SizedBox(width: 12),
                                Text('Xóa', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit(item, index);
                          } else if (value == 'delete') {
                            onDelete(index);
                          }
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String title) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerLight.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: AppTheme.textSecondaryLight,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có $title',
              style: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nhấn nút + để thêm mới',
              style: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withValues(alpha: 0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSaving ? null : _savePricingSettings,
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Lưu bảng giá', overflow: TextOverflow.ellipsis, style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
  }

  Future<void> _toggleItemStatus(dynamic item, bool isActive) async {
    try {
      if (item is TableRate) {
        await _pricingService.toggleTableRateStatus(item.id, isActive);
        setState(() {
          final index = tableRates.indexOf(item);
          tableRates[index] = item.copyWith(isActive: isActive);
        });
      } else if (item is MembershipFee) {
        await _pricingService.toggleMembershipFeeStatus(item.id, isActive);
        setState(() {
          final index = membershipFees.indexOf(item);
          membershipFees[index] = item.copyWith(isActive: isActive);
        });
      } else if (item is AdditionalService) {
        await _pricingService.toggleServiceStatus(item.id, isActive);
        setState(() {
          final index = additionalServices.indexOf(item);
          additionalServices[index] = item.copyWith(isActive: isActive);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTableRateDialog({TableRate? item, int? index}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final rateController = TextEditingController(
      text: item?.hourlyRate.toInt().toString() ?? '',
    );
    final descController = TextEditingController(
      text: item?.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Thêm bàn mới' : 'Chỉnh sửa bàn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên bàn',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateController,
                decoration: const InputDecoration(
                  labelText: 'Giá theo giờ (VNĐ)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  rateController.text.isNotEmpty) {
                try {
                  if (item == null) {
                    final newRate = TableRate(
                      id: '',
                      clubId: widget.clubId,
                      name: nameController.text,
                      description: descController.text,
                      hourlyRate: double.parse(rateController.text),
                      isActive: true,
                    );
                    final saved =
                        await _pricingService.addTableRate(newRate);
                    setState(() => tableRates.add(saved));
                  } else {
                    final updated = item.copyWith(
                      name: nameController.text,
                      description: descController.text,
                      hourlyRate: double.parse(rateController.text),
                    );
                    final saved =
                        await _pricingService.updateTableRate(updated);
                    setState(() => tableRates[index!] = saved);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(item == null ? 'Thêm' : 'Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showMembershipFeeDialog({MembershipFee? item, int? index}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final monthlyController = TextEditingController(
      text: item?.monthlyFee.toInt().toString() ?? '',
    );
    final yearlyController = TextEditingController(
      text: item?.yearlyFee.toInt().toString() ?? '',
    );
    final benefitsController = TextEditingController(
      text: item?.benefits ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          item == null ? 'Thêm gói thành viên' : 'Chỉnh sửa gói thành viên',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên gói',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: monthlyController,
                decoration: const InputDecoration(
                  labelText: 'Phí tháng (VNĐ)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: yearlyController,
                decoration: const InputDecoration(
                  labelText: 'Phí năm (VNĐ)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: benefitsController,
                decoration: const InputDecoration(
                  labelText: 'Quyền lợi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  monthlyController.text.isNotEmpty) {
                try {
                  if (item == null) {
                    final newFee = MembershipFee(
                      id: '',
                      clubId: widget.clubId,
                      name: nameController.text,
                      benefits: benefitsController.text,
                      monthlyFee: double.parse(monthlyController.text),
                      yearlyFee: double.parse(
                        yearlyController.text.isEmpty
                            ? '0'
                            : yearlyController.text,
                      ),
                      isActive: true,
                    );
                    final saved =
                        await _pricingService.addMembershipFee(newFee);
                    setState(() => membershipFees.add(saved));
                  } else {
                    final updated = item.copyWith(
                      name: nameController.text,
                      benefits: benefitsController.text,
                      monthlyFee: double.parse(monthlyController.text),
                      yearlyFee: double.parse(
                        yearlyController.text.isEmpty
                            ? '0'
                            : yearlyController.text,
                      ),
                    );
                    final saved =
                        await _pricingService.updateMembershipFee(updated);
                    setState(() => membershipFees[index!] = saved);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(item == null ? 'Thêm' : 'Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showAdditionalServiceDialog({AdditionalService? item, int? index}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(
      text: item?.price.toInt().toString() ?? '',
    );
    final unitController = TextEditingController(text: item?.unit ?? 'lần');
    final descController = TextEditingController(
      text: item?.description ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item == null ? 'Thêm dịch vụ' : 'Chỉnh sửa dịch vụ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên dịch vụ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá (VNĐ)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Đơn vị (lần, ly, ...)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                try {
                  if (item == null) {
                    final newService = AdditionalService(
                      id: '',
                      clubId: widget.clubId,
                      name: nameController.text,
                      description: descController.text,
                      price: double.parse(priceController.text),
                      unit: unitController.text.isEmpty
                          ? 'lần'
                          : unitController.text,
                      isActive: true,
                    );
                    final saved =
                        await _pricingService.addAdditionalService(newService);
                    setState(() => additionalServices.add(saved));
                  } else {
                    final updated = item.copyWith(
                      name: nameController.text,
                      description: descController.text,
                      price: double.parse(priceController.text),
                      unit: unitController.text.isEmpty
                          ? 'lần'
                          : unitController.text,
                    );
                    final saved = await _pricingService
                        .updateAdditionalService(updated);
                    setState(() => additionalServices[index!] = saved);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(item == null ? 'Thêm' : 'Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _deleteTableRate(int index) {
    _showDeleteDialog('bàn này', () async {
      try {
        await _pricingService.deleteTableRate(tableRates[index].id);
        setState(() => tableRates.removeAt(index));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã xóa thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _deleteMembershipFee(int index) {
    _showDeleteDialog('gói thành viên này', () async {
      try {
        await _pricingService.deleteMembershipFee(membershipFees[index].id);
        setState(() => membershipFees.removeAt(index));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã xóa thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _deleteAdditionalService(int index) {
    _showDeleteDialog('dịch vụ này', () async {
      try {
        await _pricingService
            .deleteAdditionalService(additionalServices[index].id);
        setState(() => additionalServices.removeAt(index));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã xóa thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _showDeleteDialog(String itemName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa $itemName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _savePricingSettings() async {
    setState(() => _isSaving = true);
    try {
      // Data đã được lưu tự động khi thêm/sửa/xóa
      // Chỉ cần thông báo thành công
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu bảng giá dịch vụ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
