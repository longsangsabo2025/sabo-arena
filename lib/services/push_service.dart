import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _supabase = Supabase.instance.client;

  // 🌐 CRITICAL: Don't initialize Firebase on web - it will crash!
  // Use lazy getter instead of final field
  FirebaseMessaging? _messagingInstance;
  FirebaseMessaging get _messaging {
    if (kIsWeb) {
      throw UnsupportedError('Firebase Messaging not supported on web');
    }
    _messagingInstance ??= FirebaseMessaging.instance;
    return _messagingInstance!;
  }

  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // 🔥 Ensure Firebase is initialized (should already be done in main.dart)
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      } else {
      }
    } catch (e) {
      _initialized = true; // Mark as initialized to prevent retry loops
      return; // Can't continue without Firebase
    }

    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      iOS: iosSettings,
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _local.initialize(initSettings);

    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      // REMOVED: if (kDebugMode) print('Error setting foreground options: $e');
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification != null) {
        await _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
              presentBadge: true,
            ),
            android: AndroidNotificationDetails('default_channel', 'General'),
          ),
          payload: message.data.isNotEmpty ? message.data.toString() : null,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) async {},
    );

    _initialized = true;
  }

  Future<void> registerForPush(String userId) async {
    // 🌐 Skip push notifications on web (Firebase FCM not supported properly)
    if (kIsWeb) {
      return;
    }

    await initialize();

    if (kIsWeb) return;

    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final platform = Platform.isIOS
          ? 'ios'
          : (Platform.isAndroid ? 'android' : 'web');

      await _supabase.from('device_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');
    } catch (e) {
      // REMOVED: if (kDebugMode) print('Error registering push token: $e');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        final platform = Platform.isIOS
            ? 'ios'
            : (Platform.isAndroid ? 'android' : 'other');
        await _supabase.from('device_tokens').upsert({
          'user_id': userId,
          'token': newToken,
          'platform': platform,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'token');
      } catch (e) {
        // REMOVED: if (kDebugMode) print('Error refreshing push token: $e');
      }
    });
  }
}

