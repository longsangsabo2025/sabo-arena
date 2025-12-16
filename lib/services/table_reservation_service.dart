import 'package:sabo_arena/models/table_reservation.dart';
import 'package:sabo_arena/models/reservation_models.dart';
import 'package:sabo_arena/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// Table Reservation Service
/// Handles all table booking operations
class TableReservationService {
  static TableReservationService? _instance;
  static TableReservationService get instance =>
      _instance ??= TableReservationService._();

  TableReservationService._();

  final _supabase = SupabaseService.instance.client;

  // =====================================================
  // USER ACTIONS
  // =====================================================

  /// Get available time slots for a club on a specific date
  Future<List<AvailableSlot>> getAvailableSlots({
    required String clubId,
    required DateTime date,
    double durationHours = 2.0,
  }) async {
    try {
      // Get club info for pricing and total tables
      final clubResponse = await _supabase
          .from('clubs')
          .select('total_tables, price_per_hour')
          .eq('id', clubId)
          .single();

      final totalTables = clubResponse['total_tables'] as int;
      final pricePerHour =
          (clubResponse['price_per_hour'] as num?)?.toDouble() ?? 50000.0;

      // Get reservations for this date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final reservations = await _supabase
          .from('table_reservations')
          .select()
          .eq('club_id', clubId)
          .gte('start_time', startOfDay.toIso8601String())
          .lt('start_time', endOfDay.toIso8601String())
          .inFilter('status', ['pending', 'confirmed']);

      // Generate time slots (every hour from 8 AM to 10 PM)
      final slots = <AvailableSlot>[];
      for (int hour = 8; hour < 22; hour++) {
        final slotStart = DateTime(date.year, date.month, date.day, hour);
        final slotEnd = slotStart.add(
          Duration(minutes: (durationHours * 60).toInt()),
        );

        // Skip past slots
        if (slotEnd.isBefore(DateTime.now())) continue;

        // Find available tables for this slot
        final availableTables = <int>[];
        for (int tableNum = 1; tableNum <= totalTables; tableNum++) {
          if (_isTableAvailable(
            tableNum,
            slotStart,
            slotEnd,
            reservations as List,
          )) {
            availableTables.add(tableNum);
          }
        }

        slots.add(
          AvailableSlot(
            startTime: slotStart,
            endTime: slotEnd,
            availableTables: availableTables,
            pricePerHour: pricePerHour,
          ),
        );
      }

      return slots;
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getAvailableSlots',
          context: 'Error getting available slots',
        ),
      );
      ProductionLogger.error('Error getting available slots', error: e, stackTrace: stackTrace, tag: 'TableReservation');
      rethrow;
    }
  }

  /// Check if a table is available for a time range
  bool _isTableAvailable(
    int tableNumber,
    DateTime start,
    DateTime end,
    List<dynamic> existingReservations,
  ) {
    for (final reservation in existingReservations) {
      if (reservation['table_number'] == tableNumber) {
        final resStart = DateTime.parse(reservation['start_time']);
        final resEnd = DateTime.parse(reservation['end_time']);

        // Check for overlap
        if ((start.isBefore(resEnd) && end.isAfter(resStart))) {
          return false;
        }
      }
    }
    return true;
  }

  /// Create a new reservation
  Future<TableReservation> createReservation(ReservationRequest request) async {
    try {
      // Verify table is still available
      final isAvailable = await isTableAvailable(
        clubId: request.clubId,
        tableNumber: request.tableNumber,
        startTime: request.startTime,
        endTime: request.endTime,
      );

      if (!isAvailable) {
        throw Exception('Bàn này đã được đặt cho khung giờ này');
      }

      // Create reservation
      final response = await _supabase
          .from('table_reservations')
          .insert(request.toJson())
          .select()
          .single();

      ProductionLogger.info('Reservation created: ${response['id']}', tag: 'TableReservation');

      return TableReservation.fromJson(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'createReservation',
          context: 'Error creating reservation',
        ),
      );
      ProductionLogger.error('Error creating reservation', error: e, stackTrace: stackTrace, tag: 'TableReservation');
      rethrow;
    }
  }

  /// Get reservations for a user
  Future<List<TableReservation>> getUserReservations(String userId) async {
    try {
      final response = await _supabase
          .from('table_reservations')
          .select('''
            *,
            club:clubs(*)
          ''')
          .eq('user_id', userId)
          .order('start_time', ascending: false);

      final reservations = (response as List)
          .map((json) => TableReservation.fromJson(json))
          .toList();

      ProductionLogger.debug('Found ${reservations.length} user reservations', tag: 'TableReservation');
      return reservations;
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getUserReservations',
          context: 'Error getting user reservations',
        ),
      );
      ProductionLogger.error('Error getting user reservations', error: e, stackTrace: stackTrace, tag: 'TableReservation');
      rethrow;
    }
  }

  /// Cancel a reservation
  Future<void> cancelReservation(
    String reservationId,
    String userId,
    String reason,
  ) async {
    try {
      await _supabase
          .from('table_reservations')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
            'cancelled_by': userId,
            'cancellation_reason': reason,
          })
          .eq('id', reservationId)
          .eq('user_id', userId);

      ProductionLogger.info('Reservation cancelled: $reservationId', tag: 'TableReservation');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'cancelReservation',
          context: 'Error cancelling reservation',
        ),
      );
      ProductionLogger.error('Error cancelling reservation', error: e, stackTrace: stackTrace, tag: 'TableReservation');
      rethrow;
    }
  }

  /// Get reservation by ID
  Future<TableReservation> getReservationById(String id) async {
    try {
      final response = await _supabase
          .from('table_reservations')
          .select('''
            *,
            club:clubs(*)
          ''')
          .eq('id', id)
          .single();

      return TableReservation.fromJson(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getReservationById',
          context: 'Error getting reservation',
        ),
      );
      ProductionLogger.error('Error getting reservation', error: e, stackTrace: stackTrace, tag: 'TableReservation');
      rethrow;
    }
  }

  // =====================================================
  // CLUB OWNER ACTIONS
  // =====================================================

  /// Get all reservations for a club
  Future<List<TableReservation>> getClubReservations({
    required String clubId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? statuses,
  }) async {
    try {
      var query = _supabase
          .from('table_reservations')
          .select('''
            *,
            club:clubs(*)
          ''')
          .eq('club_id', clubId);

      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('start_time', endDate.toIso8601String());
      }

      if (statuses != null && statuses.isNotEmpty) {
        query = query.inFilter('status', statuses);
      }

      final response = await query.order('start_time', ascending: true);

      final reservations = (response as List)
          .map((json) => TableReservation.fromJson(json))
          .toList();

      ProductionLogger.debug('Found ${reservations.length} club reservations', tag: 'TableReservation');
      return reservations;
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getClubReservations',
          context: 'Error getting club reservations',
        ),
      );
      ProductionLogger.error('Error getting club reservations', error: e, stackTrace: stackTrace, tag: 'TableReservation');
      rethrow;
    }
  }

  /// Confirm a reservation (club owner)
  Future<void> confirmReservation(String reservationId, String ownerId) async {
    try {
      await _supabase
          .from('table_reservations')
          .update({
            'status': 'confirmed',
            'confirmed_at': DateTime.now().toIso8601String(),
            'confirmed_by': ownerId,
          })
          .eq('id', reservationId);

      ProductionLogger.info('Reservation confirmed: $reservationId', tag: 'TableReservation');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'confirmReservation',
          context: 'Error confirming reservation',
        ),
      );
      ProductionLogger.error('Error confirming reservation', error: e, stackTrace: stackTrace, tag: 'TableReservation');
      rethrow;
    }
  }

  /// Reject a reservation (club owner)
  Future<void> rejectReservation(
    String reservationId,
    String ownerId,
    String reason,
  ) async {
    try {
      await _supabase
          .from('table_reservations')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
            'cancelled_by': ownerId,
            'cancellation_reason': reason,
          })
          .eq('id', reservationId);

      ProductionLogger.info('Reservation rejected: $reservationId', tag: 'TableReservation');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'rejectReservation',
          context: 'Error rejecting reservation',
        ),
      );
      ProductionLogger.error('Error rejecting reservation', error: e, stackTrace: stackTrace, tag: 'TableReservation');
      rethrow;
    }
  }

  /// Mark reservation as completed
  Future<void> markAsCompleted(String reservationId) async {
    try {
      await _supabase
          .from('table_reservations')
          .update({'status': 'completed', 'payment_status': 'fully_paid'})
          .eq('id', reservationId);

      ProductionLogger.info('Reservation marked as completed: $reservationId', tag: 'TableReservation');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'markAsCompleted',
          context: 'Error marking as completed',
        ),
      );
      ProductionLogger.error('Error marking as completed', error: e, stackTrace: stackTrace, tag: 'TableReservation');
      rethrow;
    }
  }

  /// Mark reservation as no-show
  Future<void> markAsNoShow(String reservationId) async {
    try {
      await _supabase
          .from('table_reservations')
          .update({'status': 'no_show'})
          .eq('id', reservationId);

      ProductionLogger.info('Reservation marked as no-show: $reservationId', tag: 'TableReservation');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'markAsNoShow',
          context: 'Error marking as no-show',
        ),
      );
      ProductionLogger.error('Error marking as no-show', error: e, stackTrace: stackTrace, tag: 'TableReservation');
      rethrow;
    }
  }

  /// Get reservation statistics for a club
  Future<ReservationStats> getClubStats({
    required String clubId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('table_reservations')
          .select()
          .eq('club_id', clubId);

      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('start_time', endDate.toIso8601String());
      }

      final response = await query;
      final reservations = response as List;

      // Calculate stats
      final total = reservations.length;
      final pending = reservations
          .where((r) => r['status'] == 'pending')
          .length;
      final confirmed = reservations
          .where((r) => r['status'] == 'confirmed')
          .length;
      final completed = reservations
          .where((r) => r['status'] == 'completed')
          .length;
      final cancelled = reservations
          .where((r) => r['status'] == 'cancelled')
          .length;

      double totalRevenue = 0;
      double expectedRevenue = 0;
      final tableUtil = <int, int>{};

      for (final res in reservations) {
        final price = (res['total_price'] as num).toDouble();
        final tableNum = res['table_number'] as int;

        if (res['status'] == 'completed') {
          totalRevenue += price;
        }
        if (res['status'] == 'confirmed' || res['status'] == 'pending') {
          expectedRevenue += price;
        }

        tableUtil[tableNum] = (tableUtil[tableNum] ?? 0) + 1;
      }

      final avgBooking = total > 0
          ? (totalRevenue + expectedRevenue) / total
          : 0.0;

      return ReservationStats(
        totalReservations: total,
        pendingReservations: pending,
        confirmedReservations: confirmed,
        completedReservations: completed,
        cancelledReservations: cancelled,
        totalRevenue: totalRevenue,
        expectedRevenue: expectedRevenue,
        averageBookingValue: avgBooking,
        tableUtilization: tableUtil,
      );
    } catch (e) {
      ProductionLogger.warning('Error getting club stats', error: e, tag: 'TableReservation');
      return ReservationStats.empty();
    }
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  /// Check if a specific table is available for a time range
  Future<bool> isTableAvailable({
    required String clubId,
    required int tableNumber,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _supabase.rpc(
        'is_table_available',
        params: {
          'p_club_id': clubId,
          'p_table_number': tableNumber,
          'p_start_time': startTime.toIso8601String(),
          'p_end_time': endTime.toIso8601String(),
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      // Fallback to manual check if RPC fails
      ProductionLogger.warning('RPC failed, using fallback check', error: e, tag: 'TableReservation');

      final conflicts = await _supabase
          .from('table_reservations')
          .select()
          .eq('club_id', clubId)
          .eq('table_number', tableNumber)
          .inFilter('status', ['pending', 'confirmed'])
          .or(
            'start_time.lte.${startTime.toIso8601String()},end_time.gt.${startTime.toIso8601String()}',
          )
          .or(
            'start_time.lt.${endTime.toIso8601String()},end_time.gte.${endTime.toIso8601String()}',
          );

      return (conflicts as List).isEmpty;
    }
  }

  /// Calculate price for a time range
  Future<double> calculatePrice({
    required String clubId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final clubResponse = await _supabase
          .from('clubs')
          .select('price_per_hour')
          .eq('id', clubId)
          .single();

      final pricePerHour =
          (clubResponse['price_per_hour'] as num?)?.toDouble() ?? 50000.0;
      final duration = endTime.difference(startTime).inMinutes / 60.0;

      return pricePerHour * duration;
    } catch (e) {
      ProductionLogger.warning('Error calculating price', error: e, tag: 'TableReservation');
      return 0;
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus({
    required String reservationId,
    required PaymentStatus status,
    String? transactionId,
  }) async {
    try {
      final updateData = {
        'payment_status': status.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) {
        updateData['payment_transaction_id'] = transactionId;
      }

      await _supabase
          .from('table_reservations')
          .update(updateData)
          .eq('id', reservationId);

      ProductionLogger.info('Payment status updated: ${status.value}', tag: 'TableReservation');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'updatePaymentStatus',
          context: 'Error updating payment status',
        ),
      );
      ProductionLogger.error('Error updating payment status', error: e, stackTrace: stackTrace, tag: 'TableReservation');
      rethrow;
    }
  }

  /// Real-time subscription for reservations
  RealtimeChannel subscribeToClubReservations({
    required String clubId,
    required Function(TableReservation) onInsert,
    required Function(TableReservation) onUpdate,
    required Function(String) onDelete,
  }) {
    final channel = _supabase
        .channel('club_reservations_$clubId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'table_reservations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'club_id',
            value: clubId,
          ),
          callback: (payload) {
            onInsert(TableReservation.fromJson(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'table_reservations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'club_id',
            value: clubId,
          ),
          callback: (payload) {
            onUpdate(TableReservation.fromJson(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'table_reservations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'club_id',
            value: clubId,
          ),
          callback: (payload) {
            onDelete(payload.oldRecord['id'] as String);
          },
        )
        .subscribe();

    return channel;
  }
}
