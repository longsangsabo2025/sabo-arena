import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'share_analytics_service.dart';
// ELON_MODE_AUTO_FIX

/// 🎨 Rich Content Share Service
/// Capture widgets as images and share with text like TikTok/Facebook
class RichShareService {
  static final _screenshotController = ScreenshotController();

  /// 📸 Capture widget as high-quality image
  static Future<Uint8List?> captureWidget({
    required Widget widget,
    BuildContext? context,
    double pixelRatio = 3.0,
  }) async {
    try {
      final imageBytes = await _screenshotController.captureFromWidget(
        widget,
        pixelRatio: pixelRatio,
        context: context,
        delay: const Duration(milliseconds: 100), // Wait for rendering
      );

      return imageBytes;
    } catch (e) {
      return null;
    }
  }

  /// 💾 Save image to temporary directory
  static Future<File?> saveImageToTemp(
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/${filename}_$timestamp.png');

      await file.writeAsBytes(imageBytes);

      return file;
    } catch (e) {
      return null;
    }
  }

  /// 🚀 Share widget as image + text (Main Method)
  static Future<ShareResult?> shareWidgetAsImage({
    required Widget widget,
    required String text,
    required String filename,
    BuildContext? context,
    String? subject,
    double pixelRatio = 3.0,
    // Analytics parameters
    String? contentType,
    String? contentId,
  }) async {
    final startTime = DateTime.now();

    try {
      // Track share initiated
      if (contentType != null && contentId != null) {
        await ShareAnalyticsService.trackShareInitiated(
          contentType: contentType,
          contentId: contentId,
          shareMethod: 'rich_image',
        );
      }

      if (context != null && !context.mounted) return null;

      // 1. Capture widget
      final imageBytes = await captureWidget(
        widget: widget,
        context: context,
        pixelRatio: pixelRatio,
      );

      if (imageBytes == null) {
        throw Exception('Không thể chụp ảnh widget');
      }

      // 2. Save to temp file
      final file = await saveImageToTemp(imageBytes, filename);
      if (file == null) {
        throw Exception('Không thể lưu ảnh');
      }

      // 3. Share with text
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: subject ?? 'Từ SABO ARENA',
      );

      // Track performance
      final processingTime =
          DateTime.now().difference(startTime).inMilliseconds;
      if (contentType != null && contentId != null) {
        await ShareAnalyticsService.trackSharePerformance(
          contentType: contentType,
          contentId: contentId,
          processingTimeMs: processingTime,
          imageSizeBytes: imageBytes.length,
          wasSuccessful: true,
        );

        // Track completion (if not dismissed/cancelled)
        if (result.status == ShareResultStatus.success) {
          await ShareAnalyticsService.trackShareCompleted(
            contentType: contentType,
            contentId: contentId,
            shareMethod: 'rich_image',
            shareDestination:
                'unknown', // ShareResult doesn't provide destination
          );
        } else if (result.status == ShareResultStatus.dismissed) {
          await ShareAnalyticsService.trackShareCancelled(
            contentType: contentType,
            contentId: contentId,
            shareMethod: 'rich_image',
          );
        }
      }

      // 4. Cleanup (after 5 seconds to ensure share dialog has opened)
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Ignore file deletion error
        }
      });

      return result;
    } catch (e) {
      // Track error
      if (contentType != null && contentId != null) {
        final processingTime =
            DateTime.now().difference(startTime).inMilliseconds;
        await ShareAnalyticsService.trackSharePerformance(
          contentType: contentType,
          contentId: contentId,
          processingTimeMs: processingTime,
          imageSizeBytes: 0,
          wasSuccessful: false,
          errorMessage: e.toString(),
        );
      }

      rethrow;
    }
  }

  /// 📦 Share image file directly (for pre-generated images)
  static Future<ShareResult?> shareImageFile({
    required String filePath,
    required String text,
    String? subject,
  }) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: text,
        subject: subject ?? 'Từ SABO ARENA',
      );

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 🧹 Clean up all temp share files
  static Future<void> cleanupTempFiles() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();
      // int deleted = 0;
      for (var file in files) {
        if (file.path.contains('share_') && file.path.endsWith('.png')) {
          await file.delete();
          // deleted++;
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
