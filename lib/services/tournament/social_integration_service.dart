import '../social_service.dart';
// ELON_MODE_AUTO_FIX

/// Service for creating social posts about tournament completion
class SocialIntegrationService {
  final SocialService _socialService = SocialService.instance;

  /// Create social posts for tournament completion
  Future<void> createCompletionPosts({
    required String tournamentId,
    required List<Map<String, dynamic>> standings,
    required Map<String, dynamic> tournament,
  }) async {

    try {
      if (standings.isEmpty) {
        return;
      }

      final tournamentTitle = tournament['title'] as String? ?? 'Tournament';
      final organizerId = tournament['organizer_id'] as String?;
      final clubId = tournament['club_id'] as String?;
      final participantCount = standings.length;
      final champion = standings.first;
      final championName = champion['participant_name'] as String? ?? 'Champion';

      // Create completion post by club (if tournament belongs to club) or organizer
      if (organizerId != null) {
        final postContent = '''🏆 Giải đấu "$tournamentTitle" đã kết thúc!

🥇 Vô địch: $championName
👥 Tham gia: $participantCount người chơi
🎉 Chúc mừng tất cả các vận động viên!

#SABOArena #Tournament #Champion''';

        await _socialService.createPost(
          content: postContent,
          postType: 'tournament_completion',
          tournamentId: tournamentId,
          clubId: clubId, // Post belongs to club if tournament is club tournament
          hashtags: [
            'SABOArena',
            'Tournament',
            'Champion',
            tournamentTitle.replaceAll(' ', ''),
          ],
        );

      } else {
      }
    } catch (e) {
      // Don't rethrow - social posts are not critical
    }
  }
}

