// SABO Arena - Privacy Settings cho Social Platform
// Thêm vào Flutter app để users có thể kiểm soát privacy

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacySettingsModel {
  bool profilePublic;
  bool showFollowers;
  bool showFollowing;
  bool allowDirectMessages;
  String postsDefaultVisibility; // 'public', 'followers', 'private'
  bool showOnlineStatus;
  bool allowClubInvitations;
  bool showTournamentHistory;

  PrivacySettingsModel({
    this.profilePublic = true,
    this.showFollowers = true,
    this.showFollowing = false,
    this.allowDirectMessages = true,
    this.postsDefaultVisibility = 'public',
    this.showOnlineStatus = true,
    this.allowClubInvitations = true,
    this.showTournamentHistory = true,
  });

  Map<String, dynamic> toJson() => {
    'profile_public': profilePublic,
    'show_followers': showFollowers,
    'show_following': showFollowing,
    'allow_direct_messages': allowDirectMessages,
    'posts_default_visibility': postsDefaultVisibility,
    'show_online_status': showOnlineStatus,
    'allow_club_invitations': allowClubInvitations,
    'show_tournament_history': showTournamentHistory,
  };

  factory PrivacySettingsModel.fromJson(Map<String, dynamic> json) =>
      PrivacySettingsModel(
        profilePublic: json['profile_public'] ?? true,
        showFollowers: json['show_followers'] ?? true,
        showFollowing: json['show_following'] ?? false,
        allowDirectMessages: json['allow_direct_messages'] ?? true,
        postsDefaultVisibility: json['posts_default_visibility'] ?? 'public',
        showOnlineStatus: json['show_online_status'] ?? true,
        allowClubInvitations: json['allow_club_invitations'] ?? true,
        showTournamentHistory: json['show_tournament_history'] ?? true,
      );
}

// Privacy Settings Service
class PrivacyService {
  static String getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser!.id;
  }

  static Future<PrivacySettingsModel> getUserPrivacySettings() async {
    final response = await Supabase.instance.client
        .from('user_privacy_settings')
        .select()
        .eq('user_id', getCurrentUserId())
        .single();

    return PrivacySettingsModel.fromJson(response);
  }

  static Future<void> updatePrivacySettings(
    PrivacySettingsModel settings,
  ) async {
    await Supabase.instance.client.from('user_privacy_settings').upsert({
      'user_id': getCurrentUserId(),
      ...settings.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Helper methods for common privacy checks
  static Future<bool> canViewUserProfile(String targetUserId) async {
    if (targetUserId == getCurrentUserId()) return true;

    final settings = await getUserPrivacySettings();
    if (settings.profilePublic) return true;

    // Check if following
    final following = await Supabase.instance.client
        .from('user_follows')
        .select()
        .eq('follower_id', getCurrentUserId())
        .eq('following_id', targetUserId)
        .maybeSingle();

    return following != null;
  }

  static Future<bool> canSendDirectMessage(String targetUserId) async {
    final response = await Supabase.instance.client
        .from('user_privacy_settings')
        .select('allow_direct_messages')
        .eq('user_id', targetUserId)
        .single();

    return response['allow_direct_messages'] ?? true;
  }
}

// Privacy Settings UI Screen
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  PrivacySettingsModel _settings = PrivacySettingsModel();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await PrivacyService.getUserPrivacySettings();
      setState(() {
        _settings = settings;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    await PrivacyService.updatePrivacySettings(_settings);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Cài đặt đã được lưu!')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt riêng tư'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text('LƯU', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'HỒNG SƠ CÁ NHÂN',
            children: [
              SwitchListTile(
                title: Text('Profile công khai'),
                subtitle: Text('Mọi người có thể xem thông tin cơ bản của bạn'),
                value: _settings.profilePublic,
                onChanged: (value) =>
                    setState(() => _settings.profilePublic = value),
              ),
              SwitchListTile(
                title: Text('Hiển thị danh sách followers'),
                value: _settings.showFollowers,
                onChanged: (value) =>
                    setState(() => _settings.showFollowers = value),
              ),
              SwitchListTile(
                title: Text('Hiển thị danh sách following'),
                value: _settings.showFollowing,
                onChanged: (value) =>
                    setState(() => _settings.showFollowing = value),
              ),
            ],
          ),

          _buildSection(
            title: 'BÀI ĐĂNG & TƯƠNG TÁC',
            children: [
              ListTile(
                title: Text('Chế độ mặc định cho bài đăng'),
                subtitle: Text(
                  _getVisibilityText(_settings.postsDefaultVisibility),
                ),
                trailing: Icon(Icons.chevron_right),
                onTap: _showVisibilityOptions,
              ),
              SwitchListTile(
                title: Text('Cho phép tin nhắn trực tiếp'),
                value: _settings.allowDirectMessages,
                onChanged: (value) =>
                    setState(() => _settings.allowDirectMessages = value),
              ),
            ],
          ),

          _buildSection(
            title: 'HOẠT ĐỘNG & CLB',
            children: [
              SwitchListTile(
                title: Text('Hiển thị trạng thái online'),
                value: _settings.showOnlineStatus,
                onChanged: (value) =>
                    setState(() => _settings.showOnlineStatus = value),
              ),
              SwitchListTile(
                title: Text('Cho phép lời mời vào CLB'),
                value: _settings.allowClubInvitations,
                onChanged: (value) =>
                    setState(() => _settings.allowClubInvitations = value),
              ),
              SwitchListTile(
                title: Text('Hiển thị lịch sử giải đấu'),
                value: _settings.showTournamentHistory,
                onChanged: (value) =>
                    setState(() => _settings.showTournamentHistory = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  String _getVisibilityText(String visibility) {
    switch (visibility) {
      case 'public':
        return 'Công khai cho mọi người';
      case 'followers':
        return 'Chỉ người theo dõi';
      case 'private':
        return 'Chỉ mình tôi';
      default:
        return 'Công khai cho mọi người';
    }
  }

  void _showVisibilityOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Công khai cho mọi người'),
            leading: Radio<String>(
              value: 'public',
              groupValue: _settings.postsDefaultVisibility,
              onChanged: (value) {
                setState(() => _settings.postsDefaultVisibility = value!);
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            title: const Text('Chỉ người theo dõi'),
            leading: Radio<String>(
              value: 'followers',
              groupValue: _settings.postsDefaultVisibility,
              onChanged: (value) {
                setState(() => _settings.postsDefaultVisibility = value!);
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            title: const Text('Chỉ mình tôi'),
            leading: Radio<String>(
              value: 'private',
              groupValue: _settings.postsDefaultVisibility,
              onChanged: (value) {
                setState(() => _settings.postsDefaultVisibility = value!);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  String getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id ?? '';
  }
}
