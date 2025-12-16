/// Script to fix deprecated withOpacity() -> withValues(alpha:)
/// 
/// Usage:
/// ```bash
/// dart run scripts/fix_deprecated_apis.dart
/// ```
/// 
/// This script finds all instances of .withOpacity() and replaces them with .withValues(alpha:)

import 'dart:io';

void main() async {
  print('🔧 Fixing deprecated withOpacity() APIs...\n');
  
  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    print('❌ lib directory not found. Run from app root.');
    exit(1);
  }
  
  int totalFixed = 0;
  int totalFiles = 0;
  
  await _processDirectory(libDir, (file) {
    if (file.path.endsWith('.dart')) {
      totalFiles++;
      final fixed = _fixFile(file);
      if (fixed > 0) {
        totalFixed += fixed;
        print('✅ Fixed $fixed instances in ${file.path}');
      }
    }
  });
  
  print('\n📊 Summary:');
  print('   Files processed: $totalFiles');
  print('   Instances fixed: $totalFixed');
  print('\n✅ Done! Review changes before committing.');
}

Future<void> _processDirectory(Directory dir, Function(File) processor) async {
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) {
      processor(entity);
    }
  }
}

int _fixFile(File file) {
  try {
    String content = file.readAsStringSync();
    final originalContent = content;
    
    // Pattern: .withOpacity(value) -> .withValues(alpha: value)
    // Match: .withOpacity(0.5) or .withOpacity(0.5) with whitespace
    final pattern = RegExp(r'\.withOpacity\s*\(\s*([\d.]+)\s*\)');
    
    content = content.replaceAllMapped(pattern, (match) {
      final opacityValue = match.group(1);
      return '.withValues(alpha: $opacityValue)';
    });
    
    if (content != originalContent) {
      file.writeAsStringSync(content);
      // Count replacements
      return pattern.allMatches(originalContent).length;
    }
    
    return 0;
  } catch (e) {
    print('⚠️ Error processing ${file.path}: $e');
    return 0;
  }
}

