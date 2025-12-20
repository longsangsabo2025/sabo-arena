import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/club.dart';
import '../../../models/tournament.dart';
import '../../../utils/spa_navigation_helper.dart';
import '../../../widgets/dialogs/member_registration_dialog_ios.dart';
import '../../../utils/profile_navigation_utils.dart';
import '../../table_reservation_screen/table_reservation_screen.dart';
import 'club_review_dialog.dart';
import 'club_review_history_sheet.dart';
import 'club_detail_header.dart';
import 'tabs/club_info_tab.dart';
import 'tabs/club_members_tab.dart';
import 'tabs/club_tournaments_tab.dart';
import 'tabs/club_photos_tab.dart';
import '../controllers/club_detail_controller.dart';

class ClubDetailSection extends StatefulWidget {
  final Club club;
  final VoidCallback? onNeedRefresh; // Callback to notify parent to refresh

  const ClubDetailSection({super.key, required this.club, this.onNeedRefresh});

  @override
  State<ClubDetailSection> createState() => _ClubDetailSectionState();
}

class _ClubDetailSectionState extends State<ClubDetailSection>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ClubDetailController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _controller = ClubDetailController(club: widget.club);
  }

  @override
  void didUpdateWidget(ClubDetailSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.club.id != widget.club.id) {
      _controller.dispose();
      _controller = ClubDetailController(club: widget.club);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Collapsing header with club info
              SliverToBoxAdapter(
                child: ClubDetailHeader(
                  club: widget.club,
                  isFollowing: _controller.isFollowing,
                  isFollowLoading: _controller.isFollowLoading,
                  isCurrentUserMember: _controller.isCurrentUserMember,
                  onFollow: _handleFollowClub,
                  onJoin: _handleJoinMember,
                  onRegisterRank: _handleRegisterRank,
                  onViewSpaRewards: _handleViewSpaRewards,
                  onTableReservation: _handleTableReservation,
                  onRateClub: _handleRateClub,
                  onShowReviewHistory: _showReviewHistory,
                ),
              ),
              // Pinned tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor:
                        colorScheme.onSurface.withValues(alpha: 0.6),
                    indicatorColor: colorScheme.primary,
                    indicatorWeight: 2,
                    isScrollable: true,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Thông tin'),
                      Tab(text: 'Thành viên'),
                      Tab(text: 'Giải đấu'),
                      Tab(text: 'Hình ảnh'),
                    ],
                  ),
                  colorScheme,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              ClubInfoTab(club: widget.club),
              ClubMembersTab(
                clubId: widget.club.id,
                members: _controller.members,
                isLoading: _controller.isLoadingMembers,
                error: _controller.membersError,
                onRefresh: _controller.loadMembers,
                onShowMemberProfile: _showMemberProfile,
              ),
              ClubTournamentsTab(
                club: widget.club,
                tournaments: _controller.tournaments,
                isLoading: _controller.isLoadingTournaments,
                error: _controller.tournamentsError,
                filter: _controller.tournamentFilter,
                isClubOwner: _controller.isClubOwner,
                onFilterChanged: _controller.setTournamentFilter,
                onRefresh: _controller.loadTournaments,
                onDeleteTournament: _handleDeleteTournament,
                onHideTournament: _handleHideTournament,
              ),
              ClubPhotosTab(
                photos: _controller.photos,
                isLoading: _controller.isLoadingPhotos,
                error: _controller.photosError,
                isClubOwner: _controller.isClubOwner,
                onAddPhoto: _handleAddPhoto,
                onDeletePhoto: _handleDeletePhoto,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMemberProfile(BuildContext context, String userId) {
    ProfileNavigationUtils.navigateToUserProfileById(context, userId);
  }

  void _handleFollowClub() async {
    try {
      final success = await _controller.toggleFollow();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _controller.isFollowing
                  ? 'Đã theo dõi ${widget.club.name}'
                  : 'Đã bỏ theo dõi ${widget.club.name}',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleJoinMember() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MemberRegistrationDialog(
        clubId: widget.club.id,
        clubName: widget.club.name,
        onMemberRegistered: () {
          Future.delayed(const Duration(milliseconds: 2000), () {
            _controller.loadMembers();
            _controller.checkMembershipStatus();
          });
        },
      ),
    );
  }

  void _handleRegisterRank() {
    Navigator.pushNamed(
      context,
      '/rank_management',
      arguments: {'club': widget.club},
    );
  }

  void _handleViewSpaRewards() {
    SpaNavigationHelper.navigateToUserSpaRewards(
      context,
      clubId: widget.club.id,
      clubName: widget.club.name,
    );
  }

  void _showReviewHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClubReviewHistorySheet(club: widget.club),
    );
  }

  void _handleRateClub() async {
    final result = await ClubReviewDialog.show(context, widget.club);
    if (result == true && mounted) {
      widget.onNeedRefresh?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn đánh giá của bạn! 🌟'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleTableReservation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableReservationScreen(club: widget.club),
      ),
    );
  }

  Future<void> _handleAddPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _controller.addPhoto(image);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã thêm ảnh thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi thêm ảnh: $e')),
        );
      }
    }
  }

  Future<void> _handleDeletePhoto(String photoUrl, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ảnh'),
        content: const Text('Bạn có chắc muốn xóa ảnh này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _controller.deletePhoto(photoUrl);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xóa ảnh thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi xóa ảnh: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteTournament(Tournament tournament) async {
    final canDelete = await _controller.canDeleteTournament(tournament);

    if (!mounted) return;

    if (!canDelete) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Không thể xóa'),
          content: const Text(
            'Không thể xóa giải đấu này vì đã có người đăng ký và thanh toán.\n\n'
            'Bạn chỉ có thể xóa giải đấu khi chưa có ai thanh toán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giải đấu'),
        content: Text(
          'Bạn có chắc muốn xóa giải đấu "${tournament.title}" không?\n\n'
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _controller.deleteTournament(tournament);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa giải đấu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi xóa giải đấu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleHideTournament(Tournament tournament) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ẩn giải đấu?'),
        content: Text(
            'Bạn có chắc chắn muốn ẩn giải đấu "${tournament.title}" không? Người dùng sẽ không thấy giải đấu này nữa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
            child: const Text('Ẩn'),
          ),
        ],
      ),
    );
  }
}

// Custom SliverPersistentHeaderDelegate for TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final ColorScheme colorScheme;

  _SliverTabBarDelegate(this.tabBar, this.colorScheme);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: colorScheme.surface, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
