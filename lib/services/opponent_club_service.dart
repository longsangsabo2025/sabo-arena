import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/club.dart';
// ELON_MODE_AUTO_FIX

/// Service để lấy dữ liệu CLB thật từ Supabase cho tab đối thủ
class OpponentClubService {
  static OpponentClubService? _instance;
  static OpponentClubService get instance =>
      _instance ??= OpponentClubService._();
  OpponentClubService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache để tránh gọi API liên tục
  List<Club>? _cachedClubs;
  DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(minutes: 10);

  /// Lấy danh sách CLB từ Supabase
  Future<List<Club>> getActiveClubs() async {
    try {
      // Check cache first
      if (_cachedClubs != null &&
          _lastFetch != null &&
          DateTime.now().difference(_lastFetch!) < _cacheTimeout) {
        return _cachedClubs!;
      }

      final response = await _supabase
          .from('clubs')
          .select('''
            id,
            name,
            description,
            address,
            phone,
            email,
            cover_image_url,
            profile_image_url,
            total_tables,
            is_verified,
            is_active,
            approval_status,
            rating,
            total_reviews,
            created_at,
            updated_at
          ''')
          .eq('is_active', true)
          .eq('approval_status', 'approved')
          .order('rating', ascending: false)
          .limit(50); // Giới hạn 50 CLB top

      final clubs = response.map<Club>((json) => Club.fromJson(json)).toList();

      // Update cache
      _cachedClubs = clubs;
      _lastFetch = DateTime.now();

      return clubs;
    } catch (error) {
      // Return fallback mock data if Supabase fails
      return _getFallbackClubs();
    }
  }

  /// Lấy CLB ngẫu nhiên để hiển thị cho player
  Future<String> getRandomClubName() async {
    try {
      final clubs = await getActiveClubs();

      if (clubs.isEmpty) {
        return _getFallbackClubName();
      }

      // Random club from active clubs
      final randomIndex = DateTime.now().millisecondsSinceEpoch % clubs.length;
      return clubs[randomIndex].name;
    } catch (error) {
      return _getFallbackClubName();
    }
  }

  /// Lấy CLB theo ID cụ thể (nếu cần)
  Future<Club?> getClubById(String clubId) async {
    try {
      final clubs = await getActiveClubs();
      return clubs.firstWhere(
        (club) => club.id == clubId,
        orElse: () =>
            clubs.isNotEmpty ? clubs.first : _getFallbackClubs().first,
      );
    } catch (error) {
      return null;
    }
  }

  /// Clear cache để force refresh
  void clearCache() {
    _cachedClubs = null;
    _lastFetch = null;
  }

  /// Fallback clubs nếu Supabase không hoạt động
  List<Club> _getFallbackClubs() {
    return [
      Club(
        id: 'fallback-1',
        ownerId: 'owner1',
        name: 'CLB SABO ARENA',
        description: 'Câu lạc bộ billiards hàng đầu',
        address: '123 Nguyễn Huệ, Q1, TPHCM',
        phone: '0901234567',
        email: 'contact@saboarena.com',
        coverImageUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96',
        profileImageUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96',
        totalTables: 20,
        isVerified: true,
        isActive: true,
        approvalStatus: 'approved',
        rating: 4.8,
        totalReviews: 150,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Club(
        id: 'fallback-2',
        ownerId: 'owner2',
        name: 'CLB BILLIARDS SAIGON',
        description: 'Billiards chuyên nghiệp',
        address: '456 Lê Lợi, Q1, TPHCM',
        phone: '0902345678',
        email: 'info@billiardssaigon.com',
        coverImageUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96',
        profileImageUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96',
        totalTables: 15,
        isVerified: true,
        isActive: true,
        approvalStatus: 'approved',
        rating: 4.5,
        totalReviews: 89,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// Fallback club name
  String _getFallbackClubName() {
    final names = [
      'CLB SABO ARENA',
      'CLB BILLIARDS SAIGON',
      'CLB CUE MASTER',
      'CLB CHAMPION',
      'CLB GOLDEN CUE',
      'CLB ROYAL BILLIARDS',
      'CLB ELITE PLAYERS',
    ];

    final randomIndex = DateTime.now().millisecondsSinceEpoch % names.length;
    return names[randomIndex];
  }

  /// Get club statistics for display
  Future<Map<String, int>> getClubStats() async {
    try {
      final clubs = await getActiveClubs();

      return {
        'total_clubs': clubs.length,
        'verified_clubs': clubs.where((c) => c.isVerified).length,
        'average_rating': clubs.isEmpty
            ? 0
            : (clubs.map((c) => c.rating).reduce((a, b) => a + b) /
                    clubs.length)
                .round(),
      };
    } catch (error) {
      return {'total_clubs': 0, 'verified_clubs': 0, 'average_rating': 0};
    }
  }
}
