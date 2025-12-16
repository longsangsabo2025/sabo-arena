import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// Service quản lý Welcome Voucher Campaign
/// Tự động tặng voucher cho user mới đăng ký
class WelcomeVoucherService {
  static final WelcomeVoucherService _instance =
      WelcomeVoucherService._internal();
  factory WelcomeVoucherService() => _instance;
  WelcomeVoucherService._internal();

  final _supabase = Supabase.instance.client;

  // ==================== ADMIN: Campaign Management ====================

  /// Get all welcome campaigns (admin only)
  Future<List<Map<String, dynamic>>> getAllCampaigns() async {
    try {
      final response = await _supabase
          .from('welcome_voucher_campaigns')
          .select('''
            *,
            voucher_template:voucher_templates(*)
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getAllCampaigns',
          context: 'Error getting campaigns',
        ),
      );
      ProductionLogger.error('Error getting campaigns', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  /// Create new welcome campaign (admin only)
  Future<Map<String, dynamic>> createCampaign({
    required String name,
    required String description,
    required String templateId,
    String codePrefix = 'WELCOME',
    DateTime? startDate,
    DateTime? endDate,
    int? maxRedemptions,
  }) async {
    try {
      final data = {
        'name': name,
        'description': description,
        'voucher_template_id': templateId,
        'voucher_code_prefix': codePrefix,
        'trigger_on_first_login': true,
        'is_active': true,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'max_redemptions': maxRedemptions,
        'created_by': _supabase.auth.currentUser?.id,
      };

      final response = await _supabase
          .from('welcome_voucher_campaigns')
          .insert(data)
          .select()
          .single();

      ProductionLogger.info('Campaign created: ${response['id']}', tag: 'WelcomeVoucher');
      return response;
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'createCampaign',
          context: 'Error creating campaign',
        ),
      );
      ProductionLogger.error('Error creating campaign', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  /// Update campaign status (admin only)
  Future<void> updateCampaignStatus(String campaignId, bool isActive) async {
    try {
      await _supabase
          .from('welcome_voucher_campaigns')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', campaignId);

      ProductionLogger.info('Campaign status updated', tag: 'WelcomeVoucher');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'updateCampaignStatus',
          context: 'Error updating campaign',
        ),
      );
      ProductionLogger.error('Error updating campaign', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  /// Get campaign statistics (admin only)
  Future<Map<String, dynamic>> getCampaignStats(String campaignId) async {
    try {
      // Get campaign info
      final campaign = await _supabase
          .from('welcome_voucher_campaigns')
          .select('*, voucher_template:voucher_templates(*)')
          .eq('id', campaignId)
          .single();

      // Get participating clubs count
      final clubsResponse = await _supabase
          .from('welcome_campaign_clubs')
          .select('id, status')
          .eq('campaign_id', campaignId);

      final clubs = List<Map<String, dynamic>>.from(clubsResponse);

      final pendingClubs = clubs.where((c) => c['status'] == 'pending').length;
      final approvedClubs = clubs
          .where((c) => c['status'] == 'approved')
          .length;
      final rejectedClubs = clubs
          .where((c) => c['status'] == 'rejected')
          .length;

      // Get issued vouchers count
      final issuedResponse = await _supabase
          .from('welcome_voucher_issued')
          .select('id')
          .eq('campaign_id', campaignId);

      final issuedCount = (issuedResponse as List).length;

      return {
        'campaign': campaign,
        'total_clubs': clubs.length,
        'pending_clubs': pendingClubs,
        'approved_clubs': approvedClubs,
        'rejected_clubs': rejectedClubs,
        'vouchers_issued': issuedCount,
      };
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getCampaignStats',
          context: 'Error getting campaign stats',
        ),
      );
      ProductionLogger.error('Error getting campaign stats', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  // ==================== ADMIN: Club Registration Management ====================

  /// Get club registrations for a campaign (admin only)
  Future<List<Map<String, dynamic>>> getCampaignClubRegistrations(
    String campaignId, {
    String? status,
  }) async {
    try {
      final queryBuilder = _supabase
          .from('welcome_campaign_clubs')
          .select('''
            *,
            club:clubs(*),
            campaign:welcome_voucher_campaigns(*)
          ''')
          .eq('campaign_id', campaignId);

      final query = status != null
          ? queryBuilder.eq('status', status)
          : queryBuilder;

      final response = await query.order('registered_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getCampaignClubRegistrations',
          context: 'Error getting registrations',
        ),
      );
      ProductionLogger.error('Error getting registrations', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  /// Approve club registration (admin only)
  Future<void> approveClubRegistration(String registrationId) async {
    try {
      await _supabase
          .from('welcome_campaign_clubs')
          .update({
            'status': 'approved',
            'approved_by': _supabase.auth.currentUser?.id,
            'approved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', registrationId);

      ProductionLogger.info('Club registration approved', tag: 'WelcomeVoucher');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'approveClubRegistration',
          context: 'Error approving registration',
        ),
      );
      ProductionLogger.error('Error approving registration', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  /// Reject club registration (admin only)
  Future<void> rejectClubRegistration(
    String registrationId,
    String reason,
  ) async {
    try {
      await _supabase
          .from('welcome_campaign_clubs')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', registrationId);

      ProductionLogger.info('Club registration rejected', tag: 'WelcomeVoucher');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'rejectClubRegistration',
          context: 'Error rejecting registration',
        ),
      );
      ProductionLogger.error('Error rejecting registration', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  // ==================== CLUB OWNER: Campaign Registration ====================

  /// Get available campaigns for club to register
  Future<List<Map<String, dynamic>>> getAvailableCampaigns() async {
    try {
      final response = await _supabase
          .from('welcome_voucher_campaigns')
          .select('*, voucher_template:voucher_templates(*)')
          .eq('is_active', true)
          .lte('start_date', DateTime.now().toIso8601String())
          .or(
            'end_date.is.null,end_date.gte.${DateTime.now().toIso8601String()}',
          )
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getAvailableCampaigns',
          context: 'Error getting available campaigns',
        ),
      );
      ProductionLogger.error('Error getting available campaigns', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  /// Club registers to participate in campaign
  Future<Map<String, dynamic>> registerClubForCampaign({
    required String campaignId,
    required String clubId,
  }) async {
    try {
      final data = {
        'campaign_id': campaignId,
        'club_id': clubId,
        'status': 'pending',
      };

      final response = await _supabase
          .from('welcome_campaign_clubs')
          .insert(data)
          .select()
          .single();

      ProductionLogger.info('Club registered for campaign', tag: 'WelcomeVoucher');
      return response;
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'registerClubForCampaign',
          context: 'Error registering club',
        ),
      );
      ProductionLogger.error('Error registering club', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  /// Get club's campaign registrations
  Future<List<Map<String, dynamic>>> getClubCampaignRegistrations(
    String clubId,
  ) async {
    try {
      final response = await _supabase
          .from('welcome_campaign_clubs')
          .select('''
            *,
            campaign:welcome_voucher_campaigns(
              *,
              voucher_template:voucher_templates(*)
            )
          ''')
          .eq('club_id', clubId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getClubCampaignRegistrations',
          context: 'Error getting club registrations',
        ),
      );
      ProductionLogger.error('Error getting club registrations', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  /// Check if club is already registered for campaign
  Future<bool> isClubRegistered(String campaignId, String clubId) async {
    try {
      final response = await _supabase
          .from('welcome_campaign_clubs')
          .select('id')
          .eq('campaign_id', campaignId)
          .eq('club_id', clubId)
          .maybeSingle();

      return response != null;
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'isClubRegistered',
          context: 'Error checking registration',
        ),
      );
      ProductionLogger.error('Error checking registration', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      return false;
    }
  }

  // ==================== USER: Voucher Eligibility ====================

  /// Check if user is eligible for welcome voucher
  Future<Map<String, dynamic>> checkUserEligibility(String userId) async {
    try {
      final response = await _supabase.rpc(
        'check_user_welcome_voucher_eligibility',
        params: {'p_user_id': userId},
      );

      ProductionLogger.debug('Eligibility check: $response', tag: 'WelcomeVoucher');
      return response as Map<String, dynamic>;
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'checkUserEligibility',
          context: 'Error checking eligibility',
        ),
      );
      ProductionLogger.error('Error checking eligibility', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  /// Get user's welcome voucher (if issued)
  Future<Map<String, dynamic>?> getUserWelcomeVoucher(String userId) async {
    try {
      final response = await _supabase
          .from('welcome_voucher_issued')
          .select('''
            *,
            campaign:welcome_voucher_campaigns(*),
            voucher:user_vouchers(
              *,
              template:voucher_templates(*),
              club:clubs(*)
            )
          ''')
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getUserWelcomeVoucher',
          context: 'Error getting welcome voucher',
        ),
      );
      ProductionLogger.error('Error getting welcome voucher', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      return null;
    }
  }

  /// Manually trigger welcome voucher issue (for testing or recovery)
  Future<void> manuallyIssueWelcomeVoucher(String userId) async {
    try {
      // This will trigger the function to check and issue voucher
      await _supabase.rpc(
        'issue_welcome_voucher_on_first_login',
        params: {'user_id': userId},
      );

      ProductionLogger.info('Welcome voucher manually triggered', tag: 'WelcomeVoucher');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'manuallyIssueWelcomeVoucher',
          context: 'Error manually issuing voucher',
        ),
      );
      ProductionLogger.error('Error manually issuing voucher', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }

  // ==================== ANALYTICS ====================

  /// Get overall welcome voucher statistics
  Future<Map<String, dynamic>> getOverallStats() async {
    try {
      // Total campaigns
      final campaignsResponse = await _supabase
          .from('welcome_voucher_campaigns')
          .select('id, is_active');

      final campaigns = List<Map<String, dynamic>>.from(campaignsResponse);
      final activeCampaigns = campaigns
          .where((c) => c['is_active'] == true)
          .length;

      // Total club registrations
      final clubsResponse = await _supabase
          .from('welcome_campaign_clubs')
          .select('id, status');

      final clubRegs = List<Map<String, dynamic>>.from(clubsResponse);
      final approvedClubs = clubRegs
          .where((c) => c['status'] == 'approved')
          .length;

      // Total vouchers issued
      final issuedResponse = await _supabase
          .from('welcome_voucher_issued')
          .select('id');

      final issuedCount = (issuedResponse as List).length;

      return {
        'total_campaigns': campaigns.length,
        'active_campaigns': activeCampaigns,
        'total_club_registrations': clubRegs.length,
        'approved_clubs': approvedClubs,
        'total_vouchers_issued': issuedCount,
      };
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getOverallStats',
          context: 'Error getting overall stats',
        ),
      );
      ProductionLogger.error('Error getting overall stats', error: e, stackTrace: stackTrace, tag: 'WelcomeVoucher');
      rethrow;
    }
  }
}
