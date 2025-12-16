import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Utility class to launch external map applications
class MapLauncher {
  /// Open location in native maps app (Google Maps on Android, Apple Maps on iOS)
  static Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final url = _buildMapUrl(latitude, longitude, label);

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Open directions to location in native maps app
  static Future<bool> openDirections({
    required double destinationLat,
    required double destinationLng,
    String? destinationLabel,
  }) async {
    final url = _buildDirectionsUrl(
      destinationLat,
      destinationLng,
      destinationLabel,
    );

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Build platform-specific map URL
  static String _buildMapUrl(double lat, double lng, String? label) {
    if (Platform.isIOS) {
      // Apple Maps URL scheme
      final query = label != null ? Uri.encodeComponent(label) : '';
      return 'http://maps.apple.com/?q=$query&ll=$lat,$lng';
    } else {
      // Google Maps URL (works on Android and web)
      final query = label != null ? Uri.encodeComponent(label) : '';
      return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$query';
    }
  }

  /// Build platform-specific directions URL
  static String _buildDirectionsUrl(
    double destLat,
    double destLng,
    String? label,
  ) {
    if (Platform.isIOS) {
      // Apple Maps directions
      return 'http://maps.apple.com/?daddr=$destLat,$destLng&dirflg=d';
    } else {
      // Google Maps directions
      return 'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving';
    }
  }

  /// Show map option dialog (useful if multiple map apps available)
  static Future<void> showMapOptionsDialog({
    required BuildContext context,
    required double latitude,
    required double longitude,
    String? label,
    String? address,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.map, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text('Xem vị trí'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(
                label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
            ],
            if (address != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
            Text(
              'Chọn ứng dụng bản đồ:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final success = await openLocation(
                latitude: latitude,
                longitude: longitude,
                label: label,
              );
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không thể mở ứng dụng bản đồ')),
                );
              }
            },
            icon: Icon(Icons.place),
            label: Text('Xem vị trí'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final success = await openDirections(
                destinationLat: latitude,
                destinationLng: longitude,
                destinationLabel: label,
              );
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không thể mở chỉ đường')),
                );
              }
            },
            icon: Icon(Icons.directions),
            label: Text('Chỉ đường'),
          ),
        ],
      ),
    );
  }
}

