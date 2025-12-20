import 'package:flutter/material.dart';
import '../../services/app_cache_service.dart';
import '../../services/tournament_cache_service.dart';
import '../../services/messages_cache_service.dart';

/// 🧹 Cache Management Screen
/// Cho phép user xem và quản lý cache của app
class CacheManagementScreen extends StatefulWidget {
  const CacheManagementScreen({super.key});

  @override
  State<CacheManagementScreen> createState() => _CacheManagementScreenState();
}

class _CacheManagementScreenState extends State<CacheManagementScreen> {
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    // Load cache statistics if needed in the future
    setState(() {});
  }

  Future<void> _clearAllCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xóa toàn bộ cache?'),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn xóa toàn bộ cache? '
          'App sẽ cần tải lại dữ liệu từ server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isClearing = true);

      try {
        // Clear all caches
        await AppCacheService.instance.clearAll();
        await TournamentCacheService.clearAllCache();
        await MessagesCacheService.clearCache();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã xóa toàn bộ cache thành công!'),
              backgroundColor: Colors.green,
            ),
          );

          // Reload stats
          await _loadCacheStats();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi xóa cache: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isClearing = false);
        }
      }
    }
  }

  Future<void> _viewCacheStats() async {
    // Print cache statistics
    AppCacheService.instance.printCacheStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Thống kê Cache'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xem console log để thấy thống kê chi tiết:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Total Requests'),
              Text('• Cache Hits/Misses'),
              Text('• Memory vs Disk Cache'),
              Text('• Hit Rate (%)'),
              SizedBox(height: 12),
              Text(
                'Mở DevTools > Console để xem',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          'Quản lý Cache',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cache giúp tăng tốc độ app',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Xóa cache nếu gặp lỗi hiển thị dữ liệu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Cache types
          _buildCacheTypeCard(
            icon: Icons.article,
            title: 'Posts Cache',
            subtitle: 'Bài viết, feeds (TTL: 5 phút)',
            color: Colors.green,
          ),

          const SizedBox(height: 12),

          _buildCacheTypeCard(
            icon: Icons.person,
            title: 'User Profiles Cache',
            subtitle: 'Thông tin người dùng (TTL: 30 phút)',
            color: Colors.blue,
          ),

          const SizedBox(height: 12),

          _buildCacheTypeCard(
            icon: Icons.business,
            title: 'Club Data Cache',
            subtitle: 'Thông tin câu lạc bộ (TTL: 15 phút)',
            color: Colors.purple,
          ),

          const SizedBox(height: 12),

          _buildCacheTypeCard(
            icon: Icons.emoji_events,
            title: 'Tournament Cache',
            subtitle: 'Giải đấu (TTL: 10 phút)',
            color: Colors.orange,
          ),

          const SizedBox(height: 12),

          _buildCacheTypeCard(
            icon: Icons.message,
            title: 'Messages Cache',
            subtitle: 'Tin nhắn (Local database)',
            color: Colors.teal,
          ),

          const SizedBox(height: 32),

          // Actions
          const Text(
            'Thao tác',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          // View Statistics
          _buildActionCard(
            icon: Icons.analytics_outlined,
            title: 'Xem thống kê Cache',
            subtitle: 'Cache hits, misses, hit rate',
            color: Colors.blue,
            onTap: _viewCacheStats,
          ),

          const SizedBox(height: 12),

          // Clear all cache
          _buildActionCard(
            icon: Icons.delete_sweep,
            title: 'Xóa toàn bộ Cache',
            subtitle: 'Xóa tất cả cache đã lưu',
            color: Colors.red,
            onTap: _isClearing ? null : _clearAllCache,
            trailing: _isClearing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),

          const SizedBox(height: 32),

          // Technical info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ℹ️ Thông tin kỹ thuật',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Cache Strategy', 'Memory + Disk (2 layers)'),
                _buildInfoRow('Storage', 'SharedPreferences + Memory'),
                _buildInfoRow('Auto Cleanup', 'Based on TTL'),
                _buildInfoRow('Offline Support', 'Yes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
