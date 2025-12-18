import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:sabo_arena/widgets/common/common_widgets.dart'; // Phase 4

import '../../core/app_export.dart' hide AppTheme, AppColors;
import '../../core/device/device_info.dart';
// import '../../core/performance/performance_widgets.dart';
import '../../core/design_system/design_system.dart';
import '../../models/user_profile.dart';
// import '../../models/notification_models.dart';
import '../../models/user_social_stats.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/permission_service.dart';
import '../../services/share_service.dart';
import '../../services/club_service.dart';
import '../help_support_screen/help_support_screen.dart';
// import '../../services/notification_service.dart';
import '../../models/tournament.dart';
import '../../widgets/custom_app_bar.dart';
// Import FollowEventBroadcaster
import '../club_dashboard_screen/club_owner_main_screen.dart';
import '../club_registration_screen/club_registration_screen.dart';
import '../direct_messages_screen/direct_messages_screen.dart';
import '../notification_settings_screen.dart';
// import '../friends_list_screen/friends_list_screen.dart';
import '../../widgets/loading_state_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './widgets/edit_profile_modal.dart';
import './widgets/modern_profile_header_widget.dart';
import './widgets/profile_tab_navigation_widget.dart';
// import './widgets/tournament_card_widget.dart';
import './widgets/matches_section_widget.dart';
// import './widgets/profile_quick_actions_widget.dart';
import './widgets/qr_code_widget.dart';
import './widgets/user_posts_grid_widget.dart';
import './widgets/posts_sub_tab_navigation.dart';
import './widgets/tabs/user_profile_tournaments_tab.dart';
import '../user_voucher_screen/user_voucher_screen.dart';
import '../account_settings_screen/account_settings_screen.dart';
import './controller/user_profile_controller.dart';
// ELON_MODE_AUTO_FIX

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final UserProfileController _controller = UserProfileController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isRefreshing = false;

  // Temporary image states for immediate UI update
  String? _tempCoverPhotoPath;
  String? _tempAvatarPath;

  // Tab navigation state
  int _mainTabIndex = 0; // 0: Bài đăng, 1: Giải Đấu, 2: Trận Đấu, 3: Kết quả
  int _postsSubTabIndex = 0; // 0: Bài viết (All), 1: Hình ảnh (Images only), 2: Highlight (Videos)

  // Facade getters for backward compatibility
  UserProfile? get _userProfile => _controller.userProfile;
  UserSocialStats get _socialData => _controller.socialData;
  List<Tournament> get _tournaments => _controller.tournaments;
  bool get _hasClubManagementAccess => _controller.hasClubManagementAccess;
  int get _unreadMessageCount => _controller.unreadMessageCount;
  // int get _unreadNotificationCount => _controller.unreadNotificationCount;
  String get _currentTab => _controller.currentTab;
  bool get _isLoading => _controller.isLoading;
  
  // Services (kept for local usage if needed, but should prefer controller)
  final UserService _userService = UserService.instance;
  final AuthService _authService = AuthService.instance;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      String? userId;
      if (args is String) {
        userId = args;
      } else if (args is Map && args.containsKey('user_id')) {
        userId = args['user_id'] as String?;
      }
      
      _controller.init(userId: userId);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }
  
  // Legacy methods stubbed out or redirected to controller
  
  String _formatTournamentDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final weekdays = [
      'CN',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
    ];
    final weekday = weekdays[date.weekday % 7];
    return '$day/$month - $weekday';
  }

  String _formatPrizePool(double amount) {
    if (amount == 0) return 'Miễn phí';
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(0)} Triệu';
    }
    return '${(amount / 1000).toStringAsFixed(0)}K';
  }





  Future<void> _refreshProfile() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();
    await _controller.loadUserProfile();
    await _controller.loadUnreadMessageCount();
    await _controller.loadUnreadNotificationCount();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      AppSnackbar.success(
        context: context,
        message: '✅ Đã cập nhật thông tin profile',
      );
    }
  }

  void _navigateToMessaging() {
    // Navigate to Direct Messages (1-1 chat) instead of club messaging
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DirectMessagesScreen()),
    ).then((_) {
      // Refresh unread count when returning from messaging
      _controller.loadUnreadMessageCount();
    });
  }

  void _navigateToNotifications() {
    // Navigate to new NotificationListScreen
    Navigator.pushNamed(context, AppRoutes.notificationListScreen);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const LoadingStateWidget(message: 'Đang tải hồ sơ...'),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 80, color: AppColors.textSecondary),
              SizedBox(height: 2.h),
              Text(
                'Không thể tải hồ sơ', overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 1.h),
              Text(
                'Vui lòng đăng nhập hoặc thử lại.', overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 4.h),
              AppButton(
                label: 'Đăng nhập',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.loginScreen),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: Theme.of(context).colorScheme.primary,
        child: _buildResponsiveBody(),
      ),
    );
  }

  // 🎯 iPad: Responsive body with max-width constraint
  Widget _buildResponsiveBody() {
    final isIPad = DeviceInfo.isIPad(context);
    final maxWidth = isIPad ? 900.0 : double.infinity;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Modern Profile Header - Cover + Rank + 4 Metrics + Main Tabs
            SliverToBoxAdapter(
              child: ModernProfileHeaderWidget(
                userProfile: _userProfile!,
                userStats: _controller.userStats, // Assuming controller has userStats
                socialData: _socialData,
                tempAvatar: _tempAvatarPath,
                tempCoverPhoto: _tempCoverPhotoPath,
                onEditProfile: _showEditProfileModal,
                onAvatarTap: _changeAvatar,
                onCoverPhotoTap: _changeCoverPhoto,
                selectedTabIndex: _mainTabIndex,
                onTabChanged: (tabIndex) {
                  // Nếu là tab "Kết quả" (index 3), chuyển hướng tới LeaderboardScreen
                  if (tabIndex == 3) {
                    Navigator.pushNamed(context, AppRoutes.leaderboardScreen);
                    // Không cập nhật _mainTabIndex để giữ tab hiện tại
                    return;
                  }

                  setState(() {
                    _mainTabIndex = tabIndex;
                  });
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Content based on main tab (Bài đăng, Giải Đấu, Trận Đấu, hoặc Kết quả)
            if (_mainTabIndex == 0) ...[
              // Bài đăng tab - Sub-tabs Navigation
              SliverToBoxAdapter(
                child: PostsSubTabNavigation(
                  currentIndex: _postsSubTabIndex,
                  onTabChanged: (index) {
                    setState(() {
                      _postsSubTabIndex = index;
                    });
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Content based on posts sub-tab
              if (_userProfile != null) ...[
                if (_postsSubTabIndex == 0)
                  // Bài viết chữ (Text-only posts)
                  UserPostsGridWidget(
                    userId: _userProfile!.id,
                    filterType: PostFilterType.textOnly,
                  )
                else if (_postsSubTabIndex == 1)
                  // Hình ảnh (Posts with images only)
                  UserPostsGridWidget(
                    userId: _userProfile!.id,
                    filterType: PostFilterType.imagesOnly,
                  )
                else if (_postsSubTabIndex == 2)
                  // Highlight (Videos/YouTube links)
                  UserPostsGridWidget(
                    userId: _userProfile!.id,
                    filterType: PostFilterType.videosOnly,
                  ),
              ],
            ] else if (_mainTabIndex == 1) ...[
              // Giải Đấu tab - Tab Navigation - Ready, Live, Done (for tournaments)
              SliverToBoxAdapter(
                child: ProfileTabNavigationWidget(
                  currentTab: _currentTab,
                  onTabChanged: (tab) {
                    setState(() {
                      _controller.currentTab = tab;
                    });
                    _controller.loadTournaments(); // Reload tournaments when tab changes
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Tournament List based on current tab
              UserProfileTournamentsTab(
                tournaments: _getTournamentsForCurrentTab(),
                currentTab: _currentTab,
                onTournamentTap: _navigateToTournamentDetail,
                onShareTap: _shareTournament,
              ),
            ] else if (_mainTabIndex == 2) ...[
              // Trận Đấu tab - Matches Section with tabs
              SliverToBoxAdapter(
                child: MatchesSectionWidget(userId: _authService.currentUser?.id ?? ''),
              ),
            ] else if (_mainTabIndex == 3) ...[
              // Kết quả tab - No content needed as it navigates to LeaderboardScreen
              // But add a placeholder in case navigation fails
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Đang chuyển hướng tới bảng xếp hạng...',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          ],
        ),
      ),
      // 🎯 PHASE 1: Bottom navigation moved to PersistentTabScaffold
      // No bottomNavigationBar here to prevent duplicate navigation bars
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'Hồ sơ cá nhân',
      showBackButton: false,
      showNotificationBadge: true, // Tự động thêm notification badge mới ở cuối
      onNotificationTap: _navigateToNotifications,
      actions: [
        // Hiển thị nút chuyển sang giao diện club nếu:
        // 1. User có system role "clb" hoặc "club_owner" (chủ club)
        // 2. HOẶC user có club role là admin/moderator (quản lý club)
        if (_userProfile?.role == 'clb' || 
            _userProfile?.role == 'club_owner' ||
            _hasClubManagementAccess)
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: ElevatedButton.icon(
              onPressed: _switchToClubInterface,
              icon: Icon(Icons.sports_soccer, size: 16),
              label: Text(
                'CLB', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: AppColors.textOnPrimary,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        // Messaging button with badge
        Stack(
          children: [
            IconButton(
              onPressed: _navigateToMessaging,
              icon: Icon(
                Icons.message_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Tin nhắn',
            ),
            if (_unreadMessageCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    _unreadMessageCount > 99
                        ? '99+'
                        : _unreadMessageCount.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        // QR Code button
        IconButton(
          onPressed: _showQRCode,
          icon: CustomIconWidget(
            iconName: 'qr_code',
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: 'Mã QR',
        ),
        // More options button (màu xanh)
        IconButton(
          onPressed: _showMoreOptions,
          icon: CustomIconWidget(
            iconName: 'more_vert',
            color: Theme.of(context).colorScheme.primary,
          ), // Đổi sang màu xanh
          tooltip: 'Tùy chọn khác',
        ),
        // Notification badge tự động thêm ở đây bởi CustomAppBar
      ],
    );
  }

  void _showEditProfileModal() {
    if (_userProfile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(
        userProfile: _userProfile!,
        onSave: (updatedProfile, avatarBytes, avatarName, removeAvatar) async {
          try {
            // 🚀 MUSK: Atomic update via UserService
            final newProfile = await _userService.updateProfileWithAvatarUpload(
              fullName: updatedProfile.fullName,
              displayName: updatedProfile.displayName,
              bio: updatedProfile.bio,
              phone: updatedProfile.phone,
              location: updatedProfile.location,
              avatarBytes: avatarBytes,
              avatarFileName: avatarName,
              removeAvatar: removeAvatar,
            );

            // Refresh local data directly to avoid replica lag
            _controller.updateUserProfile(newProfile);

            if (!context.mounted) return;
            
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
            // ignore: use_build_context_synchronously
            AppSnackbar.success(
              context: context,
              message: '✅ Cập nhật hồ sơ thành công',
            );
          } catch (e) {
            if (!context.mounted) return;
            
            // ignore: use_build_context_synchronously
            AppSnackbar.error(
              context: context,
              message: '❌ Lỗi cập nhật hồ sơ: $e',
            );
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _changeCoverPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Thay đổi ảnh bìa', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Chụp ảnh',
                  onTap: () {
                    Navigator.pop(context);
                    _pickCoverPhotoFromCamera();
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Chọn ảnh',
                  onTap: () {
                    Navigator.pop(context);
                    _pickCoverPhotoFromGallery();
                  },
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

  void _changeAvatar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Thay đổi ảnh đại diện', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Chụp ảnh',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAvatarFromCamera();
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Chọn ảnh',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAvatarFromGallery();
                  },
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

  // 🚀 MUSK: Unified image picker and uploader
  Future<void> _pickAndUpload({
    required ImageSource source,
    required bool isAvatar,
  }) async {
    Navigator.pop(context); // Close bottom sheet

    try {
      // Check permissions
      if (source == ImageSource.camera) {
        if (!await PermissionService.checkCameraPermission()) {
          _showErrorMessage('Cần cấp quyền camera để chụp ảnh');
          return;
        }
      } else {
        if (!await PermissionService.checkPhotosPermission()) {
          _showPermissionDialog();
          return;
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: isAvatar ? 1024 : 1200,
        maxHeight: isAvatar ? 1024 : 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isAvatar) {
            _tempAvatarPath = image.path;
          } else {
            _tempCoverPhotoPath = image.path;
          }
        });
        
        if (isAvatar) {
          await _uploadAvatar(image);
        } else {
          await _uploadCoverPhoto(image);
        }
      }
    } catch (e) {
      _showErrorMessage('Lỗi khi chọn ảnh: $e');
    }
  }

  // Cover Photo Functions
  void _pickCoverPhotoFromCamera() => _pickAndUpload(source: ImageSource.camera, isAvatar: false);
  void _pickCoverPhotoFromGallery() => _pickAndUpload(source: ImageSource.gallery, isAvatar: false);

  // Avatar Functions
  void _pickAvatarFromCamera() => _pickAndUpload(source: ImageSource.camera, isAvatar: true);
  void _pickAvatarFromGallery() => _pickAndUpload(source: ImageSource.gallery, isAvatar: true);

  // ignore: unused_element
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
            customColor: AppColors.error,
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _tempAvatarPath = null;
              });
              _showSuccessMessage('✅ Đã xóa ảnh đại diện');
              _removeAvatarFromServer();
            },
          ),
        ],
      ),
    );
  }

  // Upload functions
  Future<void> _uploadCoverPhoto(XFile image) async {
    try {
      // 🚀 MUSK: Atomic operation handled by service
      final oldCoverUrl = _userProfile?.coverPhotoUrl ?? '';
      final bytes = await image.readAsBytes();
      
      final newCoverUrl = await _userService.uploadCoverPhoto(
        bytes,
        oldUrl: oldCoverUrl,
        fileName: image.name,
      );

      if (newCoverUrl != null) {
        // Update local state with new URL
        setState(() {
          _tempCoverPhotoPath = null; // Clear temp path
          if (_controller.userProfile != null) {
            _controller.updateUserProfile(_controller.userProfile!.copyWith(coverPhotoUrl: newCoverUrl));
          }
        });

        _showSuccessMessage('✅ Ảnh bìa đã được lưu thành công!');
      } else {
        _showErrorMessage('❌ Không thể tải lên ảnh bìa. Vui lòng thử lại.');
      }
    } catch (e) {
      _showErrorMessage('Lỗi khi tải ảnh bìa: $e');
    }
  }

  Future<void> _uploadAvatar(XFile image) async {
    try {
      // 🚀 MUSK: Atomic operation handled by service
      final oldAvatarUrl = _userProfile?.avatarUrl ?? '';
      final bytes = await image.readAsBytes();

      final newAvatarUrl = await _userService.uploadAvatar(
        bytes,
        oldUrl: oldAvatarUrl,
        fileName: image.name,
      );

      if (newAvatarUrl != null) {
        // Update local state with new URL
        setState(() {
          _tempAvatarPath = null; // Clear temp path
          if (_userProfile != null) {
            _controller.updateUserProfile(_controller.userProfile!.copyWith(avatarUrl: newAvatarUrl));
          }
        });

        _showSuccessMessage('✅ Ảnh đại diện đã được lưu thành công!');
      } else {
        _showErrorMessage(
          '❌ Không thể tải lên ảnh đại diện. Vui lòng thử lại.',
        );
      }
    } catch (e) {
      _showErrorMessage('Lỗi khi tải ảnh đại diện: $e');
    }
  }

  Future<void> _removeAvatarFromServer() async {
    try {
      // 🚀 MUSK: Atomic removal via service
      await _userService.removeAvatar();

      // Update local state
      setState(() {
        _tempAvatarPath = null;
        if (_userProfile != null) {
          _controller.userProfile = _controller.userProfile!.copyWith(avatarUrl: null);
        }
      });

      _showSuccessMessage('✅ Đã xóa ảnh đại diện');
    } catch (e) {
      _showErrorMessage('Lỗi khi xóa ảnh đại diện: $e');
    }
  }

  void _showSuccessMessage(String message) {
    AppSnackbar.success(
      context: context,
      message: message,
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cần cấp quyền truy cập'),
          content: const Text(
            'Ứng dụng cần quyền truy cập thư viện ảnh để bạn có thể chọn ảnh.\n\n'
            'Vui lòng vào:\n'
            'Cài đặt > Ứng dụng > SABO Arena > Quyền\n'
            'và bật quyền "Ảnh"',
          ),
          actions: [
            AppButton(
              label: 'Hủy',
              type: AppButtonType.text,
              onPressed: () => Navigator.pop(context),
            ),
            AppButton(
              label: 'Mở cài đặt',
              onPressed: () {
                Navigator.pop(context);
                PermissionService.openDeviceAppSettings(); // Mở cài đặt ứng dụng
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    AppSnackbar.error(
      context: context,
      message: message,
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
              color: (color ?? AppColors.success).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? AppColors.success, size: 30),
          ),
          SizedBox(height: DesignTokens.space8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _switchToClubInterface() async {
    // Check nếu user có quyền truy cập:
    // 1. System role là 'clb' hoặc 'club_owner'
    // 2. HOẶC có club management access (admin/moderator)
    if (_userProfile?.role != 'clb' && 
        _userProfile?.role != 'club_owner' &&
        !_hasClubManagementAccess) {
      _showErrorMessage('Bạn không có quyền truy cập giao diện club');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Tìm club đầu tiên mà user sở hữu hoặc là member
      final club = await ClubService.instance.getFirstClubForUser(
        _userProfile!.id,
      );

      if (!context.mounted) return;

      // Close loading dialog
      // ignore: use_build_context_synchronously
      Navigator.pop(context);

      if (club == null) {
        // Show club creation options for club owner without clubs
        // ignore: use_build_context_synchronously
        _showClubCreationOptions();
        return;
      }

      if (!mounted) return;

      // Navigate to club dashboard with clubId
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClubOwnerMainScreen(clubId: club.id),
        ),
      );
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        _showErrorMessage('Lỗi khi tải thông tin club: $e');
      }
    }
  }

  void _showQRCode() {
    if (_userProfile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QRCodeWidget(
        userData: _userProfile!.toJson(),
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _shareProfile() async {
    if (_userProfile == null) return;

    try {
      // Use rich share with image (4:5 ratio for social media)
      final result = await ShareService.shareUserProfileRich(
        _userProfile!,
        context: context,
      );
      
      if (result != null && mounted) {
        AppSnackbar.success(
          context: context,
          message: '✅ Đã chia sẻ hồ sơ thành công!',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context: context,
          message: 'Lỗi chia sẻ hồ sơ: $e',
        );
      }
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 24), // Spacer for centering
                  Flexible(
                    child: Text(
                      'Tùy chọn', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Share & Copy Section
                    _buildOptionItem(
                      icon: Icons.share,
                      title: 'Chia sẻ hồ sơ',
                      subtitle: 'Chia sẻ hồ sơ của bạn với bạn bè',
                      onTap: () {
                        Navigator.pop(context);
                        _shareProfile();
                      },
                    ),
                    _buildOptionItem(
                      icon: Icons.copy,
                      title: 'Sao chép liên kết',
                      subtitle: 'Sao chép đường dẫn đến hồ sơ',
                      onTap: () {
                        Navigator.pop(context);
                        _copyProfileLink();
                      },
                    ),

                    Divider(height: 30),

                    // Settings Section
                    _buildOptionItem(
                      icon: Icons.person,
                      title: 'Tài khoản',
                      subtitle: 'Thông tin cá nhân, bảo mật',
                      onTap: () {
                        Navigator.pop(context);
                        _openAccountSettings();
                      },
                    ),
                    _buildOptionItem(
                      icon: Icons.notifications,
                      title: 'Thông báo',
                      subtitle: 'Cài đặt thông báo push',
                      onTap: () {
                        Navigator.pop(context);
                        _openNotificationSettings();
                      },
                    ),
                    _buildOptionItem(
                      icon: Icons.local_offer,
                      title: 'Voucher & Thành tựu',
                      subtitle: 'Voucher khuyến mãi và thành tựu cá nhân',
                      onTap: () {
                        Navigator.pop(context);
                        _openVoucherScreen();
                      },
                      iconColor: AppColors.error,
                    ),
                    _buildOptionItem(
                      icon: Icons.wallpaper_outlined,
                      title: 'Background bài đăng',
                      subtitle: 'Tùy chỉnh background cho posts không ảnh',
                      onTap: () {
                        Navigator.pop(context);
                        _openPostBackgroundSettings();
                      },
                      iconColor: AppColors.success,
                    ),
                    _buildOptionItem(
                      icon: Icons.storage_rounded,
                      title: 'Quản lý bộ nhớ',
                      subtitle: 'Xem và xóa dữ liệu cache',
                      onTap: () {
                        Navigator.pop(context);
                        _openCacheManagement();
                      },
                      iconColor: AppColors.premium,
                    ),
                    _buildOptionItem(
                      icon: Icons.language,
                      title: 'Ngôn ngữ',
                      subtitle: 'Tiếng Việt, English',
                      onTap: () {
                        Navigator.pop(context);
                        _openLanguageSettings();
                      },
                    ),
                    _buildOptionItem(
                      icon: Icons.help,
                      title: 'Trợ giúp & Hỗ trợ',
                      subtitle: 'FAQ, liên hệ',
                      onTap: () {
                        Navigator.pop(context);
                        _openHelpSupport();
                      },
                    ),
                    _buildOptionItem(
                      icon: Icons.star_rate,
                      title: 'Đánh giá ứng dụng',
                      subtitle: 'Đánh giá 5 sao trên App Store/Play Store',
                      onTap: () {
                        Navigator.pop(context);
                        _rateApp();
                      },
                      iconColor: AppColors.warning,
                    ),
                    _buildOptionItem(
                      icon: Icons.share,
                      title: 'Chia sẻ ứng dụng',
                      subtitle: 'Mời bạn bè cùng sử dụng',
                      onTap: () {
                        Navigator.pop(context);
                        _shareApp();
                      },
                      iconColor: AppColors.success,
                    ),
                    _buildOptionItem(
                      icon: Icons.bug_report,
                      title: 'Báo lỗi',
                      subtitle: 'Gửi báo cáo lỗi cho đội ngũ phát triển',
                      onTap: () {
                        Navigator.pop(context);
                        _reportBug();
                      },
                      iconColor: AppColors.error,
                    ),
                    _buildOptionItem(
                      icon: Icons.info_outline,
                      title: 'Về ứng dụng',
                      subtitle: 'Phiên bản, điều khoản, chính sách',
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog();
                      },
                    ),

                    // Show Club options if user is club owner
                    if (_userProfile?.role == 'club_owner') ...[
                      _buildOptionItem(
                        icon: Icons.add_business,
                        title: 'Đăng ký CLB',
                        subtitle: 'Tạo câu lạc bộ mới',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToClubRegistration();
                        },
                      ),
                      _buildOptionItem(
                        icon: Icons.business,
                        title: 'Quản lý CLB',
                        subtitle: 'Điều hành câu lạc bộ',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToClubManagement();
                        },
                      ),
                      _buildOptionItem(
                        icon: Icons.campaign,
                        title: 'Voucher Campaign',
                        subtitle: 'Đăng ký campaign voucher cho CLB',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToVoucherManagement();
                        },
                        iconColor: AppColors.premium,
                      ),
                    ],

                    // Show Admin options if user is admin
                    if (_userProfile?.role == 'admin' ||
                        _userProfile?.role == 'super_admin') ...[
                      Divider(height: 30),
                      _buildOptionItem(
                        icon: Icons.admin_panel_settings,
                        title: 'Admin Dashboard',
                        subtitle: 'Quản trị hệ thống',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToAdminDashboard();
                        },
                        iconColor: AppColors.error,
                      ),
                      _buildOptionItem(
                        icon: Icons.card_giftcard,
                        title: 'Admin Voucher',
                        subtitle: 'Quản lý campaign voucher toàn hệ thống',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToAdminVoucherDashboard();
                        },
                        iconColor: AppColors.warning,
                      ),
                    ],

                    Divider(height: 30),

                    // Logout
                    _buildOptionItem(
                      icon: Icons.logout,
                      title: 'Đăng xuất',
                      subtitle: 'Thoát tài khoản hiện tại',
                      onTap: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                      isDestructive: true,
                    ),

                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    final effectiveIconColor = isDestructive
        ? AppColors.error
        : (iconColor ?? AppColors.primary);
    final effectiveTitleColor = isDestructive ? AppColors.error : null;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveIconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: effectiveIconColor, size: 20),
      ),
      title: Text(
        title, style: TextStyle(
          fontWeight: FontWeight.w600,
          color: effectiveTitleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _copyProfileLink() {
    // In a real app, you would use Clipboard.setData()
    // Clipboard.setData(ClipboardData(text: 'https://saboarena.com/profile/${_userProfile?.id}'));
    AppSnackbar.success(
      context: context,
      message: 'Đã sao chép liên kết hồ sơ',
    );
  }

  /*
  void _viewAllAchievements() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAchievementsModal(),
    );
  }

  Widget _buildAchievementsModal() {
    // Mock data for achievements
    final achievements = [
      {
        'title': 'Người mới',
        'description': 'Hoàn thành 5 trận đấu đầu tiên',
        'icon': '🏆',
        'completed': true,
      },
      {
        'title': 'Chiến thắng đầu tiên',
        'description': 'Thắng trận đấu đầu tiên',
        'icon': '🥇',
        'completed': true,
      },
      {
        'title': 'Streak Master',
        'description': 'Thắng liên tiếp 5 trận',
        'icon': '🔥',
        'completed': true,
      },
      {
        'title': 'Tournament Player',
        'description': 'Tham gia 10 giải đấu',
        'icon': '🏟️',
        'completed': false,
      },
      {
        'title': 'Social Player',
        'description': 'Kết bạn với 50 người chơi',
        'icon': '👥',
        'completed': false,
      },
      {
        'title': 'Champion',
        'description': 'Thắng một giải đấu',
        'icon': '👑',
        'completed': false,
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.emoji_events, color: AppColors.warning, size: 24),
                Text(
                  'Thành tích của tôi', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Achievements List
          Expanded(
            child: OptimizedListView(
              padding: EdgeInsets.all(16),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final isCompleted = achievement['completed'] as bool;

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success50
                        : AppColors.gray100,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.success100
                          : AppColors.gray300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success100
                              : AppColors.gray200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            achievement['icon'] as String,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      SizedBox(width: DesignTokens.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement['title'] as String,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? AppColors.success700
                                    : AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: DesignTokens.space4),
                            Text(
                              achievement['description'] as String,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isCompleted
                                    ? AppColors.success600
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCompleted)
                        Icon(Icons.check_circle, color: AppColors.success, size: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _viewFriendsList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendsListScreen(initialTab: 0)),
    );
  }

  void _viewRecentChallenges() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChallengesHistoryModal(),
    );
  }

  void _viewTournamentHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTournamentHistoryModal(),
    );
  }
  */

  /*
  Widget _buildChallengesHistoryModal() {
    // Mock data for challenges
    final challenges = List.generate(
      10,
      (index) => {
        'id': 'challenge_$index',
        'opponent': 'Đối thủ ${index + 1}',
        'result': index % 3 == 0 ? 'won' : (index % 3 == 1 ? 'lost' : 'draw'),
        'score': '${(index % 3) + 1}-${(index % 2) + 1}',
        'date': DateTime.now().subtract(Duration(days: index)),
        'duration': '${15 + (index * 2)} phút',
      },
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.sports_esports, color: AppColors.accent, size: 24),
                Text(
                  'Lịch sử thách đấu', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Statistics
          Container(
            padding: EdgeInsets.all(16),
            color: AppColors.gray50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  'Thắng',
                  challenges
                      .where((c) => c['result'] == 'won')
                      .length
                      .toString(),
                  AppColors.success,
                ),
                _buildStatItem(
                  'Hòa',
                  challenges
                      .where((c) => c['result'] == 'draw')
                      .length
                      .toString(),
                  AppColors.warning,
                ),
                _buildStatItem(
                  'Thua',
                  challenges
                      .where((c) => c['result'] == 'lost')
                      .length
                      .toString(),
                  AppColors.error,
                ),
              ],
            ),
          ),

          // Challenges List
          Expanded(
            child: OptimizedListView(
              padding: EdgeInsets.all(16),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                final result = challenge['result'] as String;
                final date = challenge['date'] as DateTime;

                Color resultColor = result == 'won'
                    ? AppColors.success
                    : result == 'lost'
                    ? AppColors.error
                    : AppColors.warning;
                IconData resultIcon = result == 'won'
                    ? Icons.trending_up
                    : result == 'lost'
                    ? Icons.trending_down
                    : Icons.trending_flat;

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: resultColor.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: resultColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(resultIcon, color: resultColor, size: 20),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'vs ${challenge['opponent']}', overflow: TextOverflow.ellipsis, style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tỷ số: ${challenge['score']} • ${challenge['duration']}', overflow: TextOverflow.ellipsis, style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${date.day}/${date.month}/${date.year}', overflow: TextOverflow.ellipsis, style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: resultColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          result == 'won'
                              ? 'Thắng'
                              : result == 'lost'
                              ? 'Thua'
                              : 'Hòa', overflow: TextOverflow.ellipsis, style: TextStyle(
                            color: resultColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  */

  /*
  Widget _buildTournamentHistoryModal() {
    // Mock data for tournaments
    final tournaments = List.generate(
      8,
      (index) => {
        'id': 'tournament_$index',
        'name': 'Giải đấu ${index + 1}',
        'position': index % 4 + 1,
        'participants': (index + 1) * 8,
        'date': DateTime.now().subtract(Duration(days: index * 7)),
        'prize': index == 0
            ? '1.000.000 VND'
            : index == 1
            ? '500.000 VND'
            : index == 2
            ? '250.000 VND'
            : null,
      },
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.emoji_events, color: AppColors.warning, size: 24),
                Text(
                  'Lịch sử giải đấu', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Tournaments List
          Expanded(
            child: OptimizedListView(
              padding: EdgeInsets.all(16),
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                final tournament = tournaments[index];
                final position = tournament['position'] as int;
                final date = tournament['date'] as DateTime;
                final prize = tournament['prize'] as String?;

                Color positionColor = position == 1
                    ? AppColors.warning
                    : position == 2
                    ? AppColors.gray500
                    : (position == 3 || position == 4)
                    ? AppColors.gray700
                    : AppColors.gray400;
                IconData positionIcon = position <= 4
                    ? Icons.emoji_events
                    : Icons.sports_esports;

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: positionColor.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: positionColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(positionIcon, color: positionColor, size: 20),
                            Text(
                              '#$position', overflow: TextOverflow.ellipsis, style: TextStyle(
                                color: positionColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tournament['name'] as String, style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${tournament['participants']} người tham gia', overflow: TextOverflow.ellipsis, style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${date.day}/${date.month}/${date.year}', overflow: TextOverflow.ellipsis, style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            if (prize != null)
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Giải thưởng: $prize', overflow: TextOverflow.ellipsis, style: TextStyle(
                                    color: AppColors.success700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  */

  /*
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value, style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
  */

  void _openAccountSettings() {
    if (_userProfile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountSettingsScreen(
          userProfile: _userProfile!,
        ),
      ),
    ).then((shouldRefresh) {
      // If settings were saved, refresh the profile
      if (shouldRefresh == true) {
        _refreshProfile();
      }
    });
  }

  void _openNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void _openVoucherScreen() {
    if (_userProfile?.id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserVoucherScreen(userId: _userProfile!.id),
      ),
    );
  }

  // ==================== VOUCHER MANAGEMENT NAVIGATION ====================

  void _navigateToVoucherManagement() {
    if (_userProfile?.id == null) return;

    Navigator.pushNamed(
      context,
      AppRoutes.voucherManagementMainScreen,
      arguments: {
        'userId': _userProfile!.id,
        'clubId': _userProfile!.id, // Use user ID as club association
        'isAdmin': false,
      },
    );
  }

  void _navigateToAdminDashboard() {
    Navigator.pushNamed(context, AppRoutes.adminDashboardScreen);
  }

  void _navigateToAdminVoucherDashboard() {
    Navigator.pushNamed(context, AppRoutes.voucherManagementMainScreen);
  }

  void _openPostBackgroundSettings() {
    Navigator.pushNamed(context, '/post_background_settings');
  }

  void _openCacheManagement() {
    Navigator.pushNamed(context, '/cache_management');
  }

  void _openLanguageSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildLanguageSelector(),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 40, height: 40),
            const SizedBox(width: 12),
            const Text('Sabo Arena'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ứng dụng quản lý giải đấu Billiards chuyên nghiệp', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Phiên bản', '1.0.3 (20)'),
            _buildInfoRow('Build', 'Production'),
            _buildInfoRow('Cập nhật', 'October 2025'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                // TODO: Open privacy policy URL
                AppSnackbar.info(
                  context: context,
                  message: 'Chính sách bảo mật sẽ được bổ sung',
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Chính sách bảo mật', overflow: TextOverflow.ellipsis, style: TextStyle(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                // TODO: Open terms URL
                AppSnackbar.info(
                  context: context,
                  message: 'Điều khoản sử dụng sẽ được bổ sung',
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Điều khoản sử dụng', overflow: TextOverflow.ellipsis, style: TextStyle(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '© 2025 Sabo Arena. All rights reserved.', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          AppButton(
            label: 'Đóng',
            type: AppButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(
            value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ==================== RATE APP ====================

  void _rateApp() async {
    try {
      String appUrl;
      if (Platform.isIOS) {
        // TODO: Replace with actual App Store ID after app submission
        appUrl = 'https://apps.apple.com/app/id123456789';
      } else if (Platform.isAndroid) {
        appUrl =
            'https://play.google.com/store/apps/details?id=com.saboarena.app';
      } else {
        AppSnackbar.info(
          context: context,
          message: 'Tính năng chỉ khả dụng trên iOS và Android',
        );
        return;
      }

      final uri = Uri.parse(appUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $appUrl';
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context: context,
          message: 'Không thể mở store: $e',
        );
      }
    }
  }

  // ==================== SHARE APP ====================

  void _shareApp() {
    final String shareText;
    if (Platform.isIOS) {
      shareText =
          'Tải Sabo Arena - Ứng dụng quản lý giải đấu Billiards chuyên nghiệp!\n\n'
          'iOS: https://apps.apple.com/app/id123456789\n'
          'Android: https://play.google.com/store/apps/details?id=com.saboarena.app';
    } else {
      shareText =
          'Tải Sabo Arena - Ứng dụng quản lý giải đấu Billiards chuyên nghiệp!\n\n'
          'https://play.google.com/store/apps/details?id=com.saboarena.app';
    }

    share_plus.Share.share(
      shareText,
      subject: 'Sabo Arena - Billiards Tournament Management',
    );
  }

  // ==================== REPORT BUG ====================

  void _reportBug() async {
    try {
      final String subject = Uri.encodeComponent('Báo lỗi Sabo Arena v1.0.3');
      final String body = Uri.encodeComponent(
        'Xin chào đội ngũ Sabo Arena,\n\n'
        'Tôi gặp vấn đề sau:\n\n'
        '[Mô tả vấn đề của bạn ở đây]\n\n'
        '---\n'
        'Thông tin thiết bị:\n'
        '- Platform: ${Platform.operatingSystem}\n'
        '- Version: ${Platform.operatingSystemVersion}\n'
        '- App Version: 1.0.3 (20)\n'
        '- User ID: ${_userProfile?.id ?? "N/A"}\n',
      );

      final String mailtoUrl =
          'mailto:support@saboarena.com?subject=$subject&body=$body';
      final uri = Uri.parse(mailtoUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: Show contact dialog
        _showContactDialog();
      }
    } catch (e) {
      _showContactDialog();
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liên hệ hỗ trợ'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@saboarena.com'),
            SizedBox(height: 8),
            Text('Hotline: 1900-xxxx'),
            SizedBox(height: 16),
            Text(
              'Vui lòng gửi email mô tả chi tiết vấn đề bạn gặp phải.', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          AppButton(
            label: 'Đóng',
            type: AppButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _navigateToClubManagement() async {
    try {
      // Get current user ID
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) {
        AppSnackbar.warning(
          context: context,
          message: 'Vui lòng đăng nhập lại',
        );
        return;
      }

      // Find club owned by current user
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('clubs')
          .select('id, name')
          .eq('owner_id', currentUserId)
          .eq('approval_status', 'approved')
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        AppSnackbar.info(
          context: context,
          message: 'Bạn chưa có club nào được phê duyệt',
        );
        return;
      }

      // Navigate with actual club ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClubOwnerMainScreen(clubId: response['id']),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context: context,
          message: 'Lỗi: $e',
        );
      }
    }
  }

  void _openHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpSupportScreen(),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final languages = [
      {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
      {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
      {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    ];

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chọn ngôn ngữ', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ...languages.map(
            (lang) => ListTile(
              leading: Text(lang['flag']!, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 24)),
              title: Text(lang['name']!),
              trailing: lang['code'] == 'vi'
                  ? Icon(Icons.check, color: AppColors.success)
                  : null,
              onTap: () {
                Navigator.pop(context);
                AppSnackbar.success(
                  context: context,
                  message: '✅ Đã chuyển sang ${lang['name']}',
                );
              },
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  void _handleLogout() async {
    HapticFeedback.mediumImpact();
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.loginScreen,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context: context,
          message: 'Lỗi đăng xuất: $e',
        );
      }
    }
  }

  /*
  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationsModal(),
    );
  }
  */

  /*
  Widget _buildNotificationsModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Modern Header - Facebook 2025 Style
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Thông báo', overflow: TextOverflow.ellipsis, style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_unreadNotificationCount > 0)
                      AppButton(
                        label: 'Đánh dấu tất cả',
                        type: AppButtonType.text,
                        size: AppButtonSize.small,
                        onPressed: _markAllNotificationsAsRead,
                      ),
                    SizedBox(width: 4),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: FutureBuilder<List<NotificationModel>>(
              future: NotificationService.instance.getUserNotifications(limit: 50),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Lỗi tải thông báo', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Vui lòng thử lại sau', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có thông báo', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Thông báo mới sẽ hiển thị ở đây', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return OptimizedListView(
                  padding: EdgeInsets.zero,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final isRead = notification.isRead;
    final type = notification.type.value;
    final createdAt = notification.createdAt;
    final timeAgo = _getTimeAgo(createdAt);

    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'tournament_invitation':
        iconData = Icons.emoji_events;
        iconColor = AppColors.warning;
        break;
      case 'match_result':
        iconData = Icons.sports_soccer;
        iconColor = AppColors.success;
        break;
      case 'club_announcement':
        iconData = Icons.business;
        iconColor = AppColors.primary;
        break;
      case 'rank_update':
        iconData = Icons.trending_up;
        iconColor = AppColors.premium;
        break;
      case 'friend_request':
        iconData = Icons.person_add;
        iconColor = AppColors.primary;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.textSecondary;
    }

    return Material(
      color: isRead ? AppColors.surface : AppColors.info50,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      notification.body,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 4),
                    Text(
                      timeAgo, style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread indicator or more button
              if (!isRead)
                Container(
                  margin: EdgeInsets.only(left: 8, top: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
  */

  /*
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read if not already read
    if (!notification.isRead) {
      NotificationService.instance.markNotificationAsRead(notification.id);
      // Reload unread count from controller
      _controller.loadUnreadNotificationCount();
      setState(() {});
    }

    // Handle different notification types
    final type = notification.type.value;
    final actionData = notification.data;

    switch (type) {
      case 'tournament_invitation':
        // Navigate to tournament details
        if (actionData['tournament_id'] != null) {
          Navigator.pop(context); // Close modal
          Navigator.pushNamed(
            context,
            AppRoutes.tournamentDetailScreen,
            arguments: actionData['tournament_id'],
          );
        }
        break;
      case 'match_result':
        // Navigate to match details
        AppSnackbar.info(
          context: context,
          message: 'Xem chi tiết kết quả trận đấu',
        );
        break;
      case 'club_announcement':
        // Navigate to club screen
        Navigator.pop(context); // Close modal
        Navigator.pushNamed(context, AppRoutes.clubMainScreen);
        break;
      default:
        AppSnackbar.info(
          context: context,
          message: 'Đã xem thông báo: ${notification.title}',
        );
    }
  }

  void _markAllNotificationsAsRead() async {
    try {
      await NotificationService.instance.markAllNotificationsAsRead();
      // Reload unread count from controller
      await _controller.loadUnreadNotificationCount();
      if (!mounted) return;
      setState(() {});
      Navigator.pop(context); // Close modal
      AppSnackbar.success(
        context: context,
        message: '✅ Đã đánh dấu tất cả thông báo là đã đọc',
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context: context,
          message: '❌ Lỗi đánh dấu thông báo: $e',
        );
      }
    }
  }
  */

  void _showClubCreationOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.sports_soccer,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Quản lý CLB', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn chưa có câu lạc bộ nào để quản lý.', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, height: 1.4),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppColors.success50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tạo CLB mới:', overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success700,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '🏢 Đăng ký thông tin CLB của bạn\n'
                    '⏳ Chờ admin phê duyệt (24-48 giờ)\n'
                    '🎯 Bắt đầu quản lý và tổ chức giải đấu\n'
                    '👥 Thu hút thành viên và người chơi',
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.5,
                      color: AppColors.success700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          AppButton(
            label: 'Đóng',
            type: AppButtonType.text,
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppButton(
            label: 'Đăng ký CLB',
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClubRegistrationScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToClubRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClubRegistrationScreen()),
    );
  }

  void _navigateToTournamentDetail(
    String tournamentId, {
    bool showResults = false,
  }) {
    Navigator.of(context).pushNamed(
      AppRoutes.tournamentDetailScreen,
      arguments: {'tournamentId': tournamentId, 'showResults': showResults},
    );
  }

  Future<void> _shareTournament(dynamic tournamentData) async {
    try {
      String tournamentId;
      String tournamentName;
      String date;
      String playersCount;
      String prizePool;
      String format;
      String status;

      if (tournamentData is Tournament) {
        tournamentId = tournamentData.id;
        tournamentName = tournamentData.title;
        date = _formatTournamentDate(tournamentData.startDate);
        playersCount = '${tournamentData.currentParticipants}/${tournamentData.maxParticipants}';
        prizePool = _formatPrizePool(tournamentData.prizePool);
        format = tournamentData.format;
        status = tournamentData.status;
      } else {
        final tournament = tournamentData as Map<String, dynamic>;
        tournamentId = tournament['id'] as String? ?? '';
        tournamentName = tournament['name'] as String? ?? 'Tournament';
        date = tournament['date'] as String? ?? '';
        playersCount = tournament['playersCount'] as String? ?? '0';
        prizePool = tournament['prizePool'] as String? ?? '0';
        format = tournament['format'] as String? ?? 'Single Elimination';
        status = tournament['status'] as String? ?? 'upcoming';
      }
      
      // Extract participant count from "16/32" format
      final participants = playersCount.split('/').first;
      
      // Use rich share with 4:5 image card
      await ShareService.shareTournamentRich(
        tournamentId: tournamentId,
        tournamentName: tournamentName,
        startDate: date,
        participants: int.tryParse(participants) ?? 0,
        prizePool: prizePool,
        format: format,
        status: status,
        context: context,
      );
      
      if (mounted) {
        AppSnackbar.success(
          context: context,
          message: '✅ Đã chia sẻ giải đấu!',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context: context,
          message: 'Không thể chia sẻ: $e',
        );
      }
    }
  }

  // Helper method to get tournaments for current tab (now using real data)
  List<Tournament> _getTournamentsForCurrentTab() {
    // Filter based on _currentTab
    return _tournaments.where((t) {
      if (_currentTab == 'ready') return t.status == 'upcoming' || t.status == 'ready';
      if (_currentTab == 'live') return t.status == 'active' || t.status == 'live' || t.status == 'in_progress';
      if (_currentTab == 'done') return t.status == 'completed' || t.status == 'ended' || t.status == 'done';
      return true;
    }).toList();
  }


}

