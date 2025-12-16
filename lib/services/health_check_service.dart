import 'package:http/http.dart' as http;

class HealthCheckService {
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('/api/health'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return {
          'status': 'healthy',
          'timestamp': DateTime.now().toIso8601String(),
          'service': 'sabo-arena',
          'version': '1.0.0',
          'checks': {
            'api': 'ok',
            'database': 'ok',
          },
        };
      }

      throw Exception('Health check failed');
    } catch (e) {
      return {
        'status': 'unhealthy',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
}
