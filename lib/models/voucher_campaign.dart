class VoucherCampaign {
  final String id;
  final String clubId;
  final String title;
  final String? description;
  final String campaignType;
  final String voucherType;
  final int voucherValue;
  final int totalQuantity;
  final int issuedQuantity;
  final DateTime startDate;
  final DateTime endDate;
  final String approvalStatus;
  final String? adminNotes;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? clubName;
  final String? clubOwnerName;

  VoucherCampaign({
    required this.id,
    required this.clubId,
    required this.title,
    this.description,
    required this.campaignType,
    required this.voucherType,
    required this.voucherValue,
    required this.totalQuantity,
    required this.issuedQuantity,
    required this.startDate,
    required this.endDate,
    required this.approvalStatus,
    this.adminNotes,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.clubName,
    this.clubOwnerName,
  });

  factory VoucherCampaign.fromJson(Map<String, dynamic> json) {
    return VoucherCampaign(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      campaignType: json['campaign_type'] as String,
      voucherType: json['voucher_type'] as String,
      voucherValue: json['voucher_value'] as int,
      totalQuantity: json['total_quantity'] as int,
      issuedQuantity: json['issued_quantity'] as int? ?? 0,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      approvalStatus: json['approval_status'] as String? ?? 'pending',
      adminNotes: json['admin_notes'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      clubName: json['club']?['name'] as String?,
      clubOwnerName: json['club']?['owner']?['display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'club_id': clubId,
      'title': title,
      'description': description,
      'campaign_type': campaignType,
      'voucher_type': voucherType,
      'voucher_value': voucherValue,
      'total_quantity': totalQuantity,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }

  bool get isPending => approvalStatus == 'pending';
  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';
  
  String get campaignTypeDisplay {
    switch (campaignType) {
      case 'welcome': return 'Chào Mừng';
      case 'loyalty': return 'Thành Viên';
      case 'prize': return 'Giải Thưởng';
      default: return campaignType;
    }
  }
  
  String get voucherTypeDisplay {
    switch (voucherType) {
      case 'spa_balance': return 'SPA Balance';
      case 'percentage_discount': return 'Giảm %';
      case 'fixed_amount': return 'Giảm VNĐ';
      default: return voucherType;
    }
  }
  
  String get statusDisplay {
    switch (approvalStatus) {
      case 'pending': return 'Chờ Duyệt';
      case 'approved': return 'Đã Duyệt';
      case 'rejected': return 'Từ Chối';
      default: return approvalStatus;
    }
  }
}
