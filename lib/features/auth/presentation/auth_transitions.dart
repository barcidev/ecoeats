import 'package:ecoeats/design/tokens/motion.dart';
import 'package:flutter/widgets.dart';

/// Auth panels rise over the shell's background, which never moves.
Widget authPanelTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (Motion.reduced(context)) {
    return FadeTransition(opacity: animation, child: child);
  }
  final curved = CurvedAnimation(parent: animation, curve: Motion.emphasized);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
