import 'package:flutter/material.dart';

import '../../../widgets/custom_image_widget.dart';

class ProfileCreatePostWidget extends StatelessWidget {
  final VoidCallback onTap;
  final String userAvatarUrl;

  const ProfileCreatePostWidget({
    super.key,
    required this.onTap,
    required this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Main row with avatar and input
          Row(
            children: [
              // Avatar
              ClipOval(
                child: CustomImageWidget(
                  imageUrl: userAvatarUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8), // Facebook: 8px gap
              // Input hint
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'What\'s on your mind?',
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12), // Facebook: 12px spacing
          // Divider
          Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1, thickness: 0.5),

          const SizedBox(height: 12),

          // Action buttons row
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Photo',
                  color: const Color(0xFF45BD62), // Facebook: green
                  onTap: onTap,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: const Color(0xFFF3425F), // Facebook: red
                  onTap: onTap,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.emoji_emotions_outlined,
                  label: 'Feeling',
                  color: const Color(0xFFF7B928), // Facebook: yellow
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: const Color(0xFF65676B), // Facebook: gray600
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
