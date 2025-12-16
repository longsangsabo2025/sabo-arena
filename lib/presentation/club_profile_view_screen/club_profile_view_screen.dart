import 'package:flutter/material.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import 'package:sabo_arena/theme/app_colors_styles.dart' as styles;
import '../home_feed_screen/widgets/create_post_modal_widget.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class ClubProfileViewScreen extends StatefulWidget {
  final String? clubId; // 🎱 Club ID for posting

  const ClubProfileViewScreen({super.key, this.clubId});

  @override
  _ClubProfileViewScreenState createState() => _ClubProfileViewScreenState();
}

class _ClubProfileViewScreenState extends State<ClubProfileViewScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _coverAnimation;
  late Animation<double> _contentAnimation;
  late ScrollController _scrollController;

  bool _showAppBarTitle = false;
  final double _coverHeight = 280.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _coverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _controller.forward();
  }

  void _onScroll() {
    final shouldShowTitle = _scrollController.offset > _coverHeight - 100;
    if (shouldShowTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = shouldShowTitle;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: styles.appTheme.gray50,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _contentAnimation.value)),
                  child: Opacity(
                    opacity: _contentAnimation.value,
                    child: Column(
                      children: [
                        _buildBasicInfoSection(),
                        _buildStatsSection(),
                        _buildContactInfoSection(),
                        _buildBusinessInfoSection(),
                        _buildFacilitiesSection(),
                        _buildGallerySection(),
                        _buildLocationSection(),
                        SizedBox(height: 100.v),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: _coverHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      title: AnimatedOpacity(
        opacity: _showAppBarTitle ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16.h,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=100&h=100&fit=crop',
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "SABO Arena Central", overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.bold,
                      color: styles.appTheme.gray900,
                    ),
                  ),
                  Text(
                    "@saboarena_central", overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 12.fSize,
                      color: styles.appTheme.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // 📚 Help icon - Hướng dẫn sử dụng
        IconButton(
          icon: Icon(Icons.help_outline, color: const Color(0xFF8B5CF6)),
          tooltip: 'Hướng dẫn đăng bài',
          onPressed: _showPostingGuide,
        ),
        IconButton(
          icon: Icon(Icons.share_outlined, color: styles.appTheme.gray700),
          onPressed: _onSharePressed,
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: styles.appTheme.gray700),
          onPressed: _onMorePressed,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _coverAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * _coverAnimation.value),
              child: Opacity(
                opacity: _coverAnimation.value,
                child: _buildCoverSection(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCoverSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cover Image
        CustomImageWidget(
          imageUrl:
              'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=400&fit=crop',
          fit: BoxFit.cover,
        ),
        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
        ),
        // Edit Button
        Positioned(
          top: 40.v,
          right: 16.h,
          child: Container(
            padding: EdgeInsets.all(8.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 20.adaptSize,
            ),
          ),
        ),
        // Club Logo and Info
        Positioned(
          bottom: 20.v,
          left: 20.h,
          right: 20.h,
          child: Row(
            children: [
              // Club Logo
              Container(
                width: 80.adaptSize,
                height: 80.adaptSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.h),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13.h),
                  child: CustomImageWidget(
                    imageUrl:
                        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=200&h=200&fit=crop',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 16.h),
              // Club Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "SABO Arena Central", overflow: TextOverflow.ellipsis, style: TextStyle(
                              fontSize: 24.fSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.h),
                        Icon(
                          Icons.verified,
                          color: styles.appTheme.blue600,
                          size: 24.adaptSize,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.v),
                    Text(
                      "@saboarena_central", overflow: TextOverflow.ellipsis, style: TextStyle(
                        fontSize: 16.fSize,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.v),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 16.adaptSize,
                        ),
                        SizedBox(width: 4.h),
                        Flexible(
                          child: Text(
                            "123 Nguyễn Huệ, Quận 1, TP.HCM", overflow: TextOverflow.ellipsis, style: TextStyle(
                              fontSize: 14.fSize,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.h, 16.v, 16.h, 0),
      padding: EdgeInsets.all(20.h),
      decoration: styles.AppDecoration.fillWhite.copyWith(
        borderRadius: styles.BorderRadiusStyle.roundedBorder16,
        boxShadow: [
          BoxShadow(
            color: styles.appTheme.black900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Thông tin cơ bản", overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.bold,
                  color: styles.appTheme.gray900,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: styles.appTheme.gray600),
                onPressed: _onEditBasicInfo,
                iconSize: 20.adaptSize,
              ),
            ],
          ),
          SizedBox(height: 16.v),
          Text(
            "Arena bi-a hiện đại với hệ thống thi đấu chuyên nghiệp và không gian rộng rãi. "
            "Chúng tôi cung cấp môi trường tốt nhất cho các tournament và giao lưu bi-a.", overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 15.fSize,
              color: styles.appTheme.gray700,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.v),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.calendar_today_outlined,
                label: "Thành lập 2020",
                color: styles.appTheme.blue600,
              ),
              SizedBox(width: 12.h),
              _buildInfoChip(
                icon: Icons.military_tech_outlined,
                label: "Xếp hạng #12",
                color: styles.appTheme.purple600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.h, 16.v, 16.h, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: "Thành viên",
              value: "156",
              icon: Icons.people_outline,
              color: styles.appTheme.green600,
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: _buildStatCard(
              title: "Giải đấu",
              value: "24",
              icon: Icons.emoji_events_outlined,
              color: styles.appTheme.orange600,
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: _buildStatCard(
              title: "Bàn bi-a",
              value: "20",
              icon: Icons.table_restaurant_outlined,
              color: styles.appTheme.blue600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.h, 16.v, 16.h, 0),
      padding: EdgeInsets.all(20.h),
      decoration: styles.AppDecoration.fillWhite.copyWith(
        borderRadius: styles.BorderRadiusStyle.roundedBorder16,
        boxShadow: [
          BoxShadow(
            color: styles.appTheme.black900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Liên hệ", overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 18.fSize,
              fontWeight: FontWeight.bold,
              color: styles.appTheme.gray900,
            ),
          ),
          SizedBox(height: 20.v),
          _buildContactItem(
            icon: Icons.phone_outlined,
            title: "Điện thoại",
            value: "+84 28 3944 5678",
            onTap: () => _onCallPressed("+84283944567"),
          ),
          _buildContactItem(
            icon: Icons.email_outlined,
            title: "Email",
            value: "contact@saboarena.vn",
            onTap: () => _onEmailPressed("contact@saboarena.vn"),
          ),
          _buildContactItem(
            icon: Icons.language_outlined,
            title: "Website",
            value: "https://saboarena.vn",
            onTap: () => _onWebsitePressed("https://saboarena.vn"),
          ),
          SizedBox(height: 16.v),
          Row(
            children: [
              Text(
                "Mạng xã hội:", overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w600,
                  color: styles.appTheme.gray700,
                ),
              ),
              SizedBox(width: 16.h),
              _buildSocialButton(Icons.facebook, styles.appTheme.blue600),
              SizedBox(width: 8.h),
              _buildSocialButton(Icons.camera_alt, styles.appTheme.pink600),
              SizedBox(width: 8.h),
              _buildSocialButton(Icons.music_note, styles.appTheme.gray900),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.h, 16.v, 16.h, 0),
      padding: EdgeInsets.all(20.h),
      decoration: styles.AppDecoration.fillWhite.copyWith(
        borderRadius: styles.BorderRadiusStyle.roundedBorder16,
        boxShadow: [
          BoxShadow(
            color: styles.appTheme.black900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thông tin kinh doanh", overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 18.fSize,
              fontWeight: FontWeight.bold,
              color: styles.appTheme.gray900,
            ),
          ),
          SizedBox(height: 20.v),
          _buildBusinessItem(
            icon: Icons.access_time_outlined,
            title: "Giờ hoạt động",
            value: "08:00 - 24:00 (Hàng ngày)",
          ),
          _buildBusinessItem(
            icon: Icons.attach_money_outlined,
            title: "Giá thuê bàn",
            value: "80,000 - 120,000 VND/giờ",
          ),
          _buildBusinessItem(
            icon: Icons.table_restaurant_outlined,
            title: "Số bàn",
            value: "20 bàn (Pool + Carom + Snooker)",
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    final facilities = [
      "Bàn 8 bi",
      "Bàn 9 bi",
      "Bàn Carom",
      "Bàn Snooker",
      "Cafeteria",
      "Bãi đỗ xe",
      "WiFi miễn phí",
      "Điều hòa",
      "Âm thanh chất lượng",
      "Livestream",
      "VIP Rooms",
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(16.h, 16.v, 16.h, 0),
      padding: EdgeInsets.all(20.h),
      decoration: styles.AppDecoration.fillWhite.copyWith(
        borderRadius: styles.BorderRadiusStyle.roundedBorder16,
        boxShadow: [
          BoxShadow(
            color: styles.appTheme.black900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tiện ích", overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 18.fSize,
              fontWeight: FontWeight.bold,
              color: styles.appTheme.gray900,
            ),
          ),
          SizedBox(height: 16.v),
          Wrap(
            spacing: 8.h,
            runSpacing: 8.v,
            children: facilities
                .map((facility) => _buildFacilityChip(facility))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    final galleryImages = [
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
      'https://images.unsplash.com/photo-1594736797933-d0601ba2fe65?w=300&h=200&fit=crop',
      'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=300&h=200&fit=crop',
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(16.h, 16.v, 16.h, 0),
      padding: EdgeInsets.all(20.h),
      decoration: styles.AppDecoration.fillWhite.copyWith(
        borderRadius: styles.BorderRadiusStyle.roundedBorder16,
        boxShadow: [
          BoxShadow(
            color: styles.appTheme.black900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Thư viện ảnh", overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.bold,
                  color: styles.appTheme.gray900,
                ),
              ),
              TextButton(
                onPressed: _onViewAllPhotos,
                child: Text(
                  "Xem tất cả", overflow: TextOverflow.ellipsis, style: TextStyle(
                    color: styles.appTheme.blue600,
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.v),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.h,
              mainAxisSpacing: 12.v,
              childAspectRatio: 1.5,
            ),
            itemCount: galleryImages.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12.h),
                child: CustomImageWidget(
                  imageUrl: galleryImages[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.h, 16.v, 16.h, 0),
      padding: EdgeInsets.all(20.h),
      decoration: styles.AppDecoration.fillWhite.copyWith(
        borderRadius: styles.BorderRadiusStyle.roundedBorder16,
        boxShadow: [
          BoxShadow(
            color: styles.appTheme.black900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Vị trí", overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.bold,
                  color: styles.appTheme.gray900,
                ),
              ),
              TextButton(
                onPressed: _onOpenMap,
                child: Text(
                  "Chỉ đường", overflow: TextOverflow.ellipsis, style: TextStyle(
                    color: styles.appTheme.blue600,
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.v),
          Container(
            height: 200.v,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.h),
              color: styles.appTheme.gray200,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: styles.appTheme.gray600,
                    size: 48.adaptSize,
                  ),
                  SizedBox(height: 8.v),
                  Text(
                    "Bản đồ sẽ được hiển thị ở đây", overflow: TextOverflow.ellipsis, style: TextStyle(
                      color: styles.appTheme.gray600,
                      fontSize: 14.fSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.v),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: styles.appTheme.gray600,
                size: 20.adaptSize,
              ),
              SizedBox(width: 8.h),
              Expanded(
                child: Text(
                  "123 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh", overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontSize: 15.fSize,
                    color: styles.appTheme.gray700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    // 🎱 Show "Create Post" button if user can manage this club
    // For now, show both Edit and Create Post buttons
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🎱 Create Post FAB
        FloatingActionButton(
          heroTag: 'create_post',
          onPressed: () => _showCreatePostModal(context),
          backgroundColor: const Color(0xFF8B5CF6), // Purple for club
          child: const Icon(Icons.edit_note, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Edit Profile FAB
        FloatingActionButton.extended(
          heroTag: 'edit_profile',
          onPressed: _onEditProfile,
          backgroundColor: styles.appTheme.blue600,
          label: const Text(
            "Chỉnh sửa", overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          icon: Icon(Icons.edit_outlined, color: Colors.white, size: 20.adaptSize),
        ),
      ],
    );
  }

  /// 🎱 Show modal to create post as club
  void _showCreatePostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostModalWidget(
        defaultClubId: widget.clubId, // 🎱 Use real club ID from widget
      ),
    );
  }

  // Helper Widgets
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.v),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.adaptSize),
          SizedBox(width: 6.h),
          Text(
            label, style: TextStyle(
              color: color,
              fontSize: 12.fSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: styles.appTheme.black900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Icon(icon, color: color, size: 24.adaptSize),
          ),
          SizedBox(height: 8.v),
          Text(
            value, style: TextStyle(
              fontSize: 20.fSize,
              fontWeight: FontWeight.bold,
              color: styles.appTheme.gray900,
            ),
          ),
          Text(
            title, style: TextStyle(
              fontSize: 12.fSize,
              color: styles.appTheme.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.v),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.h),
        child: Padding(
          padding: EdgeInsets.all(8.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.h),
                decoration: BoxDecoration(
                  color: styles.appTheme.gray100,
                  borderRadius: BorderRadius.circular(8.h),
                ),
                child: Icon(
                  icon,
                  color: styles.appTheme.gray600,
                  size: 20.adaptSize,
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, style: TextStyle(
                        fontSize: 12.fSize,
                        color: styles.appTheme.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value, style: TextStyle(
                        fontSize: 15.fSize,
                        color: styles.appTheme.gray900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: styles.appTheme.gray400,
                size: 16.adaptSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.v),
      child: Row(
        children: [
          Icon(icon, color: styles.appTheme.gray600, size: 20.adaptSize),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, style: TextStyle(
                    fontSize: 14.fSize,
                    color: styles.appTheme.gray700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value, style: TextStyle(
                    fontSize: 13.fSize,
                    color: styles.appTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Icon(icon, color: color, size: 20.adaptSize),
    );
  }

  Widget _buildFacilityChip(String facility) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.v),
      decoration: BoxDecoration(
        color: styles.appTheme.blue50,
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: styles.appTheme.blue200),
      ),
      child: Text(
        facility, style: TextStyle(
          fontSize: 12.fSize,
          color: styles.appTheme.blue700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Event Handlers
  void _onSharePressed() => ProductionLogger.debug('Debug log', tag: 'AutoFix');
  void _onMorePressed() => ProductionLogger.debug('Debug log', tag: 'AutoFix');
  void _onEditBasicInfo() => ProductionLogger.debug('Debug log', tag: 'AutoFix');
  void _onCallPressed(String phone) => ProductionLogger.debug('Debug log', tag: 'AutoFix');
  void _onEmailPressed(String email) => ProductionLogger.debug('Debug log', tag: 'AutoFix');
  void _onWebsitePressed(String website) => ProductionLogger.debug('Debug log', tag: 'AutoFix');
  void _onViewAllPhotos() => ProductionLogger.debug('Debug log', tag: 'AutoFix');
  void _onOpenMap() => ProductionLogger.debug('Debug log', tag: 'AutoFix');
  void _onEditProfile() => ProductionLogger.debug('Debug log', tag: 'AutoFix');

  /// 📚 Show posting guide for club owners/admins
  void _showPostingGuide() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_note,
                      color: Color(0xFF8B5CF6),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Hướng dẫn đăng bài', overflow: TextOverflow.ellipsis, style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGuideSection(
                        icon: Icons.home,
                        title: '1️⃣ Đăng bài từ Trang chủ',
                        steps: [
                          'Click nút "Tạo bài viết"',
                          'Nếu bạn quản lý CLB → thấy dropdown "Đăng bài với tư cách"',
                          'Chọn CLB từ danh sách',
                          'Viết nội dung → Post',
                          '✅ Bài viết thuộc về CLB',
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        icon: Icons.sports_basketball,
                        title: '2️⃣ Đăng bài từ Trang CLB',
                        steps: [
                          'Vào trang CLB (nếu bạn là owner/admin)',
                          'Click nút màu tím 📝 (góc phải dưới)',
                          'Modal tự động chọn sẵn CLB',
                          'Viết nội dung → Post',
                          '✅ Bài viết tự động thuộc về CLB',
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        icon: Icons.auto_awesome,
                        title: '3️⃣ Tự động đăng khi giải kết thúc',
                        steps: [
                          'Khi giải đấu của CLB hoàn thành',
                          'Hệ thống tự động tạo bài viết',
                          'Thông tin: Tên giải, vô địch, số người tham gia',
                          'Hashtags tự động: #SABOArena #Tournament',
                          '✅ Bài viết thuộc về CLB tổ chức',
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        icon: Icons.visibility,
                        title: '4️⃣ Hiển thị trong Feed',
                        steps: [
                          'Bài viết của CLB: Logo CLB + Tên CLB',
                          'Bài viết cá nhân: Avatar + Tên user',
                          'Tự động phân biệt theo club_id',
                          '✅ Người dùng biết bài viết từ CLB hay cá nhân',
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFE4A3),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF856404),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Chỉ owner và admin của CLB mới có thể đăng bài với tư cách CLB.', overflow: TextOverflow.ellipsis, style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF856404),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Footer Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đã hiểu', overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 16,
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

  Widget _buildGuideSection({
    required IconData icon,
    required String title,
    required List<String> steps,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title, style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...steps.map((step) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '•', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8B5CF6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step, style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A4A4A),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

