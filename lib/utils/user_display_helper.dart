/// Utility functions for user data formatting
/// Provides consistent user display name across the app

class UserDisplayHelper {
  /// Get user display name with proper fallback priority:
  /// 1. display_name (if exists and not empty)
  /// 2. full_name (if exists and not empty)
  /// 3. username (if exists, show as @username)
  /// 4. email (show first part before @)
  /// 5. Fallback to 'Người dùng'
  static String getDisplayName(Map<String, dynamic>? userData, {String? fallback}) {
    if (userData == null) return fallback ?? 'Người dùng';
    
    // 1. Try display_name first (preferred)
    final displayName = userData['display_name']?.toString().trim();
    if (displayName != null && displayName.isNotEmpty && displayName.toLowerCase() != 'user') {
      return displayName;
    }
    
    // 2. Try full_name
    final fullName = userData['full_name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty && fullName.toLowerCase() != 'user') {
      return fullName;
    }
    
    // 3. Try username (show as @username)
    final username = userData['username']?.toString().trim();
    if (username != null && username.isNotEmpty) {
      return '@$username';
    }
    
    // 4. Try email (show first part)
    final email = userData['email']?.toString().trim();
    if (email != null && email.contains('@')) {
      return email.split('@')[0];
    }
    
    // 5. Last resort fallback
    return fallback ?? 'Người dùng';
  }
  
  /// Get user display name from user ID (for mentions, tags, etc.)
  /// Useful when you only have partial user data
  static String getNameFromId(Map<String, dynamic>? userData) {
    if (userData == null) return 'Unknown User';
    
    final name = getDisplayName(userData);
    if (name != 'Người dùng') return name;
    
    // If still "Người dùng", try to show partial ID
    final id = userData['id']?.toString();
    if (id != null && id.length >= 8) {
      return 'User ${id.substring(0, 8)}...';
    }
    
    return 'Unknown User';
  }
  
  /// Get short display name (max 15 chars)
  /// Useful for compact UI like avatars, cards
  static String getShortDisplayName(Map<String, dynamic>? userData, {int maxLength = 15}) {
    final name = getDisplayName(userData);
    
    if (name.length <= maxLength) return name;
    
    return '${name.substring(0, maxLength - 3)}...';
  }
  
  /// Get initials for avatar (2 chars)
  /// Example: "Nguyen Van A" -> "NA"
  static String getInitials(Map<String, dynamic>? userData) {
    final name = getDisplayName(userData);
    
    if (name == 'Người dùng' || name == 'Unknown User') return '?';
    
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    
    return name.substring(0, 1).toUpperCase();
  }
}
