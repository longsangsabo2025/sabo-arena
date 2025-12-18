import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../../core/app_export.dart';
import '../../utils/size_extensions.dart';
// ELON_MODE_AUTO_FIX

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<OnboardingData> _onboardingData;
  String _selectedRole = ""; // "player" or "club_owner"

  // Animation controllers for premium effects
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _initializeOnboardingData();
    _initAnimations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    // Floating animation for illustrations (smooth up-down motion)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Pulse animation for role selection cards
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Rotate animation for logo
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Particle animation for background
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void _initializeOnboardingData() {
    _onboardingData = [
      OnboardingData(
        title: "BẠN QUAN TÂM ĐIỀU GÌ?",
        description: "Chọn vai trò để chúng tôi tối ưu trải nghiệm cho bạn",
        imagePath: "assets/images/billiard_ball.svg",
        showRoleSelection: true,
      ),
    ];
  }

  void _setRoleSpecificData(String role) {
    setState(() {
      _selectedRole = role;

      if (role == "player") {
        _onboardingData = [
          _onboardingData[0], // Keep role selection screen
          OnboardingData(
            title: "TÌM ĐỐI THỦ DỄ DÀNG",
            description:
                "Kết nối với hàng nghìn cơ thủ cùng trình độ. Không còn lo thiếu đối thủ để thách đấu!",
            imagePath: "assets/images/find_opponent.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "THAM GIA GIẢI ĐẤU",
            description:
                "Thách thức bản thân qua các giải đấu chuyên nghiệp. Cải thiện kỹ năng và nhận phần thưởng hấp dẫn.",
            imagePath: "assets/images/tournament.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "THÁCH ĐẤU 1-VS-1",
            description:
                "Giao lưu với cơ thủ khắp nơi. Học hỏi kỹ thuật và nâng cao trình độ qua mỗi trận đấu.",
            imagePath: "assets/images/challenge.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "THEO DÕI THÀNH TÍCH",
            description:
                "Lưu trữ lịch sử thi đấu, thống kê chi tiết và theo dõi quá trình tiến bộ. Xây dựng danh tiếng cơ thủ của bạn!",
            imagePath: "assets/images/achievements.svg",
            showRoleSelection: false,
          ),
        ];
      } else if (role == "club_owner") {
        _onboardingData = [
          _onboardingData[0], // Keep role selection screen
          OnboardingData(
            title: "CHUYỂN ĐỔI SỐ CLB",
            description:
                "Hiện đại hóa CLB với nền tảng quản lý toàn diện. Tối ưu hoá doanh thu và nâng cao trải nghiệm khách hàng.",
            imagePath: "assets/images/digital_transformation.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "KẾT NỐI CỘNG ĐỒNG",
            description:
                "Tiếp cận hàng nghìn cơ thủ được xác minh. Tăng lượng khách hàng và xây dựng cộng đồng gắn kết.",
            imagePath: "assets/images/community.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "QUẢN LÝ GIẢI ĐẤU",
            description:
                "Tổ chức và quản lý giải đấu chuyên nghiệp. Tự động hóa quy trình và tối ưu chi phí vận hành.",
            imagePath: "assets/images/tournament_management.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "GIỮ CHÂN THÀNH VIÊN",
            description:
                "Tạo lộ trình nâng hạng rõ ràng và cơ hội thi đấu thường xuyên. Tăng sự gắn kết của thành viên với CLB.",
            imagePath: "assets/images/member_retention.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "MARKETING THÔNG MINH",
            description:
                "Tiếp cận khách hàng tiềm năng mà không cần chi phí quảng cáo cao. Hệ thống tự động quảng bá CLB cho cộng đồng.",
            imagePath: "assets/images/marketing.svg",
            showRoleSelection: false,
          ),
        ];
      }
    });
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      // Save user interest for post-login personalization
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      
      // Default to 'player' if nothing selected (for the "Skip" case)
      final roleToSave = _selectedRole.isEmpty ? 'player' : _selectedRole;
      await prefs.setString('interested_role', roleToSave);

      if (mounted) {
        // Unified flow: Everyone goes to Login
        // We pass the interest so Login screen can adapt UI if needed
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.loginScreen,
          arguments: {'preselectedRole': roleToSave},
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.loginScreen,
          arguments: {'preselectedRole': 'player'},
        );
      }
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2C1810), // Dark brown like billiards table edge
                  Color(0xFF1A1A1A), // Deep black like billiards balls
                  Color(0xFF0F4F3C), // Deep green like billiards table
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Animated particles background - DISABLED for web stability
          // Content with overlay
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Premium skip/start button
                  Padding(
                    padding: const EdgeInsets.only(top: 16, right: 24),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final isLastPage =
                              _currentPage == _onboardingData.length - 1;
                          final isRoleSelectionPage = _onboardingData[_currentPage].showRoleSelection;
                          
                          // Hide button completely if on role selection page (regardless of selection state)
                          if (isRoleSelectionPage) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            decoration: BoxDecoration(
                              gradient: isLastPage
                                  ? LinearGradient(
                                      colors: [
                                        AppTheme.primaryLight.withValues(
                                          alpha:
                                              0.9 +
                                              (_pulseController.value * 0.1),
                                        ),
                                        AppTheme.secondaryLight.withValues(
                                          alpha:
                                              0.8 +
                                              (_pulseController.value * 0.1),
                                        ),
                                      ],
                                    )
                                  : null,
                              color: isLastPage
                                  ? null
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(28),
                              // Border removed
                              boxShadow: isLastPage
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryLight.withValues(
                                          alpha:
                                              0.3 +
                                              (_pulseController.value * 0.2),
                                        ),
                                        blurRadius:
                                            15 + (_pulseController.value * 8),
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _skipOnboarding,
                                borderRadius: BorderRadius.circular(28),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isLastPage ? "Bắt đầu" : "Bỏ qua", overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: isLastPage
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 1),
                                              blurRadius: 2,
                                              color: Colors.black.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isLastPage) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _onboardingData.length,
                      itemBuilder: (context, index) {
                        final data = _onboardingData[index];

                        if (data.showRoleSelection) {
                          return _buildRoleSelectionPage(data);
                        } else {
                          return _buildContentPage(data);
                        }
                      },
                    ),
                  ),
                  
                  SizedBox(height: 2.h),

                  // Navigation dots - Premium style
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_onboardingData.length, (index) {
                          final isActive = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            width: isActive ? 8.w : 2.w,
                            height: 1.h,
                            margin: EdgeInsets.symmetric(horizontal: 1.w),
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? LinearGradient(
                                      colors: [
                                        AppTheme.primaryLight,
                                        AppTheme.secondaryLight,
                                      ],
                                    )
                                  : null,
                              color: isActive
                                  ? null
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryLight.withValues(
                                          alpha: 0.4 + (_pulseController.value * 0.2),
                                        ),
                                        blurRadius: 12 + (_pulseController.value * 5),
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      );
                    },
                  ),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelectionPage(OnboardingData data) {
    final bool isPlayerSelected = _selectedRole == "player";
    final bool isClubOwnerSelected = _selectedRole == "club_owner";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Logo - Animated with rotation and glow (increased size 2x, centered)
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 180, // Slightly reduced for better fit
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Animated glow effect - stronger for bigger logo
                          BoxShadow(
                            color: AppTheme.primaryLight.withValues(
                              alpha: 0.4 + (_pulseController.value * 0.3),
                            ),
                            blurRadius: 50 + (_pulseController.value * 30),
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: AppTheme.secondaryLight.withValues(
                              alpha: 0.3 + (_pulseController.value * 0.2),
                            ),
                            blurRadius: 40 + (_pulseController.value * 20),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/sabo-arena.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const Spacer(flex: 1),

          // Title - Gradient animated text
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.white,
                    AppTheme.primaryLight.withValues(
                      alpha: 0.8 + (_pulseController.value * 0.2),
                    ),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: Text(
                  data.title, style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 3),
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                      Shadow(
                        offset: const Offset(0, 0),
                        blurRadius: 20,
                        color: AppTheme.primaryLight.withValues(
                          alpha: 0.3 + (_pulseController.value * 0.2),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),

          SizedBox(height: 1.5.h),

          // Subtitle
          Text(
            "Chọn vai trò để bắt đầu", overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(
              fontSize: 15.sp,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 1),

          // Role selection cards
          Row(
            children: [
              Expanded(
                child: _PremiumRoleCard(
                  icon: Icons
                      .sports_golf_rounded, // Metaphor for Cue & Ball
                  title: 'Người chơi',
                  subtitle: 'Tìm đối thủ, tham gia giải đấu',
                  isSelected: isPlayerSelected,
                  pulseAnimation: _pulseController,
                  delay: 0,
                  onTap: () {
                    setState(() {
                      _selectedRole = "player";
                    });
                  },
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _PremiumRoleCard(
                  icon:
                      Icons.storefront_rounded, // Represents the Billiard Club
                  title: 'Chủ CLB',
                  subtitle: 'Quản lý CLB, tổ chức giải đấu',
                  isSelected: isClubOwnerSelected,
                  pulseAnimation: _pulseController,
                  delay: 200,
                  onTap: () {
                    setState(() {
                      _selectedRole = "club_owner";
                    });
                  },
                ),
              ),
            ],
          ),

          const Spacer(flex: 1),

          // Continue button - Musk Minimalist & Futuristic
          if (_selectedRole.isNotEmpty)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.01), // Very subtle scale
                  child: AnimatedOpacity(
                    opacity: _selectedRole.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: double.infinity,
                      height: 56, // Standard mobile button height
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30), // Pill shape
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryLight,
                            AppTheme.secondaryLight,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          // Neon Glow
                          BoxShadow(
                            color: AppTheme.primaryLight.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _setRoleSpecificData(_selectedRole);
                            _nextPage();
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'TIẾP TỤC', // Uppercase
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.5, // Wide spacing
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Animated Arrow
                              Transform.translate(
                                offset: Offset(_pulseController.value * 3, 0),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          else
            SizedBox(height: 8.h), // Placeholder to keep layout stable

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildContentPage(OnboardingData data) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              children: [
                // Animated floating illustration - OPTIMIZED SIZE
                AnimatedBuilder(
                  animation: _floatingController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -10 + (_floatingController.value * 10)),
                      child: SizedBox(
                        width: 60.w, // Reduced from 70.w for better proportion
                        height: 60.w, // Square for icon
                        child: _buildIllustration(_currentPage),
                      ),
                    );
                  },
                ),

                SizedBox(height: 5.h),

                // Gradient title
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      AppTheme.primaryLight.withValues(alpha: 0.9),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: Text(
                    data.title, style: GoogleFonts.inter(
                      fontSize: 22.sp, // Slightly smaller
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 3),
                          blurRadius: 8,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 2.5.h),

                // Description text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w), // More padding
                  child: Text(
                    data.description, style: GoogleFonts.inter(
                      fontSize: 15.sp, // Slightly smaller for balance
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Next/Finish Button (Bottom Right)
          Positioned(
            bottom: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _nextPage,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    color: Colors.white.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _currentPage == _onboardingData.length - 1
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(int pageIndex) {
    if (_selectedRole == "player") {
      return _buildPlayerIllustration(pageIndex);
    } else if (_selectedRole == "club_owner") {
      return _buildClubOwnerIllustration(pageIndex);
    }
    return Container();
  }

  Widget _buildPlayerIllustration(int pageIndex) {
    return _buildPremiumIconIllustration(
      icon: _getPlayerIcon(pageIndex),
      colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
    );
  }

  IconData _getPlayerIcon(int pageIndex) {
    switch (pageIndex) {
      case 1:
        return Icons.person_search_rounded; // Find opponents
      case 2:
        return Icons.emoji_events_rounded; // Tournaments
      case 3:
        return Icons.sports_mma_rounded; // Challenge
      case 4:
        return Icons.analytics_rounded; // Statistics
      default:
        return Icons.sports_rounded;
    }
  }

  Widget _buildPremiumIconIllustration({
    required IconData icon,
    required List<Color> colors,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Animated glow effect - stronger
              BoxShadow(
                color: colors[0].withValues(
                  alpha: 0.5 + (_pulseController.value * 0.3),
                ),
                blurRadius: 60 + (_pulseController.value * 40),
                spreadRadius: 10,
              ),
              BoxShadow(
                color: colors[1].withValues(
                  alpha: 0.4 + (_pulseController.value * 0.2),
                ),
                blurRadius: 50 + (_pulseController.value * 30),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 50.w, // Reduced from 80.w to fit better in 60.w container
              color: colors[0],
              shadows: [
                Shadow(
                  color: colors[1].withValues(alpha: 0.8),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClubOwnerIllustration(int pageIndex) {
    return _buildPremiumIconIllustration(
      icon: _getClubOwnerIcon(pageIndex),
      colors: [
        const Color(0xFF6366F1), // Indigo
        const Color(0xFF8B5CF6), // Purple
      ],
    );
  }

  IconData _getClubOwnerIcon(int pageIndex) {
    switch (pageIndex) {
      case 1:
        return Icons.transform_rounded; // Digital transformation
      case 2:
        return Icons.groups_rounded; // Community
      case 3:
        return Icons.event_available_rounded; // Tournament management
      case 4:
        return Icons.favorite_rounded; // Member retention
      case 5:
        return Icons.campaign_rounded; // Marketing
      default:
        return Icons.business_rounded;
    }
  }
}

// Premium Role Selection Card with Animations
class _PremiumRoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final AnimationController pulseAnimation;
  final int delay;

  const _PremiumRoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.pulseAnimation,
    required this.delay,
  });

  @override
  State<_PremiumRoleCard> createState() => _PremiumRoleCardState();
}

class _PremiumRoleCardState extends State<_PremiumRoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final scale = _scaleAnimation.value;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: (_) {
              _scaleController.forward();
            },
            onTapUp: (_) {
              _scaleController.reverse();
              widget.onTap();
            },
            onTapCancel: () {
              _scaleController.reverse();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
              child: Container(
                decoration: widget.isSelected
                    ? BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryLight.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryLight.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      )
                    : null,
                padding: EdgeInsets.all(2.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon only - NO BORDER, NO BACKGROUND
                    Icon(
                      widget.icon,
                      size: 60.w, // Icon lớn
                      color: widget.isSelected
                          ? AppTheme.primaryLight
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: 1.h),
                    // Title with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => widget.isSelected
                          ? LinearGradient(
                              colors: [
                                Colors.white,
                                AppTheme.primaryLight.withValues(alpha: 0.9),
                              ],
                            ).createShader(bounds)
                          : const LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ).createShader(bounds),
                      child: Text(
                        widget.title, style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: widget.isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    // Subtitle
                    Text(
                      widget.subtitle, style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: widget.isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.5),
                        height: 1.4,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String imagePath;
  final bool showRoleSelection;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.showRoleSelection,
  });
}

