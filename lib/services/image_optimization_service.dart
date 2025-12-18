import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
// ELON_MODE_AUTO_FIX
import 'package:path/path.dart' as path;

/// Image Optimization Service
/// Handles image compression, thumbnail generation, and format conversion
/// 
/// Features:
/// - Automatic compression before upload
/// - Thumbnail generation (150x150, 800x800)
/// - WebP format conversion for modern browsers
/// - Progressive image loading support
class ImageOptimizationService {
  static ImageOptimizationService? _instance;
  static ImageOptimizationService get instance =>
      _instance ??= ImageOptimizationService._();

  ImageOptimizationService._();

  // Image size limits
  static const int maxThumbnailSize = 150;
  static const int maxMediumSize = 800;
  static const int maxFullSize = 2000;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  /// Compress image before upload
  /// Returns compressed file path
  Future<File?> compressImage(
    File imageFile, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    bool convertToWebP = true,
  }) async {
    try {
      if (kDebugMode) {
      }

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        if (kDebugMode) {
        }
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final extension = convertToWebP ? '.webp' : path.extension(imageFile.path);
      final targetPath = path.join(tempDir.path, '${fileName}_compressed$extension');

      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth ?? 0,
        minHeight: maxHeight ?? 0,
        format: convertToWebP ? CompressFormat.webp : CompressFormat.jpeg,
      );

      if (compressedFile == null) {
        if (kDebugMode) {
        }
        return null;
      }

      // Convert XFile to File
      final compressedFileObj = File(compressedFile.path);
      // final compressedSize = await compressedFileObj.length(); // Unused
      // final compressionRatio = (1 - compressedSize / fileSize) * 100;

      if (kDebugMode) {
      }

      return compressedFileObj;
    } catch (e) {
      if (kDebugMode) {
      }
      return null;
    }
  }

  /// Generate thumbnail (150x150)
  Future<File?> generateThumbnail(File imageFile) async {
    return await compressImage(
      imageFile,
      maxWidth: maxThumbnailSize,
      maxHeight: maxThumbnailSize,
      quality: 75,
      convertToWebP: true,
    );
  }

  /// Generate medium size image (800x800)
  Future<File?> generateMediumSize(File imageFile) async {
    return await compressImage(
      imageFile,
      maxWidth: maxMediumSize,
      maxHeight: maxMediumSize,
      quality: 85,
      convertToWebP: true,
    );
  }

  /// Generate full size image (max 2000x2000)
  Future<File?> generateFullSize(File imageFile) async {
    return await compressImage(
      imageFile,
      maxWidth: maxFullSize,
      maxHeight: maxFullSize,
      quality: 90,
      convertToWebP: true,
    );
  }

  /// Generate all sizes (thumbnail, medium, full)
  /// Returns map with keys: 'thumbnail', 'medium', 'full'
  Future<Map<String, File?>> generateAllSizes(File imageFile) async {
    final results = <String, File?>{};

    // Generate in parallel for better performance
    final futures = await Future.wait([
      generateThumbnail(imageFile),
      generateMediumSize(imageFile),
      generateFullSize(imageFile),
    ]);

    results['thumbnail'] = futures[0];
    results['medium'] = futures[1];
    results['full'] = futures[2];

    return results;
  }

  /// Get optimal image size based on display width
  /// Returns size name: 'thumbnail', 'medium', or 'full'
  String getOptimalSize(double displayWidth) {
    if (displayWidth <= maxThumbnailSize) {
      return 'thumbnail';
    } else if (displayWidth <= maxMediumSize) {
      return 'medium';
    } else {
      return 'full';
    }
  }

  /// Validate image file
  Future<bool> validateImage(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        return false;
      }

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        return false;
      }

      // Check file extension
      final extension = path.extension(imageFile.path).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      if (!allowedExtensions.contains(extension)) {
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
      }
      return false;
    }
  }

  /// Get image dimensions
  Future<Map<String, int>?> getImageDimensions(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
      return {
        'width': frame.image.width,
        'height': frame.image.height,
      };
    } catch (e) {
      if (kDebugMode) {
      }
      return null;
    }
  }
}


