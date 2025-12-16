/// 🏆 SABO ARENA - Bracket Service Interface
/// Unified interface for all tournament bracket formats
/// Based on existing service patterns and audit findings

import 'package:flutter/material.dart';

/// Core interface for all bracket services
abstract class IBracketService {
  /// Process match result with automatic advancement
  Future<BracketOperationResult> processMatchResult({
    required String matchId,
    required String winnerId,
    required Map<String, int> scores,
    Map<String, dynamic>? metadata,
  });

  /// Create complete bracket structure
  Future<BracketOperationResult> createBracket({
    required String tournamentId,
    required List<String> participantIds,
    Map<String, dynamic>? options,
  });

  /// Validate tournament and auto-fix issues
  Future<ValidationResult> validateAndFixTournament(String tournamentId);

  /// Get tournament status and progression details
  Future<TournamentStatus> getTournamentStatus(String tournamentId);

  /// Get format information
  BracketFormatInfo get formatInfo;
}

/// Standard operation result for all bracket operations
class BracketOperationResult {
  final bool success;
  final String? message;
  final String? error;
  final Map<String, dynamic> data;
  final String service;
  final DateTime timestamp;

  const BracketOperationResult({
    required this.success,
    this.message,
    this.error,
    this.data = const {},
    required this.service,
    required this.timestamp,
  });

  factory BracketOperationResult.success({
    required String message,
    Map<String, dynamic> data = const {},
    required String service,
  }) {
    return BracketOperationResult(
      success: true,
      message: message,
      data: data,
      service: service,
      timestamp: DateTime.now(),
    );
  }

  factory BracketOperationResult.error({
    required String error,
    required String service,
  }) {
    return BracketOperationResult(
      success: false,
      error: error,
      service: service,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'error': error,
    'data': data,
    'service': service,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Validation result for tournament validation
class ValidationResult {
  final bool isValid;
  final int fixesApplied;
  final List<String> issuesFound;
  final List<String> warnings;
  final String message;

  const ValidationResult({
    required this.isValid,
    required this.fixesApplied,
    required this.issuesFound,
    required this.warnings,
    required this.message,
  });

  factory ValidationResult.success({
    required int fixesApplied,
    List<String> issuesFound = const [],
    List<String> warnings = const [],
  }) {
    return ValidationResult(
      isValid: true,
      fixesApplied: fixesApplied,
      issuesFound: issuesFound,
      warnings: warnings,
      message: fixesApplied > 0
          ? 'Tournament validated and $fixesApplied issues fixed'
          : 'Tournament validated - no issues found',
    );
  }

  factory ValidationResult.error(String error) {
    return ValidationResult(
      isValid: false,
      fixesApplied: 0,
      issuesFound: [],
      warnings: [],
      message: 'Validation failed: $error',
    );
  }
}

/// Tournament status information
class TournamentStatus {
  final String tournamentId;
  final String status; // 'pending', 'in_progress', 'completed', 'error'
  final int totalMatches;
  final int completedMatches;
  final int pendingMatches;
  final int totalRounds;
  final double completionPercentage;
  final String? tournamentWinner;
  final String bracketFormat;
  final Map<String, dynamic> metadata;

  const TournamentStatus({
    required this.tournamentId,
    required this.status,
    required this.totalMatches,
    required this.completedMatches,
    required this.pendingMatches,
    required this.totalRounds,
    required this.completionPercentage,
    this.tournamentWinner,
    required this.bracketFormat,
    this.metadata = const {},
  });

  factory TournamentStatus.fromMap(Map<String, dynamic> map) {
    return TournamentStatus(
      tournamentId: map['tournament_id'] as String,
      status: map['status'] as String,
      totalMatches: map['total_matches'] as int,
      completedMatches: map['completed_matches'] as int,
      pendingMatches: map['pending_matches'] as int,
      totalRounds: map['total_rounds'] as int,
      completionPercentage: (map['completion_percentage'] as num).toDouble(),
      tournamentWinner: map['tournament_winner'] as String?,
      bracketFormat: map['bracket_format'] as String,
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'tournament_id': tournamentId,
    'status': status,
    'total_matches': totalMatches,
    'completed_matches': completedMatches,
    'pending_matches': pendingMatches,
    'total_rounds': totalRounds,
    'completion_percentage': completionPercentage,
    'tournament_winner': tournamentWinner,
    'bracket_format': bracketFormat,
    'metadata': metadata,
  };
}

/// Format information for bracket types
class BracketFormatInfo {
  final String name;
  final String nameVi;
  final int minPlayers;
  final int maxPlayers;
  final List<int> allowedPlayerCounts;
  final String description;
  final String descriptionVi;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> properties;

  const BracketFormatInfo({
    required this.name,
    required this.nameVi,
    required this.minPlayers,
    required this.maxPlayers,
    required this.allowedPlayerCounts,
    required this.description,
    this.descriptionVi = '',
    required this.icon,
    required this.color,
    this.properties = const {},
  });

  factory BracketFormatInfo.fromFormatDetails(Map<String, dynamic> details) {
    return BracketFormatInfo(
      name: details['name'] as String,
      nameVi: details['nameVi'] as String? ?? '',
      minPlayers: details['minPlayers'] as int,
      maxPlayers: details['maxPlayers'] as int,
      allowedPlayerCounts: _calculateAllowedCounts(
        details['minPlayers'] as int,
        details['maxPlayers'] as int,
      ),
      description: details['description'] as String,
      descriptionVi: details['descriptionVi'] as String? ?? '',
      icon: details['icon'] as IconData? ?? Icons.sports_esports,
      color: details['color'] as Color? ?? Colors.grey,
      properties: Map<String, dynamic>.from(details),
    );
  }

  static List<int> _calculateAllowedCounts(int min, int max) {
    final counts = <int>[];
    int power = 2;
    while (power <= max) {
      if (power >= min) {
        counts.add(power);
      }
      power *= 2;
    }
    return counts;
  }
}

/// Exception for unsupported bracket formats
class UnsupportedBracketFormatException implements Exception {
  final String message;
  const UnsupportedBracketFormatException(this.message);

  @override
  String toString() => 'UnsupportedBracketFormatException: $message';
}
