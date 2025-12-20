import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/club_service.dart';
import '../../services/tournament_service.dart';
import '../../models/tournament.dart';
import '../../core/utils/sabo_rank_system.dart';
import '../../core/constants/ranking_constants.dart';
import '../../widgets/common/app_button.dart';

import './widgets/club_header_widget.dart';
import './widgets/club_info_section_widget.dart';
import './widgets/club_members_widget.dart';
import './widgets/club_photo_gallery_widget.dart';
import './widgets/club_tournaments_widget.dart';
import '../tournament_creation_wizard/tournament_creation_wizard.dart';
import '../rank_registration_screen/rank_registration_screen.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class ClubProfileScreen extends StatefulWidget {
  const ClubProfileScreen({super.key});

  @override
  State<ClubProfileScreen> createState() => _ClubProfileScreenState();
}

class _ClubProfileScreenState extends State<ClubProfileScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late TabController _tabController;

  // User profile data for rank checking
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = false;

  // Real data from Supabase
  Map<String, dynamic> _clubData = {};
  bool _isLoadingClub = true;
  String? _clubId;
  bool _isDataLoaded = false;

  // Club photos from posts with images
  List<String> _clubPhotos = [];
  bool _isLoadingPhotos = false;

  List<Map<String, dynamic>> _clubMembers = [];

  // Club tournaments from TournamentService
  List<Tournament> _clubTournaments = [];
  bool _isLoadingTournaments = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        if (args is String) {
          _clubId = args;
        } else if (args is Map && args.containsKey('club_id')) {
          _clubId = args['club_id'].toString();
        } else if (args is Map && args.containsKey('id')) {
          _clubId = args['id'].toString();
        }

        if (_clubId != null) {
          _loadClubData(_clubId!);
        } else {
          setState(() {
            _isLoadingClub = false;
          });
        }
      } else {
        // Fallback or handle missing ID
        setState(() {
          _isLoadingClub = false;
        });
      }
      _isDataLoaded = true;
    }
  }

  Future<void> _loadClubData(String clubId) async {
    setState(() {
      _isLoadingClub = true;
    });

    try {
      final club = await ClubService.instance.getClubById(clubId);
      final members = await ClubService.instance.getClubMembers(clubId);
      final isMember = await ClubService.instance.isClubMember(clubId);
      final currentUser = Supabase.instance.client.auth.currentUser;
      final isOwner = currentUser != null && club.ownerId == currentUser.id;

      if (mounted) {
        setState(() {
          _clubData = {
            "id": club.id,
            "name": club.name,
            "location": club.address ?? "",
            "address": club.address ?? "",
            "memberCount": members.length,
            "isMember": isMember,
            "isOwner": isOwner,
            "coverImage": club.coverImageUrl ??
                "https://images.unsplash.com/photo-1578662996442-48f60103fc96?fm=jpg&q=60&w=3000",
            "logo": club.logoUrl ??
                "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?fm=jpg&q=60&w=3000",
            "description": club.description ?? "",
            "phone": club.phone ?? "",
            "email": club.email ?? "",
            "rating": club.rating,
            "reviewCount": club.totalReviews,
          };

          _clubMembers = members
              .map((m) => {
                    "id": m.id,
                    "display_name": m.displayName,
                    "full_name": m.fullName,
                    "username": m.username, // Add username for fallback
                    "avatar_url": m.avatarUrl ?? "",
                    "role": "Member",
                    "rank": m.rank,
                    "elo_rating": m.eloRating,
                    "is_verified": m.isVerified,
                  })
              .toList();
        });
      }

      // Load club photos and tournaments in parallel
      await Future.wait([
        _loadClubPhotos(clubId),
        _loadClubTournaments(clubId),
      ]);
    } catch (e) {
      debugPrint("Error loading club data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading club data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingClub = false;
        });
      }
    }
  }

  Future<void> _loadClubPhotos(String clubId) async {
    setState(() {
      _isLoadingPhotos = true;
    });

    try {
      // Fetch posts from this club that have images
      final response = await Supabase.instance.client
          .from('posts')
          .select('image_urls')
          .eq('club_id', clubId)
          .not('image_urls', 'is', null)
          .order('created_at', ascending: false)
          .limit(20);

      final List<String> photos = [];
      for (final post in response) {
        final imageUrls = post['image_urls'] as List?;
        if (imageUrls != null && imageUrls.isNotEmpty) {
          // Add all images from this post
          photos.addAll(imageUrls.cast<String>());
        }
      }

      if (mounted) {
        setState(() {
          _clubPhotos = photos;
        });
      }
    } catch (e) {
      debugPrint("Error loading club photos: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPhotos = false;
        });
      }
    }
  }

  Future<void> _loadClubTournaments(String clubId) async {
    setState(() {
      _isLoadingTournaments = true;
    });

    try {
      final tournaments = await TournamentService.instance.getClubTournaments(
        clubId,
        page: 1,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          _clubTournaments = tournaments;
        });
      }
    } catch (e) {
      debugPrint("Error loading club tournaments: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTournaments = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      // Load current user data from Supabase
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select('*')
            .eq('id', user.id)
            .single();

        setState(() {
          _userData = response;
        });
      }
    } finally {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoadingClub) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_clubData.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text("Club Profile"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text("Could not load club data")),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Club Header with Cover Image
          ClubHeaderWidget(
            clubData: _clubData,
            isOwner: _clubData["isOwner"] as bool,
            onEditPressed: _handleEditClub,
            onJoinTogglePressed: _handleJoinToggle,
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 3.h),

                // Club Info Section
                ClubInfoSectionWidget(clubData: _clubData),

                SizedBox(height: 3.h),

                // User Rank Status Section
                _buildUserRankSection(context),

                SizedBox(height: 3.h),

                // Photo Gallery
                ClubPhotoGalleryWidget(
                  photos: _clubPhotos,
                  onViewAll: _handleViewAllPhotos,
                ),

                SizedBox(height: 3.h),

                // Members Section
                ClubMembersWidget(
                  clubId: _clubData["id"]?.toString() ?? '',
                  members: _clubMembers,
                  isOwner: _clubData["isOwner"] as bool,
                  onViewAll: _handleViewAllMembers,
                  onMemberTap: _handleMemberTap,
                ),

                SizedBox(height: 3.h),

                // Tournaments Section
                ClubTournamentsWidget(
                  tournaments: _clubTournaments
                      .map((t) => {
                            "id": t.id,
                            "name": t.title,
                            "format": t.tournamentType,
                            "status": t.status,
                            "startDate": t.startDate.toIso8601String(),
                            "endDate": t.endDate?.toIso8601String(),
                            "participants": t.currentParticipants,
                            "maxParticipants": t.maxParticipants,
                            "prizePool": t.prizePool.toString(),
                            "entryFee": t.entryFee.toString(),
                            "description": t.description,
                          })
                      .toList(),
                  isOwner: _clubData["isOwner"] as bool,
                  onViewAll: _handleViewAllTournaments,
                  onCreateTournament: _handleCreateTournament,
                  onTournamentTap: _handleTournamentTap,
                ),

                SizedBox(height: 3.h),

                // Rating and Reviews Section
                _buildRatingSection(context),

                SizedBox(height: 10.h), // Bottom padding for navigation
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 3, // Club tab
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 0,
            onTap: (index) {
              switch (index) {
                case 0:
                  _handleBottomNavTap(AppRoutes.homeFeedScreen);
                  break;
                case 1:
                  _handleBottomNavTap(AppRoutes.findOpponentsScreen);
                  break;
                case 2:
                  _handleBottomNavTap(AppRoutes.tournamentListScreen);
                  break;
                case 3:
                  // Already on club
                  break;
                case 4:
                  _handleBottomNavTap(AppRoutes.userProfileScreen);
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Đối thủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events),
                label: 'Giải đấu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business_outlined),
                activeIcon: Icon(Icons.business),
                label: 'Câu lạc bộ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Cá nhân',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rating = _clubData["rating"] as double;
    final reviewCount = _clubData["reviewCount"] as int;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                'Đánh giá',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _handleViewAllReviews,
                child: Text(
                  'Xem tất cả',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Text(
                rating.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: 2.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return CustomIconWidget(
                        iconName:
                            index < rating.floor() ? 'star' : 'star_border',
                        color: Colors.amber,
                        size: 4.w,
                      );
                    }),
                  ),
                  Text(
                    '$reviewCount đánh giá',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          AppButton(
            label: 'Viết đánh giá',
            type: AppButtonType.primary,
            size: AppButtonSize.large,
            icon: Icons.rate_review,
            iconTrailing: false,
            fullWidth: true,
            onPressed: _handleWriteReview,
          ),
        ],
      ),
    );
  }

  void _handleEditClub() {
    // Navigate to club edit screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa câu lạc bộ'),
        content: const Text(
          'Chức năng chỉnh sửa thông tin câu lạc bộ sẽ được triển khai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleJoinToggle() {
    setState(() {
      final isMember = _clubData["isMember"] as bool;
      _clubData["isMember"] = !isMember;
      if (!isMember) {
        _clubData["memberCount"] = (_clubData["memberCount"] as int) + 1;
      } else {
        _clubData["memberCount"] = (_clubData["memberCount"] as int) - 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _clubData["isMember"] as bool
              ? 'Đã tham gia câu lạc bộ thành công!'
              : 'Đã rời khỏi câu lạc bộ!',
        ),
      ),
    );
  }

  void _handleViewAllPhotos() {
    // Navigate to photo gallery screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thư viện ảnh'),
        content: const Text('Chức năng xem tất cả ảnh sẽ được triển khai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleViewAllMembers() {
    // Navigate to members list screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Danh sách thành viên'),
        content: const Text(
          'Chức năng xem tất cả thành viên sẽ được triển khai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleMemberTap(Map<String, dynamic> member) {
    Navigator.pushNamed(context, '/user-profile-screen');
  }

  void _handleViewAllTournaments() {
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentListScreen,
      arguments: {
        'clubId': _clubData['id'].toString(),
      }, // Pass club ID as filter
    );
  }

  void _handleCreateTournament() {
    // Navigate to tournament creation wizard
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TournamentCreationWizard(clubId: _clubData['id'].toString()),
      ),
    ).then((result) {
      if (!mounted) return;
      if (result != null && result is Map<String, dynamic>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giải đấu đã được tạo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh tournament list
        setState(() {});
      }
    });
  }

  void _handleTournamentTap(Map<String, dynamic> tournament) {
    ProductionLogger.info(
        '🎯 Tournament tapped: ${tournament["id"]} - ${tournament["name"]}',
        tag: 'club_profile_screen');

    // Navigate to tournament detail screen with tournament data
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentDetailScreen,
      arguments: {
        'tournamentId': tournament['id']?.toString() ?? '',
        'tournament': tournament,
      },
    );
  }

  Widget _buildUserRankSection(BuildContext context) {
    if (_isLoadingUser) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_userData == null) {
      return SizedBox.shrink();
    }

    // Kiểm tra xem user có rank từ database hay không
    final userRank = _userData!["rank"] as String?;
    final hasRank =
        userRank != null && userRank.isNotEmpty && userRank != 'unranked';
    final currentElo = _userData!["elo_rating"] as int? ?? 1200;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: hasRank
              ? SaboRankSystem.getRankColor(
                  RankingConstants.getRankFromElo(currentElo),
                ).withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.military_tech,
                color: hasRank
                    ? SaboRankSystem.getRankColor(
                        RankingConstants.getRankFromElo(currentElo),
                      )
                    : Colors.orange,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái Rank',
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      hasRank
                          ? 'Bạn đã có rank chính thức'
                          : 'Bạn chưa đăng ký rank chính thức',
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!hasRank)
                Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.priority_high,
                    color: Colors.white,
                    size: 4.w,
                  ),
                ),
            ],
          ),

          SizedBox(height: 3.h),

          // Rank info or registration prompt
          if (hasRank) ...[
            _buildRankInfo(userRank, currentElo),
          ] else ...[
            _buildRankRegistrationPrompt(),
          ],
        ],
      ),
    );
  }

  Widget _buildRankInfo(String rank, int elo) {
    final rankColor = SaboRankSystem.getRankColor(
      RankingConstants.getRankFromElo(elo),
    );
    final skillDescription = SaboRankSystem.getRankSkillDescription(
      RankingConstants.getRankFromElo(elo),
    );

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: rankColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rank hiện tại: $rank',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'ELO: $elo',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  skillDescription,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankRegistrationPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 5.w),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Để tham gia các trận đấu ranked tại club này, bạn cần đăng ký rank chính thức.',
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                'Lợi ích khi có rank:',
                overflow: TextOverflow.ellipsis,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
              SizedBox(height: 1.h),
              ...[
                '• Tham gia các trận đấu ranked',
                '• Theo dõi ELO rating chính xác',
                '• Tham gia giải đấu chính thức',
                '• Xem thống kê chi tiết',
              ].map(
                (benefit) => Padding(
                  padding: EdgeInsets.only(bottom: 0.5.h),
                  child: Text(
                    benefit,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 2.h),

        // Registration button - iOS style
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Đăng ký Rank ngay',
            type: AppButtonType.primary,
            size: AppButtonSize.large,
            icon: Icons.how_to_reg,
            iconTrailing: false,
            customColor: Colors.orange,
            customTextColor: Colors.white,
            fullWidth: true,
            onPressed: _showRankRegistrationDialog,
          ),
        ),
      ],
    );
  }

  void _showRankRegistrationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'Đăng ký Rank Chính thức',
          overflow: TextOverflow.ellipsis,
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Việc đăng ký rank sẽ giúp bạn:',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogBenefit('🏆', 'Tham gia các trận đấu ranked'),
                  _buildDialogBenefit('📊', 'Theo dõi ELO rating chính xác'),
                  _buildDialogBenefit('🎯', 'Tham gia giải đấu chính thức'),
                  _buildDialogBenefit('📈', 'Xem thống kê chi tiết'),
                  _buildDialogBenefit('🏅', 'Cạnh tranh với players khác'),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Bạn có muốn đăng ký rank ngay bây giờ không?',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Để sau',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          AppButton(
            label: 'Đăng ký ngay',
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToRankRegistration();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDialogBenefit(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 4.w)),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRankRegistration() {
    // Use mock club ID since this screen uses mock data
    final clubId = _clubData["id"].toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RankRegistrationScreen(clubId: clubId),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh user data if rank request was submitted
        _loadUserData();
      }
    });
  }

  void _handleViewAllReviews() {
    // Navigate to reviews screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tất cả đánh giá'),
        content: const Text(
          'Chức năng xem tất cả đánh giá sẽ được triển khai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleWriteReview() {
    // Show review dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Viết đánh giá'),
        content: const Text('Chức năng viết đánh giá sẽ được triển khai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleBottomNavTap(String route) {
    if (route != AppRoutes.clubProfileScreen) {
      Navigator.pushReplacementNamed(context, route);
    }
  }
}
