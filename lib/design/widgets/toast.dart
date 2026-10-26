import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

enum ToastTone { neutral, success, alert }

/// A short note that drops from the top over frosted glass and leaves by
/// itself, or at once when flicked up. Only one shows at a time: a new one
/// replaces the current.
abstract final class Toast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    ToastTone tone = .neutral,
    Duration duration = const Duration(seconds: 3),
  }) {
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastBanner(
        message: message,
        tone: tone,
        duration: duration,
        onDone: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );
    _current = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }
}

class _ToastBanner extends StatefulWidget {
  const new({
    required this.message,
    required this.tone,
    required this.duration,
    required this.onDone,
  });

  final String message;
  final ToastTone tone;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_ToastBanner> createState() => _ToastBannerState();
}

class _ToastBannerState extends State<_ToastBanner>
    with TickerProviderStateMixin {
  late final _drop = AnimationController(
    vsync: this,
    duration: Motion.standard,
  );

  /// How far the finger has moved the banner, in logical pixels.
  late final _drag = AnimationController.unbounded(vsync: this);

  Timer? _stay;
  var _leaving = false;

  // A drag past this, or an upward flick, sends the banner away.
  static const _away = 24.0;
  static const _flick = 300.0;

  @override
  void initState() {
    super.initState();
    unawaited(
      _drop.forward().then((_) {
        if (mounted) _wait();
      }),
    );
  }

  /// Starts the full stay again: a note the reader touched is not cut short.
  void _wait() {
    _stay?.cancel();
    _stay = Timer(widget.duration, _leave);
  }

  Future<void> _leave({double velocity = 0}) async {
    if (_leaving) return;
    _leaving = true;
    _stay?.cancel();
    if (_drag.value < 0) {
      // Thrown away: it keeps the finger's speed upward while it fades, and
      // a slow push still leaves briskly.
      _drag.animateWith(
        FrictionSimulation(0.05, _drag.value, math.min(velocity, -_flick * 2)),
      );
    }
    await _drop.reverse().orCancel.then<void>((_) {}, onError: (_) {});
    if (mounted) widget.onDone();
  }

  void _dragged(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    // Down is not a way out: the banner gives a little, then resists.
    final pulled =
        _drag.value + (_drag.value + delta > 0 ? delta * 0.3 : delta);
    _drag.value = math.min(pulled, Space.md);
  }

  void _released(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_drag.value < -_away || velocity < -_flick) {
      unawaited(_leave(velocity: velocity));
      return;
    }
    unawaited(
      _drag
          .animateWith(
            SpringSimulation(Motion.spring, _drag.value, 0, velocity),
          )
          .then((_) => _drag.value = 0),
    );
    _wait();
  }

  @override
  void dispose() {
    _stay?.cancel();
    _drop.dispose();
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dot = switch (widget.tone) {
      .neutral => palette.ink,
      .success => palette.aguacate,
      .alert => palette.achiote,
    };
    final reduced = Motion.reduced(context);
    final shown = CurvedAnimation(parent: _drop, curve: Motion.emphasized);
    const shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(.circular(Radii.md)),
    );

    final banner = Semantics(
      liveRegion: true,
      // Frosted: what scrolls under the note blurs instead of fighting it.
      child: ClipRSuperellipse(
        borderRadius: const BorderRadius.all(.circular(Radii.md)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: palette.raised.withValues(alpha: 0.78),
              shape: shape.copyWith(side: BorderSide(color: palette.line)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.sm,
              ),
              child: Row(
                spacing: Space.sm,
                children: [
                  DecoratedBox(
                    decoration: ShapeDecoration(
                      color: dot,
                      shape: const CircleBorder(),
                    ),
                    child: const SizedBox.square(dimension: 8),
                  ),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: EcoType.bodySmall.copyWith(color: palette.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.gutter,
            vertical: Space.xs,
          ),
          child: GestureDetector(
            onVerticalDragStart: (_) {
              _stay?.cancel();
              _drag.stop();
            },
            onVerticalDragUpdate: _dragged,
            onVerticalDragEnd: _released,
            child: AnimatedBuilder(
              animation: Listenable.merge([shown, _drag]),
              child: banner,
              builder: (context, child) => Opacity(
                opacity: shown.value,
                child: Transform.translate(
                  // It drops from above; with reduced motion it only fades.
                  offset: Offset(
                    0,
                    (reduced ? 0 : (1 - shown.value) * -Space.lg) + _drag.value,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
