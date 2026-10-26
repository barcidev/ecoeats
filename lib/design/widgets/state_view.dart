import 'dart:async';

import 'package:ecoeats/design/painters/plate_illustration.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:flutter/widgets.dart';

enum StateKind { empty, error, offline, rateLimited }

/// What a screen shows instead of its content: nothing found, no connection,
/// too many requests or a failure, always with its own drawing, never a bare
/// text. It rises into place when it appears.
class StateView extends StatefulWidget {
  const new({
    required this.kind,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.cooldown,
    this.cooldownLabel,
    this.footnote,
    super.key,
  });

  final StateKind kind;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// How long the action stays disabled, as a 429 asks.
  final Duration? cooldown;

  /// The action's text while the cooldown runs, such as «Intenta en 0:42».
  final String Function(Duration remaining)? cooldownLabel;

  /// Small print at the bottom, such as a request reference.
  final String? footnote;

  @override
  State<StateView> createState() => _StateViewState();
}

class _StateViewState extends State<StateView>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  late final _enter = AnimationController(
    vsync: this,
    duration: Motion.slow + Motion.stagger,
  );
  var _entered = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entered) return;
    _entered = true;
    if (Motion.reduced(context)) {
      _enter.value = 1;
    } else {
      _enter.forward();
    }
  }

  @override
  void didUpdateWidget(StateView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cooldown != widget.cooldown) _start();
  }

  void _start() {
    _ticker?.cancel();
    _remaining = widget.cooldown ?? Duration.zero;
    if (_remaining <= Duration.zero) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _remaining -= const Duration(seconds: 1));
      if (_remaining <= Duration.zero) timer.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _enter.dispose();
    super.dispose();
  }

  /// The view's part that starts [delay] into the entrance: it fades in
  /// while it rises the last few pixels.
  Widget _rise(Widget child, {Duration delay = Duration.zero}) {
    final total = _enter.duration!.inMicroseconds;
    final shown = CurvedAnimation(
      parent: _enter,
      curve: Interval(
        delay.inMicroseconds / total,
        (delay + Motion.slow).inMicroseconds / total,
        curve: Motion.emphasized,
      ),
    );
    return AnimatedBuilder(
      animation: shown,
      child: child,
      builder: (context, child) => Opacity(
        opacity: shown.value,
        child: Transform.translate(
          offset: Offset(0, (1 - shown.value) * Space.sm),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (detail, accent) = switch (widget.kind) {
      .empty => (PlateDetail.crumbs, palette.panela),
      .error => (PlateDetail.smoke, palette.achiote),
      // The plate's own lines are muted; the cord stands out in ink.
      .offline => (PlateDetail.cutCord, palette.ink),
      .rateLimited => (PlateDetail.hourglass, palette.maiz),
    };
    final waiting = _remaining > Duration.zero;
    final cooldown = widget.cooldown;
    final sand = waiting && cooldown != null
        ? _remaining.inMicroseconds / cooldown.inMicroseconds
        : 0.0;
    final label = waiting
        ? widget.cooldownLabel?.call(_remaining) ?? widget.actionLabel
        : widget.actionLabel;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.gutter),
        child: Column(
          mainAxisSize: .min,
          children: [
            _rise(
              // Between ticks the sand keeps falling, so it never jumps.
              TweenAnimationBuilder<double>(
                tween: Tween(end: sand),
                duration: Motion.reduced(context)
                    ? Duration.zero
                    : const Duration(seconds: 1),
                builder: (context, left, _) => PlateIllustration(
                  accent: accent,
                  detail: detail,
                  progress: left,
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            _rise(
              delay: Motion.stagger,
              Column(
                mainAxisSize: .min,
                children: [
                  Text(
                    widget.title,
                    textAlign: .center,
                    style: EcoType.title.copyWith(color: palette.ink),
                  ),
                  if (widget.message case final message?) ...[
                    const SizedBox(height: Space.xs),
                    Text(
                      message,
                      textAlign: .center,
                      style: EcoType.body.copyWith(color: palette.muted),
                    ),
                  ],
                  if (label != null) ...[
                    const SizedBox(height: Space.lg),
                    EcoButton(
                      label: label,
                      variant: .secondary,
                      expand: false,
                      onPressed: waiting ? null : widget.onAction,
                    ),
                  ],
                  if (widget.footnote case final footnote?) ...[
                    const SizedBox(height: Space.lg),
                    Text(
                      footnote,
                      style: EcoType.overline.copyWith(color: palette.muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
