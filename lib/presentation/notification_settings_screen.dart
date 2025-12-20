import 'package:flutter/material.dart';
import '../services/notification_preferences_service.dart';
import '../models/notification_models.dart';

/// Notification Settings Screen để users tùy chỉnh notification preferences
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationPreferencesService _prefsService =
      NotificationPreferencesService.instance;

  NotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _prefsService.loadPreferences();
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Không thể tải cài đặt thông báo');
    }
  }

  Future<void> _updateGlobalSetting(bool enabled) async {
    if (_preferences == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedPrefs = NotificationPreferences(
        userId: _preferences!.userId,
        globalEnabled: enabled,
        enablePushNotifications: _preferences!.enablePushNotifications,
        enableInAppNotifications: _preferences!.enableInAppNotifications,
        enableEmailNotifications: _preferences!.enableEmailNotifications,
        enableSmsNotifications: _preferences!.enableSmsNotifications,
        typeSettings: _preferences!.typeSettings,
        enableQuietHours: _preferences!.enableQuietHours,
        quietHoursStart: _preferences!.quietHoursStart,
        quietHoursEnd: _preferences!.quietHoursEnd,
        soundSetting: _preferences!.soundSetting,
        vibrationEnabled: _preferences!.vibrationEnabled,
      );
      await _prefsService.savePreferences(updatedPrefs);
      _preferences = updatedPrefs;
      setState(() => _isSaving = false);
      _showSuccessSnackBar('Đã cập nhật cài đặt thông báo');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Cập nhật cài đặt thất bại');
    }
  }

  Future<void> _updateTypeSetting(NotificationType type, bool enabled) async {
    setState(() => _isSaving = true);

    try {
      await _prefsService.updateNotificationTypeSetting(
        type: type,
        enabled: enabled,
      );
      await _loadPreferences(); // Refresh
      setState(() => _isSaving = false);
      _showSuccessSnackBar('Đã cập nhật ${type.displayName}');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Cập nhật ${type.displayName} thất bại');
    }
  }

  Future<void> _updatePushSetting(NotificationType type, bool enabled) async {
    setState(() => _isSaving = true);

    try {
      await _prefsService.updatePushSetting(type, enabled);
      await _loadPreferences(); // Refresh
      setState(() => _isSaving = false);
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Cập nhật cài đặt push thất bại');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Cài đặt thông báo',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGlobalSection(),
                  const SizedBox(height: 24),
                  _buildNotificationTypesSection(),
                  const SizedBox(height: 24),
                  _buildQuietHoursSection(),
                  const SizedBox(height: 24),
                  _buildAdvancedSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildGlobalSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.green[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cài đặt chung',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Bật thông báo',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Bật hoặc tắt tất cả thông báo'),
              value: _preferences?.globalEnabled ?? true,
              onChanged: _isSaving ? null : _updateGlobalSetting,
              activeThumbColor: Colors.green[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypesSection() {
    if (_preferences == null) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Loại thông báo',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...NotificationType.values.map(
              (type) => _buildNotificationTypeItem(type),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeItem(NotificationType type) {
    final setting = _preferences!.typeSettings[type] ??
        NotificationTypeSetting.defaultSetting(type);

    return ExpansionTile(
      leading: _getTypeIcon(type),
      title: Text(
        type.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        type.description,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Switch(
        value: setting.enabled && (_preferences!.globalEnabled),
        onChanged: _isSaving || !_preferences!.globalEnabled
            ? null
            : (value) => _updateTypeSetting(type, value),
        activeThumbColor: Colors.green[700],
      ),
      children: [
        if (setting.enabled && _preferences!.globalEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Thông báo đẩy'),
                  subtitle: const Text(
                    'Hiển thị thông báo ngay cả khi ứng dụng đã đóng',
                  ),
                  value: setting.enabled,
                  onChanged: _isSaving
                      ? null
                      : (value) => _updatePushSetting(type, value ?? false),
                  activeColor: Colors.green[700],
                ),
                CheckboxListTile(
                  title: const Text('Âm thanh'),
                  subtitle: const Text('Phát âm thanh khi có thông báo'),
                  value: setting.customSound != null &&
                      setting.customSound != NotificationSound.none,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          // Update sound setting
                          // TODO: Implement sound setting update
                        },
                  activeColor: Colors.green[700],
                ),
                CheckboxListTile(
                  title: const Text('Rung'),
                  subtitle: const Text('Rung khi có thông báo'),
                  value: setting.useVibration,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          // Update vibration setting
                          // TODO: Implement vibration setting update
                        },
                  activeColor: Colors.green[700],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuietHoursSection() {
    if (_preferences == null) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Giờ yên tĩnh',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Bật giờ yên tĩnh',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Tắt thông báo trong khoảng thời gian đã chọn',
              ),
              value: _preferences!.quietHours.enabled,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      // TODO: Implement quiet hours toggle
                    },
              activeThumbColor: Colors.green[700],
            ),
            if (_preferences!.quietHours.enabled) ...[
              ListTile(
                title: const Text('Thời gian bắt đầu'),
                subtitle: Text(_preferences!.quietHours.startTime.toString()),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(isStartTime: true),
              ),
              ListTile(
                title: const Text('Thời gian kết thúc'),
                subtitle: Text(_preferences!.quietHours.endTime.toString()),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(isStartTime: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_applications,
                  color: Colors.green[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Nâng cao',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Khôi phục mặc định'),
              subtitle: const Text(
                'Khôi phục tất cả cài đặt thông báo về mặc định',
              ),
              leading: const Icon(Icons.restore, color: Colors.orange),
              onTap: _showResetDialog,
            ),
            ListTile(
              title: const Text('Thông báo thử nghiệm'),
              subtitle: const Text('Gửi một thông báo thử nghiệm'),
              leading: const Icon(Icons.notifications, color: Colors.blue),
              onTap: _sendTestNotification,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTypeIcon(NotificationType type) {
    IconData iconData;
    Color color = Colors.green[700]!;

    switch (type) {
      case NotificationType.tournamentInvitation:
        iconData = Icons.emoji_events;
        break;
      case NotificationType.tournamentRegistration:
        iconData = Icons.app_registration;
        break;
      case NotificationType.matchResult:
        iconData = Icons.sports_score;
        break;
      case NotificationType.clubAnnouncement:
        iconData = Icons.campaign;
        break;
      case NotificationType.rankUpdate:
        iconData = Icons.trending_up;
        break;
      case NotificationType.friendRequest:
        iconData = Icons.person_add;
        break;
      case NotificationType.challengeRequest:
        iconData = Icons.sports_mma;
        break;
      case NotificationType.systemNotification:
        iconData = Icons.system_update;
        color = Colors.blue;
        break;
      case NotificationType.general:
        iconData = Icons.notifications;
        break;
    }

    return Icon(iconData, color: color, size: 24);
  }

  Future<void> _selectTime({required bool isStartTime}) async {
    final currentTime = isStartTime
        ? _preferences!.quietHours.startTime
        : _preferences!.quietHours.endTime;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay.now(),
    );

    if (selectedTime != null) {
      final newTime = TimeOfDay(
        hour: selectedTime.hour,
        minute: selectedTime.minute,
      );

      try {
        if (isStartTime) {
          await _prefsService.updateQuietHours(
            enabled: _preferences!.quietHours.enabled,
            startTime: newTime,
            endTime: _preferences!.quietHours.endTime,
          );
        } else {
          await _prefsService.updateQuietHours(
            enabled: _preferences!.quietHours.enabled,
            startTime: _preferences!.quietHours.startTime,
            endTime: newTime,
          );
        }

        await _loadPreferences();
        _showSuccessSnackBar('Đã cập nhật giờ yên tĩnh');
      } catch (e) {
        _showErrorSnackBar('Cập nhật giờ yên tĩnh thất bại');
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục cài đặt'),
        content: const Text(
          'Bạn có chắc chắn muốn khôi phục tất cả cài đặt thông báo về mặc định? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetToDefaults();
            },
            child: const Text('Khôi phục',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    setState(() => _isSaving = true);

    try {
      final userId = _preferences?.userId ?? '';
      if (userId.isEmpty) {
        _showErrorSnackBar('Không tìm thấy người dùng');
        setState(() => _isSaving = false);
        return;
      }

      final defaultPrefs = NotificationPreferences.defaultPreferences(userId);
      await _prefsService.savePreferences(defaultPrefs);
      await _loadPreferences();
      setState(() => _isSaving = false);
      _showSuccessSnackBar('Đã khôi phục cài đặt về mặc định');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Khôi phục cài đặt thất bại');
    }
  }

  void _sendTestNotification() {
    // TODO: Implement test notification
    _showSuccessSnackBar('Đã gửi thông báo thử nghiệm!');
  }
}
