import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_bar_theme.dart' as app_theme;

import '../../models/user_profile.dart';
import '../../services/friends_service.dart';
import '../../services/user_service.dart';
import '../../widgets/avatar_with_quick_follow.dart';
import '../other_user_profile_screen/other_user_profile_screen.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

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

  List<UserProfile> _friends = [];
  List<UserProfile> _following = [];
  List<UserProfile> _followers = [];

  bool _isLoadingFriends = true;
  bool _isLoadingFollowing = true;
  bool _isLoadingFollowers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadFriends(), _loadFollowing(), _loadFollowers()]);
  }

  Future<void> _loadFriends() async {
    try {
      setState(() => _isLoadingFriends = true);
      final friends = await _friendsService.getFriendsList();
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoadingFriends = false;
        });
      }
    } catch (e) {
      ProductionLogger.info('Error loading friends: $e', tag: 'friends_list_screen');
      if (mounted) {
        setState(() => _isLoadingFriends = false);
      }
    }
  }

  Future<void> _loadFollowing() async {
    try {
      setState(() => _isLoadingFollowing = true);
      final following = await _friendsService.getFollowingList();
      if (mounted) {
        setState(() {
          _following = following;
          _isLoadingFollowing = false;
        });
      }
    } catch (e) {
      ProductionLogger.info('Error loading following: $e', tag: 'friends_list_screen');
      if (mounted) {
        setState(() => _isLoadingFollowing = false);
      }
    }
  }

  Future<void> _loadFollowers() async {
    try {
      setState(() => _isLoadingFollowers = true);
      final followers = await _friendsService.getFollowersList();
      if (mounted) {
        setState(() {
          _followers = followers;
          _isLoadingFollowers = false;
        });
      }
    } catch (e) {
      ProductionLogger.info('Error loading followers: $e', tag: 'friends_list_screen');
      if (mounted) {
        setState(() => _isLoadingFollowers = false);
      }
    }
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
                  if (_friends.isNotEmpty) ...[
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
                        '${_friends.length}', overflow: TextOverflow.ellipsis, style: const TextStyle(
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
                  if (_following.isNotEmpty) ...[
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
                        '${_following.length}', overflow: TextOverflow.ellipsis, style: const TextStyle(
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
                  if (_followers.isNotEmpty) ...[
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
                        '${_followers.length}', overflow: TextOverflow.ellipsis, style: const TextStyle(
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
    if (_isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
            SizedBox(height: 2.h),
            Text(
              'Chưa có bạn bè', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 1.h),
            Text(
              'Bạn bè = người theo dõi lẫn nhau', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildUserTile(
            friend,
            trailing: OutlinedButton(
              onPressed: () => _toggleFollow(friend, true),
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
      ),
    );
  }

  Widget _buildFollowingTab() {
    if (_isLoadingFollowing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, size: 80, color: Colors.grey[300]),
            SizedBox(height: 2.h),
            Text(
              'Chưa theo dõi ai', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowing,
      child: ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: _following.length,
        itemBuilder: (context, index) {
          final user = _following[index];
          final isFriend = _friends.any((f) => f.id == user.id);

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
      ),
    );
  }

  Widget _buildFollowersTab() {
    if (_isLoadingFollowers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
            SizedBox(height: 2.h),
            Text(
              'Chưa có người theo dõi', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          final user = _followers[index];
          final isFriend = _friends.any((f) => f.id == user.id);
          final isFollowing = _following.any((f) => f.id == user.id);

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
                : ElevatedButton(
                    onPressed: () => _toggleFollow(user, false),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Theo dõi lại'),
                  ),
          );
        },
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
          user.displayName, style: const TextStyle(fontWeight: FontWeight.bold),
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
