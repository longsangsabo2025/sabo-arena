import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Simple debug method to add to any widget for testing like count
class QuickLikeDebug {
  static final _supabase = Supabase.instance.client;

  /// Quick check method that can be called from anywhere
  static Future<void> checkPost(String postId) async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    
    try {
      // Get post info
      final post = await _supabase
          .from('posts')
          .select('id, content, like_count')
          .eq('id', postId)
          .single();
      
      // Count actual likes
      final likes = await _supabase
          .from('post_interactions')
          .select('user_id')
          .eq('post_id', postId)
          .eq('interaction_type', 'like');
      
      // Check current user status
      final user = _supabase.auth.currentUser;
      bool userLiked = false;
      if (user != null) {
        final userLike = await _supabase
            .from('post_interactions')
            .select('id')
            .eq('post_id', postId)
            .eq('user_id', user.id)
            .eq('interaction_type', 'like')
            .maybeSingle();
        userLiked = userLike != null;
      }
      
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      
      if (post['like_count'] != likes.length) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        await _supabase
            .from('posts')
            .update({'like_count': likes.length})
            .eq('id', postId);
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
    
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  /// Widget for temporary debug button
  static Widget debugButton(String postId) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ElevatedButton(
        onPressed: () => checkPost(postId),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: Text('🐛 Debug Post $postId'),
      ),
    );
  }
}
