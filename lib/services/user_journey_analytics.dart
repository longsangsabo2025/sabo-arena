import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Enterprise-grade user journey analytics system
/// Tracks user behavior, conversion funnels, and engagement metrics
/// Following Facebook Analytics, Google Analytics, Mixpanel patterns
class UserJourneyAnalytics {
  static UserJourneyAnalytics? _instance;
  static UserJourneyAnalytics get instance =>
      _instance ??= UserJourneyAnalytics._();
  UserJourneyAnalytics._();

  // Supabase client for analytics tracking
  SupabaseClient get _supabase => Supabase.instance.client;

  // Session tracking
  String? _sessionId;
  DateTime? _sessionStart;
  Map<String, dynamic> _sessionMetadata = {};
  final List<Map<String, dynamic>> _eventQueue = [];

  // User identification
  String? _userId;
  String? _anonymousId;
  Map<String, dynamic> _userProperties = {};

  // Conversion funnel tracking
  static const Map<String, List<String>> conversionFunnels = {
    'authentication': [
      'splash_viewed',
      'login_screen_viewed',
      'registration_started',
      'email_entered',
      'registration_completed',
      'email_verification_started',
      'email_verified',
      'profile_setup_started',
      'profile_completed',
      'onboarding_started',
      'onboarding_completed',
      'first_login_success',
    ],
    'engagement': [
      'home_screen_viewed',
      'tournament_list_viewed',
      'tournament_details_viewed',
      'tournament_joined',
      'chat_opened',
      'message_sent',
      'profile_viewed',
      'settings_accessed',
    ],
    'retention': [
      'app_opened',
      'daily_active',
      'weekly_active',
      'monthly_active',
      'feature_used',
      'session_extended',
    ],
  };

  /// Initialize analytics system
  Future<void> initialize({String? userId}) async {
    await _initializeSession();
    await _setUserId(userId);
    await _loadUserProperties();
    _startPeriodicFlush();
  }

  /// Track user event with comprehensive metadata
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    String? category,
    double? value,
    bool isConversion = false,
  }) async {
    final event = {
      'event_id': _generateEventId(),
      'session_id': _sessionId,
      'user_id': _userId,
      'anonymous_id': _anonymousId,
      'event_name': eventName,
      'category': category ?? 'general',
      'properties': properties ?? {},
      'value': value,
      'is_conversion': isConversion,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'flutter',
      'app_version': await _getAppVersion(),
      'device_info': await _getDeviceInfo(),
      'session_metadata': _sessionMetadata,
    };

    // Add to event queue
    _eventQueue.add(event);

    // Track funnel progression
    await _trackFunnelProgression(eventName);

    // Flush if queue is getting large
    if (_eventQueue.length >= 10) {
      await _flushEvents();
    }
  }

  /// Track screen view with navigation context
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? properties,
    String? referrer,
    Duration? timeOnScreen,
  }) async {
    await trackEvent(
      'screen_viewed',
      properties: {
        'screen_name': screenName,
        'referrer': referrer,
        'time_on_screen_seconds': timeOnScreen?.inSeconds,
        ...?properties,
      },
      category: 'navigation',
    );
  }

  /// Track user conversion events
  Future<void> trackConversion(
    String conversionType,
    String step, {
    Map<String, dynamic>? properties,
    double? value,
  }) async {
    await trackEvent(
      step,
      properties: {
        'conversion_type': conversionType,
        'funnel_step': step,
        ...?properties,
      },
      category: 'conversion',
      value: value,
      isConversion: true,
    );
  }

  /// Track user engagement metrics
  Future<void> trackEngagement(
    String action, {
    String? target,
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'user_engagement',
      properties: {
        'action': action,
        'target': target,
        'engagement_score': await _calculateEngagementScore(),
        ...?properties,
      },
      category: 'engagement',
    );
  }

  /// Track app performance metrics
  Future<void> trackPerformance(
    String metric,
    double value, {
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'performance_metric',
      properties: {
        'metric_name': metric,
        'metric_value': value,
        'session_duration': _getSessionDuration(),
        ...?properties,
      },
      category: 'performance',
      value: value,
    );
  }

  /// Track error events
  Future<void> trackError(
    String errorType,
    String message, {
    String? stackTrace,
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'error_occurred',
      properties: {
        'error_type': errorType,
        'error_message': message,
        'stack_trace': stackTrace,
        'user_flow': await _getCurrentUserFlow(),
        ...?properties,
      },
      category: 'error',
    );
  }

  /// Set user properties for segmentation
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    _userProperties.addAll(properties);
    await _persistUserProperties();

    // Track user property updates
    await trackEvent(
      'user_properties_updated',
      properties: {'updated_properties': properties.keys.toList()},
      category: 'user',
    );
  }

  /// Identify user and merge analytics data
  Future<void> identify(
    String userId, {
    Map<String, dynamic>? properties,
  }) async {
    final previousUserId = _userId;
    await _setUserId(userId);

    if (properties != null) {
      await setUserProperties(properties);
    }

    await trackEvent(
      'user_identified',
      properties: {
        'previous_user_id': previousUserId,
        'new_user_id': userId,
        'is_merge': previousUserId != null,
      },
      category: 'user',
    );
  }

  /// Start new session
  Future<void> startSession({Map<String, dynamic>? metadata}) async {
    await _endCurrentSession();
    await _initializeSession(metadata: metadata);

    await trackEvent(
      'session_started',
      properties: {'session_metadata': metadata ?? {}},
      category: 'session',
    );
  }

  /// End current session
  Future<void> endSession() async {
    await trackEvent(
      'session_ended',
      properties: {
        'session_duration': _getSessionDuration(),
        'events_in_session': _eventQueue.length,
      },
      category: 'session',
    );

    await _flushEvents();
    await _endCurrentSession();
  }

  /// Get funnel analysis for specific conversion flow
  Future<Map<String, dynamic>> getFunnelAnalysis(String funnelType) async {
    try {
      if (_userId == null) return {};

      final response = await _supabase
          .from('user_journey_events')
          .select('event_name, timestamp, properties')
          .eq('user_id', _userId!)
          .eq('category', 'conversion')
          .eq('properties->>conversion_type', funnelType)
          .order('timestamp');

      return _analyzeFunnelData(response, funnelType);
    } catch (e) {
      return {};
    }
  }

  /// Get user engagement metrics
  Future<Map<String, dynamic>> getEngagementMetrics() async {
    try {
      if (_userId == null) return {};

      final response = await _supabase
          .from('user_journey_events')
          .select('*')
          .eq('user_id', _userId!)
          .gte(
            'timestamp',
            DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          );

      return _calculateEngagementMetrics(response);
    } catch (e) {
      return {};
    }
  }

  /// Flush all queued events to backend
  Future<void> _flushEvents() async {
    if (_eventQueue.isEmpty) return;

    try {
      // Batch insert events
      await _supabase.from('user_journey_events').insert(_eventQueue);

      _eventQueue.clear();
    } catch (e) {
      // Keep events in queue for retry
    }
  }

  // Private helper methods
  Future<void> _initializeSession({Map<String, dynamic>? metadata}) async {
    _sessionId = _generateSessionId();
    _sessionStart = DateTime.now();
    _sessionMetadata = {
      'start_time': _sessionStart!.toIso8601String(),
      'platform': 'flutter',
      'app_version': await _getAppVersion(),
      ...?metadata,
    };

    // Generate anonymous ID if not exists
    if (_anonymousId == null) {
      final prefs = await SharedPreferences.getInstance();
      _anonymousId =
          prefs.getString('analytics_anonymous_id') ?? _generateAnonymousId();
      await prefs.setString('analytics_anonymous_id', _anonymousId!);
    }
  }

  Future<void> _endCurrentSession() async {
    if (_sessionId != null) {
      await _flushEvents();
      _sessionId = null;
      _sessionStart = null;
      _sessionMetadata = {};
    }
  }

  Future<void> _setUserId(String? userId) async {
    _userId = userId;
    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('analytics_user_id', userId);
    }
  }

  Future<void> _loadUserProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final propertiesJson = prefs.getString('analytics_user_properties');
      if (propertiesJson != null) {
        // Parse stored properties
        _userProperties = Map<String, dynamic>.from({});
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _persistUserProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'analytics_user_properties',
        _userProperties.toString(),
      );
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _trackFunnelProgression(String eventName) async {
    // Check if this event is part of any conversion funnel
    for (final entry in conversionFunnels.entries) {
      final funnelType = entry.key;
      final steps = entry.value;

      if (steps.contains(eventName)) {
        final stepIndex = steps.indexOf(eventName);
        await trackEvent(
          'funnel_step_completed',
          properties: {
            'funnel_type': funnelType,
            'step_name': eventName,
            'step_index': stepIndex,
            'total_steps': steps.length,
            'completion_percentage':
                ((stepIndex + 1) / steps.length * 100).round(),
          },
          category: 'funnel',
          isConversion: true,
        );
      }
    }
  }

  Map<String, dynamic> _analyzeFunnelData(
    List<dynamic> events,
    String funnelType,
  ) {
    final steps = conversionFunnels[funnelType] ?? [];
    final eventCounts = <String, int>{};

    for (final event in events) {
      final eventName = event['event_name'];
      eventCounts[eventName] = (eventCounts[eventName] ?? 0) + 1;
    }

    final analysis = <String, dynamic>{
      'funnel_type': funnelType,
      'total_steps': steps.length,
      'completed_steps':
          eventCounts.keys.where((k) => steps.contains(k)).length,
      'step_counts': eventCounts,
      'conversion_rates': <String, double>{},
    };

    // Calculate conversion rates between steps
    for (int i = 0; i < steps.length - 1; i++) {
      final currentStep = steps[i];
      final nextStep = steps[i + 1];
      final currentCount = eventCounts[currentStep] ?? 0;
      final nextCount = eventCounts[nextStep] ?? 0;

      if (currentCount > 0) {
        analysis['conversion_rates']['${currentStep}_to_$nextStep'] =
            nextCount / currentCount;
      }
    }

    return analysis;
  }

  Map<String, dynamic> _calculateEngagementMetrics(List<dynamic> events) {
    final metrics = <String, dynamic>{
      'total_events': events.length,
      'unique_sessions': <String>{},
      'screen_views': 0,
      'engagement_events': 0,
      'average_session_duration': 0.0,
      'retention_indicators': <String, int>{},
    };

    for (final event in events) {
      final sessionId = event['session_id'];
      if (sessionId != null) {
        metrics['unique_sessions'].add(sessionId);
      }

      final eventName = event['event_name'];
      if (eventName == 'screen_viewed') {
        metrics['screen_views']++;
      } else if (eventName == 'user_engagement') {
        metrics['engagement_events']++;
      }

      // Track retention indicators
      if (conversionFunnels['retention']?.contains(eventName) == true) {
        metrics['retention_indicators'][eventName] =
            (metrics['retention_indicators'][eventName] ?? 0) + 1;
      }
    }

    metrics['unique_sessions'] = (metrics['unique_sessions'] as Set).length;

    return metrics;
  }

  Future<double> _calculateEngagementScore() async {
    // Simple engagement score based on recent activity
    final recentEvents = _eventQueue.where((event) {
      final timestamp = DateTime.parse(event['timestamp']);
      return DateTime.now().difference(timestamp).inMinutes <= 30;
    }).length;

    return (recentEvents * 10).toDouble().clamp(0, 100);
  }

  int _getSessionDuration() {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inSeconds;
  }

  Future<String> _getCurrentUserFlow() async {
    // Simple implementation - get last 5 screen views
    final recentScreens = _eventQueue
        .where((e) => e['event_name'] == 'screen_viewed')
        .take(5)
        .map((e) => e['properties']['screen_name'])
        .join(' -> ');

    return recentScreens;
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  String _generateEventId() {
    return 'event_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  String _generateAnonymousId() {
    return 'anon_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(12)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (index) =>
          chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length],
    ).join();
  }

  Future<String> _getAppVersion() async {
    // In real app, get from package_info_plus
    return '1.0.0';
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // In real app, get from device_info_plus
    return {'platform': 'flutter', 'os': 'unknown', 'device_model': 'unknown'};
  }

  void _startPeriodicFlush() {
    // Flush events every 60 seconds
    Timer.periodic(Duration(seconds: 60), (timer) {
      _flushEvents();
    });
  }
}

/// Analytics mixin for easy integration into widgets
mixin AnalyticsTracking<T extends StatefulWidget> on State<T> {
  String get screenName => T.toString().replaceAll('_', '').toLowerCase();
  DateTime? _screenStartTime;

  @override
  void initState() {
    super.initState();
    _screenStartTime = DateTime.now();
    _trackScreenView();
  }

  @override
  void dispose() {
    _trackScreenDuration();
    super.dispose();
  }

  void _trackScreenView() {
    UserJourneyAnalytics.instance.trackScreenView(screenName);
  }

  void _trackScreenDuration() {
    if (_screenStartTime != null) {
      final duration = DateTime.now().difference(_screenStartTime!);
      UserJourneyAnalytics.instance.trackPerformance(
        'screen_duration',
        duration.inSeconds.toDouble(),
        properties: {'screen_name': screenName},
      );
    }
  }

  // Helper methods for common tracking
  void trackButtonTap(String buttonName, {Map<String, dynamic>? properties}) {
    UserJourneyAnalytics.instance.trackEngagement(
      'button_tap',
      target: buttonName,
      properties: properties,
    );
  }

  void trackFormSubmission(String formName, {bool success = true}) {
    UserJourneyAnalytics.instance.trackEvent(
      'form_submission',
      properties: {'form_name': formName, 'success': success},
      category: 'form',
    );
  }

  void trackUserAction(String action, {Map<String, dynamic>? properties}) {
    UserJourneyAnalytics.instance.trackEngagement(
      action,
      properties: properties,
    );
  }
}
