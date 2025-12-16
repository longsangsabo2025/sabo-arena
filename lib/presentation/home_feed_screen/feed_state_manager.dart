import 'package:flutter/foundation.dart';
import '../../models/post_model.dart';
import '../../services/post_repository.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// 🎯 FACEBOOK/INSTAGRAM APPROACH: Feed State Manager
///
/// Features:
/// - Pagination with offset/limit
/// - Pull-to-refresh
/// - Optimistic updates (like/unlike instantly)
/// - Cache management
/// - Error handling with retry
/// - Loading states (initial, loading more, refreshing)
class FeedStateManager extends ChangeNotifier {
  final PostRepository _repository;
  final FeedType feedType;

  FeedStateManager({required PostRepository repository, required this.feedType})
    : _repository = repository;

  // State
  List<PostModel> _posts = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasMoreData = true;
  String? _errorMessage;

  // Pagination
  static const int _pageSize = 20;
  int _currentOffset = 0;

  // Cache timestamp for smart refresh (like Facebook)
  DateTime? _lastRefreshTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Getters
  List<PostModel> get posts => List.unmodifiable(_posts);
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get hasMoreData => _hasMoreData;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _posts.isEmpty && !_isInitialLoading;

  /// Check if cache is still valid (Facebook approach)
  bool get _isCacheValid {
    if (_lastRefreshTime == null) return false;
    return DateTime.now().difference(_lastRefreshTime!) < _cacheValidDuration;
  }

  /// Initial load - called when screen first opens
  Future<void> loadInitial({bool forceRefresh = false}) async {
    // If cache is valid and not forcing refresh, skip
    if (_isCacheValid && !forceRefresh && _posts.isNotEmpty) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return;
    }

    _isInitialLoading = true;
    _errorMessage = null;
    _currentOffset = 0;
    _hasMoreData = true;
    notifyListeners();

    try {
      final newPosts = await _fetchPosts(offset: 0, limit: _pageSize);

      _posts = newPosts;
      _currentOffset = newPosts.length;
      _hasMoreData = newPosts.length >= _pageSize;
      _lastRefreshTime = DateTime.now();
      _errorMessage = null;

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      _errorMessage = 'Không thể tải bài viết: $e';
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  /// Load more posts - called when user scrolls to bottom (Instagram approach)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMoreData || _isInitialLoading) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final morePosts = await _fetchPosts(
        offset: _currentOffset,
        limit: _pageSize,
      );

      if (morePosts.isEmpty) {
        _hasMoreData = false;
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      } else {
        _posts.addAll(morePosts);
        _currentOffset += morePosts.length;
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      // Don't show error for load more, just fail silently
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh feed - called on pull-to-refresh (Facebook approach)
  Future<void> refresh() async {
    if (_isRefreshing || _isInitialLoading) return;

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final freshPosts = await _fetchPosts(offset: 0, limit: _pageSize);

      _posts = freshPosts;
      _currentOffset = freshPosts.length;
      _hasMoreData = freshPosts.length >= _pageSize;
      _lastRefreshTime = DateTime.now();

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      _errorMessage = 'Không thể làm mới: $e';
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Optimistic like/unlike (Instagram approach - instant feedback)
  Future<void> toggleLike(String postId) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final wasLiked = post.isLiked;
    final oldLikeCount = post.likeCount;

    // Optimistic update - instant UI feedback
    _posts[postIndex] = post.copyWith(
      isLiked: !wasLiked,
      likeCount: wasLiked ? oldLikeCount - 1 : oldLikeCount + 1,
    );
    notifyListeners();

    try {
      // Send to server
      if (wasLiked) {
        await _repository.unlikePost(postId);
      } else {
        await _repository.likePost(postId);
      }
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      // Revert on error
      _posts[postIndex] = post.copyWith(
        isLiked: wasLiked,
        likeCount: oldLikeCount,
      );
      notifyListeners();
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Add new post (when user creates a post)
  void addPost(PostModel post) {
    _posts.insert(0, post);
    _currentOffset++;
    notifyListeners();
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  /// Update post (when user edits)
  void updatePost(PostModel updatedPost) {
    final index = _posts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      _posts[index] = updatedPost;
      notifyListeners();
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Remove post (when user deletes)
  void removePost(String postId) {
    _posts.removeWhere((p) => p.id == postId);
    _currentOffset--;
    notifyListeners();
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  /// Increment comment count (optimistic)
  void incrementCommentCount(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(commentCount: post.commentCount + 1);
      notifyListeners();
    }
  }

  /// Clear cache and reset
  void clearCache() {
    _posts.clear();
    _currentOffset = 0;
    _hasMoreData = true;
    _lastRefreshTime = null;
    _errorMessage = null;
    notifyListeners();
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  // Private helper to fetch posts based on feed type
  Future<List<PostModel>> _fetchPosts({
    required int offset,
    required int limit,
  }) async {
    switch (feedType) {
      case FeedType.nearby:
        return await _repository.getNearbyFeed(offset: offset, limit: limit);
      case FeedType.following:
        return await _repository.getFollowingFeed(offset: offset, limit: limit);
      case FeedType.popular:
        return await _repository.getPopularFeed(offset: offset, limit: limit);
    }
  }
}

/// Feed types
enum FeedType {
  nearby, // Posts from nearby users/clubs
  following, // Posts from followed users
  popular, // Trending/popular posts
}

