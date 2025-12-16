import 'package:http/http.dart' as http;

/// 🌐 Web-specific SSL Certificate Handler
class SSLCertificateHandlerPlatform {
  /// 🎯 Create HTTP client for web (uses browser security)
  static http.Client createSecureClient() {
    // Web always uses browser's built-in security
    return http.Client();
  }

  /// 🆘 Debug client for web (same as secure - browser handles it)
  static http.Client createDebugClient() {
    // Web always uses browser's security, even in debug mode
    return http.Client();
  }

  /// 🔍 Skip verification on web - browser handles SSL
  static Future<bool> verifyConnection(String url) async {
    return true; // Browser handles SSL automatically
  }

  static String getAdvice() {
    return '''
🌐 Web Platform Configuration:

✅ SSL/TLS is handled automatically by the browser
✅ Certificate validation managed by browser
✅ No additional configuration needed

Note: CORS must be configured on Supabase project
    ''';
  }
}
