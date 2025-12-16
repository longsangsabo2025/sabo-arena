import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/user/user_avatar_widget.dart';
import '../../../models/user_profile.dart';
import '../../../services/simple_challenge_service.dart';
import '../../../services/opponent_club_service.dart';
import '../../../core/constants/ranking_constants.dart';
import 'user_search_dialog.dart';

class CreateSocialChallengeModal extends StatefulWidget {
  final UserProfile? currentUser;
  final List<UserProfile> opponents;

  const CreateSocialChallengeModal({
    super.key,
    this.currentUser,
    required this.opponents,
  });

  @override
  State<CreateSocialChallengeModal> createState() =>
      _CreateSocialChallengeModalState();
}

class _CreateSocialChallengeModalState
    extends State<CreateSocialChallengeModal> {
  final SimpleChallengeService _challengeService =
      SimpleChallengeService.instance;
  final OpponentClubService _clubService = OpponentClubService.instance;

  UserProfile? _selectedOpponent;
  String _selectedGameType = '8-ball';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 2));
  String _selectedLocation = '';
  String? _selectedClubId; // ← THÊM: Lưu club ID
  String? _rankMin; // Rank minimum
  String? _rankMax; // Rank maximum
  final TextEditingController _noteController = TextEditingController();
  bool _isCreating = false;

  final List<String> _gameTypes = ['8-ball', '9-ball', '10-ball'];
  List<String> _commonLocations = ['Đang tải...'];
  Map<String, String> _clubNameToId = {}; // ← THÊM: Map tên club -> ID

  // Rank tiers from RankingConstants
  final List<String> _rankTiers = RankingConstants.RANK_ORDER;

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadClubData() async {
    try {
      final clubs = await _clubService.getActiveClubs();
      if (mounted) {
        setState(() {
          _commonLocations = clubs.map((club) => club.name).toList();
          _commonLocations.add('Khác (tự nhập)');

          // Build map: club name -> club ID
          _clubNameToId = {
            for (var club in clubs) club.name: club.id
          };

          // Set default location to first club if available
          if (_commonLocations.isNotEmpty &&
              _commonLocations.first != 'Khác (tự nhập)') {
            _selectedLocation = _commonLocations.first;
            _selectedClubId = _clubNameToId[_selectedLocation]; // ← Lưu club ID
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commonLocations = [
            'SABO Arena Central',
            'Golden Billiards Club',
            'VIP Billiards',
            'Champion Club',
            'Thống Nhất Billiards',
            'Khác (tự nhập)',
          ];
          _selectedLocation = _commonLocations.first;
          _selectedClubId = null; // ← Không có club ID cho fallback data
        });
      }
    }
  }

  Future<void> _createSocialChallenge() async {
    if (_isCreating) return;

    setState(() => _isCreating = true);

    try {
      // For open social challenge, use empty challenged_id
      final challengedId = _selectedOpponent?.id ?? '';

      final result = await _challengeService.sendChallenge(
        challengedUserId: challengedId,
        challengeType: 'giao_luu',
        gameType: _selectedGameType,
        scheduledTime: _selectedDateTime,
        location: _selectedLocation.isEmpty
            ? 'Chưa xác định'
            : _selectedLocation,
        clubId: _selectedClubId, // ← THÊM: Gửi club ID
        spaPoints: 0, // No SPA points for social challenges
        message: _noteController.text.trim().isEmpty
            ? (_selectedOpponent == null
                  ? 'Giao lưu mở - Ai cũng có thể tham gia!'
                  : 'Mời giao lưu')
            : _noteController.text.trim(),
      );

      if (result != null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selectedOpponent == null
                    ? 'Đã tạo giao lưu mở thành công!'
                    : 'Đã gửi lời mời giao lưu!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tạo giao lưu. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
          // Enhanced Header with gradient background (Purple theme for social)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(
                    0xFF7B1FA2,
                  ).withValues(alpha: 0.95), // Purple for social
                  const Color(0xFF6A1B9A).withValues(alpha: 0.95), // Dark purple
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
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tạo Giao Lưu',
                    style: TextStyle(
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
                                    0xFF7B1FA2,
                                  ).withValues(alpha: 0.1), // Purple
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.people,
                                  color: Color(0xFF7B1FA2), // Purple
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

                    // Enhanced Game Type Selection
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

                    // Enhanced Date & Time Selection
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
                      child: _buildDateTimeSection(),
                    ),
                    const SizedBox(height: 16),

                    // Enhanced Location Selection
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
                      child: _buildLocationSection(),
                    ),
                    const SizedBox(height: 16),

                    // Rank Min/Max Selection
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
                      child: _buildRankSection(),
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
                    const SizedBox(height: 20),

                    // Enhanced Summary Card (Purple theme)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7B1FA2).withValues(alpha: 0.05), // Purple
                            const Color(
                              0xFF6A1B9A,
                            ).withValues(alpha: 0.05), // Dark purple
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFF7B1FA2,
                          ).withValues(alpha: 0.2), // Purple
                          width: 1,
                        ),
                      ),
                      child: _buildSummaryInfo(),
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
                      : [
                          const Color(0xFF7B1FA2), // Purple for social
                          const Color(0xFF6A1B9A), // Dark purple
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF7B1FA2,
                    ).withValues(alpha: 0.3), // Purple shadow
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createSocialChallenge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                    : Text(
                        _selectedOpponent == null
                            ? 'Tạo Giao Lưu Mở'
                            : 'Gửi Lời Mời',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Open challenge info với thiết kế mới
        if (widget.opponents.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7B1FA2).withValues(alpha: 0.05),
                  const Color(0xFF6A1B9A).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF7B1FA2),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Chưa có đối thủ cụ thể. Bạn có thể tạo giao lưu mở cho mọi người tham gia.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7B1FA2),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Opponent selection list với thiết kế mới
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.opponents.length + 2, // +2: "Giao lưu mở" + "Tìm đối thủ"
            itemBuilder: (context, index) {
              // First item: "Giao lưu mở"
              if (index == 0) {
                final isSelected = _selectedOpponent == null;
                return GestureDetector(
                  onTap: () => setState(() => _selectedOpponent = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 110,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF7B1FA2).withValues(alpha: 0.15),
                                const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade100.withValues(alpha: 0.5),
                                Colors.grey.shade200.withValues(alpha: 0.3),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF7B1FA2)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
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
                              colors: isSelected
                                  ? [
                                      const Color(0xFF7B1FA2),
                                      const Color(0xFF6A1B9A),
                                    ]
                                  : [
                                      Colors.grey.shade400.withValues(alpha: 0.6),
                                      Colors.grey.shade500.withValues(alpha: 0.7),
                                    ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: isSelected 
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            Icons.public,
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Giao lưu mở',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF7B1FA2)
                                : Colors.grey.shade500, // Dimmed when not selected
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Ai cũng tham gia',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected 
                                ? Colors.grey.shade600 
                                : Colors.grey.shade400, // Even more dimmed when not selected
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Last item: "Tìm đối thủ" search button
              if (index == widget.opponents.length + 1) {
                return GestureDetector(
                  onTap: () async {
                    // Open search dialog
                    final selectedUser = await showDialog<UserProfile>(
                      context: context,
                      builder: (context) => UserSearchDialog(
                        currentUser: widget.currentUser!,
                        excludeUserIds: widget.opponents.map((o) => o.id).toList(),
                      ),
                    );

                    // Update selection if user chose someone
                    if (selectedUser != null && mounted) {
                      setState(() {
                        _selectedOpponent = selectedUser;
                      });
                    }
                  },
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.deepOrange.shade500,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
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
                            color: Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_search,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tìm đối thủ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          'Tìm kiếm',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
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
                onTap: () => setState(() => _selectedOpponent = opponent),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF7B1FA2).withValues(alpha: 0.15),
                              const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade100.withValues(alpha: 0.5),
                              Colors.grey.shade200.withValues(alpha: 0.3),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7B1FA2)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
                              blurRadius: 12,
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
                                ? const Color(0xFF7B1FA2)
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
                              ? const Color(0xFF7B1FA2)
                              : Colors.grey.shade500, // Dimmed when not selected
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Hạng: ${opponent.rank ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected 
                              ? Colors.grey.shade600 
                              : Colors.grey.shade400, // More dimmed when not selected
                        ),
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

  Widget _buildGameTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/icon8ball.png',
                width: 16,
                height: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Loại Game',
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
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _gameTypes.map((type) {
              final isSelected = _selectedGameType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedGameType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF7B1FA2), Color(0xFF6A1B9A)],
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
                              color: const Color(0xFF7B1FA2).withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.schedule,
                color: Color(0xFF7B1FA2),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Thời gian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDateTime,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF7B1FA2),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF7B1FA2),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                setState(() {
                  _selectedDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF7B1FA2),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn ngày & giờ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} - ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xFF7B1FA2),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Địa điểm',
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
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue:
                    _selectedLocation.isEmpty ||
                        !_commonLocations.contains(_selectedLocation)
                    ? null
                    : _selectedLocation,
                hint: const Text('Chọn địa điểm từ danh sách'),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                isExpanded: true,
                items: _commonLocations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Row(
                      children: [
                        Icon(
                          location == 'Khác (tự nhập)'
                              ? Icons.edit_location
                              : Icons.location_on,
                          size: 16,
                          color: const Color(0xFF7B1FA2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLocation = value;
                      // ← Update club ID khi chọn location
                      _selectedClubId = _clubNameToId[value];
                    });
                  }
                },
              ),
              if (_selectedLocation == 'Khác (tự nhập)') ...[
                const Divider(height: 1, thickness: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Nhập địa điểm cụ thể',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_location,
                          color: Color(0xFF7B1FA2),
                          size: 18,
                        ),
                      ),
                    ),
                    onChanged: (value) => _selectedLocation = value,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.military_tech,
                color: Color(0xFF7B1FA2),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Hạng đối thủ',
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
        Row(
          children: [
            // Rank Min
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hạng tối thiểu',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _rankMin,
                      hint: const Text('Chọn'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: _rankTiers.map((rank) {
                        final details = RankingConstants.RANK_DETAILS[rank];
                        final icon = RankingConstants.RANK_ICONS[rank];
                        return DropdownMenuItem(
                          value: rank,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon ?? Icons.star,
                                size: 14,
                                color: const Color(0xFF7B1FA2),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                rank,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (details != null) ...[
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    '(${details['name_en']})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _rankMin = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Rank Max
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hạng tối đa',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _rankMax,
                      hint: const Text('Chọn'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: _rankTiers.map((rank) {
                        final details = RankingConstants.RANK_DETAILS[rank];
                        final icon = RankingConstants.RANK_ICONS[rank];
                        return DropdownMenuItem(
                          value: rank,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon ?? Icons.star,
                                size: 14,
                                color: const Color(0xFF7B1FA2),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                rank,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (details != null) ...[
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    '(${details['name_en']})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _rankMax = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_rankMin != null || _rankMax != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7B1FA2).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: const Color(0xFF7B1FA2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chỉ đối thủ trong khoảng hạng này có thể nhận thách đấu',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.note, color: Color(0xFF7B1FA2), size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ghi chú',
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
          child: TextFormField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Thêm lời nhắn, yêu cầu đặc biệt...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF7B1FA2),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Thông tin giao lưu:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF7B1FA2),
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
            _selectedOpponent == null
                ? '• Loại: Giao lưu mở - Ai cũng có thể tham gia\n'
                      '• Game: $_selectedGameType\n'
                      '• Thời gian: ${_selectedDateTime.day}/${_selectedDateTime.month} ${_selectedDateTime.hour}:${_selectedDateTime.minute.toString().padLeft(2, '0')}\n'
                      '• Địa điểm: ${_selectedLocation.isEmpty ? 'Chưa xác định' : _selectedLocation}'
                      '${_rankMin != null || _rankMax != null ? '\n• Hạng: ${_rankMin ?? 'Tất cả'} → ${_rankMax ?? 'Tất cả'}' : ''}'
                : '• Đối thủ: ${_selectedOpponent!.displayName}\n'
                      '• Game: $_selectedGameType\n'
                      '• Thời gian: ${_selectedDateTime.day}/${_selectedDateTime.month} ${_selectedDateTime.hour}:${_selectedDateTime.minute.toString().padLeft(2, '0')}\n'
                      '• Địa điểm: ${_selectedLocation.isEmpty ? 'Chưa xác định' : _selectedLocation}'
                      '${_rankMin != null || _rankMax != null ? '\n• Hạng: ${_rankMin ?? 'Tất cả'} → ${_rankMax ?? 'Tất cả'}' : ''}',
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
}
