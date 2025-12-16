import 'package:flutter/material.dart';
import 'package:sabo_arena/services/share_service.dart';
import 'package:sabo_arena/widgets/shareable_cards/shareable_tournament_card.dart';

/// 🧪 Rich Share Test Screen
/// Demo screen to test rich sharing functionality
class RichShareTestScreen extends StatefulWidget {
  const RichShareTestScreen({Key? key}) : super(key: key);

  @override
  State<RichShareTestScreen> createState() => _RichShareTestScreenState();
}

class _RichShareTestScreenState extends State<RichShareTestScreen> {
  bool _isSharing = false;

  // Sample tournament data
  final _sampleTournament = {
    'id': 'test_tournament_123',
    'name': 'SABO Championship 2025',
    'startDate': '2025-02-15T10:00:00',
    'participants': 32,
    'prizePool': '50,000,000 VNĐ',
    'format': 'single_elimination',
    'status': 'upcoming',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 Rich Share Test'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Rich Share Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Test sharing tournament cards with beautiful images like TikTok/Facebook.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✅ screenshot package installed\n'
                      '✅ qr_flutter package installed\n'
                      '✅ ShareableTournamentCard created\n'
                      '✅ RichShareService implemented',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Preview Card
            const Text(
              'Preview Card (Scaled Down):',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Transform.scale(
                scale: 0.3,
                child: SizedBox(
                  width: 1080,
                  height: 1920,
                  child: ShareableTournamentCard(
                    tournamentId: _sampleTournament['id'] as String,
                    tournamentName: _sampleTournament['name'] as String,
                    startDate: _sampleTournament['startDate'] as String,
                    participants: _sampleTournament['participants'] as int,
                    prizePool: _sampleTournament['prizePool'] as String,
                    format: _sampleTournament['format'] as String,
                    status: _sampleTournament['status'] as String,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Share Buttons
            ElevatedButton.icon(
              onPressed: _isSharing ? null : () => _shareRich(context),
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share),
              label: Text(_isSharing ? 'Đang xử lý...' : 'Share với Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _isSharing ? null : () => _shareTextOnly(context),
              icon: const Icon(Icons.text_fields),
              label: const Text('Share Text Only (Legacy)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'How to Test',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Tap "Share với Image"\n'
                      '2. Wait for processing (3-5 seconds)\n'
                      '3. Share dialog opens with image preview\n'
                      '4. Choose app (WhatsApp, Facebook, etc.)\n'
                      '5. Verify image shows tournament card\n'
                      '6. Compare with "Text Only" mode',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '💡 Tip: Share to yourself first to test',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareRich(BuildContext context) async {
    setState(() => _isSharing = true);

    try {
      final result = await ShareService.shareTournamentRich(
        tournamentId: _sampleTournament['id'] as String,
        tournamentName: _sampleTournament['name'] as String,
        startDate: _sampleTournament['startDate'] as String,
        participants: _sampleTournament['participants'] as int,
        prizePool: _sampleTournament['prizePool'] as String,
        format: _sampleTournament['format'] as String,
        status: _sampleTournament['status'] as String,
        context: context,
      );

      setState(() => _isSharing = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result != null
                ? '✅ Share completed: ${result.status}'
                : '⚠️ Share cancelled or failed',
          ),
          backgroundColor:
              result != null ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _isSharing = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _shareTextOnly(BuildContext context) async {
    try {
      await ShareService.shareTournament(
        tournamentId: _sampleTournament['id'] as String,
        tournamentName: _sampleTournament['name'] as String,
        startDate: _sampleTournament['startDate'] as String,
        participants: _sampleTournament['participants'] as int,
        prizePool: _sampleTournament['prizePool'] as String,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Text-only share completed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
