import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/bracket_visualization_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Native Flutter Full Tournament Bracket Screen
/// Displays complete tournament bracket in landscape mode
class FullTournamentBracketScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentTitle;

  const FullTournamentBracketScreen({
    Key? key,
    required this.tournamentId,
    required this.tournamentTitle,
  }) : super(key: key);

  @override
  State<FullTournamentBracketScreen> createState() =>
      _FullTournamentBracketScreenState();
}

class _FullTournamentBracketScreenState
    extends State<FullTournamentBracketScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _errorMessage;
  Widget? _bracketWidget;
  String? _bracketFormat;
  int _matchCount = 0;

  @override
  void initState() {
    super.initState();
    _setLandscapeOrientation();
    _loadTournamentData();
  }

  @override
  void dispose() {
    // Restore all orientations when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _setLandscapeOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      ProductionLogger.info('✅ Landscape orientation set',
          tag: 'full_tournament_bracket_screen');
    } catch (e) {
      ProductionLogger.info('⚠️ Failed to set landscape: $e',
          tag: 'full_tournament_bracket_screen');
    }
  }

  Future<void> _loadTournamentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      ProductionLogger.info(
          '🔍 Loading full tournament: ${widget.tournamentId}',
          tag: 'full_tournament_bracket_screen');

      // 1. Get tournament format
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('bracket_format')
          .eq('id', widget.tournamentId)
          .maybeSingle();

      final bracketFormat =
          tournamentResponse?['bracket_format'] ?? 'sabo_de64';
      ProductionLogger.info('📊 Tournament format: $bracketFormat',
          tag: 'full_tournament_bracket_screen');

      // 2. Get all matches (simple query first, then enhance if needed)
      final matchesResponse = await _supabase.from('matches').select('''
            id,
            round_number,
            match_number,
            bracket_type,
            bracket_group,
            player1_id,
            player2_id,
            winner_id,
            status,
            player1_score,
            player2_score,
            bracket_position
          ''').eq('tournament_id', widget.tournamentId).order('round_number');

      final matchesData = matchesResponse as List<dynamic>;
      ProductionLogger.info('✅ Loaded ${matchesData.length} matches',
          tag: 'full_tournament_bracket_screen');

      // 3. For now, use simple match data without player profiles
      final matches = matchesData.map<Map<String, dynamic>>((match) {
        return {
          ...match,
          'player1_name': match['player1_id'] != null ? 'Player 1' : 'TBD',
          'player2_name': match['player2_id'] != null ? 'Player 2' : 'TBD',
        };
      }).toList();

      // 4. Build bracket widget using BracketVisualizationService
      final bracketWidget =
          await BracketVisualizationService.instance.buildTournamentBracket(
        tournamentId: widget.tournamentId,
        bracketData: {
          'id': widget.tournamentId,
          'format': bracketFormat,
          'matches': matches,
        },
        onMatchTap: () {
          // No action needed - just display
        },
      );

      setState(() {
        _bracketWidget = bracketWidget;
        _bracketFormat = bracketFormat;
        _matchCount = matches.length;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      ProductionLogger.info('❌ Error loading tournament: $e',
          tag: 'full_tournament_bracket_screen');
      ProductionLogger.info('Stack trace: $stackTrace',
          tag: 'full_tournament_bracket_screen');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.tournamentTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTournamentData,
          ),
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showDebugInfo,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF26D0CE)),
            SizedBox(height: 16),
            Text(
              'Đang tải bracket...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Lỗi tải dữ liệu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTournamentData,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26D0CE),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_bracketWidget == null) {
      return const Center(
        child: Text(
          'Không có dữ liệu bracket',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Display the bracket with horizontal and vertical scrolling
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4.0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _bracketWidget!,
          ),
        ),
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Debug Info',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDebugItem('Tournament ID', widget.tournamentId),
              _buildDebugItem('Title', widget.tournamentTitle),
              _buildDebugItem('Format', _bracketFormat ?? 'N/A'),
              _buildDebugItem('Total Matches', _matchCount.toString()),
              _buildDebugItem('Orientation', 'Landscape Only'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đóng',
              style: TextStyle(color: Color(0xFF26D0CE)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFF26D0CE),
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
