import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecoeats/design/painters/plate_illustration.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:flutter/widgets.dart';

/// A dish photo. While it loads, and when it fails (one seed photo is gone
/// for good), a designed placeholder takes its place: never a grey box.
class DishImage extends StatelessWidget {
  const new({
    required this.url,
    required this.name,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  /// Already sized by the caller; temporary, so it is never stored.
  final String? url;

  /// Gives the placeholder its initials and its colors.
  final String name;
  final BoxFit fit;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final placeholder = DishPlaceholder(name: name);
    final source = url;
    final Widget image;
    if (source == null || source.isEmpty) {
      image = placeholder;
    } else {
      image = LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return CachedNetworkImage(
            imageUrl: source,
            cacheKey: stableCacheKey(source),
            memCacheWidth: width.isFinite
                ? (width * MediaQuery.devicePixelRatioOf(context)).round()
                : null,
            fit: fit,
            width: width.isFinite ? width : null,
            height: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null,
            fadeInDuration: Motion.standard,
            fadeOutDuration: Motion.quick,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          );
        },
      );
    }
    return ExcludeSemantics(
      child: ClipRSuperellipse(borderRadius: borderRadius, child: image),
    );
  }
}

/// The stand-in for a photo: a gradient from the palette, the plate drawing
/// and the dish's initials in Fraunces italic.
class DishPlaceholder extends StatelessWidget {
  const new({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pairs = [
      (palette.panela, palette.maiz),
      (palette.aguacate, palette.panela),
      (palette.achiote, palette.panela),
      (palette.aguacate, palette.maiz),
    ];
    final (from, to) = pairs[_stableHash(name) % pairs.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(palette.paper, from, 0.55)!,
            Color.lerp(palette.paper, to, 0.35)!,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final size = side.isFinite ? side : 120.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              // A soft light from the upper left, as on a photographed card.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.7, -0.8),
                      radius: 1.2,
                      colors: [
                        palette.raised.withValues(alpha: 0.45),
                        palette.raised.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: 0.5,
                child: PlateIllustration(
                  size: size * 0.5,
                  color: palette.ink.withValues(alpha: 0.45),
                  accent: palette.ink.withValues(alpha: 0.45),
                ),
              ),
              Text(
                dishInitials(name),
                style: EcoType.display.copyWith(
                  fontSize: size * 0.2,
                  fontStyle: FontStyle.italic,
                  color: palette.ink.withValues(alpha: 0.8),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

const _connectors = {
  'de',
  'del',
  'la',
  'el',
  'los',
  'las',
  'con',
  'y',
  'en',
  'a',
  'al',
};

/// «Bandeja Paisa» → «BP», «Arroz con Pollo» → «AP».
String dishInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where(
        (word) => word.isNotEmpty && !_connectors.contains(word.toLowerCase()),
      );
  return words
      .take(2)
      .map((word) => word.characters.first.toUpperCase())
      .join();
}

/// Presigned URLs change their `X-Amz-*` parameters on every listing while
/// the photo stays the same, so the cache keys on the URL without them.
String stableCacheKey(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasQuery) return url;
  final kept = {
    for (final entry in uri.queryParameters.entries)
      if (!entry.key.toLowerCase().startsWith('x-amz-')) entry.key: entry.value,
  };
  return uri.replace(queryParameters: kept.isEmpty ? null : kept).toString();
}

// String.hashCode may change between runs; this keeps a dish's colors fixed.
int _stableHash(String text) {
  var hash = 0;
  for (final unit in text.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}
