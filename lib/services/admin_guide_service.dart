import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_guide_models.dart';
import 'package:sabo_arena/utils/production_logger.dart';
// ELON_MODE_AUTO_FIX

/// Service for managing admin guides with auto-update capability
class AdminGuideService {
  static final AdminGuideService _instance = AdminGuideService._internal();
  factory AdminGuideService() => _instance;
  AdminGuideService._internal();

  final _supabase = Supabase.instance.client;
  final String _appVersion = '4.0.0'; // Update this with each release

  // Cache for guides
  List<AdminGuide>? _cachedGuides;
  DateTime? _lastFetchTime;
  final Duration _cacheValidity = const Duration(hours: 1);

  /// Get all guides with caching
  Future<List<AdminGuide>> getAllGuides({bool forceRefresh = false}) async {
    try {
      // Return cache if valid
      if (!forceRefresh &&
          _cachedGuides != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheValidity) {
        return _cachedGuides!;
      }

      // Fetch from hardcoded guides (always up-to-date with code)
      final guides = _getHardcodedGuides();

      // Try to fetch from database for custom guides
      try {
        final response = await _supabase
            .from('admin_guides')
            .select()
            .order('priority', ascending: true);

        final dbGuides = (response as List)
            .map((json) => AdminGuide.fromJson(json))
            .toList();

        // Merge hardcoded and database guides
        guides.addAll(dbGuides);
      } catch (e) {
        // Continue with hardcoded guides only
      }

      _cachedGuides = guides;
      _lastFetchTime = DateTime.now();

      return guides;
    } catch (e) {
      return _getHardcodedGuides(); // Fallback to hardcoded
    }
  }

  /// Get guides by category
  Future<List<AdminGuide>> getGuidesByCategory(GuideCategory category) async {
    final allGuides = await getAllGuides();
    return allGuides.where((g) => g.category == category).toList();
  }

  /// Search guides
  Future<List<AdminGuide>> searchGuides(String query) async {
    if (query.isEmpty) return getAllGuides();

    final allGuides = await getAllGuides();
    final lowerQuery = query.toLowerCase();

    return allGuides.where((guide) {
      return guide.title.toLowerCase().contains(lowerQuery) ||
          guide.description.toLowerCase().contains(lowerQuery) ||
          guide.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Get user's progress for a guide
  Future<GuideProgress?> getGuideProgress(String userId, String guideId) async {
    try {
      final response = await _supabase
          .from('admin_guide_progress')
          .select()
          .eq('user_id', userId)
          .eq('guide_id', guideId)
          .maybeSingle();

      if (response == null) return null;
      return GuideProgress.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update user's progress
  Future<void> updateProgress({
    required String userId,
    required String guideId,
    required int currentStep,
    bool? isCompleted,
  }) async {
    try {
      final progress = GuideProgress(
        userId: userId,
        guideId: guideId,
        currentStep: currentStep,
        isCompleted: isCompleted ?? false,
        completedAt: isCompleted == true ? DateTime.now() : null,
        lastAccessedAt: DateTime.now(),
      );

      await _supabase.from('admin_guide_progress').upsert(progress.toJson());
    } catch (e) {
      ProductionLogger.error('Failed to update guide progress', error: e, tag: 'AdminGuideService');
    }
  }

  /// Mark guide as completed
  Future<void> completeGuide(String userId, String guideId) async {
    await updateProgress(
      userId: userId,
      guideId: guideId,
      currentStep: -1,
      isCompleted: true,
    );
  }

  /// Get contextual help for a screen element
  QuickHelp? getQuickHelp(String screenId, String elementId) {
    return _quickHelpData[screenId]?.firstWhere(
      (help) => help.elementId == elementId,
      orElse: () => QuickHelp(
        screenId: screenId,
        elementId: elementId,
        title: 'Help',
        description: 'No help available for this element.',
      ),
    );
  }

  /// Hardcoded guides that are always synchronized with app code
  /// This ensures guides are ALWAYS up-to-date with latest features
  List<AdminGuide> _getHardcodedGuides() {
    return [
      // NOTIFICATION MANAGEMENT GUIDE
      AdminGuide(
        id: 'notification_management_complete',
        title: 'Hệ thống Quản lý Thông báo',
        description:
            'Hướng dẫn toàn diện về dashboard thông báo, broadcast, scheduling, templates và analytics',
        category: GuideCategory.notifications,
        priority: 1,
        isNew: true,
        version: _appVersion,
        lastUpdated: DateTime(2025, 10, 22),
        estimatedMinutes: 10,
        tags: [
          'notification',
          'broadcast',
          'schedule',
          'template',
          'analytics',
        ],
        steps: [
          GuideStep(
            title: 'Truy cập Dashboard Thông báo',
            description:
                'Dashboard thông báo nằm trong menu "Khác" của Admin. Đây là trung tâm điều khiển toàn bộ hệ thống thông báo.',
            type: GuideStepType.info,
            icon: Icons.notifications_active,
            targetRoute: '/admin_more',
            keyPoints: [
              'Vào Admin Dashboard',
              'Click tab "Khác" ở bottom navigation',
              'Tìm section "Quản lý hệ thống"',
              'Click "Quản lý thông báo" (icon màu cam)',
            ],
          ),
          GuideStep(
            title: 'Dashboard - Theo dõi Thống kê',
            description:
                'Tab Dashboard hiển thị metrics real-time về thông báo đã gửi trong 30 ngày qua.',
            type: GuideStepType.info,
            icon: Icons.dashboard,
            keyPoints: [
              'Total Sent: Tổng số thông báo đã gửi',
              'Read Rate: Tỷ lệ người dùng đã đọc (%)',
              'Click Through Rate: Tỷ lệ click sau khi đọc (%)',
              'Failed: Số lượng gửi thất bại',
              'Recent Notifications: Danh sách thông báo gần nhất',
            ],
          ),
          GuideStep(
            title: 'Broadcast - Gửi Thông báo Hàng loạt',
            description:
                'Tab Broadcast cho phép gửi thông báo đến nhiều người dùng cùng lúc với targeting linh hoạt.',
            type: GuideStepType.action,
            icon: Icons.campaign,
            keyPoints: [
              'Nhập Title (bắt buộc)',
              'Nhập Message (bắt buộc)',
              'Chọn Type: system, tournament, match, club, chat, friend',
              'Chọn Target Audience:',
              '  • All Users - Tất cả người dùng',
              '  • Players Only - Chỉ người chơi',
              '  • Club Owners Only - Chỉ chủ CLB',
              '  • Admins Only - Chỉ admin',
              '  • Active Users - Người dùng active 30 ngày',
              'Preview trước khi gửi',
              'Click "Gửi ngay" để broadcast',
            ],
          ),
          GuideStep(
            title: 'Scheduled - Lên lịch Thông báo',
            description:
                'Tab Scheduled giúp lên lịch gửi thông báo tự động vào thời điểm trong tương lai.',
            type: GuideStepType.action,
            icon: Icons.schedule,
            keyPoints: [
              'Nhập Title và Message',
              'Chọn Date & Time (tối thiểu 5 phút sau)',
              'Chọn Type và Target Audience',
              'Click "Lên lịch" để tạo',
              'Xem danh sách scheduled trong list',
              'Có thể Cancel scheduled notification',
              'Status: pending → sent/cancelled/failed',
            ],
          ),
          GuideStep(
            title: 'Templates - Quản lý Mẫu',
            description:
                'Tab Templates quản lý các mẫu thông báo có sẵn với biến động (variables) để tái sử dụng.',
            type: GuideStepType.info,
            icon: Icons.description,
            keyPoints: [
              '6 templates mặc định đã có sẵn:',
              '  • welcome_new_user - Chào mừng',
              '  • tournament_starting - Giải đấu bắt đầu',
              '  • match_result - Kết quả trận',
              '  • club_approved - CLB được duyệt',
              '  • club_rejected - CLB bị từ chối',
              '  • rank_updated - Cập nhật hạng',
              'Variables: {{user_name}}, {{tournament_name}}, etc.',
              'Usage Count: Số lần template được dùng',
              'Toggle Active/Inactive templates',
            ],
          ),
          GuideStep(
            title: 'Analytics - Phân tích Hiệu suất',
            description:
                'Tab Analytics cung cấp biểu đồ và metrics chi tiết về hiệu suất thông báo.',
            type: GuideStepType.info,
            icon: Icons.analytics,
            keyPoints: [
              'Delivery Trends Chart:',
              '  • Line chart 30 ngày',
              '  • 3 đường: Sent, Delivered, Read',
              '  • Interactive tooltips',
              'Type Performance Bar Chart:',
              '  • Hiệu suất theo loại notification',
              '  • Metrics: Total, Delivery %, Read %, CTR',
              'Export as CSV hoặc PDF',
              'Chọn date range tùy chỉnh',
            ],
          ),
          GuideStep(
            title: 'Backend - SQL Functions',
            description:
                'Hệ thống được hỗ trợ bởi 12 SQL functions tự động trong Supabase.',
            type: GuideStepType.tip,
            icon: Icons.storage,
            keyPoints: [
              'get_notification_stats() - Thống kê tổng quan',
              'get_delivery_trends(days) - Xu hướng theo ngày',
              'get_notification_type_performance() - Hiệu suất theo loại',
              'process_scheduled_notifications() - Xử lý scheduled',
              'send_notification_from_template() - Gửi từ template',
              'Tất cả tự động, không cần can thiệp',
            ],
          ),
          GuideStep(
            title: 'Best Practices',
            description:
                'Một số lưu ý khi sử dụng hệ thống thông báo hiệu quả.',
            type: GuideStepType.success,
            icon: Icons.tips_and_updates,
            keyPoints: [
              'Targeting chính xác: Chọn audience phù hợp',
              'Title ngắn gọn: Dưới 50 ký tự',
              'Message rõ ràng: Nội dung dễ hiểu',
              'Timing hợp lý: Gửi vào giờ active',
              'Test trước: Preview trước khi gửi mass',
              'Monitor metrics: Theo dõi read rate và CTR',
              'Use templates: Tái sử dụng cho consistency',
              'Schedule ahead: Lên lịch cho events quan trọng',
            ],
          ),
        ],
      ),

      // GETTING STARTED GUIDE
      AdminGuide(
        id: 'admin_getting_started',
        title: 'Bắt đầu với Admin Dashboard',
        description:
            'Hướng dẫn cơ bản về giao diện và các chức năng chính của Admin',
        category: GuideCategory.gettingStarted,
        priority: 0,
        version: _appVersion,
        lastUpdated: DateTime(2025, 10, 22),
        estimatedMinutes: 5,
        tags: ['getting started', 'dashboard', 'basic'],
        steps: [
          GuideStep(
            title: 'Chào mừng Admin!',
            description:
                'Admin Dashboard là trung tâm quản lý toàn bộ hệ thống SABO Arena. Từ đây bạn có thể quản lý clubs, tournaments, users và nhiều hơn nữa.',
            type: GuideStepType.info,
            icon: Icons.home,
          ),
          GuideStep(
            title: '5 Tab chính',
            description: 'Admin Dashboard có 5 tab chính ở bottom navigation:',
            type: GuideStepType.info,
            icon: Icons.dashboard,
            keyPoints: [
              'Dashboard - Tổng quan thống kê',
              'Duyệt CLB - Phê duyệt câu lạc bộ',
              'Tournament - Quản lý giải đấu',
              'Users - Quản lý người dùng',
              'Khác - Các tính năng khác (Notifications, Vouchers, etc.)',
            ],
          ),
          GuideStep(
            title: 'Truy cập nhanh',
            description:
                'Mỗi tab có các action cards để truy cập nhanh các tính năng phổ biến.',
            type: GuideStepType.tip,
            icon: Icons.touch_app,
          ),
        ],
      ),

      // CLUB MANAGEMENT GUIDE
      AdminGuide(
        id: 'club_approval_guide',
        title: 'Phê duyệt Câu lạc bộ',
        description: 'Hướng dẫn quy trình duyệt và quản lý câu lạc bộ',
        category: GuideCategory.clubManagement,
        priority: 2,
        version: _appVersion,
        lastUpdated: DateTime(2025, 10, 22),
        estimatedMinutes: 7,
        tags: ['club', 'approval', 'management'],
        steps: [
          GuideStep(
            title: 'Truy cập Duyệt CLB',
            description: 'Click tab "Duyệt CLB" ở bottom navigation',
            type: GuideStepType.action,
            icon: Icons.business,
            targetRoute: '/admin_club_approval',
          ),
          GuideStep(
            title: 'Xem danh sách chờ duyệt',
            description:
                'Danh sách clubs đang chờ phê duyệt hiển thị với thông tin đầy đủ',
            type: GuideStepType.info,
            icon: Icons.list,
            keyPoints: [
              'Tên CLB',
              'Địa chỉ',
              'Chủ CLB',
              'Số điện thoại',
              'Ngày đăng ký',
            ],
          ),
          GuideStep(
            title: 'Phê duyệt hoặc Từ chối',
            description:
                'Click vào club để xem chi tiết, sau đó chọn Approve hoặc Reject',
            type: GuideStepType.action,
            icon: Icons.check_circle,
            keyPoints: [
              'Approve: CLB được kích hoạt ngay lập tức',
              'Reject: Cần nhập lý do từ chối',
              'Owner sẽ nhận thông báo qua notification system',
            ],
          ),
        ],
      ),

      // Add more guides for other features...
    ];
  }

  /// Quick help data mapped by screen ID
  final Map<String, List<QuickHelp>> _quickHelpData = {
    'admin_notification_management': [
      QuickHelp(
        screenId: 'admin_notification_management',
        elementId: 'dashboard_tab',
        title: 'Dashboard Tab',
        description:
            'Hiển thị thống kê real-time về thông báo: total sent, read rate, CTR, và failed count trong 30 ngày.',
        relatedGuideId: 'notification_management_complete',
      ),
      QuickHelp(
        screenId: 'admin_notification_management',
        elementId: 'broadcast_tab',
        title: 'Broadcast Tab',
        description:
            'Gửi thông báo hàng loạt đến nhóm người dùng: All, Players, Club Owners, Admins, Active Users.',
        relatedGuideId: 'notification_management_complete',
      ),
      QuickHelp(
        screenId: 'admin_notification_management',
        elementId: 'scheduled_tab',
        title: 'Scheduled Tab',
        description:
            'Lên lịch thông báo tự động gửi vào thời điểm trong tương lai. Tối thiểu 5 phút sau.',
        relatedGuideId: 'notification_management_complete',
      ),
      QuickHelp(
        screenId: 'admin_notification_management',
        elementId: 'templates_tab',
        title: 'Templates Tab',
        description:
            'Quản lý mẫu thông báo với variables để tái sử dụng. 6 templates mặc định có sẵn.',
        relatedGuideId: 'notification_management_complete',
      ),
      QuickHelp(
        screenId: 'admin_notification_management',
        elementId: 'analytics_tab',
        title: 'Analytics Tab',
        description:
            'Phân tích hiệu suất với biểu đồ: Delivery trends (30 ngày) và Type performance (bar chart).',
        relatedGuideId: 'notification_management_complete',
      ),
    ],
    'admin_club_approval': [
      QuickHelp(
        screenId: 'admin_club_approval',
        elementId: 'pending_list',
        title: 'Danh sách chờ duyệt',
        description:
            'Các club đang chờ phê duyệt. Click vào để xem chi tiết và approve/reject.',
        relatedGuideId: 'club_approval_guide',
      ),
    ],
  };
}

