import 'dart:async';

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Pulling the page down from its top shrinks it toward 0.9 over the screen
/// behind it; letting go past [threshold] closes it, otherwise it springs
/// back with the scroll.
class SwipeToDismiss extends StatefulWidget {
  const new({
    required this.child,
    required this.onDismiss,
    this.threshold = 120,
    super.key,
  });

  final Widget child;
  final VoidCallback onDismiss;

  /// How far, in logical pixels past the top, the pull must go to close.
  final double threshold;

  @override
  State<SwipeToDismiss> createState() => _SwipeToDismissState();
}

class _SwipeToDismissState extends State<SwipeToDismiss> {
  var _pull = 0.0;
  var _dragging = false;
  var _dismissed = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || _dismissed) return false;
    final metrics = notification.metrics;
    final pull = (metrics.minScrollExtent - metrics.pixels).clamp(
      0.0,
      double.infinity,
    );
    // The finger lifts when the scroll stops being dragged: the first
    // ballistic update, or the end of a drag that stopped still. The pull
    // that counts is the one held while dragging.
    final dragged = switch (notification) {
      ScrollUpdateNotification(:final dragDetails) => dragDetails != null,
      ScrollStartNotification(:final dragDetails) => dragDetails != null,
      _ => _dragging,
    };
    final released =
        _dragging &&
        (notification is ScrollEndNotification ||
            (notification is ScrollUpdateNotification && !dragged));
    if (released && _pull >= widget.threshold) {
      _dismissed = true;
      widget.onDismiss();
      return false;
    }
    _dragging = dragged && notification is! ScrollEndNotification;

    if (pull != _pull) {
      final crossed = (_pull < widget.threshold) != (pull < widget.threshold);
      if (crossed && _dragging) unawaited(HapticFeedback.selectionClick());
      setState(() => _pull = pull);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final progress = Motion.reduced(context)
        ? 0.0
        : (_pull / (widget.threshold * 2)).clamp(0.0, 1.0);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Transform.scale(
        scale: 1 - 0.1 * progress,
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.all(.circular(Radii.lg * progress)),
          child: widget.child,
        ),
      ),
    );
  }
}
