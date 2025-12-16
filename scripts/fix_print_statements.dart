#!/usr/bin/env dart
/// 🔥 ELON MODE: Auto-fix print() statements
/// 
/// This script replaces all print() and debugPrint() statements
/// with ProductionLogger calls
/// 
/// Usage: dart scripts/fix_print_statements.dart

import 'dart:io';

void main() async {
  print('🚀 Starting print() statement cleanup...\n');
  
  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    print('❌ Error: lib/ directory not found');
    exit(1);
  }

  int totalFiles = 0;
  int totalReplacements = 0;
  final processedFiles = <String>[];

  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Skip generated files and production_logger itself
      if (entity.path.contains('.g.dart') || 
          entity.path.contains('.freezed.dart') ||
          entity.path.contains('production_logger.dart')) {
        continue;
      }

      var content = await entity.readAsString();
      final originalContent = content;
      
      // Check if file uses print or debugPrint
      if (!content.contains('print(') && !content.contains('debugPrint(')) {
        continue;
      }

      // Check if ProductionLogger is already imported
      final hasLoggerImport = content.contains('production_logger.dart') ||
                             content.contains('ProductionLogger');

      // Count replacements before
      final printCount = RegExp(r'\bprint\s*\(').allMatches(content).length;
      final debugPrintCount = RegExp(r'\bdebugPrint\s*\(').allMatches(content).length;

      // Replace simple print('string') patterns
      content = content.replaceAllMapped(
        RegExp(r"\bprint\s*\(\s*'([^']+)'\s*\)"),
        (match) {
          final message = match.group(1)!;
          return "ProductionLogger.info('$message')";
        },
      );

      // Replace print("string") patterns  
      content = content.replaceAllMapped(
        RegExp(r'\bprint\s*\(\s*"([^"]+)"\s*\)'),
        (match) {
          final message = match.group(1)!;
          return 'ProductionLogger.info("$message")';
        },
      );

      // Replace simple debugPrint('string') patterns
      content = content.replaceAllMapped(
        RegExp(r"\bdebugPrint\s*\(\s*'([^']+)'\s*\)"),
        (match) {
          final message = match.group(1)!;
          return "ProductionLogger.debug('$message')";
        },
      );

      // Replace debugPrint("string") patterns
      content = content.replaceAllMapped(
        RegExp(r'\bdebugPrint\s*\(\s*"([^"]+)"\s*\)'),
        (match) {
          final message = match.group(1)!;
          return 'ProductionLogger.debug("$message")';
        },
      );

      // Add import if needed and content changed
      if (content != originalContent) {
        if (!hasLoggerImport) {
          // Find the last import statement
          final importMatches = RegExp(r"^import\s+['\"][^'\"]+['\"];", multiLine: true)
              .allMatches(content).toList();
          
          if (importMatches.isNotEmpty) {
            final lastImport = importMatches.last;
            final insertIndex = lastImport.end;
            
            // Calculate relative path
            final relativePath = _calculateRelativePath(entity.path);
            final importStatement = "\nimport '$relativePath';";
            
            content = content.substring(0, insertIndex) + 
                     importStatement + 
                     content.substring(insertIndex);
          } else {
            // No imports, add at top
            content = "import 'utils/production_logger.dart';\n\n$content";
          }
        }

        await entity.writeAsString(content);
        final replacements = printCount + debugPrintCount;
        totalReplacements += replacements;
        totalFiles++;
        processedFiles.add(entity.path);
        
        print('✅ Fixed: ${entity.path} ($replacements replacements)');
      }
    }
  }

  print('\n📊 Summary:');
  print('   Files processed: $totalFiles');
  print('   Total replacements: $totalReplacements');
  print('\n✅ Cleanup complete!');
  
  if (processedFiles.isNotEmpty) {
    print('\n📝 Files modified:');
    for (final file in processedFiles.take(30)) {
      print('   - $file');
    }
    if (processedFiles.length > 30) {
      print('   ... and ${processedFiles.length - 30} more');
    }
  }
}

String _calculateRelativePath(String filePath) {
  // Calculate relative path from file to lib/utils/production_logger.dart
  final normalizedPath = filePath.replaceAll('\\', '/');
  final parts = normalizedPath.split('/');
  final libIndex = parts.indexOf('lib');
  if (libIndex == -1) return '../utils/production_logger.dart';
  
  final depth = parts.length - libIndex - 2; // -2 for lib and filename
  if (depth <= 0) return 'utils/production_logger.dart';
  if (depth == 1) return '../utils/production_logger.dart';
  
  final prefix = List.filled(depth, '..').join('/');
  return '$prefix/utils/production_logger.dart';
}

