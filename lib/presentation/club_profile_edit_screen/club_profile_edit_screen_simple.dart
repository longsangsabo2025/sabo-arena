import 'package:flutter/material.dart';
import 'package:sabo_arena/models/club.dart';
import 'package:sabo_arena/services/club_service.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:async';
// ELON_MODE_AUTO_FIX

enum ImageType { profile, cover, logo }

class ClubProfileEditScreenSimple extends StatefulWidget {
  final String clubId;

  const ClubProfileEditScreenSimple({super.key, required this.clubId});

  @override
  State<ClubProfileEditScreenSimple> createState() =>
      _ClubProfileEditScreenSimpleState();
}

class _ClubProfileEditScreenSimpleState
    extends State<ClubProfileEditScreenSimple> {
  final ClubService _clubService = ClubService.instance;
  Club? _club;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  Timer? _autoSaveTimer;
  DateTime? _lastSavedAt;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _totalTablesController = TextEditingController();
  final _pricePerHourController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClubData();
    _setupAutoSaveListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _totalTablesController.dispose();
    _pricePerHourController.dispose();
    super.dispose();
  }

  void _setupAutoSaveListeners() {
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _websiteController.addListener(_onFieldChanged);
    _totalTablesController.addListener(_onFieldChanged);
    _pricePerHourController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }

    // Cancel previous timer
    _autoSaveTimer?.cancel();

    // Start new timer - auto save after 2 seconds of inactivity
    _autoSaveTimer = Timer(Duration(seconds: 2), () {
      _autoSave();
    });
  }

  Future<void> _autoSave() async {
    if (_club == null || !_hasUnsavedChanges) return;

    // Validation
    if (_nameController.text.trim().isEmpty) {
      // Don't auto-save if name is empty
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Parse numeric values
      final totalTables = _totalTablesController.text.trim().isNotEmpty
          ? int.tryParse(_totalTablesController.text.trim())
          : null;
      final pricePerHour = _pricePerHourController.text.trim().isNotEmpty
          ? double.tryParse(_pricePerHourController.text.trim())
          : null;

      final updatedClub = await _clubService.updateClub(
        clubId: _club!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        websiteUrl: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        totalTables: totalTables,
        pricePerHour: pricePerHour,
      );

      setState(() {
        _club = updatedClub;
        _isSaving = false;
        _hasUnsavedChanges = false;
        _lastSavedAt = DateTime.now();
      });

      // Optional: Show subtle feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Đã lưu'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 60, left: 16, right: 16),
            backgroundColor: AppColors.success.withValues(alpha: 0.9),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      // Silent fail - don't interrupt user
    }
  }

  String _getTimeSinceLastSave() {
    if (_lastSavedAt == null) return '';

    final difference = DateTime.now().difference(_lastSavedAt!);

    if (difference.inSeconds < 60) {
      return 'vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else {
      return '${difference.inHours} giờ trước';
    }
  }

  Future<void> _loadClubData() async {
    try {
      final club = await _clubService.getClubById(widget.clubId);
      setState(() {
        _club = club;
        _nameController.text = club.name;
        _descriptionController.text = club.description ?? '';
        _addressController.text = club.address ?? '';
        _phoneController.text = club.phone ?? '';
        _emailController.text = club.email ?? '';
        _websiteController.text = club.websiteUrl ?? '';
        _totalTablesController.text = club.totalTables.toString();
        _pricePerHourController.text = club.pricePerHour != null
            ? club.pricePerHour!.toStringAsFixed(0)
            : '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Chỉnh sửa thông tin CLB",
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_isSaving)
              Text(
                'Đang lưu...',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else if (_lastSavedAt != null)
              Text(
                'Đã lưu ${_getTimeSinceLastSave()}',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.success,
                ),
              )
            else if (_hasUnsavedChanges)
              Text(
                'Có thay đổi chưa lưu',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
          ],
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: () => Navigator.pop(context, _club),
              icon: Icon(Icons.check, color: AppColors.primary),
              tooltip: 'Xong',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            )
          : ListView(
              children: [
                _buildBasicInfoSection(),
                _buildDivider(),
                _buildContactSection(),
                _buildDivider(),
                _buildTableInfoSection(),
                _buildDivider(),
                _buildImageSection(),
                SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Tiểu sử',
            onEditTap: () {
              // Show bottom sheet with all basic info fields
              _showEditBottomSheet(
                title: 'Chỉnh sửa tiểu sử',
                fields: [
                  {
                    'label': 'Tên CLB',
                    'controller': _nameController,
                    'placeholder': 'SABO Billiards | TP. Vũng Tàu',
                  },
                  {
                    'label': 'Mô tả',
                    'controller': _descriptionController,
                    'placeholder': 'Câu lạc bộ bi-a cao cấp',
                    'maxLines': 3,
                  },
                ],
              );
            },
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.store_outlined,
            content: _nameController.text.isEmpty
                ? 'Thêm tên CLB'
                : _nameController.text,
            onTap: () => _showEditDialog(
              title: 'Tên CLB',
              controller: _nameController,
              placeholder: 'SABO Billiards | TP. Vũng Tàu',
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.description_outlined,
            content: _descriptionController.text.isEmpty
                ? 'Thêm mô tả'
                : _descriptionController.text,
            onTap: () => _showEditDialog(
              title: 'Mô tả',
              controller: _descriptionController,
              placeholder: 'Câu lạc bộ bi-a cao cấp với không gian sang trọng',
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Chi tiết',
            onEditTap: () {
              // Show bottom sheet with all contact fields
              _showEditBottomSheet(
                title: 'Chỉnh sửa chi tiết',
                fields: [
                  {
                    'label': 'Địa chỉ',
                    'controller': _addressController,
                    'placeholder': '601A Nguyễn An Ninh, TP. Vũng Tàu',
                  },
                  {
                    'label': 'Số điện thoại',
                    'controller': _phoneController,
                    'placeholder': '+84 79 325 9316',
                    'keyboardType': TextInputType.phone,
                  },
                  {
                    'label': 'Email',
                    'controller': _emailController,
                    'placeholder': 'contact@sabobilliards.vn',
                    'keyboardType': TextInputType.emailAddress,
                  },
                  {
                    'label': 'Website',
                    'controller': _websiteController,
                    'placeholder': 'https://sabobilliards.vn',
                    'keyboardType': TextInputType.url,
                  },
                ],
              );
            },
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            content: _addressController.text.isEmpty
                ? 'Thêm địa chỉ'
                : _addressController.text,
            onTap: () => _showEditDialog(
              title: 'Địa chỉ',
              controller: _addressController,
              placeholder: '601A Nguyễn An Ninh, TP. Vũng Tàu',
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            content: _phoneController.text.isEmpty
                ? 'Thêm số điện thoại'
                : _phoneController.text,
            onTap: () => _showEditDialog(
              title: 'Số điện thoại',
              controller: _phoneController,
              placeholder: '+84 79 325 9316',
              keyboardType: TextInputType.phone,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.email_outlined,
            content: _emailController.text.isEmpty
                ? 'Thêm email'
                : _emailController.text,
            onTap: () => _showEditDialog(
              title: 'Email',
              controller: _emailController,
              placeholder: 'contact@sabobilliards.vn',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.language_outlined,
            content: _websiteController.text.isEmpty
                ? 'Thêm website'
                : _websiteController.text,
            onTap: () => _showEditDialog(
              title: 'Website',
              controller: _websiteController,
              placeholder: 'https://sabobilliards.vn',
              keyboardType: TextInputType.url,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.schedule_outlined,
            content: 'Luôn mở cửa',
            onTap: () {
              DSSnackbar.info(
                context: context,
                message: 'Chức năng giờ mở cửa sẽ được cập nhật',
              );
            },
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.category_outlined,
            content: 'Trang · Phòng chơi bida',
            onTap: () {
              DSSnackbar.info(
                context: context,
                message: 'Chức năng chỉnh sửa danh mục sẽ được cập nhật',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableInfoSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Thông tin bàn',
            onEditTap: () {
              // Show bottom sheet to edit table info
              _showEditBottomSheet(
                title: 'Chỉnh sửa thông tin bàn',
                fields: [
                  {
                    'label': 'Số lượng bàn',
                    'controller': _totalTablesController,
                    'placeholder': '8',
                    'keyboardType': TextInputType.number,
                  },
                  {
                    'label': 'Giá thuê (VNĐ/giờ)',
                    'controller': _pricePerHourController,
                    'placeholder': '50000',
                    'keyboardType': TextInputType.number,
                  },
                ],
              );
            },
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.table_bar_outlined,
            content: _totalTablesController.text.isEmpty
                ? 'Thêm số lượng bàn'
                : '${_totalTablesController.text} bàn',
            onTap: () => _showEditDialog(
              title: 'Số lượng bàn',
              controller: _totalTablesController,
              placeholder: '8',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.attach_money_outlined,
            content: _pricePerHourController.text.isEmpty
                ? 'Thêm giá thuê'
                : '${_pricePerHourController.text} VNĐ/giờ',
            onTap: () => _showEditDialog(
              title: 'Giá thuê (VNĐ/giờ)',
              controller: _pricePerHourController,
              placeholder: '50000',
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Hình ảnh',
            onEditTap: () {
              _showImageOptionsBottomSheet();
            },
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildImageThumbnail(
                label: 'Ảnh đại diện',
                imageUrl: _club?.profileImageUrl,
                onTap: () => _pickAndUploadImage(ImageType.profile),
              ),
              SizedBox(width: 12),
              _buildImageThumbnail(
                label: 'Ảnh bìa',
                imageUrl: _club?.coverImageUrl,
                onTap: () => _pickAndUploadImage(ImageType.cover),
              ),
              SizedBox(width: 12),
              _buildImageThumbnail(
                label: 'Logo',
                imageUrl: _club?.logoUrl,
                onTap: () => _pickAndUploadImage(ImageType.logo),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods - Facebook/Instagram Edit Page Style
  Widget _buildDivider() {
    return Container(height: 8, color: AppColors.background);
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onEditTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        if (onEditTap != null)
          TextButton(
            onPressed: onEditTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Chỉnh sửa',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String content,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail({
    required String label,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: hasImage
                  ? AppColors.border.withValues(alpha: 0.3)
                  : AppColors.border.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image,
                          size: 40,
                          color: AppColors.textTertiary,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.add_a_photo_outlined,
                    size: 32,
                    color: AppColors.textSecondary,
                  ),
          ),
          SizedBox(height: DesignTokens.space8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog({
    required String title,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: AppColors.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: DesignTokens.space12,
              vertical: DesignTokens.space12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: Text(
              'Xong',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditBottomSheet({
    required String title,
    required List<Map<String, dynamic>> fields,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLG),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTypography.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.space16),

              // Fields
              ...fields.map((field) {
                final controller = field['controller'] as TextEditingController;
                final label = field['label'] as String;
                final placeholder = field['placeholder'] as String;
                final maxLines = field['maxLines'] as int? ?? 1;
                final keyboardType = field['keyboardType'] as TextInputType?;

                return Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: DesignTokens.space8),
                      TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        maxLines: maxLines,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: placeholder,
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusSM,
                            ),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusSM,
                            ),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusSM,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: DesignTokens.space12,
                            vertical: DesignTokens.space12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: DesignTokens.space8),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                    DSSnackbar.success(
                      context: context,
                      message: 'Đã cập nhật thông tin',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusSM,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Lưu thay đổi',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Image upload methods
  Future<void> _pickAndUploadImage(ImageType type) async {
    if (_club == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isSaving = true;
      });

      // Show loading
      if (mounted) {
        DSSnackbar.info(context: context, message: 'Đang tải ảnh lên...');
      }

      // Read file bytes
      final Uint8List fileBytes = await image.readAsBytes();
      final String fileName = image.name;

      // Upload based on type
      Club updatedClub;
      switch (type) {
        case ImageType.profile:
          updatedClub = await _clubService.uploadAndUpdateProfileImage(
            _club!.id,
            fileBytes,
            fileName,
          );
          break;
        case ImageType.cover:
          updatedClub = await _clubService.uploadAndUpdateCoverImage(
            _club!.id,
            fileBytes,
            fileName,
          );
          break;
        case ImageType.logo:
          updatedClub = await _clubService.uploadAndUpdateClubLogo(
            _club!.id,
            fileBytes,
            fileName,
          );
          break;
      }

      setState(() {
        _club = updatedClub;
        _isSaving = false;
      });

      if (mounted) {
        DSSnackbar.success(
          context: context,
          message: 'Tải ảnh lên thành công!',
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        DSSnackbar.error(
          context: context,
          message: 'Lỗi tải ảnh: ${e.toString()}',
        );
      }
    }
  }

  void _showImageOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLG),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(DesignTokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quản lý hình ảnh CLB',
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: DesignTokens.space16),
            ListTile(
              leading: Icon(
                Icons.account_circle_outlined,
                color: AppColors.primary,
              ),
              title: Text('Thay đổi ảnh đại diện'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageType.profile);
              },
            ),
            ListTile(
              leading: Icon(Icons.panorama_outlined, color: AppColors.primary),
              title: Text('Thay đổi ảnh bìa'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageType.cover);
              },
            ),
            ListTile(
              leading: Icon(Icons.business_outlined, color: AppColors.primary),
              title: Text('Thay đổi logo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageType.logo);
              },
            ),
          ],
        ),
      ),
    );
  }
}

