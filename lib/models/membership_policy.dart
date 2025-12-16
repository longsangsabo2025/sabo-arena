/// Model cho chính sách thành viên CLB
class MembershipPolicy {
  final String id;
  final String clubId;
  
  // Registration Settings
  final bool requiresApproval;
  final bool allowGuestAccess;
  final bool requiresDeposit;
  final double depositAmount;
  
  // Limits
  final int maxMembersLimit;
  final int minAge;
  final int? maxAge;
  
  // Renewal
  final bool enableAutoRenewal;
  final int renewalReminderDays;
  
  // Requirements
  final List<String> requiredDocuments;
  
  // Terms
  final String? termsAndConditions;
  final String? privacyPolicy;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const MembershipPolicy({
    required this.id,
    required this.clubId,
    this.requiresApproval = true,
    this.allowGuestAccess = false,
    this.requiresDeposit = false,
    this.depositAmount = 0,
    this.maxMembersLimit = 500,
    this.minAge = 16,
    this.maxAge,
    this.enableAutoRenewal = true,
    this.renewalReminderDays = 7,
    this.requiredDocuments = const [],
    this.termsAndConditions,
    this.privacyPolicy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON (Supabase response)
  factory MembershipPolicy.fromJson(Map<String, dynamic> json) {
    // Parse required documents from JSONB
    List<String> documents = [];
    if (json['required_documents'] != null) {
      if (json['required_documents'] is List) {
        documents = (json['required_documents'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return MembershipPolicy(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      requiresApproval: json['requires_approval'] as bool? ?? true,
      allowGuestAccess: json['allow_guest_access'] as bool? ?? false,
      requiresDeposit: json['requires_deposit'] as bool? ?? false,
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0,
      maxMembersLimit: json['max_members_limit'] as int? ?? 500,
      minAge: json['min_age'] as int? ?? 16,
      maxAge: json['max_age'] as int?,
      enableAutoRenewal: json['enable_auto_renewal'] as bool? ?? true,
      renewalReminderDays: json['renewal_reminder_days'] as int? ?? 7,
      requiredDocuments: documents,
      termsAndConditions: json['terms_and_conditions'] as String?,
      privacyPolicy: json['privacy_policy'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'requires_approval': requiresApproval,
      'allow_guest_access': allowGuestAccess,
      'requires_deposit': requiresDeposit,
      'deposit_amount': depositAmount,
      'max_members_limit': maxMembersLimit,
      'min_age': minAge,
      'max_age': maxAge,
      'enable_auto_renewal': enableAutoRenewal,
      'renewal_reminder_days': renewalReminderDays,
      'required_documents': requiredDocuments,
      'terms_and_conditions': termsAndConditions,
      'privacy_policy': privacyPolicy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to JSON for INSERT/UPDATE (without id, timestamps)
  Map<String, dynamic> toUpsertJson() {
    return {
      'club_id': clubId,
      'requires_approval': requiresApproval,
      'allow_guest_access': allowGuestAccess,
      'requires_deposit': requiresDeposit,
      'deposit_amount': depositAmount,
      'max_members_limit': maxMembersLimit,
      'min_age': minAge,
      'max_age': maxAge,
      'enable_auto_renewal': enableAutoRenewal,
      'renewal_reminder_days': renewalReminderDays,
      'required_documents': requiredDocuments,
      'terms_and_conditions': termsAndConditions,
      'privacy_policy': privacyPolicy,
    };
  }

  /// Copy with method
  MembershipPolicy copyWith({
    String? id,
    String? clubId,
    bool? requiresApproval,
    bool? allowGuestAccess,
    bool? requiresDeposit,
    double? depositAmount,
    int? maxMembersLimit,
    int? minAge,
    int? maxAge,
    bool? enableAutoRenewal,
    int? renewalReminderDays,
    List<String>? requiredDocuments,
    String? termsAndConditions,
    String? privacyPolicy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MembershipPolicy(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      allowGuestAccess: allowGuestAccess ?? this.allowGuestAccess,
      requiresDeposit: requiresDeposit ?? this.requiresDeposit,
      depositAmount: depositAmount ?? this.depositAmount,
      maxMembersLimit: maxMembersLimit ?? this.maxMembersLimit,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      enableAutoRenewal: enableAutoRenewal ?? this.enableAutoRenewal,
      renewalReminderDays: renewalReminderDays ?? this.renewalReminderDays,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create default policy for a club
  factory MembershipPolicy.defaultForClub(String clubId) {
    final now = DateTime.now();
    return MembershipPolicy(
      id: '',
      clubId: clubId,
      requiresApproval: true,
      allowGuestAccess: false,
      requiresDeposit: false,
      depositAmount: 0,
      maxMembersLimit: 500,
      minAge: 16,
      enableAutoRenewal: true,
      renewalReminderDays: 7,
      requiredDocuments: [
        'CMND/CCCD',
        'Số điện thoại',
        'Email',
        'Ảnh đại diện',
      ],
      createdAt: now,
      updatedAt: now,
    );
  }
}
