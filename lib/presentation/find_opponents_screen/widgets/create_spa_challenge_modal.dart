import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/user/user_avatar_widget.dart';

import '../../../models/user_profile.dart';
import '../../../models/club.dart';
import '../../../services/club_spa_service.dart';
import '../../../services/simple_challenge_service.dart';
import '../../../services/user_service.dart';
import '../../../services/opponent_club_service.dart';
import '../../../services/challenge_rules_service.dart';
import 'user_search_dialog.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class CreateSpaChallengeModal extends StatefulWidget {
  final UserProfile? currentUser;
  final List<UserProfile> opponents;
  final String challengeType; // NEW: 'thach_dau' or 'giao_luu'

  const CreateSpaChallengeModal({
    super.key,
    required this.currentUser,
    required this.opponents,
    this.challengeType = 'thach_dau', // Default to competitive
  });

  @override
  State<CreateSpaChallengeModal> createState() =>
      _CreateSpaChallengeModalState();
}

class _CreateSpaChallengeModalState extends State<CreateSpaChallengeModal> {
  final ClubSpaService _clubSpaService = ClubSpaService();
  final SimpleChallengeService _challengeService =
      SimpleChallengeService.instance;
  final UserService _userService = UserService.instance;

  // SPA Betting Configuration - matches challenge_rules_service.dart
  static const Map<int, int> _spaBettingConfig = {
    100: 8, // 100 SPA → Race to 8
    200: 12, // 200 SPA → Race to 12
    300: 14, // 300 SPA → Race to 14
    400: 16, // 400 SPA → Race to 16
    500: 18, // 500 SPA → Race to 18
    600: 22, // 600 SPA → Race to 22
  };

  UserProfile? _selectedOpponent;
  int _selectedSpaBonus = 100; // Default SPA bonus
  int _selectedRaceTo = 8; // Race-to value (auto-determined by SPA)
  String _selectedGameType = '8-ball';
  String? _rankMin; // Hạng tối thiểu
  String? _rankMax; // Hạng tối đa
  bool _isCreating = false;

  // NEW: SPA Balance tracking
  int _currentUserSpaBalance = 0;

  // NEW: Handicap calculation
  ChallengeHandicapResult? _currentHandicap;
  final ChallengeRulesService _rulesService = ChallengeRulesService.instance;

  // NEW: Date/Time/Location/Mode fields
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 24));
  TimeOfDay _selectedTime = TimeOfDay(hour: 19, minute: 0); // Default 7:00 PM
  Club? _selectedClub; // Selected club object (contains name, address, logo)
  List<Club> _clubs = []; // Available clubs from OpponentClubService
  // Removed: _isOpenMode - always private challenge mode (select specific opponent)
  bool _isLoadingLocations = false;

  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadUserSpaBalance();
  }

  /// Load current user's SPA balance
  Future<void> _loadUserSpaBalance() async {
    if (widget.currentUser == null) return;

    setState(() => _isLoadingSpaBalance = true);
    try {
      final userProfile = await _userService.getCurrentUserProfile();
      setState(() {
        _currentUserSpaBalance = userProfile?.spaPoints ?? 0;
        _isLoadingSpaBalance = false;
      });
    } catch (e) {
      ProductionLogger.info('Error loading SPA balance: $e', tag: 'create_spa_challenge_modal');
      setState(() {
        _currentUserSpaBalance = 0;
        _isLoadingSpaBalance = false;
      });
    }
  }

  /// Calculate handicap based on selected opponent and SPA amount
  void _updateHandicap() {
    if (_selectedOpponent == null || widget.currentUser == null) {
      setState(() => _currentHandicap = null);
      return;
    }

    final currentUserRank = widget.currentUser!.rank;
    final opponentRank = _selectedOpponent!.rank;

    if (currentUserRank == null || opponentRank == null) {
      setState(() => _currentHandicap = null);
      return;
    }

    try {
      final handicapResult = _rulesService.calculateHandicap(
        challengerRank: currentUserRank,
        challengedRank: opponentRank,
        spaBetAmount: _selectedSpaBonus,
      );

      setState(() => _currentHandicap = handicapResult);
    } catch (e) {
      ProductionLogger.info('Error calculating handicap: $e', tag: 'create_spa_challenge_modal');
      setState(() => _currentHandicap = null);
    }
  }

  /// Build handicap preview widget
  Widget _buildHandicapPreview() {
    if (_currentHandicap == null || !_currentHandicap!.isValid) {
      return Container();
    }

    final handicap = _currentHandicap!;
    final isCurrentUserWeaker = handicap.challengerHandicap > 0;
    final handicapAmount = isCurrentUserWeaker
        ? handicap.challengerHandicap
        : handicap.challengedHandicap;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance, color: Colors.purple.shade700, size: 16),
              const SizedBox(width: 8),
              Text(
                'Handicap System',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Race to ${handicap.raceTo}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            handicap.explanation,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.2,
            ),
          ),
          if (handicapAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isCurrentUserWeaker ? Icons.trending_up : Icons.trending_down,
                  color: isCurrentUserWeaker
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isCurrentUserWeaker
                      ? 'Bạn được cộng +${handicapAmount.toStringAsFixed(1)} bàn'
                      : 'Đối thủ được cộng +${handicapAmount.toStringAsFixed(1)} bàn',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrentUserWeaker
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Load available locations from OpponentClubService
  Future<void> _loadLocations() async {
    setState(() => _isLoadingLocations = true);
    try {
      final clubService = OpponentClubService.instance;
      final clubs = await clubService.getActiveClubs();

      setState(() {
        _clubs = clubs
            .where((club) => club.address != null && club.address!.isNotEmpty)
            .toList();

        // Auto-select first club if available
        if (_clubs.isNotEmpty) {
          _selectedClub = _clubs.first;
        }
        _isLoadingLocations = false;
      });
    } catch (e) {
      ProductionLogger.info('Error loading locations: $e', tag: 'create_spa_challenge_modal');
      setState(() {
        // Keep empty - will show error or use fallback
        _isLoadingLocations = false;
      });
    }
  }

  Widget _buildOpponentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display message when no specific opponents are available
        if (widget.opponents.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E88E5).withValues(alpha: 0.05),
                  const Color(0xFF1976D2).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF1E88E5),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Chưa có đối thủ cụ thể. Bạn có thể tạo thách đấu mở cho mọi người tham gia.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E88E5),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Opponent selection list với thiết kế mới
        SizedBox(
          height: 160, // Increased height to prevent overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.opponents.length + 2, // +2 for "Open" and "Search" buttons
            itemBuilder: (context, index) {
              if (index == 0) {
                final isOpenChallenge = _selectedOpponent == null;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedOpponent = null);
                    _updateHandicap();
                  },
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isOpenChallenge
                          ? const Color(0xFF1E88E5).withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isOpenChallenge
                            ? const Color(0xFF1E88E5)
                            : Colors.grey.shade200,
                        width: isOpenChallenge ? 2 : 1,
                      ),
                      boxShadow: isOpenChallenge
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1E88E5).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isOpenChallenge
                                  ? [
                                      const Color(0xFF1E88E5),
                                      const Color(0xFF1976D2),
                                    ]
                                  : [
                                      Colors.grey.shade300,
                                      Colors.grey.shade400,
                                    ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.public,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thách đấu mở',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOpenChallenge
                                ? const Color(0xFF1E88E5)
                                : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Ai cũng tham gia',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // NEW: Add "Search Opponent" button as last item
              if (index == widget.opponents.length + 1) {
                return GestureDetector(
                  onTap: () async {
                    final selectedUser = await showDialog<UserProfile>(
                      context: context,
                      builder: (context) => UserSearchDialog(
                        currentUser: widget.currentUser,
                        excludeUserIds: widget.opponents.map((o) => o.id).toList(),
                      ),
                    );

                    if (selectedUser != null) {
                      setState(() => _selectedOpponent = selectedUser);
                      _updateHandicap();
                    }
                  },
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade100,
                          Colors.orange.shade200,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.shade200.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade600,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade300.withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_search,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tìm đối thủ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Tìm kiếm khác',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final opponent = widget.opponents[index - 1];
              final isSelected = _selectedOpponent?.id == opponent.id;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedOpponent = opponent);
                  _updateHandicap();
                },
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E88E5).withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1E88E5)
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1E88E5).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1E88E5)
                                : Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: UserAvatarWidget(
                          avatarUrl: opponent.avatarUrl,
                          userName: opponent.displayName,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        opponent.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF1E88E5)
                              : Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Hạng: ${opponent.rank ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpaBonusSection() {
    // Check if user has sufficient balance
    final bool hasSufficientBalance =
        _currentUserSpaBalance >= _selectedSpaBonus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Color(0xFF1E88E5),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Phần thưởng SPA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'SPA cao → Race-to dài',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),

        // SPA Balance Display
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasSufficientBalance
                ? Colors.green.shade50
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasSufficientBalance
                  ? Colors.green.shade200
                  : Colors.red.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: hasSufficientBalance
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'SPA hiện tại: ',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              Text(
                '$_currentUserSpaBalance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hasSufficientBalance
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
              const Spacer(),
              if (!hasSufficientBalance) ...[
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade600,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Không đủ SPA',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Đủ SPA',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Handicap Preview Section
        if (_selectedOpponent != null) ...[
          const SizedBox(height: 8),
          _buildHandicapPreview(),
        ],

        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _spaBettingConfig.keys.map((amount) {
              final isSelected = _selectedSpaBonus == amount;
              final raceTo = _spaBettingConfig[amount]!;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedSpaBonus = amount;
                  _selectedRaceTo = raceTo;
                  _updateHandicap();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1E88E5).withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$amount SPA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Race to $raceTo',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// REMOVED: Mode Selector - no longer needed (always private challenge mode)

  /// Build Date Picker
  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 18,
              color: Color(0xFF1E88E5),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ngày thi đấu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF1E88E5),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black87,
                    ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              setState(() => _selectedDate = pickedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, color: Color(0xFF1E88E5), size: 20),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF1E88E5)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build Time Picker
  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: Color(0xFF1E88E5)),
            const SizedBox(width: 8),
            const Text(
              'Giờ thi đấu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF1E88E5),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black87,
                    ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedTime != null) {
              setState(() => _selectedTime = pickedTime);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF1E88E5), size: 20),
                const SizedBox(width: 12),
                Text(
                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF1E88E5)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build Location Picker
  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: Color(0xFFE91E63)),
            const SizedBox(width: 8),
            const Text(
              'Địa điểm',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingLocations)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Đang tải địa điểm...',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          )
        else if (_clubs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Không tìm thấy địa điểm',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: DropdownButton<Club>(
              value: _selectedClub,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE91E63)),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              items: _clubs.map((club) {
                return DropdownMenuItem<Club>(
                  value: club,
                  child: Row(
                    children: [
                      // Club logo if available
                      if (club.logoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            club.logoUrl!,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.place,
                              color: Color(0xFFE91E63),
                              size: 18,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.place,
                          color: Color(0xFFE91E63),
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              club.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (club.address != null)
                              Text(
                                club.address!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedClub = value);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGameTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.sports_basketball,
                color: const Color(0xFF1E88E5),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Loại Game & Race-to',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Enhanced Game Type Selection with Visual Cards
        Row(
          children: [
            _buildGameTypeCard('8-ball', '8', Colors.black, 'Phổ biến nhất'),
            const SizedBox(width: 8),
            _buildGameTypeCard(
              '9-ball',
              '9',
              Colors.yellow.shade600,
              'Tốc độ cao',
            ),
            const SizedBox(width: 8),
            _buildGameTypeCard(
              '10-ball',
              '10',
              Colors.blue.shade600,
              'Chuyên nghiệp',
            ),
          ],
        ),

        const SizedBox(height: 12),
        // Race-to display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.orange.shade600, size: 16),
              const SizedBox(width: 8),
              Text(
                'Race to: $_selectedRaceTo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Text(
                'Tự động theo SPA',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankLimitSection() {
    // Danh sách các hạng từ rank_system (theo thứ tự từ thấp đến cao)
    final List<Map<String, dynamic>> ranks = [
      {'code': 'K', 'name': 'Starter (Người mới)', 'value': 1},
      {'code': 'K+', 'name': 'Apprentice (Học việc)', 'value': 2},
      {'code': 'I', 'name': 'Worker III (Thợ 3)', 'value': 3},
      {'code': 'I+', 'name': 'Worker II (Thợ 2)', 'value': 4},
      {'code': 'H', 'name': 'Worker I (Thợ 1)', 'value': 5},
      {'code': 'H+', 'name': 'Master Worker (Thợ chính)', 'value': 6},
      {'code': 'G', 'name': 'Skilled Worker (Thợ giỏi)', 'value': 7},
      {'code': 'G+', 'name': 'Master Craftsman (Thợ cả)', 'value': 8},
      {'code': 'F', 'name': 'Expert (Chuyên gia)', 'value': 9},
      {'code': 'E', 'name': 'Master (Cao thủ)', 'value': 10},
      {'code': 'D', 'name': 'Legend (Huyền Thoại)', 'value': 11},
      {'code': 'C', 'name': 'Champion (Vô địch)', 'value': 12},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFFFF9800),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Giới hạn hạng tham gia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tùy chọn',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Rank Min Dropdown
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _rankMin,
                  isDense: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    hintText: 'Hạng tối thiểu',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Container(
                        width: 28,
                        height: 28,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.arrow_downward,
                          color: Color(0xFFFF9800),
                          size: 14,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 28,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  isExpanded: true, // Fix overflow
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text(
                        'Không giới hạn',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...ranks.map(
                      (rank) => DropdownMenuItem(
                        value: rank['code'],
                        child: Row(
                          children: [
                            // Rank code ở đầu, bold
                            Text(
                              '${rank['code']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Tên rank sau, màu xám
                            Expanded(
                              child: Text(
                                rank['name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _rankMin = value);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Rank Max Dropdown
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _rankMax,
                  isDense: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    hintText: 'Hạng tối đa',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Container(
                        width: 28,
                        height: 28,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Color(0xFFFF9800),
                          size: 14,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 28,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  isExpanded: true, // Fix overflow
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text(
                        'Không giới hạn',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...ranks.map(
                      (rank) => DropdownMenuItem(
                        value: rank['code'],
                        child: Row(
                          children: [
                            // Rank code ở đầu, bold
                            Text(
                              '${rank['code']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Tên rank sau, màu xám
                            Expanded(
                              child: Text(
                                rank['name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _rankMax = value);
                  },
                ),
              ),
            ),
          ],
        ),
        if (_rankMin != null || _rankMax != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFFF9800),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildRankLimitMessage(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF9800),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _buildRankLimitMessage() {
    if (_rankMin != null && _rankMax != null) {
      return 'Chỉ người chơi từ hạng $_rankMin đến $_rankMax mới có thể tham gia';
    } else if (_rankMin != null) {
      return 'Chỉ người chơi hạng $_rankMin trở lên mới có thể tham gia';
    } else if (_rankMax != null) {
      return 'Chỉ người chơi hạng $_rankMax trở xuống mới có thể tham gia';
    }
    return '';
  }

  String _getRankLimitDisplay() {
    if (_rankMin != null && _rankMax != null) {
      return 'Từ $_rankMin đến $_rankMax';
    } else if (_rankMin != null) {
      return '$_rankMin trở lên';
    } else if (_rankMax != null) {
      return '$_rankMax trở xuống';
    }
    return 'Không giới hạn (Tất cả hạng)';
  }

  Widget _buildInfoSection() {
    final dateStr =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF1E88E5),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.challengeType == 'thach_dau'
                  ? 'Thông tin thách đấu SPA:'
                  : 'Thông tin giao lưu:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E88E5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.challengeType == 'thach_dau'
                ? '• Game: $_selectedGameType - Race to $_selectedRaceTo (theo $_selectedSpaBonus SPA)\n'
                      '• SPA Bonus: Thắng +$_selectedSpaBonus, Thua -$_selectedSpaBonus\n'
                      '• Nguồn SPA từ club pool\n'
                      '• Ngày giờ: $dateStr lúc $timeStr\n'
                      '• Địa điểm: ${_selectedClub?.name ?? "TBD"}\n'
                      '• Đấu với: ${_selectedOpponent?.displayName ?? "đối thủ"}\n'
                      '• Giới hạn hạng: ${_getRankLimitDisplay()}'
                : '• Game: $_selectedGameType\n'
                      '• Ngày giờ: $dateStr lúc $timeStr\n'
                      '• Địa điểm: ${_selectedClub?.name ?? "TBD"}\n'
                      '• Đấu với: ${_selectedOpponent?.displayName ?? "đối thủ"}\n'
                      '• Giới hạn hạng: ${_getRankLimitDisplay()}\n'
                      '• Loại: Chơi vui, không SPA',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  bool get _canCreateChallenge {
    return true; // Always allow creation (either specific opponent or open challenge)
  }

  Future<void> _createChallenge() async {
    if (!_canCreateChallenge) return;

    // ✅ Validation: Require club selection
    if (_selectedClub == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Vui lòng chọn câu lạc bộ'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // ✅ NEW: Support both OPEN and TARGETED challenges
    // - OPEN: _selectedOpponent == null (anyone can join)
    // - TARGETED: _selectedOpponent != null (specific opponent)
    
    // ✅ Validation: Check rank eligibility (only for TARGETED challenges)
    final currentUserRank = widget.currentUser?.rank;
    final opponentRank = _selectedOpponent?.rank;
    
    if (_selectedOpponent != null && currentUserRank != null && opponentRank != null) {
      final rulesService = ChallengeRulesService.instance;
      if (!rulesService.canChallenge(currentUserRank, opponentRank)) {
        if (mounted) {
          // Get eligible ranks for display
          final eligibleRanks = rulesService.getEligibleRanks(currentUserRank);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ Không thể thách đấu!\n'
                'Hạng của bạn ($currentUserRank) không thể thách đấu với hạng $opponentRank.\n'
                'Bạn chỉ có thể thách đấu với: ${eligibleRanks.join(", ")}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }

    setState(() => _isCreating = true);

    try {
      // Get current user profile
      final currentUser = await _userService.getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('Không thể lấy thông tin người dùng');
      }

      // For now, use a default club ID since UserProfile doesn't have clubId field
      // In a real implementation, you would get the user's club from another service
      const String defaultClubId =
          'default-club-id'; // This should be retrieved from user's club membership

      // Check club SPA balance (only for 'thach_dau' challenges)
      if (widget.challengeType == 'thach_dau') {
        final clubBalance = await _clubSpaService.getClubSpaBalance(
          defaultClubId,
        );
        if (clubBalance == null) {
          // If no club balance record exists, we can still create the challenge
          // The SPA reward will be handled when the match is completed
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } else {
          final availableSpa = clubBalance['available_spa'] ?? 0.0;
          if (availableSpa < _selectedSpaBonus) {
            throw Exception(
              'Club không đủ SPA để tạo thách đấu (Cần: $_selectedSpaBonus, Có: ${availableSpa.toInt()})',
            );
          }
        }
      }

      // Combine selected date and time into one DateTime
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create the challenge with all new fields
      final challengeResult = await _challengeService.sendChallenge(
        challengedUserId: _selectedOpponent?.id ?? '', // Empty for OPEN challenge
        challengeType: widget
            .challengeType, // Use widget parameter (thach_dau or giao_luu)
        gameType: _selectedGameType,
        scheduledTime: scheduledDateTime, // Use selected date/time
        location:
            _selectedClub?.name ?? 'TBD', // ✅ FIX: Use club NAME, not address
        clubId: _selectedClub?.id, // Pass club ID for database reference
        spaPoints: widget.challengeType == 'thach_dau'
            ? _selectedSpaBonus
            : 0, // 0 for giao_luu
        rankMin: _rankMin,
        rankMax: _rankMax,
        message: _noteController.text.trim().isEmpty
            ? _buildDefaultMessage()
            : _noteController.text.trim(),
      );

      if (challengeResult != null) {
        if (mounted) {
          Navigator.pop(context);

          final dateStr = '${_selectedDate.day}/${_selectedDate.month}';
          final timeStr =
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
          final locationStr = _selectedClub?.name ?? 'TBD';

          String successMessage;
          final isOpenChallenge = _selectedOpponent == null;
          
          if (widget.challengeType == 'thach_dau') {
            successMessage = isOpenChallenge
                ? 'Thách đấu MỞ đã tạo thành công!\n'
                    '🌏 Ai cũng có thể tham gia\n'
                    '🎮 $_selectedGameType (Race to $_selectedRaceTo)\n'
                    '💰 SPA: ±$_selectedSpaBonus\n'
                    '📅 $dateStr lúc $timeStr\n'
                    '📍 $locationStr\n'
                    'ID: ${challengeResult['id']}'
                : 'Thách đấu đã gửi thành công!\n'
                    '👤 ${_selectedOpponent!.displayName}\n'
                    '🎮 $_selectedGameType (Race to $_selectedRaceTo)\n'
                    '💰 SPA: ±$_selectedSpaBonus\n'
                    '📅 $dateStr lúc $timeStr\n'
                    '📍 $locationStr\n'
                    'ID: ${challengeResult['id']}';
          } else {
            successMessage = isOpenChallenge
                ? 'Lời mời giao lưu MỞ đã tạo!\n'
                    '🌏 Ai cũng có thể tham gia\n'
                    '🎮 $_selectedGameType\n'
                    '📅 $dateStr lúc $timeStr\n'
                    '📍 $locationStr\n'
                    '🤝 Chơi vui không SPA\n'
                    'ID: ${challengeResult['id']}'
                : 'Lời mời giao lưu đã gửi!\n'
                    '👤 ${_selectedOpponent!.displayName}\n'
                    '🎮 $_selectedGameType\n'
                    '📅 $dateStr lúc $timeStr\n'
                      '📍 $locationStr\n'
                      '🤝 Chơi vui không SPA\n'
                      'ID: ${challengeResult['id']}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception('Không thể tạo thách đấu');
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo thách đấu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  /// Build default message based on challenge type and mode
  String _buildDefaultMessage() {
    final dateStr =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final locationStr =
        _selectedClub?.name ?? 'TBD'; // ✅ Use club NAME, not address

    final isOpenChallenge = _selectedOpponent == null;

    if (widget.challengeType == 'thach_dau') {
      // Competitive challenge with SPA
      if (isOpenChallenge) {
        return 'Thách đấu MỞ: $_selectedGameType (Race to $_selectedRaceTo)\n'
            '🌏 Ai cũng có thể tham gia\n'
            '💰 Thắng +$_selectedSpaBonus / Thua -$_selectedSpaBonus\n'
            '📅 $dateStr lúc $timeStr\n'
            '📍 $locationStr';
      } else {
        return 'Thách đấu SPA: $_selectedGameType (Race to $_selectedRaceTo)\n'
            '💰 Thắng +$_selectedSpaBonus / Thua -$_selectedSpaBonus\n'
            '📅 $dateStr lúc $timeStr\n'
            '📍 $locationStr';
      }
    } else {
      // Friendly challenge (giao_luu) - no SPA
      if (isOpenChallenge) {
        return 'Giao lưu MỞ: $_selectedGameType\n'
            '🌏 Ai cũng có thể tham gia\n'
            '📅 $dateStr lúc $timeStr\n'
            '📍 $locationStr\n'
            '🤝 Chơi vui, không SPA';
      } else {
        return 'Giao lưu: $_selectedGameType\n'
            '📅 $dateStr lúc $timeStr\n'
            '📍 $locationStr\n'
            '🤝 Chơi vui, không SPA';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Header with gradient background
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E88E5).withValues(alpha: 0.95),
                  const Color(0xFF1976D2).withValues(alpha: 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.challengeType == 'thach_dau'
                        ? Icons.sports_martial_arts
                        : Icons.handshake,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.challengeType == 'thach_dau'
                        ? 'Tạo thách đấu SPA'
                        : 'Tạo lời mời giao lưu',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Enhanced Content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Opponent Selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1E88E5,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.people,
                                  color: Color(0xFF1E88E5),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Chọn đối thủ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Tùy chọn',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildOpponentSelection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // NEW: Date/Time/Location Selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDatePicker(),
                          const SizedBox(height: 16),
                          _buildTimePicker(),
                          const SizedBox(height: 16),
                          _buildLocationPicker(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Enhanced SPA Bonus Selection (only for 'thach_dau')
                    if (widget.challengeType == 'thach_dau')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildSpaBonusSection(),
                      ),
                    if (widget.challengeType == 'thach_dau')
                      const SizedBox(height: 16),

                    // Enhanced Game Type and Race-to Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildGameTypeSection(),
                    ),
                    const SizedBox(height: 16),

                    // Rank Limit Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildRankLimitSection(),
                    ),
                    const SizedBox(height: 16),

                    // Enhanced Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E88E5).withValues(alpha: 0.05),
                            const Color(0xFF1976D2).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: _buildInfoSection(),
                    ),
                    const SizedBox(height: 16),

                    // Enhanced Notes Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildNotesSection(),
                    ),
                    const SizedBox(height: 100), // Space for button
                  ],
                ),
              ),
            ),
          ),

          // Enhanced Create button with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isCreating
                      ? [Colors.grey.shade400, Colors.grey.shade500]
                      : [const Color(0xFF1E88E5), const Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Semantics(
                label: 'Gửi thách đấu SPA',
                hint: _isCreating ? 'Đang xử lý, vui lòng chờ' : 'Nhấn để gửi thách đấu',
                enabled: !_isCreating,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18), // Increased for better touch target
                  ),
                  child: _isCreating
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Đang tạo...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Gửi thách đấu SPA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build notes section
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.note, color: Color(0xFF1E88E5), size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ghi chú thách đấu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _selectedOpponent == null
                  ? 'Thêm lời nhắn cho thách đấu mở...'
                  : 'Thêm lời nhắn cho ${_selectedOpponent!.displayName}...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGameTypeCard(
    String gameType,
    String ballNumber,
    Color ballColor,
    String description,
  ) {
    bool isSelected = _selectedGameType == gameType;

    return Expanded(
      child: Semantics(
        label: '$gameType, $description',
        hint: isSelected ? 'Đã chọn' : 'Nhấn để chọn loại game',
        selected: isSelected,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedGameType = gameType;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1E88E5).withValues(alpha: 0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1E88E5)
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                // Ball icon
                Container(
                  width: 36, // Increased from 32 for better touch target
                  height: 36, // Increased from 32 for better touch target
                  decoration: BoxDecoration(
                    color: ballColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      ballNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16, // Increased from 14 for better readability
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  gameType,
                  style: TextStyle(
                    fontSize: 14, // Increased from 13 for better readability
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF1E88E5) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11, // Increased from 10 for better readability
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

