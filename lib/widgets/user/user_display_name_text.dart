import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

/// 📝 UserDisplayNameText - Unified User Name Display
///
/// **Single source of truth** cho việc hiển thị tên user trong toàn bộ app.
///
/// ## Priority Logic:
/// 0. ✅ `userProfile` model (Strongly typed)
/// 1. ✅ `display_name` (snake_case từ Supabase)
/// 2. ✅ `displayName` (camelCase từ model)
/// 3. ✅ `full_name` (snake_case từ Supabase)
/// 4. ✅ `fullName` (camelCase từ model)
/// 5. ⚠️ Fallback: 'Unknown User'
///
/// ## Features:
/// - ✅ Handles both snake_case và camelCase field names
/// - ✅ Auto truncate với ellipsis
/// - ✅ Optional verified badge
/// - ✅ Null-safe
/// - ✅ Consistent styling
///
/// ## Usage:
/// ```dart
/// // Basic name
/// UserDisplayNameText(
///   userData: {'display_name': 'John Doe'},
/// )
///
/// // With Model
/// UserDisplayNameText(
///   userProfile: myUserProfile,
/// )
///
/// // With verified badge
/// UserDisplayNameText(
///   userData: userMap,
///   showVerifiedBadge: true,
///   maxLength: 20,
/// )
/// ```
class UserDisplayNameText extends StatelessWidget {
  /// User data map (có thể từ Supabase query hoặc UserProfile.toJson())
  final Map<String, dynamic>? userData;

  /// User Profile Model (Strongly typed)
  final UserProfile? userProfile;

  /// Text style (nếu null sẽ dùng default)
  final TextStyle? style;

  /// Max length trước khi truncate (null = không truncate)
  final int? maxLength;

  /// Hiển thị verified badge icon
  final bool showVerifiedBadge;

  /// Custom verified badge icon
  final Widget? customVerifiedBadge;

  /// Fallback text khi không có tên
  final String fallbackText;

  /// Text overflow behavior
  final TextOverflow overflow;

  /// Max lines
  final int? maxLines;

  const UserDisplayNameText({
    super.key,
    this.userData,
    this.userProfile,
    this.style,
    this.maxLength,
    this.showVerifiedBadge = false,
    this.customVerifiedBadge,
    this.fallbackText = 'Unknown User',
    this.overflow = TextOverflow.ellipsis,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = _getDisplayName();
    final truncated = _truncateName(displayName);

    if (!showVerifiedBadge || !_isVerified()) {
      return Text(
        truncated,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    // With verified badge
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            truncated,
            style: style,
            overflow: overflow,
            maxLines: maxLines,
          ),
        ),
        const SizedBox(width: 4),
        customVerifiedBadge ??
            const Icon(
              Icons.verified,
              size: 16,
              color: Colors.blue,
            ),
      ],
    );
  }

  /// Get display name with priority logic
  String _getDisplayName() {
    // Priority 0: UserProfile Model
    if (userProfile != null) {
      if (_isValidName(userProfile!.displayName))
        return userProfile!.displayName;
      if (_isValidName(userProfile!.fullName)) return userProfile!.fullName;
      if (_isValidName(userProfile!.username)) return userProfile!.username!;
    }

    if (userData == null) return fallbackText;

    // Priority 1: display_name (snake_case)
    String? name = userData!['display_name']?.toString().trim();
    if (_isValidName(name)) return name!;

    // Priority 2: displayName (camelCase)
    name = userData!['displayName']?.toString().trim();
    if (_isValidName(name)) return name!;

    // Priority 3: full_name (snake_case)
    name = userData!['full_name']?.toString().trim();
    if (_isValidName(name)) return name!;

    // Priority 4: fullName (camelCase)
    name = userData!['fullName']?.toString().trim();
    if (_isValidName(name)) return name!;

    // Priority 5: username (snake_case)
    name = userData!['username']?.toString().trim();
    if (_isValidName(name)) return name!;

    // Priority 6: userName (camelCase)
    name = userData!['userName']?.toString().trim();
    if (_isValidName(name)) return name!;

    // Fallback
    return fallbackText;
  }

  /// Check if name is valid (not null, not empty, not "User")
  bool _isValidName(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    final lower = name.trim().toLowerCase();
    if (lower == 'user') return false;
    if (lower == 'unknown') return false;
    if (lower == 'unknown user') return false;
    if (lower == 'người dùng') return false;
    return true;
  }

  /// Truncate name if exceeds maxLength
  String _truncateName(String name) {
    if (maxLength == null || name.length <= maxLength!) {
      return name;
    }
    return '${name.substring(0, maxLength!)}...';
  }

  /// Check if user is verified
  bool _isVerified() {
    if (userProfile != null) {
      return userProfile!.isVerified;
    }
    if (userData == null) return false;
    return userData!['is_verified'] == true || userData!['isVerified'] == true;
  }
}

/// 📝 UserDisplayNameHelper - Static helper cho các trường hợp không dùng Widget
///
/// Dùng cho các trường hợp cần lấy tên dạng String thay vì Widget
class UserDisplayNameHelper {
  /// Get display name as String
  static String getDisplayName(
    Map<String, dynamic>? userData, {
    String fallback = 'Unknown User',
  }) {
    if (userData == null) return fallback;

    // Priority 1: display_name
    String? name = userData['display_name']?.toString().trim();
    if (_isValidName(name)) return name!;

    // Priority 2: displayName
    name = userData['displayName']?.toString().trim();
    if (_isValidName(name)) return name!;

    // Priority 3: full_name
    name = userData['full_name']?.toString().trim();
    if (_isValidName(name)) return name!;

    // Priority 4: fullName
    name = userData['fullName']?.toString().trim();
    if (_isValidName(name)) return name!;

    // Priority 5: username
    name = userData['username']?.toString().trim();
    if (_isValidName(name)) return name!;

    // Priority 6: userName
    name = userData['userName']?.toString().trim();
    if (_isValidName(name)) return name!;

    return fallback;
  }

  /// Get short display name (truncated)
  static String getShortDisplayName(
    Map<String, dynamic>? userData, {
    int maxLength = 15,
    String fallback = 'Unknown User',
  }) {
    final name = getDisplayName(userData, fallback: fallback);
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength)}...';
  }

  /// Get first name only
  static String getFirstName(
    Map<String, dynamic>? userData, {
    String fallback = 'Unknown',
  }) {
    final fullName = getDisplayName(userData, fallback: fallback);
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.first : fallback;
  }

  /// Get initials (e.g., "John Doe" -> "JD")
  static String getInitials(
    Map<String, dynamic>? userData, {
    String fallback = '?',
  }) {
    final fullName = getDisplayName(userData, fallback: fallback);
    final parts = fullName.split(' ');

    if (parts.isEmpty) return fallback;
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : fallback;
    }

    // Take first letter of first and last name
    return '${parts.first[0].toUpperCase()}${parts.last[0].toUpperCase()}';
  }

  /// Get username with @ prefix (for profile screen only)
  static String? getUsername(
    Map<String, dynamic>? userData, {
    bool withAtSign = true,
  }) {
    if (userData == null) return null;

    final username = userData['username']?.toString().trim() ??
        userData['userName']?.toString().trim();

    if (username == null || username.isEmpty) return null;

    return withAtSign ? '@$username' : username;
  }

  /// Check if user is verified
  static bool isVerified(Map<String, dynamic>? userData) {
    if (userData == null) return false;
    return userData['is_verified'] == true || userData['isVerified'] == true;
  }

  /// Validate name helper
  static bool _isValidName(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    final lower = name.trim().toLowerCase();
    if (lower == 'user') return false;
    if (lower == 'unknown') return false;
    if (lower == 'unknown user') return false;
    if (lower == 'người dùng') return false;
    return true;
  }
}

/// 📝 UserNameWithUsername - Display name + username (for profile screens)
///
/// Hiển thị tên + username dạng @username ở dưới (như Instagram/Twitter)
class UserNameWithUsername extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final TextStyle? nameStyle;
  final TextStyle? usernameStyle;
  final bool showVerifiedBadge;

  const UserNameWithUsername({
    super.key,
    this.userData,
    this.nameStyle,
    this.usernameStyle,
    this.showVerifiedBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final username = UserDisplayNameHelper.getUsername(userData);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Display name
        UserDisplayNameText(
          userData: userData,
          style: nameStyle ??
              const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
          showVerifiedBadge: showVerifiedBadge,
        ),

        // Username (if exists)
        if (username != null) ...[
          const SizedBox(height: 2),
          Text(
            username,
            style: usernameStyle ??
                TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
          ),
        ],
      ],
    );
  }
}
