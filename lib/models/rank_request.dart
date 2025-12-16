import 'user_profile.dart';

enum RequestStatus { pending, approved, rejected }

class RankRequest {
  final String id;
  final String userId;
  final String clubId;
  final RequestStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? notes;
  final UserProfile? user;

  const RankRequest({
    required this.id,
    required this.userId,
    required this.clubId,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.notes,
    this.user,
  });

  factory RankRequest.fromJson(Map<String, dynamic> json) {
    return RankRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      clubId: json['club_id'] as String,
      status: _parseStatus(json['status'] as String),
      requestedAt: DateTime.parse(json['requested_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      notes: json['notes'] as String?,
      user: json['user'] != null ? UserProfile.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'club_id': clubId,
      'status': status.name,
      'requested_at': requestedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'rejection_reason': rejectionReason,
      'notes': notes,
      'user': user?.toJson(),
    };
  }

  static RequestStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return RequestStatus.pending;
      case 'approved':
        return RequestStatus.approved;
      case 'rejected':
        return RequestStatus.rejected;
      default:
        throw ArgumentError('Invalid status: $status');
    }
  }

  bool get isPending => status == RequestStatus.pending;
  bool get isApproved => status == RequestStatus.approved;
  bool get isRejected => status == RequestStatus.rejected;

  String get statusText {
    switch (status) {
      case RequestStatus.pending:
        return 'Đang chờ duyệt';
      case RequestStatus.approved:
        return 'Đã duyệt';
      case RequestStatus.rejected:
        return 'Đã từ chối';
    }
  }
}
