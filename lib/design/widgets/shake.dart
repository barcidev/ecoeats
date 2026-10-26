import 'dart:async';
import 'dart:math' as math;

import 'package:ecoeats/design/tokens/motion.dart';
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
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger == null || widget.trigger == oldWidget.trigger) return;
    if (widget.haptic) unawaited(HapticFeedback.mediumImpact());
    if (!Motion.reduced(context)) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      child: widget.child,
      builder: (context, child) {
        final t = _shake.value;
        // Three swings that lose strength until the panel settles.
        final dx = t == 0 || t == 1
            ? 0.0
            : math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
