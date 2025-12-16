import 'package:flutter/material.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Facebook-style Quick Actions Widget
/// Displays quick action cards like Facebook's profile sections
/// (Friends, Pages, Groups, Marketplace, etc.)
///
/// Design specs:
/// - White background #FFFFFF
/// - 0.5px borders #E4E6EB
/// - 12px padding per card
/// - Icons 24px with colors
/// - Typography: 15px weight 600
class ProfileQuickActionsWidget extends StatelessWidget {
  final List<QuickAction> actions;

  const ProfileQuickActionsWidget({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: actions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.outlineVariant,
          indent: 56, // After icon + spacing
        ),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildActionCard(action);
        },
      ),
    );
  }

  Widget _buildActionCard(QuickAction action) {
    return InkWell(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon with colored background
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    action.iconBackgroundColor ??
                    action.iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: action.icon,
                  color: action.iconColor,
                  size: 24,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (action.subtitle != null) ..[
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Badge or trailing widget
            if (action.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3425F), // Facebook red
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  action.badge!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              )
            else if (action.showChevron)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}

/// Quick Action Model
class QuickAction {
  final String icon;
  final Color iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? subtitle;
  final String? badge;
  final bool showChevron;
  final VoidCallback onTap;

  const QuickAction({
    required this.icon,
    required this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    this.badge,
    this.showChevron = true,
    required this.onTap,
  });
}
