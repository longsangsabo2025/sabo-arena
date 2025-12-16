import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/tournament_post_settings.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class TournamentPostSettingsScreen extends StatefulWidget {
  final String tournamentId;
  final String clubId;

  const TournamentPostSettingsScreen({
    Key? key,
    required this.tournamentId,
    required this.clubId,
  }) : super(key: key);

  @override
  State<TournamentPostSettingsScreen> createState() =>
      _TournamentPostSettingsScreenState();
}

class _TournamentPostSettingsScreenState
    extends State<TournamentPostSettingsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  TournamentPostSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('tournament_post_settings')
          .select()
          .eq('tournament_id', widget.tournamentId)
          .single();

      setState(() {
        _settings = TournamentPostSettings.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      ProductionLogger.info('Error loading settings: $e', tag: 'tournament_post_settings_screen');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings(Map<String, dynamic> updates) async {
    if (_settings == null) return;

    try {
      await _supabase
          .from('tournament_post_settings')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('tournament_id', widget.tournamentId);

      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu cấu hình'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình Auto Post'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00695C), Color(0xFF00897B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? const Center(child: Text('Không tìm thấy cấu hình'))
              : _buildSettingsContent(),
    );
  }

  Widget _buildSettingsContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Master switch
        _buildSectionCard(
          title: '🎯 Tự động đăng bài',
          children: [
            SwitchListTile(
              value: _settings!.autoPostEnabled,
              onChanged: (value) {
                _updateSettings({'auto_post_enabled': value});
              },
              title: const Text(
                'Bật tự động đăng bài', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Tự động tạo bài đăng khi có trận đấu quan trọng',
              ),
              activeThumbColor: const Color(0xFF00897B),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Post types
        _buildSectionCard(
          title: '📢 Loại trận đấu cần đăng',
          children: [
            _buildSwitchTile(
              title: '🏆 Chung kết (Finals)',
              subtitle: 'Đăng bài khi có trận chung kết',
              value: _settings!.postFinals,
              onChanged: _settings!.autoPostEnabled
                  ? (value) => _updateSettings({'post_finals': value})
                  : null,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: '⚔️ Cross Finals',
              subtitle: 'Winner Bracket vs Loser Bracket',
              value: _settings!.postCrossFinals,
              onChanged: _settings!.autoPostEnabled
                  ? (value) => _updateSettings({'post_cross_finals': value})
                  : null,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: '🥈 Bán kết (Semifinals)',
              subtitle: 'Đăng bài khi có trận bán kết',
              value: _settings!.postSemifinals,
              onChanged: _settings!.autoPostEnabled
                  ? (value) => _updateSettings({'post_semifinals': value})
                  : null,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: '🥉 Tranh hạng 3',
              subtitle: 'Đăng bài trận tranh hạng 3',
              value: _settings!.postThirdPlace,
              onChanged: _settings!.autoPostEnabled
                  ? (value) => _updateSettings({'post_third_place': value})
                  : null,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: '🔄 Tất cả các vòng',
              subtitle: 'Đăng bài cho tất cả trận đấu',
              value: _settings!.postAllRounds,
              onChanged: _settings!.autoPostEnabled
                  ? (value) => _updateSettings({'post_all_rounds': value})
                  : null,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Reminder settings
        _buildSectionCard(
          title: '⏰ Nhắc nhở',
          children: [
            _buildSwitchTile(
              title: 'Gửi bài nhắc nhở',
              subtitle: 'Đăng bài nhắc trước khi trận đấu bắt đầu',
              value: _settings!.sendReminder,
              onChanged: _settings!.autoPostEnabled
                  ? (value) => _updateSettings({'send_reminder': value})
                  : null,
            ),
            if (_settings!.sendReminder) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhắc trước: ${_settings!.reminderMinutesBefore} phút', overflow: TextOverflow.ellipsis, style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _settings!.reminderMinutesBefore.toDouble(),
                      min: 15,
                      max: 180,
                      divisions: 11,
                      label: '${_settings!.reminderMinutesBefore} phút',
                      onChanged: _settings!.autoPostEnabled
                          ? (value) {
                              _updateSettings({
                                'reminder_minutes_before': value.toInt()
                              });
                            }
                          : null,
                      activeColor: const Color(0xFF00897B),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '15 phút', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '3 giờ', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // Content settings
        _buildSectionCard(
          title: '📝 Nội dung bài đăng',
          children: [
            _buildSwitchTile(
              title: '📊 Hiển thị thống kê người chơi',
              subtitle: 'ELO, Rank, Thành tích',
              value: _settings!.includePlayerStats,
              onChanged: _settings!.autoPostEnabled
                  ? (value) => _updateSettings({'include_player_stats': value})
                  : null,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: '🏆 Thông tin giải đấu',
              subtitle: 'Tên giải, địa điểm, thời gian',
              value: _settings!.includeTournamentInfo,
              onChanged: _settings!.autoPostEnabled
                  ? (value) =>
                      _updateSettings({'include_tournament_info': value})
                  : null,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: '📌 Tự động ghim bài',
              subtitle: 'Ghim bài lên đầu feed',
              value: _settings!.autoPinPosts,
              onChanged: _settings!.autoPostEnabled
                  ? (value) => _updateSettings({'auto_pin_posts': value})
                  : null,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Live stream settings
        _buildSectionCard(
          title: '📺 Livestream',
          children: [
            _buildSwitchTile(
              title: 'Bật tính năng Livestream',
              subtitle: 'Hiển thị nút xem livestream trên bài đăng',
              value: _settings!.enableLiveStream,
              onChanged: _settings!.autoPostEnabled
                  ? (value) => _updateSettings({'enable_live_stream': value})
                  : null,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hệ thống sẽ tự động đăng bài khi trận đấu được tạo, bắt đầu live, hoặc kết thúc.', overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title, style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool)? onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      subtitle: Text(
        subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      activeThumbColor: const Color(0xFF00897B),
    );
  }
}
