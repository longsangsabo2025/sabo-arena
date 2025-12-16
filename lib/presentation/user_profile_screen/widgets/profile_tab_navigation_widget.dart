import 'package:flutter/material.dart';

/// Tab Navigation Widget - Ready, Live, Done
/// Design: Gray inactive, Red dot for active Live tab, underline indicator
class ProfileTabNavigationWidget extends StatelessWidget {
  final String currentTab; // 'ready', 'live', 'done'
  final Function(String) onTabChanged;

  const ProfileTabNavigationWidget({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              label: 'Ready',
              value: 'ready',
              isActive: currentTab == 'ready',
            ),
          ),
          Expanded(
            child: _buildTab(
              label: 'Live',
              value: 'live',
              isActive: currentTab == 'live',
              showRedDot: true,
            ),
          ),
          Expanded(
            child: _buildTab(
              label: 'Done',
              value: 'done',
              isActive: currentTab == 'done',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required String value,
    required bool isActive,
    bool showRedDot = false,
  }) {
    return GestureDetector(
      onTap: () => onTabChanged(value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.black : const Color(0xFF9E9E9E),
                  ),
                ),
                if (showRedDot && isActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Underline chỉ vừa với text
          Container(
            height: 2,
            width: _getUnderlineWidth(label, showRedDot && isActive),
            color: isActive ? Colors.black : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // Calculate underline width based on text length
  double _getUnderlineWidth(String label, bool hasRedDot) {
    // Approximate width: each character ~8px, red dot adds 14px
    final textWidth = label.length * 8.5;
    final dotWidth = hasRedDot ? 14.0 : 0.0;
    return textWidth + dotWidth;
  }
}
