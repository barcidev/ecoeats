import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:flutter/widgets.dart';

/// Five stars filled to the exact rating: 4.7 leaves most of the last one
/// empty instead of rounding it away.
class RatingStars extends StatelessWidget {
  const new({
    required this.rating,
    this.size = 14,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final double rating;
  final double size;
  final Color? color;

  /// The rating as the active language reads it; the stars alone say nothing.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fill = color ?? palette.maiz;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: .min,
        spacing: size / 7,
        children: [
          for (var index = 0; index < 5; index++)
            Stack(
              children: [
                Icon(EcoIcons.star, size: size, color: palette.line),
                ClipRect(
                  child: Align(
                    alignment: .centerLeft,
                    widthFactor: (rating - index).clamp(0, 1).toDouble(),
                    child: Icon(EcoIcons.starFill, size: size, color: fill),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
