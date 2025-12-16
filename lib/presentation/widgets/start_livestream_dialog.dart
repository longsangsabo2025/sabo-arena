import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialog cho CLB owner nhập link livestream khi bắt đầu match
class StartLivestreamDialog extends StatefulWidget {
  final String matchId;
  final Function(String url) onStartLive;

  const StartLivestreamDialog({
    Key? key,
    required this.matchId,
    required this.onStartLive,
  }) : super(key: key);

  @override
  State<StartLivestreamDialog> createState() => _StartLivestreamDialogState();
}

class _StartLivestreamDialogState extends State<StartLivestreamDialog> {
  final _urlController = TextEditingController();
  String _selectedPlatform = 'youtube';
  bool _isValidUrl = true;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _validateUrl(String url) {
    if (url.isEmpty) return false;

    // Validate YouTube URL
    if (_selectedPlatform == 'youtube') {
      return url.contains('youtube.com') || url.contains('youtu.be');
    }

    // Validate Facebook URL
    if (_selectedPlatform == 'facebook') {
      return url.contains('facebook.com') || url.contains('fb.watch');
    }

    return false;
  }

  void _handleStartLive() {
    final url = _urlController.text.trim();

    if (!_validateUrl(url)) {
      setState(() => _isValidUrl = false);
      return;
    }

    widget.onStartLive(url);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.live_tv,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bắt đầu Livestream',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nhập link livestream từ YouTube hoặc Facebook',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Platform selector
            const Text(
              'Nền tảng livestream',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PlatformCard(
                    icon: Icons.play_circle_fill,
                    label: 'YouTube',
                    color: Colors.red,
                    isSelected: _selectedPlatform == 'youtube',
                    onTap: () => setState(() => _selectedPlatform = 'youtube'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlatformCard(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    color: Colors.blue,
                    isSelected: _selectedPlatform == 'facebook',
                    onTap: () => setState(() => _selectedPlatform = 'facebook'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // URL input
            const Text(
              'Link livestream',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: _selectedPlatform == 'youtube'
                    ? 'https://youtube.com/live/...'
                    : 'https://facebook.com/...',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: !_isValidUrl ? 'Link không hợp lệ' : null,
              ),
              onChanged: (value) {
                if (!_isValidUrl) {
                  setState(() => _isValidUrl = true);
                }
              },
            ),

            const SizedBox(height: 16),

            // Helper text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedPlatform == 'youtube'
                          ? 'Vào YouTube Studio → Livestream → Copy link'
                          : 'Vào Facebook Live → Chia sẻ → Copy link',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleStartLive,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Bắt đầu Live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function để mở livestream URL
Future<void> openLivestreamUrl(String url, BuildContext context) async {
  try {
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Mở trong app YouTube/Facebook
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Không thể mở link livestream'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
