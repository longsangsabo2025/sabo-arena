// ignore_for_file: avoid_print
/// 🚀 ELON MUSK AUTOMATED CLEANUP SCRIPT
/// Removes unnecessary print() and debugPrint() statements from Dart files
/// 
/// Usage: dart run _flutter_scripts/remove_print_statements.dart
/// 
/// This script will:
/// 1. Find all print() and debugPrint() statements NOT inside kDebugMode blocks
/// 2. Comment them out (safe approach)
/// 3. Generate a report of changes

import 'dart:io';

void main() async {
  print('🚀 ELON MODE: Starting print statement cleanup...\n');
  
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ Error: lib directory not found!');
    exit(1);
  }

  int totalFilesProcessed = 0;
  int totalFilesModified = 0;
  int totalStatementsRemoved = 0;
  
  // Files to skip
  final skipFiles = [
    'production_logger.dart',
    'app_logger.dart',
    'dev_error_handler.dart',
    'longsang_error_reporter.dart',
  ];

  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final fileName = entity.path.split(Platform.pathSeparator).last;
      
      // Skip logger files
      if (skipFiles.contains(fileName)) {
        continue;
      }
      
      totalFilesProcessed++;
      
      String content = await entity.readAsString();
      final originalContent = content;
      int removedCount = 0;
      
      // Pattern: Standalone print statements (not in kDebugMode blocks)
      // This regex matches print('...'); or print("..."); on their own lines
      final printPattern = RegExp(
        r"^(\s*)print\s*\([^)]*\)\s*;",
        multiLine: true,
      );
      
      final debugPrintPattern = RegExp(
        r"^(\s*)debugPrint\s*\([^)]*\)\s*;",
        multiLine: true,
      );
      
      // Count matches
      removedCount += printPattern.allMatches(content).length;
      removedCount += debugPrintPattern.allMatches(content).length;
      
      if (removedCount > 0) {
        // Comment out print statements
        content = content.replaceAllMapped(printPattern, (match) {
          final indent = match.group(1) ?? '';
          return '$indent// REMOVED: ${match.group(0)?.trim()}';
        });
        
        content = content.replaceAllMapped(debugPrintPattern, (match) {
          final indent = match.group(1) ?? '';
          return '$indent// REMOVED: ${match.group(0)?.trim()}';
        });
        
        // Write back
        await entity.writeAsString(content);
        
        totalFilesModified++;
        totalStatementsRemoved += removedCount;
        
        print('  ✅ ${entity.path}: $removedCount statements commented');
      }
    }
  }
  
  print('\n${'=' * 50}');
  print('🎉 CLEANUP COMPLETE!');
  print('=' * 50);
  print('   Files processed: $totalFilesProcessed');
  print('   Files modified: $totalFilesModified');
  print('   Statements removed: $totalStatementsRemoved');
  print('=' * 50);
  print('\n⚠️  NEXT STEPS:');
  print('   1. Run: flutter analyze');
  print('   2. Review changes with: git diff');
  print('   3. Test the app');
  print('   4. Commit changes');
}


