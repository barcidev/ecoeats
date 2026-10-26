import 'dart:math' as math;

import 'package:ecoeats/design/tokens/palette.dart';
import 'package:flutter/widgets.dart';

/// Five stars filled to the exact rating: 4.7 fills 70 % of the last one
/// instead of rounding it away.
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
    final star = Size.square(size);
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
                CustomPaint(size: star, painter: _StarPainter(palette.line)),
                // The drawn star spans its whole box, so the share of the box
                // shown is the share of the star filled.
                ClipRect(
                  child: Align(
                    alignment: .centerLeft,
                    widthFactor: (rating - index).clamp(0, 1).toDouble(),
                    child: CustomPaint(size: star, painter: _StarPainter(fill)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A five-point star with softened tips, as wide as [size] and centered in
/// its height.
@visibleForTesting
Path starPath(Size size) {
  const tips = 5;
  // A little plump, so it reads as a star even at 12 px.
  const inner = 0.48;
  // How far along each edge the corners are rounded off.
  const soften = 0.16;
  final corners = [
    for (var i = 0; i < tips * 2; i++)
      Offset.fromDirection(
        -math.pi / 2 + i * math.pi / tips,
        i.isEven ? 1 : inner,
      ),
  ];
  final star = Path();
  for (final (i, corner) in corners.indexed) {
    final before = corners[(i - 1) % corners.length];
    final after = corners[(i + 1) % corners.length];
    final enter = Offset.lerp(corner, before, soften)!;
    final leave = Offset.lerp(corner, after, soften)!;
    if (i == 0) {
      star.moveTo(enter.dx, enter.dy);
    } else {
      star.lineTo(enter.dx, enter.dy);
    }
    star.quadraticBezierTo(corner.dx, corner.dy, leave.dx, leave.dy);
  }
  star.close();

  final bounds = star.getBounds();
  final scale = size.width / bounds.width;
  final top = (size.height - bounds.height * scale) / 2;
  final fit = Matrix4.identity()
    ..translateByDouble(-bounds.left * scale, top - bounds.top * scale, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1);
  return star.transform(fit.storage);
}

class _StarPainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawPath(starPath(size), Paint()..color = color);

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color;
}
