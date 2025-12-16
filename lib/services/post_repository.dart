import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import 'auto_notification_hooks.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class PostRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Query string with user and club joins
  static const String _postSelectQuery = '''
    id,
    content,
    image_urls,
    location,
    hashtags,
    created_at,
    user_id,
    club_id,
    users!posts_user_id_fkey(username, display_name, avatar_url),
    clubs!posts_club_id_fkey(name, logo_url),
    like_count,
    comment_count,
    share_count
  ''';

  // Lấy danh sách bài viết từ feed
  Future<List<PostModel>> getPosts({
    int limit = 20,
    int offset = 0,
    bool excludeHidden = true,
  }) async {
    try {
      final response = await _supabase
          .from('posts')
          .select(_postSelectQuery)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<PostModel> posts = [];
      for (final item in response) {
        final postId = item['id'];

        // Skip hidden posts if requested
        if (excludeHidden && await isPostHidden(postId)) {
          continue;
        }

        final user = item['users'];
        final club = item['clubs']; // 🎱 Get club info
        final clubId = item['club_id'];
        final imageUrls = item['image_urls'] as List?;
        final hashtags = item['hashtags'] as List?;

        // Check if current user has liked this post
        final isLiked = await hasUserLikedPost(postId);

        // 🎱 If post has club_id, use club info; otherwise use user info
        final authorName = clubId != null && club != null
            ? club['name'] ?? 'Anonymous Club'
            : user?['display_name'] ?? user?['username'] ?? 'Anonymous';
        
        final authorAvatar = clubId != null && club != null
            ? club['logo_url']
            : user?['avatar_url'];

        posts.add(
          PostModel(
            id: item['id'],
            title: '', // No title in schema
            content: item['content'] ?? '',
            imageUrl: imageUrls?.isNotEmpty == true ? imageUrls!.first : null,
            authorId: item['user_id'],
            authorName: authorName,
            authorAvatarUrl: authorAvatar,
            createdAt: DateTime.parse(item['created_at']),
            likeCount: item['like_count'] ?? 0,
            commentCount: item['comment_count'] ?? 0,
            shareCount: item['share_count'] ?? 0,
            tags: hashtags?.cast<String>(),
            isLiked: isLiked,
          ),
        );
      }

      return posts;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  // Tạo bài viết mới
  Future<PostModel?> createPost({
    String? title, // Optional since not in schema
    required String content,
    String? imageUrl,
    List<String>? inputImageUrls,
    List<String>? hashtags,
    String? locationName,
    double? latitude,
    double? longitude,
    String? videoUrl, // YouTube video ID
    String? videoPlatform, // 'youtube', 'supabase', etc.
    int? videoDuration, // Duration in seconds
    String? videoThumbnailUrl, // Thumbnail URL
    String? clubId, // 🎱 Post as club instead of user
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Prepare image URLs array
      List<String>? finalImageUrls;
      if (inputImageUrls != null && inputImageUrls.isNotEmpty) {
        finalImageUrls = inputImageUrls;
      } else if (imageUrl != null) {
        finalImageUrls = [imageUrl];
      }

      final postData = {
        'content': content,
        'image_urls': finalImageUrls,
        'hashtags': hashtags,
        'location': locationName,
        'user_id': user.id,
        'club_id': clubId, // 🎱 Post belongs to club if clubId provided
        'video_url': videoUrl,
        'video_platform': videoPlatform ?? 'youtube',
        'video_duration': videoDuration,
        'video_thumbnail_url': videoThumbnailUrl,
        'video_uploaded_at': videoUrl != null
            ? DateTime.now().toIso8601String()
            : null,
      };

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await _supabase.from('posts').insert(postData).select('''
        id,
        content,
        image_urls,
        location,
        hashtags,
        created_at,
        user_id,
        club_id,
        video_url,
        video_platform,
        video_duration,
        video_thumbnail_url,
        users!posts_user_id_fkey(username, display_name, avatar_url),
        clubs!posts_club_id_fkey(name, logo_url),
        like_count,
        comment_count,
        share_count
      ''').single();

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final userInfo = response['users'];
      final responseImageUrls = response['image_urls'] as List?;
      final responseHashtags = response['hashtags'] as List?;

      final postModel = PostModel(
        id: response['id'],
        title: title ?? '',
        content: response['content'] ?? '',
        imageUrl: responseImageUrls?.isNotEmpty == true
            ? responseImageUrls!.first
            : null,
        videoUrl: response['video_url'], // YouTube video ID
        authorId: response['user_id'],
        authorName:
            userInfo?['display_name'] ?? userInfo?['username'] ?? 'Anonymous',
        authorAvatarUrl: userInfo?['avatar_url'],
        createdAt: DateTime.parse(response['created_at']),
        likeCount: response['like_count'] ?? 0,
        commentCount: response['comment_count'] ?? 0,
        shareCount: response['share_count'] ?? 0,
        tags: responseHashtags?.cast<String>(),
      );

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return postModel;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  // ⚠️ DEPRECATED: Use likePost() and unlikePost() instead
  // This method uses old 'post_likes' table - kept for backward compatibility only
  @Deprecated('Use likePost() and unlikePost() instead')
  Future<bool> toggleLike(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Check current like status using NEW table (post_interactions)
      final isCurrentlyLiked = await hasUserLikedPost(postId);
      
      if (isCurrentlyLiked) {
        await unlikePost(postId);
      } else {
        await likePost(postId);
      }

      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // Lấy bài viết theo ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            id,
            content,
            image_urls,
            location,
            hashtags,
            created_at,
            user_id,
            users!posts_user_id_fkey(username, display_name, avatar_url),
            like_count,
            comment_count,
            share_count
          ''')
          .eq('id', postId)
          .single();

      final user = response['users'];
      final imageUrls = response['image_urls'] as List?;
      final hashtags = response['hashtags'] as List?;

      return PostModel(
        id: response['id'],
        title: '',
        content: response['content'] ?? '',
        imageUrl: imageUrls?.isNotEmpty == true ? imageUrls!.first : null,
        authorId: response['user_id'],
        authorName: user?['display_name'] ?? user?['username'] ?? 'Anonymous',
        authorAvatarUrl: user?['avatar_url'],
        createdAt: DateTime.parse(response['created_at']),
        likeCount: response['like_count'] ?? 0,
        commentCount: response['comment_count'] ?? 0,
        shareCount: response['share_count'] ?? 0,
        tags: hashtags?.cast<String>(),
      );
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  // Xóa bài viết
  Future<bool> deletePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // Tìm kiếm bài viết
  Future<List<PostModel>> searchPosts(String query) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            id,
            content,
            image_urls,
            location,
            hashtags,
            created_at,
            user_id,
            users!posts_user_id_fkey(username, display_name, avatar_url),
            like_count,
            comment_count,
            share_count
          ''')
          .ilike('content', '%$query%')
          .order('created_at', ascending: false);

      final List<PostModel> posts = [];
      for (final item in response) {
        final user = item['users'];
        final imageUrls = item['image_urls'] as List?;
        final hashtags = item['hashtags'] as List?;

        posts.add(
          PostModel(
            id: item['id'],
            title: '',
            content: item['content'] ?? '',
            imageUrl: imageUrls?.isNotEmpty == true ? imageUrls!.first : null,
            authorId: item['user_id'],
            authorName:
                user?['display_name'] ?? user?['username'] ?? 'Anonymous',
            authorAvatarUrl: user?['avatar_url'],
            createdAt: DateTime.parse(item['created_at']),
            likeCount: item['like_count'] ?? 0,
            commentCount: item['comment_count'] ?? 0,
            shareCount: item['share_count'] ?? 0,
            tags: hashtags?.cast<String>(),
          ),
        );
      }

      return posts;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  // Like a post
  Future<void> likePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Get post owner ID for notification (before insert)
      final currentPost = await _supabase
          .from('posts')
          .select('user_id')
          .eq('id', postId)
          .single();

      // Insert like record using post_interactions table
      // ✅ Database trigger will automatically increment like_count
      await _supabase.from('post_interactions').insert({
        'post_id': postId,
        'user_id': user.id,
        'interaction_type': 'like',
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // 🔔 Gửi thông báo cho post owner (không gửi cho chính mình)
      final postOwnerId = currentPost['user_id'] as String?;
      if (postOwnerId != null && postOwnerId != user.id) {
        final currentUserProfile = await _supabase
            .from('users')
            .select('display_name')
            .eq('id', user.id)
            .single();

        await AutoNotificationHooks.onPostReacted(
          postId: postId,
          postOwnerId: postOwnerId,
          reactorId: user.id,
          reactorName: currentUserProfile['display_name'] ?? 'Someone',
          reactionType: 'like',
        );
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Delete like record from post_interactions table
      // ✅ Database trigger will automatically decrement like_count
      await _supabase
          .from('post_interactions')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .eq('interaction_type', 'like');

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  // Check if user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return false;
      }

      final response = await _supabase
          .from('post_interactions')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .eq('interaction_type', 'like')
          .maybeSingle();

      final isLiked = response != null;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return isLiked;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // =============================================
  // HIDE POST FUNCTIONALITY
  // =============================================

  // Hide a post
  Future<bool> hidePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('hidden_posts').insert({
        'post_id': postId,
        'user_id': user.id,
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // Unhide a post
  Future<bool> unhidePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('hidden_posts')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // Check if post is hidden
  Future<bool> isPostHidden(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('hidden_posts')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // =============================================
  // SAVE POST FUNCTIONALITY
  // =============================================

  // Save a post
  Future<bool> savePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // ✅ FIX: Check if already saved to prevent duplicate error
      final alreadySaved = await isPostSaved(postId);
      if (alreadySaved) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return true; // Return success since it's already saved
      }

      await _supabase.from('saved_posts').insert({
        'post_id': postId,
        'user_id': user.id,
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // Unsave a post
  Future<bool> unsavePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // ✅ FIX: Check if actually saved before delete
      final isSaved = await isPostSaved(postId);
      if (!isSaved) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return true; // Return success since it's already unsaved
      }

      await _supabase
          .from('saved_posts')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // Check if post is saved
  Future<bool> isPostSaved(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('saved_posts')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // Get saved posts
  Future<List<PostModel>> getSavedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('saved_posts')
          .select('''
            created_at,
            posts:post_id (
              id,
              content,
              image_urls,
              hashtags,
              created_at,
              user_id,
              users!posts_user_id_fkey(username, display_name, avatar_url),
              like_count,
              comment_count,
              share_count
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<PostModel> posts = [];
      for (final item in response) {
        final post = item['posts'];
        if (post == null) continue;

        final userInfo = post['users'];
        final imageUrls = post['image_urls'] as List?;
        final hashtags = post['hashtags'] as List?;

        posts.add(
          PostModel(
            id: post['id'],
            title: '',
            content: post['content'] ?? '',
            imageUrl: imageUrls?.isNotEmpty == true ? imageUrls!.first : null,
            authorId: post['user_id'],
            authorName:
                userInfo?['display_name'] ??
                userInfo?['username'] ??
                'Anonymous',
            authorAvatarUrl: userInfo?['avatar_url'],
            createdAt: DateTime.parse(post['created_at']),
            likeCount: post['like_count'] ?? 0,
            commentCount: post['comment_count'] ?? 0,
            shareCount: post['share_count'] ?? 0,
            tags: hashtags?.cast<String>(),
            isLiked: await hasUserLikedPost(post['id']),
          ),
        );
      }

      return posts;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  // =============================================
  // HASHTAG FUNCTIONALITY
  // =============================================

  // Get trending hashtags
  Future<List<Map<String, dynamic>>> getTrendingHashtags({
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_trending_hashtags',
        params: {'p_limit': limit},
      );

      if (response == null) return [];

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  // Search hashtags (autocomplete)
  Future<List<String>> searchHashtags(String query, {int limit = 10}) async {
    try {
      if (query.isEmpty) return [];

      final response = await _supabase.rpc(
        'search_hashtags',
        params: {'p_query': query, 'p_limit': limit},
      );

      if (response == null) return [];

      return List<Map<String, dynamic>>.from(
        response,
      ).map((item) => item['hashtag'] as String).toList();
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  // Get suggested hashtags for creating post
  Future<List<String>> getSuggestedHashtags() async {
    final trending = await getTrendingHashtags(limit: 10);
    return trending.map((item) => item['hashtag'] as String).toList();
  }

  // =============================================
  // FEED TYPE - NEARBY VS FOLLOWING
  // =============================================

  // Get following feed (posts from users you follow)
  Future<List<PostModel>> getFollowingFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase.rpc(
        'get_following_feed',
        params: {'p_user_id': user.id, 'p_limit': limit, 'p_offset': offset},
      );

      if (response == null) return [];

      final List<PostModel> posts = [];
      for (final item in response) {
        final isLiked = await hasUserLikedPost(item['post_id']);

        // 🎱 Functions now return author_name and author_avatar 
        // with club info prioritized (done in SQL)
        posts.add(
          PostModel(
            id: item['post_id'],
            title: '',
            content: item['content'] ?? '',
            imageUrl: (item['image_urls'] as List?)?.isNotEmpty == true
                ? item['image_urls'][0]
                : null,
            authorId: item['author_id'],
            authorName: item['author_name'] ?? 'Anonymous',
            authorAvatarUrl: item['author_avatar'],
            createdAt: DateTime.parse(item['created_at']),
            likeCount: item['like_count'] ?? 0,
            commentCount: item['comment_count'] ?? 0,
            shareCount: item['share_count'] ?? 0,
            tags: (item['hashtags'] as List?)?.cast<String>(),
            isLiked: isLiked,
          ),
        );
      }

      return posts;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  // Get nearby feed (popular/nearby posts)
  Future<List<PostModel>> getNearbyFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase.rpc(
        'get_nearby_feed',
        params: {'p_user_id': user.id, 'p_limit': limit, 'p_offset': offset},
      );

      if (response == null) return [];

      final List<PostModel> posts = [];
      for (final item in response) {
        final isLiked = await hasUserLikedPost(item['post_id']);

        // 🎱 Functions now return author_name and author_avatar 
        // with club info prioritized (done in SQL)
        posts.add(
          PostModel(
            id: item['post_id'],
            title: '',
            content: item['content'] ?? '',
            imageUrl: (item['image_urls'] as List?)?.isNotEmpty == true
                ? item['image_urls'][0]
                : null,
            authorId: item['author_id'],
            authorName: item['author_name'] ?? 'Anonymous',
            authorAvatarUrl: item['author_avatar'],
            createdAt: DateTime.parse(item['created_at']),
            likeCount: item['like_count'] ?? 0,
            commentCount: item['comment_count'] ?? 0,
            shareCount: item['share_count'] ?? 0,
            tags: (item['hashtags'] as List?)?.cast<String>(),
            isLiked: isLiked,
          ),
        );
      }

      return posts;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  // Follow a user
  Future<bool> followUser(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('user_follows').insert({
        'follower_id': user.id,
        'following_id': userId,
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('user_follows')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', userId);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // Check if following a user
  Future<bool> isFollowing(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', user.id)
          .eq('following_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  // Get popular/trending feed (sorted by engagement)
  Future<List<PostModel>> getPopularFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Get posts sorted by engagement score (likes + comments + shares)
      final response = await _supabase
          .from('posts')
          .select('''
            id,
            content,
            image_urls,
            location,
            hashtags,
            created_at,
            user_id,
            users!posts_user_id_fkey(username, display_name, avatar_url),
            like_count,
            comment_count,
            share_count
          ''')
          .order('like_count', ascending: false)
          .order('comment_count', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<PostModel> posts = [];
      for (final item in response) {
        final postId = item['id'];

        // Skip hidden posts
        if (await isPostHidden(postId)) {
          continue;
        }

        final userInfo = item['users'];
        final imageUrls = item['image_urls'] as List?;
        final hashtags = item['hashtags'] as List?;
        final isLiked = await hasUserLikedPost(postId);

        posts.add(
          PostModel(
            id: item['id'],
            title: '',
            content: item['content'] ?? '',
            imageUrl: imageUrls?.isNotEmpty == true ? imageUrls!.first : null,
            authorId: item['user_id'],
            authorName:
                userInfo?['display_name'] ??
                userInfo?['username'] ??
                'Anonymous',
            authorAvatarUrl: userInfo?['avatar_url'],
            createdAt: DateTime.parse(item['created_at']),
            likeCount: item['like_count'] ?? 0,
            commentCount: item['comment_count'] ?? 0,
            shareCount: item['share_count'] ?? 0,
            tags: hashtags?.cast<String>(),
            isLiked: isLiked,
          ),
        );
      }

      return posts;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  // Get posts by specific user ID
  Future<List<PostModel>> getUserPostsByUserId(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Query posts WITHOUT JOIN (FK doesn't exist!)
      final response = await _supabase
          .from('posts')
          .select('''
            id,
            content,
            image_urls,
            video_url,
            location,
            hashtags,
            created_at,
            user_id,
            like_count,
            comment_count,
            share_count
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      if (response.isEmpty) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return [];
      }

      // Fetch user data separately
      final userResponse = await _supabase
          .from('users')
          .select('username, display_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      final user = userResponse;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final List<PostModel> posts = [];
      for (final item in response) {
        final postId = item['id'];
        final imageUrls = item['image_urls'] as List?;
        final hashtags = item['hashtags'] as List?;

        // Check if current user has liked this post
        final isLiked = await hasUserLikedPost(postId);

        posts.add(
          PostModel(
            id: item['id'],
            title: '',
            content: item['content'] ?? '',
            imageUrl: imageUrls?.isNotEmpty == true ? imageUrls!.first : null,
            videoUrl: item['video_url'],
            authorId: item['user_id'],
            authorName:
                user?['display_name'] ?? user?['username'] ?? 'Anonymous',
            authorAvatarUrl: user?['avatar_url'],
            createdAt: DateTime.parse(item['created_at']),
            likeCount: item['like_count'] ?? 0,
            commentCount: item['comment_count'] ?? 0,
            shareCount: item['share_count'] ?? 0,
            tags: hashtags?.cast<String>(),
            isLiked: isLiked,
          ),
        );
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return posts;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }
}

