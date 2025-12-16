/// Utility for getting user display name
///
/// Priority: displayName > fullName (NEVER username except in profile)
class UserDisplayName {
  /// Get display name from UserProfile object
  static String fromUserProfile(dynamic userProfile) {
    if (userProfile == null) return 'Unknown User';

    // Try displayName first
    final displayName = userProfile.displayName;
    if (displayName != null && displayName.toString().trim().isNotEmpty) {
      return displayName.toString().trim();
    }

    // Fall back to fullName
    final fullName = userProfile.fullName;
    if (fullName != null && fullName.toString().trim().isNotEmpty) {
      return fullName.toString().trim();
    }

    return 'Unknown User';
  }

  /// Get display name from Map data
  static String fromMap(Map<String, dynamic> data) {
    // Try display_name or displayName first
    final displayName = data['display_name'] ?? data['displayName'];
    if (displayName != null && displayName.toString().trim().isNotEmpty) {
      return displayName.toString().trim();
    }

    // Fall back to full_name or fullName
    final fullName = data['full_name'] ?? data['fullName'];
    if (fullName != null && fullName.toString().trim().isNotEmpty) {
      return fullName.toString().trim();
    }

    return 'Unknown User';
  }

  /// Get username for profile display only
  static String getUsername(Map<String, dynamic> data) {
    final username = data['username'];
    if (username != null && username.toString().trim().isNotEmpty) {
      return '@${username.toString().trim()}';
    }
    return '';
  }
}
