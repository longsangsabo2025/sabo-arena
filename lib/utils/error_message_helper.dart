/// Error Message Helper
///
/// Converts technical error messages into user-friendly Vietnamese messages
/// for better UX and iOS App Store compliance
library;

class ErrorMessageHelper {
  /// Convert any error to user-friendly message
  static String getUserFriendlyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Authentication errors
    if (errorString.contains('invalid_credentials') ||
        errorString.contains('invalid login') ||
        errorString.contains('wrong password')) {
      return 'Email hoặc mật khẩu không đúng. Vui lòng thử lại.';
    }

    if (errorString.contains('user not found') ||
        errorString.contains('email not found')) {
      return 'Tài khoản không tồn tại. Vui lòng đăng ký tài khoản mới.';
    }

    if (errorString.contains('email already') ||
        errorString.contains('already registered')) {
      return 'Email này đã được đăng ký. Vui lòng đăng nhập hoặc sử dụng email khác.';
    }

    if (errorString.contains('weak password') ||
        errorString.contains('password too short')) {
      return 'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn (ít nhất 6 ký tự).';
    }

    if (errorString.contains('invalid email')) {
      return 'Địa chỉ email không hợp lệ. Vui lòng kiểm tra lại.';
    }

    if (errorString.contains('email not confirmed') ||
        errorString.contains('verify email')) {
      return 'Vui lòng xác nhận email của bạn trước khi đăng nhập.';
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra và thử lại.';
    }

    if (errorString.contains('no internet') ||
        errorString.contains('offline')) {
      return 'Bạn đang offline. Vui lòng kết nối internet và thử lại.';
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('internal server') ||
        errorString.contains('server error')) {
      return 'Lỗi máy chủ. Vui lòng thử lại sau ít phút.';
    }

    if (errorString.contains('503') ||
        errorString.contains('service unavailable')) {
      return 'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.';
    }

    if (errorString.contains('429') ||
        errorString.contains('too many requests')) {
      return 'Bạn đã thực hiện quá nhiều yêu cầu. Vui lòng đợi một chút.';
    }

    // Permission errors
    if (errorString.contains('permission denied') ||
        errorString.contains('unauthorized')) {
      return 'Bạn không có quyền thực hiện hành động này.';
    }

    if (errorString.contains('forbidden')) {
      return 'Truy cập bị từ chối. Vui lòng kiểm tra quyền của bạn.';
    }

    // Data errors
    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Không tìm thấy dữ liệu. Vui lòng thử lại.';
    }

    if (errorString.contains('duplicate') ||
        errorString.contains('already exists')) {
      return 'Dữ liệu đã tồn tại. Vui lòng kiểm tra lại.';
    }

    if (errorString.contains('invalid data') ||
        errorString.contains('validation')) {
      return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra và thử lại.';
    }

    // File/Upload errors
    if (errorString.contains('file too large') ||
        errorString.contains('size exceeded')) {
      return 'File quá lớn. Vui lòng chọn file nhỏ hơn.';
    }

    if (errorString.contains('invalid file') ||
        errorString.contains('unsupported format')) {
      return 'Định dạng file không được hỗ trợ. Vui lòng chọn file khác.';
    }

    // Payment errors
    if (errorString.contains('payment failed') ||
        errorString.contains('transaction failed')) {
      return 'Thanh toán thất bại. Vui lòng kiểm tra thông tin và thử lại.';
    }

    if (errorString.contains('insufficient funds') ||
        errorString.contains('not enough')) {
      return 'Số dư không đủ. Vui lòng nạp thêm tiền.';
    }

    // Social auth errors
    if (errorString.contains('canceled') ||
        errorString.contains('cancelled') ||
        errorString.contains('popup_closed')) {
      return 'Đăng nhập bị hủy. Vui lòng thử lại.';
    }

    if (errorString.contains('google') && errorString.contains('failed')) {
      return 'Đăng nhập Google thất bại. Vui lòng thử lại.';
    }

    if (errorString.contains('facebook') && errorString.contains('failed')) {
      return 'Đăng nhập Facebook thất bại. Vui lòng thử lại.';
    }

    if (errorString.contains('apple') && errorString.contains('failed')) {
      return 'Đăng nhập Apple thất bại. Vui lòng thử lại.';
    }

    // Generic fallback
    return 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
  }

  /// Get error message for specific context
  static String getContextualError(String context, dynamic error) {
    final errorString = error.toString().toLowerCase();

    switch (context) {
      case 'login':
        if (errorString.contains('network')) {
          return 'Không thể đăng nhập. Vui lòng kiểm tra kết nối mạng.';
        }
        return 'Đăng nhập thất bại. Vui lòng kiểm tra thông tin và thử lại.';

      case 'register':
        if (errorString.contains('network')) {
          return 'Không thể đăng ký. Vui lòng kiểm tra kết nối mạng.';
        }
        return 'Đăng ký thất bại. Vui lòng kiểm tra thông tin và thử lại.';

      case 'post':
        if (errorString.contains('network')) {
          return 'Không thể đăng bài. Vui lòng kiểm tra kết nối mạng.';
        }
        return 'Đăng bài thất bại. Vui lòng thử lại.';

      case 'upload':
        if (errorString.contains('network')) {
          return 'Không thể tải lên. Vui lòng kiểm tra kết nối mạng.';
        }
        return 'Tải lên thất bại. Vui lòng thử lại.';

      case 'tournament':
        if (errorString.contains('network')) {
          return 'Không thể tải giải đấu. Vui lòng kiểm tra kết nối mạng.';
        }
        return 'Lỗi tải giải đấu. Vui lòng thử lại.';

      default:
        return getUserFriendlyError(error);
    }
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket') ||
        errorString.contains('offline');
  }

  /// Check if error requires user action
  static bool requiresUserAction(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('invalid_credentials') ||
        errorString.contains('email not confirmed') ||
        errorString.contains('permission denied') ||
        errorString.contains('insufficient funds');
  }
}
