class UserStats {
  final int totalWins;
  final int totalLosses;
  final int totalTournaments;
  final int totalMatches;
  final int eloRating;
  final int winStreak;
  final int ranking;

  const UserStats({
    required this.totalWins,
    required this.totalLosses,
    required this.totalTournaments,
    required this.totalMatches,
    required this.eloRating,
    required this.winStreak,
    this.ranking = 0,
  });

  factory UserStats.empty() {
    return const UserStats(
      totalWins: 0,
      totalLosses: 0,
      totalTournaments: 0,
      totalMatches: 0,
      eloRating: 0,
      winStreak: 0,
      ranking: 0,
    );
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalWins: map['total_wins'] as int? ?? 0,
      totalLosses: map['total_losses'] as int? ?? 0,
      totalTournaments: map['total_tournaments'] as int? ?? 0,
      totalMatches: map['total_matches'] as int? ?? 0,
      eloRating: map['elo_rating'] as int? ?? 0,
      winStreak: map['win_streak'] as int? ?? 0,
      ranking: map['ranking'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_wins': totalWins,
      'total_losses': totalLosses,
      'total_tournaments': totalTournaments,
      'total_matches': totalMatches,
      'elo_rating': eloRating,
      'win_streak': winStreak,
      'ranking': ranking,
    };
  }
}
