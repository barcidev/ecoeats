import 'dart:math' as math;

import 'package:ecoeats/design/tokens/palette.dart';
import 'package:flutter/widgets.dart';

/// A plate between a fork and a knife, drawn in one line weight, with a leaf
/// in the accent color. It stands in for photos that fail and for empty
/// states.
class PlateIllustration extends StatelessWidget {
  const new({this.size = 120, this.color, this.accent, super.key});

  final double size;
  final Color? color;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size * 1.5, size),
        painter: PlateIllustrationPainter(
          line: color ?? palette.muted,
          accent: accent ?? palette.aguacate,
        ),
      ),
    );
  }
}

class PlateIllustrationPainter extends CustomPainter {
  const new({required this.line, required this.accent});

  final Color line;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.height;
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, unit / 60)
      ..strokeCap = StrokeCap.round;
    final center = size.center(Offset.zero);

    canvas
      ..drawCircle(center, unit * 0.42, stroke)
      ..drawCircle(center, unit * 0.28, stroke);

    // Fork on the left: three tines over a handle.
    final forkX = center.dx - unit * 0.62;
    final top = center.dy - unit * 0.34;
    final bottom = center.dy + unit * 0.38;
    for (final dx in [-0.05, 0.0, 0.05]) {
      final x = forkX + unit * dx;
      canvas.drawLine(Offset(x, top), Offset(x, top + unit * 0.18), stroke);
    }
    canvas
      ..drawLine(
        Offset(forkX - unit * 0.05, top + unit * 0.18),
        Offset(forkX + unit * 0.05, top + unit * 0.18),
        stroke,
      )
      ..drawLine(
        Offset(forkX, top + unit * 0.18),
        Offset(forkX, bottom),
        stroke,
      );

    // Knife on the right: a blade that narrows into the handle.
    final knifeX = center.dx + unit * 0.62;
    final blade = Path()
      ..moveTo(knifeX, top)
      ..quadraticBezierTo(
        knifeX + unit * 0.08,
        top + unit * 0.12,
        knifeX + unit * 0.02,
        top + unit * 0.32,
      )
      ..lineTo(knifeX, top + unit * 0.32)
      ..close();
    canvas
      ..drawPath(blade, stroke)
      ..drawLine(
        Offset(knifeX, top + unit * 0.32),
        Offset(knifeX, bottom),
        stroke,
      );

    // A leaf resting in the well.
    final leaf = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round;
    final tip = center.translate(unit * 0.1, -unit * 0.1);
    final stem = center.translate(-unit * 0.1, unit * 0.1);
    final path = Path()
      ..moveTo(stem.dx, stem.dy)
      ..quadraticBezierTo(
        center.dx - unit * 0.12,
        center.dy - unit * 0.12,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        center.dx + unit * 0.12,
        center.dy + unit * 0.12,
        stem.dx,
        stem.dy,
      );
    canvas
      ..drawPath(path, leaf)
      ..drawLine(stem, Offset.lerp(stem, tip, 0.7)!, leaf);
  }

  @override
  bool shouldRepaint(PlateIllustrationPainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.accent != accent;
}
