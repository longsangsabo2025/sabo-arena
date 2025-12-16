import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
import '../models/user_profile.dart';
import '../presentation/other_user_profile_screen/other_user_profile_screen.dart';

class ProfileNavigationUtils {
  /// Navigate to user profile screen
  static void navigateToUserProfile(
    BuildContext context,
    UserProfile user, {
    String? heroTag,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OtherUserProfileScreen(userId: user.id, userName: user.fullName),
      ),
    );
  }

  /// Navigate to user profile by ID
  static void navigateToUserProfileById(
    BuildContext context,
    String userId, {
    String? userName,
    String? heroTag,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OtherUserProfileScreen(userId: userId, userName: userName),
      ),
    );
  }

  /// Create a clickable avatar widget
  static Widget buildClickableAvatar({
    required BuildContext context,
    required UserProfile user,
    double radius = 24,
    Color? backgroundColor,
    String? heroTag,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: () => navigateToUserProfile(context, user, heroTag: heroTag),
      child: Hero(
        tag: heroTag ?? 'avatar_${user.id}',
        child: UserAvatarWidget(
          avatarUrl: user.avatarUrl,
          size: radius * 2,
        ),
      ),
    );
  }

  /// Create a clickable avatar from URL and user ID
  static Widget buildClickableAvatarFromId({
    required BuildContext context,
    required String userId,
    String? userName,
    String? avatarUrl,
    double radius = 24,
    Color? backgroundColor,
    String? heroTag,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: () => navigateToUserProfileById(
        context,
        userId,
        userName: userName,
        heroTag: heroTag,
      ),
      child: Hero(
        tag: heroTag ?? 'avatar_$userId',
        child: UserAvatarWidget(
          avatarUrl: avatarUrl,
          size: radius * 2,
        ),
      ),
    );
  }
}
