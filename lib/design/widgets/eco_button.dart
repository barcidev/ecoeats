import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum EcoButtonVariant { primary, secondary, quiet }

/// The main action of a screen. While it waits it folds into a spinning
/// plate; when it succeeds it opens again with a check drawn on it.
class EcoButton extends StatefulWidget {
  const new({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.success = false,
    this.onSuccess,
    this.variant = .primary,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;

  /// Null disables it.
  final VoidCallback? onPressed;

  /// Shows the spinner in place of the label and ignores taps.
  final bool loading;

  /// Opens the button with a drawn check and ignores taps.
  final bool success;

  /// Runs once the check is drawn, after [success] turns true.
  final VoidCallback? onSuccess;
  final EcoButtonVariant variant;
  final Widget? icon;

  /// Fills the available width, as the main action of a screen does.
  final bool expand;

  static const height = 56.0;

  @visibleForTesting
  static const ValueKey<String> shapeKey = ValueKey('eco-button-shape');

  @visibleForTesting
  static const ValueKey<String> checkKey = ValueKey('eco-button-check');

  @override
  State<EcoButton> createState() => _EcoButtonState();
}

class _EcoButtonState extends State<EcoButton>
    with SingleTickerProviderStateMixin {
  // The shape widens first, then the check draws itself.
  late final _check = AnimationController(
    vsync: this,
    duration: Motion.standard + Motion.slow,
  );
  late final _stroke = CurvedAnimation(
    parent: _check,
    curve: const Interval(0.37, 1, curve: Motion.emphasized),
  );

  @override
  void initState() {
    super.initState();
    if (widget.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
    }
  }

  @override
  void didUpdateWidget(EcoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.success && !oldWidget.success) {
      unawaited(_celebrate());
    } else if (!widget.success && oldWidget.success) {
      _check.value = 0;
    }
  }

  Future<void> _celebrate() async {
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    if (Motion.reduced(context)) {
      _check.value = 1;
      // Not during this build: the callback may well rebuild the caller.
      await WidgetsBinding.instance.endOfFrame;
    } else {
      await _check
          .forward(from: 0)
          .orCancel
          .then<void>((_) {}, onError: (_) {});
    }
    if (mounted && widget.success && _check.isCompleted) {
      widget.onSuccess?.call();
    }
  }

  @override
  void dispose() {
    _stroke.dispose();
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduced = Motion.reduced(context);
    final onAchiote = Color.lerp(palette.paper, palette.raised, 0.5)!;
    final (background, foreground, border) = switch (widget.variant) {
      .primary => (palette.achiote, onAchiote, null),
      .secondary => (null, palette.ink, palette.line),
      .quiet => (null, palette.ink, null),
    };
    final busy = widget.loading || widget.success;
    final disabled = widget.onPressed == null && !busy;
    // With reduced motion the shape keeps its width; only the content swaps.
    final round = widget.loading && !widget.success && !reduced;
    final morph = reduced ? Duration.zero : Motion.standard;

    final Widget content;
    if (widget.success) {
      content = _DrawnCheck(
        key: EcoButton.checkKey,
        progress: _stroke,
        color: foreground,
      );
    } else if (widget.loading) {
      content = PlateSpinner(
        key: const ValueKey('spinner'),
        size: 22,
        color: foreground,
      );
    } else {
      content = Row(
        key: const ValueKey('label'),
        mainAxisSize: .min,
        spacing: Space.xs,
        children: [
          ?widget.icon,
          Text(widget.label, style: EcoType.label.copyWith(color: foreground)),
        ],
      );
    }

    // No LayoutBuilder: screens lay states out by their intrinsic size
    // (SliverFillRemaining), which a LayoutBuilder cannot answer.
    final fill = widget.expand;
    final width = round ? EcoButton.height : (fill ? double.infinity : null);
    final box = SizedBox(
      width: width,
      height: EcoButton.height,
      child: Padding(
        padding: round
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: Space.lg),
        child: Align(
          widthFactor: width == null ? 1 : null,
          // The label keeps its natural width while it fades out of
          // the narrowing circle, cut at its edge instead of wrapping.
          child: UnconstrainedBox(
            constrainedAxis: .vertical,
            clipBehavior: .hardEdge,
            child: AnimatedSwitcher(duration: Motion.quick, child: content),
          ),
        ),
      ),
    );

    final shape = TweenAnimationBuilder<double>(
      tween: Tween(end: round ? 1 : 0),
      duration: morph,
      curve: Motion.emphasized,
      builder: (context, roundness, child) => DecoratedBox(
        key: EcoButton.shapeKey,
        decoration: ShapeDecoration(
          color: background,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(
              .circular(lerpDouble(Radii.md, EcoButton.height / 2, roundness)!),
            ),
            side: border == null ? BorderSide.none : BorderSide(color: border),
          ),
        ),
        child: child,
      ),
      // A zero-length AnimatedSize re-dirties itself during layout, so
      // reduced motion simply relays out.
      child: reduced
          ? box
          : AnimatedSize(
              duration: Motion.standard,
              curve: Motion.emphasized,
              child: box,
            ),
    );

    // The slot keeps the full width, so nothing around the button moves
    // while the shape narrows inside it.
    return Align(
      heightFactor: 1,
      widthFactor: fill ? null : 1,
      child: Pressable(
        onPressed: busy ? null : widget.onPressed,
        semanticLabel: widget.label,
        child: AnimatedOpacity(
          opacity: disabled ? 0.4 : 1,
          duration: Motion.quick,
          child: shape,
        ),
      ),
    );
  }
}

class _DrawnCheck extends StatelessWidget {
  const new({required this.progress, required this.color, super.key});

  final Animation<double> progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(22),
      painter: _CheckPainter(progress: progress, color: color),
    );
  }
}

class _CheckPainter extends CustomPainter {
  new({required this.progress, required this.color}) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide / 10;
    final tick = Path()
      ..moveTo(size.width * 0.2, size.height * 0.54)
      ..lineTo(size.width * 0.42, size.height * 0.74)
      ..lineTo(size.width * 0.8, size.height * 0.3);
    final drawn = Path();
    for (final metric in tick.computeMetrics()) {
      drawn.addPath(
        metric.extractPath(0, metric.length * progress.value),
        Offset.zero,
      );
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
