// Supabase Configuration
// ⚠️ SECURITY: DO NOT HARDCODE CREDENTIALS
// Use environment variables via SupabaseService instead

class SupabaseConfig {
  // ⚠️ DEPRECATED: Do not use hardcoded credentials
  // Use SupabaseService.instance or environment variables instead
  
  // Storage bucket names (safe to keep as constants)
  static const String avatarsBucket = 'avatars';
  static const String tournamentImagesBucket = 'tournament-images';
  static const String postImagesBucket = 'post-images';

  // Database table names (safe to keep as constants)
  static const String usersTable = 'users';
  static const String clubsTable = 'clubs';
  static const String tournamentsTable = 'tournaments';
  static const String matchesTable = 'matches';
  static const String postsTable = 'posts';
  static const String commentsTable = 'comments';

  // Real-time channels (safe to keep as constants)
  static const String matchesChannel = 'matches-updates';
  static const String tournamentsChannel = 'tournaments-updates';
  static const String postsChannel = 'posts-updates';
}
