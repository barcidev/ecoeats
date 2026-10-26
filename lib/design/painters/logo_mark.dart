import 'dart:math' as math;

import 'package:ecoeats/design/tokens/palette.dart';
import 'package:flutter/widgets.dart';

/// The EcoEats mark: the rim of a plate drawn in one stroke, with a leaf in
/// the middle. [progress] draws the rim from the top, so the mark can sketch
/// itself on the welcome screen.
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

class _LogoPainter extends CustomPainter {
  const new({required this.progress, required this.rim, required this.leaf});

  final double progress;
  final Color rim;
  final Color leaf;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide / 14;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke;
    final pen = Paint()
      ..color = rim
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      pen,
    );

    // The leaf grows in during the last third of the stroke.
    final grown = ((progress - 0.66) / 0.34).clamp(0.0, 1.0);
    if (grown == 0) return;
    final reach = radius * 0.5 * grown;
    final tip = center.translate(reach * 0.7, -reach * 0.7);
    final stem = center.translate(-reach * 0.7, reach * 0.7);
    final blade = Path()
      ..moveTo(stem.dx, stem.dy)
      ..quadraticBezierTo(center.dx - reach, center.dy - reach, tip.dx, tip.dy)
      ..quadraticBezierTo(
        center.dx + reach,
        center.dy + reach,
        stem.dx,
        stem.dy,
      );
    canvas.drawPath(blade, Paint()..color = leaf);
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.rim != rim ||
      oldDelegate.leaf != leaf;
}
