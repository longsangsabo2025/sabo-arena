import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// 🔐 Mobile-specific SSL Certificate Handler (iOS/Android)
class SSLCertificateHandlerPlatform {
  /// 🎯 Create HTTP client with proper SSL configuration for mobile
  static http.Client createSecureClient() {
    // 🔧 iOS/Android: Use system trust store
    final httpClient = HttpClient();

    // ✅ KHÔNG bypass certificate validation
    // Use system validation for production security
    httpClient.badCertificateCallback = null;

    // Configure timeouts for slow networks
    httpClient.connectionTimeout = const Duration(seconds: 30);
    httpClient.idleTimeout = const Duration(seconds: 90);

    // ⚡ Performance optimizations
    httpClient.maxConnectionsPerHost = 5;

    return IOClient(httpClient);
  }

  /// 🆘 Fallback client for debugging ONLY
  /// NEVER use this in production!
  static http.Client createDebugClient() {
    if (!kDebugMode) {
      throw Exception('Debug client can only be used in debug mode!');
    }

    final httpClient = HttpClient();

    httpClient.badCertificateCallback = (cert, host, port) {
      if (kDebugMode) {
        ProductionLogger.info('⚠️ DEBUG: Accepting certificate for $host (DEBUG ONLY!)', tag: 'ssl_certificate_handler_mobile');
      }
      return true; // Accept all in debug mode only
    };

    httpClient.connectionTimeout = const Duration(seconds: 30);
    httpClient.idleTimeout = const Duration(seconds: 90);

    return IOClient(httpClient);
  }

  /// 🔍 Verify connection on mobile
  static Future<bool> verifyConnection(String url) async {
    try {
      final client = createSecureClient();
      final uri = Uri.parse('$url/rest/v1/');
      
      final response = await client.get(uri).timeout(
        const Duration(seconds: 10),
      );

      client.close();

      final isConnected = response.statusCode < 500;
      
      if (kDebugMode) {
        ProductionLogger.info(isConnected
            ? '✅ Connection verified (status: ${response.statusCode})'
            : '❌ Connection failed (status: ${response.statusCode})', tag: 'ssl_certificate_handler_mobile');
      }

      return isConnected;
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('❌ Connection verification failed: $e', tag: 'ssl_certificate_handler_mobile');
      }
      return false;
    }
  }

  static String getAdvice() {
    return '''
🔐 iOS/Android SSL Configuration:

✅ Currently using:
- System trust store validation
- Proper certificate chains
- TLS 1.2+ support

If you see CERTIFICATE_VERIFY_FAILED:
1. Check device date/time is correct
2. Update to latest iOS/Android version
3. Check network/firewall settings
4. Verify Supabase URL is correct

⚠️ Security: Certificate validation is NOT bypassed
    ''';
  }
}
