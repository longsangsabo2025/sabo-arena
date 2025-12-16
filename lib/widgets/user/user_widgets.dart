/// 👤 User Widgets - Unified User Display Components
///
/// Tất cả components chuẩn để hiển thị thông tin user trong app.
///
/// ## Exports:
/// - `UserAvatarWidget` - Avatar với caching, error handling, rank border
/// - `UserDisplayNameText` - Tên user với priority logic chuẩn
/// - `UserRankBadgeWidget` - Rank badge với 3 styles
/// - `UserProfileCard` - Reusable card cho lists, grids
///
/// ## Usage:
/// ```dart
/// import 'package:sabo_arena/widgets/user/user_widgets.dart';
///
/// UserProfileCard(
///   userData: userMap,
///   showRank: true,
///   showStats: true,
/// )
/// ```

// Avatar Components
export 'user_avatar_widget.dart';

// Display Name Components
export 'user_display_name_text.dart';

// Rank Badge Components
export 'user_rank_badge_widget.dart';

// Profile Card Components
export 'user_profile_card.dart';
