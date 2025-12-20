import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/user_friendly_messages.dart';
import '../../../core/design_system/design_system.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/common/app_button.dart';
import '../../../services/post_repository.dart';
import '../../../services/club_service.dart';
import '../../../models/club.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class CreatePostModalWidget extends StatefulWidget {
  final VoidCallback? onPostCreated;
  final String? defaultClubId; // 🎱 For posting as club from club profile

  const CreatePostModalWidget({
    super.key,
    this.onPostCreated,
    this.defaultClubId,
  });

  @override
  State<CreatePostModalWidget> createState() => _CreatePostModalWidgetState();
}

class _CreatePostModalWidgetState extends State<CreatePostModalWidget> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final PostRepository _postRepository = PostRepository();
  final ClubService _clubService = ClubService.instance;

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  XFile? _selectedImage;
  XFile? _selectedVideo;
  String? _uploadedVideoId;
  bool _isLoading = false;
  bool _showCamera = false;
  bool _isUploadingVideo = false;
  double _videoUploadProgress = 0.0;

  // 🎱 Club posting state
  List<Club> _managedClubs = [];
  Club? _selectedClub;

  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final response = await Supabase.instance.client
          .from('users')
          .select('display_name, username, full_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// 🎱 Load clubs that user can manage
  Future<void> _loadManagedClubs() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final clubs = await _clubService.getUserManagedClubs(user.id);

      setState(() {
        _managedClubs = clubs;

        // Set default club if provided
        if (widget.defaultClubId != null && clubs.isNotEmpty) {
          _selectedClub = clubs.firstWhere(
            (c) => c.id == widget.defaultClubId,
            orElse: () => clubs.first,
          );
        }
      });
    } catch (e) {
      // Ignore error
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadManagedClubs(); // 🎱 Load clubs on init
  }

  @override
  void dispose() {
    _textController.dispose();
    _locationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;

    try {
      ProductionLogger.info('🔍 Checking camera permission...',
          tag: 'create_post_modal_widget');
      final status = await Permission.camera.status;
      ProductionLogger.info('📋 Current camera permission status: $status',
          tag: 'create_post_modal_widget');

      if (status == PermissionStatus.granted) {
        ProductionLogger.info('✅ Camera permission already granted',
            tag: 'create_post_modal_widget');
        return true;
      }

      if (status == PermissionStatus.permanentlyDenied) {
        ProductionLogger.info('❌ Camera permission permanently denied',
            tag: 'create_post_modal_widget');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Quyền camera bị từ chối vĩnh viễn. Vui lòng bật trong cài đặt.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return false;
      }

      ProductionLogger.info('🔄 Requesting camera permission...',
          tag: 'create_post_modal_widget');
      final result = await Permission.camera.request();
      ProductionLogger.info('📋 Camera permission result: $result',
          tag: 'create_post_modal_widget');

      if (result == PermissionStatus.granted) {
        ProductionLogger.info('✅ Camera permission granted',
            tag: 'create_post_modal_widget');
        return true;
      } else {
        ProductionLogger.info('❌ Camera permission denied',
            tag: 'create_post_modal_widget');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cần quyền camera để chụp ảnh'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      ProductionLogger.info('❌ Error requesting camera permission: $e',
          tag: 'create_post_modal_widget');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xin quyền camera: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      if (!await _requestCameraPermission()) return;

      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      );

      await _cameraController!.initialize();
      await _applySettings();

      if (mounted) setState(() {});
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _applySettings() async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
    } catch (e) {
      // Ignore error
    }

    if (!kIsWeb) {
      try {
        await _cameraController!.setFlashMode(FlashMode.auto);
      } catch (e) {
        // Ignore error
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _selectedImage = photo;
        _showCamera = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể chụp ảnh')));
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      ProductionLogger.info('🔍 Starting image picker from gallery...',
          tag: 'create_post_modal_widget');

      // Let iOS/Android handle permission automatically (no pre-check needed)
      // ImagePicker will trigger native permission dialog on first access
      ProductionLogger.info('🎨 Opening image picker...',
          tag: 'create_post_modal_widget');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        ProductionLogger.info('✅ Image selected successfully: ${image.path}',
            tag: 'create_post_modal_widget');
        setState(() {
          _selectedImage = image;
          _showCamera = false;
        });
      } else {
        ProductionLogger.info('ℹ️ No image selected (user cancelled)',
            tag: 'create_post_modal_widget');
      }
    } catch (e) {
      ProductionLogger.info('❌ Gallery picker error: $e',
          tag: 'create_post_modal_widget');
      // If permission denied, show helpful message
      if (e.toString().contains('photo') ||
          e.toString().contains('library') ||
          e.toString().contains('denied')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cần cấp quyền thư viện ảnh để chọn ảnh. Bạn có thể bật trong Cài đặt > Sabo Arena > Ảnh',
              ),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể chọn ảnh: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      ProductionLogger.info('📸 Starting image picker from camera...',
          tag: 'create_post_modal_widget');

      // Check camera permission
      if (!await _requestCameraPermission()) {
        ProductionLogger.info('❌ Camera permission not granted',
            tag: 'create_post_modal_widget');
        return;
      }

      ProductionLogger.info('📸 Opening camera...',
          tag: 'create_post_modal_widget');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        ProductionLogger.info('✅ Photo captured successfully: ${image.path}',
            tag: 'create_post_modal_widget');
        setState(() {
          _selectedImage = image;
          _showCamera = false;
        });
      } else {
        ProductionLogger.info('ℹ️ No photo captured (user cancelled)',
            tag: 'create_post_modal_widget');
      }
    } catch (e) {
      ProductionLogger.info('❌ Camera picker error: $e',
          tag: 'create_post_modal_widget');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chụp ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      ProductionLogger.info('🔍 Starting video picker from gallery...',
          tag: 'create_post_modal_widget');

      // Let iOS/Android handle permission automatically (no pre-check needed)
      // ImagePicker will trigger native permission dialog on first access
      ProductionLogger.info('🎥 Opening video picker...',
          tag: 'create_post_modal_widget');
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60), // Cho phép video tối đa 60s
      );

      if (video != null) {
        ProductionLogger.info('✅ Video selected successfully: ${video.path}',
            tag: 'create_post_modal_widget');
        setState(() {
          _isLoading = true;
        });

        try {
          // Upload video to Supabase Storage
          final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
          final filePath = 'posts/$fileName';

          setState(() {
            _isUploadingVideo = true;
            _videoUploadProgress = 0.1;
          });

          // Read video bytes
          final videoBytes = await video.readAsBytes();

          setState(() => _videoUploadProgress = 0.3);

          // Upload to Supabase Storage
          await Supabase.instance.client.storage
              .from('post-media')
              .uploadBinary(
                filePath,
                videoBytes,
                fileOptions: const FileOptions(
                  contentType: 'video/mp4',
                  upsert: false,
                ),
              );

          setState(() => _videoUploadProgress = 0.8);

          // Get public URL
          final videoUrl = Supabase.instance.client.storage
              .from('post-media')
              .getPublicUrl(filePath);

          setState(() {
            _selectedVideo = video;
            _uploadedVideoId =
                videoUrl; // Store video URL instead of YouTube ID
            _selectedImage = null; // Clear image if video is selected
            _showCamera = false;
            _videoUploadProgress = 1.0;
          });

          await Future.delayed(const Duration(milliseconds: 500));

          setState(() {
            _isUploadingVideo = false;
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Video đã được tải lên!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (uploadError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ Không thể tải video lên: ${uploadError.toString()}',
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          setState(() {
            _isUploadingVideo = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // If permission denied, show helpful message
      if (e.toString().contains('photo') ||
          e.toString().contains('library') ||
          e.toString().contains('denied')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cần cấp quyền thư viện ảnh để chọn video. Bạn có thể bật trong Cài đặt > Sabo Arena > Ảnh',
              ),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi chọn video: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
      setState(() {
        _isUploadingVideo = false;
        _isLoading = false;
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_library',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.video_library,
                color: AppColors.error,
                size: 24,
              ),
              title: const Text('Thêm video (max 15s)'),
              onTap: () {
                Navigator.pop(context);
                _pickVideoFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Dialog tag người
  void _showTagPeopleDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gắn thẻ người',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn bè...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tính năng đang phát triển',
              style: TextStyle(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Dialog cảm xúc/hoạt động
  void _showFeelingDialog() {
    final feelings = [
      {'emoji': '😊', 'text': 'hạnh phúc'},
      {'emoji': '😍', 'text': 'yêu thích'},
      {'emoji': '😂', 'text': 'vui vẻ'},
      {'emoji': '😢', 'text': 'buồn'},
      {'emoji': '😎', 'text': 'ngầu'},
      {'emoji': '🥳', 'text': 'vui mừng'},
      {'emoji': '😴', 'text': 'buồn ngủ'},
      {'emoji': '🤔', 'text': 'suy nghĩ'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn đang cảm thấy thế nào?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: feelings.length,
                itemBuilder: (context, index) {
                  final feeling = feelings[index];
                  return InkWell(
                    onTap: () {
                      final currentText = _textController.text;
                      final feeling = feelings[index];
                      _textController.text =
                          '$currentText đang cảm thấy ${feeling['text']} ${feeling['emoji']}';
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            feeling['emoji']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            feeling['text']!,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog location với gợi ý địa điểm
  void _showLocationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _LocationPickerView(
          scrollController: scrollController,
          onLocationSelected: (locationName) {
            final currentText = _textController.text;
            _textController.text = '$currentText — tại $locationName 📍';
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // Dialog tag CLB
  void _showTagClubDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _TagClubView(
          scrollController: scrollController,
          onClubSelected: (clubName) {
            final currentText = _textController.text;
            _textController.text = '$currentText — tại CLB $clubName 🎱';
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _createPost() async {
    ProductionLogger.info('🚀 Starting post creation...',
        tag: 'create_post_modal_widget');

    if (_textController.text.trim().isEmpty &&
        _selectedImage == null &&
        _selectedVideo == null) {
      ProductionLogger.info('❌ No content provided',
          tag: 'create_post_modal_widget');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung, chọn ảnh hoặc video'),
        ),
      );
      return;
    }

    ProductionLogger.info('📝 Content: "${_textController.text.trim()}"',
        tag: 'create_post_modal_widget');
    ProductionLogger.info('📷 Has image: ${_selectedImage != null}',
        tag: 'create_post_modal_widget');
    ProductionLogger.info('🎥 Has video: ${_selectedVideo != null}',
        tag: 'create_post_modal_widget');

    setState(() => _isLoading = true);

    try {
      // Extract hashtags from content
      final content = _textController.text.trim();
      final hashtags = RegExp(
        r'#\w+',
      ).allMatches(content).map((match) => match.group(0)!).toList();

      ProductionLogger.info('🏷️ Extracted hashtags: $hashtags',
          tag: 'create_post_modal_widget');

      // Upload image if selected
      String? uploadedImageUrl;
      if (_selectedImage != null) {
        try {
          ProductionLogger.info('📤 Uploading image...',
              tag: 'create_post_modal_widget');
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) throw Exception('User not authenticated');

          ProductionLogger.info('👤 User authenticated: ${user.id}',
              tag: 'create_post_modal_widget');

          // Read image bytes
          final imageBytes = await _selectedImage!.readAsBytes();
          final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final filePath = 'posts/${user.id}/$fileName';

          ProductionLogger.info('📁 Uploading to path: $filePath',
              tag: 'create_post_modal_widget');
          ProductionLogger.info('📊 Image size: ${imageBytes.length} bytes',
              tag: 'create_post_modal_widget');

          // Upload to Supabase Storage
          await Supabase.instance.client.storage
              .from('user-images')
              .uploadBinary(
                filePath,
                imageBytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg', // Most camera photos are JPEG
                  upsert: true,
                ),
              );

          // Get public URL
          uploadedImageUrl = Supabase.instance.client.storage
              .from('user-images')
              .getPublicUrl(filePath);

          ProductionLogger.info(
              '✅ Image uploaded successfully: $uploadedImageUrl',
              tag: 'create_post_modal_widget');
        } catch (uploadError) {
          ProductionLogger.info('❌ Image upload error: $uploadError',
              tag: 'create_post_modal_widget');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi tải ảnh lên: $uploadError')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Get video metadata if video was uploaded
      String? videoThumbnailUrl;
      int? videoDuration;
      String? videoPlatform;

      if (_uploadedVideoId != null) {
        // Video was uploaded to Supabase Storage
        videoPlatform = 'supabase';
        videoThumbnailUrl = null; // Can generate thumbnail later if needed
        videoDuration = null; // Can extract duration if needed
        ProductionLogger.info(
            '🎥 Video data: platform=$videoPlatform, url=$_uploadedVideoId',
            tag: 'create_post_modal_widget');
      }

      ProductionLogger.info('📋 Creating post with data:',
          tag: 'create_post_modal_widget');
      ProductionLogger.info('  Content: "$content"',
          tag: 'create_post_modal_widget');
      ProductionLogger.info('  Image URL: $uploadedImageUrl',
          tag: 'create_post_modal_widget');
      ProductionLogger.info('  Video URL: $_uploadedVideoId',
          tag: 'create_post_modal_widget');
      ProductionLogger.info('  Hashtags: $hashtags',
          tag: 'create_post_modal_widget');
      ProductionLogger.info('  Location: ${_locationController.text.trim()}',
          tag: 'create_post_modal_widget');
      ProductionLogger.info(
          '  Club ID: ${_selectedClub?.id ?? "null (posting as user)"}',
          tag: 'create_post_modal_widget');

      // Create the post with uploaded image URL or video URL
      final post = await _postRepository.createPost(
        content: content,
        imageUrl: uploadedImageUrl,
        videoUrl: _uploadedVideoId, // Supabase Storage URL
        videoPlatform: videoPlatform,
        videoDuration: videoDuration,
        videoThumbnailUrl: videoThumbnailUrl,
        hashtags: hashtags.isNotEmpty ? hashtags : null,
        locationName: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        clubId: _selectedClub?.id, // 🎱 Post as club if selected
      );

      ProductionLogger.info('📝 Post creation result: ${post?.id ?? "NULL"}',
          tag: 'create_post_modal_widget');

      setState(() => _isLoading = false);

      if (mounted) {
        if (post != null) {
          ProductionLogger.info(
              '✅ Post created successfully with ID: ${post.id}',
              tag: 'create_post_modal_widget');
          Navigator.pop(context);
          widget.onPostCreated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đăng bài viết thành công!')),
          );
        } else {
          ProductionLogger.info('❌ Post creation returned null',
              tag: 'create_post_modal_widget');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi đăng bài viết. Vui lòng thử lại!'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng bài: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.surface, // Facebook: pure white
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header - Facebook style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border, // Facebook divider
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Spacer left for balance
                const SizedBox(width: 40),
                // Title centered
                const Expanded(
                  child: Text(
                    'Tạo bài viết',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17, // Facebook heading
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // Close button right
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.border, // Facebook gray background
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _showCamera ? _buildCameraView() : _buildPostForm()),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        CameraPreview(_cameraController!),
        Positioned(
          bottom: 60, // Facebook: fixed spacing
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => setState(() => _showCamera = false),
                icon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.shadowDark,
                  ),
                  child: const Icon(Icons.close,
                      color: AppColors.textOnPrimary, size: 24),
                ),
              ),
              GestureDetector(
                onTap: _capturePhoto,
                child: Container(
                  width: 72, // Fixed size instead of 20.w
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.info, // Facebook blue
                      width: 4,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _pickImageFromGallery,
                icon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.shadowDark,
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.surface,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info - Facebook style
          FutureBuilder<Map<String, dynamic>?>(
            future: _getUserData(),
            builder: (context, snapshot) {
              final userData = snapshot.data;
              final displayName = userData?['display_name'] as String? ??
                  userData?['username'] as String? ??
                  userData?['full_name'] as String? ??
                  'Người dùng';
              final avatarUrl = userData?['avatar_url'] as String?;

              return Row(
                children: [
                  // Avatar - 40px Facebook standard
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: ClipOval(
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CustomImageWidget(
                              imageUrl: avatarUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppColors.info,
                              child: Center(
                                child: Text(
                                  displayName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.surface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.public,
                                size: 12,
                                color: AppColors.textPrimary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Công khai',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // 🎱 Post As Selector (if user manages clubs)
          if (_managedClubs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sports_basketball,
                    size: 20,
                    color: AppColors.premium,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Đăng bài với tư cách:',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String?>(
                      value: _selectedClub?.id,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      items: [
                        // Post as user option
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.person,
                                  size: 18, color: AppColors.info),
                              SizedBox(width: 8),
                              Text(
                                'Cá nhân',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        // Post as club options
                        ..._managedClubs.map((club) {
                          return DropdownMenuItem<String?>(
                            value: club.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.premium
                                        .withValues(alpha: 0.1),
                                  ),
                                  child: club.logoUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            club.logoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stack) {
                                              return const Icon(
                                                Icons.sports_basketball,
                                                size: 12,
                                                color: AppColors.premium,
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(
                                          Icons.sports_basketball,
                                          size: 12,
                                          color: AppColors.premium,
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    club.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (String? clubId) {
                        setState(() {
                          if (clubId == null) {
                            _selectedClub = null;
                          } else {
                            _selectedClub =
                                _managedClubs.firstWhere((c) => c.id == clubId);
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Text input - Facebook style
          TextField(
            controller: _textController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Bạn đang nghĩ gì về billiards?',
              border: InputBorder.none,
              hintStyle: TextStyle(
                fontSize: 15, // Facebook: content text
                color: AppColors.textSecondary, // Facebook: gray600
                fontWeight: FontWeight.w400,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary, // Facebook: text primary
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 8), // Facebook: 8px spacing
          // Selected image - Facebook style (improved)
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.35,
                            fit: BoxFit.cover,
                          )
                        : FutureBuilder<Uint8List>(
                            future: _selectedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height * 0.35,
                                  fit: BoxFit.cover,
                                );
                              } else if (snapshot.hasError) {
                                return Container(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height * 0.35,
                                  color: AppColors.gray50,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: AppColors.error,
                                          size: 48,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Không thể tải ảnh',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return Container(
                                width: double.infinity,
                                height:
                                    MediaQuery.of(context).size.height * 0.35,
                                color: AppColors.gray50,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.info,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // Remove button - Facebook style
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowDark,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Selected video preview with upload progress
          if (_selectedVideo != null || _isUploadingVideo)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1),
                color: AppColors.gray50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.video_library,
                          color: AppColors.error,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isUploadingVideo
                                  ? 'Đang tải video lên YouTube...'
                                  : '✅ Video đã sẵn sàng!',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isUploadingVideo
                                  ? 'Vui lòng đợi...'
                                  : 'Video sẽ được phát trên YouTube (unlisted)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isUploadingVideo)
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.error),
                          onPressed: () {
                            setState(() {
                              _selectedVideo = null;
                              _uploadedVideoId = null;
                            });
                          },
                        ),
                    ],
                  ),
                  if (_isUploadingVideo) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _videoUploadProgress,
                        backgroundColor: AppColors.gray300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.error,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_videoUploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (_uploadedVideoId != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Video ID: $_uploadedVideoId',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 12), // Facebook: 12px spacing
          // Action buttons - Facebook style với nút Đăng
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thêm vào bài viết của bạn',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildActionIcon(
                            icon: Icons.photo_library,
                            color: AppColors.success,
                            onTap: _showImageOptions,
                          ),
                          const SizedBox(width: 8),
                          _buildActionIcon(
                            icon: Icons.person_add,
                            color: AppColors.info,
                            onTap: _showTagPeopleDialog,
                          ),
                          const SizedBox(width: 8),
                          _buildActionIcon(
                            icon: Icons.sentiment_satisfied_alt,
                            color: AppColors.warning,
                            onTap: _showFeelingDialog,
                          ),
                          const SizedBox(width: 8),
                          _buildActionIcon(
                            icon: Icons.location_on,
                            color: AppColors.error,
                            onTap: _showLocationDialog,
                          ),
                          const SizedBox(width: 8),
                          _buildActionIcon(
                            icon: Icons.sports_basketball,
                            color: AppColors.premium, // Purple cho CLB
                            onTap: _showTagClubDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Nút Đăng ở cuối hàng - iOS style với AppButton
                SizedBox(
                  width: 80,
                  child: AppButton(
                    label: 'Đăng',
                    type: AppButtonType.primary,
                    size: AppButtonSize.medium,
                    customColor: AppColors.info,
                    customTextColor: AppColors.textOnPrimary,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _createPost,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

// Widget riêng cho Location Picker
class _LocationPickerView extends StatefulWidget {
  final ScrollController scrollController;
  final Function(String locationName) onLocationSelected;

  const _LocationPickerView({
    required this.scrollController,
    required this.onLocationSelected,
  });

  @override
  State<_LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<_LocationPickerView> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _popularLocations = [];
  List<Map<String, dynamic>> _filteredLocations = [];
  bool _isLoadingLocation = false;
  String? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _getCurrentLocation();
    _searchController.addListener(_filterLocations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeLocations() {
    // Load CLBs từ database
    _loadClubsAsLocations();

    // Danh sách địa điểm phổ biến
    _popularLocations.addAll([
      {
        'name': 'Hồ Chí Minh',
        'address': 'Thành phố',
        'icon': Icons.location_city,
        'type': 'city',
      },
      {
        'name': 'Hà Nội',
        'address': 'Thủ đô',
        'icon': Icons.location_city,
        'type': 'city',
      },
      {
        'name': 'Đà Nẵng',
        'address': 'Thành phố',
        'icon': Icons.location_city,
        'type': 'city',
      },
      {
        'name': 'Quận 1',
        'address': 'TP.HCM',
        'icon': Icons.location_on,
        'type': 'district',
      },
      {
        'name': 'Quận 3',
        'address': 'TP.HCM',
        'icon': Icons.location_on,
        'type': 'district',
      },
      {
        'name': 'Quận Bình Thạnh',
        'address': 'TP.HCM',
        'icon': Icons.location_on,
        'type': 'district',
      },
    ]);
    _filteredLocations = _popularLocations;
  }

  Future<void> _loadClubsAsLocations() async {
    try {
      final clubs = await ClubService.instance.getClubs(limit: 20);

      setState(() {
        // Thêm CLBs vào đầu danh sách
        for (var club in clubs) {
          _popularLocations.insert(0, {
            'name': club.name,
            'address': club.description ?? 'CLB bi-a',
            'icon': Icons.sports_basketball,
            'type': 'club',
            'logoUrl': club.logoUrl,
          });
        }
        _filteredLocations = _popularLocations;
        // Ignore error
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoadingLocation = true);

      // Check permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied ||
            result == LocationPermission.deniedForever) {
          setState(() {
            _isLoadingLocation = false;
            _currentLocation = null;
          });
          return;
        }
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      // TODO: Reverse geocoding để lấy tên địa điểm
      // Tạm thời hiển thị tọa độ
      setState(() {
        _currentLocation =
            'Vị trí hiện tại (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _currentLocation = null;
      });
    }
  }

  void _filterLocations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = _popularLocations;
      } else {
        _filteredLocations = _popularLocations.where((location) {
          final name = location['name']?.toLowerCase() ?? '';
          final address = location['address']?.toLowerCase() ?? '';
          return name.contains(query) || address.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.error),
              const SizedBox(width: 8),
              const Text(
                'Thêm vị trí',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current location
          if (_isLoadingLocation)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Đang lấy vị trí hiện tại...'),
                ],
              ),
            )
          else if (_currentLocation != null)
            InkWell(
              onTap: () => widget.onLocationSelected(_currentLocation!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentLocation!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.info,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm địa điểm...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              filled: true,
              fillColor: AppColors.gray50,
            ),
          ),
          const SizedBox(height: 16),

          // Locations list
          Expanded(
            child: _filteredLocations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Không tìm thấy địa điểm',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: _filteredLocations.length,
                    itemBuilder: (context, index) {
                      final location = _filteredLocations[index];
                      final logoUrl = location['logoUrl'] as String?;

                      return ListTile(
                        onTap: () {
                          widget.onLocationSelected(location['name']);
                        },
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: logoUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    logoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) {
                                      return Icon(
                                        location['icon'] ?? Icons.location_on,
                                        color: AppColors.error,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  location['icon'] ?? Icons.location_on,
                                  color: AppColors.error,
                                ),
                        ),
                        title: Text(
                          location['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          location['address'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Widget riêng cho Tag CLB
class _TagClubView extends StatefulWidget {
  final ScrollController scrollController;
  final Function(String clubName) onClubSelected;

  const _TagClubView({
    required this.scrollController,
    required this.onClubSelected,
  });

  @override
  State<_TagClubView> createState() => _TagClubViewState();
}

class _TagClubViewState extends State<_TagClubView> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _clubs = [];
  List<dynamic> _filteredClubs = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadClubs();
    _searchController.addListener(_filterClubs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final clubs = await ClubService.instance.getClubs(limit: 100);

      setState(() {
        _clubs = clubs;
        _filteredClubs = clubs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = UserFriendlyMessages.getErrorMessage(
          e,
          context: 'Tải danh sách CLB',
        );
        _isLoading = false;
      });
    }
  }

  void _filterClubs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClubs = _clubs;
      } else {
        _filteredClubs = _clubs.where((club) {
          final name = club.name?.toLowerCase() ?? '';
          final description = club.description?.toLowerCase() ?? '';
          return name.contains(query) || description.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.sports_basketball, color: AppColors.premium),
              const SizedBox(width: 8),
              const Text(
                'Tag CLB',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm CLB...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              filled: true,
              fillColor: AppColors.gray50,
            ),
          ),
          const SizedBox(height: 16),

          // Club list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Thử lại',
                              type: AppButtonType.primary,
                              size: AppButtonSize.medium,
                              onPressed: _loadClubs,
                            ),
                          ],
                        ),
                      )
                    : _filteredClubs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Không tìm thấy CLB nào',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: widget.scrollController,
                            itemCount: _filteredClubs.length,
                            itemBuilder: (context, index) {
                              final club = _filteredClubs[index];
                              return ListTile(
                                onTap: () {
                                  widget.onClubSelected(club.name ?? 'CLB');
                                },
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.premium
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: club.logoUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            club.logoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stack) {
                                              return const Icon(
                                                Icons.sports_basketball,
                                                color: AppColors.premium,
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(
                                          Icons.sports_basketball,
                                          color: AppColors.premium,
                                        ),
                                ),
                                title: Text(
                                  club.name ?? 'Unnamed Club',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: club.description != null
                                    ? Text(
                                        club.description!,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      )
                                    : null,
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
