// Auto-fix print() and debugPrint() statements to ProductionLogger
// Run with: dart scripts/auto_fix_prints.dart

import 'dart:io';

void main() async {
  print('🚀 Starting print() and debugPrint() cleanup...\n');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ lib directory not found!');
    return;
  }

  var totalFiles = 0;
  var totalFixed = 0;
  var skippedFiles = <String>[];

  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Skip logger files
      if (entity.path.contains('production_logger.dart') ||
          entity.path.contains('dev_error_handler.dart') ||
          entity.path.contains('app_logger.dart') ||
          entity.path.contains('longsang_error_reporter.dart')) {
        skippedFiles.add(entity.path);
        continue;
      }

      final content = await entity.readAsString();
      
      // Check if file has print() or debugPrint() statements
      if (!content.contains('print(') && !content.contains('debugPrint(')) {
        continue;
      }

      totalFiles++;
      
      // Count statements
      final printCount = RegExp(r'\bprint\(').allMatches(content).length;
      final debugPrintCount = RegExp(r'\bdebugPrint\(').allMatches(content).length;
      
      if (printCount == 0 && debugPrintCount == 0) continue;

      totalFixed += printCount + debugPrintCount;

      var newContent = content;
      
      // Add import if needed
      final hasImport = content.contains("production_logger.dart");
      
      if (!hasImport) {
        final importMatches = RegExp(r"import\s+'[^']+';").allMatches(content).toList();
        if (importMatches.isNotEmpty) {
          final lastImport = importMatches.last;
          final insertPosition = lastImport.end;
          // Using a relative path assumption or package import if possible.
          // Trying to be safe with a comment.
          newContent = newContent.substring(0, insertPosition) +
              "\nimport 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX" +
              newContent.substring(insertPosition);
        }
      }

      // Replace print() with ProductionLogger.info()
      newContent = newContent.replaceAllMapped(
        RegExp(r"print\(([^;]*)\);", multiLine: true, dotAll: true),
        (match) {
          final arg = match.group(1)!.trim();
          final filename = entity.path.split(Platform.pathSeparator).last.replaceAll('.dart', '');
          return "ProductionLogger.info(, tag: '');";
        },
      );

      // Replace debugPrint() with ProductionLogger.debug()
      newContent = newContent.replaceAllMapped(
        RegExp(r"debugPrint\(([^;]*)\);", multiLine: true, dotAll: true),
        (match) {
          final arg = match.group(1)!.trim();
          final filename = entity.path.split(Platform.pathSeparator).last.replaceAll('.dart', '');
          return "ProductionLogger.debug(, tag: '');";
        },
      );

      // Write back
      if (newContent != content) {
        await entity.writeAsString(newContent);
        print('✅ Fixed  logs in: ');
      }
    }
  }

  print('\n📊 Summary:');
  print('   Files modified: ');
  print('   Statements fixed: ');
  print('   Files skipped: ');
  print('\n✅ Done!');
}
