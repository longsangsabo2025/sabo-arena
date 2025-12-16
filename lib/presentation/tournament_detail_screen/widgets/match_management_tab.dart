import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/services/tournament_service.dart';
import 'package:sabo_arena/services/cached_tournament_service.dart';
import 'package:sabo_arena/services/universal_match_progression_service.dart';
import 'package:sabo_arena/services/unified_bracket_service.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
// REMOVED: tournament_progression_service - not needed anymore
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/widgets/common/common_widgets.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX // Phase 4

// Safe debug print wrapper to avoid null debug service errors
void _safeDebugPrint(String message) {
  try {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  } catch (e) {
    // Ignore debug service errors in production
    ProductionLogger.info(message, tag: 'match_management_tab');
  }
}

class MatchManagementTab extends StatefulWidget {
  final String tournamentId;
  final VoidCallback? onMatchScoreUpdated;

  const MatchManagementTab({
    super.key,
    required this.tournamentId,
    this.onMatchScoreUpdated,
  });

  @override
  _MatchManagementTabState createState() => _MatchManagementTabState();
}

class _MatchManagementTabState extends State<MatchManagementTab>
    with SingleTickerProviderStateMixin {
  final TournamentService _tournamentService = TournamentService.instance;

  List<Map<String, dynamic>> _matches = [];
  Map<String, dynamic>? _tournament; // Store tournament info
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // all, pending, in_progress, completed
  // 🔥 STANDARDIZED: Filter by bracket_type + stage_round instead of round_number
  String? _selectedBracketType; // null = show all, 'WB', 'LB', 'GF'
  int? _selectedStageRound; // null = show all
  String? _selectedBracketGroup; // null = show all, 'A', 'B', 'CROSS'
  int _totalParticipants = 0; // Dynamic participant count

  // 🔥 NEW: Animation controller for refresh button
  late AnimationController _refreshAnimationController;
  late Animation<double> _refreshAnimation;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _refreshAnimationController,
        curve: Curves.linear,
      ),
    );
    _loadMatches();
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  // 🔥 NEW: Get hierarchical structure for complex formats (SABO DE32/DE16)
  Map<String, dynamic> _getHierarchicalStructure() {
    // Apply status filter first
    final filteredMatches = _getFilteredMatches();

    if (filteredMatches.isEmpty) return {};

    // Detect format: Check for DE24 (uses 'round' field for groups), DE32+ (uses bracket_group)
    bool hasBracketGroups = filteredMatches.any(
      (m) => m['bracket_group'] != null,
    );
    bool isDE24Format = filteredMatches.any(
      (m) {
        final round = m['round']?.toString() ?? '';
        return round.startsWith('Group ') && 
               (round == 'Group A' || round == 'Group B' || round == 'Group C' || 
                round == 'Group D' || round == 'Group E' || round == 'Group F' ||
                round == 'Group G' || round == 'Group H');
      },
    );
    
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    if (filteredMatches.isNotEmpty) {
      final firstMatch = filteredMatches.first;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }

    Map<String, dynamic> structure = {};

    for (var match in filteredMatches) {
      final bracketGroup = match['bracket_group']; // 'A', 'B', 'Group A', 'Group B', null
      final bracketType =
          match['bracket_type'] ?? 'WB'; // 'WB', 'LB-A', 'LB-B', 'CROSS', 'GF', 'groups', 'LB', 'Finals'
      final round = match['round']?.toString() ?? ''; // For DE24: 'Group A', 'WB R1', etc.
      final stageRound = match['stage_round'] ?? match['round_number'] ?? 1;
      final displayOrder = match['display_order'] ?? 0;

      // Level 1: Bracket Group (for SABO DE32+) OR Round Group (for DE24)
      String level1Key;
      String level1Label;

      if (isDE24Format) {
        // DE24 format - extract group from 'round' field
        if (round.startsWith('Group ')) {
          final groupLetter = round.replaceFirst('Group ', '');
          level1Key = 'group_$groupLetter';
          level1Label = '📁 Group $groupLetter';
        } else if (round.contains('WB')) {
          level1Key = 'winners_bracket';
          level1Label = '🎯 Winners Bracket';
        } else if (round.contains('LB')) {
          level1Key = 'losers_bracket';
          level1Label = '🔄 Losers Bracket';
        } else if (round.contains('Finals')) {
          level1Key = 'finals';
          level1Label = '🏆 Finals';
        } else {
          level1Key = 'other';
          level1Label = '📋 Other';
        }
      } else if (hasBracketGroups) {
        // Normalize bracket_group to handle both 'A' and 'Group A' formats
        final groupStr = bracketGroup?.toString().toUpperCase() ?? '';
        final normalizedGroup = groupStr.replaceAll('GROUP ', '').trim();
        
        if (normalizedGroup == 'A' || groupStr.contains('A')) {
          level1Key = 'group_a';
          level1Label = '📁 Group A';
        } else if (normalizedGroup == 'B' || groupStr.contains('B')) {
          level1Key = 'group_b';
          level1Label = '📁 Group B';
        } else if (normalizedGroup == 'C' || groupStr.contains('C')) {
          level1Key = 'group_c';
          level1Label = '📁 Group C';
        } else if (normalizedGroup == 'D' || groupStr.contains('D')) {
          level1Key = 'group_d';
          level1Label = '📁 Group D';
        } else {
          // Cross Finals or other
          level1Key = 'cross_finals';
          level1Label = '🏆 Cross Finals';
        }
      } else {
        // Regular DE16 or SE - use bracket_type as top level
        level1Key = bracketType.toLowerCase();
        if (bracketType == 'WB') {
          level1Label = '🎯 Winner Bracket';
        } else if (bracketType == 'LB') {
          level1Label = '🔄 Loser Bracket';
        } else if (bracketType == 'GF') {
          level1Label = '🏆 Grand Final';
        } else {
          level1Label = bracketType;
        }
      }

      // Level 2: Bracket Type (for SABO) or Stage Round (for regular formats)
      String level2Key;
      String level2Label;

      if (isDE24Format) {
        // DE24 - use round as level 2 (e.g., "WB R1", "Group A")
        level2Key = round;
        level2Label = '  ├─ $round';
      } else if (hasBracketGroups) {
        // SABO format - use bracket_type as level 2
        level2Key = bracketType;
        String groupPrefix = (bracketGroup != null && bracketGroup != 'CROSS') ? '$bracketGroup-' : '';
        if (bracketType == 'WB') {
          level2Label = '  ├─ ${groupPrefix}WB (Winner Bracket)';
        } else if (bracketType == 'LB-A') {
          level2Label = '  ├─ ${groupPrefix}LB-A (Loser Branch A)';
        } else if (bracketType == 'LB-B') {
          level2Label = '  └─ ${groupPrefix}LB-B (Loser Branch B)';
        } else if (bracketType == 'CROSS') {
          level2Label = '  ├─ Semi-Finals';
        } else if (bracketType == 'GF') {
          level2Label = '  └─ Grand Final';
        } else {
          level2Label = '  ├─ $groupPrefix$bracketType';
        }
      } else {
        // Regular format - stage_round is the key
        level2Key = 'round_$stageRound';
        level2Label = '  Round $stageRound';
      }

      // Level 3: Stage Round (always)
      String level3Key = 'round_$stageRound';
      String level3Label = '    └─ Round $stageRound';

      // Initialize structure
      if (!structure.containsKey(level1Key)) {
        structure[level1Key] = {
          'label': level1Label,
          'display_order': displayOrder,
          'children': <String, dynamic>{},
          'matches': <Map<String, dynamic>>[],
        };
      }

      if (hasBracketGroups) {
        // 3-level hierarchy for SABO
        if (!structure[level1Key]['children'].containsKey(level2Key)) {
          structure[level1Key]['children'][level2Key] = {
            'label': level2Label,
            'display_order': displayOrder,
            'children': <String, dynamic>{},
            'matches': <Map<String, dynamic>>[],
          };
        }

        if (!structure[level1Key]['children'][level2Key]['children']
            .containsKey(level3Key)) {
          structure[level1Key]['children'][level2Key]['children'][level3Key] = {
            'label': level3Label,
            'display_order': displayOrder,
            'matches': <Map<String, dynamic>>[],
          };
        }

        structure[level1Key]['children'][level2Key]['children'][level3Key]['matches']
            .add(match);
      } else {
        // 2-level hierarchy for regular formats
        if (!structure[level1Key]['children'].containsKey(level2Key)) {
          structure[level1Key]['children'][level2Key] = {
            'label': level2Label,
            'display_order': displayOrder,
            'matches': <Map<String, dynamic>>[],
          };
        }

        structure[level1Key]['children'][level2Key]['matches'].add(match);
      }
    }

    return structure;
  }

  // 🔥 STANDARDIZED: Get round name using bracket_type + stage_round
  String _getRoundName(
    String bracketType,
    int stageRound,
    String? bracketGroup,
  ) {
    // For SABO formats with bracket_group
    if (bracketGroup != null) {
      if (bracketGroup == 'A' || bracketGroup == 'B') {
        if (bracketType == 'WB') {
          return '$bracketGroup-WB-R$stageRound';
        } else if (bracketType == 'LB-A') {
          return '$bracketGroup-LB-A-R$stageRound';
        } else if (bracketType == 'LB-B') {
          return '$bracketGroup-LB-B-R$stageRound';
        }
      } else {
        // Cross Finals
        if (bracketType == 'CROSS') {
          return 'Cross-SF$stageRound';
        } else if (bracketType == 'GF') {
          return 'Final';
        }
      }
    }

    // For regular formats without bracket_group
    switch (bracketType) {
      case 'WB': // Winner Bracket
        return 'WB-R$stageRound';

      case 'LB': // Loser Bracket
        return 'LB-R$stageRound';

      case 'GF': // Grand Final
        return 'Final';

      default:
        return 'R$stageRound';
    }
  }

  // 🔥 STANDARDIZED: Get available rounds using bracket_type + stage_round
  // 🔥 FIXED: Get available bracket groups (A, B, CROSS) or bracket types (WB, LB, GF)
  // PRIORITY: bracket_type takes precedence over bracket_group
  List<Map<String, dynamic>> _getAvailableBracketGroups() {
    if (_matches.isEmpty) return [];

    // Check if we have WB (Winner Bracket) matches
    bool hasWinnerBracket = _matches.any((m) => m['bracket_type'] == 'WB');

    // Detect format:
    // - SABO DE32: Has bracket_group AND WB matches WITH group assignments
    // - SABO DE16: Has WB matches WITHOUT meaningful group structure

    bool hasBracketGroups = false;
    if (hasWinnerBracket) {
      // Check if WB matches have consistent bracket_group values
      var wbMatches = _matches.where((m) => m['bracket_type'] == 'WB');
      var groupACount = wbMatches
          .where((m) => m['bracket_group'] == 'A')
          .length;
      var groupBCount = wbMatches
          .where((m) => m['bracket_group'] == 'B')
          .length;
      var groupCCount = wbMatches
          .where((m) => m['bracket_group'] == 'C')
          .length;
      var groupDCount = wbMatches
          .where((m) => m['bracket_group'] == 'D')
          .length;

      // SABO DE32/DE64: Should have significant WB matches in groups
      // DE32: 2 groups (A, B)
      // DE64: 4 groups (A, B, C, D)
      bool isSaboDE64 = (groupACount >= 4 && groupBCount >= 4 && groupCCount >= 4 && groupDCount >= 4);
      bool isSaboDE32 = (groupACount >= 4 && groupBCount >= 4);
      hasBracketGroups = isSaboDE64 || isSaboDE32;
    }

    if (hasBracketGroups) {
      // SABO DE32 format: Group A, Group B, Cross Finals
      Map<String, int> groupCounts = {};

      for (var match in _matches) {
        final bracketGroup = match['bracket_group'];
        if (bracketGroup != null) {
          groupCounts[bracketGroup] = (groupCounts[bracketGroup] ?? 0) + 1;
        } else {
          groupCounts['CROSS'] = (groupCounts['CROSS'] ?? 0) + 1;
        }
      }

      List<Map<String, dynamic>> groups = [];
      groupCounts.forEach((group, count) {
        groups.add({
          'key': group,
          'label': group == 'CROSS' ? '🏆 Cross/GF' : '📁 Group $group',
          'count': count,
        });
      });

      // Sort: A, B, C, D, CROSS
      groups.sort((a, b) {
        const order = {'A': 0, 'B': 1, 'C': 2, 'D': 3, 'CROSS': 4};
        return (order[a['key']] ?? 99).compareTo(order[b['key']] ?? 99);
      });

      return groups;
    } else {
      // SABO DE16 or standard DE: Winner Bracket, Loser Bracket, Grand Final
      // Check if we have bracket_type field (WB, LB, GF)
      bool hasBracketType = _matches.any(
        (m) =>
            m['bracket_type'] != null &&
            (m['bracket_type'] == 'WB' ||
                m['bracket_type'] == 'LB' ||
                m['bracket_type'] == 'GF'),
      );

      if (!hasBracketType) return []; // No bracket structure

      Map<String, int> bracketCounts = {};

      for (var match in _matches) {
        final bracketType = match['bracket_type'];
        if (bracketType != null) {
          bracketCounts[bracketType] = (bracketCounts[bracketType] ?? 0) + 1;
        }
      }

      // SIMPLIFIED: Count and group into 3 tabs only
      int wbCount = 0;
      int lbCount = 0;
      int finalCount = 0;

      for (var match in _matches) {
        final bracketType = match['bracket_type'];
        if (bracketType == null) continue;

        if (bracketType == 'WB') {
          wbCount++;
        } else if (bracketType.startsWith('LB')) {
          // LB, LB-A, LB-B → Loser Bracket
          lbCount++;
        } else if (bracketType == 'GF' || bracketType == 'SABO') {
          // Finals
          finalCount++;
        }
      }

      // Build simple 3-tab structure
      List<Map<String, dynamic>> brackets = [];

      if (wbCount > 0) {
        brackets.add({
          'key': 'WB',
          'label': 'WB',
          'count': wbCount,
          'order': 0,
        });
      }

      if (lbCount > 0) {
        brackets.add({
          'key': 'LB',
          'label': 'LB',
          'count': lbCount,
          'order': 1,
        });
      }

      if (finalCount > 0) {
        brackets.add({
          'key': 'FINAL',
          'label': 'Finals',
          'count': finalCount,
          'order': 2,
        });
      }

      return brackets;
    }
  }

  List<Map<String, dynamic>> _getAvailableRounds() {
    if (_matches.isEmpty) return [];

    // 🔥 FIX: Use filtered matches to respect selected bracket group
    final matchesToUse = _getFilteredMatches();
    
    if (matchesToUse.isEmpty) return [];

    // Group matches by bracket_type + stage_round + bracket_group
    Map<String, List<Map<String, dynamic>>> groupedMatches = {};

    for (var match in matchesToUse) {
      // Use new standardized fields
      final bracketType = match['bracket_type'] ?? 'WB';
      final stageRound = match['stage_round'] ?? match['round_number'] ?? 1;
      final bracketGroup = match['bracket_group'];

      // Create unique key for this round tab
      final key = '$bracketType-$stageRound-${bracketGroup ?? ""}';

      if (!groupedMatches.containsKey(key)) {
        groupedMatches[key] = [];
      }
      groupedMatches[key]!.add(match);
    }

    // Convert to list and sort by display_order
    List<Map<String, dynamic>> rounds = [];
    groupedMatches.forEach((key, matches) {
      final firstMatch = matches.first;
      final bracketType = firstMatch['bracket_type'] ?? 'WB';
      final stageRound =
          firstMatch['stage_round'] ?? firstMatch['round_number'] ?? 1;
      final bracketGroup = firstMatch['bracket_group'];
      final displayOrder = firstMatch['display_order'] ?? 0;

      rounds.add({
        'bracket_type': bracketType,
        'stage_round': stageRound,
        'bracket_group': bracketGroup,
        'display_order': displayOrder,
        'name': _getRoundName(bracketType, stageRound, bracketGroup),
        'matches': matches.length,
      });
    });

    // Sort by display_order
    rounds.sort(
      (a, b) =>
          (a['display_order'] as int).compareTo(b['display_order'] as int),
    );

    return rounds;
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _safeDebugPrint(
        '🔄 MatchManagementTab: Loading matches for tournament ${widget.tournamentId}',
      );

      // Load tournament info to check bracket_format
      try {
        final tournamentData = await Supabase.instance.client
            .from('tournaments')
            .select('bracket_format')
            .eq('id', widget.tournamentId)
            .single();
        _tournament = tournamentData;
        _safeDebugPrint(
          '🏆 MatchManagementTab: Tournament bracket_format = ${_tournament?['bracket_format']}',
        );
      } catch (e) {
        _safeDebugPrint('⚠️ Failed to load tournament info: $e');
      }

      // Load participants count for dynamic round calculation
      List<Map<String, dynamic>> participants = [];
      try {
        participants = await _tournamentService
            .getTournamentParticipantsWithPaymentStatus(widget.tournamentId);
        _totalParticipants = participants.length;
        _safeDebugPrint(
          '👥 MatchManagementTab: Loaded $_totalParticipants participants',
        );
      } catch (e) {
        _safeDebugPrint('⚠️ Failed to load participants: $e');
        _totalParticipants = 0;
      }

      // Try to load matches with better error handling
      List<Map<String, dynamic>> matches = [];
      String? loadError;

      // Use enhanced tournament service that includes user profiles
      try {
        matches = await _tournamentService.getTournamentMatches(
          widget.tournamentId,
        );
        _safeDebugPrint(
          '📋 Loaded ${matches.length} matches from enhanced service with user profiles',
        );
      } catch (serviceError) {
        _safeDebugPrint('⚠️ Enhanced service failed: $serviceError');
        loadError = serviceError.toString();

        // Fallback to cached service (raw data only)
        try {
          matches = await CachedTournamentService.loadMatches(
            widget.tournamentId,
            forceRefresh: true,
          );
          _safeDebugPrint(
            '📋 Loaded ${matches.length} matches from cache/service (fallback)',
          );
          loadError = null; // Clear error if cache works
        } catch (cacheError) {
          _safeDebugPrint('❌ Cache service also failed: $cacheError');
          loadError = 'Không thể tải trận đấu: ${cacheError.toString()}';
        }
      }

      // If we have matches, use them even if there were some errors
      if (matches.isNotEmpty) {
        setState(() {
          _matches = matches;
          _isLoading = false;
          _errorMessage = null; // Clear any previous errors
        });

        _safeDebugPrint(
          '📊 MatchManagementTab: Successfully loaded ${matches.length} matches',
        );
        if (matches.isNotEmpty) {
          final firstMatch = matches.first;
          _safeDebugPrint('🎯 MatchManagementTab: First match data:');
          _safeDebugPrint('   matchId: ${firstMatch['matchId']}');
          _safeDebugPrint('   player1: ${firstMatch['player1']}');
          _safeDebugPrint('   player2: ${firstMatch['player2']}');
        }
      } else if (loadError != null) {
        // Only show error if we have no matches and there's an error
        setState(() {
          _matches = [];
          _isLoading = false;
          _errorMessage = loadError;
        });
      } else {
        // No matches but no error - empty tournament
        setState(() {
          _matches = [];
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _safeDebugPrint(
        '❌ MatchManagementTab: Critical error loading matches: $e',
      );
      setState(() {
        _errorMessage = 'Lỗi tải dữ liệu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Method to manually refresh matches
  Future<void> _refreshMatches() async {
    // 🔥 Start rotation animation
    _refreshAnimationController.repeat();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _safeDebugPrint(
      '🔄 Manual refresh triggered for tournament ${widget.tournamentId}',
    );

    try {
      // 🔥 FORCE REFRESH: Use TournamentService to get matches WITH user profiles
      _safeDebugPrint('🗑️ Force refreshing matches with user profiles...');
      
      // Load participants count for dynamic round calculation
      List<Map<String, dynamic>> participants = [];
      try {
        participants = await _tournamentService
            .getTournamentParticipantsWithPaymentStatus(widget.tournamentId);
        _totalParticipants = participants.length;
        _safeDebugPrint(
          '👥 Refreshed: Loaded $_totalParticipants participants',
        );
      } catch (e) {
        _safeDebugPrint('⚠️ Failed to refresh participants: $e');
      }

      // 🔥 KEY FIX: Use TournamentService instead of CachedTournamentService
      // This ensures we get user profiles (player names, avatars, etc.)
      List<Map<String, dynamic>> matches = [];
      try {
        matches = await _tournamentService.getTournamentMatches(
          widget.tournamentId,
        );
        _safeDebugPrint(
          '📋 Refreshed ${matches.length} matches with user profiles from TournamentService',
        );
      } catch (serviceError) {
        _safeDebugPrint('⚠️ TournamentService failed: $serviceError');
        
        // Fallback to cached service with forceRefresh
        matches = await CachedTournamentService.loadMatches(
          widget.tournamentId,
          forceRefresh: true,
        );
        _safeDebugPrint(
          '📋 Fallback: Loaded ${matches.length} matches from CachedTournamentService',
        );
      }

      setState(() {
        _matches = matches;
        _isLoading = false;
        _errorMessage = null;
      });

      // 🔥 Stop rotation animation
      _refreshAnimationController.stop();
      _refreshAnimationController.reset();

      _safeDebugPrint(
        '✅ Successfully refreshed ${matches.length} matches with user data',
      );

      // Show success feedback
      if (mounted) {
        AppSnackbar.success(
          context: context,
          message: 'Đã làm mới ${matches.length} trận đấu từ server',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      _safeDebugPrint('❌ Refresh failed: $e');
      
      // 🔥 Stop rotation animation on error
      _refreshAnimationController.stop();
      _refreshAnimationController.reset();

      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi làm mới: ${e.toString()}';
      });

      // Show error feedback
      if (mounted) {
        AppSnackbar.error(
          context: context,
          message: 'Lỗi khi làm mới: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  // 🔥 NEW: Force load directly from database, bypassing all caches
  Future<void> _forceLoadFromDatabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _safeDebugPrint(
      '🔥 Force loading from database for tournament ${widget.tournamentId}',
    );

    try {
      // Load participants count
      List<Map<String, dynamic>> participants = [];
      try {
        participants = await _tournamentService
            .getTournamentParticipantsWithPaymentStatus(widget.tournamentId);
        _totalParticipants = participants.length;
        _safeDebugPrint(
          '👥 Force load: Found $_totalParticipants participants',
        );
      } catch (e) {
        _safeDebugPrint('⚠️ Failed to load participants: $e');
      }

      // 🔥 CRITICAL: Directly query Supabase, completely bypass cache
      _safeDebugPrint('🗄️ Querying database directly...');
      
      final rawMatches = await Supabase.instance.client
          .from('matches')
          .select('*')
          .eq('tournament_id', widget.tournamentId)
          .order('round_number')
          .order('match_number');

      _safeDebugPrint('📊 Got ${rawMatches.length} raw matches from DB');

      // Collect player IDs
      List<String> playerIds = [];
      for (var match in rawMatches) {
        if (match['player1_id'] != null) playerIds.add(match['player1_id']);
        if (match['player2_id'] != null) playerIds.add(match['player2_id']);
      }

      // Fetch user profiles
      Map<String, dynamic> userProfiles = {};
      if (playerIds.isNotEmpty) {
        final uniquePlayerIds = playerIds.toSet().toList();
        _safeDebugPrint('👥 Fetching ${uniquePlayerIds.length} user profiles...');
        
        final profiles = await Supabase.instance.client
            .from('users')
            .select('id, full_name, display_name, avatar_url, elo_rating, rank')
            .inFilter('id', uniquePlayerIds);

        for (var profile in profiles) {
          userProfiles[profile['id']] = profile;
        }
        _safeDebugPrint('✅ Fetched ${profiles.length} profiles');
      }

      // Map profiles to matches
      final processedMatches = rawMatches.map<Map<String, dynamic>>((match) {
        final player1Profile = match['player1_id'] != null
            ? userProfiles[match['player1_id']]
            : null;
        final player2Profile = match['player2_id'] != null
            ? userProfiles[match['player2_id']]
            : null;

        return {
          "matchId": match['id'],
          "id": match['id'],
          "round_number": match['round_number'] ?? 1,
          "match_number": match['match_number'] ?? 1,
          "bracket_group": match['bracket_group'],
          "bracket_type": match['bracket_type'],
          "status": match['status'] ?? "pending",
          "player1_id": match['player1_id'],
          "player2_id": match['player2_id'],
          "player1": player1Profile != null
              ? {
                  "id": player1Profile['id'],
                  "name": player1Profile['display_name'] ?? 
                          player1Profile['full_name'] ?? 
                          'Player 1',
                  "display_name": player1Profile['display_name'],
                  "full_name": player1Profile['full_name'],
                  "avatar": player1Profile['avatar_url'] ??
                      "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                  "rank": player1Profile['rank'],
                }
              : null,
          "player2": player2Profile != null
              ? {
                  "id": player2Profile['id'],
                  "name": player2Profile['display_name'] ?? 
                          player2Profile['full_name'] ?? 
                          'Player 2',
                  "display_name": player2Profile['display_name'],
                  "full_name": player2Profile['full_name'],
                  "avatar": player2Profile['avatar_url'] ??
                      "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                  "rank": player2Profile['rank'],
                }
              : null,
          "player1_score": match['player1_score'] ?? 0,
          "player2_score": match['player2_score'] ?? 0,
          "winner_id": match['winner_id'],
          "display_order": match['display_order'],
          "next_match_id": match['next_match_id'],
          "winner_advances_to": match['winner_advances_to'],
          "loser_advances_to": match['loser_advances_to'],
        };
      }).toList();

      setState(() {
        _matches = processedMatches;
        _isLoading = false;
        _errorMessage = null;
      });

      _safeDebugPrint(
        '✅ Force loaded ${processedMatches.length} matches directly from database',
      );

      // Show success feedback
      if (mounted) {
        AppSnackbar.success(
          context: context,
          message: 'Đã tải ${processedMatches.length} trận từ database',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      _safeDebugPrint('❌ Force load failed: $e');
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải từ database: ${e.toString()}';
      });

      // Show error feedback
      if (mounted) {
        AppSnackbar.error(
          context: context,
          message: 'Lỗi: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  // 🔥 UPDATED: Filter matches based on selected status and bracket group/type
  List<Map<String, dynamic>> _getFilteredMatches() {
    var filtered = _matches;

    // 🔥 Filter by bracket_group (SABO DE32) or bracket_type (SABO DE16)
    if (_selectedBracketGroup != null) {
      // Check if this tournament uses bracket_group (SABO DE32)
      bool hasBracketGroups = _matches.any((m) => m['bracket_group'] != null);

      if (hasBracketGroups) {
        // SABO DE32: Filter by bracket_group (A, B, C, D, CROSS)
        filtered = filtered.where((m) {
          final bracketGroup = m['bracket_group'];
          
          // Debug log
          if (filtered.indexOf(m) == 0) {
            ProductionLogger.debug('Debug log', tag: 'AutoFix');
          }
          
          if (_selectedBracketGroup == 'CROSS') {
            return bracketGroup == 'CROSS' || bracketGroup == null || bracketGroup.toString().toUpperCase().contains('CROSS');
          }
          
          // Support both formats: 'A' or 'Group A'
          final groupStr = bracketGroup?.toString().toUpperCase() ?? '';
          final selectedStr = _selectedBracketGroup?.toUpperCase() ?? '';
          
          return groupStr == selectedStr || 
                 groupStr == 'GROUP $selectedStr' ||
                 groupStr.endsWith(selectedStr);
        }).toList();
      } else {
        // SABO DE16: Filter by bracket_type (WB, LB, FINAL) - SIMPLIFIED
        filtered = filtered.where((m) {
          final bracketType = m['bracket_type'];

          if (_selectedBracketGroup == 'WB') {
            return bracketType == 'WB';
          } else if (_selectedBracketGroup == 'LB') {
            // Include all loser bracket types: LB, LB-A, LB-B
            return bracketType == 'LB' ||
                bracketType == 'LB-A' ||
                bracketType == 'LB-B';
          } else if (_selectedBracketGroup == 'FINAL') {
            // Include GF and SABO types as Finals
            return bracketType == 'GF' || bracketType == 'SABO';
          }

          return false;
        }).toList();
      }
    }

    // Filter by status
    switch (_selectedFilter) {
      case 'pending':
        return filtered.where((m) => m['status'] == 'pending').toList();
      case 'in_progress':
        return filtered.where((m) => m['status'] == 'in_progress').toList();
      case 'completed':
        return filtered.where((m) => m['status'] == 'completed').toList();
      default:
        return filtered;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: Keep normal match list view for all formats including DE24
    // The bracket visualization is in the "Bracket" tab, not "Matches" tab
    
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.sp),
            Text('Đang tải trận đấu...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40.sp, color: AppTheme.errorLight),
            SizedBox(height: 10.sp),
            Text(
              "Lỗi tải dữ liệu",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.sp),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 12.sp),
            AppButton(
              label: 'Thử lại',
              onPressed: _loadMatches,
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports,
              size: 40.sp,
              color: AppTheme.dividerLight,
            ),
            SizedBox(height: 10.sp),
            Text(
              "Chưa có trận đấu nào",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.sp),
            Text(
              "Tạo bảng đấu để bắt đầu các trận đấu",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 16.sp),
            ElevatedButton.icon(
              onPressed: _refreshMatches,
              icon: Icon(Icons.refresh, size: 16.sp),
              label: Text("Làm mới", style: TextStyle(fontSize: 14.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.sp,
                  vertical: 8.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            expandedHeight: _getAvailableBracketGroups().isNotEmpty ? 130 : 95,
            floating: false,
            pinned: false,
            snap: false,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Filter theo trạng thái + Refresh button
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn(
                                  'All',
                                  _matches.length.toString(),
                                  'all',
                                ),
                                _buildStatColumn(
                                  'Chờ',
                                  _matches
                                      .where((m) => m['status'] == 'pending')
                                      .length
                                      .toString(),
                                  'pending',
                                ),
                                _buildStatColumn(
                                  'Đang',
                                  _matches
                                      .where(
                                        (m) => m['status'] == 'in_progress',
                                      )
                                      .length
                                      .toString(),
                                  'in_progress',
                                ),
                                _buildStatColumn(
                                  'Xong',
                                  _matches
                                      .where((m) => m['status'] == 'completed')
                                      .length
                                      .toString(),
                                  'completed',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          // 🔥 Force load from database button
                          IconButton(
                            onPressed: _isLoading ? null : _forceLoadFromDatabase,
                            icon: Icon(
                              Icons.cloud_download_outlined,
                              color: _isLoading 
                                  ? Colors.grey 
                                  : Colors.blue[700],
                              size: 24,
                            ),
                            tooltip: 'Tải trực tiếp từ database (bỏ qua cache)',
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(),
                          ),
                          SizedBox(width: 4),
                          // 🔥 Animated refresh button
                          RotationTransition(
                            turns: _refreshAnimation,
                            child: IconButton(
                              onPressed: _isLoading ? null : _refreshMatches,
                              icon: Icon(
                                Icons.refresh,
                                color: _isLoading 
                                    ? Colors.grey 
                                    : AppTheme.primaryLight,
                                size: 24,
                              ),
                              tooltip: 'Làm mới từ server',
                              padding: EdgeInsets.all(8),
                              constraints: BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                      // Row 2: Group filters (if SABO DE32 format)
                      if (_getAvailableBracketGroups().isNotEmpty) ...[
                        SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // "All Groups" button
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 3),
                                child: _buildGroupFilterButton(
                                  'All',
                                  _matches.length,
                                  null,
                                ),
                              ),
                              // Individual group buttons
                              ..._getAvailableBracketGroups()
                                  .map(
                                    (groupData) => Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      child: _buildGroupFilterButton(
                                        groupData['label'],
                                        groupData['count'],
                                        groupData['key'],
                                      ),
                                    ),
                                  )
                                  ,
                            ],
                          ),
                        ),
                      ],
                      // Row 3: Dynamic round filters based on bracket_type + stage_round
                      if (_matches.isNotEmpty) ...[
                        SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _getAvailableRounds()
                                .map(
                                  (roundData) => Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: _buildRoundFilterButton(
                                      roundData['name'],
                                      roundData['matches'].toString(),
                                      roundData['bracket_type'], // 🔥 NEW: bracket type
                                      roundData['stage_round'], // 🔥 NEW: stage round
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ] else ...[
                        // Fallback for when participant data isn't loaded yet
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildRoundFilterColumn(
                              'R1',
                              _matches
                                  .where(
                                    (m) =>
                                        (m['round'] ??
                                            m['round_number'] ??
                                            1) ==
                                        1,
                                  )
                                  .length
                                  .toString(),
                              'round1',
                            ),
                            _buildRoundFilterColumn(
                              'R2',
                              _matches
                                  .where(
                                    (m) =>
                                        (m['round'] ??
                                            m['round_number'] ??
                                            1) ==
                                        2,
                                  )
                                  .length
                                  .toString(),
                              'round2',
                            ),
                            _buildRoundFilterColumn(
                              'R3',
                              _matches
                                  .where(
                                    (m) =>
                                        (m['round'] ??
                                            m['round_number'] ??
                                            1) ==
                                        3,
                                  )
                                  .length
                                  .toString(),
                              'round3',
                            ),
                            _buildRoundFilterColumn(
                              'R4',
                              _matches
                                  .where(
                                    (m) =>
                                        (m['round'] ??
                                            m['round_number'] ??
                                            1) ==
                                        4,
                                  )
                                  .length
                                  .toString(),
                              'round4',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ];
      },
      body: _buildHierarchicalMatchList(),
    );
  }

  // 🔥 NEW: Build hierarchical match list with expandable sections
  Widget _buildHierarchicalMatchList() {
    final structure = _getHierarchicalStructure();

    // ⚡ PERFORMANCE: Debug logging disabled to reduce overhead
    // _safeDebugPrint('🔍 DEBUG _buildHierarchicalMatchList:');
    // _safeDebugPrint('   Total matches: ${_matches.length}');
    // _safeDebugPrint('   Selected filter: $_selectedFilter');
    // _safeDebugPrint('   Selected bracket group: $_selectedBracketGroup');
    // _safeDebugPrint('   Filtered matches: ${_getFilteredMatches().length}');
    // _safeDebugPrint('   Structure keys: ${structure.keys.toList()}');

    if (structure.isEmpty) {
      // Show more helpful empty state with debug info
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _selectedBracketGroup != null
                    ? Icons.filter_alt_off
                    : Icons.info_outline,
                size: 56.sp,
                color: _selectedBracketGroup != null
                    ? Colors.orange[400]
                    : Colors.grey[400],
              ),
              SizedBox(height: 16.sp),
              Text(
                _selectedBracketGroup != null
                    ? 'Không có trận đấu trong bộ lọc này'
                    : 'Không có trận đấu',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12.sp),
              if (_matches.isNotEmpty && _selectedBracketGroup != null) ...[
                Text(
                  'Có ${_matches.length} trận đấu trong giải\nNhưng không có trận nào trong "$_selectedBracketGroup"',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 16.sp),
                ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _selectedBracketGroup = null;
                    _selectedFilter = 'all';
                  }),
                  icon: Icon(Icons.clear_all, size: 18.sp),
                  label: Text(
                    'Xem tất cả trận đấu',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.sp,
                      vertical: 12.sp,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Tổng: ${_matches.length} trận đấu\nSau lọc: ${_getFilteredMatches().length} trận',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                ),
                if (_selectedBracketGroup != null) ...[
                  SizedBox(height: 12.sp),
                  OutlinedButton(
                    onPressed: () =>
                        setState(() => _selectedBracketGroup = null),
                    child: Text(
                      'Xóa bộ lọc',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }

    // Sort top-level keys by display_order
    final sortedLevel1Keys = structure.keys.toList()
      ..sort(
        (a, b) => (structure[a]['display_order'] as int).compareTo(
          structure[b]['display_order'] as int,
        ),
      );

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 8.sp,
        right: 8.sp,
        top: 8.sp,
        bottom: kBottomNavigationBarHeight + 8.sp,
      ),
      itemCount: sortedLevel1Keys.length,
      itemBuilder: (context, index) {
        final key = sortedLevel1Keys[index];
        final section = structure[key];
        return _buildExpandableSection(
          label: section['label'],
          children: section['children'],
          matches: section['matches'],
        );
      },
    );
  }

  // 🔥 NEW: Build expandable section for each level
  Widget _buildExpandableSection({
    required String label,
    required Map<String, dynamic> children,
    required List<Map<String, dynamic>> matches,
  }) {
    // Count total matches in this section (including children)
    int totalMatches = matches.length;
    children.forEach((key, child) {
      totalMatches += _countMatches(child);
    });

    // If no children, just show matches
    if (children.isEmpty && matches.isNotEmpty) {
      return Card(
        margin: EdgeInsets.only(bottom: 8.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12.sp),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.sp,
                      vertical: 4.sp,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12.sp),
                    ),
                    child: Text(
                      '$totalMatches trận',
                      style: TextStyle(
                        fontSize: 13.sp, // Increased from 10.sp
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...matches.map((match) => _buildMatchCard(match)),
          ],
        ),
      );
    }

    // Has children - create expandable tile
    return Card(
      margin: EdgeInsets.only(bottom: 8.sp),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(12.sp),
          ),
          child: Text(
            '$totalMatches trận',
            style: TextStyle(
              fontSize: 13.sp, // Increased from 10.sp
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ),
        children: [
          // Sort children by display_order
          ...(() {
            final sortedChildKeys = children.keys.toList()
              ..sort(
                (a, b) => (children[a]['display_order'] as int).compareTo(
                  children[b]['display_order'] as int,
                ),
              );

            return sortedChildKeys.map((childKey) {
              final child = children[childKey];

              // If child has its own children (3-level hierarchy), recurse
              if (child['children'] != null &&
                  (child['children'] as Map).isNotEmpty) {
                return Padding(
                  padding: EdgeInsets.only(left: 16.sp),
                  child: _buildExpandableSection(
                    label: child['label'],
                    children: child['children'],
                    matches: child['matches'] ?? [],
                  ),
                );
              }

              // Leaf node - show matches directly
              final childMatches =
                  child['matches'] as List<Map<String, dynamic>>;
              return Padding(
                padding: EdgeInsets.only(left: 16.sp),
                child: Card(
                  margin: EdgeInsets.only(bottom: 8.sp),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.sp),
                        color: Colors.grey[100],
                        child: Row(
                          children: [
                            Text(
                              child['label'],
                              style: TextStyle(
                                fontSize: 14.sp, // Increased from 12.sp
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Spacer(),
                            Text(
                              '${childMatches.length} trận',
                              style: TextStyle(
                                fontSize: 13.sp, // Increased from 10.sp
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...childMatches
                          .map((match) => _buildMatchCard(match))
                          ,
                    ],
                  ),
                ),
              );
            }).toList();
          })(),
        ],
      ),
    );
  }

  // Helper: Count total matches in a section
  int _countMatches(Map<String, dynamic> section) {
    int count = (section['matches'] as List?)?.length ?? 0;

    if (section['children'] != null) {
      (section['children'] as Map).forEach((key, child) {
        count += _countMatches(child);
      });
    }

    return count;
  }

  Widget _buildStatColumn(String label, String value, String filter) {
    bool isSelected = _selectedFilter == filter;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.primaryLight : Colors.grey[700],
              ),
            ),
            SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppTheme.primaryLight : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 NEW: Build group filter button (for SABO DE32 bracket_group filtering)
  Widget _buildGroupFilterButton(String label, int count, String? groupKey) {
    bool isSelected = _selectedBracketGroup == groupKey;

    return InkWell(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedBracketGroup = null; // Toggle off
        } else {
          _selectedBracketGroup = groupKey; // Select this group
        }
      }),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue[900]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.blue[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue[700] : Colors.blue[900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 STANDARDIZED: Build round filter button with bracket_type + stage_round filtering
  Widget _buildRoundFilterButton(
    String label,
    String value,
    String bracketType,
    int stageRound,
  ) {
    bool isSelected =
        _selectedBracketType == bracketType &&
        _selectedStageRound == stageRound;

    return InkWell(
      onTap: () => setState(() {
        if (isSelected) {
          // Toggle: click again to show all
          _selectedBracketType = null;
          _selectedStageRound = null;
        } else {
          _selectedBracketType = bracketType;
          _selectedStageRound = stageRound;
        }
        _selectedFilter = 'all'; // Reset status filter when changing rounds
      }),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryDark.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDark : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryDark : Colors.grey[700],
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryDark
                    : AppTheme.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Legacy: Build round filter column with old string-based filtering (for fallback)
  Widget _buildRoundFilterColumn(String label, String value, String filter) {
    bool isSelected = _selectedFilter == filter;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.sp, horizontal: 4.sp),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryDark.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(6.sp),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDark : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp, // Increased from 7.sp
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryDark : Colors.grey[700],
              ),
            ),
            SizedBox(height: 2.sp),
            Text(
              value,
              style: TextStyle(
                fontSize: 15.sp, // Increased from 10.sp
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryDark
                    : AppTheme.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final status = match['status'] ?? 'pending';

    // ⚡ PERFORMANCE: Variables kept for future debugging, currently unused
    // int roundNumber = match['round_number'] ?? match['round'] ?? 1;
    // int matchNumber = match['match_number'] ?? 1;

    final player1Score = match['player1_score'] ?? 0;
    final player2Score = match['player2_score'] ?? 0;

    // Auto update status if both players are available but status is still pending
    String actualStatus = status;
    final hasPlayer1 = match['player1'] != null;
    final hasPlayer2 = match['player2'] != null;

    if (status == 'pending' && hasPlayer1 && hasPlayer2) {
      actualStatus = 'in_progress';
      // Update the match status in the backend - use compatible ID field
      final matchId = match['id'] ?? match['matchId'];
      if (matchId != null) {
        _autoUpdateMatchStatus(matchId, 'in_progress');
      }
    }

    return InkWell(
      onTap: () {
        if (actualStatus == 'completed') {
          _editCompletedMatch(match);
        } else {
          _enterScore(match);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 1),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.dividerLight.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with match code and status icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Display match progression from database
                Flexible(
                  child: Text(
                    _buildMatchProgressionText(match),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 12),
                _buildMatchStatusBadge(actualStatus),
              ],
            ),
            SizedBox(height: 10),

            // Players in single rows
            _buildCompactPlayerRow(
              match['player1'],
              player1Score,
              match['winner'] == 'player1',
              match,
              'player1',
            ),
            SizedBox(height: 6),
            _buildCompactPlayerRow(
              match['player2'],
              player2Score,
              match['winner'] == 'player2',
              match,
              'player2',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPlayerRow(
    dynamic player,
    int score,
    bool isWinner,
    Map<String, dynamic> match,
    String playerType,
  ) {
    // Get player name from different possible data structures
    String playerName = 'TBD';
    if (player != null) {
      if (player is Map<String, dynamic>) {
        playerName =
            player['name'] ??
            player['full_name'] ??
            player['display_name'] ??
            'Unknown Player';
      } else if (player is String) {
        playerName = player.isNotEmpty ? player : 'TBD';
      }
    }

    if (player == null || playerName == 'TBD') {
      return GestureDetector(
        onTap: () => _enterScore(match),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              UserAvatarWidget(
                avatarUrl: null,
                size: 32,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'TBD',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Text(
                '0',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _enterScore(match),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isWinner
              ? AppTheme.successLight.withValues(alpha: 0.08)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isWinner
                ? AppTheme.successLight.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            UserAvatarWidget(
              avatarUrl: player['avatar'],
              size: 32,
            ),
            SizedBox(width: 10),
            // Player name
            Expanded(
              child: Text(
                playerName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isWinner ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.grey[900],
                ),
              ),
            ),
            // Score
            Text(
              score.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isWinner ? AppTheme.successLight : Colors.grey[700],
              ),
            ),
            // Trophy if winner
            if (isWinner) ...[
              SizedBox(width: 8),
              Icon(Icons.emoji_events, color: Colors.amber[700], size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchStatusBadge(String status) {
    // Simple icon-only badge - iOS/Facebook style
    IconData icon;
    Color iconColor;

    switch (status) {
      case 'pending':
        icon = Icons.schedule; // Clock icon for pending
        iconColor = Colors.orange[600]!;
        break;
      case 'in_progress':
        icon = Icons.play_circle_outline; // Play icon for in progress
        iconColor = Colors.blue[600]!;
        break;
      case 'completed':
        icon = Icons.check_circle; // Green checkmark for completed
        iconColor = Color(0xFF00C853); // Bright green like Facebook
        break;
      default:
        icon = Icons.help_outline;
        iconColor = Colors.grey[400]!;
    }

    return Icon(icon, color: iconColor, size: 20);
  }

  void _enterScore(Map<String, dynamic> match) async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Get player names using same logic as _buildCompactPlayerRow
    String player1Name = 'Player 1';
    String player2Name = 'Player 2';

    if (match['player1'] != null) {
      if (match['player1'] is Map<String, dynamic>) {
        player1Name =
            match['player1']['name'] ??
            match['player1']['full_name'] ??
            match['player1']['display_name'] ??
            'Player 1';
      } else if (match['player1'] is String) {
        player1Name = match['player1'].isNotEmpty
            ? match['player1']
            : 'Player 1';
      }
    }

    if (match['player2'] != null) {
      if (match['player2'] is Map<String, dynamic>) {
        player2Name =
            match['player2']['name'] ??
            match['player2']['full_name'] ??
            match['player2']['display_name'] ??
            'Player 2';
      } else if (match['player2'] is String) {
        player2Name = match['player2'].isNotEmpty
            ? match['player2']
            : 'Player 2';
      }
    }

    final TextEditingController player1Controller = TextEditingController();
    final TextEditingController player2Controller = TextEditingController();

    // Pre-fill current scores
    player1Controller.text = (match['player1_score'] ?? 0).toString();
    player2Controller.text = (match['player2_score'] ?? 0).toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final p1Score = int.tryParse(player1Controller.text) ?? 0;
            final p2Score = int.tryParse(player2Controller.text) ?? 0;
            final isDraw = p1Score == p2Score;
            
            return AlertDialog(
              title: Text(
                'Nhập tỷ số trận đấu',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Player 1 score input with +/- buttons
                  _buildScoreInputRow(
                    player1Name, 
                    player1Controller,
                    onChanged: () => setDialogState(() {}),
                  ),
                  SizedBox(height: 16.sp),
                  // Player 2 score input with +/- buttons
                  _buildScoreInputRow(
                    player2Name, 
                    player2Controller,
                    onChanged: () => setDialogState(() {}),
                  ),
                  // Warning for draw
                  if (isDraw) ...[
                    SizedBox(height: 12.sp),
                    Container(
                      padding: EdgeInsets.all(8.sp),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange[300]!),
                        borderRadius: BorderRadius.circular(8.sp),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange[700],
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.sp),
                          Expanded(
                            child: Text(
                              'Không được hòa! Phải có người thắng.',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                AppButton(
                  label: 'Hủy',
                  type: AppButtonType.text,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                AppButton(
                  label: 'Lưu',
                  onPressed: isDraw ? null : () async {
                    final p1Score = int.tryParse(player1Controller.text) ?? 0;
                    final p2Score = int.tryParse(player2Controller.text) ?? 0;

                    await _updateMatchScore(match, p1Score, p2Score);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateMatchScore(
    Map<String, dynamic> match,
    int player1Score,
    int player2Score,
  ) async {
    try {
      final matchId = match['id'] ?? match['matchId'];
      String winnerId = '';
      String status = 'completed';

      // Determine winner based on scores
      if (player1Score > player2Score) {
        winnerId = match['player1_id'] ?? '';
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      } else if (player2Score > player1Score) {
        winnerId = match['player2_id'] ?? '';
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      // Validate winner_id
      if (winnerId.isEmpty && player1Score != player2Score) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      // Update in database (with silent caching)
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      try {
        // ⚡ CRITICAL FIX: Always update directly to database first
        // This ensures data is persisted before cache update
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        await Supabase.instance.client
            .from('matches')
            .update({
              'player1_score': player1Score,
              'player2_score': player2Score,
              'winner_id': winnerId.isEmpty ? null : winnerId,
              'status': status,
              // 'completed_at': status == 'completed' ? DateTime.now().toIso8601String() : null, // TODO: Add column to database
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', matchId);

        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // Then update cache to reflect database state
        try {
          await CachedTournamentService.updateMatchScore(
            widget.tournamentId,
            matchId,
            player1Score: player1Score,
            player2Score: player2Score,
            winnerId: winnerId.isEmpty ? null : winnerId,
            status: status,
          );
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } catch (cacheError) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          // Cache failure is non-critical since database is already updated
        }
      } catch (e) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        rethrow; // Rethrow to show error to user
      }

      // Update local state - OPTIMIZED: No setState during score input
      final matchIndex = _matches.indexWhere(
        (m) => (m['id'] ?? m['matchId']) == matchId,
      );
      if (matchIndex != -1) {
        _matches[matchIndex]['player1_score'] = player1Score;
        _matches[matchIndex]['player2_score'] = player2Score;
        _matches[matchIndex]['winner_id'] = winnerId.isEmpty ? null : winnerId;
        _matches[matchIndex]['status'] = status;

        // Update winner field for UI display
        if (winnerId.isNotEmpty) {
          if (winnerId == match['player1_id']) {
            _matches[matchIndex]['winner'] = 'player1';
          } else if (winnerId == match['player2_id']) {
            _matches[matchIndex]['winner'] = 'player2';
          }
        } else {
          _matches[matchIndex]['winner'] = null;
        }
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // ✅ NEW: Call advancement service if match is completed with a winner
      if (status == 'completed' && winnerId.isNotEmpty) {
        try {
          // ✅ Use UnifiedBracketService for ALL formats
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          await UnifiedBracketService.instance.processMatchResult(
            matchId: matchId,
            winnerId: winnerId,
            scores: {
              'player1': player1Score,
              'player2': player2Score,
            },
          );
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } catch (advError) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }
      
      // ⚡ PERFORMANCE: Just rebuild with current data
      // The local _matches array is already updated above
      // No need to reload all 27 matches from database!
      setState(() {});

      // Show success message to user
      if (mounted) {
        AppSnackbar.success(
          context: context,
          message: 'Tỷ số đã cập nhật: $player1Score - $player2Score'
              '${winnerId.isNotEmpty ? '\n🏆 Người thắng đã được tiến vào vòng tiếp theo!' : ''}',
          duration: const Duration(seconds: 2),
        );
      }

      // Notify parent widget about the score update to refresh bracket
      if (widget.onMatchScoreUpdated != null) {
        widget.onMatchScoreUpdated!();
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Show error to user
      if (mounted) {
        AppSnackbar.error(
          context: context,
          message: 'Lỗi cập nhật tỷ số: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  // REMOVED: _checkAndCreateNextRound() - not used anymore
  // This function was for auto-creating next round matches, but now advancement
  // is handled using database winner_advances_to/loser_advances_to fields
  /*
  Future<void> _checkAndCreateNextRound(Map<String, dynamic> completedMatch) async {
    try {
      final currentRound = completedMatch['round'] ?? completedMatch['round_number'] ?? 1;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      
      // Get all matches for the current round
      final currentRoundMatches = await Supabase.instance.client
          .from('matches')
          .select('id, round_number, status, winner_id, player1_id, player2_id')
          .eq('tournament_id', widget.tournamentId)
          .eq('round_number', currentRound);
      
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      
      // Get completed matches with winners (progressive creation)
      final completedMatches = currentRoundMatches
          .where((m) => m['status'] == 'completed' && m['winner_id'] != null)
          .toList();
      
      _safeDebugPrint('✅ Completed matches with winners: ${completedMatches.length}/${currentRoundMatches.length}');
      
      // Group completed matches into pairs for next round creation
      final availableWinners = completedMatches
          .map((m) => m['winner_id'] as String)
          .toList();
      
      // Only create next round matches if we have pairs of winners (every 2 winners = 1 next match)
      final possibleNextMatches = availableWinners.length ~/ 2;
      
      if (possibleNextMatches == 0) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return;
      }
      
      // Check which next round matches already exist  
      final existingNextRoundMatches = await Supabase.instance.client
          .from('matches')
          .select('id, match_number')
          .eq('tournament_id', widget.tournamentId)
          .eq('round_number', currentRound + 1)
          .order('match_number');
      
      final maxPossibleNextMatches = currentRoundMatches.length ~/ 2;
      final existingCount = existingNextRoundMatches.length;
      
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      
      if (existingCount >= maxPossibleNextMatches) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return;
      }
      
      // Progressive creation: Only create matches for new winner pairs
      final matchesToCreate = possibleNextMatches - existingCount;
      
      if (matchesToCreate <= 0) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return;
      }
      
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      
      // Create next round matches progressively
      final nextRoundMatches = <Map<String, dynamic>>[];
      final startIndex = existingCount * 2; // Skip already paired winners
      
      for (int i = startIndex; i < availableWinners.length && nextRoundMatches.length < matchesToCreate; i += 2) {
        if (i + 1 < availableWinners.length) {
          final matchNumber = existingCount + nextRoundMatches.length + 1;
          final matchData = {
            'tournament_id': widget.tournamentId,
            'round_number': currentRound + 1,
            'match_number': matchNumber,
            'player1_id': availableWinners[i],
            'player2_id': availableWinners[i + 1],
            'status': 'pending',
            'player1_score': 0,
            'player2_score': 0,
            'winner_id': null,
          };
          nextRoundMatches.add(matchData);
          
          final p1Short = availableWinners[i].length > 8 ? availableWinners[i].substring(0, 8) : availableWinners[i];
          final p2Short = availableWinners[i + 1].length > 8 ? availableWinners[i + 1].substring(0, 8) : availableWinners[i + 1];
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } else {
          // Odd number of winners - bye for the last player
          final playerShort = availableWinners[i].length > 8 ? availableWinners[i].substring(0, 8) : availableWinners[i];
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }
      
      if (nextRoundMatches.isNotEmpty) {
        try {
          await Supabase.instance.client
              .from('matches')
              .insert(nextRoundMatches);
          
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          
          // Refresh the matches list to show new round
          await _loadMatches();
          
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } catch (e) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          rethrow;
        }
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }
  */

  Widget _buildScoreInputRow(
    String playerName,
    TextEditingController controller, {
    VoidCallback? onChanged,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          children: [
            Expanded(
              flex: 3, // Tăng không gian cho tên
              child: Text(
                playerName,
                style: TextStyle(fontSize: 13.sp),
                maxLines: 2, // Cho phép hiển thị 2 dòng
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 4.sp), // Giảm khoảng cách
            // Decrease button
            GestureDetector(
              onTap: () {
                int currentValue = int.tryParse(controller.text) ?? 0;
                if (currentValue > 0) {
                  setState(() {
                    controller.text = (currentValue - 1).toString();
                  });
                  onChanged?.call(); // Notify parent
                }
              },
              child: Container(
                width: 24.sp, // Giảm kích thước nút
                height: 24.sp,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.sp),
                  border: Border.all(
                    color: AppTheme.primaryLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.remove,
                  size: 12.sp, // Giảm kích thước icon
                  color: AppTheme.primaryLight,
                ),
              ),
            ),
            SizedBox(width: 4.sp), // Giảm khoảng cách
            // Score input
            SizedBox(
              width: 40.sp, // Giảm kích thước ô nhập
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6.sp),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 4.sp), // Giảm padding
                ),
                onChanged: (value) {
                  setState(() {});
                  onChanged?.call(); // Notify parent
                },
              ),
            ),
            SizedBox(width: 4.sp), // Giảm khoảng cách
            // Increase button
            GestureDetector(
              onTap: () {
                int currentValue = int.tryParse(controller.text) ?? 0;
                setState(() {
                  controller.text = (currentValue + 1).toString();
                });
                onChanged?.call(); // Notify parent
              },
              child: Container(
                width: 24.sp, // Giảm kích thước nút
                height: 24.sp,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.sp),
                  border: Border.all(
                    color: AppTheme.primaryLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.add,
                  size: 16.sp,
                  color: AppTheme.primaryLight,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editCompletedMatch(Map<String, dynamic> match) {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  Future<void> _autoUpdateMatchStatus(String matchId, String newStatus) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Update in database
      await Supabase.instance.client
          .from('matches')
          .update({'status': newStatus})
          .eq('id', matchId);

      // Update local state
      setState(() {
        final matchIndex = _matches.indexWhere(
          (m) => (m['id'] ?? m['matchId']) == matchId,
        );
        if (matchIndex != -1) {
          _matches[matchIndex]['status'] = newStatus;
        }
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  // 🗑️ REMOVED: _advanceWinnerDirectly()
  // This function caused duplicate player advancement - removed completely

  /// Build match progression text from database values
  String _buildMatchProgressionText(Map<String, dynamic> match) {
    final matchNumber = match['match_number'] ?? 1;
    final winnerAdvancesTo = match['winner_advances_to'];
    final loserAdvancesTo = match['loser_advances_to'];

    // Base text
    String text = 'M$matchNumber';

    // Add winner progression if exists
    if (winnerAdvancesTo != null) {
      text += ' → M$winnerAdvancesTo';

      // Add loser progression if exists (for double elimination)
      if (loserAdvancesTo != null) {
        text += ' (L→M$loserAdvancesTo)';
      }
    } else {
      // Only Grand Final (match 31) has no winner advancement
      final roundNumber = match['round_number'] ?? 0;
      if (roundNumber == 999) {
        text = 'M$matchNumber (Final)';
      }
    }

    return text;
  }

  // REMOVED: _advancePlayerToMatch() - caused duplicate advancement

  // REMOVED: _advancePlayerToMatch() - caused duplicate advancement
}

