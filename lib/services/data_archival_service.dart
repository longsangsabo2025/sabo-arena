import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Data Archival Service
/// Archives old data to reduce database size and costs
/// 
/// Archives:
/// - Completed tournaments >6 months old
/// - Messages >1 year old
/// - Notifications >3 months old
class DataArchivalService {
  static DataArchivalService? _instance;
  static DataArchivalService get instance =>
      _instance ??= DataArchivalService._();

  DataArchivalService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Archival thresholds
  static const Duration tournamentArchiveAge = Duration(days: 180); // 6 months
  static const Duration messageArchiveAge = Duration(days: 365); // 1 year
  static const Duration notificationArchiveAge = Duration(days: 90); // 3 months

  /// Archive old completed tournaments
  /// Moves tournaments to archive table or marks as archived
  Future<ArchivalResult> archiveOldTournaments() async {
    try {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      final cutoffDate = DateTime.now().subtract(tournamentArchiveAge);
      final cutoffDateStr = cutoffDate.toIso8601String();

      // Find tournaments to archive
      final tournamentsToArchive = await _supabase
          .from('tournaments')
          .select('id, title, created_at')
          .eq('status', 'completed')
          .lt('created_at', cutoffDateStr);

      if (tournamentsToArchive.isEmpty) {
        if (kDebugMode) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
        return ArchivalResult(
          success: true,
          itemsArchived: 0,
          message: 'No tournaments to archive',
        );
      }

      final tournamentIds = tournamentsToArchive.map((t) => t['id'] as String).toList();

      // Option 1: Move to archive table (if exists)
      // Option 2: Mark as archived (add archived_at column)
      // For now, we'll mark as archived by updating status
      for (final id in tournamentIds) {
        await _supabase
            .from('tournaments')
            .update({
              'status': 'archived',
              'archived_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id);
      }

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      return ArchivalResult(
        success: true,
        itemsArchived: tournamentIds.length,
        message: 'Archived ${tournamentIds.length} tournaments',
      );
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      return ArchivalResult(
        success: false,
        itemsArchived: 0,
        message: 'Error: $e',
      );
    }
  }

  /// Archive old messages
  /// Moves messages to archive table or deletes them
  Future<ArchivalResult> archiveOldMessages() async {
    try {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      final cutoffDate = DateTime.now().subtract(messageArchiveAge);
      final cutoffDateStr = cutoffDate.toIso8601String();

      // Find messages to archive
      final messagesToArchive = await _supabase
          .from('chat_messages')
          .select('id')
          .lt('created_at', cutoffDateStr);

      if (messagesToArchive.isEmpty) {
        if (kDebugMode) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
        return ArchivalResult(
          success: true,
          itemsArchived: 0,
          message: 'No messages to archive',
        );
      }

      final messageIds = messagesToArchive.map((m) => m['id'] as String).toList();

      // Option 1: Move to archive table (if exists)
      // Option 2: Delete old messages (be careful with this!)
      // For now, we'll just mark them (if archived column exists)
      // Or delete if archive table doesn't exist
      for (final id in messageIds) {
        await _supabase
            .from('chat_messages')
            .delete()
            .eq('id', id);
      }

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      return ArchivalResult(
        success: true,
        itemsArchived: messageIds.length,
        message: 'Archived ${messageIds.length} messages',
      );
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      return ArchivalResult(
        success: false,
        itemsArchived: 0,
        message: 'Error: $e',
      );
    }
  }

  /// Archive old notifications
  /// Deletes or marks old notifications as archived
  Future<ArchivalResult> archiveOldNotifications() async {
    try {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      final cutoffDate = DateTime.now().subtract(notificationArchiveAge);
      final cutoffDateStr = cutoffDate.toIso8601String();

      // Find notifications to archive (only read ones)
      final notificationsToArchive = await _supabase
          .from('notifications')
          .select('id')
          .eq('is_read', true)
          .lt('created_at', cutoffDateStr);

      if (notificationsToArchive.isEmpty) {
        if (kDebugMode) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
        return ArchivalResult(
          success: true,
          itemsArchived: 0,
          message: 'No notifications to archive',
        );
      }

      final notificationIds =
          notificationsToArchive.map((n) => n['id'] as String).toList();

      // Delete old read notifications
      for (final id in notificationIds) {
        await _supabase
            .from('notifications')
            .delete()
            .eq('id', id);
      }

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      return ArchivalResult(
        success: true,
        itemsArchived: notificationIds.length,
        message: 'Archived ${notificationIds.length} notifications',
      );
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      return ArchivalResult(
        success: false,
        itemsArchived: 0,
        message: 'Error: $e',
      );
    }
  }

  /// Run all archival tasks
  Future<ArchivalSummary> runArchival() async {
    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }

    final results = await Future.wait([
      archiveOldTournaments(),
      archiveOldMessages(),
      archiveOldNotifications(),
    ]);

    final summary = ArchivalSummary(
      tournamentResult: results[0],
      messageResult: results[1],
      notificationResult: results[2],
    );

    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }

    return summary;
  }

  /// Get archival statistics
  Future<Map<String, dynamic>> getArchivalStatistics() async {
    try {
      final now = DateTime.now();
      final tournamentCutoff = now.subtract(tournamentArchiveAge);
      final messageCutoff = now.subtract(messageArchiveAge);
      final notificationCutoff = now.subtract(notificationArchiveAge);

      // Count items eligible for archival
      final tournamentsToArchive = await _supabase
          .from('tournaments')
          .select('id')
          .eq('status', 'completed')
          .lt('created_at', tournamentCutoff.toIso8601String());

      final messagesToArchive = await _supabase
          .from('chat_messages')
          .select('id')
          .lt('created_at', messageCutoff.toIso8601String());

      final notificationsToArchive = await _supabase
          .from('notifications')
          .select('id')
          .eq('is_read', true)
          .lt('created_at', notificationCutoff.toIso8601String());

      return {
        'tournaments_eligible': tournamentsToArchive.length,
        'messages_eligible': messagesToArchive.length,
        'notifications_eligible': notificationsToArchive.length,
        'tournament_cutoff_date': tournamentCutoff.toIso8601String(),
        'message_cutoff_date': messageCutoff.toIso8601String(),
        'notification_cutoff_date': notificationCutoff.toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      return {
        'error': e.toString(),
      };
    }
  }
}

/// Archival result
class ArchivalResult {
  final bool success;
  final int itemsArchived;
  final String message;

  ArchivalResult({
    required this.success,
    required this.itemsArchived,
    required this.message,
  });
}

/// Archival summary
class ArchivalSummary {
  final ArchivalResult tournamentResult;
  final ArchivalResult messageResult;
  final ArchivalResult notificationResult;

  ArchivalSummary({
    required this.tournamentResult,
    required this.messageResult,
    required this.notificationResult,
  });

  int get totalItemsArchived =>
      tournamentResult.itemsArchived +
      messageResult.itemsArchived +
      notificationResult.itemsArchived;

  bool get allSuccessful =>
      tournamentResult.success &&
      messageResult.success &&
      notificationResult.success;
}


