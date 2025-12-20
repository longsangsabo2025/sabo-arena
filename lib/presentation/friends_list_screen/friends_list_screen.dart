import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_bar_theme.dart' as app_theme;

import '../../models/user_profile.dart';
import '../../services/friends_service.dart';
import '../../services/user_service.dart';
import '../../widgets/avatar_with_quick_follow.dart';
import '../../widgets/common/app_button.dart';
import '../other_user_profile_screen/other_user_profile_screen.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

/// Friends List Screen with 3 tabs: Friends, Following, Followers
class FriendsListScreen extends StatefulWidget {
  final int initialTab; // 0=Friends, 1=Following, 2=Followers

  const FriendsListScreen({super.key, this.initialTab = 0});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen>
    with SingleTickerProviderStateMixin {
  final _friendsService = FriendsService.instance;
  final _userService = UserService.instance;

  late TabController _tabController;

  // ♾️ Infinite Scroll Pagination Controllers
  late PagingController<int, UserProfile> _friendsPagingController;
  late PagingController<int, UserProfile> _followingPagingController;
  late PagingController<int, UserProfile> _followersPagingController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    // Initialize paging controllers
    _friendsPagingController =
        PagingController<int, UserProfile>(firstPageKey: 0);
    _followingPagingController =
        PagingController<int, UserProfile>(firstPageKey: 0);
    _followersPagingController =
        PagingController<int, UserProfile>(firstPageKey: 0);

    // Add page request listeners
    _friendsPagingController.addPageRequestListener((pageKey) {
      _fetchFriendsPage(pageKey);
    });
    _followingPagingController.addPageRequestListener((pageKey) {
      _fetchFollowingPage(pageKey);
    });
    _followersPagingController.addPageRequestListener((pageKey) {
      _fetchFollowersPage(pageKey);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _friendsPagingController.dispose();
    _followingPagingController.dispose();
    _followersPagingController.dispose();
    super.dispose();
  }

  // Get current paging controller based on tab
  PagingController<int, UserProfile> get _currentPagingController {
    switch (_tabController.index) {
      case 0:
        return _friendsPagingController;
      case 1:
        return _followingPagingController;
      case 2:
        return _followersPagingController;
      default:
        return _friendsPagingController;
    }
  }

  Future<void> _fetchFriendsPage(int pageKey) async {
    try {
      final friends = await _friendsService.getFriendsList(
        limit: 20,
        offset: pageKey,
      );

      final isLastPage = friends.length < 20;
      if (isLastPage) {
        _friendsPagingController.appendLastPage(friends);
      } else {
        _friendsPagingController.appendPage(friends, pageKey + friends.length);
      }
    } catch (error) {
      _friendsPagingController.error = error;
      ProductionLogger.info('Error loading friends: $error',
          tag: 'friends_list_screen');
    }
  }

  Future<void> _fetchFollowingPage(int pageKey) async {
    try {
      final following = await _friendsService.getFollowingList(
        limit: 20,
        offset: pageKey,
      );

      final isLastPage = following.length < 20;
      if (isLastPage) {
        _followingPagingController.appendLastPage(following);
      } else {
        _followingPagingController.appendPage(
            following, pageKey + following.length);
      }
    } catch (error) {
      _followingPagingController.error = error;
      ProductionLogger.info('Error loading following: $error',
          tag: 'friends_list_screen');
    }
  }

  Future<void> _fetchFollowersPage(int pageKey) async {
    try {
      final followers = await _friendsService.getFollowersList(
        limit: 20,
        offset: pageKey,
      );

      final isLastPage = followers.length < 20;
      if (isLastPage) {
        _followersPagingController.appendLastPage(followers);
      } else {
        _followersPagingController.appendPage(
            followers, pageKey + followers.length);
      }
    } catch (error) {
      _followersPagingController.error = error;
      ProductionLogger.info('Error loading followers: $error',
          tag: 'friends_list_screen');
    }
  }

  Future<void> _loadAllData() async {
    // Refresh all paging controllers
    _friendsPagingController.refresh();
    _followingPagingController.refresh();
    _followersPagingController.refresh();
  }

  Future<void> _toggleFollow(UserProfile user, bool isFollowing) async {
    try {
      if (isFollowing) {
        await _userService.unfollowUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã bỏ theo dõi ${user.displayName}')),
          );
        }
      } else {
        await _userService.followUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã theo dõi ${user.displayName}')),
          );
        }
      }
      // Reload all lists
      await _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        title: app_theme.AppBarTheme.buildGradientTitle('Kết nối'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn bè'),
                  if ((_friendsPagingController.itemList?.length ?? 0) > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_friendsPagingController.itemList?.length ?? 0}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đang theo dõi'),
                  if ((_followingPagingController.itemList?.length ?? 0) >
                      0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_followingPagingController.itemList?.length ?? 0}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Người theo dõi'),
                  if ((_followersPagingController.itemList?.length ?? 0) >
                      0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_followersPagingController.itemList?.length ?? 0}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildFollowingTab(),
          _buildFollowersTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return RefreshIndicator(
      onRefresh: () async => _friendsPagingController.refresh(),
      child: PagedListView<int, UserProfile>(
        pagingController: _friendsPagingController,
        padding: EdgeInsets.all(2.w),
        builderDelegate: PagedChildBuilderDelegate<UserProfile>(
          itemBuilder: (context, friend, index) {
            return _buildUserTile(
              friend,
              trailing: AppButton(
                label: 'Bỏ theo dõi',
                type: AppButtonType.outline,
                size: AppButtonSize.small,
                customColor: Colors.red,
                onPressed: () => _toggleFollow(friend, true),
              ),
            );
          },
          firstPageProgressIndicatorBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
          newPageProgressIndicatorBuilder: (context) => const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )),
          noItemsFoundIndicatorBuilder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                SizedBox(height: 2.h),
                Text(
                  'Chưa có bạn bè',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Bạn bè = người theo dõi lẫn nhau',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowingTab() {
    return RefreshIndicator(
      onRefresh: () async => _followingPagingController.refresh(),
      child: PagedListView<int, UserProfile>(
        pagingController: _followingPagingController,
        padding: EdgeInsets.all(2.w),
        builderDelegate: PagedChildBuilderDelegate<UserProfile>(
          itemBuilder: (context, user, index) {
            final isFriend = _friendsPagingController.itemList
                    ?.any((f) => f.id == user.id) ??
                false;

            return _buildUserTile(
              user,
              trailing: isFriend
                  ? Chip(
                      label: const Text('Bạn bè'),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () => _toggleFollow(user, true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Bỏ theo dõi'),
                    ),
            );
          },
          firstPageProgressIndicatorBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
          newPageProgressIndicatorBuilder: (context) => const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )),
          noItemsFoundIndicatorBuilder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_outlined,
                    size: 80, color: Colors.grey[300]),
                SizedBox(height: 2.h),
                Text(
                  'Chưa theo dõi ai',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowersTab() {
    return RefreshIndicator(
      onRefresh: () async => _followersPagingController.refresh(),
      child: PagedListView<int, UserProfile>(
        pagingController: _followersPagingController,
        padding: EdgeInsets.all(2.w),
        builderDelegate: PagedChildBuilderDelegate<UserProfile>(
          itemBuilder: (context, user, index) {
            final isFriend = _friendsPagingController.itemList
                    ?.any((f) => f.id == user.id) ??
                false;
            final isFollowing = _followingPagingController.itemList
                    ?.any((f) => f.id == user.id) ??
                false;

            return _buildUserTile(
              user,
              trailing: isFriend
                  ? Chip(
                      label: const Text('Bạn bè'),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : isFollowing
                      ? OutlinedButton(
                          onPressed: () => _toggleFollow(user, true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Bỏ theo dõi'),
                        )
                      : AppButton(
                          label: 'Theo dõi lại',
                          type: AppButtonType.primary,
                          size: AppButtonSize.small,
                          onPressed: () => _toggleFollow(user, false),
                        ),
            );
          },
          firstPageProgressIndicatorBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
          newPageProgressIndicatorBuilder: (context) => const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )),
          noItemsFoundIndicatorBuilder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                SizedBox(height: 2.h),
                Text(
                  'Chưa có người theo dõi',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(UserProfile user, {Widget? trailing}) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.w),
      child: ListTile(
        leading: AvatarWithQuickFollow(
          userId: user.id,
          avatarUrl: user.avatarUrl,
          size: 56,
          showQuickFollow: true,
          onFollowChanged: () {
            // Reload lists after follow/unfollow
            _loadAllData();
          },
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: user.bio != null && user.bio!.isNotEmpty
            ? Text(user.bio!, maxLines: 1, overflow: TextOverflow.ellipsis)
            : Text(user.email),
        trailing: trailing,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherUserProfileScreen(
              userId: user.id,
              userName: user.displayName,
            ),
          ),
        ),
      ),
    );
  }
}
