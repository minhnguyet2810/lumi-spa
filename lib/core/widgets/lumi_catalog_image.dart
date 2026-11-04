import '../data/lumi_catalog_repository.dart';
import 'package:flutter/material.dart';


abstract final class LumiImageSources {
  static List<String> fromItem(Map<String, dynamic> item) {
    final urls = <String>[];
    void collect(dynamic value) {
      if (value is String) {
        var candidate = value.trim();
        if (candidate.startsWith('//')) {
          candidate = 'https:$candidate';
        }
        final uri = Uri.tryParse(candidate);
        if (uri != null &&
            (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty &&
            !urls.contains(candidate)) {
          urls.add(candidate);
        }
      } else if (value is List) {
        for (final image in value) {
          collect(image);
        }
      } else if (value is Map) {
        for (final key in ['url', 'downloadUrl', 'imageUrl', 'src']) {
          collect(value[key]);
        }
      }
    }

    for (final key in [
      'imageUrl',
      'imageUrls',
      'images',
      'image',
      'thumbnailUrl',
      'thumbnail',
      'coverImageUrl',
      'photoUrl',
    ]) {
      collect(item[key]);
    }
    final enriched = LumiCatalogRepository.withDemoImage(item);
    collect(enriched['imageUrl']);
    collect(enriched['imageUrls']);
    return urls;
  }
}

/// Tries each real URL once. Missing media is not replaced by an unrelated product.
class LumiCatalogImage extends StatelessWidget {
  const LumiCatalogImage({
    super.key,
    required this.item,
    this.height,
    this.fit = BoxFit.cover,
  });
  final Map<String, dynamic> item;
  final double? height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final urls = LumiImageSources.fromItem(item);
    Widget placeholder() {
      final key = (item['id'] ?? item['name'] ?? 'lumi').toString();
      final assetIndex = (key.hashCode.abs() % 5) + 1;
      return Image.asset(
        'assets/images/welcome_spa_$assetIndex.png',
        fit: fit,
        width: double.infinity,
        height: height,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/welcome_spa_1.png',
          fit: fit,
          width: double.infinity,
          height: height,
        ),
      );
    }

    Widget attempt(int index) {
      if (index >= urls.length) {
        return placeholder();
      }
      return Image.network(
        urls[index],
        fit: fit,
        key: ValueKey(urls[index]),
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => attempt(index + 1),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : ColoredBox(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Center(
                  child: SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      );
    }

    return SizedBox(width: double.infinity, height: height, child: attempt(0));
  }
}
