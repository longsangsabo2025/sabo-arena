// Test Environment Helper
// Automatically loads env.json and initializes Supabase for tests

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class TestEnvHelper {
  static Map<String, dynamic>? _env;
  static bool _isInitialized = false;

  /// Load environment variables from env.json
  static Future<Map<String, dynamic>> loadEnv() async {
    if (_env != null) return _env!;

    try {
      final file = File('env.json');
      if (!await file.exists()) {
        throw Exception('env.json not found. Please create it in the app root.');
      }

      final content = await file.readAsString();
      _env = jsonDecode(content) as Map<String, dynamic>;
      return _env!;
    } catch (e) {
      throw Exception('Failed to load env.json: $e');
    }
  }

  /// Get Supabase URL from env.json
  static Future<String> getSupabaseUrl() async {
    final env = await loadEnv();
    final url = env['SUPABASE_URL'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in env.json');
    }
    return url;
  }

  /// Get Supabase Anon Key from env.json
  static Future<String> getSupabaseAnonKey() async {
    final env = await loadEnv();
    final key = env['SUPABASE_ANON_KEY'] as String?;
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in env.json');
    }
    return key;
  }

  /// Initialize Supabase for tests
  static Future<void> initializeSupabase() async {
    if (_isInitialized) return;

    try {
      // Ensure Flutter binding is initialized for plugins
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Mock SharedPreferences for tests
      const MethodChannel('plugins.flutter.io/shared_preferences')
          .setMockMethodCallHandler((call) async {
        if (call.method == 'getAll') {
          return <String, dynamic>{};
        }
        return null;
      });

      final url = await getSupabaseUrl();
      final anonKey = await getSupabaseAnonKey();

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false, // Tests should not be in debug mode
      );

      _isInitialized = true;
      print('✅ Supabase initialized for tests from env.json');
    } catch (e) {
      print('⚠️ Failed to initialize Supabase: $e');
      print('⚠️ Some tests may fail without Supabase initialization');
      // Don't rethrow - allow tests to continue
    }
  }

  /// Setup for tests (call in setUpAll)
  static Future<void> setup() async {
    await initializeSupabase();
  }

  /// Cleanup after tests (call in tearDownAll)
  static Future<void> cleanup() async {
    // Supabase doesn't need explicit cleanup
    _isInitialized = false;
  }
}

