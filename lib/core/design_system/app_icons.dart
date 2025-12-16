/// Icon System - Centralized Icons
///
/// Single source of truth for all icons used in the app:
/// - Navigation icons
/// - Action icons
/// - Social icons
/// - Status icons
/// - Custom icon sizes
///
/// Makes it easy to switch icon packs or customize icons consistently

import 'package:flutter/material.dart';

/// Icon system for SABO ARENA
///
/// All icons should be referenced through this class
/// to ensure consistency and easy customization
class AppIcons {
  AppIcons._(); // Private constructor

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  /// Extra small icon (12px) - inline icons, dense UI
  static const double sizeXS = 12.0;

  /// Small icon (16px) - compact lists, badges
  static const double sizeSM = 16.0;

  /// Medium icon (20px) - standard UI elements
  static const double sizeMD = 20.0;

  /// Large icon (24px) - buttons, tabs (default)
  static const double sizeLG = 24.0;

  /// Extra large icon (32px) - emphasized actions
  static const double sizeXL = 32.0;

  /// XXL icon (40px) - large touch targets
  static const double sizeXXL = 40.0;

  /// Huge icon (48px) - hero icons
  static const double sizeHuge = 48.0;

  /// Massive icon (64px) - splash screens, empty states
  static const double sizeMassive = 64.0;

  // ============================================================================
  // NAVIGATION ICONS
  // ============================================================================

  /// Home icon
  static const IconData home = Icons.home_rounded;
  static const IconData homeOutlined = Icons.home_outlined;

  /// Search icon
  static const IconData search = Icons.search_rounded;

  /// Explore/Discover icon
  static const IconData explore = Icons.explore_rounded;
  static const IconData exploreOutlined = Icons.explore_outlined;

  /// Notifications icon
  static const IconData notifications = Icons.notifications_rounded;
  static const IconData notificationsOutlined = Icons.notifications_outlined;

  /// Profile/Account icon
  static const IconData profile = Icons.account_circle_rounded;
  static const IconData profileOutlined = Icons.account_circle_outlined;

  /// Menu icon
  static const IconData menu = Icons.menu_rounded;

  /// More options icon
  static const IconData more = Icons.more_vert_rounded;
  static const IconData moreHoriz = Icons.more_horiz_rounded;

  /// Back icon
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData backIOS = Icons.arrow_back_ios_rounded;

  /// Forward icon
  static const IconData forward = Icons.arrow_forward_rounded;
  static const IconData forwardIOS = Icons.arrow_forward_ios_rounded;

  /// Close icon
  static const IconData close = Icons.close_rounded;

  /// Settings icon
  static const IconData settings = Icons.settings_rounded;
  static const IconData settingsOutlined = Icons.settings_outlined;

  // ============================================================================
  // ACTION ICONS
  // ============================================================================

  /// Add icon
  static const IconData add = Icons.add_rounded;
  static const IconData addCircle = Icons.add_circle_rounded;
  static const IconData addCircleOutlined = Icons.add_circle_outline_rounded;

  /// Remove icon
  static const IconData remove = Icons.remove_rounded;
  static const IconData removeCircle = Icons.remove_circle_rounded;

  /// Edit icon
  static const IconData edit = Icons.edit_rounded;
  static const IconData editOutlined = Icons.edit_outlined;

  /// Delete icon
  static const IconData delete = Icons.delete_rounded;
  static const IconData deleteOutlined = Icons.delete_outlined;

  /// Save icon
  static const IconData save = Icons.save_rounded;
  static const IconData saveOutlined = Icons.save_outlined;

  /// Share icon
  static const IconData share = Icons.share_rounded;

  /// Send icon
  static const IconData send = Icons.send_rounded;

  /// Download icon
  static const IconData download = Icons.download_rounded;

  /// Upload icon
  static const IconData upload = Icons.upload_rounded;

  /// Copy icon
  static const IconData copy = Icons.copy_rounded;

  /// Paste icon
  static const IconData paste = Icons.content_paste_rounded;

  /// Cut icon
  static const IconData cut = Icons.content_cut_rounded;

  /// Undo icon
  static const IconData undo = Icons.undo_rounded;

  /// Redo icon
  static const IconData redo = Icons.redo_rounded;

  /// Refresh icon
  static const IconData refresh = Icons.refresh_rounded;

  /// Filter icon
  static const IconData filter = Icons.filter_list_rounded;

  /// Sort icon
  static const IconData sort = Icons.sort_rounded;

  // ============================================================================
  // SOCIAL ICONS (Billiards/Sports specific)
  // ============================================================================

  /// Like/Favorite icon
  static const IconData like = Icons.favorite_rounded;
  static const IconData likeOutlined = Icons.favorite_border_rounded;

  /// Comment icon
  static const IconData comment = Icons.chat_bubble_rounded;
  static const IconData commentOutlined = Icons.chat_bubble_outline_rounded;

  /// Message/Chat icon
  static const IconData message = Icons.message_rounded;
  static const IconData messageOutlined = Icons.message_outlined;

  /// Follow/Add user icon
  static const IconData follow = Icons.person_add_rounded;
  static const IconData followOutlined = Icons.person_add_outlined;
  static const IconData personAdd = Icons.person_add_rounded;

  /// Following/Friends icon
  static const IconData following = Icons.people_rounded;
  static const IconData followingOutlined = Icons.people_outlined;

  /// People icon
  static const IconData people = Icons.people_rounded;

  /// Group/Club icon
  static const IconData group = Icons.groups_rounded;
  static const IconData groupOutlined = Icons.groups_outlined;

  /// Event/Calendar icon
  static const IconData event = Icons.event_rounded;
  static const IconData eventOutlined = Icons.event_outlined;

  /// Trophy/Award icon
  static const IconData trophy = Icons.emoji_events_rounded;
  static const IconData trophyOutlined = Icons.emoji_events_outlined;

  /// Star/Rating icon
  static const IconData star = Icons.star_rounded;
  static const IconData starOutlined = Icons.star_outline_rounded;
  static const IconData starHalf = Icons.star_half_rounded;

  /// Verified/Badge icon
  static const IconData verified = Icons.verified_rounded;
  static const IconData verifiedOutlined = Icons.verified_outlined;

  /// Bookmark icon
  static const IconData bookmark = Icons.bookmark_rounded;
  static const IconData bookmarkOutlined = Icons.bookmark_outline_rounded;

  // ============================================================================
  // CONTENT ICONS
  // ============================================================================

  /// Camera icon
  static const IconData camera = Icons.camera_alt_rounded;
  static const IconData cameraOutlined = Icons.camera_alt_outlined;

  /// Photo/Image icon
  static const IconData photo = Icons.photo_rounded;
  static const IconData photoOutlined = Icons.photo_outlined;

  /// Video icon
  static const IconData video = Icons.videocam_rounded;
  static const IconData videoOutlined = Icons.videocam_outlined;

  /// Play icon
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData playCircle = Icons.play_circle_rounded;
  static const IconData playArrow = Icons.play_arrow_rounded;

  /// Pause icon
  static const IconData pause = Icons.pause_rounded;
  static const IconData pauseCircle = Icons.pause_circle_rounded;

  /// Stop icon
  static const IconData stop = Icons.stop_rounded;
  static const IconData stopCircle = Icons.stop_circle_rounded;

  /// Mic icon
  static const IconData mic = Icons.mic_rounded;
  static const IconData micOff = Icons.mic_off_rounded;

  /// Volume icon
  static const IconData volume = Icons.volume_up_rounded;
  static const IconData volumeOff = Icons.volume_off_rounded;

  /// Attachment icon
  static const IconData attachment = Icons.attach_file_rounded;

  /// PDF icon
  static const IconData pdf = Icons.picture_as_pdf_rounded;

  /// Link icon
  static const IconData link = Icons.link_rounded;

  // ============================================================================
  // STATUS ICONS
  // ============================================================================

  /// Success/Check icon
  static const IconData success = Icons.check_circle_rounded;
  static const IconData successOutlined = Icons.check_circle_outline_rounded;
  static const IconData check = Icons.check_rounded;

  /// Error/Warning icon
  static const IconData error = Icons.error_rounded;
  static const IconData errorOutlined = Icons.error_outline_rounded;

  /// Warning icon
  static const IconData warning = Icons.warning_rounded;
  static const IconData warningOutlined = Icons.warning_outlined;

  /// Info icon
  static const IconData info = Icons.info_rounded;
  static const IconData infoOutlined = Icons.info_outlined;

  /// Help icon
  static const IconData help = Icons.help_rounded;
  static const IconData helpOutlined = Icons.help_outlined;

  /// Online/Active icon
  static const IconData online = Icons.fiber_manual_record_rounded;

  /// Offline icon
  static const IconData offline = Icons.circle_outlined;

  /// Loading/Pending icon
  static const IconData loading = Icons.hourglass_empty_rounded;

  // ============================================================================
  // LOCATION & MAP ICONS
  // ============================================================================

  /// Location icon
  static const IconData location = Icons.location_on_rounded;
  static const IconData locationOutlined = Icons.location_on_outlined;

  /// Map icon
  static const IconData map = Icons.map_rounded;
  static const IconData mapOutlined = Icons.map_outlined;

  /// Navigation/Directions icon
  static const IconData directions = Icons.directions_rounded;

  /// Pin/Place icon
  static const IconData pin = Icons.place_rounded;

  // ============================================================================
  // TIME & DATE ICONS
  // ============================================================================

  /// Clock/Time icon
  static const IconData clock = Icons.access_time_rounded;

  /// Calendar/Date icon
  static const IconData calendar = Icons.calendar_today_rounded;

  /// Schedule icon
  static const IconData schedule = Icons.schedule_rounded;

  /// History icon
  static const IconData history = Icons.history_rounded;

  // ============================================================================
  // FORM & INPUT ICONS
  // ============================================================================

  /// Visibility on icon
  static const IconData visibility = Icons.visibility_rounded;

  /// Visibility off icon
  static const IconData visibilityOff = Icons.visibility_off_rounded;

  /// Email icon
  static const IconData email = Icons.email_rounded;
  static const IconData emailOutlined = Icons.email_outlined;

  /// Phone icon
  static const IconData phone = Icons.phone_rounded;
  static const IconData phoneOutlined = Icons.phone_outlined;

  /// Lock icon
  static const IconData lock = Icons.lock_rounded;
  static const IconData lockOutlined = Icons.lock_outlined;

  /// Unlock icon
  static const IconData unlock = Icons.lock_open_rounded;

  /// Key icon
  static const IconData key = Icons.key_rounded;

  // ============================================================================
  // ARROW & CHEVRON ICONS
  // ============================================================================

  /// Arrow up
  static const IconData arrowUp = Icons.arrow_upward_rounded;

  /// Arrow down
  static const IconData arrowDown = Icons.arrow_downward_rounded;

  /// Arrow left
  static const IconData arrowLeft = Icons.arrow_back_rounded;

  /// Arrow right
  static const IconData arrowRight = Icons.arrow_forward_rounded;
  static const IconData arrowForward = Icons.arrow_forward_rounded;

  /// Chevron up
  static const IconData chevronUp = Icons.keyboard_arrow_up_rounded;

  /// Chevron down
  static const IconData chevronDown = Icons.keyboard_arrow_down_rounded;

  /// Chevron left
  static const IconData chevronLeft = Icons.keyboard_arrow_left_rounded;

  /// Chevron right
  static const IconData chevronRight = Icons.keyboard_arrow_right_rounded;

  /// Expand more
  static const IconData expandMore = Icons.expand_more_rounded;

  /// Expand less
  static const IconData expandLess = Icons.expand_less_rounded;

  // ============================================================================
  // BILLIARDS SPECIFIC ICONS (Custom or placeholder)
  // ============================================================================

  /// Ball/Billiards icon (using sports_handball as placeholder)
  static const IconData ball = Icons.sports_handball_rounded;

  /// Cue stick icon (using sports_golf as placeholder)
  static const IconData cue = Icons.sports_golf_rounded;

  /// Table/Arena icon
  static const IconData table = Icons.table_restaurant_rounded;

  /// Match/Game icon
  static const IconData match = Icons.sports_rounded;

  /// Tournament icon
  static const IconData tournament = Icons.emoji_events_rounded;

  /// Ranking/Leaderboard icon
  static const IconData ranking = Icons.leaderboard_rounded;

  /// Score icon
  static const IconData score = Icons.scoreboard_rounded;

  /// Practice icon
  static const IconData practice = Icons.fitness_center_rounded;

  // ============================================================================
  // MISCELLANEOUS ICONS
  // ============================================================================

  /// Dashboard icon
  static const IconData dashboard = Icons.dashboard_rounded;
  static const IconData dashboardOutlined = Icons.dashboard_outlined;

  /// List icon
  static const IconData list = Icons.list_rounded;

  /// Grid icon
  static const IconData grid = Icons.grid_view_rounded;

  /// Tag icon
  static const IconData tag = Icons.local_offer_rounded;

  /// Report/Flag icon
  static const IconData report = Icons.flag_rounded;
  static const IconData reportOutlined = Icons.flag_outlined;

  /// Block icon
  static const IconData block = Icons.block_rounded;

  /// Logout icon
  static const IconData logout = Icons.logout_rounded;

  /// Login icon
  static const IconData login = Icons.login_rounded;

  /// QR code icon
  static const IconData qrCode = Icons.qr_code_rounded;

  /// Barcode icon
  static const IconData barcode = Icons.qr_code_scanner_rounded;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get icon size based on named size
  static double getSize(String size) {
    switch (size.toLowerCase()) {
      case 'xs':
        return sizeXS;
      case 'sm':
      case 'small':
        return sizeSM;
      case 'md':
      case 'medium':
        return sizeMD;
      case 'lg':
      case 'large':
        return sizeLG;
      case 'xl':
        return sizeXL;
      case 'xxl':
        return sizeXXL;
      case 'huge':
        return sizeHuge;
      case 'massive':
        return sizeMassive;
      default:
        return sizeLG; // Default
    }
  }

  /// Create Icon widget with size
  static Icon icon(IconData iconData, {double? size, Color? color}) {
    return Icon(iconData, size: size ?? sizeLG, color: color);
  }
}
