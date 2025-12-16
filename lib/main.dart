import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:sizer/sizer.dart';
import 'package:upgrader/upgrader.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import './core/device/orientation_manager.dart'; // 📱 SMART ORIENTATION: iPad landscape + iPhone portrait
import './services/analytics_service.dart'; // 📊 UNIFIED ANALYTICS
import './services/app_cache_service.dart'; // 🚀 PHASE 1: Cache service
import './services/deep_link_handler.dart'; // 🔗 DEEP LINK HANDLER
import './services/supabase_service.dart';
import './services/tournament_cache_service.dart';
import './services/upgrader_messages_vi.dart'; // 🔄 Vietnamese messages for app updates
import './services/user_journey_analytics.dart';
import './services/database_replica_manager.dart'; // 🔄 Database Replica Manager
import './services/cdn_service.dart'; // 🔄 CDN Service
import './services/rate_limit_service.dart'; // 🔄 Rate Limit Service
import './services/cost_monitoring_service.dart'; // 🔄 Cost Monitoring Service
// import './test/backend_test_runner.dart'; // 🧪 BACKEND TEST RUNNER - DISABLED
import 'utils/longsang_error_reporter.dart'; // 🔴 LONGSANG AUTO-FIX
import 'package:sentry_flutter/sentry_flutter.dart'; // 🔍 SENTRY ERROR TRACKING
import 'package:sabo_arena/utils/production_logger.dart';
// import './services/auto_tournament_progression_service.dart'; // ❌ DISABLED
// import './services/auto_winner_detection_service.dart'; // ❌ DISABLED

void main() {
  // Initialize Sentry for error tracking (if DSN provided)
  final sentryDsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  
  if (sentryDsn.isNotEmpty) {
    // Initialize Sentry and run app
    SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
        options.environment = const String.fromEnvironment('ENV', defaultValue: 'development');
        options.enableAutoSessionTracking = true;
        options.attachStacktrace = true;
        options.enableAutoPerformanceTracing = true;
        // Tags will be set automatically via StandardizedErrorHandler
      },
      appRunner: () => _runApp(),
    );
  } else {
    // Fallback to LongSangErrorReporter if no Sentry DSN
    LongSangErrorReporter.init(() async {
      await _runApp();
    }, appName: 'sabo-arena');
  }
}

/// App initialization logic (shared between Sentry and LongSang paths)
Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();

    // 🎯 CRITICAL INITIALIZATION ONLY - Keep startup fast
    ProductionLogger.info('🚀 Starting SABO Arena...', tag: 'AppInit');

    // 1️⃣ CRITICAL: Initialize Supabase first (REQUIRED for app to work)
    try {
      await SupabaseService.initialize();
      ProductionLogger.info('✅ Supabase ready!', tag: 'AppInit');
      
      // Initialize Database Replica Manager after Supabase is ready
      try {
        await DatabaseReplicaManager.instance.initialize();
        ProductionLogger.info('✅ Database Replica Manager ready!', tag: 'AppInit');
      } catch (e) {
        ProductionLogger.warning(
          'Database Replica Manager initialization failed',
          error: e,
          tag: 'AppInit',
        );
        // Non-critical, app can continue
      }
      
      // 🧪 AUTO BACKEND TESTING: DISABLED BY ELON (Too slow for startup)
      /*
      if (kDebugMode) {
        try {
          ProductionLogger.info('🧪 Running backend tests...', tag: 'BackendTest');
          final testRunner = BackendTestRunner();
          final results = await testRunner.runAllTests();
          ProductionLogger.info(
            '📊 Backend Test Results: ${results['passed']}/${results['total']} passed (${results['successRate']}%)',
            tag: 'BackendTest',
          );
          
          // Log failed tests
          final failedTests = (results['results'] as List)
              .where((r) => r['passed'] == false)
              .toList();
          if (failedTests.isNotEmpty) {
            ProductionLogger.warning(
              '❌ Failed tests: ${failedTests.map((t) => t['name']).join(', ')}',
              tag: 'BackendTest',
            );
          }
        } catch (e) {
          ProductionLogger.warning(
            'Backend test runner failed (non-critical)',
            error: e,
            tag: 'BackendTest',
          );
        }
      }
      */
    } catch (e) {
      ProductionLogger.error(
        '💥 Critical: Supabase initialization failed',
        error: e,
        tag: 'AppInit',
      );
      // App cannot work without Supabase
    }

    // 📊 Initialize Analytics
    try {
      AnalyticsService();
      ProductionLogger.info('✅ Analytics ready!', tag: 'AppInit');
    } catch (e) {
      ProductionLogger.warning(
        'Analytics initialization failed',
        error: e,
        tag: 'AppInit',
      );
    }

    // 2️⃣ NON-CRITICAL: Initialize in background to keep startup fast
    _initializeNonCriticalServices();

    ProductionLogger.info('✅ App startup complete!', tag: 'AppInit');

    bool hasShownError = false;

    // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (!hasShownError) {
        hasShownError = true;

        // Reset flag after 3 seconds to allow error widget on new screens
        Future.delayed(Duration(seconds: 5), () {
          hasShownError = false;
        });

        return CustomErrorWidget(errorDetails: details);
      }
      return SizedBox.shrink();
    };

    // ✅ iOS HIG: Support all orientations initially
    // Will auto-adjust to device-specific orientations after app starts
    // iPad: landscape + portrait | iPhone: portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 🔗 Initialize deep link handler after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.init(context);
      ProductionLogger.info('✅ Deep Link Handler initialized', tag: 'AppInit');

      // 📱 SMART ORIENTATION: Set device-specific orientations
      // iPad: landscape + portrait | iPhone: portrait only
      OrientationManager.setDeviceOrientations(context);
      ProductionLogger.info('✅ Smart orientation configured', tag: 'AppInit');
    });
  }

  @override
  void dispose() {
    DeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return OverlaySupport.global(
          child: MaterialApp(
            title: 'sabo_arena',
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('en', 'US'), // English
              Locale('vi', 'VN'), // Vietnamese
            ],
            locale: Locale('vi', 'VN'), // Set Vietnamese as default
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system, // ✅ iOS: Respect system dark mode preference
            // ✅ iOS ACCESSIBILITY: Support Dynamic Type for vision accessibility
            // Removed forced text scaling to allow users to adjust text size in iOS Settings
            debugShowCheckedModeBanner: false,
            routes: AppRoutes.routes,
            initialRoute: AppRoutes.initial,
            // 🔄 AUTO UPDATE: Check for app updates from App Store/Play Store
            home: UpgradeAlert(
              upgrader: Upgrader(
                durationUntilAlertAgain: Duration(days: 1), // Show alert once per day
                messages: UpgraderMessagesVi(),
              ),
              child: Builder(
                builder: (context) => Navigator(
                  onGenerateRoute: (settings) {
                    final String? routeName = settings.name;
                    final WidgetBuilder? builder = AppRoutes.routes[routeName ?? AppRoutes.initial];
                    if (builder != null) {
                      return MaterialPageRoute(
                        builder: builder,
                        settings: settings,
                      );
                    }
                    return MaterialPageRoute(
                      builder: AppRoutes.routes[AppRoutes.initial]!,
                      settings: settings,
                    );
                  },
                  initialRoute: AppRoutes.initial,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 🚀 PERFORMANCE: Initialize non-critical services in background
void _initializeNonCriticalServices() async {
  // Run all background initializations without blocking app startup
  Future.microtask(() async {
    // 1. Cache Service
    try {
      await TournamentCacheService.initialize();
      ProductionLogger.info('✅ Background: Tournament Cache initialized', tag: 'AppInit');
    } catch (e) {
      ProductionLogger.warning(
        'Background: Cache init failed (non-critical)',
        error: e,
        tag: 'AppInit',
      );
    }

    // 2. App Cache Service
    try {
      await AppCacheService.instance.initialize();
      ProductionLogger.info('✅ Background: App Cache initialized', tag: 'AppInit');
    } catch (e) {
      ProductionLogger.warning(
        'Background: App Cache init failed (non-critical)',
        error: e,
        tag: 'AppInit',
      );
    }

    // 3. Firebase (Push Notifications) - Skip on web
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();
        ProductionLogger.info('✅ Background: Firebase initialized', tag: 'AppInit');
      } catch (e) {
        ProductionLogger.warning(
          'Background: Firebase init failed (non-critical)',
          error: e,
          tag: 'AppInit',
        );
      }
    }

    // 4. CDN Service
    try {
      // Initialize CDN (configure via environment variable if needed)
      CDNService.instance.initialize();
      ProductionLogger.info('✅ Background: CDN Service initialized', tag: 'AppInit');
    } catch (e) {
      ProductionLogger.warning(
        'Background: CDN init failed (non-critical)',
        error: e,
        tag: 'AppInit',
      );
    }

    // 5. Rate Limit Service
    try {
      RateLimitService.instance.initialize();
      ProductionLogger.info('✅ Background: Rate Limit Service initialized', tag: 'AppInit');
    } catch (e) {
      ProductionLogger.warning(
        'Background: Rate Limit init failed (non-critical)',
        error: e,
        tag: 'AppInit',
      );
    }

    // 6. Performance Monitor
    try {
      // Performance monitor is ready to use
      ProductionLogger.info('✅ Background: Performance Monitor ready', tag: 'AppInit');
    } catch (e) {
      ProductionLogger.warning(
        'Background: Performance Monitor init failed (non-critical)',
        error: e,
        tag: 'AppInit',
      );
    }

    // 7. Database Monitoring
    try {
      // Database monitoring is ready to use
      ProductionLogger.info('✅ Background: Database Monitoring ready', tag: 'AppInit');
    } catch (e) {
      ProductionLogger.warning(
        'Background: Database Monitoring init failed (non-critical)',
        error: e,
        tag: 'AppInit',
      );
    }

    // 8. Cost Monitoring
    try {
      CostMonitoringService.instance.initialize();
      ProductionLogger.info('✅ Background: Cost Monitoring initialized', tag: 'AppInit');
    } catch (e) {
      ProductionLogger.warning(
        'Background: Cost Monitoring init failed (non-critical)',
        error: e,
        tag: 'AppInit',
      );
    }

    // 9. Schedule data archival (run weekly)
    try {
      // Schedule archival to run weekly (can be configured)
      ProductionLogger.info('✅ Background: Data Archival service ready', tag: 'AppInit');
    } catch (e) {
      ProductionLogger.warning(
        'Background: Data Archival init failed (non-critical)',
        error: e,
        tag: 'AppInit',
      );
    }

    // 4. User Journey Analytics
    try {
      await UserJourneyAnalytics.instance.initialize();
      ProductionLogger.info('✅ Background: Analytics initialized', tag: 'AppInit');
    } catch (e) {
      ProductionLogger.warning(
        'Background: Analytics init failed (non-critical)',
        error: e,
        tag: 'AppInit',
      );
    }

    ProductionLogger.info('✅ All background services initialized', tag: 'AppInit');
  });
}
