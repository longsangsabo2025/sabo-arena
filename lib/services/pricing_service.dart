import 'package:sabo_arena/services/supabase_service.dart';
import 'package:sabo_arena/models/pricing_models.dart';

class PricingService {
  final _supabase = SupabaseService.instance.client;

  // ============================================================
  // TABLE RATES
  // ============================================================

  /// Get all table rates for a club
  Future<List<TableRate>> getTableRates(String clubId) async {
    try {
      final response = await _supabase
          .from('club_table_rates')
          .select()
          .eq('club_id', clubId)
          .order('display_order')
          .order('name');

      return (response as List)
          .map((json) => TableRate.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load table rates: $e');
    }
  }

  /// Add a new table rate
  Future<TableRate> addTableRate(TableRate rate) async {
    try {
      final response = await _supabase
          .from('club_table_rates')
          .insert(rate.toJson())
          .select()
          .single();

      return TableRate.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add table rate: $e');
    }
  }

  /// Update an existing table rate
  Future<TableRate> updateTableRate(TableRate rate) async {
    try {
      final response = await _supabase
          .from('club_table_rates')
          .update(rate.toJson())
          .eq('id', rate.id)
          .select()
          .single();

      return TableRate.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update table rate: $e');
    }
  }

  /// Delete a table rate
  Future<void> deleteTableRate(String id) async {
    try {
      await _supabase.from('club_table_rates').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete table rate: $e');
    }
  }

  /// Toggle table rate active status
  Future<void> toggleTableRateStatus(String id, bool isActive) async {
    try {
      await _supabase
          .from('club_table_rates')
          .update({'is_active': isActive}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to toggle table rate status: $e');
    }
  }

  // ============================================================
  // MEMBERSHIP FEES
  // ============================================================

  /// Get all membership fees for a club
  Future<List<MembershipFee>> getMembershipFees(String clubId) async {
    try {
      final response = await _supabase
          .from('club_membership_fees')
          .select()
          .eq('club_id', clubId)
          .order('display_order')
          .order('name');

      return (response as List)
          .map((json) => MembershipFee.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load membership fees: $e');
    }
  }

  /// Add a new membership fee
  Future<MembershipFee> addMembershipFee(MembershipFee fee) async {
    try {
      final response = await _supabase
          .from('club_membership_fees')
          .insert(fee.toJson())
          .select()
          .single();

      return MembershipFee.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add membership fee: $e');
    }
  }

  /// Update an existing membership fee
  Future<MembershipFee> updateMembershipFee(MembershipFee fee) async {
    try {
      final response = await _supabase
          .from('club_membership_fees')
          .update(fee.toJson())
          .eq('id', fee.id)
          .select()
          .single();

      return MembershipFee.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update membership fee: $e');
    }
  }

  /// Delete a membership fee
  Future<void> deleteMembershipFee(String id) async {
    try {
      await _supabase.from('club_membership_fees').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete membership fee: $e');
    }
  }

  /// Toggle membership fee active status
  Future<void> toggleMembershipFeeStatus(String id, bool isActive) async {
    try {
      await _supabase
          .from('club_membership_fees')
          .update({'is_active': isActive}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to toggle membership fee status: $e');
    }
  }

  // ============================================================
  // ADDITIONAL SERVICES
  // ============================================================

  /// Get all additional services for a club
  Future<List<AdditionalService>> getAdditionalServices(String clubId) async {
    try {
      final response = await _supabase
          .from('club_additional_services')
          .select()
          .eq('club_id', clubId)
          .order('display_order')
          .order('name');

      return (response as List)
          .map((json) => AdditionalService.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load additional services: $e');
    }
  }

  /// Add a new service
  Future<AdditionalService> addAdditionalService(
    AdditionalService service,
  ) async {
    try {
      final response = await _supabase
          .from('club_additional_services')
          .insert(service.toJson())
          .select()
          .single();

      return AdditionalService.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add service: $e');
    }
  }

  /// Update an existing service
  Future<AdditionalService> updateAdditionalService(
    AdditionalService service,
  ) async {
    try {
      final response = await _supabase
          .from('club_additional_services')
          .update(service.toJson())
          .eq('id', service.id)
          .select()
          .single();

      return AdditionalService.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }

  /// Delete a service
  Future<void> deleteAdditionalService(String id) async {
    try {
      await _supabase.from('club_additional_services').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete service: $e');
    }
  }

  /// Toggle service active status
  Future<void> toggleServiceStatus(String id, bool isActive) async {
    try {
      await _supabase
          .from('club_additional_services')
          .update({'is_active': isActive}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to toggle service status: $e');
    }
  }

  // ============================================================
  // BULK OPERATIONS
  // ============================================================

  /// Get all pricing data for a club
  Future<ClubPricing> getClubPricing(String clubId) async {
    try {
      final tableRates = await getTableRates(clubId);
      final membershipFees = await getMembershipFees(clubId);
      final additionalServices = await getAdditionalServices(clubId);

      return ClubPricing(
        tableRates: tableRates,
        membershipFees: membershipFees,
        additionalServices: additionalServices,
      );
    } catch (e) {
      throw Exception('Failed to load club pricing: $e');
    }
  }

  /// Save all pricing data (batch update)
  Future<void> saveClubPricing(ClubPricing pricing, String clubId) async {
    try {
      // Update table rates
      for (final rate in pricing.tableRates) {
        if (rate.id.isEmpty) {
          await addTableRate(rate.copyWith(clubId: clubId));
        } else {
          await updateTableRate(rate);
        }
      }

      // Update membership fees
      for (final fee in pricing.membershipFees) {
        if (fee.id.isEmpty) {
          await addMembershipFee(fee.copyWith(clubId: clubId));
        } else {
          await updateMembershipFee(fee);
        }
      }

      // Update additional services
      for (final service in pricing.additionalServices) {
        if (service.id.isEmpty) {
          await addAdditionalService(service.copyWith(clubId: clubId));
        } else {
          await updateAdditionalService(service);
        }
      }
    } catch (e) {
      throw Exception('Failed to save club pricing: $e');
    }
  }
}
