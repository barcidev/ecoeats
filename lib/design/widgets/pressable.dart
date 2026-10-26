import 'dart:async';

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The app's tap target: it sinks a little under the finger instead of
/// rippling, and ticks the haptic engine on release.
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

class _PressableState extends State<Pressable> {
  var _pressed = false;

  void _press(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  void _tap() {
    if (widget.haptic) unawaited(HapticFeedback.selectionClick());
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final sink = _pressed && !Motion.reduced(context);
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.semanticLabel,
        // A given label replaces the child's texts instead of repeating them.
        excludeSemantics: widget.semanticLabel != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _press(true) : null,
          onTapUp: enabled ? (_) => _press(false) : null,
          onTapCancel: enabled ? () => _press(false) : null,
          onTap: enabled ? _tap : null,
          child: AnimatedScale(
            scale: sink ? widget.pressedScale : 1,
            duration: Motion.quick,
            curve: Motion.emphasized,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
