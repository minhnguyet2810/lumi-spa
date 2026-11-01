import 'package:flutter/material.dart';

import '../theme/lumi_adaptive.dart';

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
    Widget placeholder({required bool failed}) {
      final colors = Theme.of(context).colorScheme;
      return ColoredBox(
        color: colors.secondaryContainer,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.spa_outlined,
                  color: colors.onSecondaryContainer,
                  size: 34,
                ),
                const SizedBox(height: 8),
                Text(
                  LumiAdaptive.text(
                    failed ? 'Ảnh chưa tải được' : 'Ảnh đang cập nhật',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSecondaryContainer,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget attempt(int index) {
      if (index >= urls.length) {
        return placeholder(failed: urls.isNotEmpty);
      }
      return Image.network(
        urls[index],
        fit: fit,
        key: ValueKey(urls[index]),
        excludeFromSemantics: true,
        errorBuilder: (_, error, stack) => attempt(index + 1),
        loadingBuilder: (_, child, progress) => progress == null
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
