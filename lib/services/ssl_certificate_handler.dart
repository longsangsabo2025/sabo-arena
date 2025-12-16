import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

// Conditional imports for platform-specific code
import 'ssl_certificate_handler_mobile.dart'
    if (dart.library.html) 'ssl_certificate_handler_web.dart' as platform;

/// 🔐 PRODUCTION-GRADE SSL CERTIFICATE HANDLER
/// Giải quyết TRIỆT ĐỂ lỗi CERTIFICATE_VERIFY_FAILED trên iOS
///
/// Phương pháp này KHÔNG bypass security mà sử dụng system trust store
/// và proper certificate validation theo iOS/Android guidelines
class SSLCertificateHandler {
  /// 🎯 Create HTTP client với proper SSL configuration
  static http.Client createSecureClient() {
    return platform.SSLCertificateHandlerPlatform.createSecureClient();
  }

  /// 🆘 Fallback client for debugging ONLY
  /// NEVER use this in production!
  static http.Client createDebugClient() {
    if (!kDebugMode) {
      throw Exception('Debug client can only be used in debug mode!');
    }
    return platform.SSLCertificateHandlerPlatform.createDebugClient();
  }

  /// 🔍 Verify Supabase connection với proper error handling
  static Future<bool> verifySupabaseConnection(String url) async {
    return await platform.SSLCertificateHandlerPlatform.verifyConnection(url);
  }

  /// 🎯 Get recommended configuration message
  static String getConfigurationAdvice() {
    return platform.SSLCertificateHandlerPlatform.getAdvice();
  }
}
