import 'package:flutter/material.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'dart:math' as math;

/// Widget hiển thị trạng thái lỗi chuyên nghiệp cho toàn hệ thống
class ErrorStateWidget extends StatefulWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? title;
  final String? description;
  final IconData? icon;
  final bool showErrorDetails;
  final bool useLogo; // Option to use animated logo instead of error icon

  const ErrorStateWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.title,
    this.description,
    this.icon,
    this.showErrorDetails = false,
    this.useLogo = true, // Default to using logo for consistency
  });

  @override
  State<ErrorStateWidget> createState() => _ErrorStateWidgetState();
}

class _ErrorStateWidgetState extends State<ErrorStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
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
            // Logo hoặc Icon - iOS style
            if (widget.useLogo)
              // Logo xoay với màu xanh lá đậm
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
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              )
            else
              // Icon lỗi truyền thống
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEEBEE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon ?? Icons.error_outline,
                  size: 40,
                  color: const Color(0xFFF44336),
                ),
              ),
            const SizedBox(height: 20),

            // Title
            Text(
              widget.title ?? 'Không thể tải dữ liệu',
              style: AppTypography.headingMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              widget.description ?? 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            if (widget.onRetry != null) ...[
              const SizedBox(height: 24),
              // Retry button - iOS style
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_outlined, size: 20),
                  label: Text(
                    'Thử lại',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            // Show error details button
            if (widget.showErrorDetails && widget.errorMessage != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _showErrorDetails(context),
                child: const Text('Xem chi tiết lỗi'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showErrorDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết lỗi'),
        content: SingleChildScrollView(
          child: Text(
            widget.errorMessage ?? 'Không có thông tin lỗi',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
}

/// Widget hiển thị trạng thái lỗi có thể làm mới (pull to refresh)
class RefreshableErrorStateWidget extends StatelessWidget {
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final String? title;
  final String? description;
  final IconData? icon;
  final bool showErrorDetails;

  const RefreshableErrorStateWidget({
    super.key,
    this.errorMessage,
    required this.onRefresh,
    this.title,
    this.description,
    this.icon,
    this.showErrorDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ErrorStateWidget(
            errorMessage: errorMessage,
            onRetry: onRefresh,
            title: title,
            description: description,
            icon: icon,
            showErrorDetails: showErrorDetails,
          ),
        ),
      ),
    );
  }
}
