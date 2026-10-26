import 'dart:math' as math;

import 'package:ecoeats/design/tokens/palette.dart';
import 'package:flutter/widgets.dart';

/// The EcoEats mark: a plate seen from above, its rim and its well drawn in
/// one line weight, with a veined leaf resting in the middle. [progress]
/// draws it the way a hand would: the rim from the top, then the well, and
/// the leaf last, so the mark can sketch itself on the welcome screen.
class LogoMark extends StatelessWidget {
  const new({
    this.size = 64,
    this.progress = 1,
    this.color,
    this.accent,
    super.key,
  });

  final double size;
  final double progress;
  final Color? color;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _LogoPainter(
          progress: progress.clamp(0, 1),
          rim: color ?? palette.ink,
          leaf: accent ?? palette.achiote,
        ),
      ),
    );
  }
}

/// How far a stage that runs from [start] to [end] of the drawing has got.
double _stage(double progress, double start, double end) =>
    ((progress - start) / (end - start)).clamp(0, 1);

/// A full circle as one contour that starts at [angle], so a stroke can be
/// drawn from that point onward.
Path _ring(Offset center, double radius, double angle) {
  final bounds = Rect.fromCircle(center: center, radius: radius);
  return Path()
    ..arcTo(bounds, angle, math.pi, true)
    ..arcTo(bounds, angle + math.pi, math.pi, false);
}

Path _partial(Path path, double share) {
  final drawn = Path();
  for (final metric in path.computeMetrics()) {
    drawn.addPath(metric.extractPath(0, metric.length * share), Offset.zero);
  }
  return drawn;
}

class _LogoPainter extends CustomPainter {
  const new({required this.progress, required this.rim, required this.leaf});

  final double progress;
  final Color rim;
  final Color leaf;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final stroke = side / 14;
    final center = size.center(Offset.zero);
    final radius = side / 2 - stroke;
    final pen = Paint()
      ..color = rim
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    final rimDrawn = _stage(progress, 0, 0.6);
    if (rimDrawn > 0) {
      canvas.drawPath(
        _partial(_ring(center, radius, -math.pi / 2), rimDrawn),
        pen,
      );
    }
    // The well starts from the bottom, where the hand ended the rim's turn
    // a moment ago, and is drawn lighter.
    final wellDrawn = _stage(progress, 0.35, 0.75);
    if (wellDrawn > 0) {
      canvas.drawPath(
        _partial(_ring(center, radius * 0.64, math.pi / 2), wellDrawn),
        pen..strokeWidth = stroke * 0.55,
      );
    }

    final grown = _stage(progress, 0.66, 1);
    if (grown == 0) return;
    _paintLeaf(
      canvas,
      center,
      radius * 0.96 * Curves.easeOutBack.transform(grown),
      stroke,
    );
  }

  /// A leaf of [length] lying across the well, from its stem at the bottom
  /// left to its tip at the top right, with its vein cut out so whatever is
  /// behind the mark shows through.
  void _paintLeaf(Canvas canvas, Offset center, double length, double stroke) {
    if (length <= 0) return;
    // The leaf's own axes: along the midrib, and across it.
    const diagonal = Offset(math.sqrt1_2, -math.sqrt1_2);
    final axis = diagonal * length;
    final across = Offset(-diagonal.dy, diagonal.dx) * length * 0.34;
    // A short stalk, then the blade.
    final stalk = center - axis / 2;
    final stem = stalk + axis * 0.14;
    final reach = axis * 0.86;
    final tip = stem + reach;
    Offset at(double along, double side) =>
        stem + reach * along + across * side;

    // The two edges bow unevenly, as a real leaf does.
    final c1 = at(0.2, -1.05);
    final c2 = at(0.78, -0.95);
    final c3 = at(0.82, 0.8);
    final c4 = at(0.25, 0.9);
    final blade = Path()
      ..moveTo(stem.dx, stem.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, tip.dx, tip.dy)
      ..cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, stem.dx, stem.dy)
      ..close();
    // Inside the blade at both ends, so the leaf stays in one piece.
    final from = at(0.16, 0);
    final bend = at(0.5, -0.12);
    final to = at(0.8, 0);
    final vein = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(bend.dx, bend.dy, to.dx, to.dy);

    canvas
      ..saveLayer(
        blade
            .getBounds()
            .expandToInclude(Rect.fromPoints(stalk, stem))
            .inflate(stroke),
        Paint(),
      )
      ..drawPath(blade, Paint()..color = leaf)
      ..drawLine(
        stalk,
        at(0.1, 0),
        Paint()
          ..color = leaf
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1, stroke * 0.42),
      )
      ..drawPath(
        vein,
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1, stroke * 0.3),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.rim != rim ||
      oldDelegate.leaf != leaf;
}
