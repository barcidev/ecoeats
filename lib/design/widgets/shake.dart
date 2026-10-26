import 'dart:async';

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Shakes its child sideways, the way a head says no, each time [trigger]
/// changes to a new non-null value (for example, a failed attempt counter).
class Shake extends StatefulWidget {
  const new({
    required this.child,
    required this.trigger,
    this.haptic = true,
    super.key,
  });

  final Widget child;
  final Object? trigger;
  final bool haptic;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  // Looser and far less damped than Motion.spring: the panel swings about
  // three times, each weaker, before it rests.
  static const _swing = SpringDescription(
    mass: 1,
    stiffness: 1400,
    damping: 14,
  );

  /// The sideways kick, in logical pixels per second: about 11 px of reach.
  static const _kick = 420.0;

  // Below a tenth of a pixel the swings are invisible; stop there.
  static const _rest = Tolerance(distance: 0.1, velocity: 5);

  late final _offset = AnimationController.unbounded(vsync: this);

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger == null || widget.trigger == oldWidget.trigger) return;
    if (widget.haptic) unawaited(HapticFeedback.mediumImpact());
    if (Motion.reduced(context)) return;
    unawaited(
      _offset
          .animateWith(SpringSimulation(_swing, 0, 0, _kick, tolerance: _rest))
          .then((_) => _offset.value = 0),
    );
  }

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      child: widget.child,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_offset.value, 0), child: child),
    );
  }
}
