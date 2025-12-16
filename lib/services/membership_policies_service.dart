import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/membership_policy.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service quản lý chính sách thành viên CLB
class MembershipPoliciesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get policy for a club
  Future<MembershipPolicy?> getClubPolicy(String clubId) async {
    try {
      final response = await _supabase
          .from('membership_policies')
          .select()
          .eq('club_id', clubId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return MembershipPolicy.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load membership policy: $e');
    }
  }

  /// Get policy or create default if not exists
  Future<MembershipPolicy> getOrCreatePolicy(String clubId) async {
    try {
      final existing = await getClubPolicy(clubId);
      
      if (existing != null) {
        return existing;
      }

      // Create default policy
      final defaultPolicy = MembershipPolicy.defaultForClub(clubId);
      return await savePolicy(defaultPolicy);
    } catch (e) {
      throw Exception('Failed to get or create policy: $e');
    }
  }

  /// Save (upsert) policy for a club
  Future<MembershipPolicy> savePolicy(MembershipPolicy policy) async {
    try {
      ProductionLogger.info('🔵 [MembershipPoliciesService] Saving policy for club: ${policy.clubId}', tag: 'membership_policies_service');
      ProductionLogger.info('🔵 [MembershipPoliciesService] Policy data: ${policy.toUpsertJson()}', tag: 'membership_policies_service');
      
      final response = await _supabase
          .from('membership_policies')
          .upsert(
            policy.toUpsertJson(),
            onConflict: 'club_id', // UNIQUE constraint on club_id
          )
          .select()
          .single();

      ProductionLogger.info('✅ [MembershipPoliciesService] Save successful!', tag: 'membership_policies_service');
      ProductionLogger.info('✅ [MembershipPoliciesService] Response: $response', tag: 'membership_policies_service');
      
      return MembershipPolicy.fromJson(response);
    } catch (e) {
      ProductionLogger.info('❌ [MembershipPoliciesService] Save failed: $e', tag: 'membership_policies_service');
      throw Exception('Failed to save membership policy: $e');
    }
  }

  /// Update specific fields of a policy
  Future<MembershipPolicy> updatePolicy(
    String clubId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabase
          .from('membership_policies')
          .update(updates)
          .eq('club_id', clubId)
          .select()
          .single();

      return MembershipPolicy.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update membership policy: $e');
    }
  }

  /// Update registration settings
  Future<MembershipPolicy> updateRegistrationSettings({
    required String clubId,
    required bool requiresApproval,
    required bool allowGuestAccess,
    required bool requiresDeposit,
    required double depositAmount,
  }) async {
    return await updatePolicy(clubId, {
      'requires_approval': requiresApproval,
      'allow_guest_access': allowGuestAccess,
      'requires_deposit': requiresDeposit,
      'deposit_amount': depositAmount,
    });
  }

  /// Update limits
  Future<MembershipPolicy> updateLimits({
    required String clubId,
    required int maxMembersLimit,
    required int minAge,
    int? maxAge,
  }) async {
    return await updatePolicy(clubId, {
      'max_members_limit': maxMembersLimit,
      'min_age': minAge,
      'max_age': maxAge,
    });
  }

  /// Update renewal settings
  Future<MembershipPolicy> updateRenewalSettings({
    required String clubId,
    required bool enableAutoRenewal,
    required int renewalReminderDays,
  }) async {
    return await updatePolicy(clubId, {
      'enable_auto_renewal': enableAutoRenewal,
      'renewal_reminder_days': renewalReminderDays,
    });
  }

  /// Update required documents
  Future<MembershipPolicy> updateRequiredDocuments({
    required String clubId,
    required List<String> requiredDocuments,
  }) async {
    return await updatePolicy(clubId, {
      'required_documents': requiredDocuments,
    });
  }

  /// Update terms and policies
  Future<MembershipPolicy> updateTerms({
    required String clubId,
    String? termsAndConditions,
    String? privacyPolicy,
  }) async {
    return await updatePolicy(clubId, {
      'terms_and_conditions': termsAndConditions,
      'privacy_policy': privacyPolicy,
    });
  }

  /// Delete policy for a club
  Future<void> deletePolicy(String clubId) async {
    try {
      await _supabase
          .from('membership_policies')
          .delete()
          .eq('club_id', clubId);
    } catch (e) {
      throw Exception('Failed to delete membership policy: $e');
    }
  }

  /// Check if policy exists for a club
  Future<bool> policyExists(String clubId) async {
    try {
      final response = await _supabase
          .from('membership_policies')
          .select('id')
          .eq('club_id', clubId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}
