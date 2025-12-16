import 'package:sabo_arena/models/club.dart';
import 'package:sabo_arena/models/user_profile.dart';

/// Table Reservation Model
/// Represents a booking for a billiard table at a club
class TableReservation {
  final String id;
  final String clubId;
  final String userId;
  final int tableNumber;

  // Time information
  final DateTime startTime;
  final DateTime endTime;
  final double durationHours;

  // Pricing
  final double pricePerHour;
  final double totalPrice;
  final double depositAmount;

  // Status
  final ReservationStatus status;
  final PaymentStatus paymentStatus;
  final String? paymentMethod;
  final String? paymentTransactionId;

  // Additional info
  final String? notes;
  final String? specialRequests;
  final int numberOfPlayers;

  // Confirmation and cancellation
  final DateTime? confirmedAt;
  final String? confirmedBy;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations (loaded separately)
  final Club? club;
  final UserProfile? user;

  const TableReservation({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.tableNumber,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.pricePerHour,
    required this.totalPrice,
    this.depositAmount = 0,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentTransactionId,
    this.notes,
    this.specialRequests,
    this.numberOfPlayers = 2,
    this.confirmedAt,
    this.confirmedBy,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.club,
    this.user,
  });

  factory TableReservation.fromJson(Map<String, dynamic> json) {
    return TableReservation(
      id: json['id'] ?? '',
      clubId: json['club_id'] ?? '',
      userId: json['user_id'] ?? '',
      tableNumber: json['table_number'] ?? 1,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      durationHours: (json['duration_hours'] as num).toDouble(),
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      depositAmount: json['deposit_amount'] != null
          ? (json['deposit_amount'] as num).toDouble()
          : 0,
      status: ReservationStatus.fromString(json['status'] ?? 'pending'),
      paymentStatus: PaymentStatus.fromString(
        json['payment_status'] ?? 'unpaid',
      ),
      paymentMethod: json['payment_method'],
      paymentTransactionId: json['payment_transaction_id'],
      notes: json['notes'],
      specialRequests: json['special_requests'],
      numberOfPlayers: json['number_of_players'] ?? 2,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      confirmedBy: json['confirmed_by'],
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      cancelledBy: json['cancelled_by'],
      cancellationReason: json['cancellation_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      club: json['club'] != null ? Club.fromJson(json['club']) : null,
      user: json['user'] != null ? UserProfile.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'user_id': userId,
      'table_number': tableNumber,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_hours': durationHours,
      'price_per_hour': pricePerHour,
      'total_price': totalPrice,
      'deposit_amount': depositAmount,
      'status': status.value,
      'payment_status': paymentStatus.value,
      'payment_method': paymentMethod,
      'payment_transaction_id': paymentTransactionId,
      'notes': notes,
      'special_requests': specialRequests,
      'number_of_players': numberOfPlayers,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'confirmed_by': confirmedBy,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancelled_by': cancelledBy,
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TableReservation copyWith({
    String? id,
    String? clubId,
    String? userId,
    int? tableNumber,
    DateTime? startTime,
    DateTime? endTime,
    double? durationHours,
    double? pricePerHour,
    double? totalPrice,
    double? depositAmount,
    ReservationStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    String? paymentTransactionId,
    String? notes,
    String? specialRequests,
    int? numberOfPlayers,
    DateTime? confirmedAt,
    String? confirmedBy,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    Club? club,
    UserProfile? user,
  }) {
    return TableReservation(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      userId: userId ?? this.userId,
      tableNumber: tableNumber ?? this.tableNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationHours: durationHours ?? this.durationHours,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      totalPrice: totalPrice ?? this.totalPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      notes: notes ?? this.notes,
      specialRequests: specialRequests ?? this.specialRequests,
      numberOfPlayers: numberOfPlayers ?? this.numberOfPlayers,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      club: club ?? this.club,
      user: user ?? this.user,
    );
  }

  // Helper getters
  String get statusDisplay => status.displayName;
  String get paymentStatusDisplay => paymentStatus.displayName;

  String get timeRangeDisplay {
    final startStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  String get dateDisplay {
    final day = startTime.day.toString().padLeft(2, '0');
    final month = startTime.month.toString().padLeft(2, '0');
    final year = startTime.year;
    return '$day/$month/$year';
  }

  String get priceDisplay {
    return '${totalPrice.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ';
  }

  String get depositDisplay {
    return '${depositAmount.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ';
  }

  bool get canCancel => status == ReservationStatus.pending;
  bool get canConfirm =>
      status == ReservationStatus.pending &&
      paymentStatus != PaymentStatus.unpaid;
  bool get requiresPayment => paymentStatus == PaymentStatus.unpaid;
  bool get isPast => endTime.isBefore(DateTime.now());
  bool get isUpcoming =>
      startTime.isAfter(DateTime.now()) &&
      status == ReservationStatus.confirmed;
}

/// Reservation Status Enum
enum ReservationStatus {
  pending('pending', 'Chờ xác nhận', '⏳'),
  confirmed('confirmed', 'Đã xác nhận', '✅'),
  cancelled('cancelled', 'Đã hủy', '❌'),
  completed('completed', 'Hoàn thành', '✔️'),
  noShow('no_show', 'Không đến', '⚠️');

  final String value;
  final String displayName;
  final String icon;

  const ReservationStatus(this.value, this.displayName, this.icon);

  static ReservationStatus fromString(String value) {
    return ReservationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReservationStatus.pending,
    );
  }
}

/// Payment Status Enum
enum PaymentStatus {
  unpaid('unpaid', 'Chưa thanh toán', '💳'),
  depositPaid('deposit_paid', 'Đã đặt cọc', '💰'),
  fullyPaid('fully_paid', 'Đã thanh toán', '✅'),
  refunded('refunded', 'Đã hoàn tiền', '↩️');

  final String value;
  final String displayName;
  final String icon;

  const PaymentStatus(this.value, this.displayName, this.icon);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}
