import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/layout/responsive.dart';
import '../../core/device/device_info.dart';
import 'package:sabo_arena/core/app_export.dart' hide AppTheme, AppColors;
import '../../core/design_system/design_system.dart';
import '../../services/tournament_service.dart';
// import '../../services/club_service.dart';
import '../../services/tournament_eligibility_service.dart';
import '../../services/user_service.dart';
import '../../services/share_service.dart';
import '../../models/tournament.dart';
import '../../models/user_profile.dart';
// import '../../models/club.dart';
import '../../models/tournament_eligibility.dart';
// import '../../utils/number_formatter.dart';

import 'widgets/tournament_management_panel.dart';
import 'widgets/tournament_bracket_view.dart';
import 'widgets/participant_management_tab.dart';
import 'widgets/match_management_tab.dart';
import 'widgets/tournament_stats_view.dart';
import './widgets/payment_options_dialog.dart';
import '../tournament_management_center/widgets/bracket_management_tab.dart';
import './widgets/tournament_header_widget.dart';
import '../tournament_prize_voucher/tournament_prize_voucher_setup_screen.dart';
import '../../widgets/common/app_button.dart';
import 'package:sabo_arena/utils/production_logger.dart';

import 'widgets/tabs/tournament_detail_overview_tab.dart';
import 'widgets/tabs/tournament_detail_rules_tab.dart';
import 'widgets/tabs/tournament_detail_participants_tab.dart';
import 'widgets/tabs/tournament_detail_results_tab.dart';

class TournamentDetailScreen extends StatefulWidget {
  const TournamentDetailScreen({super.key});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late TabController _tabController;
  bool _isRegistered = false;

  // Service instances
  final TournamentService _tournamentService = TournamentService.instance;
  // final ClubService _clubService = ClubService.instance;

  // State variables
  Tournament? _tournament;
  // Club? _organizerClub;
  List<UserProfile> _participants = [];
  bool _isLoading = true;
  String? _error;
  String? _tournamentId;
  UserProfile? _currentUser;
  EligibilityResult? _eligibilityResult;

  // Tournament rules - default fallback if not provided by API
  final List<String> _tournamentRules = [
    "Giải đấu áp dụng luật 9-ball quốc tế WPA",
    "Mỗi trận đấu thi đấu theo thể thức race to 7 (ai thắng trước 7 game)",
    "Thời gian suy nghĩ tối đa 30 giây cho mỗi cú đánh",
    "Không được sử dụng điện thoại trong quá trình thi đấu",
    "Trang phục lịch sự, không mặc áo ba lỗ hoặc quần short",
    "Nghiêm cấm hành vi gian lận, cãi vã với trọng tài",
    "Thí sinh đến muộn quá 15 phút sẽ bị tước quyền thi đấu",
    "Quyết định của trọng tài là quyết định cuối cùng",
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tournamentId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;

      // Support both String and Map arguments
      if (args is String) {
        _tournamentId = args;
        _loadTournamentData();
      } else if (args is Map<String, dynamic>) {
        _tournamentId = args['tournamentId'] as String?;
        final showResults = args['showResults'] as bool? ?? false;
        _loadTournamentData();

        // If showResults is true, switch to results/rankings tab after loading
        if (showResults) {
          // Tab index 4 is rankings/results
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_tabController.length > 4) {
              _tabController.animateTo(4);
            }
          });
        }
      }
    }
  }

  Future<void> _loadTournamentData() async {
    if (_tournamentId == null) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load tournament details
      _tournament = await _tournamentService.getTournamentById(_tournamentId!);

      // Load organizer club if available
      /* if (_tournament?.clubId != null) {
        try {
          _organizerClub = await _clubService.getClubById(_tournament!.clubId!);
        } catch (e) {
          ProductionLogger.warning('Failed to load organizer club', error: e, tag: 'TournamentDetailScreen');
        }
      } */

      // Load participants
      _participants = await _tournamentService.getTournamentParticipants(
        _tournamentId!,
      );

      // Check if user is already registered
      _isRegistered = await _tournamentService.isRegisteredForTournament(
        _tournamentId!,
      );

      // Load current user
      try {
        _currentUser = await UserService.instance.getCurrentUserProfile();
      } catch (e) {
        ProductionLogger.warning('Failed to load current user',
            error: e, tag: 'TournamentDetailScreen');
      }

      // Check eligibility
      if (_tournament != null && _currentUser != null) {
        _eligibilityResult = TournamentEligibilityService.checkEligibility(
          tournament: _tournament!,
          user: _currentUser!,
          isAlreadyRegistered: _isRegistered,
        );
      }

      // Convert tournament model to UI data format
      _convertTournamentToUIData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _convertTournamentToUIData() {
    if (_tournament == null) return;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              'Không thể tải thông tin giải đấu',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Thử lại',
              type: AppButtonType.primary,
              size: AppButtonSize.medium,
              onPressed: _loadTournamentData,
            ),
          ],
        ),
      );
    }

    if (_tournament == null) {
      return const Center(child: Text('Không tìm thấy giải đấu'));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildResponsiveBody(),
    );
  }

  // 🎯 iPad: Responsive body with max-width constraint for better bracket viewing
  Widget _buildResponsiveBody() {
    final isIPad = DeviceInfo.isIPad(context);
    final maxWidth = isIPad ? 1200.0 : double.infinity; // Wider for brackets

    final bodyWidget = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              TournamentHeaderWidget(
                tournament: _tournament!,
                scrollController: _scrollController,
                onShareTap: _handleShareTournament,
                onMenuAction: _handleMenuAction,
                canEditCover: _canManageTournament(),
                onEditCoverTap: _handleEditCover,
              ),
            ];
          },
          body: Column(
            children: [
              // iOS Facebook Style TabBar
              Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: AppColors.info600,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro',
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'SF Pro',
                  ),
                  indicatorColor: AppColors.info600,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: AppColors.border,
                  dividerHeight: 1,
                  tabs: const [
                    Tab(icon: Icon(Icons.home_rounded, size: 24)),
                    Tab(icon: Icon(Icons.account_tree_rounded, size: 24)),
                    Tab(icon: Icon(Icons.groups_rounded, size: 24)),
                    Tab(icon: Icon(Icons.gavel_rounded, size: 24)),
                    Tab(icon: Icon(Icons.emoji_events_rounded, size: 24)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildBracketTab(),
                    _buildParticipantsTab(),
                    _buildRulesTab(),
                    _buildResultsTab(),
                  ],
                ),
              ),
            ],
          ), // Column
        ), // NestedScrollView
      ), // ConstrainedBox
    ); // Center

    return Scaffold(
      body: bodyWidget,
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      // Add bottom padding to push FAB above tabs
      bottomNavigationBar: const SizedBox(height: 16), // Transparent spacer
    );
  }

  Widget _buildOverviewTab() {
    return TournamentDetailOverviewTab(
      eligibilityResult: _eligibilityResult,
      tournament: _tournament!,
      isRegistered: _isRegistered,
      onRegisterTap:
          _eligibilityResult?.isEligible == true ? _handleRegistration : null,
      onRegisterWithPayment: _eligibilityResult?.isEligible == true
          ? (paymentMethod) =>
              _performRegistration(paymentMethod: paymentMethod)
          : null,
      onWithdrawTap: _handleWithdrawal,
    );
  }

  Widget _buildBracketTab() {
    // Use BracketManagementTab from Tournament Management Center
    if (_tournament == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BracketManagementTab(tournament: _tournament!);
  }

  Widget _buildParticipantsTab() {
    return TournamentDetailParticipantsTab(
      participants: _participants,
      onViewAllTap: _handleViewAllParticipants,
    );
  }

  Widget _buildRulesTab() {
    return TournamentDetailRulesTab(
      tournament: _tournament,
      defaultRules: _tournamentRules,
    );
  }

  Widget _buildResultsTab() {
    return TournamentDetailResultsTab(
      tournamentId: _tournamentId,
      tournament: _tournament,
    );
  }

  Widget? _buildFloatingActionButton() {
    // Don't show button if tournament data is not loaded
    if (_tournament == null) return null;

    final isDeadlinePassed =
        DateTime.now().isAfter(_tournament!.registrationDeadline);
    final isFull =
        _tournament!.currentParticipants >= _tournament!.maxParticipants;

    // Determine button state
    String buttonText;
    Color buttonColor;
    IconData buttonIcon;
    VoidCallback? onPressed;

    if (isDeadlinePassed) {
      buttonText = 'Hết hạn đăng ký';
      buttonColor = AppColors.border;
      buttonIcon = Icons.event_busy;
      onPressed = null;
    } else if (_isRegistered) {
      buttonText = 'Đã đăng ký ✓';
      buttonColor = AppColors.info600;
      buttonIcon = Icons.check_circle_outline;
      onPressed = () {
        // Show options: view registration, withdraw, pay
        _showRegistrationOptions();
      };
    } else if (isFull) {
      buttonText = 'Đầy';
      buttonColor = AppColors.textTertiary;
      buttonIcon = Icons.group_off_rounded;
      onPressed = null;
    } else {
      buttonText = 'Đăng ký';
      buttonColor = AppColors.info600;
      buttonIcon = Icons.edit_calendar_rounded;
      onPressed = _handleRegistration;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: FloatingActionButton.extended(
              heroTag: 'tournament_detail_action',
              onPressed: onPressed,
              backgroundColor: buttonColor.withValues(alpha: 0.95),
              foregroundColor: AppColors.textOnPrimary,
              elevation: onPressed == null ? 0 : 3,
              highlightElevation: onPressed == null ? 0 : 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              icon: Icon(buttonIcon, size: 20),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /* bool _isDeadlinePassed(String deadline) {
    try {
      final deadlineDate = DateTime.parse(
        deadline.split(' ')[0].split('/').reversed.join('-'),
      );
      return DateTime.now().isAfter(deadlineDate);
    } catch (e) {
      return false;
    }
  } */

  void _showRegistrationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đăng ký của bạn',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.payment,
              title: 'Thanh toán lệ phí',
              subtitle: 'Hoàn tất đăng ký bằng cách thanh toán',
              color: AppColors.info600,
              onTap: () {
                Navigator.pop(context);
                // Handle payment
                _handlePayment();
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.info_outline,
              title: 'Xem thông tin đăng ký',
              subtitle: 'Chi tiết về đăng ký của bạn',
              color: AppColors.textSecondary,
              onTap: () {
                Navigator.pop(context);
                // Show registration details
                _showRegistrationDetails();
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.exit_to_app,
              title: 'Rút lui',
              subtitle: 'Hủy đăng ký tham gia giải đấu',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                _handleWithdrawal();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _handlePayment() {
    // TODO: Implement payment logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng thanh toán đang được phát triển'),
        backgroundColor: AppColors.info600,
      ),
    );
  }

  void _showRegistrationDetails() {
    // TODO: Show detailed registration info
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hiển thị thông tin đăng ký'),
        backgroundColor: AppColors.info600,
      ),
    );
  }

  Future<void> _handleShareTournament() async {
    if (_tournament == null) {
      _showMessage('Không thể chia sẻ giải đấu', isError: true);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tạo hình ảnh chia sẻ...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Use rich share with image
      await ShareService.shareTournamentRich(
        tournamentId: _tournament!.id,
        tournamentName: _tournament!.title,
        startDate: _tournament!.startDate.toIso8601String(),
        participants: _tournament!.maxParticipants,
        prizePool: _tournament!.prizePool.toString(),
        format: _tournament!.format,
        status: _tournament!.status,
        context: context,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      _showMessage('✅ Đã chia sẻ giải đấu!');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      _showMessage('⚠️ Lỗi chia sẻ: $e', isError: true);
    }
  }

  void _handleRegistration() {
    if (_tournament == null) {
      _showMessage('Không thể tải thông tin giải đấu', isError: true);
      return;
    }

    // Show new payment options dialog
    showDialog(
      context: context,
      builder: (context) => PaymentOptionsDialog(
        tournamentId: _tournament!.id,
        tournamentName: _tournament!.title,
        entryFee: _tournament!.entryFee,
        clubId: _tournament?.clubId ?? '',
        onPaymentConfirmed: (paymentMethod) async {
          // Perform registration with selected payment method
          await _performRegistration(paymentMethod: paymentMethod);
        },
      ),
    );
  }

  Future<void> _performRegistration({String? paymentMethod}) async {
    try {
      // Show loading message
      _showMessage('Đang xử lý đăng ký...', duration: 2);

      // Call registration service with actual payment method
      final success = await _tournamentService.registerForTournament(
        _tournamentId!,
        paymentMethod: paymentMethod ?? '0', // Use provided method or default
      );

      if (success && mounted) {
        // Update UI state
        setState(() {
          _isRegistered = true;
        });

        // Reload tournament data
        await _loadTournamentData();

        // Show success message based on payment method
        String successMessage;
        if (paymentMethod == '1') {
          // Bank transfer - needs club confirmation
          successMessage =
              'Đăng ký thành công! Vui lòng chờ CLB xác nhận thanh toán.';
        } else if (paymentMethod == '0') {
          // Cash payment at venue
          successMessage =
              'Đăng ký thành công! Vui lòng thanh toán tại quán khi đến thi đấu.';
        } else {
          // Default message
          successMessage = 'Đăng ký thành công!';
        }

        _showMessage(
          successMessage,
          isError: false,
          duration: 5,
        );
      } else {
        throw Exception('Registration service returned false');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Đăng ký thất bại: ${error.toString()}',
          isError: true,
          duration: 5,
        );
      }
    }
  }

  void _showMessage(String message, {bool isError = false, int duration = 3}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          duration: Duration(seconds: duration),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _handleWithdrawal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Xác nhận rút lui',
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn rút lui khỏi giải đấu này? Lệ phí đã đóng sẽ được hoàn trả 80%.',
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          AppButton(
            label: 'Rút lui',
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
            customColor: Theme.of(context).colorScheme.error,
            customTextColor: Theme.of(context).colorScheme.onError,
            onPressed: () {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              if (mounted) {
                setState(() {
                  _isRegistered = false;
                });
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã rút lui khỏi giải đấu thành công',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onInverseSurface,
                          ),
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.inverseSurface,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleViewAllParticipants() {
    final participantsData =
        {}; // _convertParticipantsToUIData() // Temporarily disabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 600,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(Gaps.xl),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: Gaps.lg),
                  Text(
                    'Danh sách tham gia (${participantsData.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: Gaps.xl),
                itemCount: participantsData.length,
                itemBuilder: (context, index) {
                  final participant = participantsData[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: Gaps.sm),
                    padding: const EdgeInsets.all(Gaps.lg),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${index + 1}',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        const SizedBox(width: Gaps.md),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(27),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(27),
                            child: CustomImageWidget(
                              imageUrl: participant["avatar"] as String,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: Gaps.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                participant["name"] as String,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Rank ${participant["rank"]} • ${participant["elo"]} ELO',
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBracketView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TournamentBracketView(
        tournamentId: _tournament!.id,
        format: _tournament!.tournamentType,
        totalParticipants: _tournament!.currentParticipants,
        isEditable: _canManageTournament(),
      ),
    );
  }

  void _showParticipantManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ParticipantManagementTab(
          tournamentId: _tournament!.id,
        ),
      ),
    );
  }

  void _showManagementPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TournamentManagementPanel(
        tournamentId: _tournament!.id,
        tournamentStatus: _tournament!.status,
        onStatusChanged: () {
          // Reload tournament data if needed
          setState(() {});
        },
      ),
    );
  }

  void _showMatchManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: MatchManagementTab(
          tournamentId: _tournament!.id,
        ),
      ),
    );
  }

  void _showTournamentStats() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TournamentStatsView(
        tournamentId: _tournament!.id,
        tournamentStatus: _tournament!.status,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'participants':
        _showParticipantManagement();
        break;
      case 'bracket':
        _showBracketView();
        break;
      case 'matches':
        _showMatchManagement();
        break;
      case 'stats':
        _showTournamentStats();
        break;
      case 'manage':
        if (_canManageTournament()) {
          _showManagementPanel();
        }
        break;
      case 'share':
        _handleShareTournament();
        break;
      case 'prize_vouchers':
        _showPrizeVoucherSetup();
        break;
    }
  }

  bool _canManageTournament() {
    // Add logic to check if current user can manage this tournament
    // For now, return true for demo
    return true;
  }

  Future<void> _handleEditCover() async {
    if (_tournament == null) return;

    // Show bottom sheet with image picker options
    final result = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thay đổi ảnh bìa giải đấu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Camera option
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.info600),
                title: const Text('Chụp ảnh'),
                onTap: () async {
                  final picker = ImagePicker();
                  final image =
                      await picker.pickImage(source: ImageSource.camera);
                  if (context.mounted) {
                    Navigator.pop(context, image);
                  }
                },
              ),
              // Gallery option
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.info600),
                title: const Text('Chọn từ thư viện'),
                onTap: () async {
                  final picker = ImagePicker();
                  final image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (context.mounted) {
                    Navigator.pop(context, image);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null || !mounted) return;

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Read file bytes
      final bytes = await result.readAsBytes();

      // Upload and update cover
      final updatedTournament =
          await _tournamentService.uploadAndUpdateTournamentCover(
        _tournament!.id,
        bytes,
        result.name,
      );

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        // Update UI
        setState(() {
          _tournament = updatedTournament;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh bìa thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showPrizeVoucherSetup() async {
    if (_tournament == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentPrizeVoucherSetupScreen(
          tournamentId: _tournament!.id,
          tournamentTitle: _tournament!.title,
        ),
      ),
    );

    // Reload if config was saved
    if (result == true) {
      _loadTournamentData();
    }
  }
}
