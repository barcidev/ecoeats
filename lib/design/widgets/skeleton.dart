import 'dart:ui' show lerpDouble;

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// One sweep of the light and the pause after it.
const _period = Duration(milliseconds: 1600);

/// The part of the period the light spends crossing; the rest is a pause.
const _crossing = 0.7;

/// How wide the light is, as a share of the screen.
const _bandShare = 0.4;

/// The center of the light band at [time], in screen coordinates.
///
/// Every skeleton reads it from the frame clock, so blocks mounted at
/// different moments still shine in step, as one light crossing the screen.
@visibleForTesting
double shimmerBandX(Duration time, double screenWidth) {
  final t =
      (time.inMicroseconds % _period.inMicroseconds) / _period.inMicroseconds;
  final band = screenWidth * _bandShare;
  final travel = Curves.easeInOut.transform((t / _crossing).clamp(0, 1));
  return lerpDouble(-band, screenWidth + band, travel)!;
}

/// A block in the shape of the content that is on its way. Screens compose
/// them to mirror their real layout, so nothing jumps when data arrives.
class Skeleton extends StatefulWidget {
  const new({this.width, this.height, this.radius = Radii.sm, super.key});

  final double? width;
  final double? height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Duration> _clock = ValueNotifier(Duration.zero);
  late final _ticker = createTicker((_) {
    _clock.value = SchedulerBinding.instance.currentFrameTimeStamp;
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // The light lifts the block toward the brightest surface of each mode.
    final light = palette.paper.computeLuminance() > 0.5;
    final shine = light
        ? Color.lerp(palette.line, palette.raised, 0.75)!
        : Color.lerp(palette.line, palette.ink, 0.08)!;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: _ShimmerBlock(
          color: palette.line,
          shine: Motion.reduced(context) ? null : shine,
          radius: widget.radius,
          clock: _clock,
          screenWidth: MediaQuery.sizeOf(context).width,
        ),
      ),
    );
  }
}

class _ShimmerBlock extends LeafRenderObjectWidget {
  const new({
    required this.color,
    required this.shine,
    required this.radius,
    required this.clock,
    required this.screenWidth,
  });

  final Color color;

  /// Null keeps the block flat.
  final Color? shine;
  final double radius;
  final ValueListenable<Duration> clock;
  final double screenWidth;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderShimmerBlock(
    color: color,
    shine: shine,
    radius: radius,
    clock: clock,
    screenWidth: screenWidth,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderShimmerBlock renderObject,
  ) {
    renderObject
      ..color = color
      ..shine = shine
      ..radius = radius
      ..clock = clock
      ..screenWidth = screenWidth;
  }
}

class _RenderShimmerBlock extends RenderBox {
  new({
    required this._color,
    required this._shine,
    required this._radius,
    required this._clock,
    required this._screenWidth,
  });

  Color _color;
  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  Color? _shine;
  Color? get shine => _shine;
  set shine(Color? value) {
    if (_shine == value) return;
    _shine = value;
    markNeedsPaint();
  }

  double _radius;
  double get radius => _radius;
  set radius(double value) {
    if (_radius == value) return;
    _radius = value;
    markNeedsPaint();
  }

  ValueListenable<Duration> _clock;
  ValueListenable<Duration> get clock => _clock;
  set clock(ValueListenable<Duration> value) {
    if (_clock == value) return;
    if (attached) _clock.removeListener(markNeedsPaint);
    _clock = value;
    if (attached) _clock.addListener(markNeedsPaint);
  }

  double _screenWidth;
  double get screenWidth => _screenWidth;
  set screenWidth(double value) {
    if (_screenWidth == value) return;
    _screenWidth = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _clock.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _clock.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  // Like an empty Container: it fills bounded space and collapses otherwise.
  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    Size(
      constraints.hasBoundedWidth ? constraints.maxWidth : 0,
      constraints.hasBoundedHeight ? constraints.maxHeight : 0,
    ),
  );

  @override
  void paint(PaintingContext context, Offset offset) {
    final rect = offset & size;
    final outline = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(.circular(_radius)),
    ).getOuterPath(rect);
    final canvas = context.canvas..drawPath(outline, Paint()..color = _color);

    final shine = _shine;
    if (shine == null) return;
    final band = _screenWidth * _bandShare;
    final center =
        shimmerBandX(_clock.value, _screenWidth) -
        localToGlobal(Offset.zero).dx;
    final light = Rect.fromLTWH(
      offset.dx + center - band / 2,
      offset.dy,
      band,
      size.height,
    );
    if (!light.overlaps(rect)) return;
    canvas
      ..save()
      ..clipPath(outline)
      ..drawRect(
        light,
        Paint()
          ..shader = LinearGradient(
            colors: [
              shine.withValues(alpha: 0),
              shine,
              shine.withValues(alpha: 0),
            ],
          ).createShader(light),
      )
      ..restore();
  }
}
