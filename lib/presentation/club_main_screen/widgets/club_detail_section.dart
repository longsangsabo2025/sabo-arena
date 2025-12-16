import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../models/club.dart';
import '../../../models/user_profile.dart';
import '../../../models/club_permission.dart';
import '../../../models/tournament.dart';
import '../../../services/club_service.dart';
import '../../../services/club_permission_service.dart';
import '../../../services/tournament_service.dart';
import '../../../utils/map_launcher.dart';
import '../../../utils/spa_navigation_helper.dart';
import '../../../widgets/loading_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/dialogs/member_registration_dialog_ios.dart';
import '../../../utils/profile_navigation_utils.dart';
import '../../table_reservation_screen/table_reservation_screen.dart';
import '../../shared/widgets/tournament_card_widget.dart';
import 'club_review_dialog.dart';
import 'club_review_history_sheet.dart';
import 'package:intl/intl.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

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
  bool _isJoined = false;
  bool _isLoading = false;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  // Members data
  final ClubService _clubService = ClubService.instance;
  final TournamentService _tournamentService = TournamentService.instance;
  List<UserProfile> _members = [];
  bool _isLoadingMembers = false;
  String? _membersError;
  bool _isCurrentUserMember = false;

  // Tournaments data
  List<Tournament> _tournaments = [];
  bool _isLoadingTournaments = false;
  String? _tournamentsError;

  // Tournament filter state
  String _tournamentFilter = 'Tất cả'; // 'Tất cả', 'Sắp tới', 'Đang diễn ra', 'Đã kết thúc'
  
  // Photos data
  List<String> _photos = [];
  bool _isLoadingPhotos = false;
  String? _photosError;
  bool _isClubOwner = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMembers();
    _loadTournaments();
    _loadPhotos();
    _checkFollowStatus();
    _checkMembershipStatus();
    _checkOwnerStatus();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _membersError = null;
    });

    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Check authentication status
      final user = Supabase.instance.client.auth.currentUser;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final members = await _clubService.getClubMembers(widget.club.id);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoadingMembers = false;
        });
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        if (members.isEmpty) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } else {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
          _membersError = e.toString();
        });
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // Better error messages based on error type
        if (e.toString().contains('JWT') || e.toString().contains('auth')) {
          _membersError = 'Vui lòng đăng nhập để xem danh sách thành viên';
        } else if (e.toString().contains('timeout') ||
            e.toString().contains('network')) {
          _membersError = 'Kết nối mạng chậm. Vui lòng thử lại';
        } else if (e.toString().contains('RLS') ||
            e.toString().contains('policy')) {
          _membersError = 'Quyền truy cập bị hạn chế. Đang khắc phục...';
        } else {
          _membersError = 'Lỗi: ${e.toString()}';
        }
      }
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing = await _clubService.isFollowingClub(widget.club.id);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  Future<void> _checkMembershipStatus() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return;
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await Supabase.instance.client
          .from('club_members')
          .select()
          .eq('club_id', widget.club.id)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isCurrentUserMember = response != null;
        });
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  Future<void> _checkOwnerStatus() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        return;
      }

      setState(() {
        _isClubOwner = widget.club.ownerId == currentUser.id;
      });
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoadingPhotos = true;
      _photosError = null;
    });

    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await Supabase.instance.client
          .from('club_photos')
          .select('photo_url')
          .eq('club_id', widget.club.id)
          .order('created_at', ascending: false);

      if (mounted) {
        final photoList = (response as List)
            .map((item) => item['photo_url'] as String)
            .toList();
        
        setState(() {
          _photos = photoList;
          _isLoadingPhotos = false;
        });
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPhotos = false;
          _photosError = e.toString();
          // Don't use mock photos - leave empty
          _photos = [];
        });
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoadingTournaments = true;
      _tournamentsError = null;
    });

    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final tournaments = await _tournamentService.getTournaments(
        clubId: widget.club.id,
      );

      if (mounted) {
        setState(() {
          _tournaments = tournaments;
          _isLoadingTournaments = false;
        });
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        for (var t in tournaments) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTournaments = false;
          _tournamentsError = e.toString();
        });
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  void _showMemberProfile(BuildContext context, UserProfile member) {
    ProfileNavigationUtils.navigateToUserProfile(context, member);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // Collapsing header with club info
          SliverToBoxAdapter(child: _buildClubHeader(colorScheme)),
          // Pinned tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
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
          _buildInfoTab(colorScheme),
          _buildMembersTab(colorScheme),
          _buildTournamentsTab(colorScheme),
          _buildPhotosTab(colorScheme),
        ],
      ),
    );
  }

  Widget _buildClubHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hàng 1: Logo + Club Info + Nút Đặt Bàn
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  image: widget.club.profileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(widget.club.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: widget.club.profileImageUrl == null
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : null,
                ),
                child: widget.club.profileImageUrl == null
                    ? Icon(Icons.business, size: 24, color: colorScheme.primary)
                    : null,
              ),

              const SizedBox(width: 16),

              // Club Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tên CLB
                    Text(
                      widget.club.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Địa chỉ + Icon bản đồ
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.club.address ?? 'Không có địa chỉ',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.club.latitude != null &&
                            widget.club.longitude != null)
                          OutlinedButton.icon(
                            onPressed: () {
                              MapLauncher.showMapOptionsDialog(
                                context: context,
                                latitude: widget.club.latitude!,
                                longitude: widget.club.longitude!,
                                label: widget.club.name,
                                address: widget.club.address,
                              );
                            },
                            icon: Icon(Icons.map_outlined, size: 16),
                            label: const Text('Xem bản đồ'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Số sao + Nút đánh giá
                    Row(
                      children: [
                        // Clickable rating stars to view review history
                        InkWell(
                          onTap: () => _showReviewHistory(),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < widget.club.rating.floor()
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: colorScheme.primary,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  widget.club.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${widget.club.totalReviews})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ],
                            ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _handleRateClub(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Đánh giá',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Nút Đặt Bàn (góc phải trên)
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: _handleTableReservation,
                  icon: const Icon(Icons.event_available, size: 16),
                  label: const Text(
                    'Đặt Bàn',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hàng 2: Action buttons nằm ngang
          Row(
            children: [
              Expanded(
                child: _buildHorizontalActionButton(
                  icon: _isFollowing ? Icons.favorite : Icons.favorite_border,
                  label: _isFollowing ? 'Unfollow' : 'Follow',
                  colorScheme: colorScheme,
                  onPressed: _isFollowLoading
                      ? null
                      : () => _handleFollowClub(),
                  isLoading: _isFollowLoading,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildHorizontalActionButton(
                  icon: _isCurrentUserMember
                      ? Icons.check_circle
                      : Icons.group_add,
                  label: _isCurrentUserMember ? 'Đã tham gia' : 'ĐK Member',
                  colorScheme: colorScheme,
                  onPressed: _isCurrentUserMember
                      ? null
                      : () => _handleJoinMember(),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildHorizontalActionButton(
                  icon: Icons.emoji_events,
                  label: 'ĐK Hạng',
                  colorScheme: colorScheme,
                  onPressed: () => _handleRegisterRank(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Hàng 3: Button Phần thưởng SPA
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _handleViewSpaRewards(),
              icon: const Icon(Icons.card_giftcard, size: 20),
              label: const Text(
                'Phần thưởng SPA',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinLeaveButton(ColorScheme colorScheme) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleJoinLeave,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isJoined ? colorScheme.error : colorScheme.primary,
          foregroundColor: _isJoined
              ? colorScheme.onError
              : colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isJoined ? colorScheme.onError : colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                _isJoined ? 'Rời khỏi' : 'Tham gia',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _handleJoinLeave() async {
    if (_isJoined) {
      // Show confirmation dialog for leaving
      final shouldLeave = await _showLeaveConfirmDialog();
      if (shouldLeave == true) {
        await _leaveClub();
      }
    } else {
      await _joinClub();
    }
  }

  Future<bool?> _showLeaveConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời khỏi câu lạc bộ'),
        content: Text(
          'Bạn có chắc chắn muốn rời khỏi câu lạc bộ "${widget.club.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Rời khỏi'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinClub() async {
    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isJoined = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tham gia câu lạc bộ "${widget.club.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tham gia câu lạc bộ: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveClub() async {
    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isJoined = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã rời khỏi câu lạc bộ "${widget.club.name}"'),
          ),
        );
      }
    } catch (error) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi rời câu lạc bộ: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'Mô tả',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.club.description ?? 'Không có mô tả',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.6, // Better line height for readability
            ),
          ),

          const SizedBox(height: 24),

          // Facilities (using real data from club.amenities)
          if (widget.club.amenities != null &&
              widget.club.amenities!.isNotEmpty) ...[
            Text(
              'Tiện ích',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.club.amenities!.map((facility) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    facility,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Club Details (Tables & Price)
          Text(
            'Thông tin bàn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.table_bar, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Số bàn: ${widget.club.totalTables} bàn',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          if (widget.club.pricePerHour != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Giá: ${widget.club.pricePerHour!.toStringAsFixed(0)}đ/giờ',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Opening hours (using real data if available)
          Text(
            'Giờ mở cửa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.club.openingHours != null
                ? _formatOpeningHours(widget.club.openingHours!)
                : 'Chưa cập nhật giờ mở cửa',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),

          const SizedBox(height: 24),

          // Contact info (using real data)
          Text(
            'Thông tin liên hệ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          if (widget.club.phone != null) ...[
            Row(
              children: [
                Icon(Icons.phone, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  widget.club.phone!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          if (widget.club.email != null) ...[
            Row(
              children: [
                Icon(Icons.email, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  widget.club.email!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          if (widget.club.websiteUrl != null) ...[
            Row(
              children: [
                Icon(Icons.language, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.club.websiteUrl!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          if (widget.club.phone == null &&
              widget.club.email == null &&
              widget.club.websiteUrl == null)
            Text(
              'Chưa cập nhật thông tin liên hệ',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(ColorScheme colorScheme) {
    // Show loading state
    if (_isLoadingMembers) {
      return const Center(
        child: LoadingStateWidget(message: 'Đang tải danh sách thành viên...'),
      );
    }

    // Show error state
    if (_membersError != null) {
      return RefreshableErrorStateWidget(
        errorMessage: _membersError!,
        onRefresh: _loadMembers,
        title: 'Không thể tải danh sách thành viên',
        showErrorDetails: true,
      );
    }

    // Show empty state
    if (_members.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.people_outline,
          message: 'Chưa có thành viên',
          subtitle: 'Câu lạc bộ chưa có thành viên nào',
        ),
      );
    }

    return Column(
      children: [
        // Members list (stats header hidden per user request)
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _members.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = _members[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                onTap: () => _showMemberProfile(context, member),
                leading: ProfileNavigationUtils.buildClickableAvatar(
                  context: context,
                  user: member,
                  radius: 24,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  heroTag: 'member_avatar_${member.id}',
                  child: member.avatarUrl == null
                      ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
                      : null,
                ),
                title: Text(
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: member.rank != null
                                ? colorScheme.primary
                                : colorScheme.outline,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            member.rank != null
                                ? 'Rank ${member.rank}'
                                : 'Chưa xếp hạng',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.rank != null
                              ? '${member.eloRating} ELO'
                              : member.skillLevelDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(member.id, widget.club.id),
                      ],
                    ),
                  ],
                ),
                trailing: null, // Removed online status indicator
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentsTab(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    
    // Filter tournaments based on selected filter
    final filteredTournaments = _tournamentFilter == 'Tất cả'
        ? _tournaments
        : _tournaments.where((t) {
            switch (_tournamentFilter) {
              case 'Sắp tới':
                return t.status == 'upcoming';
              case 'Đang diễn ra':
                return t.status == 'ongoing';
              case 'Đã kết thúc':
                return t.status == 'completed' || t.status == 'done';
              default:
                return true;
            }
          }).toList();

    // Show loading state
    if (_isLoadingTournaments) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (_tournamentsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Không thể tải giải đấu',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _tournamentsError!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTournaments,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Filter tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('Tất cả', _tournamentFilter == 'Tất cả', colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('Sắp tới', _tournamentFilter == 'Sắp tới', colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('Đang diễn ra', _tournamentFilter == 'Đang diễn ra', colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('Đã kết thúc', _tournamentFilter == 'Đã kết thúc', colorScheme),
            ],
          ),
        ),

        // Tournaments list
        Expanded(
          child: filteredTournaments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _tournamentFilter == 'Tất cả'
                              ? 'Chưa có giải đấu nào'
                              : 'Không có giải đấu $_tournamentFilter',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: filteredTournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = filteredTournaments[index];
                    final cardData = _convertTournamentToCardData(tournament);
                    
                    // Show delete button if user is club owner
                    return Stack(
                      children: [
                        TournamentCardWidget(
                          tournament: cardData,
                          onTap: () {
                            ProductionLogger.info('🎯 Tournament tapped: ${tournament.id} - ${tournament.title}', tag: 'club_detail_section');
                            // Navigate to tournament detail (tap on card)
                            Navigator.pushNamed(
                              context,
                              '/tournament-detail-screen',
                              arguments: {
                                'tournamentId': tournament.id,
                                'tournament': tournament,
                              },
                            );
                          },
                          onDetailTap: () {
                            ProductionLogger.info('🎯 Tournament detail button tapped: ${tournament.id}', tag: 'club_detail_section');
                            // Navigate to tournament detail (tap on Detail button)
                            Navigator.pushNamed(
                              context,
                              '/tournament-detail-screen',
                              arguments: {
                                'tournamentId': tournament.id,
                                'tournament': tournament,
                              },
                            );
                          },
                          onResultTap: () {
                            ProductionLogger.info('🎯 Tournament result button tapped: ${tournament.id}', tag: 'club_detail_section');
                            // Navigate to tournament results (tap on Kết quả button)
                            Navigator.pushNamed(
                              context,
                              '/tournament-detail-screen',
                              arguments: {
                                'tournamentId': tournament.id,
                                'tournament': tournament,
                                'showResults': true,
                              },
                            );
                          },
                          onShareTap: () {
                            // TODO: Implement share tournament
                            ProductionLogger.debug('Debug log', tag: 'AutoFix');
                          },
                        ),
                        // Delete button for club owner
                        if (_isClubOwner)
                          Positioned(
                            top: 16,
                            right: 24,
                            child: GestureDetector(
                              onTap: () => _handleDeleteTournament(tournament),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Convert Tournament model to TournamentCardWidget format
  Map<String, dynamic> _convertTournamentToCardData(Tournament tournament) {
    // Determine icon number from game format (8-ball, 9-ball, 10-ball)
    String iconNumber = '9'; // Default
    final gameFormat = tournament.format.toLowerCase();
    if (gameFormat.contains('8')) {
      iconNumber = '8';
    } else if (gameFormat.contains('9')) {
      iconNumber = '9';
    } else if (gameFormat.contains('10')) {
      iconNumber = '10';
    }

    // Format date
    String dateStr = '';
    final weekday = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'][tournament.startDate.weekday % 7];
    dateStr = '${DateFormat('dd/MM').format(tournament.startDate)} - $weekday';

    // Format time
    String timeStr = DateFormat('HH:mm').format(tournament.startDate);

    // Format players count
    String playersCount = '${tournament.currentParticipants}/${tournament.maxParticipants}';

    // Prize pool (convert double to formatted string)
    String prizePool = tournament.prizePool > 0 
        ? '${(tournament.prizePool / 1000000).toStringAsFixed(1)}M VNĐ' 
        : 'Chưa có';

    // Rating/Rank requirement
    String rating = tournament.skillLevelRequired ?? 'Tất cả';

    // Mạng count (use 2 as default since not in model)
    int mangCount = 2;

    // Is live?
    bool isLive = tournament.status == 'ongoing';
    
    // ✅ Get prize breakdown from prize_distribution
    Map<String, String>? prizeBreakdown;
    final prizeDistribution = tournament.prizeDistribution;
    if (prizeDistribution != null) {
      // Check for text-based format (first, second, third keys)
      if (prizeDistribution.containsKey('first') && prizeDistribution['first'] is String) {
        prizeBreakdown = {
          'first': prizeDistribution['first'] as String,
          if (prizeDistribution['second'] != null)
            'second': prizeDistribution['second'] as String,
          if (prizeDistribution['third'] != null)
            'third': prizeDistribution['third'] as String,
        };
      }
    }

    return {
      'name': tournament.title,
      'date': dateStr,
      'startTime': timeStr,
      'playersCount': playersCount,
      'prizePool': prizePool,
      'prizeBreakdown': prizeBreakdown,
      'rating': rating,
      'iconNumber': iconNumber,
      'clubLogo': widget.club.logoUrl,
      'clubName': widget.club.name,
      'mangCount': mangCount,
      'isLive': isLive,
      'status': tournament.status,
    };
  }

  Widget _buildPhotosTab(ColorScheme colorScheme) {
    if (_isLoadingPhotos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_photosError != null && _photos.isEmpty) {
      return Center(
        child: Text('Lỗi tải ảnh: $_photosError'),
      );
    }

    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có hình ảnh nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_isClubOwner) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handleAddPhoto,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Thêm ảnh đầu tiên'),
              ),
            ],
          ],
        ),
      );
    }

    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _photos.length,
          itemBuilder: (context, index) {
            final photo = _photos[index];
            return GestureDetector(
              onTap: () => _showPhotoDialog(photo, index),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photo,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[900],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        ProductionLogger.info('❌ Error loading photo $index: $error', tag: 'club_detail_section');
                        return Container(
                          color: Colors.grey[900],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text(
                                'Lỗi tải ảnh',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Delete button for owner
                  if (_isClubOwner)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _handleDeletePhoto(photo, index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        // FAB for adding photos (only for owner)
        if (_isClubOwner)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _handleAddPhoto,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.add_a_photo),
            ),
          ),
      ],
    );
  }

  void _showPhotoDialog(String photoUrl, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Hình ảnh'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: _isClubOwner
                  ? [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _handleDeletePhoto(photoUrl, index);
                        },
                      ),
                    ]
                  : null,
            ),
            Image.network(photoUrl, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddPhoto() async {
    try {
      // Import image_picker package
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Read and compress image
      final bytes = await image.readAsBytes();
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1280,
        minHeight: 720,
        quality: 85,
        format: CompressFormat.jpeg, // Always convert to JPEG for compatibility
      );
      
      ProductionLogger.info('📸 Original size: ${bytes.length} bytes', tag: 'club_detail_section');
      ProductionLogger.info('📸 Compressed size: ${compressedBytes.length} bytes', tag: 'club_detail_section');
      ProductionLogger.info('📸 Compression ratio: ${(compressedBytes.length / bytes.length * 100).toStringAsFixed(1)}%', tag: 'club_detail_section');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'clubs/${widget.club.id}/photos/$fileName';

      // Upload compressed image to Supabase Storage
      await Supabase.instance.client.storage
          .from('club-photos')
          .uploadBinary(filePath, compressedBytes);

      // Get public URL
      final photoUrl = Supabase.instance.client.storage
          .from('club-photos')
          .getPublicUrl(filePath);

      // Save to database
      await Supabase.instance.client.from('club_photos').insert({
        'club_id': widget.club.id,
        'photo_url': photoUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Refresh photos
        await _loadPhotos();
        
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã thêm ảnh thành công!')),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi thêm ảnh: $e')),
        );
      }
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  Future<void> _handleDeletePhoto(String photoUrl, int index) async {
    // Confirm deletion
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
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete from database
      await Supabase.instance.client
          .from('club_photos')
          .delete()
          .eq('club_id', widget.club.id)
          .eq('photo_url', photoUrl);

      // Try to delete from storage (optional, might fail if already deleted)
      try {
        final uri = Uri.parse(photoUrl);
        final path = uri.pathSegments.skip(uri.pathSegments.length - 3).join('/');
        await Supabase.instance.client.storage
            .from('club-photos')
            .remove([path]);
      } catch (storageError) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Refresh photos
        await _loadPhotos();
        
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xóa ảnh thành công!')),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi xóa ảnh: $e')),
        );
      }
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  Future<void> _handleDeleteTournament(Tournament tournament) async {
    try {
      // First, check if anyone has paid
      final participantsResponse = await Supabase.instance.client
          .from('tournament_participants')
          .select('id, payment_status')
          .eq('tournament_id', tournament.id);

      final participants = participantsResponse as List;
      final hasPaidUsers = participants.any(
        (p) => p['payment_status'] == 'paid' || p['payment_status'] == 'completed',
      );

      if (hasPaidUsers) {
        // Cannot delete - show error
        if (!mounted) return;
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

      // Confirm deletion
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

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete tournament participants first (foreign key constraint)
      await Supabase.instance.client
          .from('tournament_participants')
          .delete()
          .eq('tournament_id', tournament.id);

      // Delete tournament
      await Supabase.instance.client
          .from('tournaments')
          .delete()
          .eq('id', tournament.id);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Refresh tournaments
        await _loadTournaments();
        
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa giải đấu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi xóa giải đấu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  // _buildStatCard removed - stats header hidden per user request

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _tournamentFilter = label;
          });
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      },
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
      ),
    );
  }

  // Helper method to format opening hours
  String _formatOpeningHours(Map<String, dynamic> openingHours) {
    // Try to format opening hours from JSON
    // Example format: {"monday": "08:00-22:00", "tuesday": "08:00-22:00", ...}
    // or {"default": "08:00-22:00"}

    if (openingHours.containsKey('default')) {
      return openingHours['default'] + ' (Hàng ngày)';
    }

    // If more complex format, return first day's hours as example
    if (openingHours.isNotEmpty) {
      final firstDay = openingHours.entries.first;
      return '${firstDay.value} (${firstDay.key})';
    }

    return 'Chưa cập nhật giờ mở cửa';
  }

  Widget _buildHorizontalActionButton({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  size: 18,
                  color: onPressed != null
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.5),
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: onPressed != null
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFollowClub() async {
    if (_isFollowLoading) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      bool success;
      if (_isFollowing) {
        success = await _clubService.unfollowClub(widget.club.id);
        if (success && mounted) {
          setState(() {
            _isFollowing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã bỏ theo dõi ${widget.club.name}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        success = await _clubService.followClub(widget.club.id);
        if (success && mounted) {
          setState(() {
            _isFollowing = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã theo dõi ${widget.club.name}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra. Vui lòng thử lại'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
  }

  // Removed unused _handleViewMembershipPlans method

  void _handleJoinMember() {
    // Show member registration dialog with benefits and pricing
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MemberRegistrationDialog(
        clubId: widget.club.id,
        clubName: widget.club.name,
        onMemberRegistered: () {
          // Force refresh member list and membership status after successful registration
          ProductionLogger.debug('Debug log', tag: 'AutoFix');

          // Add longer delay to ensure database commit and replication is complete
          Future.delayed(const Duration(milliseconds: 2000), () {
            ProductionLogger.debug('Debug log', tag: 'AutoFix');
            _loadMembers();
            _checkMembershipStatus();
          });
        },
      ),
    );
  }

  void _handleRegisterRank() {
    // Navigate to rank management screen
    Navigator.pushNamed(
      context,
      '/rank_management',
      arguments: {'club': widget.club},
    );
  }

  /// Navigate to SPA rewards screen
  void _handleViewSpaRewards() {
    SpaNavigationHelper.navigateToUserSpaRewards(
      context,
      clubId: widget.club.id,
      clubName: widget.club.name,
    );
  }

  /// Show review history bottom sheet
  void _showReviewHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClubReviewHistorySheet(club: widget.club),
    );
  }

  /// Handle rating club - Show review dialog
  void _handleRateClub() async {
    final result = await ClubReviewDialog.show(context, widget.club);

    // If review was submitted successfully, notify parent to refresh
    if (result == true && mounted) {
      // Call parent callback to reload club data
      widget.onNeedRefresh?.call();

      // Show success message
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
    // Navigate to table reservation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableReservationScreen(club: widget.club),
      ),
    );
  }

  Widget _buildRoleBadge(String userId, String clubId) {
    return FutureBuilder<ClubPermission?>(
      future: ClubPermissionService().getUserPermissions(userId, clubId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final role = snapshot.data!.role;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Color(int.parse(role.badgeColor.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                role.icon,
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 4),
              Text(
                role.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
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

