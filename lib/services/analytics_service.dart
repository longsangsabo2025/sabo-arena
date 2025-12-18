/// Analytics Service for SABO Arena
/// Tracks events to unified analytics database
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class AnalyticsService {
  static const String _supabaseUrl = 'https://diexsbzqwsbpilsymnfb.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpZXhzYnpxd3NicGlsc3ltbmZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE3NTczMDIsImV4cCI6MjA0NzMzMzMwMn0.T8dCzPiLLlc3vI9nWY0xjU5Q9JcA9vXX_QRs-z3xvBw';
  static const String _productName = 'sabo-arena';

  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;

  String? _sessionId;
  String? _anonymousId;
  String? _deviceType;
  String? _browser;
  String? _os;

  AnalyticsService._internal() {
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Get or create anonymous ID
    _anonymousId = prefs.getString('analytics_anonymous_id');
    if (_anonymousId == null) {
      _anonymousId = const Uuid().v4();
      await prefs.setString('analytics_anonymous_id', _anonymousId!);
    }

    // Create new session ID
    _sessionId = const Uuid().v4();

    // Detect device info
    await _detectDeviceInfo();
  }

  Future<void> _detectDeviceInfo() async {
    if (kIsWeb) {
      _browser = 'Web Browser';
      _os = 'Web';
      _deviceType = 'desktop';
      return;
    }
    
    if (Platform.isAndroid) {
      _deviceType = 'mobile';
      _os = 'Android';
      _browser = 'Native App';
    } else if (Platform.isIOS) {
      _deviceType = 'mobile';
      _os = 'iOS';
      _browser = 'Native App';
    } else {
      _deviceType = 'desktop';
      _os = Platform.operatingSystem;
      _browser = 'Desktop App';
    }
  }

  /// Track page view
  Future<void> trackPageView(String pageName, {String? pageTitle}) async {
    await _trackEvent(
      eventType: 'page_view',
      eventName: pageName,
      properties: {
        'page_title': pageTitle ?? pageName,
        'page_url': '/$pageName',
      },
    );
  }

  /// Track button click
  Future<void> trackClick(String buttonName, {Map<String, dynamic>? properties}) async {
    await _trackEvent(
      eventType: 'click',
      eventName: buttonName,
      properties: properties,
    );
  }

  /// Track form submission
  Future<void> trackFormSubmit(String formName, {Map<String, dynamic>? properties}) async {
    await _trackEvent(
      eventType: 'form_submit',
      eventName: formName,
      properties: properties,
    );
  }

  /// Track conversion (e.g., tournament registration, payment)
  Future<void> trackConversion(String conversionName, {double? value, Map<String, dynamic>? properties}) async {
    final props = properties ?? {};
    if (value != null) props['value'] = value;

    await _trackEvent(
      eventType: 'conversion',
      eventName: conversionName,
      properties: props,
    );
  }

  /// Track error
  Future<void> trackError(String errorMessage, {String? stackTrace, Map<String, dynamic>? properties}) async {
    final props = properties ?? {};
    props['error_message'] = errorMessage;
    if (stackTrace != null) props['stack_trace'] = stackTrace;

    await _trackEvent(
      eventType: 'error',
      eventName: 'error_occurred',
      properties: props,
    );
  }

  /// Track tournament-specific events
  Future<void> trackTournamentEvent(
    String eventName, {
    String? tournamentId,
    String? tournamentType,
    int? playerCount,
    Map<String, dynamic>? properties,
  }) async {
    final props = properties ?? {};
    if (tournamentId != null) props['tournament_id'] = tournamentId;
    if (tournamentType != null) props['tournament_type'] = tournamentType;
    if (playerCount != null) props['player_count'] = playerCount;

    await _trackEvent(
      eventType: 'feature_used',
      eventName: eventName,
      properties: props,
    );
  }

  /// Track match events
  Future<void> trackMatchEvent(
    String eventName, {
    String? matchId,
    String? player1,
    String? player2,
    String? winner,
    Map<String, dynamic>? properties,
  }) async {
    final props = properties ?? {};
    if (matchId != null) props['match_id'] = matchId;
    if (player1 != null) props['player1'] = player1;
    if (player2 != null) props['player2'] = player2;
    if (winner != null) props['winner'] = winner;

    await _trackEvent(
      eventType: 'feature_used',
      eventName: eventName,
      properties: props,
    );
  }

  Future<void> _trackEvent({
    required String eventType,
    required String eventName,
    String? eventCategory,
    String? userId,
    Map<String, dynamic>? properties,
  }) async {
    try {
      final event = {
        'product_name': _productName,
        'event_type': eventType,
        'event_name': eventName,
        'event_category': eventCategory,
        'user_id': userId,
        'session_id': _sessionId,
        'anonymous_id': _anonymousId,
        'device_type': _deviceType,
        'browser': _browser,
        'os': _os,
        'properties': properties != null ? jsonEncode(properties) : null,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/analytics_events'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(event),
      );

      if (response.statusCode != 201) {
        ProductionLogger.info('❌ Analytics tracking failed: ${response.statusCode} ${response.body}', tag: 'analytics_service');
      }
    } catch (e) {
      ProductionLogger.info('❌ Analytics error: $e', tag: 'analytics_service');
    }
  }
}
