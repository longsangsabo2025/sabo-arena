import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/production_logger.dart';

/// Service for account deactivation and deletion
class AccountManagementService {
  static final AccountManagementService instance =
      AccountManagementService._internal();
  factory AccountManagementService() => instance;
  AccountManagementService._internal();

  final _supabase = Supabase.instance.client;

  /// Deactivate current user's account (soft delete - reversible)
  /// User can reactivate by logging in again
  Future<void> deactivateAccount({String? reason}) async {
    try {
      ProductionLogger.info('Deactivating account', tag: 'AccountManagement');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Update user record
      await _supabase.from('users').update({
        'is_deactivated': true,
        'deactivated_at': DateTime.now().toIso8601String(),
        'deactivation_reason': reason,
      }).eq('id', userId);

      ProductionLogger.info('Account deactivated successfully',
          tag: 'AccountManagement');

      // Sign out user
      await _supabase.auth.signOut();
    } catch (error) {
      ProductionLogger.error(
        'Failed to deactivate account',
        error: error,
        tag: 'AccountManagement',
      );
      rethrow;
    }
  }

  /// Reactivate account (called automatically on login)
  Future<void> reactivateAccount(String userId) async {
    try {
      ProductionLogger.info('Reactivating account: $userId',
          tag: 'AccountManagement');

      await _supabase.from('users').update({
        'is_deactivated': false,
        'deactivated_at': null,
        'deactivation_reason': null,
      }).eq('id', userId);

      ProductionLogger.info('Account reactivated successfully',
          tag: 'AccountManagement');
    } catch (error) {
      ProductionLogger.error(
        'Failed to reactivate account',
        error: error,
        tag: 'AccountManagement',
      );
      rethrow;
    }
  }

  /// Check if account is deactivated
  Future<bool> isAccountDeactivated(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_deactivated')
          .eq('id', userId)
          .maybeSingle();

      return response?['is_deactivated'] ?? false;
    } catch (error) {
      ProductionLogger.error(
        'Failed to check account status',
        error: error,
        tag: 'AccountManagement',
      );
      return false;
    }
  }

  /// Delete account permanently (IRREVERSIBLE)
  /// Requires password confirmation before calling this
  Future<void> deleteAccountPermanently({
    required String password,
    String? reason,
  }) async {
    try {
      ProductionLogger.warning('Starting permanent account deletion',
          tag: 'AccountManagement');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userId = user.id;
      final email = user.email;
      if (email == null) {
        throw Exception('User email not found');
      }

      // Step 1: Re-authenticate to verify password
      ProductionLogger.info('Re-authenticating for deletion',
          tag: 'AccountManagement');
      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        throw Exception('Mật khẩu không đúng. Vui lòng thử lại.');
      }

      // Step 2: Log deletion to audit table
      ProductionLogger.info('Logging account deletion',
          tag: 'AccountManagement');
      try {
        // Get user data before deletion
        final userData = await _supabase
            .from('users')
            .select('full_name, email, phone')
            .eq('id', userId)
            .maybeSingle();

        await _supabase.from('deleted_accounts_log').insert({
          'user_id': userId,
          'email': email,
          'full_name': userData?['full_name'] ?? 'Unknown',
          'phone': userData?['phone'],
          'deletion_reason': reason,
          'deleted_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        ProductionLogger.warning('Failed to log deletion, continuing anyway',
            tag: 'AccountManagement');
      }

      // Step 3: Delete related data (cascade)
      ProductionLogger.info('Deleting user data', tag: 'AccountManagement');

      // Delete user posts
      await _supabase.from('posts').delete().eq('user_id', userId);

      // Delete notifications
      await _supabase.from('notifications').delete().eq('user_id', userId);

      // Delete privacy settings
      await _supabase
          .from('user_privacy_settings')
          .delete()
          .eq('user_id', userId);

      // Delete user blocks (both as blocker and blocked)
      await _supabase
          .from('user_blocks')
          .delete()
          .eq('blocker_user_id', userId);
      await _supabase
          .from('user_blocks')
          .delete()
          .eq('blocked_user_id', userId);

      // Delete sessions
      await _supabase.from('user_sessions').delete().eq('user_id', userId);

      // Delete club memberships
      await _supabase.from('club_members').delete().eq('user_id', userId);

      // Delete tournament participants
      await _supabase
          .from('tournament_participants')
          .delete()
          .eq('user_id', userId);

      // Delete match records
      await _supabase.from('matches').delete().eq('user1_id', userId);
      await _supabase.from('matches').delete().eq('user2_id', userId);

      // Step 4: Delete user record
      ProductionLogger.info('Deleting user record', tag: 'AccountManagement');
      await _supabase.from('users').delete().eq('id', userId);

      // Step 5: Delete auth user (Supabase Auth)
      ProductionLogger.info('Deleting auth user', tag: 'AccountManagement');
      await _supabase.auth.admin.deleteUser(userId);

      ProductionLogger.warning('Account deleted permanently',
          tag: 'AccountManagement');

      // Sign out
      await _supabase.auth.signOut();
    } catch (error) {
      ProductionLogger.error(
        'Failed to delete account',
        error: error,
        tag: 'AccountManagement',
      );
      rethrow;
    }
  }

  /// Get account data for export (GDPR compliance)
  Future<Map<String, dynamic>> exportAccountData() async {
    try {
      ProductionLogger.info('Exporting account data', tag: 'AccountManagement');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user data
      final userData =
          await _supabase.from('users').select().eq('id', userId).single();

      // Get privacy settings
      final privacyData = await _supabase
          .from('user_privacy_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // Get posts
      final postsData =
          await _supabase.from('posts').select().eq('user_id', userId);

      // Get matches
      final matchesData = await _supabase
          .from('matches')
          .select()
          .or('user1_id.eq.$userId,user2_id.eq.$userId');

      // Get tournament participations
      final tournamentsData = await _supabase
          .from('tournament_participants')
          .select('tournament_id, status, joined_at')
          .eq('user_id', userId);

      return {
        'user': userData,
        'privacy_settings': privacyData,
        'posts': postsData,
        'matches': matchesData,
        'tournaments': tournamentsData,
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      ProductionLogger.error(
        'Failed to export account data',
        error: error,
        tag: 'AccountManagement',
      );
      rethrow;
    }
  }
}
