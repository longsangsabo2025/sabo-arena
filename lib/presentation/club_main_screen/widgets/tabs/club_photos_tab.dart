import 'package:flutter/material.dart';
import '../../../../utils/production_logger.dart';

class ClubPhotosTab extends StatelessWidget {
  final List<String> photos;
  final bool isLoading;
  final String? error;
  final bool isClubOwner;
  final VoidCallback onAddPhoto;
  final Function(String, int) onDeletePhoto;

  const ClubPhotosTab({
    super.key,
    required this.photos,
    required this.isLoading,
    this.error,
    required this.isClubOwner,
    required this.onAddPhoto,
    required this.onDeletePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && photos.isEmpty) {
      return Center(
        child: Text('Lỗi tải ảnh: $error'),
      );
    }

    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có hình ảnh nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (isClubOwner) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAddPhoto,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Thêm ảnh đầu tiên'),
              ),
            ],
          ],
        ),
      );
    }

    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return GestureDetector(
              onTap: () => _showPhotoDialog(context, photo, index),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photo,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[900],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        ProductionLogger.info('❌ Error loading photo $index: $error', tag: 'club_detail_section');
                        return Container(
                          color: Colors.grey[900],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text(
                                'Lỗi tải ảnh',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Delete button for owner
                  if (isClubOwner)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onDeletePhoto(photo, index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        // FAB for adding photos (only for owner)
        if (isClubOwner)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: onAddPhoto,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.add_a_photo),
            ),
          ),
      ],
    );
  }

  void _showPhotoDialog(BuildContext context, String photoUrl, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Hình ảnh'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: isClubOwner
                  ? [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDeletePhoto(photoUrl, index);
                        },
                      ),
                    ]
                  : null,
            ),
            Image.network(photoUrl, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}
