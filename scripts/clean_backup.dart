import 'dart:convert';
import 'dart:io';

/// Clean backup - Remove demo/test users, keep only real users

class CleanBackup {
  static Future<void> clean(String backupFile) async {
    print('🧹 CLEANING BACKUP - REMOVING DEMO/TEST USERS...\n');

    // Read backup file
    print('📂 Reading backup file: $backupFile');
    final file = File(backupFile);
    if (!await file.exists()) {
      throw Exception('Backup file not found: $backupFile');
    }

    final content = await file.readAsString();
    final backup = jsonDecode(content);

    final allUsers = List<Map<String, dynamic>>.from(backup['users']);
    print('✅ Found ${allUsers.length} users in backup\n');

    // Filter: Keep only real users
    print('🔍 Filtering users...');
    final realUsers = allUsers.where((user) {
      final email = user['email'] as String?;

      if (email == null || email.isEmpty) {
        return false; // Remove no-email users
      }

      // Remove demo/test patterns
      if (email.contains('@temp.demo')) return false;
      if (email.contains('@demo.billiards.vn')) return false;
      if (email.contains('demo') && email.contains('@saboarena.com'))
        return false;
      if (email.contains('test') && email.contains('@example.com'))
        return false;
      if (email.startsWith('test_')) return false;
      if (email.startsWith('test-')) return false;

      // Keep real users (Gmail + Sabo Media + others)
      return true;
    }).toList();

    print('✅ Filtered: ${realUsers.length} real users\n');

    // Show what was removed
    final removed = allUsers.length - realUsers.length;
    print('📊 Summary:');
    print('   Original:  ${allUsers.length} users');
    print('   Kept:      ${realUsers.length} users');
    print('   Removed:   $removed users\n');

    // Show kept users
    print('✅ USERS TO KEEP (${realUsers.length}):');
    print('=' * 70);

    final gmailUsers = realUsers
        .where((u) => (u['email'] as String).contains('@gmail.com'))
        .toList();
    final otherUsers = realUsers
        .where((u) => !(u['email'] as String).contains('@gmail.com'))
        .toList();

    print('Gmail users: ${gmailUsers.length}');
    for (var i = 0; i < gmailUsers.length && i < 10; i++) {
      print('  ${i + 1}. ${gmailUsers[i]['email']}');
    }
    if (gmailUsers.length > 10) {
      print('  ... and ${gmailUsers.length - 10} more');
    }

    if (otherUsers.isNotEmpty) {
      print('\nOther users: ${otherUsers.length}');
      for (var i = 0; i < otherUsers.length && i < 10; i++) {
        print('  ${i + 1}. ${otherUsers[i]['email']}');
      }
      if (otherUsers.length > 10) {
        print('  ... and ${otherUsers.length - 10} more');
      }
    }
    print('=' * 70);
    print('');

    // Save cleaned backup
    final cleanedFilename = backupFile.replaceAll('.json', '_cleaned.json');
    final cleanedFile = File(cleanedFilename);

    print('💾 Saving cleaned backup to: $cleanedFilename');
    await cleanedFile.writeAsString(
      JsonEncoder.withIndent('  ').convert({
        'backup_date': backup['backup_date'],
        'cleaned_date': DateTime.now().toIso8601String(),
        'source': backup['source'],
        'original_count': allUsers.length,
        'cleaned_count': realUsers.length,
        'removed_count': removed,
        'total_users': realUsers.length,
        'users': realUsers,
      }),
    );

    print('✅ Cleaned backup saved!\n');

    // Summary
    print('=' * 70);
    print('🎉 CLEANING COMPLETE!');
    print('=' * 70);
    print('Original file:   $backupFile (${allUsers.length} users)');
    print('Cleaned file:    $cleanedFilename (${realUsers.length} users)');
    print('Removed:         $removed demo/test users');
    print(
      'File size:       ${(await cleanedFile.length() / 1024).toStringAsFixed(2)} KB',
    );
    print('=' * 70);
    print('');
    print('✅ Ready to restore cleaned backup!');
    print('   Run: dart run scripts/restore_from_backup.dart $cleanedFilename');
  }
}

void main(List<String> args) async {
  try {
    if (args.isEmpty) {
      print('Usage: dart run scripts/clean_backup.dart <backup_file.json>');
      exit(1);
    }

    await CleanBackup.clean(args[0]);
  } catch (e) {
    print('\n❌ Clean failed: $e');
    exit(1);
  }
}
