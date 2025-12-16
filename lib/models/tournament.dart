class Tournament {
  final String id;
  final String title;
  final String description;
  final String? clubId;
  final String? organizerId;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? registrationStart; // When registration opens
  final DateTime registrationDeadline;
  final int maxParticipants;
  final int currentParticipants;
  final double entryFee;
  final double prizePool;
  final String status;
  final String? skillLevelRequired;
  final String format; // Game type (8-ball, 9-ball, 10-ball)
  final String
  tournamentType; // Tournament elimination format (single_elimination, double_elimination)
  final String? rules;
  final String? requirements;
  final bool isPublic;
  final String? coverImageUrl;
  final Map<String, dynamic>? prizeDistribution;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Enhanced prize fields
  final String prizeSource; // 'entry_fees', 'sponsor', 'hybrid'
  final String
  distributionTemplate; // 'winner_takes_all', 'top_3', 'top_4', 'dong_hang_3', 'custom'
  final double organizerFeePercent; // Organizer fee percentage (0-100)
  final double sponsorContribution; // Additional sponsor money
  final List<Map<String, dynamic>>?
  customDistribution; // Custom distribution array

  // Rank restriction fields
  final String? minRank; // Minimum rank required
  final String? maxRank; // Maximum rank allowed

  // Venue and contact fields
  final String? venueAddress; // Detailed venue address
  final String? venueContact; // Contact person name
  final String? venuePhone; // Contact phone number

  // Additional rules fields
  final String? specialRules; // Special tournament rules
  final bool registrationFeeWaiver; // Whether registration fee is waived

  // Club information (joined from clubs table)
  final String? clubName;
  final String? clubLogo;
  final String? clubAddress;

  const Tournament({
    required this.id,
    required this.title,
    required this.description,
    this.clubId,
    this.organizerId,
    required this.startDate,
    this.endDate,
    this.registrationStart,
    required this.registrationDeadline,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.entryFee,
    required this.prizePool,
    required this.status,
    this.skillLevelRequired,
    required this.format, // Game type
    required this.tournamentType, // Tournament elimination format
    this.rules,
    this.requirements,
    required this.isPublic,
    this.coverImageUrl,
    this.prizeDistribution,
    required this.createdAt,
    required this.updatedAt,
    // Enhanced prize fields
    this.prizeSource = 'entry_fees',
    this.distributionTemplate = 'top_4',
    this.organizerFeePercent = 10.0,
    this.sponsorContribution = 0.0,
    this.customDistribution,
    // Rank restriction fields
    this.minRank,
    this.maxRank,
    // Venue and contact fields
    this.venueAddress,
    this.venueContact,
    this.venuePhone,
    // Additional rules fields
    this.specialRules,
    this.registrationFeeWaiver = false,
    // Club information
    this.clubName,
    this.clubLogo,
    this.clubAddress,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      clubId: json['club_id'],
      organizerId: json['organizer_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      registrationStart: json['registration_start'] != null
          ? DateTime.parse(json['registration_start'])
          : null,
      registrationDeadline: DateTime.parse(json['registration_deadline']),
      maxParticipants: json['max_participants'] ?? 0,
      currentParticipants: json['current_participants'] ?? 0,
      entryFee: (json['entry_fee'] ?? 0).toDouble(),
      prizePool: (json['prize_pool'] ?? 0).toDouble(),
      status: json['status'] ?? 'upcoming',
      skillLevelRequired: json['skill_level_required'],
      // CLEAN SCHEMA: Use proper field mapping with new columns
      format:
          json['game_format'] ?? '8-ball', // Game type from game_format field
      tournamentType:
          json['bracket_format'] ??
          'single_elimination', // Tournament format from bracket_format field
      rules: json['rules'],
      requirements: json['requirements'],
      isPublic: json['is_public'] ?? true,
      coverImageUrl: json['cover_image_url'],
      prizeDistribution: json['prize_distribution'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      // Enhanced prize fields
      prizeSource: json['prize_source'] ?? 'entry_fees',
      distributionTemplate: json['distribution_template'] ?? 'top_4',
      organizerFeePercent: (json['organizer_fee_percent'] ?? 10.0).toDouble(),
      sponsorContribution: (json['sponsor_contribution'] ?? 0.0).toDouble(),
      customDistribution: json['custom_distribution'] != null
          ? List<Map<String, dynamic>>.from(json['custom_distribution'])
          : null,
      // Rank restriction fields
      minRank: json['min_rank'],
      maxRank: json['max_rank'],
      // Venue and contact fields
      venueAddress: json['venue_address'],
      venueContact: json['venue_contact'],
      venuePhone: json['venue_phone'],
      // Additional rules fields
      specialRules: json['special_rules'],
      registrationFeeWaiver: json['registration_fee_waiver'] ?? false,
      // Club information (from joined clubs table)
      clubName: json['clubs']?['name'],
      clubLogo: json['clubs']?['logo_url'],
      clubAddress: json['clubs']?['address'],
    );
  }

  // Getter for cover image (for backward compatibility)
  String? get coverImage => coverImageUrl;

  // Helpers for clarity after migration
  String get gameFormat => format; // 8-ball, 9-ball, etc.
  String get bracketFormat =>
      tournamentType; // single_elimination, double_elimination, etc.

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'club_id': clubId,
      'organizer_id': organizerId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'registration_start': registrationStart?.toIso8601String(),
      'registration_deadline': registrationDeadline.toIso8601String(),
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'entry_fee': entryFee,
      'prize_pool': prizePool,
      'status': status,
      'skill_level_required': skillLevelRequired,
      // CLEAN SCHEMA: Save to proper new columns
      'bracket_format':
          tournamentType, // Tournament format saved to bracket_format field
      'game_format': format, // Game type saved to game_format field
      'rules': rules,
      'requirements': requirements,
      'is_public': isPublic,
      'cover_image_url': coverImageUrl,
      'prize_distribution': prizeDistribution,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Tournament copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    int? maxParticipants,
    double? entryFee,
    double? prizePool,
    String? status,
    String? skillLevelRequired,
    String? format,
    String? tournamentType,
    String? rules,
    String? requirements,
    String? coverImageUrl,
  }) {
    return Tournament(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      clubId: clubId,
      organizerId: organizerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      status: status ?? this.status,
      skillLevelRequired: skillLevelRequired ?? this.skillLevelRequired,
      format: format ?? this.format,
      tournamentType: tournamentType ?? this.tournamentType,
      rules: rules ?? this.rules,
      requirements: requirements ?? this.requirements,
      isPublic: isPublic,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      prizeDistribution: prizeDistribution,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Format display name getter
  String get formatDisplayName {
    switch (tournamentType) {
      case 'single_elimination':
        return 'Single Elimination';
      case 'double_elimination':
        return 'Double Elimination';
      case 'round_robin':
        return 'Round Robin';
      case 'swiss':
        return 'Swiss System';
      case 'sabo_double_elimination':
        return 'SABO DE16';
      case 'sabo_double_elimination_32':
        return 'SABO DE32';
      default:
        return tournamentType.replaceAll('_', ' ').toUpperCase();
    }
  }

  bool get isRegistrationOpen {
    return DateTime.now().isBefore(registrationDeadline) &&
        status == 'upcoming' &&
        currentParticipants < maxParticipants;
  }

  bool get isFull => currentParticipants >= maxParticipants;

  String get statusDisplay {
    switch (status) {
      case 'upcoming':
        return 'Sắp diễn ra';
      case 'ongoing':
        return 'Đang diễn ra';
      case 'completed':
        return 'Đã kết thúc';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Sắp diễn ra';
    }
  }

  String get skillLevelDisplay {
    switch (skillLevelRequired) {
      case 'beginner':
        return 'Người mới';
      case 'intermediate':
        return 'Trung bình';
      case 'advanced':
        return 'Nâng cao';
      case 'professional':
        return 'Chuyên nghiệp';
      default:
        return 'Tất cả';
    }
  }

  Duration get timeToStart => startDate.difference(DateTime.now());
  Duration get timeToRegistrationEnd =>
      registrationDeadline.difference(DateTime.now());

  double get participationRate {
    if (maxParticipants == 0) return 0.0;
    return (currentParticipants / maxParticipants) * 100;
  }
}
