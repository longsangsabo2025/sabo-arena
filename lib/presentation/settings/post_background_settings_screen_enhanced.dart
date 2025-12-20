import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../models/post_background_theme.dart';
import '../../core/design_system/design_system.dart';
import '../../theme/app_bar_theme.dart' as app_theme;
import '../../core/utils/user_friendly_messages.dart';
// ELON_MODE_AUTO_FIX

/// Màn hình cài đặt background cho posts không có ảnh - Enhanced version
/// Features:
/// - Upload ảnh từ thiết bị/kho ảnh
/// - Chỉnh overlay (lớp phủ màu)
/// - Điều chỉnh độ sáng/tối của background
class PostBackgroundSettingsScreenEnhanced extends StatefulWidget {
  const PostBackgroundSettingsScreenEnhanced({super.key});

  @override
  State<PostBackgroundSettingsScreenEnhanced> createState() =>
      _PostBackgroundSettingsScreenEnhancedState();
}

class _PostBackgroundSettingsScreenEnhancedState
    extends State<PostBackgroundSettingsScreenEnhanced> {
  String _selectedThemeId = PostBackgroundThemes.defaultTheme.id;
  bool _autoRotate = false;

  // Custom background settings
  File? _customBackgroundImage;
  double _brightness = 0.0; // -1.0 to 1.0 (darker to brighter)
  Color _overlayColor = Colors.black;
  double _overlayOpacity = 0.3; // 0.0 to 1.0

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        // Load theme selection
        _selectedThemeId = prefs.getString('post_bg_theme_id') ??
            PostBackgroundThemes.defaultTheme.id;

        // Load auto-rotate
        _autoRotate = prefs.getBool('post_bg_auto_rotate') ?? false;

        // Load custom image path
        final imagePath = prefs.getString('post_bg_custom_image');
        if (imagePath != null && imagePath.isNotEmpty) {
          final file = File(imagePath);
          if (file.existsSync()) {
            _customBackgroundImage = file;
            _selectedThemeId = 'custom'; // Mark as custom
          }
        }

        // Load brightness
        _brightness = prefs.getDouble('post_bg_brightness') ?? 0.0;

        // Load overlay color
        final colorValue = prefs.getInt('post_bg_overlay_color');
        if (colorValue != null) {
          _overlayColor = Color(colorValue);
        }

        // Load overlay opacity
        _overlayOpacity = prefs.getDouble('post_bg_overlay_opacity') ?? 0.3;
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save theme selection
      await prefs.setString('post_bg_theme_id', _selectedThemeId);

      // Save auto-rotate
      await prefs.setBool('post_bg_auto_rotate', _autoRotate);

      // Save custom image path
      if (_customBackgroundImage != null) {
        await prefs.setString(
          'post_bg_custom_image',
          _customBackgroundImage!.path,
        );
      } else {
        await prefs.remove('post_bg_custom_image');
      }

      // Save brightness
      await prefs.setDouble('post_bg_brightness', _brightness);

      // Save overlay color
      await prefs.setInt('post_bg_overlay_color', _overlayColor.toARGB32());

      // Save overlay opacity
      await prefs.setDouble('post_bg_overlay_opacity', _overlayOpacity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu cài đặt background'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi lưu: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _customBackgroundImage = File(image.path);
          _selectedThemeId = 'custom'; // Mark as custom
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserFriendlyMessages.getErrorMessage(e, context: 'Chọn ảnh'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _customBackgroundImage = File(image.path);
          _selectedThemeId = 'custom';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserFriendlyMessages.getErrorMessage(e, context: 'Chụp ảnh'),
            ),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Chọn nguồn ảnh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gallery option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library, color: AppColors.primary),
              ),
              title: const Text(
                'Thư viện ảnh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Chọn từ kho ảnh của bạn'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),

            // Camera option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: const Text(
                'Máy ảnh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),

            const SizedBox(height: 8),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBackgroundControls() {
    if (_customBackgroundImage == null && _selectedThemeId != 'custom') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Section header
        Text(
          'Tùy chỉnh background',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // Brightness control
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.brightness_6, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Độ sáng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _brightness > 0
                        ? '+${(_brightness * 100).toInt()}%'
                        : '${(_brightness * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.brightness_low,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                  Expanded(
                    child: Slider(
                      value: _brightness,
                      min: -1.0,
                      max: 1.0,
                      divisions: 20,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() => _brightness = value);
                      },
                    ),
                  ),
                  Icon(
                    Icons.brightness_high,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Overlay controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overlay opacity
              Row(
                children: [
                  Icon(Icons.layers, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Độ đậm lớp phủ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(_overlayOpacity * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: _overlayOpacity,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() => _overlayOpacity = value);
                },
              ),

              const SizedBox(height: 16),

              // Overlay color picker
              Row(
                children: [
                  Icon(Icons.palette, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Màu lớp phủ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Color options
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildColorOption(Colors.black, 'Đen'),
                  _buildColorOption(const Color(0xFF1a472a), 'Xanh lục'),
                  _buildColorOption(const Color(0xFF003366), 'Xanh dương'),
                  _buildColorOption(const Color(0xFF4A0E4E), 'Tím'),
                  _buildColorOption(const Color(0xFF8B4513), 'Nâu'),
                  _buildColorOption(Colors.white, 'Trắng'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorOption(Color color, String label) {
    final isSelected = _overlayColor == color;

    return GestureDetector(
      onTap: () {
        setState(() => _overlayColor = color);
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: color == Colors.white ? Colors.black : Colors.white,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPreview() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            if (_customBackgroundImage != null)
              Image.file(_customBackgroundImage!, fit: BoxFit.cover)
            else if (_selectedThemeId != 'custom')
              Container(
                decoration: BoxDecoration(
                  gradient: PostBackgroundThemes.allThemes
                      .firstWhere(
                        (t) => t.id == _selectedThemeId,
                        orElse: () => PostBackgroundThemes.defaultTheme,
                      )
                      .gradient,
                ),
              ),

            // Brightness adjustment
            if (_brightness != 0.0)
              Container(
                color: _brightness > 0
                    ? Colors.white.withValues(alpha: _brightness.abs() * 0.5)
                    : Colors.black.withValues(alpha: _brightness.abs() * 0.5),
              ),

            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _overlayColor.withValues(alpha: _overlayOpacity * 0.6),
                    _overlayColor.withValues(alpha: _overlayOpacity),
                  ],
                ),
              ),
            ),

            // Preview text
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Đây là preview của background bài đăng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: app_theme.AppBarTheme.primaryGreen,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: app_theme.AppBarTheme.buildGradientTitle('Background bài đăng'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Lưu',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chọn background cho bài đăng không có hình ảnh',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),

          // Preview
          _buildBackgroundPreview(),

          // Upload custom image button
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: OutlinedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Upload ảnh tùy chỉnh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Custom controls (brightness, overlay)
          _buildCustomBackgroundControls(),

          const SizedBox(height: 24),

          // Auto-rotate toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.autorenew, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tự động đổi background',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Mỗi bài đăng sẽ có background khác nhau',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _autoRotate,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() => _autoRotate = value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Predefined themes header
          Text(
            'Chọn background mặc định',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Predefined theme grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: PostBackgroundThemes.allThemes.length,
            itemBuilder: (context, index) {
              final theme = PostBackgroundThemes.allThemes[index];
              final isSelected = _selectedThemeId == theme.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedThemeId = theme.id;
                    _customBackgroundImage = null; // Clear custom image
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(gradient: theme.gradient),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Đây là preview của background này',
                              style: theme.textStyle.copyWith(fontSize: 13),
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                            child: Text(
                              theme.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
