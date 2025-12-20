import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_routes.dart';
import 'controllers/club_registration_controller.dart';
// ELON_MODE_AUTO_FIX

class ClubRegistrationScreen extends StatefulWidget {
  const ClubRegistrationScreen({super.key});

  @override
  State<ClubRegistrationScreen> createState() => _ClubRegistrationScreenState();
}

class _ClubRegistrationScreenState extends State<ClubRegistrationScreen> {
  late final ClubRegistrationController _controller;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ClubRegistrationController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            ),
            title: Text(
              'Đăng ký câu lạc bộ',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            centerTitle: true,
          ),
          body: Form(
            key: _controller.formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header thông tin
                        _buildSectionHeader(
                          'Thông tin cơ bản',
                          'Nhập thông tin cơ bản về câu lạc bộ của bạn',
                          Icons.business,
                          colorScheme,
                        ),
                        const SizedBox(height: 16),

                        // Tên câu lạc bộ
                        _buildTextField(
                          controller: _controller.clubNameController,
                          label: 'Tên câu lạc bộ',
                          hint: 'VD: Billiards Club Sài Gòn',
                          icon: Icons.store,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên câu lạc bộ';
                            }
                            if (value.trim().length < 3) {
                              return 'Tên câu lạc bộ phải có ít nhất 3 ký tự';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Thành phố
                        _buildDropdownField(
                          label: 'Thành phố',
                          value: _controller.selectedCity,
                          items: _controller.cities,
                          onChanged: _controller.setCity,
                          icon: Icons.location_city,
                          validator: (value) {
                            if (value == null) {
                              return 'Vui lòng chọn thành phố';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Địa chỉ chi tiết
                        _buildTextField(
                          controller: _controller.addressController,
                          label: 'Địa chỉ chi tiết',
                          hint: 'VD: 123 Nguyễn Huệ, Phường Bến Nghé, Quận 1',
                          icon: Icons.location_on,
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập địa chỉ';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Thông tin liên hệ
                        _buildSectionHeader(
                          'Thông tin liên hệ',
                          'Thông tin để khách hàng có thể liên hệ với bạn',
                          Icons.contact_phone,
                          colorScheme,
                        ),
                        const SizedBox(height: 16),

                        // Số điện thoại
                        _buildTextField(
                          controller: _controller.phoneController,
                          label: 'Số điện thoại',
                          hint: 'VD: 0901234567',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            if (value.length < 10) {
                              return 'Số điện thoại phải có ít nhất 10 số';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Email
                        _buildTextField(
                          controller: _controller.emailController,
                          label: 'Email',
                          hint: 'VD: contact@billiards.com',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Website (optional)
                        _buildTextField(
                          controller: _controller.websiteController,
                          label: 'Website (tùy chọn)',
                          hint: 'VD: https://billiards.com',
                          icon: Icons.language,
                          keyboardType: TextInputType.url,
                        ),

                        const SizedBox(height: 24),

                        // Xác thực quyền sở hữu
                        _buildSectionHeader(
                          'Xác thực quyền sở hữu',
                          'Cung cấp hình ảnh để xác minh bạn là chủ sở hữu',
                          Icons.verified_user,
                          colorScheme,
                        ),
                        const SizedBox(height: 16),

                        _buildImageUploadField(
                          label: 'Giấy phép kinh doanh',
                          file: _controller.businessLicenseImage,
                          onTap: _controller.pickBusinessLicenseImage,
                          colorScheme: colorScheme,
                        ),

                        const SizedBox(height: 16),

                        _buildImageUploadField(
                          label: 'CCCD/CMND (Mặt trước)',
                          file: _controller.identityCardImage,
                          onTap: _controller.pickIdentityCardImage,
                          colorScheme: colorScheme,
                        ),

                        const SizedBox(height: 24),

                        // Mô tả
                        _buildSectionHeader(
                          'Mô tả câu lạc bộ',
                          'Giới thiệu về câu lạc bộ, dịch vụ và đặc điểm nổi bật',
                          Icons.description,
                          colorScheme,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _controller.descriptionController,
                          label: 'Mô tả',
                          hint:
                              'Giới thiệu về câu lạc bộ, lịch sử, dịch vụ và những điều đặc biệt...',
                          icon: Icons.notes,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mô tả câu lạc bộ';
                            }
                            if (value.trim().length < 20) {
                              return 'Mô tả phải có ít nhất 20 ký tự';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Tiện ích
                        _buildSectionHeader(
                          'Tiện ích & Dịch vụ',
                          'Chọn các tiện ích có sẵn tại câu lạc bộ',
                          Icons.star,
                          colorScheme,
                        ),
                        const SizedBox(height: 16),

                        _buildAmenitiesSelection(colorScheme),

                        const SizedBox(height: 24),

                        // Giờ hoạt động
                        _buildSectionHeader(
                          'Giờ hoạt động',
                          'Thiết lập giờ mở cửa của câu lạc bộ',
                          Icons.access_time,
                          colorScheme,
                        ),
                        const SizedBox(height: 16),

                        _buildOperatingHours(colorScheme),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _controller.isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: colorScheme.outline),
                          ),
                          child: Text(
                            'Hủy',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _controller.isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _controller.isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Đăng ký câu lạc bộ',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
    );
  }

  Widget _buildAmenitiesSelection(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _controller.allAmenities.map((amenity) {
        final isSelected = _controller.selectedAmenities.contains(amenity);
        return FilterChip(
          label: Text(amenity),
          selected: isSelected,
          onSelected: (selected) {
            _controller.toggleAmenity(amenity);
          },
          backgroundColor: colorScheme.surface,
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.primary,
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOperatingHours(ColorScheme colorScheme) {
    return Column(
      children: _controller.operatingHours.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () => _showTimePicker(entry.key, entry.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Icon(
                          Icons.access_time,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showTimePicker(String day, String currentTime) async {
    // Parse current time range (e.g., "08:00 - 22:00")
    final parts = currentTime.split(' - ');
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 22, minute: 0);

    if (parts.length == 2) {
      final startParts = parts[0].split(':');
      final endParts = parts[1].split(':');
      if (startParts.length == 2) {
        startTime = TimeOfDay(
            hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      }
      if (endParts.length == 2) {
        endTime = TimeOfDay(
            hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      }
    }

    final TimeOfDay? newStartTime = await showTimePicker(
      context: context,
      initialTime: startTime,
      helpText: 'CHỌN GIỜ MỞ CỬA ($day)',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.primary,
              dayPeriodTextColor: Theme.of(context).colorScheme.primary,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialBackgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newStartTime == null) return;

    if (!mounted) return;

    final TimeOfDay? newEndTime = await showTimePicker(
      context: context,
      initialTime: endTime,
      helpText: 'CHỌN GIỜ ĐÓNG CỬA ($day)',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.primary,
              dayPeriodTextColor: Theme.of(context).colorScheme.primary,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialBackgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newEndTime == null) return;

    // Format time to HH:mm
    String formatTime(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    final newTimeRange =
        '${formatTime(newStartTime)} - ${formatTime(newEndTime)}';
    _controller.updateOperatingHours(day, newTimeRange);
  }

  void _submitForm() async {
    await _controller.submitForm(
      onError: (message) {
        if (message.contains('chưa đăng nhập')) {
          // Navigate to login screen
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.loginScreen,
              (route) => false,
            );
          }
        } else {
          _showErrorSnackBar(message);
        }
      },
      onSuccess: () {
        if (mounted) {
          _showSuccessDialog();
        }
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text(
          'Đăng ký CLB thành công!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Câu lạc bộ của bạn đã được gửi để xét duyệt.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bước tiếp theo:',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⏳ Chờ admin phê duyệt (24-48 giờ)\n'
                    '📧 Nhận email thông báo kết quả\n'
                    '🎯 Bắt đầu quản lý CLB của bạn',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: Text(
              'Quay lại',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Navigate to main screen (PersistentTabScaffold)
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.mainScreen,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadField({
    required String label,
    required XFile? file,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(
                            file.path,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.error));
                            },
                          )
                        : FutureBuilder<Uint8List>(
                            future: file.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhấn để tải ảnh lên',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
