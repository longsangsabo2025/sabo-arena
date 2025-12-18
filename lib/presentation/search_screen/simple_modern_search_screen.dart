import 'package:flutter/material.dart';
import '../../services/post_repository.dart';
import 'dart:async';

/// 🚀 SIMPLE MODERN SEARCH SCREEN
/// Modern Instagram-like search experience
class ModernSearchScreen extends StatefulWidget {
  const ModernSearchScreen({super.key});

  @override
  State<ModernSearchScreen> createState() => _ModernSearchScreenState();
}

class _ModernSearchScreenState extends State<ModernSearchScreen> {
  
  // Services
  final PostRepository _postRepository = PostRepository();
  
  // Search state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  
  // Results state
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _showResults = false;
  String _currentQuery = '';
  
  // Recent searches
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.requestFocus();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  void _loadRecentSearches() {
    setState(() {
      _recentSearches = ['billiards', 'tournament', 'challenge'];
    });
  }
  
  void _saveRecentSearch(String query) {
    if (!_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      });
    }
  }

  /// 🚀 DEBOUNCED SEARCH
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      if (mounted) {
        setState(() {
          _showResults = false;
          _searchResults = [];
        });
      }
      return;
    }
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  /// Perform search
  Future<void> _performSearch(String query) async {
    if (query.isEmpty || !mounted) return;
    
    setState(() {
      _isLoading = true;
      _currentQuery = query;
    });
    
    try {
      _saveRecentSearch(query);
      
      // Get PostModels and convert to dynamic for compatibility
      final posts = await _postRepository.searchPosts(query);
      
      final postsAsMap = posts.map((post) => {
        'id': post.id,
        'content': post.content,
        'created_at': post.createdAt.toString(),
        'like_count': post.likeCount,
        'comment_count': post.commentCount,
        'user': {
          'display_name': post.authorName,
          'username': post.authorId,
        },
      }).toList();
      
      if (mounted) {
        setState(() {
          _searchResults = postsAsMap;
          _showResults = true;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tìm kiếm: ${e.toString()}')),
        );
      }
    }
  }
  
  void _clearSearch() {
    _searchController.clear();
    if (mounted) {
      setState(() {
        _showResults = false;
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildSearchAppBar(),
      body: _showResults ? _buildSearchResults() : _buildSearchHome(),
    );
  }
  
  /// Modern search AppBar
  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm bài viết...',
            hintStyle: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 16,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF8E8E93),
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Color(0xFF8E8E93),
                      size: 18,
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
  
  /// Search home khi chưa search
  Widget _buildSearchHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            const Text(
              'Tìm kiếm gần đây',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          search,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
          
          // Search suggestions
          const Text(
            'Gợi ý tìm kiếm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...['Giải đấu', 'Thách đấu', 'Billiards', 'Pool', 'Tournament'].map((suggestion) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.trending_up, color: Colors.blue[600]),
              title: Text(suggestion),
              onTap: () {
                _searchController.text = suggestion;
                _performSearch(suggestion);
              },
            );
          }),
        ],
      ),
    );
  }
  
  /// Search results
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả cho "$_currentQuery"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử từ khóa khác hoặc kiểm tra chính tả',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        return _buildPostItem(post);
      },
    );
  }
  
  Widget _buildPostItem(dynamic post) {
    final user = post['user'] as Map<String, dynamic>?;
    final userName = user?['display_name'] ?? user?['username'] ?? 'Người dùng ẩn danh';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Icon(
                  Icons.person, 
                  size: 18, 
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Post content
          Text(
            post['content'] ?? 'Không có nội dung',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Post meta
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatDate(post['created_at']?.toString()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Icon(Icons.favorite_border, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${post['like_count'] ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.mode_comment_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${post['comment_count'] ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Không xác định';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} phút trước';
      } else {
        return 'Vừa xong';
      }
    } catch (e) {
      return dateString.substring(0, 10);
    }
  }
}