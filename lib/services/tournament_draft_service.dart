import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// ELON_MODE_AUTO_FIX

/// Service để quản lý việc lưu và khôi phục nháp giải đấu
class TournamentDraftService {
  static TournamentDraftService? _instance;
  static TournamentDraftService get instance =>
      _instance ??= TournamentDraftService._();
  TournamentDraftService._();

  static const String _draftKeyPrefix = 'tournament_draft_';
  static const String _draftsListKey = 'tournament_drafts_list';

  /// Lưu nháp giải đấu
  Future<void> saveDraft({
    required String draftId,
    required Map<String, dynamic> tournamentData,
    String? draftName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Tạo draft object với metadata
      final draft = {
        'id': draftId,
        'name':
            draftName ?? 'Nháp ${DateTime.now().toString().substring(0, 16)}',
        'data': tournamentData,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      // Lưu draft data
      await prefs.setString('$_draftKeyPrefix$draftId', jsonEncode(draft));

      // Cập nhật danh sách drafts
      await _updateDraftsList(draftId, draft['name'] as String);

    } catch (e) {
      // Ignore error
    }
  }

  /// Auto-save draft (gọi khi user thay đổi form)
  Future<void> autoSaveDraft({
    required String draftId,
    required Map<String, dynamic> tournamentData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingDraftJson = prefs.getString('$_draftKeyPrefix$draftId');

      Map<String, dynamic> draft;
      if (existingDraftJson != null) {
        // Update existing draft
        draft = jsonDecode(existingDraftJson);
        draft['data'] = tournamentData;
        draft['updatedAt'] = DateTime.now().toIso8601String();
      } else {
        // Create new auto-save draft
        draft = {
          'id': draftId,
          'name': 'Tự động lưu ${DateTime.now().toString().substring(0, 16)}',
          'data': tournamentData,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'version': '1.0',
          'isAutoSave': true,
        };

        await _updateDraftsList(
          draftId,
          draft['name'] as String,
          isAutoSave: true,
        );
      }

      await prefs.setString('$_draftKeyPrefix$draftId', jsonEncode(draft));
    } catch (e) {
      // Ignore error
    }
  }

  /// Lấy nháp theo ID
  Future<Map<String, dynamic>?> getDraft(String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString('$_draftKeyPrefix$draftId');

      if (draftJson != null) {
        return jsonDecode(draftJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Lấy danh sách tất cả drafts
  Future<List<Map<String, dynamic>>> getAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsListJson = prefs.getString(_draftsListKey);

      if (draftsListJson != null) {
        final draftsList = jsonDecode(draftsListJson) as List;

        // Load full draft data
        List<Map<String, dynamic>> drafts = [];
        for (final draftInfo in draftsList) {
          final draftId = draftInfo['id'];
          final draft = await getDraft(draftId);
          if (draft != null) {
            drafts.add(draft);
          }
        }

        // Sort by updated date (newest first)
        drafts.sort(
          (a, b) => DateTime.parse(
            b['updatedAt'],
          ).compareTo(DateTime.parse(a['updatedAt'])),
        );

        return drafts;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Xóa nháp
  Future<void> deleteDraft(String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove draft data
      await prefs.remove('$_draftKeyPrefix$draftId');

      // Update drafts list
      await _removeDraftFromList(draftId);

    } catch (e) {
      // Ignore error
    }
  }

  /// Đổi tên nháp
  Future<void> renameDraft(String draftId, String newName) async {
    try {
      final draft = await getDraft(draftId);
      if (draft != null) {
        draft['name'] = newName;
        draft['updatedAt'] = DateTime.now().toIso8601String();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_draftKeyPrefix$draftId', jsonEncode(draft));

        // Update drafts list
        await _updateDraftsList(
          draftId,
          newName,
          isAutoSave: draft['isAutoSave'] ?? false,
        );

      }
    } catch (e) {
      // Ignore error
    }
  }

  /// Tạo bản sao của nháp
  Future<String> duplicateDraft(String originalDraftId, String newName) async {
    try {
      final originalDraft = await getDraft(originalDraftId);
      if (originalDraft != null) {
        final newDraftId = 'draft_${DateTime.now().millisecondsSinceEpoch}';

        await saveDraft(
          draftId: newDraftId,
          tournamentData: Map<String, dynamic>.from(originalDraft['data']),
          draftName: newName,
        );

        return newDraftId;
      }
      throw Exception('Original draft not found');
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo draft ID duy nhất
  String generateDraftId() {
    return 'draft_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Kiểm tra có nháp auto-save gần đây không
  Future<Map<String, dynamic>?> getLatestAutoSave() async {
    try {
      final drafts = await getAllDrafts();
      final autoSaveDrafts = drafts
          .where((d) => d['isAutoSave'] == true)
          .toList();

      if (autoSaveDrafts.isNotEmpty) {
        return autoSaveDrafts.first; // Already sorted by updatedAt
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clean up old auto-save drafts (keep only latest 3)
  Future<void> cleanUpAutoSaves() async {
    try {
      final drafts = await getAllDrafts();
      final autoSaveDrafts = drafts
          .where((d) => d['isAutoSave'] == true)
          .toList();

      if (autoSaveDrafts.length > 3) {
        // Keep only latest 3, delete the rest
        final draftsToDelete = autoSaveDrafts.skip(3);
        for (final draft in draftsToDelete) {
          await deleteDraft(draft['id']);
        }
      }
    } catch (e) {
      // Ignore error
    }
  }

  // Private methods

  Future<void> _updateDraftsList(
    String draftId,
    String draftName, {
    bool isAutoSave = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsListJson = prefs.getString(_draftsListKey);

      List<Map<String, dynamic>> draftsList = [];
      if (draftsListJson != null) {
        draftsList = List<Map<String, dynamic>>.from(
          jsonDecode(draftsListJson),
        );
      }

      // Remove existing entry if exists
      draftsList.removeWhere((d) => d['id'] == draftId);

      // Add/update entry
      draftsList.add({
        'id': draftId,
        'name': draftName,
        'updatedAt': DateTime.now().toIso8601String(),
        'isAutoSave': isAutoSave,
      });

      await prefs.setString(_draftsListKey, jsonEncode(draftsList));
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _removeDraftFromList(String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsListJson = prefs.getString(_draftsListKey);

      if (draftsListJson != null) {
        List<Map<String, dynamic>> draftsList = List<Map<String, dynamic>>.from(
          jsonDecode(draftsListJson),
        );

        draftsList.removeWhere((d) => d['id'] == draftId);

        await prefs.setString(_draftsListKey, jsonEncode(draftsList));
      }
      // Ignore error
    } catch (e) {
      // Ignore error
    }
  }
}

