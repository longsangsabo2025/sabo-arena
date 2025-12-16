/// Tournament eligibility check result
class EligibilityResult {
  final bool isEligible;
  final List<EligibilityIssue> issues;

  const EligibilityResult({
    required this.isEligible,
    this.issues = const [],
  });

  factory EligibilityResult.eligible() {
    return const EligibilityResult(
      isEligible: true,
      issues: [],
    );
  }

  factory EligibilityResult.notEligible(List<EligibilityIssue> issues) {
    return EligibilityResult(
      isEligible: false,
      issues: issues,
    );
  }

  /// Get primary issue (most important one)
  EligibilityIssue? get primaryIssue => issues.isNotEmpty ? issues.first : null;
}

/// Individual eligibility issue
class EligibilityIssue {
  final EligibilityIssueType type;
  final String title;
  final String message;
  final String? guidance; // Optional guidance for user
  final String? actionButtonText; // Optional action button text
  final String? actionRoute; // Optional navigation route

  const EligibilityIssue({
    required this.type,
    required this.title,
    required this.message,
    this.guidance,
    this.actionButtonText,
    this.actionRoute,
  });
}

/// Types of eligibility issues
enum EligibilityIssueType {
  rankTooLow, // User rank below minimum required
  rankTooHigh, // User rank above maximum allowed
  registrationClosed, // Registration deadline passed
  tournamentFull, // Max participants reached
  alreadyRegistered, // User already registered
  insufficientMatches, // Not enough matches played
  accountIncomplete, // Missing profile information
  paymentRequired, // Payment required but not completed
  bannedFromTournament, // User is banned
}

extension EligibilityIssueTypeExtension on EligibilityIssueType {
  String get icon {
    switch (this) {
      case EligibilityIssueType.rankTooLow:
        return '📉';
      case EligibilityIssueType.rankTooHigh:
        return '📈';
      case EligibilityIssueType.registrationClosed:
        return '⏰';
      case EligibilityIssueType.tournamentFull:
        return '👥';
      case EligibilityIssueType.alreadyRegistered:
        return '✅';
      case EligibilityIssueType.insufficientMatches:
        return '🎮';
      case EligibilityIssueType.accountIncomplete:
        return '📝';
      case EligibilityIssueType.paymentRequired:
        return '💰';
      case EligibilityIssueType.bannedFromTournament:
        return '🚫';
    }
  }

  String get severity {
    switch (this) {
      case EligibilityIssueType.rankTooLow:
      case EligibilityIssueType.rankTooHigh:
      case EligibilityIssueType.insufficientMatches:
        return 'warning'; // Can be fixed by playing more
      case EligibilityIssueType.registrationClosed:
      case EligibilityIssueType.tournamentFull:
      case EligibilityIssueType.bannedFromTournament:
        return 'error'; // Cannot be fixed
      case EligibilityIssueType.alreadyRegistered:
        return 'info'; // Already done
      case EligibilityIssueType.accountIncomplete:
      case EligibilityIssueType.paymentRequired:
        return 'action'; // Needs immediate action
    }
  }
}
