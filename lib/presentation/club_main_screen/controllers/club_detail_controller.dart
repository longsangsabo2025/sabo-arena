import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../models/club.dart';
import '../../../models/club_permission.dart';
import '../../../models/tournament.dart';
import '../../../services/club_service.dart';
import '../../../services/club_permission_service.dart';
import '../../../services/tournament_service.dart';
import '../../../utils/production_logger.dart';

class ClubDetailController extends ChangeNotifier {
  final Club club;
  final ClubService _clubService = ClubService.instance;
  final ClubPermissionService _clubPermissionService = ClubPermissionService();
  final TournamentService _tournamentService = TournamentService.instance;

  // State
  bool _isDisposed = false;

  // Follow & Membership Status
  bool isFollowing = false;
  bool isFollowLoading = false;
  bool isCurrentUserMember = false;
  bool isClubOwner = false;

  // Members Data
  List<ClubMemberWithPermissions> members = [];
  bool isLoadingMembers = false;
  String? membersError;

  // Tournaments Data
  List<Tournament> tournaments = [];
  bool isLoadingTournaments = false;
  String? tournamentsError;
  String tournamentFilter =
      'Tất cả'; // 'Tất cả', 'Sắp tới', 'Đang diễn ra', 'Đã kết thúc'

  // Photos Data
  List<String> photos = [];
  bool isLoadingPhotos = false;
  String? photosError;

  ClubDetailController({required this.club}) {
    _init();
  }

  void _init() {
    loadMembers();
    loadTournaments();
    loadPhotos();
    checkFollowStatus();
    checkMembershipStatus();
    checkOwnerStatus();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // ==========================================
  // MEMBERS LOGIC
  // ==========================================
  Future<void> loadMembers() async {
    isLoadingMembers = true;
    membersError = null;
    _safeNotifyListeners();

    try {
      final result = await _clubPermissionService.getClubMembers(club.id);
      members = result;
      isLoadingMembers = false;
    } catch (e) {
      isLoadingMembers = false;
      membersError = _getFriendlyErrorMessage(e);
      ProductionLogger.error('Error loading members',
          error: e, tag: 'ClubDetailController');
    }
    _safeNotifyListeners();
  }

  // ==========================================
  // TOURNAMENTS LOGIC
  // ==========================================
  Future<void> loadTournaments() async {
    isLoadingTournaments = true;
    tournamentsError = null;
    _safeNotifyListeners();

    try {
      final result = await _tournamentService.getTournaments(clubId: club.id);
      // Sort descending by start date (Newest first)
      result.sort((a, b) => b.startDate.compareTo(a.startDate));
      tournaments = result;
      isLoadingTournaments = false;
    } catch (e) {
      isLoadingTournaments = false;
      tournamentsError = e.toString();
      ProductionLogger.error('Error loading tournaments',
          error: e, tag: 'ClubDetailController');
    }
    _safeNotifyListeners();
  }

  void setTournamentFilter(String filter) {
    tournamentFilter = filter;
    _safeNotifyListeners();
  }

  Future<void> deleteTournament(Tournament tournament) async {
    // Logic to delete tournament is complex and involves UI confirmation
    // We'll keep the core deletion logic here but UI confirmation stays in View
    try {
      // Delete tournament participants first (foreign key constraint)
      await Supabase.instance.client
          .from('tournament_participants')
          .delete()
          .eq('tournament_id', tournament.id);

      // Delete tournament
      await Supabase.instance.client
          .from('tournaments')
          .delete()
          .eq('id', tournament.id);

      // Refresh list
      await loadTournaments();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> canDeleteTournament(Tournament tournament) async {
    try {
      final participantsResponse = await Supabase.instance.client
          .from('tournament_participants')
          .select('id, payment_status')
          .eq('tournament_id', tournament.id);

      final participants = participantsResponse as List;
      final hasPaidUsers = participants.any(
        (p) =>
            p['payment_status'] == 'paid' || p['payment_status'] == 'completed',
      );

      return !hasPaidUsers;
    } catch (e) {
      ProductionLogger.error('Error checking tournament deletion',
          error: e, tag: 'ClubDetailController');
      return false;
    }
  }

  // ==========================================
  // PHOTOS LOGIC
  // ==========================================
  Future<void> loadPhotos() async {
    isLoadingPhotos = true;
    photosError = null;
    _safeNotifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('club_photos')
          .select('photo_url')
          .eq('club_id', club.id)
          .order('created_at', ascending: false);

      photos = (response as List)
          .map((item) => item['photo_url'] as String)
          .toList();
      isLoadingPhotos = false;
    } catch (e) {
      isLoadingPhotos = false;
      photosError = e.toString();
      photos = [];
      ProductionLogger.error('Error loading photos',
          error: e, tag: 'ClubDetailController');
    }
    _safeNotifyListeners();
  }

  Future<void> addPhoto(XFile image) async {
    try {
      // Read and compress image
      final bytes = await image.readAsBytes();
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1280,
        minHeight: 720,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'clubs/${club.id}/photos/$fileName';

      // Upload compressed image to Supabase Storage
      await Supabase.instance.client.storage.from('club-photos').uploadBinary(
            filePath,
            compressedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get public URL
      final photoUrl = Supabase.instance.client.storage
          .from('club-photos')
          .getPublicUrl(filePath);

      // Save to database
      await Supabase.instance.client.from('club_photos').insert({
        'club_id': club.id,
        'photo_url': photoUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Refresh photos
      await loadPhotos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePhoto(String photoUrl) async {
    try {
      // Delete from database
      await Supabase.instance.client
          .from('club_photos')
          .delete()
          .eq('club_id', club.id)
          .eq('photo_url', photoUrl);

      // Try to delete from storage
      try {
        final uri = Uri.parse(photoUrl);
        final path =
            uri.pathSegments.skip(uri.pathSegments.length - 3).join('/');
        await Supabase.instance.client.storage
            .from('club-photos')
            .remove([path]);
      } catch (storageError) {
        ProductionLogger.warning('Error deleting photo from storage',
            error: storageError, tag: 'ClubDetailController');
      }

      // Refresh photos
      await loadPhotos();
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // STATUS & ACTIONS LOGIC
  // ==========================================
  Future<void> checkFollowStatus() async {
    try {
      final status = await _clubService.isFollowingClub(club.id);
      isFollowing = status;
      _safeNotifyListeners();
    } catch (error) {
      ProductionLogger.error('Error checking follow status',
          error: error, tag: 'ClubDetailController');
    }
  }

  Future<void> checkMembershipStatus() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final response = await Supabase.instance.client
          .from('club_members')
          .select()
          .eq('club_id', club.id)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      isCurrentUserMember = response != null;
      _safeNotifyListeners();
    } catch (error) {
      ProductionLogger.error('Error checking membership status',
          error: error, tag: 'ClubDetailController');
    }
  }

  Future<void> checkOwnerStatus() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      isClubOwner = club.ownerId == currentUser.id;
      _safeNotifyListeners();
    } catch (error) {
      ProductionLogger.error('Error checking owner status',
          error: error, tag: 'ClubDetailController');
    }
  }

  Future<bool> toggleFollow() async {
    if (isFollowLoading) return false;

    isFollowLoading = true;
    _safeNotifyListeners();

    try {
      bool success;
      if (isFollowing) {
        success = await _clubService.unfollowClub(club.id);
        if (success) isFollowing = false;
      } else {
        success = await _clubService.followClub(club.id);
        if (success) isFollowing = true;
      }

      isFollowLoading = false;
      _safeNotifyListeners();
      return success;
    } catch (error) {
      isFollowLoading = false;
      _safeNotifyListeners();
      rethrow;
    }
  }

  // Helper
  String _getFriendlyErrorMessage(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('JWT') || errorStr.contains('auth')) {
      return 'Vui lòng đăng nhập để xem danh sách thành viên';
    } else if (errorStr.contains('timeout') || errorStr.contains('network')) {
      return 'Kết nối mạng chậm. Vui lòng thử lại';
    } else if (errorStr.contains('RLS') || errorStr.contains('policy')) {
      return 'Quyền truy cập bị hạn chế. Đang khắc phục...';
    } else {
      return 'Lỗi: $errorStr';
    }
  }
}
