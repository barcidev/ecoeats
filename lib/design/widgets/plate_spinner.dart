import 'dart:math' as math;

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:flutter/widgets.dart';

/// One chase of the rim: long enough to read as calm, short enough to feel
/// alive.
const _cycle = Duration(milliseconds: 1400);

/// The spinning arc at [t] of a cycle, in turns from the top of the plate.
///
/// The head runs ahead in the first half and the tail catches up in the
/// second, so the arc grows and shrinks as it turns. The base rotation of
/// 1.25 turns per cycle plus the tail's 0.75 adds up to whole turns, so a
/// cycle ends exactly where the next one starts.
@visibleForTesting
({double start, double sweep}) plateSpinnerArc(double t) {
  const reach = 0.75;
  const shortest = 0.04;
  final head = reach * Curves.easeInOut.transform((t * 2).clamp(0, 1));
  final tail = reach * Curves.easeInOut.transform((t * 2 - 1).clamp(0, 1));
  return (start: t * 1.25 + tail, sweep: math.max(shortest, head - tail));
}

/// A plate seen from above whose rim fills or chases itself: the app's only
/// loading indicator.
class PlateSpinner extends StatefulWidget {
  const new({this.size = 24, this.color, this.progress, super.key});

  final double size;
  final Color? color;

  /// From 0 to 1, drawn as a still partial rim (pull-to-refresh); null spins.
  final double? progress;

  @override
  State<PlateSpinner> createState() => _PlateSpinnerState();
}

class _PlateSpinnerState extends State<PlateSpinner>
    with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(vsync: this, duration: _cycle);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PlateSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final spin = widget.progress == null && !Motion.reduced(context);
    if (spin && !_turn.isAnimating) {
      _turn.repeat();
    } else if (!spin && _turn.isAnimating) {
      _turn.stop();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.palette.achiote;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _turn,
        builder: (context, _) => CustomPaint(
          painter: _PlatePainter(
            color: color,
            progress: widget.progress,
            turn: _turn.value,
          ),
        ),
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  const new({required this.color, required this.progress, required this.turn});

  final Color color;
  final double? progress;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide / 12;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke / 2;
    final faint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas
      ..drawCircle(center, radius, faint)
      ..drawCircle(center, radius * 0.58, faint..strokeWidth = stroke * 0.6);

    final rim = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final value = progress;
    if (value != null) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        value.clamp(0, 1) * math.pi * 2,
        false,
        rim,
      );
    } else {
      final arc = plateSpinnerArc(turn);
      canvas.drawArc(
        rect,
        arc.start * math.pi * 2 - math.pi / 2,
        arc.sweep * math.pi * 2,
        false,
        rim,
      );
    }
  }

  @override
  bool shouldRepaint(_PlatePainter oldDelegate) =>
      oldDelegate.turn != turn ||
      oldDelegate.progress != progress ||
      oldDelegate.color != color;
}
