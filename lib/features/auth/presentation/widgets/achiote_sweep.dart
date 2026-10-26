import 'dart:async';
import 'dart:math' as math;

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:material_ui/material_ui.dart';

/// After a sign-in, an achiote disc grows from the button's check until it
/// covers the app, holds while Home settles beneath, and then fades away.
///
/// It lives in the root overlay, above the navigator, so it outlives the
/// page that started it when the app replaces the auth pages with Home.
abstract final class AchioteSweep {
  static const duration = Duration(milliseconds: 1100);

  @visibleForTesting
  static const key = Key('achiote-sweep');

  /// Starts the sweep at [origin], in global coordinates, and calls
  /// [onCovered] once the disc covers the app. With reduced motion there is
  /// none, the route change alone is the crossfade, and the app counts as
  /// covered at once.
  static void play(
    BuildContext context, {
    required Offset origin,
    VoidCallback? onCovered,
  }) {
    if (Motion.reduced(context)) {
      onCovered?.call();
      return;
    }
    final overlay = Overlay.of(context, rootOverlay: true);
    final box = overlay.context.findRenderObject() as RenderBox?;
    final center = box?.globalToLocal(origin) ?? origin;
    final color = context.palette.achiote;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Sweep(
        key: key,
        center: center,
        color: color,
        onCovered: onCovered,
        onDone: () => entry
          ..remove()
          ..dispose(),
      ),
    );
    overlay.insert(entry);
  }
}

class _Sweep extends StatefulWidget {
  const new({
    required this.center,
    required this.color,
    required this.onDone,
    this.onCovered,
    super.key,
  });

  final Offset center;
  final Color color;
  final VoidCallback onDone;
  final VoidCallback? onCovered;

  @override
  State<_Sweep> createState() => _SweepState();
}

class _SweepState extends State<_Sweep> with SingleTickerProviderStateMixin {
  /// Where the growth ends in the run: from here on the disc covers the app.
  static const _grown = 0.45;

  var _covered = false;

  late final _run = AnimationController(
    vsync: this,
    duration: AchioteSweep.duration,
  );

  // Grows over the first 45 %, holds while Home arrives, fades at the end.
  late final _grow = CurvedAnimation(
    parent: _run,
    curve: const Interval(0, _grown, curve: Motion.emphasized),
  );
  late final _fade = CurvedAnimation(
    parent: _run,
    curve: const Interval(0.65, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _run.addListener(_onProgress);
    unawaited(_run.forward().whenComplete(widget.onDone));
  }

  // An interval's status follows the whole run, so the end of the growth is
  // read from the run's value.
  void _onProgress() {
    if (_covered || _run.value < _grown) return;
    _covered = true;
    widget.onCovered?.call();
  }

  @override
  void dispose() {
    _grow.dispose();
    _fade.dispose();
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _run,
        builder: (context, _) => Opacity(
          opacity: 1 - _fade.value,
          child: CustomPaint(
            size: Size.infinite,
            painter: _DiscPainter(
              center: widget.center,
              growth: _grow.value,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscPainter extends CustomPainter {
  const new({required this.center, required this.growth, required this.color});

  /// The button's half height: the disc starts as the button's own color.
  static const _start = 28.0;

  final Offset center;
  final double growth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Far enough to reach the corner farthest from where it started.
    final reach = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - center).distance).reduce(math.max);
    final radius = _start + (reach - _start) * growth;
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DiscPainter oldDelegate) =>
      oldDelegate.growth != growth ||
      oldDelegate.center != center ||
      oldDelegate.color != color;
}
