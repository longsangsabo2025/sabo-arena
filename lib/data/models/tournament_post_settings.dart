// Model cho Tournament Post Settings
class TournamentPostSettings {
  final String id;
  final String tournamentId;
  final String clubId;

  // Auto post configuration
  final bool autoPostEnabled;
  final bool postCrossFinals;
  final bool postSemifinals;
  final bool postFinals;
  final bool postThirdPlace;
  final bool postAllRounds;

  // Reminder settings
  final int reminderMinutesBefore;
  final bool sendReminder;

  // Content settings
  final bool includePlayerStats;
  final bool includeTournamentInfo;
  final bool enableLiveStream;
  final bool autoPinPosts;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  TournamentPostSettings({
    required this.id,
    required this.tournamentId,
    required this.clubId,
    required this.autoPostEnabled,
    required this.postCrossFinals,
    required this.postSemifinals,
    required this.postFinals,
    required this.postThirdPlace,
    required this.postAllRounds,
    required this.reminderMinutesBefore,
    required this.sendReminder,
    required this.includePlayerStats,
    required this.includeTournamentInfo,
    required this.enableLiveStream,
    required this.autoPinPosts,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentPostSettings.fromJson(Map<String, dynamic> json) {
    return TournamentPostSettings(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      clubId: json['club_id'] as String,
      autoPostEnabled: json['auto_post_enabled'] as bool,
      postCrossFinals: json['post_cross_finals'] as bool,
      postSemifinals: json['post_semifinals'] as bool,
      postFinals: json['post_finals'] as bool,
      postThirdPlace: json['post_third_place'] as bool,
      postAllRounds: json['post_all_rounds'] as bool,
      reminderMinutesBefore: json['reminder_minutes_before'] as int,
      sendReminder: json['send_reminder'] as bool,
      includePlayerStats: json['include_player_stats'] as bool,
      includeTournamentInfo: json['include_tournament_info'] as bool,
      enableLiveStream: json['enable_live_stream'] as bool,
      autoPinPosts: json['auto_pin_posts'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'club_id': clubId,
      'auto_post_enabled': autoPostEnabled,
      'post_cross_finals': postCrossFinals,
      'post_semifinals': postSemifinals,
      'post_finals': postFinals,
      'post_third_place': postThirdPlace,
      'post_all_rounds': postAllRounds,
      'reminder_minutes_before': reminderMinutesBefore,
      'send_reminder': sendReminder,
      'include_player_stats': includePlayerStats,
      'include_tournament_info': includeTournamentInfo,
      'enable_live_stream': enableLiveStream,
      'auto_pin_posts': autoPinPosts,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TournamentPostSettings copyWith({
    String? id,
    String? tournamentId,
    String? clubId,
    bool? autoPostEnabled,
    bool? postCrossFinals,
    bool? postSemifinals,
    bool? postFinals,
    bool? postThirdPlace,
    bool? postAllRounds,
    int? reminderMinutesBefore,
    bool? sendReminder,
    bool? includePlayerStats,
    bool? includeTournamentInfo,
    bool? enableLiveStream,
    bool? autoPinPosts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentPostSettings(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      clubId: clubId ?? this.clubId,
      autoPostEnabled: autoPostEnabled ?? this.autoPostEnabled,
      postCrossFinals: postCrossFinals ?? this.postCrossFinals,
      postSemifinals: postSemifinals ?? this.postSemifinals,
      postFinals: postFinals ?? this.postFinals,
      postThirdPlace: postThirdPlace ?? this.postThirdPlace,
      postAllRounds: postAllRounds ?? this.postAllRounds,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      sendReminder: sendReminder ?? this.sendReminder,
      includePlayerStats: includePlayerStats ?? this.includePlayerStats,
      includeTournamentInfo:
          includeTournamentInfo ?? this.includeTournamentInfo,
      enableLiveStream: enableLiveStream ?? this.enableLiveStream,
      autoPinPosts: autoPinPosts ?? this.autoPinPosts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
