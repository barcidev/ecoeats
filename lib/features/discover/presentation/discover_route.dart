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
        builder: (context, child) => ClipPath(
          clipper: CircleRevealClipper(origin: origin, fraction: curved.value),
          child: child,
        ),
      );
    },
  );
}

class CircleRevealClipper extends CustomClipper<Path> {
  const new({required this.origin, required this.fraction});

  final Offset? origin;

  /// 0 is a point, 1 reaches the farthest corner.
  final double fraction;

  @override
  Path getClip(Size size) {
    final center = origin ?? size.center(Offset.zero);
    final reach = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - center).distance).reduce(math.max);
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: reach * fraction));
  }

  @override
  bool shouldReclip(CircleRevealClipper oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.origin != origin;
}
