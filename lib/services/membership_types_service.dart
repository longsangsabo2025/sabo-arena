import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/membership_type.dart';

/// Service quản lý các loại thành viên CLB
class MembershipTypesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all membership types for a club
  Future<List<MembershipType>> getClubMembershipTypes(String clubId) async {
    try {
      final response = await _supabase
          .from('membership_types')
          .select()
          .eq('club_id', clubId)
          .order('priority', ascending: false)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => MembershipType.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load membership types: $e');
    }
  }

  /// Get only active membership types
  Future<List<MembershipType>> getActiveMembershipTypes(String clubId) async {
    try {
      final response = await _supabase
          .from('membership_types')
          .select()
          .eq('club_id', clubId)
          .eq('is_active', true)
          .order('priority', ascending: false)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => MembershipType.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load active membership types: $e');
    }
  }

  /// Get a single membership type by id
  Future<MembershipType?> getMembershipType(String id) async {
    try {
      final response = await _supabase
          .from('membership_types')
          .select()
          .eq('id', id)
          .single();

      return MembershipType.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create a new membership type
  Future<MembershipType> createMembershipType(MembershipType type) async {
    try {
      final response = await _supabase
          .from('membership_types')
          .insert(type.toInsertJson())
          .select()
          .single();

      return MembershipType.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create membership type: $e');
    }
  }

  /// Update a membership type
  Future<MembershipType> updateMembershipType(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabase
          .from('membership_types')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return MembershipType.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update membership type: $e');
    }
  }

  /// Toggle active status
  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await _supabase
          .from('membership_types')
          .update({'is_active': isActive}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to toggle membership type status: $e');
    }
  }

  /// Delete a membership type
  Future<void> deleteMembershipType(String id) async {
    try {
      await _supabase.from('membership_types').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete membership type: $e');
    }
  }

  /// Check if a name already exists for a club
  Future<bool> nameExists(String clubId, String name,
      {String? excludeId}) async {
    try {
      var query = _supabase
          .from('membership_types')
          .select('id')
          .eq('club_id', clubId)
          .eq('name', name);

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Update priority order
  Future<void> updatePriority(String id, int priority) async {
    try {
      await _supabase
          .from('membership_types')
          .update({'priority': priority}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update priority: $e');
    }
  }

  /// Reorder membership types
  Future<void> reorderTypes(List<String> orderedIds) async {
    try {
      // Update priorities based on order (highest priority first)
      for (int i = 0; i < orderedIds.length; i++) {
        await updatePriority(orderedIds[i], orderedIds.length - i);
      }
    } catch (e) {
      throw Exception('Failed to reorder membership types: $e');
    }
  }
}
