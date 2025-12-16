import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../../services/simple_challenge_service.dart';
import '../../../services/opponent_club_service.dart';
import '../../../services/club_spa_service.dart';
import '../../../services/user_service.dart';
import '../../../services/challenge_rules_service.dart';
import '../../../models/user_profile.dart';
import '../../../models/club.dart';
import 'user_search_dialog.dart';

/// Modern iOS Facebook-style Challenge Modal
class ModernChallengeModal extends StatefulWidget {
  final Map<String, dynamic> player;
  final String challengeType; // 'thach_dau' or 'giao_luu'
  final VoidCallback? onSendChallenge;
  final List<UserProfile>?
  availableFriends; // For private mode friend selection

  const ModernChallengeModal({
    super.key,
    required this.player,
    required this.challengeType,
    this.onSendChallenge,
    this.availableFriends,
  });

  @override
  State<ModernChallengeModal> createState() => _ModernChallengeModalState();
}

class _ModernChallengeModalState extends State<ModernChallengeModal> {
  String _selectedGameType = '8-ball';
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedLocation = '';
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  List<String> _locations = [];
  
  // ✅ NEW: Club selection (REQUIRED for challenges)
  List<Club> _clubs = [];
  Club? _selectedClub;

  // NEW: Open/Private mode
  bool _isOpenMode = true; // true = Open (default), false = Private
  String? _selectedFriendId;
  String? _selectedFriendName;

  // NEW: SPA Betting Configuration
  static const Map<int, int> _spaBettingConfig = {
    0: 0, // No betting
    100: 8, // 100 SPA → Race to 8
    200: 12, // 200 SPA → Race to 12
    300: 14, // 300 SPA → Race to 14
    400: 16, // 400 SPA → Race to 16
    500: 18, // 500 SPA → Race to 18
    600: 22, // 600 SPA → Race to 22
  };

  int _selectedSpaBonus = 0; // Default: No betting
  int _selectedRaceTo = 0; // Auto-determined from SPA

  final List<String> _gameTypes = ['8-ball', '9-ball', '10-ball'];

  // Services
  final ClubSpaService _clubSpaService = ClubSpaService();
  final UserService _userService = UserService.instance;

  // Check if this modal is opened for a specific opponent (from card)
  bool get _isTargetedChallenge => widget.player['id'] != null && widget.player['id'].toString().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadLocations();

    // If player is provided, auto-select them for private mode and LOCK it
    if (_isTargetedChallenge) {
      _selectedFriendId = widget.player['id'];
      _selectedFriendName =
          widget.player['fullName'] ?? 
          widget.player['display_name'] ?? 
          widget.player['username'] ?? 
          'Đối thủ';
      _isOpenMode = false; // LOCKED to private mode
    }
  }

  Future<void> _loadLocations() async {
    try {
      // ✅ Load clubs as objects (not just names)
      final clubs = await OpponentClubService.instance.getActiveClubs();
      
      if (mounted) {
        setState(() {
          _clubs = clubs;
          // ✅ Auto-select first club if available
          _selectedClub = clubs.isNotEmpty ? clubs.first : null;
          _selectedLocation = _selectedClub?.name ?? 'CLB SABO ARENA';
          
          // Keep old location list for backward compatibility
          _locations = clubs.map((club) => club.name).toList();
          _locations.add('Khác (ghi chú)');
        });
      }
    } catch (error) {
      final fallbackLocations = [
        'SABO Arena Central',
        'SABO Arena East',
        'SABO Arena West',
        'Khác (ghi chú)',
      ];

      if (mounted) {
        setState(() {
          _locations = fallbackLocations;
          _selectedLocation = fallbackLocations.first;
          _selectedClub = null; // No club loaded
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCED0D4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                Text(
                  widget.challengeType == 'thach_dau'
                      ? 'Gửi Thách Đấu'
                      : 'Gửi Lời Mời',
                  style: TextStyle(
                    fontFamily: _getSystemFont(),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF050505),
                    letterSpacing: -0.4,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    size: 24,
                    color: Color(0xFF65676B),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Player Info Card - Show target opponent clearly
                  _buildPlayerInfoCard(),
                  const SizedBox(height: 16),

                  // Mode Selector (Open/Private) - ONLY show if NOT targeted challenge
                  if (!_isTargetedChallenge) ...[
                    _buildSectionTitle('Chế độ'),
                    const SizedBox(height: 8),
                    _buildModeSelector(),
                    const SizedBox(height: 16),
                  ],

                  // ✅ ALWAYS show opponent selector (not just in private mode)
                  if (!_isTargetedChallenge) ...[
                    _buildSectionTitle('Chọn đối thủ'),
                    const SizedBox(height: 8),
                    _buildQuickOpponentSelector(), // Quick search button - ALWAYS visible
                    const SizedBox(height: 16),
                  ],

                  // Game Type
                  _buildSectionTitle('Loại game'),
                  const SizedBox(height: 8),
                  _buildGameTypeSelector(),
                  const SizedBox(height: 16),

                  // Date & Time
                  _buildSectionTitle('Thời gian'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildDatePicker()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTimePicker()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location
                  _buildSectionTitle('Địa điểm'),
                  const SizedBox(height: 8),
                  _buildLocationSelector(),
                  const SizedBox(height: 16),

                  // SPA Betting (for thach_dau only)
                  if (widget.challengeType == 'thach_dau') ...[
                    _buildSectionTitle('SPA Betting'),
                    const SizedBox(height: 8),
                    _buildSpaBettingSection(),
                    const SizedBox(height: 16),
                  ],

                  // Message
                  _buildSectionTitle('Lời nhắn (Tùy chọn)'),
                  const SizedBox(height: 8),
                  _buildMessageInput(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfoCard() {
    // If targeted challenge, show clearly who we're challenging
    if (_isTargetedChallenge) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.challengeType == 'thach_dau' 
                ? const Color(0xFFFF9800).withValues(alpha: 0.1)
                : const Color(0xFF0866FF).withValues(alpha: 0.1),
              widget.challengeType == 'thach_dau'
                ? const Color(0xFFFF9800).withValues(alpha: 0.05)
                : const Color(0xFF0866FF).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.challengeType == 'thach_dau'
              ? const Color(0xFFFF9800).withValues(alpha: 0.3)
              : const Color(0xFF0866FF).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Gửi thách đấu đến"
            Row(
              children: [
                Icon(
                  widget.challengeType == 'thach_dau' 
                    ? Icons.emoji_events 
                    : Icons.groups,
                  size: 18,
                  color: widget.challengeType == 'thach_dau'
                    ? const Color(0xFFFF9800)
                    : const Color(0xFF0866FF),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.challengeType == 'thach_dau' 
                    ? 'Gửi thách đấu đến:'
                    : 'Gửi lời mời giao lưu đến:',
                  style: TextStyle(
                    fontFamily: _getSystemFont(),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF65676B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Opponent Info
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0866FF),
                  ),
                  child: Center(
                    child: Text(
                      (widget.player['display_name']?.toString() ?? 
                       widget.player['fullName']?.toString() ?? 
                       'S')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
                        fontFamily: _getSystemFont(),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.player['display_name']?.toString() ?? 
                        widget.player['fullName']?.toString() ?? 
                        'Unknown',
                        style: TextStyle(
                          fontFamily: _getSystemFont(),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF050505),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (widget.player['rank'] != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0866FF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.player['rank'].toString(),
                                style: TextStyle(
                                  fontFamily: _getSystemFont(),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0866FF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (widget.player['elo_rating'] != null)
                            Text(
                              '⭐ ELO: ${widget.player['elo_rating']}',
                              style: TextStyle(
                                fontFamily: _getSystemFont(),
                                fontSize: 12,
                                color: const Color(0xFF65676B),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    // Original card for open challenges
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0866FF),
            ),
            child: Center(
              child: Text(
                widget.player['fullName']
                        ?.toString()
                        .substring(0, 1)
                        .toUpperCase() ??
                    'S',
                style: TextStyle(
                  fontFamily: _getSystemFont(),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.player['fullName']?.toString() ?? 'Unknown',
                  style: TextStyle(
                    fontFamily: _getSystemFont(),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF050505),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.player['club']?.toString() ?? 'CLB SABO',
                  style: TextStyle(
                    fontFamily: _getSystemFont(),
                    fontSize: 13,
                    color: const Color(0xFF65676B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: _getSystemFont(),
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF050505),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildGameTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCED0D4), width: 1),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedGameType,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        items: _gameTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(
              type,
              style: TextStyle(
                fontFamily: _getSystemFont(),
                fontSize: 15,
                color: const Color(0xFF050505),
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedGameType = value);
          }
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCED0D4), width: 1),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 18,
              color: Color(0xFF65676B),
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: TextStyle(
                fontFamily: _getSystemFont(),
                fontSize: 15,
                color: const Color(0xFF050505),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCED0D4), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: Color(0xFF65676B)),
            const SizedBox(width: 8),
            Text(
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontFamily: _getSystemFont(),
                fontSize: 15,
                color: const Color(0xFF050505),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    // ✅ NEW: Build club dropdown instead of location strings
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedClub == null 
            ? Colors.red.withValues(alpha: 0.5)  // ❌ Highlight if not selected
            : const Color(0xFFCED0D4),
          width: _selectedClub == null ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<Club>(
            initialValue: _selectedClub,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              // ✅ Show error hint if no club selected
              helperText: _selectedClub == null ? '⚠️ Bắt buộc chọn CLB' : null,
              helperStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            hint: Text(
              '⚠️ Chọn CLB (Bắt buộc)',
              style: TextStyle(
                fontFamily: _getSystemFont(),
                fontSize: 15,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            items: _clubs.map((club) {
              return DropdownMenuItem<Club>(
                value: club,
                child: Row(
                  children: [
                    // Club logo
                    if (club.logoUrl != null)
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          image: DecorationImage(
                            image: NetworkImage(club.logoUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00695C).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.sports_tennis,
                          size: 18,
                          color: Color(0xFF00695C),
                        ),
                      ),
                    
                    // Club info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            club.name,
                            style: TextStyle(
                              fontFamily: _getSystemFont(),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF050505),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (club.address != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '📍 ${club.address}',
                              style: TextStyle(
                                fontFamily: _getSystemFont(),
                                fontSize: 11,
                                color: const Color(0xFF65676B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (club) {
              if (club != null) {
                setState(() {
                  _selectedClub = club;
                  _selectedLocation = club.name; // Keep for backward compat
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpaBettingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monetization_on,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn mức cược SPA',
                      style: TextStyle(
                        fontFamily: _getSystemFont(),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF050505),
                      ),
                    ),
                    Text(
                      'SPA cao hơn → Race-to dài hơn',
                      style: TextStyle(
                        fontFamily: _getSystemFont(),
                        fontSize: 12,
                        color: const Color(0xFF65676B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SPA Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _spaBettingConfig.keys.map((amount) {
              final isSelected = _selectedSpaBonus == amount;
              final raceTo = _spaBettingConfig[amount]!;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedSpaBonus = amount;
                  _selectedRaceTo = raceTo;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF9800)
                          : const Color(0xFFCED0D4),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
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
                        amount == 0 ? 'Không cược' : '$amount SPA',
                        style: TextStyle(
                          fontFamily: _getSystemFont(),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF050505),
                        ),
                      ),
                      if (raceTo > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Race to $raceTo',
                          style: TextStyle(
                            fontFamily: _getSystemFont(),
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF65676B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Info message
          if (_selectedSpaBonus > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cược $_selectedSpaBonus SPA - Race to $_selectedRaceTo',
                      style: TextStyle(
                        fontFamily: _getSystemFont(),
                        fontSize: 12,
                        color: const Color(0xFF050505),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCED0D4), width: 1),
      ),
      child: TextField(
        controller: _messageController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Thêm lời nhắn...',
          hintStyle: TextStyle(
            fontFamily: _getSystemFont(),
            fontSize: 15,
            color: const Color(0xFF65676B),
          ),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontFamily: _getSystemFont(),
          fontSize: 15,
          color: const Color(0xFF050505),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Hủy',
                style: TextStyle(
                  fontFamily: _getSystemFont(),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF050505),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Send Button
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0866FF), Color(0xFF0952CC)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0866FF).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton(
              onPressed: _isLoading ? null : _handleSendChallenge,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Gửi',
                      style: TextStyle(
                        fontFamily: _getSystemFont(),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSendChallenge() async {
    // ✅ VALIDATION: Bắt buộc phải chọn CLB
    if (_selectedClub == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Vui lòng chọn CLB để tổ chức trận đấu',
            style: TextStyle(fontFamily: _getSystemFont()),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return; // ❌ Stop here if no club selected
    }

    // ✅ VALIDATION: Check rank eligibility (only for specific opponent challenges)
    if (!_isOpenMode) {
      final currentUser = await _userService.getCurrentUserProfile();
      final currentUserRank = currentUser?.rank;
      final opponentRank = widget.player['rank'] as String?;
      
      if (currentUserRank != null && opponentRank != null) {
        final rulesService = ChallengeRulesService.instance;
        if (!rulesService.canChallenge(currentUserRank, opponentRank)) {
          final eligibleRanks = rulesService.getEligibleRanks(currentUserRank);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ Không thể thách đấu!\n'
                  'Hạng của bạn ($currentUserRank) không thể thách đấu với hạng $opponentRank.\n'
                  'Bạn chỉ có thể thách đấu với: ${eligibleRanks.join(", ")}',
                  style: TextStyle(fontFamily: _getSystemFont()),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      // 1. Check club balance if SPA betting is selected
      if (_selectedSpaBonus > 0) {
        final currentUser = await _userService.getCurrentUserProfile();
        if (currentUser == null) {
          throw Exception('Không thể lấy thông tin người dùng');
        }

        // ✅ Use selected club ID instead of default
        final clubBalance = await _clubSpaService.getClubSpaBalance(
          _selectedClub!.id,
        );
        if (clubBalance != null) {
          final availableSpa = clubBalance['available_spa'] ?? 0.0;
          if (availableSpa < _selectedSpaBonus) {
            throw Exception(
              'Club không đủ SPA!\nCó: ${availableSpa.toInt()} SPA\nCần: $_selectedSpaBonus SPA',
            );
          }
        }
      }

      // 2. Prepare scheduled date time
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // 3. Determine challenged user ID based on mode
      final challengedUserId = _isOpenMode
          ? '' // Empty = OPEN challenge
          : (_selectedFriendId ??
                widget.player['id'] ??
                ''); // Use selected friend or widget player ID

      // 4. Send challenge with club ID
      await SimpleChallengeService.instance.sendChallenge(
        challengedUserId: challengedUserId,
        challengeType: widget.challengeType,
        gameType: _selectedGameType,
        scheduledTime: scheduledDateTime,
        location: _selectedLocation,
        clubId: _selectedClub!.id, // ✅ Pass club ID
        spaPoints: _selectedSpaBonus,
        message: _messageController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSendChallenge?.call();

        // Success message with SPA info
        final message = _selectedSpaBonus > 0
            ? '✅ Đã gửi ${widget.challengeType == 'thach_dau' ? 'thách đấu' : 'lời mời'} với $_selectedSpaBonus SPA!'
            : '✅ Đã gửi ${widget.challengeType == 'thach_dau' ? 'thách đấu' : 'lời mời'}!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: TextStyle(fontFamily: _getSystemFont()),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Lỗi: $e',
              style: TextStyle(fontFamily: _getSystemFont()),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isOpenMode = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isOpenMode ? const Color(0xFF0866FF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOpenMode
                      ? const Color(0xFF0866FF)
                      : const Color(0xFFCED0D4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.public,
                    size: 20,
                    color: _isOpenMode ? Colors.white : const Color(0xFF65676B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mở',
                    style: TextStyle(
                      fontFamily: _getSystemFont(),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _isOpenMode
                          ? Colors.white
                          : const Color(0xFF050505),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isOpenMode = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !_isOpenMode ? const Color(0xFF0866FF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_isOpenMode
                      ? const Color(0xFF0866FF)
                      : const Color(0xFFCED0D4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_person,
                    size: 20,
                    color: !_isOpenMode
                        ? Colors.white
                        : const Color(0xFF65676B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chọn đối thủ',
                    style: TextStyle(
                      fontFamily: _getSystemFont(),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: !_isOpenMode
                          ? Colors.white
                          : const Color(0xFF050505),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ NEW: Quick opponent selector - Simple button that opens search immediately
  Widget _buildQuickOpponentSelector() {
    return Column(
      children: [
        // If opponent already selected, show their info
        if (_selectedFriendId != null && _selectedFriendName != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: Colors.purple.shade700, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFriendName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đối thủ đã chọn',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  onPressed: () {
                    setState(() {
                      _selectedFriendId = null;
                      _selectedFriendName = null;
                    });
                  },
                ),
              ],
            ),
          )
        else
          // Search button when no opponent selected
          GestureDetector(
            onTap: () async {
              // Get current user first
              final currentUser = await _userService.getCurrentUserProfile();
              if (!mounted) return;

              // Open search dialog
              final selectedUser = await showDialog<UserProfile>(
                context: context,
                builder: (context) => UserSearchDialog(
                  currentUser: currentUser,
                  excludeUserIds: widget.availableFriends
                      ?.map((f) => f.id)
                      .toList() ??
                      [],
                ),
              );

              // Update selection if user chose someone
              if (selectedUser != null && mounted) {
                setState(() {
                  _selectedFriendId = selectedUser.id;
                  _selectedFriendName = selectedUser.displayName;
                  _isOpenMode = false; // Auto-switch to private mode
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_search, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Tìm đối thủ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Additional option: Show friend list button
        if (_selectedFriendId == null && 
            widget.availableFriends != null && 
            widget.availableFriends!.isNotEmpty) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showFriendListDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, color: Colors.purple.shade600, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Chọn từ danh sách bạn bè',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Show friend list in a bottom sheet
  void _showFriendListDialog() async {
    // Show friend selection bottom sheet
    final selected = await showModalBottomSheet<UserProfile>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCED0D4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chọn từ danh sách bạn bè',
                    style: TextStyle(
                      fontFamily: _getSystemFont(),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF050505),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: const Color(0xFF65676B),
                  ),
                ],
              ),
            ),

            // Friends list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.availableFriends!.length,
                itemBuilder: (context, index) {
                  final friend = widget.availableFriends![index];
                  
                  return ListTile(
                    onTap: () => Navigator.pop(context, friend),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0866FF),
                      ),
                      child: Center(
                        child: Text(
                          friend.displayName[0].toUpperCase(),
                          style: TextStyle(
                            fontFamily: _getSystemFont(),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      friend.displayName,
                      style: TextStyle(
                        fontFamily: _getSystemFont(),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF050505),
                      ),
                    ),
                    subtitle: Text(
                      'Hạng: ${friend.rank ?? 'N/A'}',
                      style: TextStyle(
                        fontFamily: _getSystemFont(),
                        fontSize: 13,
                        color: const Color(0xFF65676B),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF65676B),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    // Update selection if user chose someone
    if (selected != null && mounted) {
      setState(() {
        _selectedFriendId = selected.id;
        _selectedFriendName = selected.displayName;
        _isOpenMode = false; // Auto-switch to private mode
      });
    }
  }

  String _getSystemFont() {
    try {
      if (Platform.isIOS) {
        return '.SF Pro Display';
      } else {
        return 'Roboto';
      }
    } catch (e) {
      return 'Roboto';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
