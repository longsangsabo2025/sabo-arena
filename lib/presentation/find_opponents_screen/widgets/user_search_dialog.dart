import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
import '../../../models/user_profile.dart';
import '../../../services/user_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Dialog to search and select any user in the system as opponent
class UserSearchDialog extends StatefulWidget {
  final UserProfile? currentUser;
  final List<String>? excludeUserIds; // Users to exclude from search

  const UserSearchDialog({
    super.key,
    this.currentUser,
    this.excludeUserIds,
  });

  @override
  State<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final UserService _userService = UserService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // 🚀 MUSK OPTIMIZATIONS
  Timer? _debounceTimer;
  final Map<String, List<UserProfile>> _searchCache = {};
  final List<String> _recentSearches = [];

  List<UserProfile> _searchResults = [];
  List<UserProfile> _suggestedUsers = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedUsers();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchCache.clear();
    super.dispose();
  }

  /// 🚀 MUSK DEBOUNCED SEARCH - No spam, intelligent caching
  void _debouncedSearch(String value) {
    _debounceTimer?.cancel();
    
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }
    
    if (value.trim().length < 2) return;
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSmartSearch(value.trim());
    });
  }
  
  /// Smart search với caching và intelligent suggestions
  Future<void> _performSmartSearch(String query) async {
    // Check cache first
    if (_searchCache.containsKey(query.toLowerCase())) {
      setState(() {
        _searchResults = _searchCache[query.toLowerCase()]!;
        _hasSearched = true;
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      // Multiple search strategies
      final List<UserProfile> results = [];
      
      // 1. Exact username match (highest priority)
      final exactMatch = await _userService.searchUsersByUsername(query);
      results.addAll(exactMatch);
      
      // 2. Partial name match 
      if (results.length < 10) {
        final nameMatches = await _userService.searchUsersByName(query);
        results.addAll(nameMatches.where((u) => !results.any((r) => r.id == u.id)));
      }
      
      // 3. Similar rank suggestions (if user has rank)
      if (results.length < 5 && widget.currentUser?.rank != null) {
        final rankMatches = await _userService.searchUsersBySimilarRank(
          widget.currentUser!.rank!, 
          query,
        );
        results.addAll(rankMatches.where((u) => !results.any((r) => r.id == u.id)));
      }
      
      // Filter exclusions
      final filteredResults = results.where((user) {
        if (user.id == widget.currentUser?.id) return false;
        if (widget.excludeUserIds?.contains(user.id) ?? false) return false;
        return true;
      }).toList();
      
      // Cache results
      _searchCache[query.toLowerCase()] = filteredResults;
      
      // Add to recent searches
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      }
      
      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
        _hasSearched = true;
      });
      
    } catch (e) {
      ProductionLogger.error('🔍 Smart search failed: $e', tag: 'user_search');
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  /// Load suggested users (nearby players with similar rank)
  Future<void> _loadSuggestedUsers() async {
    if (widget.currentUser == null) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      // Get users with similar rank (±2 ranks)
      final allUsers = await _userService.searchUsers('');
      
      final currentRank = widget.currentUser!.rank ?? 'Beginner';
      
      // Filter: similar rank, exclude current user and excluded IDs
      final suggested = allUsers.where((user) {
        if (user.id == widget.currentUser!.id) return false;
        if (widget.excludeUserIds?.contains(user.id) ?? false) return false;
        
        // Simple rank similarity check
        final userRank = user.rank ?? 'Beginner';
        return userRank == currentRank; // Same rank for now
      }).take(6).toList(); // Limit to 6 suggestions

      setState(() {
        _suggestedUsers = suggested;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      ProductionLogger.info('Error loading suggested users: $e', tag: 'user_search_dialog');
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query.trim();
    });

    try {
      // Search users by name or email
      final results = await _userService.searchUsers(query);

      // Filter out current user and excluded users
      final filteredResults = results.where((user) {
        if (user.id == widget.currentUser?.id) return false;
        if (widget.excludeUserIds?.contains(user.id) ?? false) return false;
        return true;
      }).toList();

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      ProductionLogger.info('Error searching users: $e', tag: 'user_search_dialog');
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tìm đối thủ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Box
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc email...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E88E5),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _debouncedSearch(value);
              },
              onSubmitted: _searchUsers,
            ),

            const SizedBox(height: 16),

            // Search Results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    // Loading state với smart indicators
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
            ),
            const SizedBox(height: 16),
            Text(
              '🚀 Tìm kiếm thông minh: "$_searchQuery"',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Username → Tên → Cùng hạng',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Empty state - no search yet, show suggestions
    if (!_hasSearched) {
      return _buildSuggestionsView();
    }

    // No results found
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search,
                size: 48,
                color: Colors.orange.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy người chơi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm với từ khóa khác',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Results list
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.pop(context, user),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: UserAvatarWidget(
                  avatarUrl: user.avatarUrl,
                  userName: user.displayName,
                  size: 56,
                ),
              ),
              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Rank Badge with unified component
                        UserRankBadgeWidget(
                          rankCode: user.rank,
                          style: RankBadgeStyle.compact,
                        ),
                        const SizedBox(width: 8),

                        // ELO
                        Icon(
                          Icons.trending_up,
                          size: 14,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${user.eloRating ?? 1000} ELO',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Select Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Color(0xFF1E88E5),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build suggestions view with nearby and similar rank players
  Widget _buildSuggestionsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.recommend,
              color: Colors.orange.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Gợi ý đối thủ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Người chơi cùng hạng',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 12),

        // Loading or suggestions list
        Expanded(
          child: _isLoadingSuggestions
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
                  ),
                )
              : _suggestedUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có gợi ý',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tìm kiếm để tìm đối thủ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _suggestedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _suggestedUsers[index];
                        return _buildUserCard(user);
                      },
                    ),
        ),
      ],
    );
  }
}
