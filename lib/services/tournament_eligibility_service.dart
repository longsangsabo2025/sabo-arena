import '../models/tournament.dart';
import '../models/tournament_eligibility.dart';
import '../models/user_profile.dart';
import '../core/utils/sabo_rank_system.dart';

/// Service to check tournament eligibility
class TournamentEligibilityService {
  /// Check if user is eligible to register for tournament
  static EligibilityResult checkEligibility({
    required Tournament tournament,
    required UserProfile user,
    bool isAlreadyRegistered = false,
  }) {
    final issues = <EligibilityIssue>[];

    // 1. Check if already registered
    if (isAlreadyRegistered) {
      issues.add(const EligibilityIssue(
        type: EligibilityIssueType.alreadyRegistered,
        title: 'Đã đăng ký',
        message: 'Bạn đã đăng ký tham gia giải đấu này rồi.',
      ));
      return EligibilityResult.notEligible(issues);
    }

    // 2. Check registration deadline
    if (DateTime.now().isAfter(tournament.registrationDeadline)) {
      issues.add(EligibilityIssue(
        type: EligibilityIssueType.registrationClosed,
        title: 'Hết hạn đăng ký',
        message:
            'Thời hạn đăng ký đã kết thúc vào ${_formatDateTime(tournament.registrationDeadline)}.',
      ));
    }

    // 3. Check tournament capacity
    if (tournament.currentParticipants >= tournament.maxParticipants) {
      issues.add(EligibilityIssue(
        type: EligibilityIssueType.tournamentFull,
        title: 'Giải đã đầy',
        message:
            'Giải đấu đã đủ ${tournament.maxParticipants} người tham gia.',
      ));
    }

    // 4. Check minimum rank requirement
    if (tournament.minRank != null && tournament.minRank!.isNotEmpty) {
      if (!_meetsMinRankRequirement(user.rank, tournament.minRank!)) {
        final minRankName =
            SaboRankSystem.getRankDisplayName(tournament.minRank!);
        final userRankName = SaboRankSystem.getRankDisplayName(user.rank ?? 'K');
        final minRankElo = SaboRankSystem.getRankMinElo(tournament.minRank!);
        final currentElo = user.eloRating ?? 1000;

        issues.add(EligibilityIssue(
          type: EligibilityIssueType.rankTooLow,
          title: 'Hạng chưa đủ',
          message:
              'Giải đấu yêu cầu tối thiểu Hạng $minRankName (${tournament.minRank}), bạn hiện tại là Hạng $userRankName (${user.rank ?? "K"}).',
          guidance:
              'Hãy tiếp tục thi đấu để nâng ELO lên $minRankElo điểm hoặc cao hơn. '
              'Hiện tại bạn có $currentElo ELO, cần thêm ${minRankElo - currentElo} điểm.',
          actionButtonText: 'Tìm trận đấu',
          actionRoute: '/challenges',
        ));
      }
    }

    // 5. Check maximum rank restriction
    if (tournament.maxRank != null && tournament.maxRank!.isNotEmpty) {
      if (!_meetsMaxRankRequirement(user.rank, tournament.maxRank!)) {
        final maxRankName =
            SaboRankSystem.getRankDisplayName(tournament.maxRank!);
        final userRankName = SaboRankSystem.getRankDisplayName(user.rank ?? 'K');

        issues.add(EligibilityIssue(
          type: EligibilityIssueType.rankTooHigh,
          title: 'Hạng vượt quá',
          message:
              'Giải đấu chỉ dành cho người chơi tối đa Hạng $maxRankName (${tournament.maxRank}), '
              'bạn hiện tại là Hạng $userRankName (${user.rank}).',
          guidance:
              'Giải đấu này dành cho người chơi trình độ thấp hơn. Hãy tìm giải đấu phù hợp với trình độ của bạn.',
          actionButtonText: 'Xem giải khác',
          actionRoute: '/tournaments',
        ));
      }
    }

    // 6. Check profile completeness
    if (user.displayName.isEmpty) {
      issues.add(const EligibilityIssue(
        type: EligibilityIssueType.accountIncomplete,
        title: 'Chưa hoàn thiện hồ sơ',
        message: 'Bạn cần điền đầy đủ thông tin cá nhân để tham gia giải đấu.',
        guidance: 'Vui lòng cập nhật tên hiển thị, ảnh đại diện và thông tin liên hệ.',
        actionButtonText: 'Cập nhật hồ sơ',
        actionRoute: '/profile/edit',
      ));
    }

    // Return result
    if (issues.isEmpty) {
      return EligibilityResult.eligible();
    } else {
      return EligibilityResult.notEligible(issues);
    }
  }

  /// Check if user meets minimum rank requirement
  static bool _meetsMinRankRequirement(String? userRank, String minRank) {
    if (userRank == null) return false;

    final userElo = SaboRankSystem.getRankMinElo(userRank);
    final minElo = SaboRankSystem.getRankMinElo(minRank);

    return userElo >= minElo;
  }

  /// Check if user meets maximum rank requirement
  static bool _meetsMaxRankRequirement(String? userRank, String maxRank) {
    if (userRank == null) return true; // No rank = allow

    final userElo = SaboRankSystem.getRankMinElo(userRank);
    final maxElo = SaboRankSystem.getRankMinElo(maxRank);

    return userElo <= maxElo;
  }

  /// Format DateTime for display
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get user-friendly rank range description
  static String getRankRangeDescription(String? minRank, String? maxRank) {
    if (minRank != null && maxRank != null) {
      return 'Hạng ${SaboRankSystem.getRankDisplayName(minRank)} đến ${SaboRankSystem.getRankDisplayName(maxRank)}';
    } else if (minRank != null) {
      return 'Từ Hạng ${SaboRankSystem.getRankDisplayName(minRank)} trở lên';
    } else if (maxRank != null) {
      return 'Tối đa Hạng ${SaboRankSystem.getRankDisplayName(maxRank)}';
    }
    return 'Mọi hạng';
  }

  /// Check if tournament has rank restrictions
  static bool hasRankRestrictions(Tournament tournament) {
    return (tournament.minRank != null && tournament.minRank!.isNotEmpty) ||
        (tournament.maxRank != null && tournament.maxRank!.isNotEmpty);
  }
}
