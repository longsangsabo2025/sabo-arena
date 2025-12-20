// 🎯 SABO ARENA - Demo Bracket Screen
// Trang riêng biệt cho demo bracket với không gian hiển thị tối ưu

import 'package:flutter/material.dart';
import '../tournament_detail_screen/widgets/demo_bracket_tab.dart';
import '../../services/share_service.dart';

class DemoBracketScreen extends StatelessWidget {
  const DemoBracketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withValues(alpha: 0.3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E86AB)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E86AB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.preview,
                color: Color(0xFF2E86AB),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sơ Đồ Mẫu',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF2E86AB),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Xem trước các format bảng đấu',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareBracket(context),
            tooltip: 'Chia sẻ sơ đồ',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E86AB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'MẪU',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF2E86AB),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: const SafeArea(
        child: Padding(padding: EdgeInsets.all(16.0), child: DemoBracketTab()),
      ),
    );
  }

  Future<void> _shareBracket(BuildContext context) async {
    try {
      await ShareService.shareBracket(
        tournamentId: 'demo',
        tournamentName: 'Sơ Đồ Giải Đấu Mẫu',
        clubName: 'CLB Mẫu',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chia sẻ: $e')),
        );
      }
    }
  }
}
