import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:flutter/widgets.dart';

/// Auth panels rise from the bottom as sheets over the shell's backdrop.
/// What lies beneath steps back: the welcome fades away, and a panel shrinks
/// and lifts behind the new one, like stacked sheets.
Widget authPanelTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  // The welcome is the bottom page: it is never a sheet.
  final isBase = ModalRoute.of(context)?.isFirst ?? false;
  if (Motion.reduced(context)) {
    return FadeTransition(
      opacity: animation,
      child: FadeTransition(
        opacity: ReverseAnimation(secondaryAnimation),
        child: child,
      ),
    );
  }

  final rise = CurvedAnimation(
    parent: animation,
    curve: Motion.emphasized,
    reverseCurve: Motion.emphasized.flipped,
  );
  final recede = CurvedAnimation(
    parent: secondaryAnimation,
    curve: Motion.emphasized,
    reverseCurve: Motion.emphasized.flipped,
  );

  if (isBase) {
    return FadeTransition(
      opacity: animation,
      child: FadeTransition(opacity: ReverseAnimation(recede), child: child),
    );
  }
  return SlideTransition(
    position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(rise),
    child: AnimatedBuilder(
      animation: recede,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -Space.sm * recede.value),
        child: Transform.scale(
          scale: 1 - 0.06 * recede.value,
          alignment: .topCenter,
          child: child,
        ),
      ),
    ),
  );
}
