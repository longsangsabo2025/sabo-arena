import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🔍 Connection Diagnostics Widget
///
/// Shows in production to help diagnose connection issues.
/// Can be accessed from login screen when user taps logo 5 times.
class ConnectionDiagnosticsDialog extends StatefulWidget {
  const ConnectionDiagnosticsDialog({super.key});

  @override
  State<ConnectionDiagnosticsDialog> createState() =>
      _ConnectionDiagnosticsDialogState();
}

class _ConnectionDiagnosticsDialogState
    extends State<ConnectionDiagnosticsDialog> {
  bool _isChecking = false;
  Map<String, dynamic> _diagnostics = {};

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isChecking = true);

    final results = <String, dynamic>{};

    // Check 1: Supabase initialization
    try {
      results['supabaseInitialized'] = SupabaseService.instance.isInitialized;
      ProductionLogger.info(
        'Diagnostics: Supabase initialized = ${results['supabaseInitialized']}',
      );
    } catch (e) {
      results['supabaseInitialized'] = false;
      results['supabaseError'] = e.toString();
      ProductionLogger.error('Diagnostics: Supabase check failed', error: e);
    }

    // Check 2: Network connectivity (simple check)
    try {
      final client = SupabaseService.instance.client;
      results['clientAvailable'] = true;

      // Try to get auth status
      final user = client.auth.currentUser;
      results['currentUser'] = user != null ? 'Logged in' : 'Not logged in';

      ProductionLogger.info(
        'Diagnostics: Client available, user = ${results['currentUser']}',
      );
    } catch (e) {
      results['clientAvailable'] = false;
      results['clientError'] = e.toString();
      ProductionLogger.error('Diagnostics: Client check failed', error: e);
    }

    // Check 3: Build mode
    results['buildMode'] = kDebugMode
        ? 'Debug'
        : (kReleaseMode ? 'Release' : 'Profile');
    results['platform'] = defaultTargetPlatform.toString();

    ProductionLogger.info(
      'Diagnostics: Build mode = ${results['buildMode']}, Platform = ${results['platform']}',
    );

    setState(() {
      _diagnostics = results;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.orange),
          SizedBox(width: 8),
          Text('Chẩn đoán kết nối'),
        ],
      ),
      content: _isChecking
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang kiểm tra...'),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin hệ thống:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._diagnostics.entries.map((entry) {
                    final isError = entry.key.contains('Error');
                    final isSuccess =
                        entry.value == true ||
                        entry.value == 'Logged in' ||
                        (entry.key == 'supabaseInitialized' &&
                            entry.value == true);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isError
                                ? Icons.error
                                : (isSuccess ? Icons.check_circle : Icons.info),
                            size: 16,
                            color: isError
                                ? Colors.red
                                : (isSuccess ? Colors.green : Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatKey(entry.key),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  entry.value.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isError ? Colors.red : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 Nếu gặp lỗi:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '1. Kiểm tra kết nối internet\n'
                          '2. Khởi động lại ứng dụng\n'
                          '3. Liên hệ hỗ trợ nếu vẫn lỗi',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        if (!_isChecking)
          TextButton(
            onPressed: _runDiagnostics,
            child: const Text('Kiểm tra lại'),
          ),
      ],
    );
  }

  String _formatKey(String key) {
    final map = {
      'supabaseInitialized': 'Supabase đã khởi tạo',
      'supabaseError': 'Lỗi Supabase',
      'clientAvailable': 'Client khả dụng',
      'clientError': 'Lỗi Client',
      'currentUser': 'Trạng thái người dùng',
      'buildMode': 'Chế độ build',
      'platform': 'Nền tảng',
    };
    return map[key] ?? key;
  }
}
