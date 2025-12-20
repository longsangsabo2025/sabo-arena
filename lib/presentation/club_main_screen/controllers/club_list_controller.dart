import 'package:flutter/material.dart';
import '../../../models/club.dart';
import '../../../services/club_service.dart';

class ClubListController extends ChangeNotifier {
  final ClubService _clubService = ClubService.instance;

  List<Club> _clubs = [];
  List<Club> get clubs => _clubs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Club? _selectedClub;
  Club? get selectedClub => _selectedClub;

  // Filter state
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Pagination
  int _currentPage = 0;
  static const int _pageSize = 10;

  ClubListController() {
    loadClubs();
  }

  Future<void> loadClubs({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _clubs = [];
      _selectedClub = null; // Reset selection on refresh
      notifyListeners();
    }

    if (!_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newClubs = await _clubService.getClubs(
        searchQuery: _searchQuery,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (newClubs.length < _pageSize) {
        _hasMore = false;
      }

      _clubs.addAll(newClubs);
      _currentPage++;

      // Auto-select first club if none selected and list is not empty
      if (_selectedClub == null && _clubs.isNotEmpty) {
        _selectedClub = _clubs.first;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectClub(Club club) {
    _selectedClub = club;
    notifyListeners();
  }

  void search(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    loadClubs(refresh: true);
  }
}
