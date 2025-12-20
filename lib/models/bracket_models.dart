/// Tournament participant data
class TournamentParticipant {
  final String id;
  final String name;
  final String? rank;
  final int? elo;
  final int? seed;
  final Map<String, dynamic>? metadata;

  const TournamentParticipant({
    required this.id,
    required this.name,
    this.rank,
    this.elo,
    this.seed,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rank': rank,
        'elo': elo,
        'seed': seed,
        'metadata': metadata,
      };

  factory TournamentParticipant.fromJson(Map<String, dynamic> json) {
    return TournamentParticipant(
      id: json['id'],
      name: json['name'],
      rank: json['rank'],
      elo: json['elo'],
      seed: json['seed'],
      metadata: json['metadata'],
    );
  }
}

/// Tournament match representation
class TournamentMatch {
  final String id;
  final String roundId;
  final int roundNumber;
  final int matchNumber;
  final TournamentParticipant? player1;
  final TournamentParticipant? player2;
  final TournamentParticipant? winner;
  final String status; // 'pending', 'in_progress', 'completed', 'bye'
  final Map<String, dynamic>? result;
  final DateTime? scheduledTime;
  final Map<String, dynamic>? metadata;

  const TournamentMatch({
    required this.id,
    required this.roundId,
    required this.roundNumber,
    required this.matchNumber,
    this.player1,
    this.player2,
    this.winner,
    this.status = 'pending',
    this.result,
    this.scheduledTime,
    this.metadata,
  });

  /// Check if this is a bye match (only one player)
  bool get isBye => player1 != null && player2 == null;

  /// Check if match is ready to be played
  bool get isReady => player1 != null && player2 != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'roundId': roundId,
        'roundNumber': roundNumber,
        'matchNumber': matchNumber,
        'player1': player1?.toJson(),
        'player2': player2?.toJson(),
        'winner': winner?.toJson(),
        'status': status,
        'result': result,
        'scheduledTime': scheduledTime?.toIso8601String(),
        'metadata': metadata,
      };
}

/// Tournament round representation
class TournamentRound {
  final String id;
  final int roundNumber;
  final String name;
  final String type; // 'winner', 'loser', 'group', 'swiss', 'final'
  final List<TournamentMatch> matches;
  final Map<String, dynamic>? metadata;

  const TournamentRound({
    required this.id,
    required this.roundNumber,
    required this.name,
    required this.type,
    required this.matches,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'roundNumber': roundNumber,
        'name': name,
        'type': type,
        'matches': matches.map((m) => m.toJson()).toList(),
        'metadata': metadata,
      };
}

/// Bracket structure
class Bracket {
  final String tournamentId;
  final String type;
  final List<TournamentRound> rounds;
  final Map<String, dynamic>? metadata;

  const Bracket({
    required this.tournamentId,
    required this.type,
    required this.rounds,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'tournamentId': tournamentId,
        'type': type,
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'metadata': metadata,
      };
}
