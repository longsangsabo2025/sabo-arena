import 'package:flutter/material.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'dart:math' as math;

/// Widget hiển thị trạng thái trống (empty state) chuyên nghiệp
class EmptyStateWidget extends StatefulWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Widget? customAction;
  final bool useLogo;

  const EmptyStateWidget({
    Key? key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox,
    this.iconColor,
    this.onAction,
    this.actionLabel,
    this.customAction,
    this.useLogo = true, // Mặc định dùng logo
  }) : super(key: key);

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.useLogo) {
      _controller = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat();
    } else {
      _controller = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo xoay hoặc Icon
            if (widget.useLogo)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF0D5C4C), // Màu xanh lá đậm và tối
                    BlendMode.srcATop,
                  ),
                  child: Image.asset(
                    'assets/images/logoxoaphong.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/logo.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 40,
                  color: widget.iconColor ?? AppColors.textTertiary,
                ),
              ),
            const SizedBox(height: 20),

            // Message
            Text(
              widget.message,
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action button
            if (widget.customAction != null) ...[
              const SizedBox(height: 24),
              widget.customAction!,
            ] else if (widget.onAction != null &&
                widget.actionLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: widget.onAction,
                  icon: const Icon(Icons.add_outlined, size: 20),
                  label: Text(
                    widget.actionLabel!,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị trạng thái trống có thể làm mới (pull to refresh)
class RefreshableEmptyStateWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAction;
  final String? actionLabel;

  const RefreshableEmptyStateWidget({
    Key? key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox,
    this.iconColor,
    required this.onRefresh,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: EmptyStateWidget(
            message: message,
            subtitle: subtitle ?? 'Kéo xuống để làm mới',
            icon: icon,
            iconColor: iconColor,
            onAction: onAction,
            actionLabel: actionLabel,
          ),
        ),
      ),
    );
  }
}
