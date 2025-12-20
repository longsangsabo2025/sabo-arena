// 🎯 SABO Arena - Premium Coach Marks Tutorial System
// ✨ Ultra modern overlay tutorial với spotlight effect xịn sò
//
// Features:
// - Dark theme with white text (nền đen chữ trắng - tăng điểm nhấn)
// - Bright spotlight on target (target sáng bật để user chú ý)
// - Smart tooltip positioning (tự động tránh che bottom bar)
// - Accurate arrows pointing to exact targets (mũi tên chỉ đúng target)
// - Beautiful Poppins font (font chữ đẹp)
// - Rich animations: pulse, glow, fade, scale
// - Step-by-step navigation
// - Skip & Back functionality

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🎯 Coach Mark Step - Mỗi step là 1 hướng dẫn
class CoachMarkStep {
  final GlobalKey targetKey; // Key của widget cần highlight
  final String title; // Tiêu đề ngắn
  final String description; // Mô tả chi tiết
  final CoachMarkPosition position; // Vị trí của tooltip (trên/dưới target)
  final IconData icon; // Icon đại diện cho step

  CoachMarkStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.position = CoachMarkPosition.bottom,
    this.icon = Icons.star_rounded, // Default icon
  });
}

enum CoachMarkPosition { top, bottom, left, right }

/// 🎨 Coach Marks Overlay - Hiển thị tutorial overlay
class AppCoachMarks extends StatefulWidget {
  final List<CoachMarkStep> steps;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const AppCoachMarks({
    super.key,
    required this.steps,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<AppCoachMarks> createState() => _AppCoachMarksState();

  /// 🚀 Show coach marks - Helper method
  static Future<void> show({
    required BuildContext context,
    required List<CoachMarkStep> steps,
    required VoidCallback onComplete,
    VoidCallback? onSkip,
  }) async {
    // Đợi frame render xong để lấy được position của widgets
    await Future.delayed(const Duration(milliseconds: 100));

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) =>
          AppCoachMarks(steps: steps, onComplete: onComplete, onSkip: onSkip),
    );
  }
}

class _AppCoachMarksState extends State<AppCoachMarks>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Fade animation cho overlay - nhanh và clean
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Scale animation cho tooltip - bouncy nhẹ
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Play animation một lần khi appear
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      // Reset và play lại animation cho step mới
      _animationController.stop();
      _animationController.reset();
      _animationController.forward();
    } else {
      _complete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      // Reset và play lại animation
      _animationController.stop();
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _skip() {
    widget.onSkip?.call();
    Navigator.of(context).pop();
  }

  void _complete() {
    widget.onComplete();
    Navigator.of(context).pop();
  }

  Rect? _getTargetRect() {
    final currentStep = widget.steps[_currentStep];
    final RenderBox? renderBox =
        currentStep.targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return null;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // ✨ KHÔNG offset cho iOS - giữ nguyên vị trí chính xác
    // iOS có safe area riêng, offset sẽ làm spotlight lệch

    return Rect.fromLTWH(
      position.dx,
      position.dy, // Không offset, giữ nguyên position
      size.width,
      size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetRect = _getTargetRect();
    final currentStep = widget.steps[_currentStep];

    if (targetRect == null) {
      // Target chưa render, bỏ qua step này
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nextStep();
      });
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 🌑 Background dim với spotlight hole (nền tối mờ)
          FadeTransition(
            opacity: _fadeAnimation,
            child: CustomPaint(
              painter: SpotlightPainter(
                targetRect: targetRect,
                fadeValue: 1.0, // Always full opacity sau khi fade in
                pulseValue: 1.0, // No pulse - steady glow
              ),
              child: Container(),
            ),
          ),

          // 💬 Tooltip với mũi tên (dark theme - nền đen chữ trắng)
          _buildTooltip(context, targetRect, currentStep),
        ],
      ),
    );
  }

  Widget _buildTooltip(
    BuildContext context,
    Rect targetRect,
    CoachMarkStep step,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    // 🧠 Smart positioning: Tính toán vị trí tốt nhất cho tooltip
    const tooltipHeight = 240.0; // Chiều cao cố định để đồng bộ layout

    // 🎯 Phát hiện FAB và Bottom tabs - SỬ DỤNG TỶ LỆ % thay vì giá trị cố định
    final screenBottom20Percent = screenHeight * 0.8; // 80% từ trên xuống
    final screenRight15Percent = screenWidth * 0.85; // 85% từ trái qua

    final isFAB = targetRect.bottom > screenBottom20Percent &&
        targetRect.right > screenRight15Percent;
    final isBottomTab = targetRect.bottom > screenBottom20Percent;

    // 🎯 Tính toán safe area để tránh notch/dynamic island trên iOS
    const safeMargin = 60.0; // Tăng margin để an toàn với iOS notch

    // Tính toán bottom safe area (bao gồm cả bottom bar)
    final bottomSafeArea =
        bottomPadding + (screenHeight * 0.12); // 12% cho bottom bar + padding

    // Với bottom tabs hoặc FAB, LUÔN hiển thị tooltip ở phía trên
    bool canShowAbove =
        targetRect.top - tooltipHeight - safeMargin > topPadding + 100;
    bool canShowBelow = !isBottomTab &&
        !isFAB &&
        targetRect.bottom + tooltipHeight + safeMargin <
            screenHeight - bottomSafeArea;

    double tooltipTop;
    bool showArrowUp = false;

    if (canShowAbove || isBottomTab || isFAB) {
      // ✨ Bottom tabs và FAB: Di chuyển tooltip LÊN CAO để tránh che bottom bar
      if (isBottomTab) {
        // Bottom tabs: Cao nhất để tránh che bottom bar - TÍNH CHÍNH XÁC cho iOS
        tooltipTop = targetRect.top -
            tooltipHeight -
            (screenHeight * 0.08); // 8% clearance
      } else if (isFAB) {
        tooltipTop = targetRect.top -
            tooltipHeight -
            (screenHeight * 0.07); // FAB: 7% clearance
      } else {
        tooltipTop = targetRect.top -
            tooltipHeight -
            (screenHeight * 0.06); // Targets khác: 6%
      }
      showArrowUp = false;
    } else if (canShowBelow) {
      tooltipTop = targetRect.bottom + 40;
      showArrowUp = true;
    } else {
      // Fallback: Đặt tooltip ở giữa màn hình nhưng tránh bottom bar
      tooltipTop = (screenHeight - bottomSafeArea - tooltipHeight) / 2;
      showArrowUp = targetRect.center.dy > tooltipTop + tooltipHeight / 2;
    }

    // 🎯 Tính toán vị trí X của mũi tên (chỉ CHÍNH GIỮA target)
    final arrowCenterX = targetRect.center.dx;
    final tooltipLeft = 20.0;
    final tooltipRight = screenWidth - 20.0;
    final tooltipWidth = tooltipRight - tooltipLeft;

    // Arrow offset từ bên trái tooltip
    final arrowOffsetFromLeft = (arrowCenterX - tooltipLeft).clamp(
      30.0,
      tooltipWidth - 30.0,
    );

    return Positioned(
      left: tooltipLeft,
      right: 20,
      top: tooltipTop,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔼 Mũi tên chỉ lên (khi tooltip ở dưới target)
              if (showArrowUp)
                Padding(
                  padding: EdgeInsets.only(left: arrowOffsetFromLeft - 20),
                  child: _buildArrow(isPointingDown: false),
                ),

              // � Step indicator + Skip button (TRÊN tooltip)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 📍 Step indicator (bên trái)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bước ${_currentStep + 1}/${widget.steps.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ⏭️ Skip button (bên phải)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _skip,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Bỏ qua',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // �💬 Tooltip card - DARK THEME (nền đen chữ trắng)
              Container(
                width: double.infinity,
                height: tooltipHeight, // Chiều cao cố định
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  // 🎨 Nền đen gradient với một chút purple
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.25),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✨ Icon + Title - CHUẨN LAYOUT
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFF5F4FDB)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C5CE7)
                                    .withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            step.icon, // ✨ Sử dụng icon từ step
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white, // 🎨 Chữ trắng
                              letterSpacing: -0.5,
                              fontFamily: 'Poppins', // 🎨 Font Poppins
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 📝 Description - CHUẨN LAYOUT
                    Expanded(
                      child: Text(
                        step.description,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFB0B0B0), // 🎨 Chữ xám sáng
                          height: 1.6,
                          letterSpacing: 0.2,
                          fontFamily: 'Poppins', // 🎨 Font Poppins
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🎮 Navigation buttons - CHUẨN LAYOUT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ⬅️ Previous button
                        if (_currentStep > 0)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _previousStep,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_back_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Quay lại',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 100), // Placeholder
                        // ➡️ Next button - PURPLE GRADIENT
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _nextStep,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C5CE7),
                                    Color(0xFF5F4FDB),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6C5CE7,
                                    ).withValues(alpha: 0.6),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _currentStep < widget.steps.length - 1
                                        ? 'Tiếp theo'
                                        : 'Hoàn thành',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 🔽 Mũi tên chỉ xuống (khi tooltip ở trên target)
              if (!showArrowUp)
                Padding(
                  padding: EdgeInsets.only(left: arrowOffsetFromLeft - 20),
                  child: _buildArrow(isPointingDown: true),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrow({required bool isPointingDown}) {
    return CustomPaint(
      size: const Size(40, 20),
      painter: ArrowPainter(
        isPointingDown: isPointingDown,
        color: const Color(0xFF1A1A1A), // 🎨 Màu đen của tooltip
      ),
    );
  }
}

/// 🎨 Premium Spotlight Painter - Vẽ nền tối mờ với spotlight sáng rõ + pulse animation
class SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double fadeValue;
  final double pulseValue;

  SpotlightPainter({
    required this.targetRect,
    required this.fadeValue,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 🌑 Step 1: Vẽ overlay tối mờ cho TOÀN BỘ màn hình
    // Tạo lớp phủ đen với opacity cao (92%) để làm mờ background
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.92 * fadeValue)
      ..style = PaintingStyle.fill;

    // 🎯 Phát hiện loại target dựa trên vị trí - CHÍNH XÁC hơn cho iOS
    // FAB: góc dưới phải, Bottom tabs: dưới cùng màn hình
    // Sử dụng tỷ lệ phần trăm thay vì giá trị tuyệt đối để tương thích iOS/Android
    final screenBottom20Percent = size.height * 0.8; // 80% từ trên xuống
    final screenRight15Percent = size.width * 0.85; // 85% từ trái qua

    final isFAB = targetRect.bottom > screenBottom20Percent &&
        targetRect.right > screenRight15Percent;
    final isBottomTab = targetRect.bottom > screenBottom20Percent &&
        targetRect.center.dx > size.width * 0.1 &&
        targetRect.center.dx < size.width * 0.9;

    // 🎯 Step 2: Tạo spotlight area với padding thông minh
    // FAB: Padding lớn hơn vì có shadow lớn (blurRadius: 12, offset: 6)
    // Bottom tabs: Padding trung bình để bao phủ đủ icon
    // Targets khác: Padding tiêu chuẩn
    double horizontalPadding = 20.0;
    double verticalPadding = 20.0;
    double cornerRadius = 24.0;

    if (isFAB) {
      // FAB có shadow lớn, cần padding lớn hơn
      horizontalPadding = 24.0;
      verticalPadding = 24.0;
      cornerRadius = 28.0;
    } else if (isBottomTab) {
      // Bottom tabs cần padding đủ để bao icon
      horizontalPadding = 22.0;
      verticalPadding = 22.0;
      cornerRadius = 26.0;
    }

    final spotlightRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        targetRect.left - horizontalPadding,
        targetRect.top - verticalPadding,
        targetRect.right + horizontalPadding,
        targetRect.bottom + verticalPadding,
      ),
      Radius.circular(cornerRadius),
    );

    // 🖼️ Step 3: Sử dụng saveLayer + BlendMode để tạo "lỗ" trong overlay
    // saveLayer cho phép chúng ta vẽ overlay sau đó "xóa" một phần bằng BlendMode.clear
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Vẽ overlay đen phủ toàn bộ màn hình
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // ✨ Step 4: "Xóa" phần overlay tại vị trí target để tạo spotlight sáng
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear; // BlendMode.clear = xóa pixel

    canvas.drawRRect(spotlightRect, clearPaint);

    // Restore layer để áp dụng effect
    canvas.restore();

    // 🌟 Step 5: Thêm outer glow xung quanh spotlight (bright purple glow)
    // Điều chỉnh glow theo loại target
    double glowPadding = 24.0;
    double glowRadius = 28.0;
    double glowOpacity = 0.35;
    double glowStrokeWidth = 8.0;
    double glowBlurRadius = 28.0;

    if (isFAB) {
      // FAB: Glow mạnh hơn để nổi bật
      glowPadding = 28.0;
      glowRadius = 32.0;
      glowOpacity = 0.4;
      glowStrokeWidth = 10.0;
      glowBlurRadius = 32.0;
    } else if (isBottomTab) {
      // Bottom tabs: Glow vừa phải
      glowPadding = 26.0;
      glowRadius = 30.0;
      glowOpacity = 0.38;
      glowStrokeWidth = 9.0;
      glowBlurRadius = 30.0;
    }

    final outerGlowPaint = Paint()
      ..color =
          const Color(0xFF6C5CE7).withValues(alpha: glowOpacity * fadeValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowStrokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlurRadius);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          targetRect.left - glowPadding,
          targetRect.top - glowPadding,
          targetRect.right + glowPadding,
          targetRect.bottom + glowPadding,
        ),
        Radius.circular(glowRadius),
      ),
      outerGlowPaint,
    );

    // 💡 Step 6: Thêm inner glow sáng rõ hơn (bright white inner glow)
    final innerGlowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18 * fadeValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawRRect(spotlightRect, innerGlowPaint);
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.fadeValue != fadeValue ||
        oldDelegate.pulseValue != pulseValue;
  }
}

/// 🎨 Premium Arrow Painter - Vẽ mũi tên tam giác với shadow và gradient
class ArrowPainter extends CustomPainter {
  final bool isPointingDown;
  final Color color;

  ArrowPainter({required this.isPointingDown, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 🎨 Dark shadow paint (purple glow)
    final shadowPaint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // 🎨 Arrow paint
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final shadowPath = Path();

    if (isPointingDown) {
      // 🔽 Mũi tên chỉ xuống (từ tooltip xuống target)
      path.moveTo(size.width / 2 - 15, 0); // Top left
      path.lineTo(size.width / 2 + 15, 0); // Top right
      path.lineTo(size.width / 2, size.height); // Bottom point
      path.close();

      // Shadow offset và lớn hơn một chút
      shadowPath.moveTo(size.width / 2 - 17, 0);
      shadowPath.lineTo(size.width / 2 + 17, 0);
      shadowPath.lineTo(size.width / 2, size.height + 2);
      shadowPath.close();
    } else {
      // 🔼 Mũi tên chỉ lên (từ tooltip lên target)
      path.moveTo(size.width / 2 - 15, size.height); // Bottom left
      path.lineTo(size.width / 2 + 15, size.height); // Bottom right
      path.lineTo(size.width / 2, 0); // Top point
      path.close();

      // Shadow offset và lớn hơn một chút
      shadowPath.moveTo(size.width / 2 - 17, size.height);
      shadowPath.lineTo(size.width / 2 + 17, size.height);
      shadowPath.lineTo(size.width / 2, -2);
      shadowPath.close();
    }

    // Vẽ shadow trước
    canvas.drawPath(shadowPath, shadowPaint);

    // Vẽ arrow
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) {
    return oldDelegate.isPointingDown != isPointingDown ||
        oldDelegate.color != color;
  }
}

/// 🎯 Coach Marks Controller - Quản lý hiển thị tutorial
class CoachMarksController {
  static const String _prefKey = 'has_seen_coach_marks';
  static const String _supabaseMetadataKey = 'has_seen_tutorial';

  /// 🔧 DEV MODE - Bật để luôn hiển thị tutorial (cho testing)
  /// Set = true để test, = false cho production
  static const bool DEV_MODE =
      false; // ✅ PRODUCTION MODE - Tutorial chỉ hiện 1 lần

  /// Check if user đã xem tutorial chưa
  /// ✨ IMPROVED: Check Supabase user metadata (persistent across devices)
  static Future<bool> hasSeenTutorial() async {
    // Nếu dev mode, luôn return false để hiển thị tutorial
    if (DEV_MODE) return false;

    try {
      // 1. Check Supabase user metadata (PERSISTENT - cloud storage)
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null && user.userMetadata != null) {
        final hasSeenInCloud =
            user.userMetadata![_supabaseMetadataKey] as bool?;
        if (hasSeenInCloud == true) {
          ProductionLogger.info(
            '🎯 CoachMarks: User has seen tutorial (from Supabase metadata)',
          );
          return true;
        }
      }

      // 2. Fallback: Check local SharedPreferences (for offline/temp)
      final prefs = await SharedPreferences.getInstance();
      final hasSeenLocal = prefs.getBool(_prefKey) ?? false;

      ProductionLogger.info('🎯 CoachMarks Check: hasSeenLocal = $hasSeenLocal',
          tag: 'app_coach_marks');
      return hasSeenLocal;
    } catch (e) {
      ProductionLogger.info('⚠️ CoachMarks: Error checking tutorial status: $e',
          tag: 'app_coach_marks');
      // Fallback to local prefs if Supabase fails
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? false;
    }
  }

  /// Mark tutorial as seen
  /// ✨ IMPROVED: Save to BOTH Supabase metadata AND local prefs
  static Future<void> markTutorialAsSeen() async {
    // Trong dev mode, không lưu flag (để test lại được)
    if (DEV_MODE) {
      ProductionLogger.info('🔧 DEV MODE: Skipping save tutorial flag',
          tag: 'app_coach_marks');
      return;
    }

    try {
      // 1. Save to Supabase user metadata (PERSISTENT - cloud storage)
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        await supabase.auth.updateUser(
          UserAttributes(
            data: {...?user.userMetadata, _supabaseMetadataKey: true},
          ),
        );
        ProductionLogger.info(
            '✅ CoachMarks: Tutorial marked as seen (saved to Supabase metadata)',
            tag: 'app_coach_marks');
      }

      // 2. Also save locally for faster access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
      ProductionLogger.info('✅ CoachMarks: Tutorial also saved locally',
          tag: 'app_coach_marks');
    } catch (e) {
      ProductionLogger.info('⚠️ CoachMarks: Error saving tutorial status: $e',
          tag: 'app_coach_marks');
      // Fallback: At least save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
      ProductionLogger.info('✅ CoachMarks: Saved locally as fallback',
          tag: 'app_coach_marks');
    }
  }

  /// Reset tutorial (for testing)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    ProductionLogger.info('🔄 Tutorial flag reset - Tutorial sẽ hiện lại',
        tag: 'app_coach_marks');
  }

  /// Show tutorial if chưa xem (hoặc dev mode)
  static Future<void> showIfNeeded({
    required BuildContext context,
    required List<CoachMarkStep> steps,
  }) async {
    final hasSeen = await hasSeenTutorial();

    if (DEV_MODE) {
      ProductionLogger.info('🔧 DEV MODE: Force showing tutorial',
          tag: 'app_coach_marks');
    }

    if (!hasSeen && context.mounted) {
      await AppCoachMarks.show(
        context: context,
        steps: steps,
        onComplete: () async {
          await markTutorialAsSeen();
        },
        onSkip: () async {
          await markTutorialAsSeen();
        },
      );
    }
  }
}
