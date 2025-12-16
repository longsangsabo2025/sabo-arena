import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/cdn_service.dart';
import '../services/image_optimization_service.dart';
import 'package:sabo_arena/utils/production_logger.dart';

class CustomImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  /// Optional widget to show when the image fails to load.
  /// If null, a default asset image is shown.
  final Widget? errorWidget;

  /// Show shimmer effect (Facebook-style) during loading
  final bool showShimmer;

  const CustomImageWidget({
    super.key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.showShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    // Validate URL first
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty || url == 'null' || url == 'undefined') {
      return _buildErrorWidget();
    }

    // Use CDN URL if available, optimize size based on display width
    final optimalSize = ImageOptimizationService.instance.getOptimalSize(width);
    final cdnUrl = CDNService.instance.getImageUrl(url, size: optimalSize);

    return CachedNetworkImage(
      imageUrl: cdnUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(
        milliseconds: 300,
      ), // Smooth fade-in like Facebook
      fadeOutDuration: const Duration(milliseconds: 100),

      // Facebook-style shimmer placeholder
      placeholder: (context, url) =>
          showShimmer ? _buildShimmerPlaceholder() : _buildSimplePlaceholder(),

      // Improved error widget
      errorWidget: (context, url, error) {
        ProductionLogger.error('Image load error: $url - $error', error: error);
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(width: width, height: height, color: Colors.white),
    );
  }

  Widget _buildSimplePlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: width != double.infinity ? width * 0.3 : 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Không thể tải',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
  }
}
