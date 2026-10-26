import 'dart:math' as math;

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:flutter/widgets.dart';

/// Opens a page through a circle that grows from the point the user tapped,
/// or from the center of the screen when there is none.
Route<T> revealRoute<T>({
  required RouteSettings settings,
  required Widget child,
  Offset? origin,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: Motion.slow,
    reverseTransitionDuration: Motion.standard,
    pageBuilder: (_, _, _) => child,
    transitionsBuilder: (context, animation, _, child) {
      if (Motion.reduced(context)) {
        return FadeTransition(opacity: animation, child: child);
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Motion.emphasized,
        reverseCurve: Motion.emphasized.flipped,
      );
      return AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (context, child) {
          final fraction = curved.value;
          final moving = fraction > 0 && fraction < 1;
          return ClipPath(
            clipper: CircleRevealClipper(origin: origin, fraction: fraction),
            // While it grows, a shadow hugs the circle's edge and the page
            // settles from slightly closer, so it reads as an opening rather
            // than a cut.
            child: moving
                ? CustomPaint(
                    foregroundPainter: RevealEdgePainter(
                      origin: origin,
                      fraction: fraction,
                    ),
                    child: Transform.scale(
                      scale: 1 + 0.04 * (1 - fraction),
                      child: child,
                    ),
                  )
                : child,
          );
        },
      );
    },
  );
}

/// How far the farthest corner of [size] is from [center].
double _reach(Size size, Offset center) => [
  Offset.zero,
  Offset(size.width, 0),
  Offset(0, size.height),
  Offset(size.width, size.height),
].map((corner) => (corner - center).distance).reduce(math.max);

class CircleRevealClipper extends CustomClipper<Path> {
  const new({required this.origin, required this.fraction});

  final Offset? origin;

  /// 0 is a point, 1 reaches the farthest corner.
  final double fraction;

  @override
  Path getClip(Size size) {
    final center = origin ?? size.center(Offset.zero);
    return Path()..addOval(
      Rect.fromCircle(center: center, radius: _reach(size, center) * fraction),
    );
  }

  @override
  bool shouldReclip(CircleRevealClipper oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.origin != origin;
}

/// A soft shadow just inside the growing circle's edge, fading out as the
/// circle completes.
@visibleForTesting
class RevealEdgePainter extends CustomPainter {
  const new({required this.origin, required this.fraction});

  final Offset? origin;
  final double fraction;

  static const _band = 56.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = origin ?? size.center(Offset.zero);
    final radius = _reach(size, center) * fraction;
    if (radius <= 0) return;
    final circle = Rect.fromCircle(center: center, radius: radius);
    final shade = const Color(0xFF140F0B)
        .withValues(alpha: 0.4 * (1 - fraction));
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            shade.withValues(alpha: 0),
            shade.withValues(alpha: 0),
            shade,
          ],
          stops: [0, math.max(0, 1 - _band / radius), 1],
        ).createShader(circle),
    );
  }

  @override
  bool shouldRepaint(RevealEdgePainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.origin != origin;
}
