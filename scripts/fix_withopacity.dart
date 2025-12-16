// Auto-fix deprecated withOpacity() calls
// Run with: dart scripts/fix_withopacity.dart

import 'dart:io';

void main() async {
  print('🚀 Starting withOpacity() cleanup...\n');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ lib directory not found!');
    return;
  }

  var totalFiles = 0;
  var totalFixed = 0;

  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      
      if (!content.contains('.withOpacity(')) {
        continue;
      }

      totalFiles++;
      
      final matches = RegExp(r'\.withOpacity\(').allMatches(content).length;
      totalFixed += matches;

      // Replace .withOpacity(x) with .withValues(alpha: x)
      final newContent = content.replaceAllMapped(
        RegExp(r'\.withOpacity\(([^)]+)\)'),
        (match) {
          final alpha = match.group(1)!.trim();
          return '.withValues(alpha: $alpha)';
        },
      );

      if (newContent != content) {
        await entity.writeAsString(newContent);
        print('✅ Fixed $matches withOpacity() in: ${entity.path}');
      }
    }
  }

  print('\n📊 Summary:');
  print('   Files modified: $totalFiles');
  print('   withOpacity() calls fixed: $totalFixed');
  print('\n✅ Done!');
}
