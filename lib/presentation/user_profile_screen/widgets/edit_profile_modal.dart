import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart'; // TODO: Re-enable after App Store approval
import 'dart:io';
import 'package:sabo_arena/widgets/common/common_widgets.dart'; // Phase 4

import '../../../models/user_profile.dart';
import '../../../services/user_service.dart';
import '../../../widgets/user/user_avatar_widget.dart';

class EditProfileModal extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onSave;
  final VoidCallback onCancel;

  const EditProfileModal({
    super.key,
    required this.userProfile,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  String? _selectedAvatarPath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController.text = widget.userProfile.fullName;
    _displayNameController.text = widget.userProfile.displayName;
    _phoneController.text = widget.userProfile.phone ?? '';
    _bioController.text = widget.userProfile.bio ?? '';
    _locationController.text = widget.userProfile.location ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.lightImpact();

    try {
      String? avatarUrl = widget.userProfile.avatarUrl;

      // Xử lý upload ảnh nếu có ảnh mới được chọn
      if (_selectedAvatarPath != null &&
          _selectedAvatarPath != 'REMOVE_AVATAR') {
        final file = File(_selectedAvatarPath!);
        final bytes = await file.readAsBytes();
        final fileName = file.path.split('/').last;

        // Upload ảnh lên Supabase storage
        final uploadedUrl = await _uploadAvatar(bytes, fileName);
        if (uploadedUrl != null) {
          avatarUrl = uploadedUrl;
        }
      } else if (_selectedAvatarPath == 'REMOVE_AVATAR') {
        avatarUrl = null;
      }

      // Sử dụng copyWith để cập nhật thông tin
      final updatedProfile = widget.userProfile.copyWith(
        fullName: _fullNameController.text.trim().isEmpty
            ? widget.userProfile.fullName
            : _fullNameController.text.trim(),
        displayName: _displayNameController.text.trim().isEmpty
            ? widget.userProfile.displayName
            : _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        avatarUrl: avatarUrl,
      );

      await widget.onSave(updatedProfile);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context: context,
          message: 'Lỗi: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _uploadAvatar(List<int> bytes, String fileName) async {
    try {
      // Import UserService để sử dụng upload method
      final userService = UserService.instance;
      return await userService.uploadAvatar(bytes, fileName);
    } catch (e) {
      _showErrorMessage('Lỗi upload ảnh: $e');
      return null;
    }
  }

  void _changeAvatar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Thay đổi ảnh đại diện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Chụp ảnh',
                  onTap: () => _pickImageFromCamera(),
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Chọn ảnh',
                  onTap: () => _pickImageFromGallery(),
                ),
                if (widget.userProfile.avatarUrl != null)
                  _buildImageSourceOption(
                    icon: Icons.delete,
                    label: 'Xóa ảnh',
                    onTap: () => _removeAvatar(),
                    color: Colors.red,
                  ),
              ],
            ),
            SizedBox(height: 30),
            AppButton(
              label: 'Hủy',
              type: AppButtonType.text,
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? Colors.green).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? Colors.green, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    Navigator.pop(context); // Đóng bottom sheet

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedAvatarPath = image.path;
        });
        _showSuccessMessage('✅ Đã chọn ảnh từ camera');
      }
    } catch (e) {
      // If permission denied, show message only (Apple 5.1.1 - do not auto-redirect)
      if (e.toString().contains('photo access') ||
          e.toString().contains('camera') ||
          e.toString().contains('denied')) {
        _showErrorMessage(
          'Cần cấp quyền camera để chụp ảnh. Bạn có thể bật trong Cài đặt > Sabo Arena > Camera',
        );
      } else {
        _showErrorMessage('Lỗi khi chụp ảnh: $e');
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    Navigator.pop(context); // Đóng bottom sheet

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedAvatarPath = image.path;
        });
        _showSuccessMessage('✅ Đã chọn ảnh từ thư viện');
      }
    } catch (e) {
      // If permission denied, show message only (Apple 5.1.1 - do not auto-redirect)
      if (e.toString().contains('photo') ||
          e.toString().contains('library') ||
          e.toString().contains('denied')) {
        _showErrorMessage(
          'Cần cấp quyền thư viện ảnh để chọn ảnh. Bạn có thể bật trong Cài đặt > Sabo Arena > Ảnh',
        );
      } else {
        _showErrorMessage('Lỗi khi chọn ảnh: $e');
      }
    }
  }

  void _removeAvatar() {
    Navigator.pop(context); // Đóng bottom sheet

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa ảnh đại diện'),
        content: Text('Bạn có chắc chắn muốn xóa ảnh đại diện không?'),
        actions: [
          AppButton(
            label: 'Hủy',
            type: AppButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            label: 'Xóa',
            type: AppButtonType.text,
            customColor: Colors.red,
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedAvatarPath = 'REMOVE_AVATAR';
              });
              _showSuccessMessage('✅ Đã xóa ảnh đại diện');
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    AppSnackbar.success(
      context: context,
      message: message,
    );
  }

  void _showErrorMessage(String message) {
    AppSnackbar.error(
      context: context,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppButton(
                  label: 'Hủy',
                  type: AppButtonType.text,
                  onPressed: _isLoading ? null : widget.onCancel,
                ),
                Text(
                  'Chỉnh sửa hồ sơ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                AppButton(
                  label: 'Lưu',
                  type: AppButtonType.text,
                  customColor: Colors.green,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleSave,
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar section
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _selectedAvatarPath != null &&
                                    _selectedAvatarPath != 'REMOVE_AVATAR'
                                ? Image.file(File(_selectedAvatarPath!),
                                    fit: BoxFit.cover)
                                : widget.userProfile.avatarUrl != null &&
                                        _selectedAvatarPath != 'REMOVE_AVATAR'
                                    ? UserAvatarWidget(
                                        avatarUrl: widget.userProfile.avatarUrl,
                                        size: 100,
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: _changeAvatar,
                                constraints: BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Họ và tên thật
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Họ và tên thật',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Họ và tên không được để trống';
                        }
                        if (value.trim().length < 2) {
                          return 'Tên phải có ít nhất 2 ký tự';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 3.h),

                    // Tên hiển thị
                    _buildTextField(
                      controller: _displayNameController,
                      label: 'Tên hiển thị',
                      icon: Icons.badge_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Tên hiển thị không được để trống';
                        }
                        if (value.trim().length < 2) {
                          return 'Tên hiển thị phải có ít nhất 2 ký tự';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 3.h),

                    _buildInfoDisplay(
                      'Email',
                      widget.userProfile.email,
                      Icons.email_outlined,
                    ),
                    SizedBox(height: 3.h),

                    // Số điện thoại
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (!RegExp(
                            r'^[0-9+\-\s\(\)\.]+$',
                          ).hasMatch(value.trim())) {
                            return 'Số điện thoại không hợp lệ';
                          }
                          if (value.trim().length < 10) {
                            return 'Số điện thoại phải có ít nhất 10 số';
                          }
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Địa điểm
                    _buildTextField(
                      controller: _locationController,
                      label: 'Địa điểm',
                      icon: Icons.location_on_outlined,
                    ),

                    SizedBox(height: 3.h),

                    // Giới thiệu bản thân
                    _buildTextField(
                      controller: _bioController,
                      label: 'Giới thiệu bản thân',
                      icon: Icons.edit_outlined,
                      maxLines: 4,
                      maxLength: 200,
                      validator: (value) {
                        if (value != null && value.length > 200) {
                          return 'Giới thiệu không được quá 200 ký tự';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDisplay(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade600),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ),
              Icon(Icons.lock_outlined, color: Colors.grey.shade400, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
