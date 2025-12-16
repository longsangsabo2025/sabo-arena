import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'circuit_breaker.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// CDN Service with Circuit Breaker and Fallback
/// Manages CDN URLs for images and static assets
/// 
/// Features:
/// - Circuit breaker protection
/// - Automatic fallback to direct storage if CDN fails
/// - Graceful degradation
/// 
/// Supports:
/// - Cloudflare CDN
/// - CloudFront CDN
/// - Supabase CDN (default fallback)
/// - Direct Supabase Storage (fallback if CDN fails)
class CDNService {
  static CDNService? _instance;
  static CDNService get instance => _instance ??= CDNService._();

  CDNService._();

  // CDN configuration
  String? _cdnBaseUrl;
  String? _cdnProvider; // 'cloudflare', 'cloudfront', 'supabase'
  bool _enabled = false;
  
  // Circuit breaker for CDN
  final CircuitBreaker _circuitBreaker = CircuitBreakerManager.instance.getBreaker('cdn');

  /// Initialize CDN service
  void initialize({
    String? cdnBaseUrl,
    String? cdnProvider,
  }) {
    _cdnBaseUrl = cdnBaseUrl;
    _cdnProvider = cdnProvider ?? 'supabase';
    _enabled = cdnBaseUrl != null;

    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Get CDN URL for image with fallback to direct storage
  /// Returns CDN URL if enabled and healthy, otherwise returns original URL
  String getImageUrl(String originalUrl, {String? size}) {
    // If CDN not enabled, return original URL
    if (!_enabled || _cdnBaseUrl == null) {
      return originalUrl;
    }

    // Check circuit breaker state
    if (_circuitBreaker.state == CircuitState.open) {
      // Circuit is open, use fallback (direct storage)
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      return originalUrl;
    }

    // If URL is already a CDN URL, return as is
    if (originalUrl.contains(_cdnBaseUrl!)) {
      return originalUrl;
    }

    // Extract path from Supabase Storage URL
    final path = _extractPathFromSupabaseUrl(originalUrl);
    if (path == null) {
      return originalUrl; // Fallback to original if can't parse
    }

    // Build CDN URL with size parameter if provided
    final sizeSuffix = size != null ? '_$size' : '';
    final cdnPath = path.replaceAll(RegExp(r'\.(jpg|jpeg|png)$'), '$sizeSuffix.webp');
    
    return '$_cdnBaseUrl$cdnPath';
  }
  
  /// Test CDN health and update circuit breaker
  Future<bool> checkHealth() async {
    if (!_enabled || _cdnBaseUrl == null) {
      return false;
    }
    
    return await _circuitBreaker.execute(
      () async {
        // Test CDN with a simple request
        final testUrl = '$_cdnBaseUrl/health';
        final response = await Future.any([
          Future.delayed(const Duration(seconds: 2), () => throw TimeoutException('CDN health check timeout')),
          http.get(Uri.parse(testUrl)),
        ]);
        
        if (response.statusCode == 200) {
          return true;
        } else {
          throw Exception('CDN health check failed: ${response.statusCode}');
        }
      },
      fallback: () async {
        if (kDebugMode) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
        return false;
      },
    );
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String originalUrl) {
    return getImageUrl(originalUrl, size: 'thumb');
  }

  /// Get medium size URL
  String getMediumUrl(String originalUrl) {
    return getImageUrl(originalUrl, size: 'medium');
  }

  /// Get full size URL
  String getFullUrl(String originalUrl) {
    return getImageUrl(originalUrl, size: 'full');
  }

  /// Extract path from Supabase Storage URL
  String? _extractPathFromSupabaseUrl(String url) {
    try {
      // Supabase Storage URL format:
      // https://[project].supabase.co/storage/v1/object/public/[bucket]/[path]
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Find 'public' segment and get everything after it
      final publicIndex = pathSegments.indexOf('public');
      if (publicIndex == -1 || publicIndex >= pathSegments.length - 1) {
        return null;
      }

      // Get path after 'public'
      final path = '/${pathSegments.sublist(publicIndex + 1).join('/')}';
      return path;
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      return null;
    }
  }

  /// Check if CDN is enabled
  bool get isEnabled => _enabled;

  /// Get CDN provider
  String? get provider => _cdnProvider;

  /// Get CDN base URL
  String? get baseUrl => _cdnBaseUrl;
}

// Exception for timeout
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}


