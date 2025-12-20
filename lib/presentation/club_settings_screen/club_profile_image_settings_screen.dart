import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sabo_arena/services/club_service.dart';
import 'package:sabo_arena/models/club.dart';

class ClubProfileImageSettingsScreen extends StatefulWidget {
  final String clubId;

  const ClubProfileImageSettingsScreen({super.key, required this.clubId});

  @override
  State<ClubProfileImageSettingsScreen> createState() =>
      _ClubProfileImageSettingsScreenState();
}

class _ClubProfileImageSettingsScreenState
    extends State<ClubProfileImageSettingsScreen> {
  final ClubService _clubService = ClubService.instance;
  final ImagePicker _picker = ImagePicker();

  Club? _club;
  bool _isLoading = true;
  bool _isUploadingProfile = false;
  bool _isUploadingCover = false;

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  Future<void> _loadClubData() async {
    try {
      setState(() => _isLoading = true);
      final club = await _clubService.getClubById(widget.clubId);
      setState(() {
        _club = club;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin CLB: $error')),
        );
      }
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingProfile = true);

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Upload to Supabase and update club
      final updatedClub = await _clubService.uploadAndUpdateProfileImage(
        widget.clubId,
        imageBytes,
        image.name,
      );

      setState(() {
        _club = updatedClub;
        _isUploadingProfile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ảnh đại diện đã được cập nhật thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      setState(() => _isUploadingProfile = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi upload ảnh đại diện: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadCoverImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingCover = true);

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Upload to Supabase and update club
      final updatedClub = await _clubService.uploadAndUpdateCoverImage(
        widget.clubId,
        imageBytes,
        image.name,
      );

      setState(() {
        _club = updatedClub;
        _isUploadingCover = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ảnh bìa đã được cập nhật thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      setState(() => _isUploadingCover = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi upload ảnh bìa: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Ảnh đại diện & Ảnh bìa')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ảnh đại diện & Ảnh bìa'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image Section
            Text(
              'Ảnh đại diện',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  // Current profile image or placeholder
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      image: _club?.profileImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_club!.profileImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _club?.profileImageUrl == null
                        ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                        : null,
                  ),
                  SizedBox(height: 16),
                  // Upload button
                  ElevatedButton.icon(
                    onPressed:
                        _isUploadingProfile ? null : _pickAndUploadProfileImage,
                    icon: _isUploadingProfile
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.upload),
                    label: Text(
                      _isUploadingProfile
                          ? 'Đang upload...'
                          : 'Thay đổi ảnh đại diện',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ảnh đại diện sẽ hiển thị trên danh sách CLB và trang hồ sơ',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Cover Image Section
            Text(
              'Ảnh bìa',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  // Current cover image or placeholder
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                      image: _club?.coverImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_club!.coverImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _club?.coverImageUrl == null
                        ? Icon(Icons.image, size: 50, color: Colors.grey[400])
                        : null,
                  ),
                  SizedBox(height: 16),
                  // Upload button
                  ElevatedButton.icon(
                    onPressed:
                        _isUploadingCover ? null : _pickAndUploadCoverImage,
                    icon: _isUploadingCover
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.upload),
                    label: Text(
                      _isUploadingCover ? 'Đang upload...' : 'Thay đổi ảnh bìa',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ảnh bìa sẽ hiển thị ở đầu trang CLB và làm nổi bật thương hiệu',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Tips section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Text(
                        'Mẹo để có ảnh đẹp',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Ảnh đại diện: Sử dụng ảnh vuông, rõ nét khuôn mặt hoặc logo\n• Ảnh bìa: Sử dụng ảnh ngang, thể hiện không gian CLB\n• Định dạng hỗ trợ: JPG, PNG, tối đa 10MB',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
