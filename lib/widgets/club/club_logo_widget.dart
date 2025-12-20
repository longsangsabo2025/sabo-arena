import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:sabo_arena/utils/production_logger.dart';

class ClubLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final double borderRadius;

  const ClubLogoWidget({
    super.key,
    this.logoUrl,
    this.size = 40,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null || logoUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    final url = logoUrl!;

    if (url.toLowerCase().contains('.svg')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: FutureBuilder<String>(
          future: _fetchSvg(url),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SvgPicture.string(
                snapshot.data!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholderBuilder: (context) => _buildPlaceholder(),
              );
            }
            return _buildPlaceholder();
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.sports_tennis,
        size: size * 0.6,
        color: Colors.grey[400],
      ),
    );
  }

  static final Map<String, String> _svgCache = {};

  Future<String> _fetchSvg(String url) async {
    if (_svgCache.containsKey(url)) {
      return _svgCache[url]!;
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String svgContent = response.body;
        // Clean SVG string to remove unsupported elements
        svgContent = svgContent.replaceAll(
            RegExp(r'<filter[\s\S]*?<\/filter>', caseSensitive: false), '');
        svgContent = svgContent.replaceAll(
            RegExp(r'<filter[^>]*\/>', caseSensitive: false), '');
        svgContent = svgContent.replaceAll(
            RegExp(r'filter="[^"]*"', caseSensitive: false), '');
        svgContent = svgContent.replaceAll(
            RegExp(r'<metadata[\s\S]*?<\/metadata>', caseSensitive: false), '');

        _svgCache[url] = svgContent;
        return svgContent;
      }
      throw Exception('Failed to load SVG');
    } catch (e) {
      ProductionLogger.error('Error loading SVG club logo',
          error: e, tag: 'ClubLogo');
      rethrow;
    }
  }
}
