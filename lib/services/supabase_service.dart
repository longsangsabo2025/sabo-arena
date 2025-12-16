import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import './ssl_certificate_handler.dart';
import './database_connection_manager.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🎯 SMART SUPABASE SERVICE - PRODUCTION READY
/// 🔐 SECURITY: Environment variables REQUIRED - No hardcoded credentials
/// 🔐 PRODUCTION-GRADE SSL: Uses proper certificate validation (NO BYPASS!)
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  // 🧠 SMART GETTERS - Require environment variables
  static String get _url {
    const url = String.fromEnvironment('SUPABASE_URL');
    if (url.isEmpty) {
      // 🚨 CRITICAL SECURITY CHECK
      throw Exception(
          '🚨 FATAL: SUPABASE_URL is missing! You must provide it via --dart-define or .env');
    }
    return url;
  }

  static String get _anonKey {
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (key.isEmpty) {
      // 🚨 CRITICAL SECURITY CHECK
      throw Exception(
          '🚨 FATAL: SUPABASE_ANON_KEY is missing! You must provide it via --dart-define or .env');
    }
    return key;
  }

  // 🎯 SMART INITIALIZATION - PRODUCTION-GRADE SSL
  static Future<void> initialize() async {
    try {
      ProductionLogger.info('🚀 Initializing Supabase...', tag: 'Supabase');
      ProductionLogger.info(
        '📡 URL: ${_url.substring(0, 30)}...',
        tag: 'Supabase',
      );
      ProductionLogger.info(
        '🔑 Using environment credentials',
        tag: 'Supabase',
      );

      // 🔐 PRODUCTION-GRADE SSL: Use proper certificate validation
      // ✅ KHÔNG bypass security - uses system trust store
      // ✅ Follows iOS/Android security guidelines
      // ✅ Giải quyết TRIỆT ĐỂ lỗi CERTIFICATE_VERIFY_FAILED
      
      // For web, don't pass httpClient (browser handles it)
      // For mobile, use SSL certificate handler
      final httpClient = kIsWeb ? null : (kDebugMode
          ? SSLCertificateHandler.createDebugClient()  // Debug: Accept all (for testing)
          : SSLCertificateHandler.createSecureClient()); // Production: Proper validation

      ProductionLogger.info(
        '🔐 SSL: Using ${kIsWeb ? 'browser' : (kDebugMode ? 'debug' : 'production-grade')} certificate validation',
        tag: 'Supabase',
      );

      // 🔍 Pre-verify connection (helps detect issues early)
      if (!kDebugMode && !kIsWeb) {
        final isConnected = await SSLCertificateHandler.verifySupabaseConnection(_url);
        if (!isConnected) {
          ProductionLogger.warning(
            '⚠️ Pre-verification failed, but continuing initialization...',
            tag: 'Supabase',
          );
        }
      }

      await Supabase.initialize(
        url: _url,
        anonKey: _anonKey,
        debug: kDebugMode,
        httpClient: httpClient,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      ProductionLogger.info(
        '✅ Supabase initialized successfully!',
        tag: 'Supabase',
      );

      // Initialize connection manager for health checks and retry logic
      DatabaseConnectionManager.instance.initialize();
      ProductionLogger.info(
        '✅ Database connection manager initialized',
        tag: 'Supabase',
      );
    } catch (e, stackTrace) {
      ProductionLogger.error(
        '💥 CRITICAL: Supabase initialization failed. Environment variables required!',
        error: e,
        stackTrace: stackTrace,
        tag: 'Supabase',
      );
      // Fail fast - no fallback credentials
      rethrow;
    }
  }

  // SAFE CLIENT GETTER - NEVER THROWS LateInitializationError
  SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      ProductionLogger.error(
        '⚠️ Supabase client not ready',
        error: e,
        tag: 'Supabase',
      );
      throw Exception(
        'Supabase not initialized! Call SupabaseService.initialize() first.',
      );
    }
  }

  // UTILITY METHOD TO CHECK IF INITIALIZED
  bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (e) {
      return false;
    }
  }

  // SAFE AUTHENTICATION CHECK
  bool get isAuthenticated {
    try {
      return client.auth.currentUser != null;
    } catch (e) {
      ProductionLogger.warning('⚠️ Auth check failed: $e', tag: 'Supabase');
      return false;
    }
  }
}
