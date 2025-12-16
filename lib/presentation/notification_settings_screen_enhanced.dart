import 'package:flutter/material.dart';
import '../services/notification_preferences_service.dart';

/// Enhanced notification settings screen with detailed controls
class NotificationSettingsScreenEnhanced extends StatefulWidget {
  const NotificationSettingsScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreenEnhanced> createState() =>
      _NotificationSettingsScreenEnhancedState();
}

class _NotificationSettingsScreenEnhancedState
    extends State<NotificationSettingsScreenEnhanced> {
  final _prefsService = NotificationPreferencesService.instance;

  Map<String, dynamic> _preferences = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    final prefs = await _prefsService.getPreferencesAsMap();

    setState(() {
      _preferences = prefs;
      _isLoading = false;
    });
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    setState(() => _preferences[key] = value);

    final success = await _prefsService.updatePreference(key, value);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update preference')),
      );
      _loadPreferences(); // Reload to restore previous state
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFF0866FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Master Toggle
                _buildMasterToggle(),

                const Divider(height: 1),

                // Push & Email
                _buildSection('Delivery Methods', [
                  _buildSwitchTile(
                    'Push Notifications',
                    'Receive notifications on this device',
                    'push_notifications_enabled',
                    Icons.notifications_active,
                  ),
                  _buildSwitchTile(
                    'Email Notifications',
                    'Receive important updates via email',
                    'email_notifications_enabled',
                    Icons.email,
                  ),
                ]),

                const Divider(height: 32),

                // Notification Types
                _buildSection(
                  'Notification Types',
                  _buildNotificationTypeToggles(),
                ),

                const Divider(height: 32),

                // Quiet Hours
                _buildQuietHoursSection(),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildMasterToggle() {
    final allEnabled = _preferences['all_notifications_enabled'] ?? true;

    return Container(
      color: allEnabled
          ? const Color(0xFF0866FF).withValues(alpha: 0.1)
          : Colors.grey[100],
      child: SwitchListTile(
        value: allEnabled,
        onChanged: (value) =>
            _updatePreference('all_notifications_enabled', value),
        title: const Text(
          'All Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          allEnabled ? 'Enabled' : 'Disabled',
          style: TextStyle(
            color: allEnabled ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
        secondary: Icon(
          allEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: allEnabled ? const Color(0xFF0866FF) : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    String key,
    IconData icon,
  ) {
    final value = _preferences[key] ?? false;
    final masterEnabled = _preferences['all_notifications_enabled'] ?? true;

    return SwitchListTile(
      value: value,
      onChanged: masterEnabled ? (val) => _updatePreference(key, val) : null,
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(
        icon,
        color: masterEnabled && value ? const Color(0xFF0866FF) : Colors.grey,
      ),
    );
  }

  List<Widget> _buildNotificationTypeToggles() {
    final types = _prefsService.getNotificationTypeNames();
    final descriptions = _prefsService.getNotificationTypeDescriptions();

    return types.entries.map((entry) {
      final key = '${entry.key}_notifications_enabled';
      final name = entry.value;
      final description = descriptions[entry.key] ?? '';

      return _buildSwitchTile(
        name,
        description,
        key,
        _getIconForType(entry.key),
      );
    }).toList();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'tournament':
        return Icons.emoji_events;
      case 'club':
        return Icons.groups;
      case 'challenge':
        return Icons.sports_martial_arts;
      case 'match':
        return Icons.sports_esports;
      case 'social':
        return Icons.favorite;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Widget _buildQuietHoursSection() {
    final enabled = _preferences['quiet_hours_enabled'] ?? false;
    final start = _preferences['quiet_hours_start'] ?? '22:00';
    final end = _preferences['quiet_hours_end'] ?? '08:00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'Quiet Hours',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Switch(
                value: enabled,
                onChanged: (value) =>
                    _updatePreference('quiet_hours_enabled', value),
              ),
            ],
          ),
        ),
        if (enabled) ...[
          ListTile(
            leading: const Icon(Icons.bedtime),
            title: const Text('Start Time'),
            subtitle: Text(start),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _selectTime(true, start),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny),
            title: const Text('End Time'),
            subtitle: Text(end),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _selectTime(false, end),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'No notifications will be sent between $start and $end',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectTime(bool isStart, String currentTime) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      final timeString =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      final key = isStart ? 'quiet_hours_start' : 'quiet_hours_end';
      _updatePreference(key, timeString);
    }
  }
}
