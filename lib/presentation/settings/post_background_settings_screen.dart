import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../models/post_background_theme.dart';
import '../../core/design_system/design_system.dart';
import '../../theme/app_bar_theme.dart' as app_theme;

/// Màn hình cài đặt background cho posts không có ảnh
class PostBackgroundSettingsScreen extends StatefulWidget {
  const PostBackgroundSettingsScreen({super.key});

  @override
  State<PostBackgroundSettingsScreen> createState() =>
      _PostBackgroundSettingsScreenState();
}

class _PostBackgroundSettingsScreenState
    extends State<PostBackgroundSettingsScreen> {
  String _selectedThemeId = PostBackgroundThemes.defaultTheme.id;
  bool _autoRotate = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load từ SharedPreferences hoặc database
    // final prefs = await SharedPreferences.getInstance();
    // setState(() {
    //   _selectedThemeId = prefs.getString('post_background_theme') ?? 'billiard_green';
    //   _autoRotate = prefs.getBool('post_background_auto_rotate') ?? false;
    // });
  }

  Future<void> _saveSettings() async {
    // TODO: Save to SharedPreferences hoặc database
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('post_background_theme', _selectedThemeId);
    // await prefs.setBool('post_background_auto_rotate', _autoRotate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã lưu cài đặt background'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        shadowColor: AppColors.shadow,
        leading: IconButton(
          icon: const Icon(
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
              'Lưu', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontFamily: _getSystemFont(),
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
                    'Chọn background cho bài đăng không có hình ảnh', overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontFamily: _getSystemFont(),
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Auto rotate option
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SwitchListTile(
              value: _autoRotate,
              onChanged: (value) {
                setState(() {
                  _autoRotate = value;
                });
              },
              title: Text(
                'Tự động đổi background', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontFamily: _getSystemFont(),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Mỗi bài đăng sẽ có background khác nhau', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontFamily: _getSystemFont(),
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              activeThumbColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Theme selection
          Text(
            'Chọn background mặc định', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontFamily: _getSystemFont(),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Theme grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: PostBackgroundThemes.allThemes.length,
            itemBuilder: (context, index) {
              final theme = PostBackgroundThemes.allThemes[index];
              final isSelected = theme.id == _selectedThemeId;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedThemeId = theme.id;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
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
                        // Background preview
                        Container(
                          decoration: BoxDecoration(gradient: theme.gradient),
                        ),

                        // Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.shadow.withValues(alpha: 0.3),
                                AppColors.shadow.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),

                        // Preview text
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Đây là preview của background này',
                              style: theme.textStyle.copyWith(
                                fontSize: 13,
                                fontFamily: _getSystemFont(),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        // Theme name
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
                              color: AppColors.shadow.withValues(alpha: 0.7),
                            ),
                            child: Text(
                              theme.name, style: TextStyle(
                                fontFamily: _getSystemFont(),
                                color: AppColors.textOnPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // Selected indicator
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
                                    color: AppColors.shadow.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: AppColors.textOnPrimary,
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

  String _getSystemFont() {
    try {
      if (Platform.isIOS) {
        return '.SF Pro Display';
      } else {
        return 'Roboto';
      }
    } catch (e) {
      return 'Roboto';
    }
  }
}
