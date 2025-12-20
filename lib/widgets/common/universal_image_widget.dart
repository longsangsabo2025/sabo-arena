import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:sabo_arena/utils/production_logger.dart';

class UniversalImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const UniversalImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder ?? const SizedBox();
    }

    final url = imageUrl!;

    if (url.toLowerCase().contains('.svg')) {
      return FutureBuilder<String>(
        future: _fetchSvg(url),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SvgPicture.string(
              snapshot.data!,
              width: width,
              height: height,
              fit: fit,
              placeholderBuilder: (context) => placeholder ?? const SizedBox(),
            );
          }
          return placeholder ?? const SizedBox();
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? const SizedBox(),
      errorWidget: (context, url, error) => errorWidget ?? const SizedBox(),
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
        // Clean SVG string
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
      ProductionLogger.error('Error loading SVG image',
          error: e, tag: 'UniversalImage');
      rethrow;
    }
  }
}
