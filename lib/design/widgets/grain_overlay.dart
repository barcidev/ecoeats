import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ecoeats/design/tokens/palette.dart';
import 'package:flutter/widgets.dart';

/// Paper grain over a surface, so flat color reads as printed matter. The
/// dots come from a fixed seed: the texture never crawls between frames.
class GrainOverlay extends StatelessWidget {
  const new({this.child, this.opacity = 0.06, super.key});

  final Widget? child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final grain = IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GrainPainter(
            context.palette.ink.withValues(alpha: opacity),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
    final content = child;
    if (content == null) return grain;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        content,
        Positioned.fill(child: grain),
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    final count = math.min(6000, (size.width * size.height / 90).round());
    final points = [
      for (var i = 0; i < count; i++)
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
    ];
    canvas.drawPoints(
      ui.PointMode.points,
      points,
      Paint()
        ..color = color
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) => oldDelegate.color != color;
}
