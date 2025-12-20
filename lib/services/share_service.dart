import 'package:share_plus/share_plus.dart';
import 'package:sabo_arena/models/user_profile.dart';
import 'referral_service.dart';
import 'rich_share_service.dart';
import 'package:flutter/material.dart';
import '../widgets/shareable_cards/shareable_tournament_card.dart';
import '../widgets/shareable_cards/shareable_profile_card.dart';
import '../widgets/shareable_cards/shareable_tournament_match_card.dart';
import '../widgets/shareable_cards/shareable_post_card.dart';
// ELON_MODE_AUTO_FIX

class ShareService {
  static const String _baseUrl = 'https://saboarena.com';

  /// Generate unique code for user
  static String generateUserCode(String userId) {
    // Generate SABO prefix + last 6 chars of userId
    final shortId =
        userId.length > 6 ? userId.substring(userId.length - 6) : userId;
    return 'SABO${shortId.toUpperCase()}';
  }

  /// 🎨 Share user profile with IMAGE (Rich Share - NEW)
  /// Creates a beautiful 4:5 ratio card optimized for social media
  static Future<ShareResult?> shareUserProfileRich(
    UserProfile user, {
    BuildContext? context,
  }) async {
    try {
      final userCode = generateUserCode(user.id);

      // Create shareable card widget (4:5 ratio)
      final cardWidget = ShareableProfileCard(
        user: user,
        qrCodeData: user.id,
      );

      // Generate share text
      final shareText = '''
🏆 Hãy thách đấu với tôi trên SABO ARENA!

👤 ${user.fullName}
🎯 Rank: ${user.rank ?? 'Chưa xếp hạng'}
⚡ ELO: ${user.eloRating}
🏅 Thắng/Thua: ${user.totalWins}/${user.totalLosses}
🎪 Tournament: ${user.totalTournaments}

🔗 ID: $userCode
📱 Tải app: $_baseUrl/download
🤝 Kết nối: $_baseUrl/user/${user.id}

#SABOArena #Badminton #ThachDau
''';

      // Share with image + analytics
      return await RichShareService.shareWidgetAsImage(
        widget: cardWidget,
        text: shareText,
        filename: 'share_profile_${user.id}',
        context: context,
        subject: 'Thách đấu cùng ${user.fullName} trên SABO ARENA',
        contentType: 'user_profile',
        contentId: user.id,
      );
    } catch (e) {
      // Fallback to text-only share
      await shareUserProfile(user);
      return null;
    }
  }

  /// 🏸 Share tournament match with IMAGE (Rich Share - NEW)
  /// Creates 4:5 ratio card for semifinals and finals only
  static Future<ShareResult?> shareTournamentMatchRich({
    required String matchId,
    required String tournamentId,
    required String tournamentName,
    required String clubName,
    required String player1Name,
    required String player2Name,
    String? player1Avatar,
    String? player2Avatar,
    int? player1Score,
    int? player2Score,
    required String matchType, // 'semifinal' or 'final'
    DateTime? matchDate,
    bool isLive = false,
    BuildContext? context,
  }) async {
    try {
      // Create shareable match card widget (4:5 ratio)
      final cardWidget = ShareableMatchCard(
        tournamentName: tournamentName,
        player1Name: player1Name,
        player2Name: player2Name,
        player1Avatar: player1Avatar,
        player2Avatar: player2Avatar,
        player1Score: player1Score,
        player2Score: player2Score,
        matchType: matchType,
        matchDate: matchDate?.toString() ?? '',
        isLive: isLive,
        clubName: clubName,
      );

      // Generate share text based on match status
      String shareText;
      final matchTypeLabel = matchType == 'final' ? 'CHUNG KẾT' : 'BÁN KẾT';

      if (isLive) {
        shareText = '''
🔴 ĐANG DIỄN RA!

🏸 $matchTypeLabel - $tournamentName

⚔️ $player1Name vs $player2Name

📍 $clubName
📺 Theo dõi trực tiếp trên SABO ARENA

📱 $_baseUrl/tournament/$tournamentId/match/$matchId

#SABOArena #Badminton #LiveMatch
''';
      } else if (player1Score != null && player2Score != null) {
        // Match finished
        final winner = player1Score > player2Score ? player1Name : player2Name;
        shareText = '''
✅ KẾT QUẢ $matchTypeLabel

🏸 $tournamentName

🥇 $player1Name: $player1Score
🥈 $player2Name: $player2Score

🎉 Chúc mừng $winner!

📍 $clubName
📱 $_baseUrl/tournament/$tournamentId

#SABOArena #Badminton #TournamentResults
''';
      } else {
        // Upcoming match
        final dateStr = matchDate != null
            ? '🗓️ ${matchDate.day}/${matchDate.month} lúc ${matchDate.hour}:${matchDate.minute.toString().padLeft(2, '0')}'
            : '';
        shareText = '''
📢 SẮP DIỄN RA!

🏸 $matchTypeLabel - $tournamentName

⚔️ $player1Name vs $player2Name

$dateStr
📍 $clubName

📱 Theo dõi: $_baseUrl/tournament/$tournamentId/match/$matchId

#SABOArena #Badminton #UpcomingMatch
''';
      }

      // Share with image + analytics
      return await RichShareService.shareWidgetAsImage(
        widget: cardWidget,
        text: shareText,
        filename: 'match_${matchId}_${DateTime.now().millisecondsSinceEpoch}',
        context: context,
        subject: '$matchTypeLabel: $player1Name vs $player2Name',
        contentType: 'tournament_match',
        contentId: matchId,
      );
    } catch (e) {
      return null;
    }
  }

  /// 📱 Share post with IMAGE (Rich Share - NEW)
  /// Creates 4:5 ratio card for social media feed posts
  static Future<ShareResult?> sharePostRich({
    required String postId,
    required String authorName,
    required String? authorAvatar,
    required String content,
    required String? imageUrl,
    required int likeCount,
    required int commentCount,
    required int shareCount,
    required DateTime createdAt,
    BuildContext? context,
  }) async {
    try {
      // Create shareable post card widget (4:5 ratio)
      final cardWidget = ShareablePostCard(
        authorName: authorName,
        authorAvatar: authorAvatar,
        content: content,
        imageUrl: imageUrl,
        likeCount: likeCount,
        commentCount: commentCount,
        shareCount: shareCount,
        createdAt: createdAt,
      );

      // Generate share text
      final shareText = '''
📢 Bài viết từ SABO ARENA

👤 $authorName

${content.isNotEmpty ? '$content\n\n' : ''}📊 $likeCount lượt thích • $commentCount bình luận • $shareCount chia sẻ

📱 Tham gia cộng đồng: $_baseUrl/post/$postId

#SABOArena #Badminton #Community
''';

      // Share with image + analytics
      return await RichShareService.shareWidgetAsImage(
        widget: cardWidget,
        text: shareText,
        filename: 'post_${postId}_${DateTime.now().millisecondsSinceEpoch}',
        context: context,
        subject: 'Chia sẻ từ SABO ARENA',
        contentType: 'post',
        contentId: postId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Share user profile (Text Only - Legacy)
  static Future<void> shareUserProfile(UserProfile user) async {
    final userCode = generateUserCode(user.id);
    final shareText = '''
🏆 Hãy thách đấu với tôi trên SABO ARENA!

👤 ${user.fullName}
🎯 Rank: ${user.rank ?? 'Chưa xếp hạng'}
⚡ ELO: ${user.eloRating}
🏅 Thắng/Thua: ${user.totalWins}/${user.totalLosses}
🎪 Tournament: ${user.totalTournaments}

🔗 ID: $userCode
📱 Tải app: $_baseUrl/download
🤝 Kết nối: $_baseUrl/user/${user.id}

#SABOArena #Badminton #ThachDau
''';

    await Share.share(
      shareText,
      subject: 'Thách đấu cùng ${user.fullName} trên SABO ARENA',
    );
  }

  /// Share tournament (Text Only - Legacy)
  static Future<void> shareTournament({
    required String tournamentId,
    required String tournamentName,
    required String startDate,
    required int participants,
    required String prizePool,
  }) async {
    final shareText = '''
🏆 Tham gia giải đấu SABO ARENA!

🎪 $tournamentName
📅 Ngày: $startDate
👥 Người chơi: $participants
💰 Giải thưởng: $prizePool

🔗 Đăng ký: $_baseUrl/tournament/$tournamentId
📱 Tải app: $_baseUrl/download

#SABOArena #Tournament #Badminton
''';

    await Share.share(shareText, subject: 'Tham gia giải đấu: $tournamentName');
  }

  /// 🎨 Share tournament with IMAGE (Rich Share - NEW)
  static Future<ShareResult?> shareTournamentRich({
    required String tournamentId,
    required String tournamentName,
    required String startDate,
    required int participants,
    required String prizePool,
    String? format,
    String? status,
    BuildContext? context,
  }) async {
    try {
      // Create shareable card widget
      final cardWidget = ShareableTournamentCard(
        tournamentId: tournamentId,
        tournamentName: tournamentName,
        startDate: startDate,
        participants: participants,
        prizePool: prizePool,
        format: format,
        status: status,
      );

      // Generate share text
      final shareText = '''
🏆 Tham gia giải đấu SABO ARENA!

🎪 $tournamentName
📅 Ngày: $startDate
👥 Người chơi: $participants
💰 Giải thưởng: $prizePool

🔗 Đăng ký: $_baseUrl/tournament/$tournamentId
📱 Tải app: $_baseUrl/download

#SABOArena #Tournament #Badminton
''';

      // Share with image + analytics
      return await RichShareService.shareWidgetAsImage(
        widget: cardWidget,
        text: shareText,
        filename: 'share_tournament_$tournamentId',
        context: context,
        subject: 'Tham gia giải đấu: $tournamentName',
        contentType: 'tournament',
        contentId: tournamentId,
      );
    } catch (e) {
      // Fallback to text-only share
      await shareTournament(
        tournamentId: tournamentId,
        tournamentName: tournamentName,
        startDate: startDate,
        participants: participants,
        prizePool: prizePool,
      );
      return null;
    }
  }

  /// Share match result
  static Future<void> shareMatchResult({
    required String player1Name,
    required String player2Name,
    required String score,
    required String winner,
    required String matchDate,
    String? matchId,
  }) async {
    final shareText = '''
🏸 Kết quả trận đấu SABO ARENA

⚔️ $player1Name vs $player2Name
📊 Tỷ số: $score
🏆 Thắng: $winner
📅 Ngày: $matchDate

${matchId != null ? '🔗 Chi tiết: $_baseUrl/match/$matchId\n' : ''}📱 Tải app: $_baseUrl/download

#SABOArena #MatchResult #Badminton
''';

    await Share.share(
      shareText,
      subject: 'Kết quả trận đấu: $player1Name vs $player2Name',
    );
  }

  /// Share club
  static Future<void> shareClub({
    required String clubId,
    required String clubName,
    required String location,
    required int memberCount,
    String? description,
  }) async {
    final shareText = '''
🏛️ Tham gia CLB $clubName!

📍 Địa điểm: $location
👥 Thành viên: $memberCount người
${description != null ? '📝 $description\n' : ''}
🔗 Tham gia: $_baseUrl/club/$clubId
📱 Tải app: $_baseUrl/download

#SABOArena #Club #Badminton
''';

    await Share.share(shareText, subject: 'Tham gia CLB: $clubName');
  }

  /// Share app download
  static Future<void> shareApp() async {
    const shareText = '''
🏸 SABO ARENA - Ứng dụng billiards #1 Việt Nam!

✨ Tính năng nổi bật:
🎯 Tìm đối thủ theo trình độ
🏆 Tham gia giải đấu
📊 Theo dõi thống kê ELO
👥 Kết nối cộng đồng billiards
💰 Giải thưởng hấp dẫn

📱 Tải ngay: $_baseUrl/download
🌟 4.8⭐ trên App Store & Google Play

#SABOArena #Billiards #Vietnam
''';

    await Share.share(
      shareText,
      subject: 'SABO ARENA - Ứng dụng billiards #1 Việt Nam',
    );
  }

  /// Share with custom content
  static Future<void> shareCustom({
    required String text,
    String? subject,
  }) async {
    await Share.share(text, subject: subject);
  }

  /// Generate QR data for user
  static String generateUserQRData(UserProfile user) {
    return '$_baseUrl/user/${user.id}';
  }

  /// Generate QR data for user with referral code
  static Future<String> generateUserQRDataWithReferral(UserProfile user) async {
    try {
      // Lấy mã ref của user từ ReferralService
      final referralCode = await ReferralService.instance.getUserReferralCode(
        user.id,
      );

      if (referralCode != null) {
        // Tích hợp mã ref vào URL: $_baseUrl/user/${user.id}?ref=${referralCode}
        return '$_baseUrl/user/${user.id}?ref=$referralCode';
      } else {
        // Nếu chưa có mã ref, tạo URL thông thường
        return '$_baseUrl/user/${user.id}';
      }
    } catch (error) {
      // Fallback về URL thông thường nếu có lỗi
      return '$_baseUrl/user/${user.id}';
    }
  }

  /// Generate QR data for tournament
  static String generateTournamentQRData(String tournamentId) {
    return '$_baseUrl/tournament/$tournamentId';
  }

  /// Generate QR data for club
  static String generateClubQRData(String clubId) {
    return '$_baseUrl/club/$clubId';
  }

  /// Share tournament bracket
  static Future<void> shareBracket({
    required String tournamentId,
    required String tournamentName,
    required String clubName,
  }) async {
    final shareText = '''
🎱 Sơ đồ đấu - $tournamentName

📍 CLB: $clubName
🏆 Xem sơ đồ đấu đầy đủ và theo dõi các trận đấu!

🔗 Xem: $_baseUrl/bracket/$tournamentId
📱 Tải app: $_baseUrl/download

#SABOArena #Billiards #TournamentBracket
''';

    await Share.share(
      shareText,
      subject: '🎱 Sơ đồ đấu - $tournamentName',
    );
  }

  /// Share leaderboard
  static Future<void> shareLeaderboard({
    required String tournamentId,
    required String tournamentName,
    required String clubName,
    required int totalPlayers,
  }) async {
    final shareText = '''
🏆 Bảng xếp hạng - $tournamentName

📍 CLB: $clubName
👥 Số người chơi: $totalPlayers
🎯 Xem bảng xếp hạng đầy đủ!

🔗 Xem: $_baseUrl/leaderboard/$tournamentId
📱 Tải app: $_baseUrl/download

#SABOArena #Billiards #Leaderboard
''';

    await Share.share(
      shareText,
      subject: '🏆 Bảng xếp hạng - $tournamentName',
    );
  }

  /// Share referral code with rewards
  static Future<void> shareReferralCode({
    required String code,
    required String userName,
  }) async {
    final shareText = '''
🎱 $userName mời bạn tham gia Sabo Arena!

🎁 Đăng ký với mã giới thiệu để nhận thưởng:
📝 Mã: $code

💰 Người mới: +50 SPA
💰 Người giới thiệu: +100 SPA

🔗 Đăng ký: $_baseUrl/ref/$code
📱 Tải app: $_baseUrl/download

#SABOArena #Referral #GioiThieu
''';

    await Share.share(
      shareText,
      subject: '🎁 Mã giới thiệu Sabo Arena',
    );
  }

  /// Generate QR data for bracket
  static String generateBracketQRData(String tournamentId) {
    return '$_baseUrl/bracket/$tournamentId';
  }

  /// Generate QR data for leaderboard
  static String generateLeaderboardQRData(String tournamentId) {
    return '$_baseUrl/leaderboard/$tournamentId';
  }
}
