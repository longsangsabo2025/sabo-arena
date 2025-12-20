import 'package:flutter/material.dart';
import '../../services/match_management_service.dart';
import '../../services/club_permission_service.dart';
import '../user_profile_screen/widgets/score_input_dialog.dart';
import '../user_profile_screen/widgets/match_card_widget.dart';
// ELON_MODE_AUTO_FIX

/// 🎯 CLUB MATCH MANAGEMENT SCREEN
/// Screen for club owners to manage matches at their club
/// Features:
/// - View matches by status (Pending/In Progress/Completed)
/// - Start matches
/// - Update scores
/// - Complete matches
/// - View match details

class ClubMatchManagementScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const ClubMatchManagementScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubMatchManagementScreen> createState() =>
      _ClubMatchManagementScreenState();
}

class _ClubMatchManagementScreenState extends State<ClubMatchManagementScreen>
    with SingleTickerProviderStateMixin {
  final _matchService = MatchManagementService();
  late TabController _tabController;

  bool _isLoading = false;
  final Map<String, List<Map<String, dynamic>>> _matches = {
    'pending': [],
    'in_progress': [],
    'completed': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _matchService.unsubscribe();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);

    try {
      // Load matches for each status
      // Tab "Chờ" = accepted (đã chấp nhận, chờ bắt đầu)
      final pending = await _matchService.getClubMatches(
          clubId: widget.clubId, status: 'accepted');
      final inProgress = await _matchService.getClubMatches(
          clubId: widget.clubId, status: 'in_progress');
      final completed = await _matchService.getClubMatches(
          clubId: widget.clubId, status: 'completed');

      setState(() {
        _matches['pending'] = pending; // Key 'pending' nhưng data là 'accepted'
        _matches['in_progress'] = inProgress;
        _matches['completed'] = completed;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải trận đấu: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Future<void> _startMatch(String matchId) async {
  //   try {
  //     await _matchService.startMatch(matchId);
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('✅ Đã bắt đầu trận đấu')),
  //       );
  //     }
  //     _loadMatches();
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('❌ Lỗi: $e')),
  //       );
  //     }
  //   }
  // }

  Future<void> _showScoreDialog(Map<String, dynamic> match) async {
    // 🔐 PERMISSION CHECK: Verify user can input scores
    final canInputScore = await ClubPermissionService().canPerformAction(
      clubId: widget.clubId,
      permissionKey: 'input_score',
    );

    if (!mounted) return;

    if (!canInputScore) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Bạn không có quyền nhập tỷ số'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 🎨 Use beautiful ScoreInputDialog with ± buttons
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => ScoreInputDialog(match: match),
    );

    if (result != null) {
      try {
        await _matchService.updateMatchScore(
          matchId: match['id'],
          player1Score: result['player1Score']!,
          player2Score: result['player2Score']!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Đã cập nhật tỷ số')),
          );
        }
        _loadMatches();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Lỗi: $e')),
          );
        }
      }
    } else {}
  }

  // Future<void> _completeMatch(Map<String, dynamic> match) async {
  //   final player1Score = match['player1_score'] ?? 0;
  //   final player2Score = match['player2_score'] ?? 0;
  //
  //   if (player1Score == player2Score) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('⚠️ Tỷ số hòa, vui lòng cập nhật tỷ số')),
  //     );
  //     return;
  //   }
  //
  //   final winnerId = player1Score > player2Score
  //       ? match['player1_id']
  //       : match['player2_id'];
  //
  //   final winnerName = player1Score > player2Score
  //       ? (match['player1']?['full_name'] ?? 'Player 1')
  //       : (match['player2']?['full_name'] ?? 'Player 2');
  //
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Kết thúc trận đấu'),
  //       content: Text('Xác nhận người thắng: $winnerName?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Hủy'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.green,
  //           ),
  //           child: const Text('Xác nhận'),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   if (confirmed == true) {
  //     try {
  //       await _matchService.completeMatch(
  //         matchId: match['id'],
  //         winnerId: winnerId,
  //         finalPlayer1Score: player1Score,
  //         finalPlayer2Score: player2Score,
  //       );
  //
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('✅ Đã kết thúc trận đấu')),
  //         );
  //       }
  //       _loadMatches();
  //     } catch (e) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('❌ Lỗi: $e')),
  //         );
  //       }
  //     }
  //   }
  // }

  // Future<void> _toggleLiveStream(Map<String, dynamic> match) async {
  //   final isLive = match['is_live'] == true;
  //
  //   if (isLive) {
  //     // Disable live stream
  //     try {
  //       await _matchService.disableLiveStream(match['id']);
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('✅ Đã tắt phát trực tiếp')),
  //         );
  //       }
  //       _loadMatches();
  //     } catch (e) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('❌ Lỗi: $e')),
  //         );
  //       }
  //     }
  //   } else {
  //     // Enable live stream - show dialog to input video URL
  //     final videoUrlController = TextEditingController();
  //
  //     final result = await showDialog<bool>(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: const Text('Bật phát trực tiếp'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Text(
  //               'Nhập link video trực tiếp (YouTube Live, Facebook Live):',
  //               style: TextStyle(fontSize: 14),
  //             ),
  //             const SizedBox(height: 16),
  //             TextField(
  //               controller: videoUrlController,
  //               keyboardType: TextInputType.url,
  //               decoration: const InputDecoration(
  //                 labelText: 'Video URL',
  //                 hintText: 'https://youtube.com/watch?v=...',
  //                 border: OutlineInputBorder(),
  //                 prefixIcon: Icon(Icons.link),
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: const Text('Hủy'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () => Navigator.pop(context, true),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.orange,
  //             ),
  //             child: const Text('Bật phát trực tiếp'),
  //           ),
  //         ],
  //       ),
  //     );
  //
  //     if (result == true) {
  //       final videoUrl = videoUrlController.text.trim();
  //       if (videoUrl.isEmpty) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('⚠️ Vui lòng nhập link video')),
  //         );
  //         return;
  //       }
  //
  //       try {
  //         await _matchService.enableLiveStream(
  //           matchId: match['id'],
  //           videoUrl: videoUrl,
  //         );
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('✅ Đã bật phát trực tiếp')),
  //           );
  //         }
  //         _loadMatches();
  //       } catch (e) {
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text('❌ Lỗi: $e')),
  //           );
  //         }
  //       }
  //     }
  //   }
  // }

  /// Convert challenge data from DB format to MatchCardWidget format
  Map<String, dynamic> _convertMatchForCard(Map<String, dynamic> challenge) {
    // Challenges use challenger/challenged instead of player1/player2
    final player1 = challenge['challenger'] ?? {};
    final player2 = challenge['challenged'] ?? {};

    final player1Rank = player1['rank'] as String?; // NULL = chưa xác minh
    final player2Rank = player2['rank'] as String?; // NULL = chưa xác minh

    // Get player names with fallback: full_name → display_name → 'Player X'
    final player1Name =
        player1['full_name'] ?? player1['display_name'] ?? 'Player 1';
    final player2Name =
        player2['full_name'] ?? player2['display_name'] ?? 'Player 2';

    return {
      'id': challenge['id'],
      'clubId':
          challenge['location'] ?? widget.clubId, // location stores club info
      'player1Id': player1['id'],
      'player2Id': player2['id'],
      'player1Name': player1Name,
      'player1Rank': player1Rank,
      'player1Avatar': player1['avatar_url'],
      'player1Online': player1['is_online'] ?? false,
      'player2Name': player2Name,
      'player2Rank': player2Rank,
      'player2Avatar': player2['avatar_url'],
      'player2Online': player2['is_online'] ?? false,
      'clubName': widget.clubName,
      'status': _mapStatus(challenge['status']),
      'matchType': _mapMatchType(
          challenge['challenge_type']), // challenge_type not match_type
      'score1': challenge['player1_score']?.toString() ?? '0',
      'score2': challenge['player2_score']?.toString() ?? '0',
      'date': _formatDate(challenge['created_at']),
      'time': _formatTime(challenge['created_at']),
      'prize': _formatPrize(challenge),
      'raceInfo':
          'Race to ${challenge['race_to'] ?? 7}', // race_to is direct column
      'handicap': _calculateHandicap(player1Rank, player2Rank),
      'winnerId': challenge['winner_id'],

      // ✅ Add original challenge data for dialog
      'challenger': player1,
      'challenged': player2,
    };
  }

  /// Calculate handicap based on rank difference
  String _calculateHandicap(String? rank1, String? rank2) {
    // If either player is unverified (rank = NULL), cannot calculate handicap
    if (rank1 == null || rank2 == null) {
      return 'Chưa xác định';
    }

    // SABO rank order: C > D > E > F > G+ > G > H+ > H > I+ > I > K+ > K
    // MIGRATED 2025: Removed K+ and I+ - Updated rank values for 10-rank system
    const rankValues = {
      'C': 10, // Vô địch (1900+ ELO)
      'D': 9, // Huyền thoại (1900-1999 ELO)
      'E': 8, // Cao thủ (1800-1899 ELO)
      'F+': 7, // Chuyên gia+ (1700-1799 ELO)
      'F': 6, // Chuyên gia (1600-1699 ELO)
      'G+': 5, // Thợ cả (1500-1599 ELO)
      'G': 4, // Thợ giỏi (1400-1499 ELO)
      'H+': 3, // Thợ chính (1300-1399 ELO)
      'H': 2, // Thợ 1 (1200-1299 ELO)
      'I': 1, // Thợ 3 (1100-1199 ELO)
      'K': 0, // Người mới (1000-1099 ELO)
    };

    final value1 = rankValues[rank1.toUpperCase()] ?? 0;
    final value2 = rankValues[rank2.toUpperCase()] ?? 0;
    final diff = (value1 - value2).abs();

    if (diff == 0) {
      return 'Không cược';
    } else if (diff == 1) {
      return 'Handicap 0.5 ván';
    } else if (diff == 2) {
      return 'Handicap 1 ván';
    } else if (diff == 3) {
      return 'Handicap 1.5 ván';
    } else {
      return 'Handicap 2 ván';
    }
  }

  String _mapStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'ready';
      case 'in_progress':
        return 'live';
      case 'completed':
        return 'done';
      default:
        return 'ready';
    }
  }

  String _mapMatchType(String? type) {
    switch (type) {
      case 'thach_dau':
        return 'Thách đấu';
      case 'giao_luu':
        return 'Giao lưu';
      default:
        return 'Giao lưu';
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'Hôm nay';
    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      if (date.day == now.day && date.month == now.month) {
        return 'Hôm nay';
      }
      return 'T${date.weekday} - ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Hôm nay';
    }
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '--:--';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }

  String _formatPrize(Map<String, dynamic> match) {
    final stakesType = match['stakes_type'];
    final amount = match['spa_stakes_amount'] ?? 0;

    if (stakesType == 'spa_points' && amount > 0) {
      return '$amount SPA';
    }
    return 'Không cược';
  }

  Widget _buildMatchList(String status) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final matches = _matches[status] ?? [];

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_tennis, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có trận đấu nào',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final originalMatch = matches[index];
          final convertedMatch = _convertMatchForCard(originalMatch);

          // 🎨 Use beautiful MatchCardWidget
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            child: MatchCardWidget(
              matchMap: convertedMatch,
              onInputScore: () => _showScoreDialog(originalMatch),
              onTap: () {
                // TODO: Navigate to match detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Chi tiết trận đấu - Coming soon!')),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quản lý trận đấu'),
            Text(
              widget.clubName,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chờ'),
            Tab(text: 'Đang chơi'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMatches,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatchList('pending'),
          _buildMatchList('in_progress'),
          _buildMatchList('completed'),
        ],
      ),
    );
  }
}
