// 🎯 SABO ARENA - Bracket Management Tab
// Real tournament bracket management with live participant data
// Integrates bracket generation, visualization and progression

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/device/device_info.dart';
import '../../../models/tournament.dart';
import '../../../services/bracket_visualization_service.dart';
import '../../../services/tournament_service.dart';
import '../../tournament_detail_screen/widgets/full_tournament_bracket_screen.dart';
import '../../../services/tournament/tournament_completion_orchestrator.dart';
import '../../../services/production_bracket_service.dart';
import '../../../services/user_service.dart'; // ADD: Import UserService
import '../../../services/club_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX // ADD: Import ClubService

// Helper class for progress tracking
class CompletionProgress {
  final String step;
  final double progress;

  CompletionProgress({required this.step, required this.progress});
}

class BracketManagementTab extends StatefulWidget {
  final Tournament tournament;

  const BracketManagementTab({super.key, required this.tournament});

  @override
  State<BracketManagementTab> createState() => _BracketManagementTabState();
}

class _BracketManagementTabState extends State<BracketManagementTab> {
  final TournamentService _tournamentService = TournamentService.instance;
  final UserService _userService = UserService.instance; // ADD: UserService instance
  final ClubService _clubService = ClubService.instance; // ADD: ClubService instance
  final BracketVisualizationService _visualizationService =
      BracketVisualizationService.instance;

  bool _isLoading = false;
  bool _hasBracket = false;
  Map<String, dynamic>? _bracketData;
  String? _errorMessage;
  bool _isClubOwner = false; // ADD: Track if current user is club owner

  @override
  void initState() {
    super.initState();
    _loadBracketData();
    _checkClubOwnership(); // ADD: Check if user is club owner
  }

  // ADD: Check if current user is the club owner
  Future<void> _checkClubOwnership() async {
    try {
      final userProfile = await _userService.getCurrentUserProfile();
      if (userProfile == null) return;

      // Check if user is the owner of the club that created the tournament
      final clubId = widget.tournament.clubId;
      if (clubId == null) return; // No club, can't be owner
      
      final club = await _clubService.getClubById(clubId);
      if (club.ownerId == userProfile.id) {
        setState(() {
          _isClubOwner = true;
        });
      }
    } catch (e) {
      // If error, default to false (not owner)
      setState(() {
        _isClubOwner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 iPad: Extra padding for better bracket viewing
    final isIPad = DeviceInfo.isIPad(context);
    final padding = isIPad ? 4.w : 3.w;
    
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header hidden for cleaner UI
              // _buildHeader(),
              // SizedBox(height: 2.h),
              if (_isLoading)
                _buildLoadingState()
              else if (_errorMessage != null)
                _buildErrorState()
              else if (!_hasBracket)
                _buildNoBracketState()
              else
                _buildBracketView(),
            ],
          ),
        ),

        // Floating action buttons with semi-transparent background
        if (_hasBracket)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Full Tournament button
                  IconButton(
                    onPressed: _openFullTournamentView,
                    icon: const Icon(Icons.fullscreen, color: Color(0xFF6C757D)),
                    tooltip: 'Full Tournament View',
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  // Complete Tournament button - ONLY for Club Owners
                  if (widget.tournament.status != 'completed' && _isClubOwner) ...[
                    IconButton(
                      onPressed: _completeTournament,
                      icon: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF28A745),
                      ),
                      tooltip: 'Complete Tournament',
                      iconSize: 24,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                  ],
                  // Refresh button
                  IconButton(
                    onPressed: _refreshBracket,
                    icon: const Icon(Icons.refresh, color: Color(0xFF2E86AB)),
                    tooltip: 'Refresh Bracket',
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Header with bracket controls
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E86AB), Color(0xFF1B5E7D)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.account_tree, color: Colors.white, size: 6.w),
          ),
          // Header texts hidden for cleaner UI
          // SizedBox(width: 3.w),
          // Expanded(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         'Bracket Management',
          //         style: TextStyle(
          //           color: Colors.white,
          //           fontSize: 18.sp,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //       Text(
          //         widget.tournament.title,
          //         style: TextStyle(
          //           color: Colors.white70,
          //           fontSize: 12.sp,
          //         ),
          //         overflow: TextOverflow.ellipsis,
          //       ),
          //     ],
          //   ),
          // ),
          const Spacer(),
          if (_hasBracket) _buildBracketActions(),
        ],
      ),
    );
  }

  /// Bracket action buttons
  Widget _buildBracketActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _refreshBracket,
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh Bracket',
        ),
        IconButton(
          onPressed: _regenerateBracket,
          icon: const Icon(Icons.autorenew, color: Colors.white),
          tooltip: 'Regenerate Bracket',
        ),
      ],
    );
  }

  /// Loading state
  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF2E86AB),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Loading bracket data...',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Error state
  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 15.w),
            SizedBox(height: 2.h),
            Text(
              'Error loading bracket',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: _loadBracketData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E86AB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// No bracket state
  Widget _buildNoBracketState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_outlined,
              color: Colors.grey[400],
              size: 20.w,
            ),
            SizedBox(height: 3.h),
            Text(
              'Chưa có sơ đồ bảng đấu',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Hãy tạo bảng đấu để bắt đầu giải',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            ),
            SizedBox(height: 3.h),
            _buildTournamentInfo(),
          ],
        ),
      ),
    );
  }

  /// Tournament info card
  Widget _buildTournamentInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Format • Status',
            '${_formatTournamentType(widget.tournament.tournamentType)} • ${widget.tournament.status.toUpperCase()}',
          ),
          SizedBox(height: 1.h),
          _buildInfoRow(
            'Participants',
            '${widget.tournament.currentParticipants}/${widget.tournament.maxParticipants}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E86AB),
          ),
        ),
      ],
    );
  }

  /// Bracket view
  Widget _buildBracketView() {
    // Safety check: ensure bracket data exists
    if (_bracketData == null) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Không thể tải dữ liệu bracket',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: FutureBuilder<Widget>(
          future: _visualizationService.buildTournamentBracket(
            tournamentId: widget.tournament.id,
            bracketData: _bracketData!,
            onMatchTap: _handleMatchTap,
            showLiveUpdates: true,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi hiển thị bracket: ${snapshot.error}',
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return snapshot.data ?? const SizedBox();
          },
        ),
      ),
    );
  }

  // ==================== DATA METHODS ====================

  /// Load existing bracket data
  Future<void> _loadBracketData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load matches using TournamentService (same as Match Management Tab)
      final matches = await _tournamentService.getTournamentMatches(
        widget.tournament.id,
      );

      if (matches.isNotEmpty) {
        // Create bracket data from matches
        final bracketData = {
          'tournament_id': widget.tournament.id,
          'matches': matches,
          'format': widget.tournament.bracketFormat,
          'total_participants': widget.tournament.currentParticipants,
          'participantCount': widget.tournament.currentParticipants, // Add for compatibility
        };

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        setState(() {
          _bracketData = bracketData;
          _hasBracket = true;
          _isLoading = false;
        });
      } else {
        // No matches found - no bracket exists yet
        setState(() {
          _hasBracket = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Generate new bracket using ProductionBracketService with proper format support
  Future<void> _generateBracket() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use ProductionBracketService which supports all formats including sabo_de64
      final productionService = ProductionBracketService();
      
      ProductionLogger.info('🎯 Creating bracket with format: ${widget.tournament.bracketFormat}', tag: 'bracket_management_tab');
      
      final result = await productionService.createTournamentBracket(
        tournamentId: widget.tournament.id,
        format: widget.tournament.bracketFormat,
      );

      if (result?['success'] == true) {
        // Reload bracket data from database to get fresh matches
        setState(() {
          _hasBracket = true;
          _isLoading = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result?['message'] as String? ??
                    'Bracket generated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage =
              result?['error'] as String? ?? 'Failed to generate bracket';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Refresh bracket data
  Future<void> _refreshBracket() async {
    await _loadBracketData();
  }

  /// Open full tournament view in browser
  Future<void> _openFullTournamentView() async {
    try {
      if (!mounted) return;

      // Tạo URL để xem bracket full screen trên web
      String webUrl = _generateTournamentBracketWebUrl();
      
      final Uri url = Uri.parse(webUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: Mở native screen như cũ nếu không thể mở web
        _openNativeBracketScreen();
      }
    } catch (e) {
      ProductionLogger.info('❌ Error opening full tournament view: $e', tag: 'bracket_management_tab');
      // Fallback: Mở native screen như cũ nếu có lỗi
      _openNativeBracketScreen();
    }
  }

  String _generateTournamentBracketWebUrl() {
    // Tạo URL web cho tournament detail page
    // Sử dụng format URL thật của SABO Arena
    const String baseUrl = 'https://saboarena.com/tournaments';
    
    return '$baseUrl/${widget.tournament.id}?ref=app_fullscreen';
  }

  void _openNativeBracketScreen() {
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullTournamentBracketScreen(
          tournamentId: widget.tournament.id,
          tournamentTitle: widget.tournament.title,
        ),
      ),
    );
  }

  /// Complete tournament manually
  Future<void> _completeTournament() async {
    // Show confirmation dialog
    final confirm = await _showConfirmationDialog(
      'Hoàn thành giải đấu',
      'Bạn có chắc muốn hoàn thành giải đấu này?\n\n'
          '• Tính xếp hạng cuối cùng\n'
          '• Phát thưởng ELO & SPA\n'
          '• Gửi thông báo cho người chơi',
    );

    if (confirm != true) return;

    // Show progress dialog with real-time updates
    if (!mounted) return;
    
    // Create a ValueNotifier to track progress
    final progressNotifier = ValueNotifier<CompletionProgress>(
      CompletionProgress(step: 'Bắt đầu...', progress: 0.0),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CompletionProgressDialog(progressNotifier: progressNotifier),
    );

    try {
      // Import new orchestrator
      final orchestrator = TournamentCompletionOrchestrator.instance;
      
      // Set up progress callback
      orchestrator.setProgressCallback((step, progress) {
        progressNotifier.value = CompletionProgress(step: step, progress: progress);
      });

      // Complete tournament with orchestrator
      final result = await orchestrator.completeTournament(
        tournamentId: widget.tournament.id,
        updateElo: true,
        distributePrizes: true,
        issueVouchers: true,
        sendNotifications: false,
        executeRewards: false, // 🆕 DON'T execute rewards - let admin use "Gửi Quà" button manually
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        progressNotifier.dispose();
      }

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Tournament completed! Use "Gửi Quà" button to distribute rewards.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );

          // Refresh to show updated status
          await _loadBracketData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing tournament: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Regenerate bracket
  Future<void> _regenerateBracket() async {
    final confirm = await _showConfirmationDialog(
      'Regenerate Bracket',
      'This will create a new bracket and overwrite the existing one. Continue?',
    );

    if (confirm == true) {
      await _generateBracket();
    }
  }

  /// Handle match tap
  void _handleMatchTap() {
    // TODO: Navigate to match detail or show match management dialog
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  // ==================== UTILITY METHODS ====================

  String _formatTournamentType(String type) {
    switch (type.toLowerCase()) {
      case 'single_elimination':
        return 'Single Elimination';
      case 'double_elimination':
        return 'Double Elimination';
      case 'sabo_de16':
        return 'SABO DE16';
      case 'sabo_de32':
        return 'SABO DE32';
      case 'round_robin':
        return 'Round Robin';
      case 'swiss_system':
        return 'Swiss System';
      default:
        return type.toUpperCase();
    }
  }

  Future<bool?> _showConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E86AB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

/// Progress dialog showing tournament completion steps
class _CompletionProgressDialog extends StatelessWidget {
  final ValueNotifier<CompletionProgress> progressNotifier;

  const _CompletionProgressDialog({required this.progressNotifier});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissal
      child: ValueListenableBuilder<CompletionProgress>(
        valueListenable: progressNotifier,
        builder: (context, progress, child) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated spinner
                  CircularProgressIndicator(
                    value: progress.progress > 0 ? progress.progress : null,
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E86AB)),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    '🏆 Đang hoàn thành giải đấu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Current step
                  Text(
                    progress.step,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2E86AB),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress percentage
                  Text(
                    '${(progress.progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E86AB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Steps list
                  _buildStep('✅ Kiểm tra trận đấu', progress.progress >= 0.1),
                  _buildStep('⚡ Tính toán xếp hạng', progress.progress >= 0.2),
                  _buildStep('💰 Phát thưởng ELO & SPA', progress.progress >= 0.6),
                  _buildStep('🎁 Tạo voucher Top 4', progress.progress >= 0.8),
                  _buildStep('🏁 Hoàn tất giải đấu', progress.progress >= 0.9),
                  
                  const SizedBox(height: 16),
                  
                  // Warning text
                  const Text(
                    '⚠️ Vui lòng không tắt ứng dụng',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStep(String text, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          if (completed)
            const Icon(Icons.check_circle, size: 16, color: Colors.green)
          else
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: completed ? Colors.green : Colors.grey,
                fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

