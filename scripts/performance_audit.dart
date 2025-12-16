// Performance Audit Script
// Analyzes codebase for performance issues and optimization opportunities

import 'dart:io';

void main() async {
  print('🔍 SABO Arena Performance Audit');
  print('================================\n');

  // Check for common performance issues
  await checkPagination();
  await checkNPlusOneQueries();
  await checkImageOptimization();
  await checkCaching();
  await checkIndexes();

  print('\n✅ Performance audit complete!');
}

Future<void> checkPagination() async {
  print('📄 Checking pagination implementation...');
  
  final serviceFiles = Directory('lib/services')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  int filesWithPagination = 0;
  int filesWithoutPagination = 0;
  final filesNeedingPagination = <String>[];

  for (final file in serviceFiles) {
    final content = await file.readAsString();
    
    // Check if file has list queries
    final hasListQuery = content.contains('.select(') && 
                        (content.contains('getTournaments') || 
                         content.contains('getUsers') || 
                         content.contains('getClubs') ||
                         content.contains('getMatches') ||
                         content.contains('getMessages'));
    
    if (hasListQuery) {
      // Check if pagination is implemented
      final hasPagination = content.contains('.range(') || 
                           content.contains('.limit(') ||
                           content.contains('page') ||
                           content.contains('pageSize') ||
                           content.contains('QueryOptimizer');
      
      if (hasPagination) {
        filesWithPagination++;
      } else {
        filesWithoutPagination++;
        filesNeedingPagination.add(file.path);
      }
    }
  }

  print('   ✅ Files with pagination: $filesWithPagination');
  if (filesWithoutPagination > 0) {
    print('   ⚠️  Files needing pagination: $filesWithoutPagination');
    for (final file in filesNeedingPagination.take(5)) {
      print('      - $file');
    }
    if (filesNeedingPagination.length > 5) {
      print('      ... and ${filesNeedingPagination.length - 5} more');
    }
  }
  print('');
}

Future<void> checkNPlusOneQueries() async {
  print('🔍 Checking for N+1 query patterns...');
  
  final serviceFiles = Directory('lib/services')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  int potentialNPlusOne = 0;
  final filesWithNPlusOne = <String>[];

  for (final file in serviceFiles) {
    final content = await file.readAsString();
    
    // Check for loops with queries inside
    final hasLoop = content.contains('for (') || content.contains('.forEach(');
    final hasQueryInLoop = hasLoop && 
                          (content.contains('.select(') || 
                           content.contains('.from('));
    
    if (hasQueryInLoop) {
      potentialNPlusOne++;
      filesWithNPlusOne.add(file.path);
    }
  }

  print('   ⚠️  Potential N+1 queries found: $potentialNPlusOne');
  if (filesWithNPlusOne.isNotEmpty) {
    for (final file in filesWithNPlusOne.take(5)) {
      print('      - $file');
    }
    if (filesWithNPlusOne.length > 5) {
      print('      ... and ${filesWithNPlusOne.length - 5} more');
    }
  }
  print('');
}

Future<void> checkImageOptimization() async {
  print('🖼️  Checking image optimization...');
  
  final hasImageOptimization = File('lib/services/image_optimization_service.dart').existsSync();
  final hasCDN = File('lib/services/cdn_service.dart').existsSync();
  
  print('   ${hasImageOptimization ? "✅" : "❌"} Image optimization service: ${hasImageOptimization ? "Found" : "Missing"}');
  print('   ${hasCDN ? "✅" : "❌"} CDN service: ${hasCDN ? "Found" : "Missing"}');
  print('');
}

Future<void> checkCaching() async {
  print('💾 Checking caching implementation...');
  
  final hasCacheManager = File('lib/services/cache_manager.dart').existsSync();
  final hasRedisCache = File('lib/services/redis_cache_service.dart').existsSync();
  final hasResilientCache = File('lib/services/resilient_cache_service.dart').existsSync();
  final hasEdgeFunctions = Directory('supabase/functions').existsSync();
  
  print('   ${hasCacheManager ? "✅" : "❌"} Cache Manager: ${hasCacheManager ? "Found" : "Missing"}');
  print('   ${hasRedisCache ? "✅" : "❌"} Redis Cache: ${hasRedisCache ? "Found" : "Missing"}');
  print('   ${hasResilientCache ? "✅" : "❌"} Resilient Cache: ${hasResilientCache ? "Found" : "Missing"}');
  print('   ${hasEdgeFunctions ? "✅" : "❌"} Edge Functions: ${hasEdgeFunctions ? "Found" : "Missing"}');
  print('');
}

Future<void> checkIndexes() async {
  print('📊 Checking database indexes...');
  
  final hasIndexMigration = File('migrations_organized/04_data_integrity/migration_4_scaling_indexes.sql').existsSync();
  
  print('   ${hasIndexMigration ? "✅" : "❌"} Index migration: ${hasIndexMigration ? "Found" : "Missing"}');
  print('');
}

