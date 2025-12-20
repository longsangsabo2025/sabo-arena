import 'package:supabase_flutter/supabase_flutter.dart';
import '../chat_service.dart';
import '../../utils/number_formatter.dart';
// ELON_MODE_AUTO_FIX

/// Service for sending congratulatory chat messages
class ChatIntegrationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send congratulatory chat messages to top performers
  Future<void> sendCongratulatoryChatMessages({
    required String tournamentId,
    required List<Map<String, dynamic>> standings,
    required List<Map<String, dynamic>> prizeRecipients,
    required Map<String, dynamic> tournament,
  }) async {
    try {
      final tournamentTitle = tournament['title'] as String? ?? 'Tournament';
      final clubId = tournament['club_id'] as String?;

      if (clubId == null) {
        return;
      }

      // Get or create tournament announcement chat room
      final chatRoom = await _getOrCreateTournamentChatRoom(
        tournamentId,
        clubId,
        tournamentTitle,
      );

      if (chatRoom == null) {
        return;
      }

      final roomId = chatRoom['id'] as String;

      // Send congratulatory messages for top 4 positions
      final topPerformers = prizeRecipients.where((p) {
        final pos = p['position'] as int;
        return pos <= 4; // Top 4 to include tied 3rd place
      }).toList();

      for (final performer in topPerformers) {
        final position = performer['position'] as int;
        final participantId = performer['participant_id'] as String;
        final prizeVND = performer['prize_money_vnd'] ?? 0;
        final bonusSPA = performer['position_bonus_spa'] ?? 0;

        // Get participant name
        final participant = standings.firstWhere(
          (s) => s['participant_id'] == participantId,
          orElse: () => {'participant_name': 'Player'},
        );
        final participantName = participant['participant_name'] ?? 'Player';

        // Build congratulatory message based on position
        String message;
        if (position == 1) {
          message = '''🏆🎉 CHÚC MỪNG VÔ ĐỊCH! 🎉🏆

👑 **$participantName** đã xuất sắc giành chức vô địch giải đấu "$tournamentTitle"!

🎁 Phần thưởng:
💰 ${NumberFormatter.formatCurrency(prizeVND)} VND
⭐ ${NumberFormatter.formatCurrency(bonusSPA)} SPA

Chúc mừng nhà vô địch! 🔥🏅''';
        } else if (position == 2) {
          message = '''🥈✨ CHÚC MỪNG Á QUÂN! ✨🥈

🌟 **$participantName** đã đạt vị trí Á quân tại giải đấu "$tournamentTitle"!

🎁 Phần thưởng:
💰 ${NumberFormatter.formatCurrency(prizeVND)} VND
⭐ ${NumberFormatter.formatCurrency(bonusSPA)} SPA

Thành tích xuất sắc! 👏''';
        } else if (position == 3 || position == 4) {
          message = '''🥉🎖️ CHÚC MỪNG ĐỒNG HẠNG 3! 🎖️🥉

💪 **$participantName** đã giành vị trí thứ $position (Đồng hạng 3) tại giải đấu "$tournamentTitle"!

🎁 Phần thưởng:
💰 ${NumberFormatter.formatCurrency(prizeVND)} VND
⭐ ${NumberFormatter.formatCurrency(bonusSPA)} SPA

Chúc mừng! 🎉''';
        } else {
          continue; // Skip positions > 4
        }

        // Send message to chat room
        await ChatService.sendMessage(
          roomId: roomId,
          message: message,
          messageType: 'tournament_completion',
        );

        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Send final summary message
      final summaryMessage = '''📊 **KẾT QUẢ GIẢI ĐẤU "$tournamentTitle"** 📊

${standings.take(5).map((s) {
        final pos = standings.indexOf(s) + 1;
        final name = s['participant_name'];
        final wins = s['wins'] ?? 0;
        final losses = s['losses'] ?? 0;
        String medal = '';
        if (pos == 1)
          medal = '🥇';
        else if (pos == 2)
          medal = '🥈';
        else if (pos == 3 || pos == 4) medal = '🥉';
        return '$medal #$pos: **$name** ($wins-$losses)';
      }).join('\n')}

Cảm ơn tất cả các vận động viên đã tham gia! 🙏
#SABOArena #Tournament''';

      await ChatService.sendMessage(
        roomId: roomId,
        message: summaryMessage,
        messageType: 'tournament_summary',
      );
    } catch (e) {
      // Don't rethrow - chat messages are not critical
    }
  }

  /// Get or create chat room for tournament announcements
  Future<Map<String, dynamic>?> _getOrCreateTournamentChatRoom(
    String tournamentId,
    String clubId,
    String tournamentTitle,
  ) async {
    try {
      // Try to find existing tournament chat room
      final existingRooms = await _supabase
          .from('chat_rooms')
          .select()
          .eq('club_id', clubId)
          .eq('type', 'tournament')
          .eq('is_active', true)
          .limit(1);

      if (existingRooms.isNotEmpty) {
        return existingRooms.first;
      }

      // Create new tournament announcement room
      final newRoom = await ChatService.createChatRoom(
        clubId: clubId,
        name: 'Thông báo giải đấu',
        description: 'Kênh thông báo kết quả và chúc mừng các giải đấu',
        type: 'tournament',
        isPrivate: false,
      );

      return newRoom;
    } catch (e) {
      return null;
    }
  }
}
