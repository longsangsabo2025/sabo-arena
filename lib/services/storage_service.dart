import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'cdn_service.dart';
import 'rate_limit_service.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class StorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload avatar image to Supabase Storage and update user profile
  static Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return null;
      }

      final userId = user.id;

      // Check rate limit
      final rateLimitService = RateLimitService.instance;
      if (!await rateLimitService.checkImageUpload(userId)) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        throw Exception('Rate limit exceeded. Please try again later.');
      }
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Get file extension
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

      if (!allowedExtensions.contains(fileExtension)) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return null;
      }

      // Create unique filename
      final fileName =
          'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'avatars/$fileName';

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await _supabase.storage
          .from('user-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExtension),
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('user-images')
          .getPublicUrl(filePath);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Update user profile in database
      await _supabase
          .from('users')
          .update({
            'avatar_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      
      // Use CDN service if available, otherwise return public URL
      final cdnUrl = CDNService.instance.getImageUrl(publicUrl);
      return cdnUrl;
    } catch (e) {
      final errorInfo = StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.api,
          operation: 'uploadAvatar',
          context: 'Failed to upload avatar image',
        ),
      );
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Upload cover photo to Supabase Storage and update user profile
  static Future<String?> uploadCoverPhoto(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return null;
      }

      final userId = user.id;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Get file extension
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

      if (!allowedExtensions.contains(fileExtension)) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return null;
      }

      // Create unique filename
      final fileName =
          'cover_${userId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'covers/$fileName';

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await _supabase.storage
          .from('user-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExtension),
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('user-images')
          .getPublicUrl(filePath);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Update user profile in database
      await _supabase
          .from('users')
          .update({
            'cover_photo_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return publicUrl;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Delete old avatar from storage
  static Future<void> deleteOldAvatar(String oldAvatarUrl) async {
    try {
      if (oldAvatarUrl.isEmpty) return;

      // Extract file path from URL
      final uri = Uri.parse(oldAvatarUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final filePath = pathSegments
            .sublist(2)
            .join('/'); // Skip /storage/v1/object/public/user-images/
        await _supabase.storage.from('user-images').remove([filePath]);
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      final errorInfo = StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.api,
          operation: 'deleteOldAvatar',
          context: 'Failed to delete old avatar',
        ),
      );
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Delete old cover photo from storage
  static Future<void> deleteOldCoverPhoto(String oldCoverUrl) async {
    try {
      if (oldCoverUrl.isEmpty) return;

      // Extract file path from URL
      final uri = Uri.parse(oldCoverUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final filePath = pathSegments
            .sublist(2)
            .join('/'); // Skip /storage/v1/object/public/user-images/
        await _supabase.storage.from('user-images').remove([filePath]);
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      final errorInfo = StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.api,
          operation: 'deleteOldCoverPhoto',
          context: 'Failed to delete old cover photo',
        ),
      );
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
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
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    } catch (e) {
      final errorInfo = StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.network,
          operation: 'checkStorageConnection',
          context: 'Failed to check storage connection',
        ),
      );
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }
}

