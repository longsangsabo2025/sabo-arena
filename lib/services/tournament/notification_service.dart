import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/number_formatter.dart';
// ELON_MODE_AUTO_FIX

/// 🚀 ELON MODE: Direct notification service for tournament completion
/// Sends PERSONAL notifications to each player about their rewards
/// No more hoping they check the chat room
class TournamentNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send completion notifications to ALL tournament participants
  /// Each player gets a DIRECT notification about their rewards
  Future<void> sendTournamentCompletionNotifications({
    required String tournamentId,
    required List<Map<String, dynamic>> standings,
    required Map<String, dynamic> tournament,
  }) async {
    try {
      final tournamentTitle = tournament['title'] as String? ?? 'Tournament';

      // Send notification to EACH player
      for (final standing in standings) {
        try {
          await _sendPlayerRewardNotification(
            userId: standing['participant_id'] as String,
            tournamentId: tournamentId,
            tournamentTitle: tournamentTitle,
            position: standing['position'] as int,
            spaReward: standing['spa_reward'] as int? ?? 0,
            eloChange: standing['elo_change'] as int? ?? 0,
            prizeMoney:
                (standing['prize_money_vnd'] as num?)?.toDouble() ?? 0.0,
            voucherCode: standing['voucher_code'] as String?,
          );
        } catch (e) {
          // Don't fail entire batch if one notification fails
          continue;
        }
      }
    } catch (e) {
      // Don't fail tournament completion if notifications fail
    }
  }

  /// Send personal notification to one player
  Future<void> _sendPlayerRewardNotification({
    required String userId,
    required String tournamentId,
    required String tournamentTitle,
    required int position,
    required int spaReward,
    required int eloChange,
    required double prizeMoney,
    String? voucherCode,
  }) async {
    // Build notification title and message based on position
    String title;
    String message;
    String icon;

    if (position == 1) {
      title = '🏆 CHAMPION!';
      icon = 'trophy';
      message = 'Congratulations! You won "$tournamentTitle"!\n\n'
          '🎁 Rewards:\n'
          '⭐ +$spaReward SPA\n'
          '📈 +$eloChange ELO\n';
      if (prizeMoney > 0) {
        message += '💰 ${NumberFormatter.formatCurrency(prizeMoney)} VND\n';
      }
      if (voucherCode != null) {
        message += '🎟️ Voucher: $voucherCode\n';
      }
    } else if (position == 2) {
      title = '🥈 Runner-up!';
      icon = 'medal';
      message = 'Great performance in "$tournamentTitle"! 2nd place!\n\n'
          '🎁 Rewards:\n'
          '⭐ +$spaReward SPA\n'
          '📈 +$eloChange ELO\n';
      if (prizeMoney > 0) {
        message += '💰 ${NumberFormatter.formatCurrency(prizeMoney)} VND\n';
      }
      if (voucherCode != null) {
        message += '🎟️ Voucher: $voucherCode\n';
      }
    } else if (position <= 4) {
      title = '🥉 Top 4!';
      icon = 'medal';
      message = 'You finished #$position in "$tournamentTitle"!\n\n'
          '🎁 Rewards:\n'
          '⭐ +$spaReward SPA\n'
          '📈 +$eloChange ELO\n';
      if (prizeMoney > 0) {
        message += '💰 ${NumberFormatter.formatCurrency(prizeMoney)} VND\n';
      }
      if (voucherCode != null) {
        message += '🎟️ Voucher: $voucherCode\n';
      }
    } else {
      title = '🎯 Tournament Completed';
      icon = 'info';
      message = 'You finished #$position in "$tournamentTitle".\n\n'
          '🎁 Rewards:\n'
          '⭐ +$spaReward SPA\n'
          '📈 ${eloChange >= 0 ? '+' : ''}$eloChange ELO\n';
      if (prizeMoney > 0) {
        message += '💰 ${NumberFormatter.formatCurrency(prizeMoney)} VND\n';
      }
    }

    // Create notification record in database
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'type': 'tournament_completion',
      'title': title,
      'message': message,
      'icon': icon,
      'data': {
        'tournament_id': tournamentId,
        'tournament_title': tournamentTitle,
        'position': position,
        'spa_reward': spaReward,
        'elo_change': eloChange,
        'prize_money': prizeMoney,
        'voucher_code': voucherCode,
      },
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    // TODO: Send push notification via FCM (if user has device token)
    // await _sendPushNotification(userId, title, message);
  }

  /// Send push notification via Firebase Cloud Messaging
  /// TODO: Implement FCM integration
  // Future<void> _sendPushNotification(String userId, String title, String message) async {
  //   // Get user's FCM token from database
  //   final tokenResponse = await _supabase
  //       .from('user_devices')
  //       .select('fcm_token')
  //       .eq('user_id', userId)
  //       .maybeSingle();
  //
  //   if (tokenResponse == null) return;
  //
  //   final fcmToken = tokenResponse['fcm_token'] as String?;
  //   if (fcmToken == null) return;
  //
  //   // Send FCM message
  //   // await FirebaseMessaging.instance.sendMessage(...);
  // }
}
