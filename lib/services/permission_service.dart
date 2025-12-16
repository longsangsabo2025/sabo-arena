import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class PermissionService {
  static const String _cameraPermissionKey = 'camera_permission_granted';
  static const String _photosPermissionKey = 'photos_permission_granted';
  static const String _storagePermissionKey = 'storage_permission_granted';

  /// Check camera permission status and request if needed
  static Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;

      if (status.isGranted) {
        await _saveCameraPermissionStatus(true);
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.camera.request();
        final granted = result.isGranted;
        await _saveCameraPermissionStatus(granted);
        return granted;
      }

      if (status.isPermanentlyDenied) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return false;
      }

      return false;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Check photos/gallery permission status and request if needed
  static Future<bool> checkPhotosPermission() async {
    try {
      PermissionStatus status;

      if (Platform.isAndroid) {
        // Check Android API level
        status = await Permission.photos.status;
        if (!status.isGranted) {
          // Try storage permission for older Android versions
          final storageStatus = await Permission.storage.status;
          if (storageStatus.isGranted) {
            status = storageStatus;
          }
        }
      } else {
        // iOS
        status = await Permission.photos.status;
      }

      if (status.isGranted) {
        await _savePhotosPermissionStatus(true);
        return true;
      }

      if (status.isDenied) {
        PermissionStatus result;

        if (Platform.isAndroid) {
          // Try photos permission first
          result = await Permission.photos.request();
          if (!result.isGranted) {
            // Fallback to storage for older Android versions
            result = await Permission.storage.request();
          }
        } else {
          result = await Permission.photos.request();
        }

        final granted = result.isGranted;
        await _savePhotosPermissionStatus(granted);
        return granted;
      }

      if (status.isPermanentlyDenied) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return false;
      }

      return false;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Check if camera permission was previously granted
  static Future<bool> isCameraPermissionGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStatus = prefs.getBool(_cameraPermissionKey) ?? false;

      // Double check with system permission
      final currentStatus = await Permission.camera.status;
      final actuallyGranted = currentStatus.isGranted;

      // Update saved status if different
      if (savedStatus != actuallyGranted) {
        await _saveCameraPermissionStatus(actuallyGranted);
      }

      return actuallyGranted;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Check if photos permission was previously granted
  static Future<bool> isPhotosPermissionGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStatus = prefs.getBool(_photosPermissionKey) ?? false;

      // Double check with system permission
      PermissionStatus currentStatus;
      if (Platform.isAndroid) {
        currentStatus = await Permission.photos.status;
        if (!currentStatus.isGranted) {
          currentStatus = await Permission.storage.status;
        }
      } else {
        currentStatus = await Permission.photos.status;
      }

      final actuallyGranted = currentStatus.isGranted;

      // Update saved status if different
      if (savedStatus != actuallyGranted) {
        await _savePhotosPermissionStatus(actuallyGranted);
      }

      return actuallyGranted;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Save camera permission status
  static Future<void> _saveCameraPermissionStatus(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cameraPermissionKey, granted);
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Save photos permission status
  static Future<void> _savePhotosPermissionStatus(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_photosPermissionKey, granted);
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Check all necessary permissions at app startup
  static Future<Map<String, bool>> checkAllPermissions() async {
    try {
      final cameraGranted = await isCameraPermissionGranted();
      final photosGranted = await isPhotosPermissionGranted();

      return {'camera': cameraGranted, 'photos': photosGranted};
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {'camera': false, 'photos': false};
    }
  }

  /// Open app settings if permissions are permanently denied
  static Future<bool> openDeviceAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Clear saved permission statuses (for testing purposes)
  static Future<void> clearSavedPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cameraPermissionKey);
      await prefs.remove(_photosPermissionKey);
      await prefs.remove(_storagePermissionKey);
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }
}

