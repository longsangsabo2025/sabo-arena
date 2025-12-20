// 🎯 SABO ARENA - Demo Bracket Visualization Tab
// Cho phép CLB owner xem trước các format bảng đấu với data mẫu

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'demo_bracket/formats/single_elimination_bracket.dart';
import 'demo_bracket/formats/double_elimination_bracket.dart';
import 'demo_bracket/formats/de8_demo_wrapper.dart';
import 'demo_bracket/formats/de16_demo_wrapper.dart';
import 'demo_bracket/formats/de32_bracket_simple.dart';
import 'demo_bracket/formats/de64_bracket_simple.dart';
import 'demo_bracket/formats/round_robin_bracket.dart';
import 'demo_bracket/formats/swiss_system_bracket.dart';
import 'demo_bracket/formats/group_knockout_bracket.dart';
import 'demo_bracket/formats/song_to_bracket.dart';
import 'demo_bracket/formats/mosconi_bracket.dart';
import 'demo_bracket/components/bracket_components.dart';
import 'demo_bracket/shared/tournament_data_generator.dart';

class DemoBracketTab extends StatefulWidget {
  const DemoBracketTab({super.key});

  @override
  State<DemoBracketTab> createState() => _DemoBracketTabState();
}

class _DemoBracketTabState extends State<DemoBracketTab> {
  String _selectedFormat = 'single_elimination';
  int _selectedPlayerCount = 8;

  final Map<String, Map<String, String>> _formats = {
    'single_elimination': {
      'name': 'Single Elimination',
      'emoji': '🏆',
      'description': 'Thua là loại ngay, nhanh gọn',
      'badge': '⭐ PHỔ BIẾN',
      'recommended': 'true',
    },
    'double_elimination': {
      'name': 'Double Elimination',
      'emoji': '🎯',
      'description': 'Thua 2 lần mới bị loại',
    },
    'de8': {
      'name': 'SABO DE8',
      'emoji': '⚔️',
      'description': 'SABO: 8 người • 13 trận',
    },
    'de16': {
      'name': 'SABO DE16',
      'emoji': '⚡',
      'description': 'SABO: 16 người • 27 trận',
      'badge': '⭐ PHỔ BIẾN',
      'recommended': 'true',
    },
    'de32': {
      'name': 'SABO DE32',
      'emoji': '🔥',
      'description': 'SABO: 32 người • 55 trận',
      'badge': '⭐ PHỔ BIẾN',
      'recommended': 'true',
    },
    'de64': {
      'name': 'SABO DE64',
      'emoji': '🚀',
      'description': 'SABO: 64 người • 111 trận',
      'badge': '🏆 PRO',
      'recommended': 'false',
    },
    'round_robin': {
      'name': 'Round Robin',
      'emoji': '🔄',
      'description': 'Đấu vòng tròn, tính điểm',
    },
    'swiss': {
      'name': 'Swiss System',
      'emoji': '🇨🇭',
      'description': 'Ghép đối thủ cùng trình',
    },
    'group_knockout': {
      'name': 'Group + Knockout',
      'emoji': '📊',
      'description': 'Vòng bảng → loại trực tiếp',
    },
    'song_to': {
      'name': '14-1 Straight Pool (Song tô)',
      'emoji': '🎱',
      'description': 'Tích điểm đến 100, kinh điển billiards',
    },
    'mosconi': {
      'name': 'Mosconi Cup',
      'emoji': '🏅',
      'description': 'Đấu đồng đội theo format Mosconi',
    },
  };

  final List<int> _playerCounts = [8, 16, 32, 64];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          // Collapsible Header
          SliverAppBar(
            backgroundColor: Colors.white,
            pinned: false,
            floating: true,
            snap: true,
            elevation: 0,
            expandedHeight: 220, // Increased to fit content
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(background: _buildControls()),
          ),

          // Bracket Content
          SliverFillRemaining(hasScrollBody: true, child: _buildBracketView()),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E6EB), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0866FF), Color(0xFF0B5ED7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_tree,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Các định dạng giải đấu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF050505),
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Xem trước các hình thức thi đấu với dữ liệu mẫu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF65676B),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Format & Player Count Selectors (Compact Row)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Format Selector (60% width)
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hình thức thi đấu',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF050505),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildCompactFormatSelector(),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Player Count Selector (40% width)
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Số người chơi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF050505),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildCompactPlayerCountSelector(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Compact format selector (for row layout)
  Widget _buildCompactFormatSelector() {
    final Map<String, String> selectedFormat = _formats[_selectedFormat]!;

    return GestureDetector(
      onTap: () => _showFormatPicker(),
      child: Container(
        height: 56, // Fixed height
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF0866FF).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Emoji
            Text(
              selectedFormat['emoji']!,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            // Text
            Expanded(
              child: Text(
                selectedFormat['name']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF050505),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            // Arrow
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF65676B),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Compact player count selector (for row layout)
  Widget _buildCompactPlayerCountSelector() {
    return Container(
      height: 56, // Fixed height
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF0866FF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedPlayerCount,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF65676B),
            size: 20,
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF050505),
            letterSpacing: -0.3,
          ),
          dropdownColor: Colors.white,
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPlayerCount = newValue;
              });
            }
          },
          items: _playerCounts.map((count) {
            return DropdownMenuItem<int>(value: count, child: Text('$count'));
          }).toList(),
        ),
      ),
    );
  }

  /* Widget _buildModernFormatSelector() {
    final Map<String, String> selectedFormat = _formats[_selectedFormat]!;

    return GestureDetector(
      onTap: () => _showFormatPicker(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF0866FF).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Emoji
            Text(
              selectedFormat['emoji']!,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedFormat['name']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF050505),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedFormat['description']!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF65676B),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF65676B),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPlayerCountSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0866FF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedPlayerCount,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF65676B),
            size: 24,
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF050505),
            letterSpacing: -0.3,
          ),
          dropdownColor: Colors.white,
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPlayerCount = newValue;
              });
            }
          },
          items: _playerCounts.map((count) {
            return DropdownMenuItem<int>(
              value: count,
              child: Text('$count người chơi'),
            );
          }).toList(),
        ),
      ),
    );
  } */

  void _showFormatPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFF0F2F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCED0D4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE4E6EB), width: 1),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chọn hình thức thi đấu',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF050505),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Format list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _formats.entries.map((entry) {
                  final isSelected = entry.key == _selectedFormat;
                  return _buildFormatOption(
                    key: entry.key,
                    emoji: entry.value['emoji']!,
                    name: entry.value['name']!,
                    description: entry.value['description']!,
                    isSelected: isSelected,
                    badge: entry.value['badge'],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption({
    required String key,
    required String emoji,
    required String name,
    required String description,
    required bool isSelected,
    String? badge,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFormat = key;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0866FF) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0866FF)
                                : const Color(0xFF050505),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF65676B),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF0866FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBracketView() {
    try {
      switch (_selectedFormat) {
        case 'single_elimination':
          return _buildSingleEliminationBracket();
        case 'double_elimination':
          return _buildDoubleEliminationBracket();
        case 'de8':
          return _buildDE8Bracket();
        case 'de16':
          return _buildDE16Bracket();
        case 'de32':
          return _buildDE32Bracket();
        case 'de64':
          return _buildDE64Bracket();
        case 'round_robin':
          return _buildRoundRobinBracket();
        case 'swiss':
          return _buildSwissBracket();
        case 'group_knockout':
          return _buildGroupKnockoutBracket();
        case 'song_to':
          return _buildSongToBracket();
        case 'mosconi':
          return _buildMosconiBracket();
        default:
          return _buildSingleEliminationBracket();
      }
    } catch (e) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 16),
              const Text(
                'Có lỗi xảy ra',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF050505),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF65676B)),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSingleEliminationBracket() {
    return SingleEliminationBracket(
      playerCount: _selectedPlayerCount,
      onFullscreenTap: _showFullscreenBracket,
    );
  }

  Widget _buildDoubleEliminationBracket() {
    // Traditional Double Elimination
    return DoubleEliminationBracket(
      playerCount: _selectedPlayerCount,
      onFullscreenTap: _showFullscreenBracket,
    );
  }

  Widget _buildDE8Bracket() {
    // SABO Arena special: DE8 with sample data
    return const DE8DemoWrapper();
  }

  Widget _buildDE16Bracket() {
    // SABO Arena special: DE16 with sample data
    return const DE16DemoWrapper();
  }

  Widget _buildDE32Bracket() {
    // SABO Arena special: DE32 Two-Group System
    return const DE32Bracket();
  }

  Widget _buildDE64Bracket() {
    // SABO Arena special: DE64 Four-Group System
    return const DE64Bracket();
  }

  Widget _buildGroupKnockoutBracket() {
    return const GroupKnockoutBracket();
  }

  Widget _buildSongToBracket() {
    return const SongToBracket();
  }

  Widget _buildMosconiBracket() {
    return const MosconiBracket();
  }

  Widget _buildRoundRobinBracket() {
    return RoundRobinBracket(
      playerCount: _selectedPlayerCount,
      onFullscreenTap: _showFullscreenBracket,
    );
  }

  Widget _buildSwissBracket() {
    return SwissSystemBracket(
      playerCount: _selectedPlayerCount,
      onFullscreenTap: _showFullscreenBracket,
    );
  }

  void _showFullscreenBracket() async {
    // Tạo URL để xem bracket full screen trên web
    String webUrl = _generateBracketWebUrl();

    try {
      final Uri url = Uri.parse(webUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: Hiển thị dialog như cũ nếu không thể mở web
        _showFullscreenDialog();
      }
    } catch (e) {
      // Fallback: Hiển thị dialog như cũ nếu có lỗi
      _showFullscreenDialog();
    }
  }

  String _generateBracketWebUrl() {
    // Tạo URL web cho SABO Arena website
    // Hiện tại dẫn về trang chủ vì chưa có bracket viewer riêng
    const String baseUrl = 'https://saboarena.com';

    return '$baseUrl?ref=app_demo_bracket&format=$_selectedFormat&players=$_selectedPlayerCount';
  }

  void _showFullscreenDialog() {
    Widget dialog;

    switch (_selectedFormat) {
      case 'single_elimination':
        dialog = SingleEliminationFullscreenDialog(
          playerCount: _selectedPlayerCount,
        );
        break;
      case 'double_elimination':
        // SABO Arena rule: Double Elimination with 32 players uses DE32 format
        if (_selectedPlayerCount == 32) {
          dialog = _buildDE32FullscreenDialog();
        } else {
          dialog = _buildDoubleEliminationFullscreenDialog();
        }
        break;
      case 'round_robin':
        dialog = RoundRobinFullscreenDialog(playerCount: _selectedPlayerCount);
        break;
      case 'swiss':
        dialog = SwissSystemFullscreenDialog(playerCount: _selectedPlayerCount);
        break;
      default:
        dialog = SingleEliminationFullscreenDialog(
          playerCount: _selectedPlayerCount,
        );
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => dialog,
    );
  }

  void _showDoubleEliminationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Double Elimination'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hình thức thi đấu loại kép',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '🎯 Nguyên tắc cơ bản:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text('• Mỗi người chơi có 2 cơ hội'),
              Text('• Thua 1 lần = rớt xuống Losers Bracket'),
              Text('• Thua 2 lần = bị loại khỏi giải đấu'),
              Text('• Winner WB vs Winner LB ở Grand Final'),
              SizedBox(height: 12),
              Text(
                '🏆 Winners Bracket (WB):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text('• Player chưa thua lần nào'),
              Text('• Thua = rớt xuống Losers Bracket'),
              Text('• Thắng = tiến lên vòng tiếp theo'),
              Text('• Winner WB Final vào Grand Final'),
              SizedBox(height: 12),
              Text(
                '⚡ Losers Bracket (LB):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 4),
              Text('• Player đã thua 1 lần từ WB'),
              Text('• Thua thêm 1 lần = bị loại'),
              Text('• Thắng = có cơ hội phục sinh'),
              Text('• Winner LB Final vào Grand Final'),
              SizedBox(height: 12),
              Text(
                '🏅 Grand Final:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 4),
              Text('• Winner WB vs Winner LB'),
              Text('• Nếu Winner WB thắng = Vô địch'),
              Text('• Nếu Winner LB thắng = Reset bracket'),
              Text('• Reset bracket = đấu thêm 1 trận'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleEliminationFullscreenDialog() {
    // Use the SAME logic as the main bracket display
    final winnersRounds =
        TournamentDataGenerator.calculateDoubleEliminationWinners(
      _selectedPlayerCount,
    );
    final losersRounds =
        TournamentDataGenerator.calculateDoubleEliminationLosers(
      _selectedPlayerCount,
    );
    final grandFinalRounds =
        TournamentDataGenerator.calculateDoubleEliminationGrandFinal(
      _selectedPlayerCount,
    );

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Double Elimination - $_selectedPlayerCount Players'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showDoubleEliminationInfo(),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Winners Bracket
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Winners Bracket',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: winnersRounds
                              .map(
                                (round) => Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  child: RoundColumn(
                                    title: round['title'] ?? 'Round',
                                    matches: List<Map<String, String>>.from(
                                      round['matches'] ?? [],
                                    ),
                                    isFullscreen: true,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Losers Bracket
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.orange.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_down,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Losers Bracket',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      losersRounds.isNotEmpty
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: losersRounds
                                    .map(
                                      (round) => Container(
                                        margin: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: RoundColumn(
                                          title: round['title'] ?? 'Round',
                                          matches:
                                              List<Map<String, String>>.from(
                                            round['matches'] ?? [],
                                          ),
                                          isFullscreen: true,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(32),
                              child: const Center(
                                child: Text(
                                  'Losers bracket will populate as players are eliminated from Winners Bracket',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),

                // Grand Final
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.purple.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.military_tech,
                            color: Colors.purple,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Grand Final',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: grandFinalRounds
                              .map(
                                (round) => Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  child: RoundColumn(
                                    title: round['title'] ?? 'Grand Final',
                                    matches: List<Map<String, String>>.from(
                                      round['matches'] ?? [],
                                    ),
                                    isFullscreen: true,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDE32FullscreenDialog() {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SABO Double Elimination DE32'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showDE32Info(),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tournament Info
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo[50]!, Colors.indigo[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspaces,
                        color: Colors.indigo[700],
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SABO DE32 Two-Group Tournament System',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '32 players • 2 groups of 16 • 55 total matches\n'
                              'Each group: Modified DE16 → 2 qualifiers\n'
                              'Cross-Bracket: 4 qualifiers → 1 champion',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.indigo[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Group A Section
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.blue.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'GROUP A',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '16 players • 26 matches • Modified DE16 Format',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Structure: Winners Bracket (15 matches) + Losers Bracket (11 matches)\n'
                        'Produces: Group Winner (1st) + Group Runner-up (2nd)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Group B Section
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'GROUP B',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '16 players • 26 matches • Modified DE16 Format',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Structure: Winners Bracket (15 matches) + Losers Bracket (11 matches)\n'
                        'Produces: Group Winner (1st) + Group Runner-up (2nd)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cross-Bracket Finals Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.purple.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CROSS-BRACKET FINALS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '4 qualifiers • 3 matches (2 Semis + 1 Final)',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.purple[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bracket Structure:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Semifinal 1: Group A Winner vs Group B Winner\n'
                            '• Semifinal 2: Group A Runner-up vs Group B Runner-up\n'
                            '• DE32 Final: SF1 Winner vs SF2 Winner',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.purple[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDE32Info() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspaces, color: Colors.indigo),
            SizedBox(width: 8),
            Text('SABO DE32 Tournament'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SABO Double Elimination DE32',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '🎯 Tournament Structure:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              SizedBox(height: 4),
              Text('• 32 players split into 2 groups (A & B)'),
              Text('• Each group: 16 players, modified DE16 format'),
              Text('• Group matches: 26 per group (52 total)'),
              Text('• Cross-bracket finals: 3 matches'),
              Text('• Total tournament: 55 matches'),
              SizedBox(height: 12),
              Text(
                '🏆 Group Phase:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 4),
              Text('• Winners Bracket: 15 matches per group'),
              Text('• Losers Bracket: 11 matches per group'),
              Text('• Each group produces 2 qualifiers'),
              Text('• 1st place: Group Winner'),
              Text('• 2nd place: Group Runner-up'),
              SizedBox(height: 12),
              Text(
                '⚡ Cross-Bracket Finals:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 4),
              Text('• SF1: Group A Winner vs Group B Runner-up'),
              Text('• SF2: Group A Runner-up vs Group B Winner'),
              Text('• Final: SF1 Winner vs SF2 Winner'),
              Text('• Single elimination format'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
