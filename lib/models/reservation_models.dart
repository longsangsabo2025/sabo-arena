/// Additional models for Table Reservation System

/// Represents a time slot with available tables
class AvailableSlot {
  final DateTime startTime;
  final DateTime endTime;
  final List<int> availableTables;
  final double pricePerHour;

  const AvailableSlot({
    required this.startTime,
    required this.endTime,
    required this.availableTables,
    required this.pricePerHour,
  });

  String get timeDisplay {
    final startStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  String get priceDisplay {
    return '${pricePerHour.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ/giờ';
  }

  int get tableCount => availableTables.length;
  bool get hasAvailableTables => availableTables.isNotEmpty;
}

/// Request model for creating a reservation
class ReservationRequest {
  final String clubId;
  final String userId;
  final int tableNumber;
  final DateTime startTime;
  final DateTime endTime;
  final double durationHours;
  final double pricePerHour;
  final double totalPrice;
  final double depositAmount;
  final String paymentMethod;
  final String? notes;
  final String? specialRequests;
  final int numberOfPlayers;

  const ReservationRequest({
    required this.clubId,
    required this.userId,
    required this.tableNumber,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.pricePerHour,
    required this.totalPrice,
    this.depositAmount = 0,
    required this.paymentMethod,
    this.notes,
    this.specialRequests,
    this.numberOfPlayers = 2,
  });

  Map<String, dynamic> toJson() {
    return {
      'club_id': clubId,
      'user_id': userId,
      'table_number': tableNumber,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_hours': durationHours,
      'price_per_hour': pricePerHour,
      'total_price': totalPrice,
      'deposit_amount': depositAmount,
      'payment_method': paymentMethod,
      'notes': notes,
      'special_requests': specialRequests,
      'number_of_players': numberOfPlayers,
      'status': 'pending',
      'payment_status': depositAmount > 0 ? 'deposit_paid' : 'unpaid',
    };
  }
}

/// Table availability information
class TableAvailability {
  final String id;
  final String clubId;
  final int tableNumber;
  final DateTime date;
  final DateTime timeSlot;
  final bool isAvailable;
  final String? reason;

  const TableAvailability({
    required this.id,
    required this.clubId,
    required this.tableNumber,
    required this.date,
    required this.timeSlot,
    required this.isAvailable,
    this.reason,
  });

  factory TableAvailability.fromJson(Map<String, dynamic> json) {
    return TableAvailability(
      id: json['id'] ?? '',
      clubId: json['club_id'] ?? '',
      tableNumber: json['table_number'] ?? 1,
      date: DateTime.parse(json['date']),
      timeSlot: DateTime.parse(json['time_slot']),
      isAvailable: json['is_available'] ?? true,
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'table_number': tableNumber,
      'date': date.toIso8601String().split('T')[0],
      'time_slot':
          '${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}:00',
      'is_available': isAvailable,
      'reason': reason,
    };
  }
}

/// Reservation statistics for club owners
class ReservationStats {
  final int totalReservations;
  final int pendingReservations;
  final int confirmedReservations;
  final int completedReservations;
  final int cancelledReservations;
  final double totalRevenue;
  final double expectedRevenue;
  final double averageBookingValue;
  final Map<int, int> tableUtilization; // table_number -> booking count

  const ReservationStats({
    required this.totalReservations,
    required this.pendingReservations,
    required this.confirmedReservations,
    required this.completedReservations,
    required this.cancelledReservations,
    required this.totalRevenue,
    required this.expectedRevenue,
    required this.averageBookingValue,
    required this.tableUtilization,
  });

  factory ReservationStats.empty() {
    return const ReservationStats(
      totalReservations: 0,
      pendingReservations: 0,
      confirmedReservations: 0,
      completedReservations: 0,
      cancelledReservations: 0,
      totalRevenue: 0,
      expectedRevenue: 0,
      averageBookingValue: 0,
      tableUtilization: {},
    );
  }

  String get totalRevenueDisplay {
    return '${totalRevenue.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ';
  }

  String get expectedRevenueDisplay {
    return '${expectedRevenue.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ';
  }

  String get averageBookingValueDisplay {
    return '${averageBookingValue.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ';
  }

  int get mostUtilizedTable {
    if (tableUtilization.isEmpty) return 0;
    return tableUtilization.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int get leastUtilizedTable {
    if (tableUtilization.isEmpty) return 0;
    return tableUtilization.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }
}

/// Time slot option for booking
class TimeSlotOption {
  final DateTime startTime;
  final double durationHours;
  final bool isAvailable;

  const TimeSlotOption({
    required this.startTime,
    required this.durationHours,
    this.isAvailable = true,
  });

  DateTime get endTime =>
      startTime.add(Duration(minutes: (durationHours * 60).toInt()));

  String get displayTime {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  bool get isPast => startTime.isBefore(DateTime.now());
}

/// Booking filter options
class ReservationFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? statuses;
  final List<String>? paymentStatuses;
  final int? tableNumber;
  final String? userId;

  const ReservationFilter({
    this.startDate,
    this.endDate,
    this.statuses,
    this.paymentStatuses,
    this.tableNumber,
    this.userId,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String();
    }
    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String();
    }
    if (statuses != null && statuses!.isNotEmpty) {
      params['statuses'] = statuses;
    }
    if (paymentStatuses != null && paymentStatuses!.isNotEmpty) {
      params['payment_statuses'] = paymentStatuses;
    }
    if (tableNumber != null) {
      params['table_number'] = tableNumber;
    }
    if (userId != null) {
      params['user_id'] = userId;
    }

    return params;
  }
}
