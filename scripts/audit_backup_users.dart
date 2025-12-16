import 'dart:convert';
import 'dart:io';

/// Audit users in backup file
/// Analyze and categorize users before restore

class AuditBackupUsers {
  static Future<void> audit(String backupFile) async {
    print('🔍 AUDITING BACKUP USERS...\n');

    // Read backup file
    print('📂 Reading backup file: $backupFile');
    final file = File(backupFile);
    if (!await file.exists()) {
      throw Exception('Backup file not found: $backupFile');
    }

    final content = await file.readAsString();
    final backup = jsonDecode(content);

    final users = List<Map<String, dynamic>>.from(backup['users']);
    print('✅ Found ${users.length} users in backup\n');

    print('Backup info:');
    print('  Date: ${backup['backup_date']}');
    print('  Source: ${backup['source']}');
    print('  Total: ${backup['total_users']}\n');

    // Categorize users
    print('🔍 Analyzing users...\n');

    final categories = {
      'real_gmail': <Map<String, dynamic>>[],
      'real_other': <Map<String, dynamic>>[],
      'demo_temp': <Map<String, dynamic>>[],
      'demo_saboarena': <Map<String, dynamic>>[],
      'test_users': <Map<String, dynamic>>[],
      'no_email': <Map<String, dynamic>>[],
      'sabo_media': <Map<String, dynamic>>[],
      'other': <Map<String, dynamic>>[],
    };

    for (var user in users) {
      final email = user['email'] as String?;

      if (email == null || email.isEmpty) {
        categories['no_email']!.add(user);
      } else if (email.contains('@temp.demo')) {
        categories['demo_temp']!.add(user);
      } else if (email.contains('@demo.billiards.vn')) {
        categories['demo_temp']!.add(user);
      } else if (email.contains('demo') && email.contains('@saboarena.com')) {
        categories['demo_saboarena']!.add(user);
      } else if (email.contains('test') || email.contains('@example.com')) {
        categories['test_users']!.add(user);
      } else if (email.contains('sabomedia')) {
        categories['sabo_media']!.add(user);
      } else if (email.contains('@gmail.com')) {
        categories['real_gmail']!.add(user);
      } else if (email.contains('@')) {
        categories['real_other']!.add(user);
      } else {
        categories['other']!.add(user);
      }
    }

    // Print summary
    print('=' * 70);
    print('📊 AUDIT SUMMARY');
    print('=' * 70);
    print('');

    print(
      '✅ REAL USERS (${categories['real_gmail']!.length + categories['real_other']!.length}):',
    );
    print('   Gmail users:     ${categories['real_gmail']!.length}');
    print('   Other emails:    ${categories['real_other']!.length}');
    print('');

    print(
      '⚠️  DEMO/TEST USERS (${categories['demo_temp']!.length + categories['demo_saboarena']!.length + categories['test_users']!.length}):',
    );
    print('   @temp.demo:      ${categories['demo_temp']!.length}');
    print('   demo@saboarena:  ${categories['demo_saboarena']!.length}');
    print('   Test users:      ${categories['test_users']!.length}');
    print('');

    print('📧 SABO MEDIA:      ${categories['sabo_media']!.length}');
    print('❌ NO EMAIL:        ${categories['no_email']!.length}');
    print('❓ OTHER:           ${categories['other']!.length}');
    print('');
    print('=' * 70);

    // Detailed lists
    print('\n📋 DETAILED BREAKDOWN:\n');

    _printCategory('✅ REAL GMAIL USERS', categories['real_gmail']!);
    _printCategory('✅ REAL OTHER EMAILS', categories['real_other']!);
    _printCategory('📧 SABO MEDIA USERS', categories['sabo_media']!);
    _printCategory('⚠️  DEMO TEMP USERS', categories['demo_temp']!);
    _printCategory('⚠️  DEMO SABOARENA USERS', categories['demo_saboarena']!);
    _printCategory('⚠️  TEST USERS', categories['test_users']!);
    _printCategory('❌ NO EMAIL USERS', categories['no_email']!);

    // Recommendations
    print('\n' + '=' * 70);
    print('💡 RECOMMENDATIONS');
    print('=' * 70);

    final realCount =
        categories['real_gmail']!.length + categories['real_other']!.length;
    final demoCount =
        categories['demo_temp']!.length +
        categories['demo_saboarena']!.length +
        categories['test_users']!.length;

    print('');
    print('Total users in backup: ${users.length}');
    print('  ✅ Real users:       $realCount');
    print('  ⚠️  Demo/Test users:  $demoCount');
    print('  📧 Sabo Media:       ${categories['sabo_media']!.length}');
    print('  ❌ No email:         ${categories['no_email']!.length}');
    print('');

    if (demoCount > 0) {
      print('⚠️  WARNING: Backup contains $demoCount demo/test users!');
      print('   Consider cleaning before restore.');
    }

    if (categories['no_email']!.length > 0) {
      print(
        '⚠️  WARNING: ${categories['no_email']!.length} users have no email!',
      );
      print('   These will get auto-generated emails.');
    }

    print('');
    print('✅ Ready to restore? All ${users.length} users will be created.');
    print('=' * 70);
  }

  static void _printCategory(String title, List<Map<String, dynamic>> users) {
    if (users.isEmpty) return;

    print('$title (${users.length}):');
    print('-' * 70);

    final limit = users.length > 20 ? 20 : users.length;
    for (var i = 0; i < limit; i++) {
      final user = users[i];
      final email = user['email'] ?? '(no email)';
      final verified = user['email_confirmed_at'] != null ? '✓' : '✗';
      print('  ${i + 1}. $email [$verified]');
    }

    if (users.length > 20) {
      print('  ... and ${users.length - 20} more');
    }

    print('');
  }
}

void main(List<String> args) async {
  try {
    if (args.isEmpty) {
      print(
        'Usage: dart run scripts/audit_backup_users.dart <backup_file.json>',
      );
      exit(1);
    }

    await AuditBackupUsers.audit(args[0]);
  } catch (e) {
    print('\n❌ Audit failed: $e');
    exit(1);
  }
}
