import 'dart:async';

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The app's tap target: it sinks a little under the finger instead of
/// rippling, springs back when released, and ticks the haptic engine.
class Pressable extends StatefulWidget {
  const new({
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.pressedScale = 0.97,
    this.haptic = true,
    super.key,
  });

  final Widget child;

  /// Null disables it.
  final VoidCallback? onPressed;

  /// Read instead of the child's texts.
  final String? semanticLabel;
  final double pressedScale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  // Unbounded: the release overshoots past 1 before it settles.
  late final _scale = AnimationController.unbounded(vsync: this, value: 1);

  // Read in build: a cancel can arrive while the tree is being torn down,
  // when the context can no longer be asked.
  var _reduced = false;

  void _springTo(double target) {
    if (_reduced) {
      _scale.value = 1;
      return;
    }
    // Starting from the current velocity keeps a quick tap a visible dip
    // instead of a jump, and a re-press mid-release smooth.
    unawaited(
      _scale
          .animateWith(
            SpringSimulation(
              Motion.spring,
              _scale.value,
              target,
              _scale.velocity,
            ),
          )
          // The simulation stops within its tolerance; rest exactly there.
          .then((_) => _scale.value = target),
    );
  }

  void _tap() {
    if (widget.haptic) unawaited(HapticFeedback.selectionClick());
    widget.onPressed?.call();
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    _reduced = Motion.reduced(context);
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.semanticLabel,
        // A given label replaces the child's texts instead of repeating them.
        excludeSemantics: widget.semanticLabel != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _springTo(widget.pressedScale) : null,
          onTapUp: enabled ? (_) => _springTo(1) : null,
          onTapCancel: enabled ? () => _springTo(1) : null,
          onTap: enabled ? _tap : null,
          child: AnimatedBuilder(
            animation: _scale,
            child: widget.child,
            builder: (context, child) =>
                Transform.scale(scale: _scale.value, child: child),
          ),
        ),
      ),
    );
  }
}
