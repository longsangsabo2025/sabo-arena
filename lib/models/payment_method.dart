import 'package:flutter/material.dart';

/// Payment Method Model
/// Represents different payment methods for club tournaments
class PaymentMethod {
  final String id;
  final String clubId;
  final PaymentMethodType type;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final String? qrCodeUrl; // URL to QR code image in storage
  final String? qrCodePath; // Path in storage
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata; // Additional info

  PaymentMethod({
    required this.id,
    required this.clubId,
    required this.type,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.qrCodeUrl,
    this.qrCodePath,
    this.isActive = true,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      type: PaymentMethodType.fromString(map['method_type'] as String? ?? map['type'] as String),
      bankName: map['bank_name'] as String?,
      accountNumber: map['account_number'] as String?,
      accountName: map['account_holder'] as String? ?? map['account_name'] as String?,
      qrCodeUrl: map['qr_code_url'] as String?,
      qrCodePath: map['qr_code_path'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      isDefault: map['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'club_id': clubId,
      'method_type': type.value,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_holder': accountName,
      'qr_code_url': qrCodeUrl,
      'qr_code_path': qrCodePath,
      'is_active': isActive,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  PaymentMethod copyWith({
    String? id,
    String? clubId,
    PaymentMethodType? type,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? qrCodeUrl,
    String? qrCodePath,
    bool? isActive,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      type: type ?? this.type,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      qrCodePath: qrCodePath ?? this.qrCodePath,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum PaymentMethodType {
  bankTransfer(
    'bank_transfer',
    'Chuyển khoản ngân hàng',
    true,
    Icons.account_balance,
  ),
  qrCode(
    'qr_code',
    'Quét mã QR',
    true,
    Icons.qr_code_2,
  ),
  cash('cash', 'Tiền mặt tại quán', true, Icons.store),
  momo('momo', 'Ví MoMo', true, Icons.account_balance_wallet),
  zalopay('zalopay', 'ZaloPay', false, Icons.payment),
  vnpay('vnpay', 'VNPay', false, Icons.credit_card),
  other('other', 'Khác', true, Icons.more_horiz);

  final String value;
  final String displayName;
  final bool isDeveloped; // true = can be enabled, false = coming soon
  final IconData icon;

  const PaymentMethodType(
    this.value,
    this.displayName,
    this.isDeveloped,
    this.icon,
  );

  static PaymentMethodType fromString(String value) {
    return PaymentMethodType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PaymentMethodType.other,
    );
  }
}

/// Tournament Registration Payment
/// Tracks payment for tournament registration
class TournamentPayment {
  final String id;
  final String tournamentId;
  final String userId;
  final String clubId;
  final String paymentMethodId;
  final double amount;
  final PaymentStatus status;
  final String? proofImageUrl; // Screenshot of transfer
  final String? proofImagePath;
  final String? transactionNote;
  final String? transactionReference; // Bank transaction ID
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? verifiedAt;
  final String? verifiedBy; // Admin user ID who verified
  final String? rejectionReason;

  TournamentPayment({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.clubId,
    required this.paymentMethodId,
    required this.amount,
    required this.status,
    this.proofImageUrl,
    this.proofImagePath,
    this.transactionNote,
    this.transactionReference,
    required this.createdAt,
    this.paidAt,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
  });

  factory TournamentPayment.fromMap(Map<String, dynamic> map) {
    return TournamentPayment(
      id: map['id'] as String,
      tournamentId: map['tournament_id'] as String,
      userId: map['user_id'] as String,
      clubId: map['club_id'] as String,
      paymentMethodId: map['payment_method_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: PaymentStatus.fromString(map['status'] as String),
      proofImageUrl: map['proof_image_url'] as String?,
      proofImagePath: map['proof_image_path'] as String?,
      transactionNote: map['transaction_note'] as String?,
      transactionReference: map['transaction_reference'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      paidAt: map['paid_at'] != null
          ? DateTime.parse(map['paid_at'] as String)
          : null,
      verifiedAt: map['verified_at'] != null
          ? DateTime.parse(map['verified_at'] as String)
          : null,
      verifiedBy: map['verified_by'] as String?,
      rejectionReason: map['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'user_id': userId,
      'club_id': clubId,
      'payment_method_id': paymentMethodId,
      'amount': amount,
      'status': status.value,
      'proof_image_url': proofImageUrl,
      'proof_image_path': proofImagePath,
      'transaction_note': transactionNote,
      'transaction_reference': transactionReference,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'rejection_reason': rejectionReason,
    };
  }
}

enum PaymentStatus {
  pending('pending', 'Chờ thanh toán'),
  paid('paid', 'Đã thanh toán'),
  verifying('verifying', 'Đang xác minh'),
  verified('verified', 'Đã xác nhận'),
  rejected('rejected', 'Từ chối'),
  refunded('refunded', 'Đã hoàn tiền');

  final String value;
  final String displayName;

  const PaymentStatus(this.value, this.displayName);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  Color get color {
    switch (this) {
      case PaymentStatus.pending:
        return const Color(0xFFFFA500); // Orange
      case PaymentStatus.paid:
      case PaymentStatus.verifying:
        return const Color(0xFF2196F3); // Blue
      case PaymentStatus.verified:
        return const Color(0xFF4CAF50); // Green
      case PaymentStatus.rejected:
        return const Color(0xFFF44336); // Red
      case PaymentStatus.refunded:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}
