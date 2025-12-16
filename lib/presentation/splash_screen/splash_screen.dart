import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_navigation_controller.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _textAnimationController;
  late AnimationController _logoAnimationController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _logoRotateAnimation;
  
  // 📊 Progress tracking
  double _loadingProgress = 0.0;
  String _loadingStatus = 'Đang khởi động...';

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Text animation controller
    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Logo animation controller
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Progress controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Create sophisticated animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeIn),
    );

    _logoRotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations sequence
    _startAnimations();
    _simulateLoading();
    _navigateToHome();
  }

  void _startAnimations() async {
    _animationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _logoAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _textAnimationController.forward();
  }

  // 📊 Simulate loading progress with realistic steps
  void _simulateLoading() async {
    final steps = [
      {'progress': 0.15, 'status': 'Đang khởi tạo...', 'delay': 200},
      {'progress': 0.35, 'status': 'Đang tải cấu hình...', 'delay': 300},
      {'progress': 0.55, 'status': 'Đang kết nối server...', 'delay': 400},
      {'progress': 0.75, 'status': 'Đang tải dữ liệu...', 'delay': 400},
      {'progress': 0.90, 'status': 'Hoàn tất...', 'delay': 300},
      {'progress': 1.0, 'status': 'Sẵn sàng!', 'delay': 200},
    ];

    for (var step in steps) {
      await Future.delayed(Duration(milliseconds: step['delay'] as int));
      if (mounted) {
        setState(() {
          _loadingProgress = step['progress'] as double;
          _loadingStatus = step['status'] as String;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textAnimationController.dispose();
    _logoAnimationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  _navigateToHome() async {
    try {
      await Future.delayed(const Duration(milliseconds: 3000), () {});

      if (!mounted) return;

      // 🎯 Use the new AuthNavigationController for proper flow
      await AuthNavigationController.navigateFromSplash(context);
    } catch (e) {
      ProductionLogger.info('ERROR in _navigateToHome: $e', tag: 'splash_screen');
      // Fallback navigation
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
              theme.colorScheme.secondary,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background decoration
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  backgroundBlendMode: BlendMode.overlay,
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _logoRotateAnimation.value * 0.1,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: SvgPicture.asset(
                              'assets/images/logo.svg',
                              height: 140,
                              width: 140,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Animated App Name - Using MONTSERRAT
                  AnimatedBuilder(
                    animation: _textAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Text(
                            "SABO ARENA", overflow: TextOverflow.ellipsis, style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 4),
                                  blurRadius: 8,
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Animated Tagline - Using SOURCE SANS 3
                  AnimatedBuilder(
                    animation: _textAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value * 0.5),
                          child: Text(
                            "Kết nối những tay cơ thủ", overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black.withValues(alpha: 0.2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Loading indicator with progress at bottom
            Positioned(
              bottom: 60,
              left: 40,
              right: 40,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 8,
                        child: LinearProgressIndicator(
                          value: _loadingProgress,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Progress percentage and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _loadingStatus,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(_loadingProgress * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
