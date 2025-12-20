import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'cdn_service.dart';
import 'rate_limit_service.dart';
import 'cache_manager.dart';
import '../core/error_handling/standardized_error_handler.dart';
// ELON_MODE_AUTO_FIX

class StorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload avatar image to Supabase Storage and update user profile
  /// 🚀 MUSK: Atomic operation - Upload, Update DB, Delete Old, Invalidate Cache
  /// Supports both File (Mobile) and Uint8List (Web/Bytes)
  static Future<String?> uploadAvatar(dynamic imageSource,
      {String? oldUrl,
      String? fileName,
      bool skipDatabaseUpdate = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint(
            '🚀 MUSK_DEBUG: uploadAvatar failed - User not authenticated');
        return null;
      }

      final userId = user.id;
      debugPrint('🚀 MUSK_DEBUG: Starting avatar upload for user: $userId');

      // Check rate limit
      final rateLimitService = RateLimitService.instance;
      if (!await rateLimitService.checkImageUpload(userId)) {
        debugPrint('🚀 MUSK_DEBUG: uploadAvatar failed - Rate limit exceeded');
        throw Exception('Rate limit exceeded. Please try again later.');
      }

      Uint8List bytes;
      String fileExtension;

      if (imageSource is File) {
        bytes = await imageSource.readAsBytes();
        fileExtension = path.extension(imageSource.path).toLowerCase();
        debugPrint(
            '🚀 MUSK_DEBUG: Source is File. Size: ${bytes.length} bytes, Ext: $fileExtension');
      } else if (imageSource is Uint8List) {
        bytes = imageSource;
        fileExtension =
            fileName != null ? path.extension(fileName).toLowerCase() : '.jpg';
        debugPrint(
            '🚀 MUSK_DEBUG: Source is Uint8List. Size: ${bytes.length} bytes, Ext: $fileExtension');
      } else {
        debugPrint(
            '🚀 MUSK_DEBUG: uploadAvatar failed - Invalid image source type');
        throw Exception('Invalid image source type');
      }

      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      if (!allowedExtensions.contains(fileExtension)) {
        debugPrint(
            '🚀 MUSK_DEBUG: Unsupported extension $fileExtension, falling back to .jpg');
        fileExtension = '.jpg';
      }

      // Create unique filename
      final finalFileName =
          '${DateTime.now().millisecondsSinceEpoch}_avatar$fileExtension';
      final filePath = 'avatars/$userId/$finalFileName';
      debugPrint('🚀 MUSK_DEBUG: Target path: $filePath');

      // Upload to Supabase Storage
      debugPrint('🚀 MUSK_DEBUG: Uploading to Supabase Storage...');
      await _supabase.storage.from('user-images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExtension),
              upsert: true,
            ),
          );
      debugPrint('🚀 MUSK_DEBUG: Storage upload successful');

      // Get public URL
      final publicUrl =
          _supabase.storage.from('user-images').getPublicUrl(filePath);
      debugPrint('🚀 MUSK_DEBUG: Public URL generated: $publicUrl');

      // Update user profile in database
      if (!skipDatabaseUpdate) {
        debugPrint('🚀 MUSK_DEBUG: Updating database user record...');
        await _supabase.from('users').update({
          'avatar_url': publicUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
        debugPrint('🚀 MUSK_DEBUG: Database update successful');
      } else {
        debugPrint(
            '🚀 MUSK_DEBUG: Skipping database update (handled by caller)');
      }

      // 🚀 MUSK: Delete old avatar if provided
      if (oldUrl != null && oldUrl.isNotEmpty) {
        debugPrint('🚀 MUSK_DEBUG: Deleting old avatar: $oldUrl');
        await deleteOldAvatar(oldUrl);
      }

      // 🚀 MUSK: Invalidate cache
      debugPrint('🚀 MUSK_DEBUG: Invalidating user cache...');
      await CacheManager.instance.invalidateUser(userId);

      // Use CDN service if available, otherwise return public URL
      final cdnUrl = CDNService.instance.getImageUrl(publicUrl);
      debugPrint('🚀 MUSK_DEBUG: Final CDN URL: $cdnUrl');
      return cdnUrl;
    } catch (e) {
      debugPrint('🚀 MUSK_DEBUG: uploadAvatar CRITICAL ERROR: $e');
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.api,
          operation: 'uploadAvatar',
          context: 'Failed to upload avatar image',
        ),
      );
      return null;
    }
  }

  /// Upload cover photo to Supabase Storage and update user profile
  /// 🚀 MUSK: Atomic operation - Upload, Update DB, Delete Old, Invalidate Cache
  static Future<String?> uploadCoverPhoto(dynamic imageSource,
      {String? oldUrl, String? fileName}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint(
            '🚀 MUSK_DEBUG: uploadCoverPhoto failed - User not authenticated');
        return null;
      }

      final userId = user.id;
      debugPrint(
          '🚀 MUSK_DEBUG: Starting cover photo upload for user: $userId');

      // Check rate limit
      final rateLimitService = RateLimitService.instance;
      if (!await rateLimitService.checkImageUpload(userId)) {
        debugPrint(
            '🚀 MUSK_DEBUG: uploadCoverPhoto failed - Rate limit exceeded');
        throw Exception('Rate limit exceeded. Please try again later.');
      }

      Uint8List bytes;
      String fileExtension;

      if (imageSource is File) {
        bytes = await imageSource.readAsBytes();
        fileExtension = path.extension(imageSource.path).toLowerCase();
        debugPrint(
            '🚀 MUSK_DEBUG: Source is File. Size: ${bytes.length} bytes, Ext: $fileExtension');
      } else if (imageSource is Uint8List) {
        bytes = imageSource;
        fileExtension =
            fileName != null ? path.extension(fileName).toLowerCase() : '.jpg';
        debugPrint(
            '🚀 MUSK_DEBUG: Source is Uint8List. Size: ${bytes.length} bytes, Ext: $fileExtension');
      } else {
        debugPrint(
            '🚀 MUSK_DEBUG: uploadCoverPhoto failed - Invalid image source type');
        throw Exception('Invalid image source type');
      }

      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      if (!allowedExtensions.contains(fileExtension)) {
        debugPrint(
            '🚀 MUSK_DEBUG: Unsupported extension $fileExtension, falling back to .jpg');
        fileExtension = '.jpg';
      }

      // Create unique filename
      final finalFileName =
          '${DateTime.now().millisecondsSinceEpoch}_cover$fileExtension';
      final filePath = 'covers/$userId/$finalFileName';
      debugPrint('🚀 MUSK_DEBUG: Target path: $filePath');

      // Upload to Supabase Storage
      debugPrint('🚀 MUSK_DEBUG: Uploading to Supabase Storage...');
      await _supabase.storage.from('user-images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExtension),
              upsert: true,
            ),
          );
      debugPrint('🚀 MUSK_DEBUG: Storage upload successful');

      // Get public URL
      final publicUrl =
          _supabase.storage.from('user-images').getPublicUrl(filePath);
      debugPrint('🚀 MUSK_DEBUG: Public URL generated: $publicUrl');

      // Update user profile in database
      debugPrint('🚀 MUSK_DEBUG: Updating database user record...');
      await _supabase.from('users').update({
        'cover_photo_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      debugPrint('🚀 MUSK_DEBUG: Database update successful');

      // 🚀 MUSK: Delete old cover photo if provided
      if (oldUrl != null && oldUrl.isNotEmpty) {
        debugPrint('🚀 MUSK_DEBUG: Deleting old cover photo: $oldUrl');
        await deleteOldCoverPhoto(oldUrl);
      }

      // 🚀 MUSK: Invalidate cache
      debugPrint('🚀 MUSK_DEBUG: Invalidating user cache...');
      await CacheManager.instance.invalidateUser(userId);

      // Use CDN service if available
      final cdnUrl = CDNService.instance.getImageUrl(publicUrl);
      debugPrint('🚀 MUSK_DEBUG: Final CDN URL: $cdnUrl');
      return cdnUrl;
    } catch (e) {
      debugPrint('🚀 MUSK_DEBUG: uploadCoverPhoto CRITICAL ERROR: $e');
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.api,
          operation: 'uploadCoverPhoto',
          context: 'Failed to upload cover photo',
        ),
      );
      return null;
    }
  }

  /// Delete old avatar from storage
  static Future<void> deleteOldAvatar(String oldAvatarUrl) async {
    try {
      if (oldAvatarUrl.isEmpty) return;
      debugPrint(
          '🚀 MUSK_DEBUG: Attempting to delete old avatar: $oldAvatarUrl');

      // Extract file path from URL
      final uri = Uri.parse(oldAvatarUrl);
      final pathSegments = uri.pathSegments;

      // Supabase URL structure: /storage/v1/object/public/user-images/avatars/userId/filename
      // We need to extract everything after 'user-images/'
      final bucketIndex = pathSegments.indexOf('user-images');
      if (bucketIndex != -1 && pathSegments.length > bucketIndex + 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        debugPrint(
            '🚀 MUSK_DEBUG: Parsed relative path for deletion: $filePath');
        await _supabase.storage.from('user-images').remove([filePath]);
        debugPrint('🚀 MUSK_DEBUG: Old avatar deleted successfully');
      } else {
        debugPrint(
            '🚀 MUSK_DEBUG: Could not parse bucket path from URL: $oldAvatarUrl');
      }
    } catch (e) {
      debugPrint('🚀 MUSK_DEBUG: Error deleting old avatar: $e');
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.api,
          operation: 'deleteOldAvatar',
          context: 'Failed to delete old avatar',
        ),
      );
    }
  }

  /// Delete old cover photo from storage
  static Future<void> deleteOldCoverPhoto(String oldCoverUrl) async {
    try {
      if (oldCoverUrl.isEmpty) return;
      debugPrint(
          '🚀 MUSK_DEBUG: Attempting to delete old cover photo: $oldCoverUrl');

      // Extract file path from URL
      final uri = Uri.parse(oldCoverUrl);
      final pathSegments = uri.pathSegments;

      // Supabase URL structure: /storage/v1/object/public/user-images/covers/userId/filename
      final bucketIndex = pathSegments.indexOf('user-images');
      if (bucketIndex != -1 && pathSegments.length > bucketIndex + 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        debugPrint(
            '🚀 MUSK_DEBUG: Parsed relative path for deletion: $filePath');
        await _supabase.storage.from('user-images').remove([filePath]);
        debugPrint('🚀 MUSK_DEBUG: Old cover photo deleted successfully');
      } else {
        debugPrint(
            '🚀 MUSK_DEBUG: Could not parse bucket path from URL: $oldCoverUrl');
      }
    } catch (e) {
      debugPrint('🚀 MUSK_DEBUG: Error deleting old cover photo: $e');
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.api,
          operation: 'deleteOldCoverPhoto',
          context: 'Failed to delete old cover photo',
        ),
      );
    }
  }

  /// Get content type based on file extension
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Check if Supabase Storage bucket exists and is accessible
  static Future<bool> checkStorageConnection() async {
    try {
      await _supabase.storage.listBuckets();
      return true;
    } catch (e) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.network,
          operation: 'checkStorageConnection',
          context: 'Failed to check storage connection',
        ),
      );
      return false;
    }
  }
}
