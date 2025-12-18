import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sabo_arena/widgets/common/common_widgets.dart'; // Phase 4

import '../../../models/user_profile.dart';
import '../../../services/permission_service.dart';
import '../../../widgets/user/user_avatar_widget.dart';

class EditProfileModal extends StatefulWidget {
  final UserProfile userProfile;
  // 🚀 MUSK: Updated signature for atomic operations
  final Future<void> Function(UserProfile profile, List<int>? avatarBytes, String? avatarName, bool removeAvatar) onSave;
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
  late TextEditingController _fullNameController;
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;

  bool _isLoading = false;
  String? _selectedAvatarPath;
  Uint8List? _selectedAvatarBytes; // Store bytes for Web support
  String? _selectedFileName; // Store filename for extension
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController(text: widget.userProfile.fullName);
    _displayNameController = TextEditingController(text: widget.userProfile.displayName);
    _phoneController = TextEditingController(text: widget.userProfile.phone ?? '');
    _bioController = TextEditingController(text: widget.userProfile.bio ?? '');
    _locationController = TextEditingController(text: widget.userProfile.location ?? '');
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
      // Prepare profile update
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
        // Avatar URL is handled by the service, we don't set it here
      );

      final removeAvatar = _selectedAvatarPath == 'REMOVE_AVATAR';
      String? fileName;
      if (_selectedAvatarBytes != null && !removeAvatar) {
         // FIX: Use correct extension
         final ext = _selectedFileName != null ? path.extension(_selectedFileName!) : 
                     (_selectedAvatarPath != null ? path.extension(_selectedAvatarPath!) : '.jpg');
         fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}$ext';
      }

      // 🚀 MUSK: Delegate to parent/service for atomic operation
      await widget.onSave(
        updatedProfile, 
        removeAvatar ? null : _selectedAvatarBytes, 
        fileName,
        removeAvatar
      );
      
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

  void _changeAvatar() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
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
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Chọn ảnh đại diện',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            // 📱 MARK Z: Facebook-style image picker with better UX
            Column(
              children: [
                // Primary action: Choose from Gallery (most common)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    icon: Icon(Icons.photo_library),
                    label: Text('Chọn từ thư viện ảnh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Secondary action: Take Photo
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                    icon: Icon(Icons.camera_alt),
                    label: Text('Chụp ảnh mới'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                if (widget.userProfile.avatarUrl != null) ...[
                  SizedBox(height: 12),
                  // Destructive action: Remove
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _removeAvatar();
                      },
                      icon: Icon(Icons.delete_outline),
                      label: Text('Xóa ảnh hiện tại'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
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

  // 📱 MARK Z: Removed old _buildImageSourceOption - using Facebook-style buttons now

  Future<void> _pickImageFromCamera() async {
    // Navigator.pop(context); // 🚀 MUSK_FIX: Removed double pop (handled by caller)
    
    // 📱 MARK Z: Debug logging for user action tracking
    print('🎥 USER ACTION: _pickImageFromCamera() called - should open CAMERA');

    try {
      final cameraGranted = await PermissionService.checkCameraPermission();
      if (!cameraGranted) {
        _showErrorMessage(
          'Cần cấp quyền camera để chụp ảnh. Bạn có thể bật trong Cài đặt > Sabo Arena > Camera',
        );
        return;
      }

      // 📱 MARK Z: Explicit source confirmation
      print('🎥 CALLING ImagePicker with source: ImageSource.camera');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (!mounted) return; // 🚀 MUSK_FIX: Check mounted after async
        setState(() {
          _selectedAvatarPath = image.path;
          _selectedAvatarBytes = bytes;
          _selectedFileName = image.name;
        });
        // 📱 MARK Z: Facebook-style success feedback
        _showSuccessMessage('📸 Ảnh đã được chụp! Nhấn Lưu để cập nhật.');
      }
    } catch (e) {
      // 🚀 MUSK: Removed fragile string matching. If we are here, it's a real error.
      _showErrorMessage('Lỗi khi chụp ảnh: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    // Navigator.pop(context); // 🚀 MUSK_FIX: Removed double pop (handled by caller)
    
    // 📱 MARK Z: Debug logging for user action tracking
    print('📷 USER ACTION: _pickImageFromGallery() called - should open GALLERY');

    try {
      final photosGranted = await PermissionService.checkPhotosPermission();
      if (!photosGranted) {
        _showErrorMessage(
          'Cần cấp quyền thư viện ảnh để chọn ảnh. Bạn có thể bật trong Cài đặt > Sabo Arena > Ảnh',
        );
        return;
      }

      // 📱 MARK Z: Explicit source confirmation
      print('📷 CALLING ImagePicker with source: ImageSource.gallery');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (!mounted) return; // 🚀 MUSK_FIX: Check mounted after async
        setState(() {
          _selectedAvatarPath = image.path;
          _selectedAvatarBytes = bytes;
          _selectedFileName = image.name;
        });
        // 📱 MARK Z: Facebook-style success feedback
        _showSuccessMessage('🖼️ Ảnh đã được chọn! Nhấn Lưu để cập nhật.');
      }
    } catch (e) {
       // 🚀 MUSK: Removed fragile string matching.
      _showErrorMessage('Lỗi khi chọn ảnh: $e');
    }
  }

  void _removeAvatar() {
    // Navigator.pop(context); // 🚀 MUSK_FIX: Removed double pop (handled by caller)

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
            customColor: Theme.of(context).colorScheme.error,
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedAvatarPath = 'REMOVE_AVATAR';
                _selectedAvatarBytes = null;
              });
              _showSuccessMessage('🗑️ Ảnh đại diện đã được xóa! Nhấn Lưu để cập nhật.');
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
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
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
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                AppButton(
                  label: 'Lưu',
                  type: AppButtonType.text,
                  customColor: theme.colorScheme.primary,
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
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _selectedAvatarBytes != null
                                ? Image.memory(_selectedAvatarBytes!,
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
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: theme.colorScheme.onPrimary,
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
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
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDisplay(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.lock_outlined, color: theme.colorScheme.outline, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}