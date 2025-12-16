/// User-Friendly Messages
/// Chuyển đổi error messages kỹ thuật thành messages thân thiện cho production
class UserFriendlyMessages {
  // Private constructor
  UserFriendlyMessages._();

  /// Lấy error message thân thiện từ exception
  static String getErrorMessage(dynamic error, {String? context}) {
    // Debug mode: show technical details
    if (_isDebugMode()) {
      return _getTechnicalMessage(error, context);
    }

    // Production mode: show friendly messages
    return _getFriendlyMessage(error, context);
  }

  /// Check if running in debug mode
  static bool _isDebugMode() {
    bool isDebug = false;
    assert(isDebug = true); // Only true in debug mode
    return isDebug;
  }

  /// Technical message for debug
  static String _getTechnicalMessage(dynamic error, String? context) {
    final contextStr = context != null ? '$context: ' : '';
    return '$contextStr$error';
  }

  /// Friendly message for production
  static String _getFriendlyMessage(dynamic error, String? context) {
    final errorStr = error.toString().toLowerCase();

    // Network errors
    if (errorStr.contains('network') ||
        errorStr.contains('socket') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout') ||
        errorStr.contains('failed host lookup')) {
      return '📡 Không có kết nối mạng. Vui lòng kiểm tra và thử lại nhé!';
    }

    // Authentication errors
    if (errorStr.contains('auth') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('token') ||
        errorStr.contains('session')) {
      return '🔐 Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại!';
    }

    // Permission errors
    if (errorStr.contains('permission') ||
        errorStr.contains('denied') ||
        errorStr.contains('forbidden')) {
      return '🚫 Bạn không có quyền thực hiện thao tác này.';
    }

    // Data not found
    if (errorStr.contains('not found') ||
        errorStr.contains('404') ||
        errorStr.contains('does not exist')) {
      return '🔍 Không tìm thấy dữ liệu. Vui lòng thử lại!';
    }

    // Server errors
    if (errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503') ||
        errorStr.contains('server error')) {
      return '⚙️ Hệ thống đang bảo trì. Vui lòng thử lại sau nhé!';
    }

    // File/Image errors
    if (errorStr.contains('file') ||
        errorStr.contains('image') ||
        errorStr.contains('upload')) {
      return '📁 Không thể tải file. Vui lòng thử lại!';
    }

    // Context-specific messages
    if (context != null) {
      return _getContextualMessage(context);
    }

    // Default friendly message
    return '😅 Có lỗi xảy ra. Vui lòng thử lại sau nhé!';
  }

  /// Get contextual friendly message
  static String _getContextualMessage(String context) {
    final ctx = context.toLowerCase();

    if (ctx.contains('load') || ctx.contains('fetch') || ctx.contains('tải')) {
      return '📥 Chưa thể tải dữ liệu. Vui lòng thử lại sau nha!';
    }

    if (ctx.contains('save') || ctx.contains('update') || ctx.contains('lưu')) {
      return '💾 Chưa thể lưu thông tin. Vui lòng thử lại!';
    }

    if (ctx.contains('delete') ||
        ctx.contains('remove') ||
        ctx.contains('xóa')) {
      return '🗑️ Chưa thể xóa. Vui lòng thử lại!';
    }

    if (ctx.contains('send') || ctx.contains('gửi')) {
      return '📤 Chưa thể gửi. Vui lòng thử lại!';
    }

    if (ctx.contains('post') || ctx.contains('đăng')) {
      return '📝 Chưa thể đăng bài. Vui lòng thử lại!';
    }

    if (ctx.contains('message') || ctx.contains('tin nhắn')) {
      return '💬 Chưa thể gửi tin nhắn. Vui lòng thử lại!';
    }

    if (ctx.contains('follow') || ctx.contains('theo dõi')) {
      return '👥 Chưa thể thực hiện. Vui lòng thử lại!';
    }

    if (ctx.contains('search') || ctx.contains('tìm')) {
      return '🔎 Không tìm thấy kết quả. Vui lòng thử lại!';
    }

    return '😅 Có lỗi xảy ra. Vui lòng thử lại sau nhé!';
  }

  // Predefined friendly messages for common scenarios
  static const String loadError =
      '📥 Chưa thể tải dữ liệu. Vui lòng thử lại sau nha!';
  static const String saveError =
      '💾 Chưa thể lưu thông tin. Vui lòng thử lại!';
  static const String deleteError = '🗑️ Chưa thể xóa. Vui lòng thử lại!';
  static const String sendError = '📤 Chưa thể gửi. Vui lòng thử lại!';
  static const String postError = '📝 Chưa thể đăng bài. Vui lòng thử lại!';
  static const String messageError =
      '💬 Chưa thể gửi tin nhắn. Vui lòng thử lại!';
  static const String followError = '👥 Chưa thể thực hiện. Vui lòng thử lại!';
  static const String searchError =
      '🔎 Không tìm thấy kết quả. Vui lòng thử lại!';
  static const String networkError =
      '📡 Không có kết nối mạng. Vui lòng kiểm tra và thử lại nhé!';
  static const String authError =
      '🔐 Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại!';
  static const String permissionError =
      '🚫 Bạn không có quyền thực hiện thao tác này.';
  static const String notFoundError =
      '🔍 Không tìm thấy dữ liệu. Vui lòng thử lại!';
  static const String serverError =
      '⚙️ Hệ thống đang bảo trì. Vui lòng thử lại sau nhé!';
  static const String fileError = '📁 Không thể tải file. Vui lòng thử lại!';
  static const String genericError =
      '😅 Có lỗi xảy ra. Vui lòng thử lại sau nhé!';

  // Success messages
  static const String saveSuccess = '✅ Đã lưu thành công!';
  static const String deleteSuccess = '✅ Đã xóa thành công!';
  static const String sendSuccess = '✅ Đã gửi thành công!';
  static const String postSuccess = '✅ Đã đăng bài thành công!';
  static const String followSuccess = '✅ Đã theo dõi!';
  static const String unfollowSuccess = '✅ Đã bỏ theo dõi!';
  static const String updateSuccess = '✅ Đã cập nhật thành công!';
}
