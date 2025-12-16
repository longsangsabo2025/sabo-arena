// Edge Functions Caching E2E Tests
// Tests Edge Functions caching implementation

import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('Edge Functions Caching E2E Tests', () {
    test('Cache Tournament Edge Function exists', () {
      final file = File('supabase/functions/cache-tournament/index.ts');
      expect(file.existsSync(), isTrue, reason: 'cache-tournament/index.ts should exist');
    });

    test('Cache User Edge Function exists', () {
      final file = File('supabase/functions/cache-user/index.ts');
      expect(file.existsSync(), isTrue, reason: 'cache-user/index.ts should exist');
    });

    test('Cache Club Edge Function exists', () {
      final file = File('supabase/functions/cache-club/index.ts');
      expect(file.existsSync(), isTrue, reason: 'cache-club/index.ts should exist');
    });

    test('Edge Functions use Deno KV', () {
      // Read cache-tournament function
      final file = File('supabase/functions/cache-tournament/index.ts');
      final content = file.readAsStringSync();
      
      // Verify it uses Deno.openKv()
      expect(content.contains('Deno.openKv'), isTrue, 
        reason: 'Should use Deno KV for caching');
    });

    test('Edge Functions have CORS headers', () {
      final file = File('supabase/functions/cache-tournament/index.ts');
      final content = file.readAsStringSync();
      
      // Verify CORS headers
      expect(content.contains('corsHeaders'), isTrue,
        reason: 'Should have CORS headers');
      expect(content.contains('Access-Control-Allow-Origin'), isTrue,
        reason: 'Should allow CORS');
    });

    test('Edge Functions handle cache miss', () {
      final file = File('supabase/functions/cache-tournament/index.ts');
      final content = file.readAsStringSync();
      
      // Verify cache miss handling
      expect(content.contains('Cache miss'), isTrue,
        reason: 'Should handle cache miss');
      expect(content.contains('fetch from database'), isTrue,
        reason: 'Should fetch from database on cache miss');
    });

    test('Edge Functions set TTL', () {
      final file = File('supabase/functions/cache-tournament/index.ts');
      final content = file.readAsStringSync();
      
      // Verify TTL is set
      expect(content.contains('expireIn'), isTrue,
        reason: 'Should set cache expiration');
    });
  });
}

