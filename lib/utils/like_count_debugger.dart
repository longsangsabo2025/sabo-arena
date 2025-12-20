import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Debug utility để kiểm tra và sửa lỗi like count
class LikeCountDebugger {
  static final _supabase = Supabase.instance.client;

  /// 🔍 Kiểm tra trạng thái like count của một post
  static Future<Map<String, dynamic>> debugPostLikes(String postId) async {
    try {
      // 1. Lấy thông tin post từ database
      final postResponse = await _supabase
          .from('posts')
          .select('id, content, like_count, user_id')
          .eq('id', postId)
          .single();

      // 2. Đếm thực tế số likes trong post_interactions
      final actualLikesResponse = await _supabase
          .from('post_interactions')
          .select('user_id, created_at')
          .eq('post_id', postId)
          .eq('interaction_type', 'like');

      // 3. Kiểm tra post_likes table (legacy)
      final legacyLikesResponse = await _supabase
          .from('post_likes')
          .select('user_id, created_at')
          .eq('post_id', postId);

      // 4. Kiểm tra current user status
      final currentUser = _supabase.auth.currentUser;
      bool userLikedInInteractions = false;
      bool userLikedInLegacy = false;

      if (currentUser != null) {
        // Check in post_interactions
        final userLikeResponse = await _supabase
            .from('post_interactions')
            .select('id')
            .eq('post_id', postId)
            .eq('user_id', currentUser.id)
            .eq('interaction_type', 'like')
            .maybeSingle();
        userLikedInInteractions = userLikeResponse != null;

        // Check in post_likes (legacy)
        final userLegacyResponse = await _supabase
            .from('post_likes')
            .select('id')
            .eq('post_id', postId)
            .eq('user_id', currentUser.id)
            .maybeSingle();
        userLikedInLegacy = userLegacyResponse != null;
      }

      final debug = {
        'post_id': postId,
        'stored_like_count': postResponse['like_count'],
        'actual_likes_count': actualLikesResponse.length,
        'legacy_likes_count': legacyLikesResponse.length,
        'current_user_id': currentUser?.id,
        'user_liked_in_interactions': userLikedInInteractions,
        'user_liked_in_legacy': userLikedInLegacy,
        'status': _getStatus(
          postResponse['like_count'],
          actualLikesResponse.length,
          legacyLikesResponse.length,
        ),
        'actual_likes': actualLikesResponse.map((e) => e['user_id']).toList(),
        'legacy_likes': legacyLikesResponse.map((e) => e['user_id']).toList(),
      };

      return debug;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 🔧 Sửa like count cho một post cụ thể
  static Future<bool> fixPostLikeCount(String postId) async {
    try {
      // 1. Migrate legacy likes to post_interactions if any
      final legacyLikes =
          await _supabase.from('post_likes').select('*').eq('post_id', postId);

      for (final like in legacyLikes) {
        // Check if already exists in post_interactions
        final existing = await _supabase
            .from('post_interactions')
            .select('id')
            .eq('post_id', like['post_id'])
            .eq('user_id', like['user_id'])
            .eq('interaction_type', 'like')
            .maybeSingle();

        if (existing == null) {
          // Insert into post_interactions
          await _supabase.from('post_interactions').insert({
            'post_id': like['post_id'],
            'user_id': like['user_id'],
            'interaction_type': 'like',
            'created_at': like['created_at'],
          });
        }
      }

      // 2. Count actual likes
      final actualLikes = await _supabase
          .from('post_interactions')
          .select('id')
          .eq('post_id', postId)
          .eq('interaction_type', 'like');

      // 3. Update post like_count
      await _supabase
          .from('posts')
          .update({'like_count': actualLikes.length}).eq('id', postId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🔧 Sửa like count cho tất cả posts (chạy một lần)
  static Future<void> fixAllPostLikeCounts() async {
    try {
      // 1. Get all posts
      final posts = await _supabase.from('posts').select('id, like_count');

      // int fixedCount = 0;
      for (int i = 0; i < posts.length; i++) {
        final post = posts[i];
        final postId = post['id'];

        // Show progress every 10 posts
        if (i % 10 == 0) {
          // REMOVED: debugPrint('Processing post $i/${posts.length}...');
        }

        // Count actual likes
        final actualLikes = await _supabase
            .from('post_interactions')
            .select('id')
            .eq('post_id', postId)
            .eq('interaction_type', 'like');

        // Update if different
        if (post['like_count'] != actualLikes.length) {
          await _supabase
              .from('posts')
              .update({'like_count': actualLikes.length}).eq('id', postId);
          // fixedCount++;
        }
      }
      // REMOVED: debugPrint('Fixed $fixedCount posts.');
    } catch (e) {
      // REMOVED: debugPrint('Error fixing all post like counts: $e');
    }
  }

  static String _getStatus(int stored, int actual, int legacy) {
    if (stored == actual && legacy == 0) {
      return '✅ Correct';
    } else if (stored != actual && legacy > 0) {
      return '🔄 Migration needed';
    } else if (stored != actual) {
      return '❌ Count mismatch';
    } else {
      return '⚠️ Check needed';
    }
  }

  /// 🎯 Hiển thị debug widget trong app
  static Widget buildDebugPanel(String postId) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔍 Debug: Post Like Count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => debugPostLikes(postId),
                child: const Text('Check Status'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => fixPostLikeCount(postId),
                child: const Text('Fix This Post'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Post ID: $postId',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
