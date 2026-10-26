import 'dart:math' as math;

import 'package:ecoeats/design/tokens/palette.dart';
import 'package:flutter/widgets.dart';

/// What rests in the plate's well, in the accent color.
enum PlateDetail {
  /// A fresh leaf: the brand's plate, and the stand-in for a photo.
  leaf,

  /// A few crumbs: nothing left to show.
  crumbs,

  /// A scorch mark with smoke rising: something burnt in the kitchen.
  smoke,

  /// A plug pulled from its socket: no connection.
  cutCord,

  /// An hourglass: too many requests, wait a moment.
  hourglass,
}

/// A plate between a fork and a knife, drawn in one line weight, with a
/// [detail] in the accent color. It stands in for photos that fail and for
/// the app's unhappy states.
class PlateIllustration extends StatelessWidget {
  const new({
    this.size = 120,
    this.color,
    this.accent,
    this.detail = .leaf,
    this.progress = 1,
    super.key,
  });

  final double size;
  final Color? color;
  final Color? accent;
  final PlateDetail detail;

  /// From 1 to 0, the sand still in the hourglass's top bulb; other details
  /// ignore it.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size * 1.5, size),
        painter: PlateIllustrationPainter(
          line: color ?? palette.muted,
          accent: accent ?? palette.aguacate,
          detail: detail,
          progress: progress.clamp(0, 1),
        ),
      ),
    );
  }
}

class PlateIllustrationPainter extends CustomPainter {
  const new({
    required this.line,
    required this.accent,
    this.detail = .leaf,
    this.progress = 1,
  });

  final Color line;
  final Color accent;
  final PlateDetail detail;
  final double progress;

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

    final pen = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (detail) {
      case .leaf:
        _leaf(canvas, center, unit, pen);
      case .crumbs:
        _crumbs(canvas, center, unit);
      case .smoke:
        _smoke(canvas, center, unit, pen);
      case .cutCord:
        _cutCord(canvas, center, unit, pen);
      case .hourglass:
        _hourglass(canvas, center, unit, pen);
    }
  }

  void _leaf(Canvas canvas, Offset center, double unit, Paint pen) {
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
      ..drawPath(path, pen)
      ..drawLine(stem, Offset.lerp(stem, tip, 0.7)!, pen);
  }

  void _crumbs(Canvas canvas, Offset center, double unit) {
    final crumb = Paint()..color = accent;
    for (final (dx, dy, size) in const [
      (-0.1, 0.07, 0.022),
      (0.06, -0.05, 0.018),
      (0.12, 0.1, 0.016),
      (-0.03, -0.13, 0.014),
    ]) {
      canvas.drawCircle(
        center.translate(unit * dx, unit * dy),
        unit * size,
        crumb,
      );
    }
  }

  void _smoke(Canvas canvas, Offset center, double unit, Paint pen) {
    // The scorch: a soft, uneven stain at the bottom of the well.
    final stain = Path()
      ..addOval(
        Rect.fromCenter(
          center: center.translate(0, unit * 0.12),
          width: unit * 0.26,
          height: unit * 0.09,
        ),
      );
    canvas.drawPath(stain, Paint()..color = accent.withValues(alpha: 0.28));
    // Two wisps curling up from it.
    for (final dx in [-0.05, 0.05]) {
      final base = center.translate(unit * dx, unit * 0.08);
      final wisp = Path()
        ..moveTo(base.dx, base.dy)
        ..cubicTo(
          base.dx - unit * 0.06,
          base.dy - unit * 0.08,
          base.dx + unit * 0.06,
          base.dy - unit * 0.14,
          base.dx,
          base.dy - unit * 0.22,
        );
      canvas.drawPath(wisp, pen);
    }
  }

  void _cutCord(Canvas canvas, Offset center, double unit, Paint pen) {
    final gap = unit * 0.03;
    // The plug, from the left of the well, its prongs pointing right.
    final plug = Rect.fromLTRB(
      center.dx - unit * 0.12,
      center.dy - unit * 0.04,
      center.dx - gap - unit * 0.04,
      center.dy + unit * 0.04,
    );
    // The socket, on the right, waiting.
    final socket = Rect.fromLTRB(
      center.dx + gap,
      center.dy - unit * 0.05,
      center.dx + unit * 0.09,
      center.dy + unit * 0.05,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(plug, Radius.circular(unit * 0.015)),
        pen,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(socket, Radius.circular(unit * 0.015)),
        pen,
      );
    for (final dy in [-0.018, 0.018]) {
      canvas.drawLine(
        Offset(plug.right, center.dy + unit * dy),
        Offset(plug.right + unit * 0.035, center.dy + unit * dy),
        pen,
      );
    }
    final leftCord = Path()
      ..moveTo(plug.left, center.dy)
      ..quadraticBezierTo(
        plug.left - unit * 0.06,
        center.dy + unit * 0.1,
        center.dx - unit * 0.24,
        center.dy + unit * 0.12,
      );
    final rightCord = Path()
      ..moveTo(socket.right, center.dy)
      ..quadraticBezierTo(
        socket.right + unit * 0.06,
        center.dy - unit * 0.1,
        center.dx + unit * 0.24,
        center.dy - unit * 0.12,
      );
    canvas
      ..drawPath(leftCord, pen)
      ..drawPath(rightCord, pen);
  }

  void _hourglass(Canvas canvas, Offset center, double unit, Paint pen) {
    final half = unit * 0.16;
    final width = unit * 0.1;
    final top = center.dy - half;
    final bottom = center.dy + half;
    Path bulb(double from) => Path()
      ..moveTo(center.dx - width, from)
      ..lineTo(center.dx + width, from)
      ..lineTo(center.dx, center.dy)
      ..close();
    final upper = bulb(top);
    final lower = bulb(bottom);
    final sand = Paint()..color = accent;

    // The sand left on top sits at the neck; what fell rests on the base.
    if (progress > 0) {
      canvas
        ..save()
        ..clipRect(
          Rect.fromLTRB(
            center.dx - width,
            center.dy - half * progress,
            center.dx + width,
            center.dy,
          ),
        )
        ..drawPath(upper, sand)
        ..restore();
    }
    if (progress < 1) {
      canvas
        ..save()
        ..clipRect(
          Rect.fromLTRB(
            center.dx - width,
            bottom - half * (1 - progress),
            center.dx + width,
            bottom,
          ),
        )
        ..drawPath(lower, sand)
        ..restore();
    }
    canvas
      ..drawPath(upper, pen)
      ..drawPath(lower, pen)
      ..drawLine(
        Offset(center.dx - width * 1.3, top),
        Offset(center.dx + width * 1.3, top),
        pen,
      )
      ..drawLine(
        Offset(center.dx - width * 1.3, bottom),
        Offset(center.dx + width * 1.3, bottom),
        pen,
      );
  }

  @override
  bool shouldRepaint(PlateIllustrationPainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.accent != accent ||
      oldDelegate.detail != detail ||
      oldDelegate.progress != progress;
}
